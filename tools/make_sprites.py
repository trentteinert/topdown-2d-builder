#!/usr/bin/env python3
"""Generates the pixel-art sprites in assets/sprites/.

Everything is drawn at low resolution and scaled up with nearest-neighbour, so the
sprites stay crisp. Re-run after editing:  python3 tools/make_sprites.py
Animated sprites are horizontal strips (one frame per cell).
"""
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
SCALE = 2

PAL = {
    ".": None,
    "K": (12, 10, 16), "d": (38, 40, 52), "g": (76, 80, 96), "G": (124, 130, 148), "w": (228, 234, 242),
    "r": (208, 56, 64), "R": (128, 30, 50), "o": (232, 144, 62), "O": (150, 82, 42),
    "y": (252, 214, 72), "Y": (190, 140, 40), "c": (112, 236, 255), "C": (40, 150, 172),
    "b": (66, 116, 224), "B": (34, 58, 130), "p": (160, 76, 208), "P": (88, 42, 134),
    "n": (118, 76, 64), "N": (76, 46, 50), "t": (52, 134, 128), "T": (28, 82, 82),
}


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def from_art(rows, w=16, h=16):
    """Builds an image from ASCII rows using PAL; short rows/columns are padded transparent."""
    img = new(w, h)
    for y, row in enumerate(rows):
        assert len(row) <= w, f"row {y} too wide ({len(row)}): {row!r}"
        for x, ch in enumerate(row):
            if PAL[ch]:
                img.putpixel((x, y), PAL[ch] + (255,))
    return img


def disc(img, cx, cy, r, fill, outline=None):
    d = ImageDraw.Draw(img)
    box = (cx - r, cy - r, cx + r, cy + r)
    d.ellipse(box, fill=fill, outline=outline)


def rect(img, x0, y0, x1, y1, fill, outline=None):
    ImageDraw.Draw(img).rectangle((x0, y0, x1, y1), fill=fill, outline=outline)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c + (255,) if len(c) == 3 else c)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST).save(os.path.join(OUT, name + ".png"))


def strip(frames, name):
    sheet = new(sum(f.width for f in frames), frames[0].height)
    x = 0
    for f in frames:
        sheet.paste(f, (x, 0))
        x += f.width
    save(sheet, name)


# --------------------------------------------------------------------- ground

def ground():
    rng = random.Random(7)
    tile = 16
    img = new(tile * 4, tile * 4)
    base = (60, 34, 46)
    for ty in range(4):
        for tx in range(4):
            shade = rng.randint(-4, 4)
            c = tuple(max(0, v + shade) for v in base)
            rect(img, tx * tile, ty * tile, tx * tile + tile - 1, ty * tile + tile - 1, c)
            for _ in range(10):  # speckles
                x, y = tx * tile + rng.randint(1, 14), ty * tile + rng.randint(1, 14)
                f = rng.choice((-9, -6, 6))
                px(img, x, y, tuple(max(0, min(255, v + f)) for v in c))
            if rng.random() < 0.55:  # dry grass tuft
                x, y = tx * tile + rng.randint(3, 12), ty * tile + rng.randint(4, 12)
                grass = (118, 98, 54)
                px(img, x, y, grass); px(img, x, y - 1, grass); px(img, x - 1, y - 2, grass); px(img, x + 1, y - 2, grass)
            # faint tile seams so the build grid is readable
            for i in range(tile):
                px(img, tx * tile + i, ty * tile, tuple(max(0, v - 7) for v in c))
                px(img, tx * tile, ty * tile + i, tuple(max(0, v - 7) for v in c))
    save(img, "ground")


# ------------------------------------------------------------------- deposits

