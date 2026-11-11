"""Build a player release ZIP without editor files or development dependencies."""

from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import sys
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
ADDON_NAME = "EnhancedJackfockHealthBar"
ADDON_DIR = ROOT / ADDON_NAME
SCREENSHOTS = (
    "docs/screenshots/health-bar.png",
    "docs/screenshots/in-game.png",
    "docs/screenshots/options.png",
)


def source_file(relative_path, boundary=ROOT):
    path = (ROOT / relative_path).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_relative_to(boundary.resolve()) or not path.is_file():
        raise ValueError(f"Source must be a file inside {boundary.name}: {relative_path}")
    return path


def png_file(relative_path, boundary=ROOT):
    path = source_file(relative_path, boundary)
    with path.open("rb") as stream:
        if stream.read(8) != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"Not a PNG file: {relative_path}")
    return path


def manifest():
    toc_name = f"{ADDON_NAME}/{ADDON_NAME}.toc"
    toc = source_file(toc_name, ADDON_DIR)
    versions, entries = [], []
    for raw_line in toc.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if line.startswith("## Version:"):
            versions.append(line.partition(":")[2].strip())
        if not line or line.startswith("#"):
            continue
        entry = PurePosixPath(line.replace("\\", "/"))
        if (entry.is_absolute() or PureWindowsPath(line).drive
                or ".." in entry.parts or entry.suffix.lower() != ".lua"):
            raise ValueError(f"Invalid Lua file in TOC: {line}")
        entries.append(entry.as_posix())
    if len(versions) != 1 or not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*(?:[-+][A-Za-z0-9.-]+)?", versions[0]):
        raise ValueError("The TOC must contain one safe numeric release version.")
    if not entries or len({name.casefold() for name in entries}) != len(entries):
        raise ValueError("The TOC must list Lua files without duplicates.")
    members = [(toc_name, toc)]
    for entry in entries:
        archive_name = f"{ADDON_NAME}/{entry}"
        members.append((archive_name, source_file(archive_name, ADDON_DIR)))
    image_name = f"{ADDON_NAME}/Media/AddonImage.png"
    members.append((image_name, png_file(image_name, ADDON_DIR)))
    audio_name = f"{ADDON_NAME}/Media/alarm.mp3"
    audio = source_file(audio_name, ADDON_DIR)
    if audio.stat().st_size == 0:
        raise ValueError("The bundled alarm.mp3 must not be empty.")
    members.append((audio_name, audio))
    for name in ("README.md", "docs/COMPATIBILITY.md"):
        members.append((name, source_file(name)))
    for name in SCREENSHOTS:
        members.append((name, png_file(name)))
    return versions[0], members


def build_package():
    version, members = manifest()
    output_dir = (ROOT / "dist").resolve()
    if not output_dir.is_relative_to(ROOT):
        raise ValueError("The release directory must stay inside the project.")
    output_dir.mkdir(parents=True, exist_ok=True)
    archive_path = output_dir / f"EnhancedJackfockHealthBar-{version}.zip"
    if not archive_path.resolve().is_relative_to(output_dir):
        raise ValueError("The release archive must stay inside dist.")
    with ZipFile(archive_path, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, path in members:
            # Fixed timestamps and permissions make identical inputs reproducible.
            info = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(archive_path) as archive:
        names = archive.namelist()
        if (names != [name for name, _ in members] or archive.testzip() is not None
                or f"{ADDON_NAME}/{ADDON_NAME}.toc" not in names
                or any(name.startswith("MyForeverAddon/") for name in names)):
            raise ValueError("Release archive verification failed.")
    print(f"{archive_path.relative_to(ROOT)} ({len(members)} files)")
    return archive_path


if __name__ == "__main__":
    try:
        build_package()
    except (OSError, ValueError) as error:
        sys.exit(f"Packaging failed: {error}")
