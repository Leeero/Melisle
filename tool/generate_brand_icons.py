from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/icons/source/melisle-logo-mark.png"
BACKGROUND = (247, 252, 252, 255)


def fitted_mark(size: int, scale: float = 0.70) -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    bounds = source.getbbox()
    if bounds is None:
        raise RuntimeError("Logo source is empty")
    source = source.crop(bounds)
    target = max(1, round(size * scale))
    source.thumbnail((target, target), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(source, ((size - source.width) // 2, (size - source.height) // 2))
    return canvas


def app_icon(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BACKGROUND)
    mark = fitted_mark(size, 0.68)
    canvas.alpha_composite(mark)
    return canvas


def save_png(image: Image.Image, path: Path, *, rgb: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    output = image.convert("RGB") if rgb else image
    output.save(path, format="PNG", optimize=True)


def main() -> None:
    save_png(fitted_mark(512, 0.88), ROOT / "assets/icons/logo.png")
    save_png(fitted_mark(44, 0.86), ROOT / "assets/icons/tray.png")

    tray_ico = fitted_mark(256, 0.84)
    tray_ico.save(
        ROOT / "assets/icons/tray.ico",
        format="ICO",
        sizes=[(16, 16), (20, 20), (24, 24), (32, 32), (40, 40), (48, 48), (64, 64), (128, 128), (256, 256)],
    )

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        save_png(
            app_icon(size),
            ROOT / f"android/app/src/main/res/{folder}/ic_launcher.png",
        )

    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for path in ios_dir.glob("*.png"):
        with Image.open(path) as current:
            size = current.width
        save_png(app_icon(size), path, rgb=True)

    macos_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for path in macos_dir.glob("*.png"):
        with Image.open(path) as current:
            size = current.width
        save_png(app_icon(size), path)

    windows_icon = app_icon(256)
    windows_icon.save(
        ROOT / "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
