import os
import shutil
import subprocess
import zipfile
from pathlib import Path

BASE_DIR = Path(__file__).parent
PACKAGE_DIR = BASE_DIR / "package"
ZIP_FILE = BASE_DIR / "rss-feeds.zip"
REQUIREMENTS_FILE = BASE_DIR / "requirements.txt"
HANDLER_FILE = BASE_DIR / "handler.py"


def set_up():
    if PACKAGE_DIR.exists():
        shutil.rmtree(PACKAGE_DIR)
    if ZIP_FILE.exists():
        ZIP_FILE.unlink()
    PACKAGE_DIR.mkdir(parents=True, exist_ok=True)


def clean_up():
    if PACKAGE_DIR.exists():
        shutil.rmtree(PACKAGE_DIR)


def install_dependencies():
    subprocess.check_call(
        ["pip", "install", "-r", str(REQUIREMENTS_FILE), "--target", str(PACKAGE_DIR)]
    )


def copy_handler():
    shutil.copy(HANDLER_FILE, PACKAGE_DIR)


def create_zip():
    with zipfile.ZipFile(ZIP_FILE, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(PACKAGE_DIR):
            if "__pycache__" in root:
                continue
            for file in files:
                file_path = Path(root) / file
                arcname = file_path.relative_to(PACKAGE_DIR)
                zipf.write(file_path, arcname)


def main():
    print("Building deployment package...")
    set_up()
    install_dependencies()
    copy_handler()
    create_zip()
    clean_up()
    print(f"Deployment package created {ZIP_FILE}")


if __name__ == "__main__":
    main()