def deposits():
    ore = from_art([
        "................",
        ".....KKKK.......",
        "...KKnnnnKK.....",
        "..KnnnnnnnnK....",
        "..KnnoonnnnK.KK.",
        ".KnnnooonnnKKnK.",
        ".KnnnnnnnnnnnnK.",
        ".KnnonnnnnnnnnK.",
        ".KnnooonnnnoonK.",
        ".KnnnonnnnnooonK",
        "..KnnnnnnnnnoonK",
        "..KNnnnnnnnnnnK.",
        "...KNNnnnnnnNK..",
        "....KKNNNNNNK...",
        "......KKKKKK....",
    ])
    save(ore, "ore")
    crystal = from_art([
        ".......KK.......",
        "......KccK......",
        ".....KcwcCK.....",
        ".....KcccCK..KK.",
        "..KK.KccCCK.KcK.",
        ".KcCKKcccCKKcCK.",
        ".KcwcKcccCKcwCK.",
        ".KccCKcwcCKccCK.",
        ".KcCCKccCCKcCCK.",
        "..KCCKcCCCKCCK..",
        "..KKKKCCCCKKKK..",
        "....KKKKKKKK....",
    ])
    save(crystal, "crystal")
    save(from_art([
        "..KKKK..",
        ".KooooK.",
        "KooyoooK",
        "KoooOooK",
        "KooOOooK",
        ".KOOOOK.",
        "..KKKK..",
    ], 8, 8), "item_ore")
    save(from_art([
        "...KK...",
        "..KccK..",
        ".KcwcCK.",
        ".KccCCK.",
        "..KCCK..",
        "...KK...",
    ], 8, 8), "item_crystal")


# ------------------------------------------------------------------ machinery

def drill_frame(f):
    img = new(16, 16)
    rect(img, 1, 1, 13, 14, PAL["g"], PAL["K"])
    for x, y in ((2, 2), (12, 2), (2, 13), (12, 13)):
        px(img, x, y, PAL["y"])
    disc(img, 7, 7, 4, PAL["T"], PAL["K"])
    bit = PAL["c"]
    if f == 0:
        for i in range(-3, 4):
            px(img, 7 + i, 7, bit); px(img, 7, 7 + i, bit)
    else:
        for i in range(-2, 3):
            px(img, 7 + i, 7 + i, bit); px(img, 7 + i, 7 - i, bit)
    px(img, 7, 7, PAL["w"])
    rect(img, 14, 5, 15, 9, PAL["y"], PAL["K"])  # output nozzle, faces east
    return img


def conveyor_frame(s):
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, (30, 30, 38))
    for x in range(16):
        px(img, x, 0, PAL["g"]); px(img, x, 15, PAL["g"])
        px(img, x, 1, PAL["K"]); px(img, x, 14, PAL["K"])
    for base in (0, 8):
        x0 = (base + s) % 16
        for k in range(4):  # a ">" chevron
            for yy in (3 + k, 12 - k):
                px(img, (x0 + k) % 16, yy, PAL["y"])
                px(img, (x0 + k + 1) % 16, yy, PAL["Y"])
    return img


def turret():
    base = new(16, 16)
    disc(base, 8, 8, 7, PAL["g"], PAL["K"])
    for x, y in ((3, 3), (12, 3), (3, 12), (12, 12)):
        px(base, x, y, PAL["G"])
    disc(base, 8, 8, 4, PAL["d"], PAL["K"])
    save(base, "turret_base")
    barrel = new(12, 5)
    rect(barrel, 0, 0, 11, 4, PAL["G"], PAL["K"])
    rect(barrel, 9, 1, 11, 3, PAL["y"], PAL["K"])
    for x in (2, 4, 6):
        px(barrel, x, 2, PAL["g"])
    save(barrel, "turret_barrel")
    cap = new(8, 8)
    disc(cap, 4, 4, 3, PAL["G"], PAL["K"])
    px(cap, 3, 3, PAL["w"])
    save(cap, "turret_cap")


def tesla_frame(f):
    img = new(16, 16)
    disc(img, 8, 8, 7, PAL["P"], PAL["K"])
    for a in range(0, 16, 4):
        px(img, 8 + (6 if a % 8 == 0 else 0) * (1 if a < 8 else -1), 8 + (6 if a % 8 else 0) * (1 if a < 8 else -1), PAL["p"])
    disc(img, 8, 8, 4, (120, 66, 176), PAL["K"])
    disc(img, 8, 8, 2, PAL["c"] if f == 0 else PAL["w"])
    if f == 1:
        for dx, dy in ((0, -4), (0, 4), (-4, 0), (4, 0), (3, 3), (-3, -3)):
            px(img, 8 + dx, 8 + dy, PAL["c"])
    return img


