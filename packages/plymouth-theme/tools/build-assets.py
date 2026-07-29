#!/usr/bin/env python3
"""Build deterministic, lightweight Plymouth assets from the supplied logo."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "gemstone-boot-logo.png"
GENERATED = ROOT / "assets" / "generated"
PACKAGE_THEME = (
    ROOT
    / "package"
    / "usr"
    / "share"
    / "plymouth"
    / "themes"
    / "t3-gemstone"
)


def build_watermark() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    luminance = ImageOps.grayscale(source)
    luminance = ImageEnhance.Contrast(luminance).enhance(1.35)
    alpha = luminance.point(lambda value: 0 if value < 4 else value)

    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError("The supplied logo has no visible pixels")

    alpha = alpha.crop(bbox)
    target_width = 260
    target_height = round(alpha.height * target_width / alpha.width)
    alpha = alpha.resize((target_width, target_height), Image.Resampling.LANCZOS)

    watermark = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
    watermark.putalpha(alpha)
    return watermark


def build_preview(watermark: Image.Image) -> Image.Image:
    preview = Image.new("RGB", (1280, 720), "#000000")
    logo_x = (preview.width - watermark.width) // 2
    logo_y = (preview.height - watermark.height) // 2 - 32
    preview.paste(watermark, (logo_x, logo_y), watermark)

    draw = ImageDraw.Draw(preview)
    dot_y = logo_y + watermark.height + 56
    colors = ("#19b5e5", "#f5a623", "#e31e2f")
    for index, color in enumerate(colors):
        x = preview.width // 2 - 30 + index * 30
        draw.ellipse((x - 5, dot_y - 5, x + 5, dot_y + 5), fill=color)
    return preview


def main() -> None:
    GENERATED.mkdir(parents=True, exist_ok=True)
    PACKAGE_THEME.mkdir(parents=True, exist_ok=True)

    watermark = build_watermark()
    preview = build_preview(watermark)

    watermark.save(GENERATED / "watermark.png", optimize=True)
    watermark.save(PACKAGE_THEME / "watermark.png", optimize=True)
    preview.save(GENERATED / "t3-plymouth-preview.png", optimize=True)

    print(f"watermark={watermark.width}x{watermark.height}")
    print("preview=1280x720")


if __name__ == "__main__":
    main()
