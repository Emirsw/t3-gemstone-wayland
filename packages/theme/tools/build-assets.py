#!/usr/bin/env python3
"""Build deterministic T3 Gemstone theme assets from the supplied logo."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source"
GENERATED = ROOT / "assets" / "generated"
PACKAGE = ROOT / "package"
REPO_ROOT = ROOT.parents[1]

NAVY = (8, 24, 39, 255)
NAVY_INNER = (13, 36, 57, 255)
CYAN = (18, 168, 212, 255)
ORANGE = (245, 166, 35, 255)
RED = (214, 31, 44, 255)


def resolve_source(*candidates: Path) -> Path:
    for candidate in candidates:
        if candidate.exists():
            return candidate
    options = ", ".join(str(candidate) for candidate in candidates)
    raise FileNotFoundError(f"No source asset found. Checked: {options}")


def extract_logo() -> Image.Image:
    """Remove the white JPEG background while retaining the original mark."""
    source_path = resolve_source(
        SOURCE / "t3-logo-original.jpg",
        REPO_ROOT / "assets" / "icons" / "10th-anniversary" / "t3-gemstone-10th-512.png",
    )
    source = Image.open(source_path)
    if source_path.suffix.lower() not in {".jpg", ".jpeg"}:
        rgba = source.convert("RGBA")
        bounds = rgba.getbbox()
        if bounds is None:
            raise RuntimeError("Logo extraction produced an empty image")
        return rgba.crop(bounds)

    source = source.convert("RGB")
    rgba = Image.new("RGBA", source.size)
    output = []

    pixels = source.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue = pixels[x, y]
            alpha = max(0, 255 - min(red, green, blue))
            if alpha < 8:
                output.append((0, 0, 0, 0))
                continue

            opacity = alpha / 255.0
            clean = tuple(
                max(0, min(255, round((channel - 255 * (1 - opacity)) / opacity)))
                for channel in (red, green, blue)
            )
            output.append((*clean, alpha))

    rgba.putdata(output)
    bounds = rgba.getbbox()
    if bounds is None:
        raise RuntimeError("Logo extraction produced an empty image")
    return rgba.crop(bounds)


def launcher_icon(logo: Image.Image, size: int) -> Image.Image:
    scale = 4
    canvas_size = size * scale
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    margin = int(canvas_size * 0.035)
    shadow_draw.ellipse(
        (margin, margin + scale * 4, canvas_size - margin, canvas_size - margin + scale * 4),
        fill=(0, 0, 0, 150),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(canvas_size * 0.025))
    canvas.alpha_composite(shadow)

    draw = ImageDraw.Draw(canvas)
    ring_margin = int(canvas_size * 0.045)
    ring_box = (
        ring_margin,
        ring_margin,
        canvas_size - ring_margin,
        canvas_size - ring_margin,
    )
    ring_width = int(canvas_size * 0.065)
    draw.ellipse(ring_box, fill=NAVY)
    draw.arc(ring_box, start=210, end=322, fill=CYAN, width=ring_width)
    draw.arc(ring_box, start=328, end=440, fill=RED, width=ring_width)
    draw.arc(ring_box, start=88, end=200, fill=ORANGE, width=ring_width)

    inner_margin = ring_margin + ring_width
    draw.ellipse(
        (
            inner_margin,
            inner_margin,
            canvas_size - inner_margin,
            canvas_size - inner_margin,
        ),
        fill=NAVY_INNER,
        outline=(255, 255, 255, 25),
        width=max(1, scale * 2),
    )

    logo_limit = int(canvas_size * 0.57)
    fitted = ImageOps.contain(logo, (logo_limit, logo_limit), Image.Resampling.LANCZOS)

    logo_shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    logo_position = (
        (canvas_size - fitted.width) // 2,
        (canvas_size - fitted.height) // 2 + int(canvas_size * 0.01),
    )
    shadow_mask = fitted.getchannel("A").filter(ImageFilter.GaussianBlur(scale * 5))
    shadow_layer = Image.new("RGBA", fitted.size, (0, 0, 0, 120))
    shadow_layer.putalpha(shadow_mask)
    logo_shadow.alpha_composite(
        shadow_layer,
        (logo_position[0], logo_position[1] + scale * 6),
    )
    canvas.alpha_composite(logo_shadow)
    canvas.alpha_composite(fitted, logo_position)

    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def build_wallpaper(icon: Image.Image, width: int, height: int) -> Image.Image:
    background = Image.open(
        resolve_source(
            SOURCE / "t3-abstract-background.png",
            REPO_ROOT
            / "assets"
            / "wallpapers"
            / "10th-anniversary"
            / "t3-gemstone-10th-anniversary-obsidian-horizon-1920x1080.png",
        )
    ).convert("RGB")
    wallpaper = ImageOps.fit(
        background,
        (width, height),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    ).convert("RGBA")

    badge_size = round(width * 0.105)
    badge = icon.resize((badge_size, badge_size), Image.Resampling.LANCZOS)
    badge.putalpha(badge.getchannel("A").point(lambda value: round(value * 0.92)))
    x = round(width * 0.075)
    y = (height - badge_size) // 2
    wallpaper.alpha_composite(badge, (x, y))

    return wallpaper.convert("RGB")


def main() -> None:
    GENERATED.mkdir(parents=True, exist_ok=True)
    logo = extract_logo()
    master = launcher_icon(logo, 512)

    for size in (128, 256, 512):
        icon = master.resize((size, size), Image.Resampling.LANCZOS)
        generated_path = GENERATED / f"t3-gemstone-{size}.png"
        package_path = (
            PACKAGE
            / "usr"
            / "share"
            / "icons"
            / "hicolor"
            / f"{size}x{size}"
            / "apps"
            / "t3-gemstone.png"
        )
        package_path.parent.mkdir(parents=True, exist_ok=True)
        icon.save(generated_path, optimize=True)
        icon.save(package_path, optimize=True)

    for width, height in ((1280, 720), (1920, 1080)):
        wallpaper = build_wallpaper(master, width, height)
        filename = f"{width}x{height}.png"
        generated_path = GENERATED / f"t3-gemstone-wallpaper-{filename}"
        package_path = (
            PACKAGE
            / "usr"
            / "share"
            / "wallpapers"
            / "T3Gemstone"
            / "contents"
            / "images"
            / filename
        )
        package_path.parent.mkdir(parents=True, exist_ok=True)
        wallpaper.save(generated_path, optimize=True)
        wallpaper.save(package_path, optimize=True)

    preview = build_wallpaper(master, 1280, 720)
    preview.save(GENERATED / "t3-gemstone-theme-preview.png", optimize=True)
    print(f"Assets written to {GENERATED}")


if __name__ == "__main__":
    main()