def core():
    img = new(48, 48)
    rect(img, 0, 0, 47, 47, (48, 54, 74), PAL["K"])
    for i in range(1, 47):  # hazard stripes along the hull edge
        if (i // 3) % 2 == 0:
            for t in (1, 2):
                px(img, i, t, PAL["y"]); px(img, i, 47 - t, PAL["y"]); px(img, t, i, PAL["y"]); px(img, 47 - t, i, PAL["y"])
    rect(img, 6, 6, 41, 41, (70, 78, 104), PAL["K"])
    for x, y in ((8, 8), (39, 8), (8, 39), (39, 39)):
        px(img, x, y, PAL["G"])
    for i in range(10, 38, 4):  # panel lines
        for j in range(8, 40):
            if abs(j - 24) > 11:
                px(img, i, j, (58, 64, 88)); px(img, j, i, (58, 64, 88))
    disc(img, 24, 24, 12, PAL["B"], PAL["K"])
    disc(img, 24, 24, 8, PAL["b"], PAL["K"])
    disc(img, 24, 24, 4, PAL["c"])
    disc(img, 24, 24, 1, PAL["w"])
    save(img, "core")


# ------------------------------------------------------------ player & enemies

def player():
    body = new(12, 12)
    rect(body, 0, 3, 2, 8, PAL["g"], PAL["K"])  # backpack (west)
    disc(body, 6, 6, 5, PAL["w"], PAL["K"])
    rect(body, 7, 3, 10, 8, PAL["b"], PAL["K"])  # visor (east)
    px(body, 8, 4, PAL["c"]); px(body, 8, 5, PAL["c"])
    save(body, "player")
    gun = new(10, 4)
    rect(gun, 0, 0, 9, 3, PAL["g"], PAL["K"])
    rect(gun, 7, 1, 9, 2, PAL["y"])
    save(gun, "player_gun")


def crawler_frame(f):
    img = new(12, 12)
    legs = (3, 6, 8) if f == 0 else (4, 5, 7)
    for x in legs:
        px(img, x, 1, PAL["K"]); px(img, x, 10, PAL["K"])
        px(img, x, 2, PAL["R"]); px(img, x, 9, PAL["R"])
    disc(img, 6, 6, 4, PAL["r"], PAL["K"])
    rect(img, 3, 4, 5, 7, PAL["R"])
    px(img, 8, 4, PAL["y"]); px(img, 8, 7, PAL["y"])
    return img


def brute_frame(f):
    img = new(16, 16)
    for a in range(8):
        sx = 8 + int(round(7 * (1 if a in (0, 1, 7) else -1 if a in (3, 4, 5) else 0)))
        sy = 8 + int(round(7 * (1 if a in (1, 2, 3) else -1 if a in (5, 6, 7) else 0)))
        px(img, sx, sy, PAL["p"])
    legs = (4, 8, 11) if f == 0 else (5, 7, 10)
    for x in legs:
        px(img, x, 1, PAL["K"]); px(img, x, 14, PAL["K"])
        px(img, x, 2, PAL["P"]); px(img, x, 13, PAL["P"])
    disc(img, 8, 8, 6, PAL["P"], PAL["K"])
    disc(img, 7, 8, 4, PAL["p"])
    rect(img, 4, 5, 6, 10, PAL["P"])
    rect(img, 10, 5, 11, 6, PAL["y"]); rect(img, 10, 9, 11, 10, PAL["y"])
    return img


def bullet():
    img = new(4, 4)
    rect(img, 0, 0, 3, 3, PAL["y"])
    rect(img, 1, 1, 2, 2, PAL["w"])
    save(img, "bullet")


if __name__ == "__main__":
    ground()
    deposits()
    strip([drill_frame(0), drill_frame(1)], "drill")
    strip([conveyor_frame(s) for s in (0, 2, 4, 6)], "conveyor")
    turret()
    strip([tesla_frame(0), tesla_frame(1)], "tesla")
    core()
    player()
    strip([crawler_frame(0), crawler_frame(1)], "crawler")
    strip([brute_frame(0), brute_frame(1)], "brute")
    bullet()
    print("sprites written to", os.path.normpath(OUT))
