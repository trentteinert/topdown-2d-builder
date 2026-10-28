#!/usr/bin/env python3
"""Generates the 3/4-view pixel-art sprites in assets/sprites/.

Perspective: the camera looks down at an angle, so solid things show a lit top face
and a darker front face. Every sprite is drawn with its footprint at the BOTTOM of the
image; the scenes anchor that edge to the bottom of the tile so Y-sorting works.

Everything is drawn at low resolution and scaled up with nearest-neighbour.
Re-run after editing:  python3 tools/make_sprites.py
Animated sprites are horizontal strips (one frame per cell).
"""
import math
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
SCALE = 2

PAL = {
    "K": (12, 10, 16), "d": (38, 40, 52), "g": (76, 80, 96), "G": (124, 130, 148), "L": (162, 170, 188),
    "w": (232, 238, 246), "s": (160, 170, 190),
    "r": (208, 56, 64), "R": (128, 30, 50), "o": (232, 144, 62), "O": (150, 82, 42),
    "y": (252, 214, 72), "Y": (190, 140, 40), "c": (112, 236, 255), "C": (40, 150, 172),
    "b": (66, 116, 224), "B": (34, 58, 130), "p": (160, 76, 208), "P": (88, 42, 134),
    "n": (118, 76, 64), "N": (76, 46, 50), "t": (52, 134, 128), "T": (28, 82, 82),
}
K = PAL["K"]


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((int(x), int(y)), tuple(c) + (255,) if len(c) == 3 else tuple(c))


def rect(img, x0, y0, x1, y1, fill, outline=None):
    ImageDraw.Draw(img).rectangle((x0, y0, x1, y1), fill=fill, outline=outline)


def ellipse(img, x0, y0, x1, y1, fill, outline=None):
    ImageDraw.Draw(img).ellipse((x0, y0, x1, y1), fill=fill, outline=outline)


def poly(img, pts, fill, outline=None):
    ImageDraw.Draw(img).polygon(pts, fill=fill, outline=outline)


def blob(img, discs, fill, outline=K):
    """Union of discs (cx, cy, r) with a single clean outline."""
    for cx, cy, r in discs:
        ellipse(img, cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1, outline)
    for cx, cy, r in discs:
        ellipse(img, cx - r, cy - r, cx + r, cy + r, fill)


