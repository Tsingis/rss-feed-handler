import os
import shutil
import subprocess
import zipfile
import argparse
from pathlib import Path

BASE_DIR = Path(__file__).parent
PACKAGE_DIR = BASE_DIR / "package"


def set_up(zip_file: Path):
    if PACKAGE_DIR.exists():
        shutil.rmtree(PACKAGE_DIR)
    if zip_file.exists():
        zip_file.unlink()
    PACKAGE_DIR.mkdir(parents=True, exist_ok=True)


def clean_up():
    if PACKAGE_DIR.exists():
        shutil.rmtree(PACKAGE_DIR)


def install_dependencies(requirements_file: Path):
    subprocess.check_call(
        ["pip", "install", "-r", str(requirements_file), "--target", str(PACKAGE_DIR)]
    )


def copy_handler(handler_file: Path):
    shutil.copy(handler_file, PACKAGE_DIR)


def create_zip(zip_file: Path):
    with zipfile.ZipFile(zip_file, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(PACKAGE_DIR):
            if "__pycache__" in root:
                continue
            for file in sorted(files):
                file_path = Path(root) / file
                arcname = file_path.relative_to(PACKAGE_DIR)
                zip_info = zipfile.ZipInfo(str(arcname))
                zip_info.compress_type = zipfile.ZIP_DEFLATED
                with open(file_path, "rb") as f:
                    zipf.writestr(zip_info, f.read())


def main():
    parser = argparse.ArgumentParser(description="Build a Lambda deployment package.")
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default="rss-feeds.zip",
        help="Output zip file name (default: rss-feeds.zip)",
    )
    parser.add_argument(
        "--requirements",
        "-r",
        type=str,
        default="requirements.txt",
        help="Path to requirements.txt (default: requirements.txt)",
    )
    parser.add_argument(
        "--handler",
        type=str,
        default="handler.py",
        help="Path to handler.py (default: handler.py)",
    )
    args = parser.parse_args()

    zip_file = BASE_DIR / args.output
    requirements_file = BASE_DIR / args.requirements
    handler_file = BASE_DIR / args.handler

    print("Building deployment package...")
    set_up(zip_file)
    install_dependencies(requirements_file)
    copy_handler(handler_file)
    create_zip(zip_file)
    clean_up()
    print(f"Deployment package created: {zip_file}")


if __name__ == "__main__":
    main()
