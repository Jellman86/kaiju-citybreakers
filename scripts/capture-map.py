#!/usr/bin/env python3
"""Extract the authored Workspace terrain and map root from a saved Studio place."""

from __future__ import annotations

import argparse
import copy
import os
from pathlib import Path
import tempfile
import xml.etree.ElementTree as ET


WORLD_NAME = "KaijuFeelLab"


def instance_name(item: ET.Element) -> str | None:
    properties = item.find("Properties")
    if properties is None:
        return None
    name = properties.find("string[@name='Name']")
    return name.text if name is not None else None


def write_model(instance: ET.Element, shared_strings: ET.Element | None, destination: Path) -> None:
    root = ET.Element("roblox", {"version": "4"})
    root.append(copy.deepcopy(instance))
    if shared_strings is not None:
        root.append(copy.deepcopy(shared_strings))

    ET.indent(root, space="  ")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="wb", prefix=f".{destination.name}.", dir=destination.parent, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
        ET.ElementTree(root).write(temporary, encoding="utf-8", xml_declaration=False)
    os.replace(temporary_path, destination)
    destination.chmod(0o644)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Capture Workspace.Terrain and Workspace.KaijuFeelLab from a saved .rbxlx file."
    )
    parser.add_argument("place", type=Path, help="Saved Studio .rbxlx place")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("src/world"),
        help="Destination directory (default: src/world)",
    )
    capture_scope = parser.add_mutually_exclusive_group()
    capture_scope.add_argument(
        "--world-only",
        action="store_true",
        help="Capture KaijuFeelLab without replacing the terrain source",
    )
    capture_scope.add_argument(
        "--terrain-only",
        action="store_true",
        help="Capture Terrain without replacing the KaijuFeelLab source",
    )
    args = parser.parse_args()

    tree = ET.parse(args.place)
    root = tree.getroot()
    workspace = next(
        (
            item
            for item in root.findall("Item")
            if item.get("class") == "Workspace" or instance_name(item) == "Workspace"
        ),
        None,
    )
    if workspace is None:
        raise SystemExit("Saved place does not contain a top-level Workspace")

    terrain = next(
        (item for item in workspace.findall("Item") if item.get("class") == "Terrain"),
        None,
    )
    world = next(
        (item for item in workspace.findall("Item") if instance_name(item) == WORLD_NAME),
        None,
    )
    if terrain is None:
        raise SystemExit("Saved place does not contain Workspace.Terrain")
    if world is None:
        raise SystemExit(f"Saved place does not contain Workspace.{WORLD_NAME}")

    shared_strings = root.find("SharedStrings")
    captured = []
    if not args.world_only:
        write_model(terrain, shared_strings, args.output / "Terrain.rbxmx")
        captured.append("Terrain")
    if not args.terrain_only:
        write_model(world, shared_strings, args.output / f"{WORLD_NAME}.rbxmx")
        captured.append(WORLD_NAME)
    print(f"Captured {' and '.join(captured)} in {args.output}")


if __name__ == "__main__":
    main()