def lit(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


def box(img, x0, y0, x1, y1, top_h, top, front):
    """A block seen from the front-top: lit top face above a darker front face."""
    rect(img, x0, y0 + top_h, x1, y1, front, K)
    rect(img, x0, y0, x1, y0 + top_h, top, K)


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


def shadow(w, h, name, alpha=95):
    img = new(w, h)
    ImageDraw.Draw(img).ellipse((0, 0, w - 1, h - 1), fill=(0, 0, 0, alpha))
    save(img, name)


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
            for _ in range(10):
                x, y = tx * tile + rng.randint(1, 14), ty * tile + rng.randint(1, 14)
                px(img, x, y, lit(c, rng.choice((0.86, 0.9, 1.1))))
            if rng.random() < 0.6:  # dry grass tuft
                x, y = tx * tile + rng.randint(3, 12), ty * tile + rng.randint(5, 12)
                grass = (122, 102, 56)
                for dx, dy in ((0, 0), (0, -1), (-1, -2), (1, -2), (0, -3)):
                    px(img, x + dx, y + dy, grass)
            for i in range(tile):  # faint tile seams so the build grid is readable
                px(img, tx * tile + i, ty * tile, lit(c, 0.9))
                px(img, tx * tile, ty * tile + i, lit(c, 0.9))
    save(img, "ground")
    shadow(16, 6, "shadow")
    shadow(30, 9, "shadow_large")
    shadow(48, 12, "shadow_core", 80)


# ------------------------------------------------------------------ deposits

def ore_deposit():
    img = new(16, 16)
    ellipse(img, 0, 8, 6, 14, PAL["N"], K)            # small boulder behind
    ellipse(img, 2, 3, 14, 15, PAL["n"], K)           # main boulder
    ellipse(img, 4, 4, 11, 8, lit(PAL["n"], 1.35))    # lit top
    for x in range(5, 13):
        px(img, x, 14, PAL["N"])
    for x, y, c in ((5, 7, "o"), (6, 7, "y"), (5, 8, "o"), (10, 9, "o"), (11, 9, "o"), (10, 10, "O"),
                    (7, 11, "o"), (8, 11, "y"), (7, 12, "O"), (12, 6, "o")):
        px(img, x, y, PAL[c])
    save(img, "ore")


def crystal_deposit():
    img = new(16, 20)
    ellipse(img, 1, 15, 14, 19, PAL["N"], K)  # rocky base

    def spike(cx, base, h, w, light, dark, hi):
        top = base - h
        poly(img, [(cx - w, base), (cx, top), (cx, base)], light, K)
        poly(img, [(cx, base), (cx, top), (cx + w, base)], dark, K)
        px(img, cx - 1, top + 2, hi)
        px(img, cx - 1, top + 3, hi)

    spike(4, 16, 9, 3, PAL["c"], PAL["C"], PAL["w"])
    spike(12, 17, 11, 3, PAL["c"], PAL["C"], PAL["w"])
    spike(8, 18, 16, 4, (150, 245, 255), (60, 170, 200), PAL["w"])
    save(img, "crystal")


def scrap_icon_art():
    img = new(16, 16)
    poly(img, [(2, 12), (6, 5), (11, 7), (10, 13)], PAL["G"], K)
    poly(img, [(8, 4), (14, 6), (13, 12), (10, 9)], PAL["g"], K)
    px(img, 5, 9, PAL["L"]); px(img, 6, 8, PAL["L"]); px(img, 11, 7, PAL["L"])
    px(img, 8, 11, PAL["o"]); px(img, 12, 9, PAL["o"])
    return img


# --------------------------------------------------------------------- props

def tree():
    img = new(24, 36)
    rect(img, 10, 21, 13, 34, (222, 178, 184), K)
    for y in range(23, 33, 3):
        px(img, 11, y, (170, 120, 130))
    for x in (9, 14):
        px(img, x, 34, K)
    discs = [(12, 10, 8), (6, 15, 5), (18, 15, 5), (12, 18, 5)]
    blob(img, discs, (132, 28, 52))
    for cx, cy, r in ((10, 7, 4), (5, 13, 2), (16, 11, 3)):
        ellipse(img, cx - r, cy - r, cx + r, cy + r, (188, 58, 82))
    for x, y in ((9, 5), (10, 5), (15, 9), (4, 12)):
        px(img, x, y, (236, 120, 130))
    for x in range(8, 18):
        px(img, x, 21, (96, 20, 42))
    return img


def rock_prop():
    img = new(16, 11)
    blob(img, [(6, 6, 4), (11, 7, 3)], PAL["g"])
    ellipse(img, 4, 3, 8, 5, PAL["L"])
    ellipse(img, 10, 5, 12, 6, PAL["G"])
    return img


# ---------------------------------------------------------------- machinery

def drill_frame(facing, f):
    img = new(16, 24)
    box(img, 2, 5, 13, 22, 9, PAL["L"], PAL["g"])          # top face y5-14, front face y14-22
    for x, y in ((3, 6), (12, 6)):
        px(img, x, y, PAL["y"])
    for x in range(4, 12, 2):                                # vents on the front face
        rect(img, x, 17, x, 19, PAL["d"])
    for x in range(3, 13, 2):                                # hazard dashes along the bottom
        px(img, x, 21, PAL["y"])
    ellipse(img, 5, 6, 10, 12, PAL["T"], K)                  # drill bit housing on the top face
    bit = PAL["c"]
    if f == 0:
        for i in range(-2, 3):
            px(img, 7 + i, 9, bit); px(img, 7, 9 + i, bit)
    else:
        for i in range(-2, 3):
            px(img, 7 + i, 9 + i, bit); px(img, 7 + i, 9 - i, bit)
    px(img, 7, 9, PAL["w"])
    y, d = PAL["y"], K
    if facing == "e":
        rect(img, 13, 11, 15, 17, y, d)
    elif facing == "w":
        rect(img, 0, 11, 2, 17, y, d)
    elif facing == "s":
        rect(img, 6, 18, 9, 23, y, d)
        poly(img, [(5, 20), (10, 20), (7.5, 23)], K)
    else:
        rect(img, 6, 2, 9, 6, y, d)
        poly(img, [(5, 5), (10, 5), (7.5, 2)], K)
    return img


def conveyor_frame(facing, s):
    img = new(16, 16)
    rect(img, 0, 0, 15, 13, (28, 28, 36))
    rect(img, 0, 14, 15, 15, (16, 16, 22))                  # front lip gives the belt thickness
    dx, dy = {"e": (1, 0), "s": (0, 1), "w": (-1, 0), "n": (0, -1)}[facing]
    along = [(dx, dy), (-dy, dx)]
    yellow, dark = PAL["y"], PAL["Y"]
    # chevrons march along the travel direction
    for base in (0, 8):
        a0 = ((s + base) % 16) - 8
        for k in range(4):
            for v in (k - 3, 3 - k):
                a = a0 + k
                a = (a + 8) % 16 - 8
                x = 7.5 + dx * a + (-dy) * v * 1.0 + 0.5
                y = 6.5 + dy * a + dx * v * 1.0 + 0.5
                px(img, math.floor(x), math.floor(y), yellow)
    # dotted yellow edge on the sides running parallel to travel
    for i in range(0, 16, 2):
        if dx != 0:
            px(img, i, 0, dark); px(img, i, 13, dark)
        else:
            px(img, 0, i, dark); px(img, 15, i, dark)
    return img


def turret_base():
    img = new(16, 24)
    box(img, 2, 10, 13, 22, 5, PAL["L"], PAL["g"])
    for x in range(3, 13, 2):
        px(img, x, 21, PAL["y"])
    rect(img, 4, 17, 11, 19, PAL["d"])
    px(img, 3, 11, PAL["G"]); px(img, 12, 11, PAL["G"])
    save(img, "turret_base")
    head = new(12, 12)
    blob(head, [(6, 6, 4)], PAL["G"])
    ellipse(head, 4, 3, 7, 5, PAL["L"])
    save(head, "turret_head")
    barrel = new(11, 5)
    rect(barrel, 0, 0, 10, 4, PAL["G"], K)
    rect(barrel, 8, 1, 10, 3, PAL["y"], K)
    for x in (2, 4, 6):
        px(barrel, x, 2, PAL["g"])
    save(barrel, "turret_barrel")
    flash = new(9, 9)
    poly(flash, [(0, 4), (4, 2), (8, 4), (4, 6)], PAL["y"])
    poly(flash, [(2, 4), (4, 3), (6, 4), (4, 5)], PAL["w"])
    save(flash, "muzzle_flash")


def tesla_frame(f):
    img = new(16, 28)
    box(img, 2, 18, 13, 26, 4, PAL["L"], PAL["P"])
    rect(img, 6, 8, 9, 20, PAL["P"], K)                      # shaft
    for y in (11, 14, 17):
        rect(img, 4, y, 11, y + 1, PAL["p"], K)
    orb = PAL["c"] if f != 1 else PAL["w"]
    blob(img, [(8, 6, 3)], orb)
    px(img, 7, 5, PAL["w"])
    if f == 1:
        for dx, dy in ((0, -6), (-5, 0), (5, 0), (-4, -4), (4, -4)):
            px(img, 8 + dx, 6 + dy, PAL["c"])
    if f == 2:
        for dx, dy in ((0, -5), (-4, -3), (4, -3)):
            px(img, 8 + dx, 6 + dy, PAL["c"])
    return img


def core_frame(f):
    img = new(48, 64)
    box(img, 0, 2, 47, 62, 38, (86, 96, 124), (52, 58, 82))   # roof y2-40, front face y40-62
    for i in range(1, 47):                                      # hazard border on the roof edge
        if (i // 3) % 2 == 0:
            px(img, i, 3, PAL["y"]); px(img, i, 4, PAL["y"])
            px(img, i, 38, PAL["y"]); px(img, i, 39, PAL["y"])
    for y in range(6, 38):
        if (y // 3) % 2 == 0:
            px(img, 1, y, PAL["y"]); px(img, 2, y, PAL["y"]); px(img, 45, y, PAL["y"]); px(img, 46, y, PAL["y"])
    rect(img, 6, 8, 41, 33, (66, 74, 100), K)                  # roof plate
    blob(img, [(24, 21, 9)], PAL["B"])
    ellipse(img, 18, 15, 30, 27, PAL["b"], K)
    glow = PAL["c"] if f == 0 else PAL["w"]
    ellipse(img, 21, 18, 27, 24, glow)
    px(img, 23, 19, PAL["w"])
    for x in (8, 39):
        for y in (10, 31):
            px(img, x, y, PAL["L"])
    rect(img, 19, 44, 28, 61, (30, 34, 50), K)                 # airlock door on the front
    rect(img, 23, 46, 24, 60, (20, 22, 34))
    for x in (6, 12, 35, 41):                                   # lit windows
        rect(img, x, 47, x + 3, 51, PAL["c"] if (x + f) % 2 else PAL["C"], K)
    for x in range(2, 46, 4):
        px(img, x, 60, PAL["y"]); px(img, x + 1, 60, PAL["y"])
    return img


# ------------------------------------------------------------ player & enemies

def player_frame(view, step):
    """12x16 astronaut. view: down|up|side. step 0 = idle, 1-4 = walk cycle."""
    img = new(12, 16)
    suit, shade = PAL["w"], PAL["s"]
    phase = (0, 1, 0, -1, 0)[step]
    lift_l = 1 if phase > 0 else 0
    lift_r = 1 if phase < 0 else 0
    bob = 1 if step in (2, 4) else 0
    legs = [(3, 5, lift_l), (6, 8, lift_r)] if view != "side" else [(3, 5, lift_l), (5, 7, lift_r)]
    for x0, x1, lift in legs:
        rect(img, x0, 12, x1, 15 - lift, shade, K)
    up = new(12, 14)
    if view == "side":
        rect(up, 0, 6, 3, 10, PAL["g"], K)                     # backpack
    rect(up, 2, 6, 9, 11, suit, K)                             # torso
    if view == "up":
        rect(up, 3, 6, 8, 10, PAL["g"], K)
    if view == "down":
        px(up, 5, 8, PAL["y"]); px(up, 6, 8, PAL["y"])
    ellipse(up, 1, 0, 10, 8, suit, K)                          # helmet
    if view == "down":
        rect(up, 3, 3, 8, 5, PAL["b"], K)
        px(up, 4, 3, PAL["c"]); px(up, 5, 3, PAL["c"])
    elif view == "side":
        rect(up, 6, 2, 9, 5, PAL["b"], K)
        px(up, 7, 2, PAL["c"])
        rect(up, 4, 7, 6, 9, shade, K)                         # near arm
    else:
        px(up, 5, 0, K); px(up, 6, 0, K)
        rect(up, 4, 1, 7, 2, shade)
    if view != "side":
        rect(up, 0, 7, 1, 9, shade, K); rect(up, 10, 7, 11, 9, shade, K)
    img.alpha_composite(up, (0, 2 - bob))
    return img


def crawler_frame(f):
    img = new(14, 12)
    for i, x in enumerate((3, 6, 9)):
        lift = ((f + i) % 4) < 2
        px(img, x, 8, K); px(img, x, 9, PAL["R"])
        px(img, x - 1 if lift else x, 10 if lift else 11, K)
        px(img, x + 1, 9, K)
    blob(img, [(6, 5, 3), (9, 5, 3)], PAL["r"])
    ellipse(img, 4, 2, 9, 4, (240, 110, 110))
    for x in range(3, 11):
        px(img, x, 7, PAL["R"])
    px(img, 11, 4, PAL["y"]); px(img, 11, 6, PAL["y"])
    px(img, 12, 7, PAL["w"])
    return img


def brute_frame(f):
    img = new(20, 18)
    for i, x in enumerate((4, 8, 12, 15)):
        lift = ((f + i) % 4) < 2
        rect(img, x, 12, x + 1, 15 if lift else 16, PAL["P"], K)
    blob(img, [(9, 8, 6), (13, 8, 5)], PAL["P"])
    ellipse(img, 5, 3, 13, 8, PAL["p"])
    for x in (4, 7, 10, 13):  # back spikes
        poly(img, [(x, 5), (x + 1, 0), (x + 2, 5)], PAL["L"], K)
    rect(img, 15, 6, 17, 7, PAL["y"]); rect(img, 15, 10, 17, 11, PAL["y"])
    px(img, 18, 9, PAL["w"])
    return img


def bullet():
    img = new(4, 4)
    rect(img, 0, 0, 3, 3, PAL["y"])
    rect(img, 1, 1, 2, 2, PAL["w"])
    save(img, "bullet")


# ---------------------------------------------------------------------- icons

def icons():
    def ico(name, draw):
        img = new(16, 16)
        draw(img)
        save(img, name)

    def ore(i):
        blob(i, [(5, 10, 3), (10, 9, 4), (8, 5, 3)], PAL["n"])
        for x, y in ((4, 9), (9, 8), (8, 4), (11, 10)):
            px(i, x, y, PAL["o"])
        px(i, 9, 7, PAL["y"])

    def crystal(i):
        poly(i, [(2, 13), (5, 6), (8, 13)], PAL["c"], K)
        poly(i, [(7, 14), (11, 2), (14, 14)], (150, 245, 255), K)
        poly(i, [(11, 14), (11, 2), (14, 14)], PAL["C"], K)

    def drill(i):
        box(i, 2, 3, 13, 14, 5, PAL["L"], PAL["g"])
        ellipse(i, 5, 4, 10, 7, PAL["T"], K)
        px(i, 7, 5, PAL["c"])
        rect(i, 13, 7, 15, 11, PAL["y"], K)

    def conveyor(i):
        rect(i, 0, 4, 15, 11, (28, 28, 36), K)
        for x in (3, 9):
            for k in range(3):
                px(i, x + k, 5 + k, PAL["y"]); px(i, x + k, 10 - k, PAL["y"])

    def turret(i):
        box(i, 3, 7, 12, 14, 3, PAL["L"], PAL["g"])
        blob(i, [(7, 5, 3)], PAL["G"])
        rect(i, 9, 4, 15, 6, PAL["G"], K)
        px(i, 15, 5, PAL["y"])

    def tesla(i):
        box(i, 3, 11, 12, 15, 2, PAL["L"], PAL["P"])
        rect(i, 6, 5, 9, 12, PAL["P"], K)
        rect(i, 4, 8, 11, 9, PAL["p"], K)
        blob(i, [(8, 3, 2)], PAL["c"])

    def sun(i):
        blob(i, [(8, 8, 4)], PAL["y"])
        for dx, dy in ((0, -7), (0, 7), (-7, 0), (7, 0), (5, 5), (-5, -5), (5, -5), (-5, 5)):
            px(i, 8 + dx, 8 + dy, PAL["y"])
        px(i, 7, 7, PAL["w"])

    def moon(i):
        blob(i, [(8, 8, 5)], (200, 210, 240))
        ellipse(i, 8, 3, 15, 12, (0, 0, 0, 0))
        for y in range(16):
            for x in range(16):
                if (x - 11) ** 2 + (y - 6) ** 2 <= 20:
                    i.putpixel((x, y), (0, 0, 0, 0))

    def heart(i):
        blob(i, [(5, 6, 3), (10, 6, 3)], PAL["r"])
        poly(i, [(2, 8), (13, 8), (8, 14)], PAL["r"])
        px(i, 4, 4, PAL["w"])

    def core_icon(i):
        box(i, 1, 3, 14, 14, 6, (86, 96, 124), (52, 58, 82))
        blob(i, [(7, 7, 2)], PAL["c"])
        for x in range(2, 14, 2):
            px(i, x, 13, PAL["y"])

    ico("ico_ore", ore)
    ico("ico_crystal", crystal)
    save(scrap_icon_art(), "ico_scrap")
    ico("ico_drill", drill)
    ico("ico_conveyor", conveyor)
    ico("ico_turret", turret)
    ico("ico_tesla", tesla)
    ico("ico_sun", sun)
    ico("ico_moon", moon)
    ico("ico_heart", heart)
    ico("ico_core", core_icon)


if __name__ == "__main__":
    ground()
    ore_deposit()
    crystal_deposit()
    save(tree(), "tree")
    save(rock_prop(), "rock")
    strip([drill_frame(d, f) for d in "esw" "n" for f in (0, 1)], "drill")        # order: e0 e1 s0 s1 w0 w1 n0 n1
    strip([conveyor_frame(d, s) for d in "esw" "n" for s in (0, 4, 8, 12)], "conveyor")  # 4 frames per facing
    turret_base()
    strip([tesla_frame(f) for f in (0, 1, 2)], "tesla")
    strip([core_frame(0), core_frame(1)], "core")
    strip([player_frame(v, s) for v in ("down", "up", "side") for s in range(5)], "player")
    gun = new(10, 4)
    rect(gun, 0, 0, 9, 3, PAL["g"], K)
    rect(gun, 7, 1, 9, 2, PAL["y"])
    save(gun, "player_gun")
    strip([crawler_frame(f) for f in range(4)], "crawler")
    strip([brute_frame(f) for f in range(4)], "brute")
    bullet()
    icons()
    print("sprites written to", os.path.normpath(OUT))
