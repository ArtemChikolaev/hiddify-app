from pathlib import Path
from sys import argv
from PIL import Image, ImageDraw, ImageFont

source, target = map(Path, argv[1:3])
target.mkdir(exist_ok=True)
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
for theme in ("light", "dark"):
    for lang in ("en", "fa"):
        frames = []
        for mode in ("tree", "text"):
            images = [Image.open(source / f"{theme}-{lang}-{mode}-{v}.png").convert("RGB") for v in ("before", "after")]
            width, height = images[0].size
            assert images[1].size == (width, height)
            canvas = Image.new("RGB", (2 * width + 2, height + 32), "#334155")
            draw = ImageDraw.Draw(canvas)
            for i, (label, img) in enumerate(zip(("Before", "After"), images)):
                x = i * (width + 2)
                draw.text((x + 12, 6), f"{label}  |  {mode.capitalize()}", font=font, fill="white")
                canvas.paste(img, (x, 32))
            frames.append(canvas)
        out = target / f"{theme}-{lang}.webp"
        frames[0].save(out, save_all=True, append_images=frames[1:], duration=[2200, 2200], loop=0, lossless=True)
        with Image.open(out) as anim:
            assert anim.n_frames == 2
