#!/usr/bin/env python3
import json
import logging
import os
from dataclasses import dataclass
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_symlink(
    src: Path, dest: Path, overwrite=False, backup=False
) -> None:
    if not src.exists():
        logger.warning(f"Source does not exist: {src}")
        return

    if dest.exists() or dest.is_symlink():
        if dest.is_symlink() and dest.resolve() == src:
            logger.info(f"Already linked: {dest} → {src}")
            return

        if not overwrite:
            logger.info(f"Skipping existing file: {dest}")
            return

        if backup:
            backup_path = dest.with_suffix(dest.suffix + ".bak")
            dest.rename(backup_path)
            logger.info(f"Backed up {dest} → {backup_path}")
        else:
            if dest.is_dir() and not dest.is_symlink():
                raise RuntimeError(f"Refusing to overwrite directory: {dest}")
            dest.unlink()
            logger.info(f"Removed existing: {dest}")

    dest.parent.mkdir(parents=True, exist_ok=True)

    try:
        os.symlink(src, dest)
        logger.info(f"{dest} → {src}")
    except OSError as e:
        logger.warning(f"Failed to link {dest}: {e}")


def main() -> None:
    home = Path.home()
    repo = Path().resolve()

    mapping_file = repo / "mappings.json"

    with mapping_file.open() as f:
        temp = json.load(f)

    @dataclass(slots=True)
    class Mapping:
        src: Path
        dest: Path

    mappings = [
        Mapping(src=repo / item["repo"], dest=home / item["home"])
        for item in temp
    ]
    del temp

    for map in mappings:
        create_symlink(map.src, map.dest, overwrite=True, backup=True)


if __name__ == "__main__":
    main()
