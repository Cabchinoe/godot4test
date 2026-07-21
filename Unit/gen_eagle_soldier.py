#!/usr/bin/env python3
"""Generate anthropomorphic eagle soldier sprites (64x64)"""
from PIL import Image, ImageDraw

def px(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def rect(img, x1, y1, x2, y2, color):
    for y in range(y1, y2+1):
        for x in range(x1, x2+1):
            px(img, x, y, color)

def draw_eagle_soldier(img, ox=0, walk_phase=0):
    """Draw anthropomorphic eagle soldier. walk_phase: 0-3"""
    leg_off = [0, 2, 0, -2][walk_phase % 4]
    arm_off = [0, -1, 0, 1][walk_phase % 4]
    bounce = [0, -1, 0, -1][walk_phase % 4]

    # Colors
    feather_dark = (60, 45, 30)
    feather_brown = (100, 70, 45)
    feather_mid = (130, 95, 60)
    feather_light = (165, 125, 85)
    feather_highlight = (195, 160, 115)
    white_feather = (240, 235, 225)
    white_feather_d = (215, 210, 200)
    beak_orange = (220, 160, 40)
    beak_dark = (180, 120, 25)
    beak_tip = (60, 55, 50)
    eye_white = (252, 252, 252)
    eye_pupil = (20, 15, 10)
    eye_highlight = (255, 255, 255)
    eye_ring = (200, 170, 60)
    vest = (75, 85, 65)
    vest_d = (55, 62, 48)
    vest_h = (95, 105, 82)
    strap = (50, 45, 38)
    pants = (70, 75, 58)
    pants_d = (50, 55, 40)
    boot = (45, 38, 30)
    boot_h = (65, 58, 48)
    gun = (55, 55, 60)
    gun_d = (38, 38, 42)
    talon = (180, 140, 50)
    talon_d = (140, 105, 35)
    crest = (80, 55, 35)
    crest_h = (110, 80, 50)
    badge = (185, 165, 55)
    pouch = (100, 90, 68)

    by = bounce

    # === HEAD ===
    # White head feathers (bald eagle style)
    rect(img, ox+22, 4+by, ox+42, 6+by, white_feather)
    rect(img, ox+20, 6+by, ox+44, 9+by, white_feather)
    rect(img, ox+18, 9+by, ox+46, 13+by, white_feather)
    rect(img, ox+17, 13+by, ox+47, 17+by, white_feather)
    rect(img, ox+18, 17+by, ox+46, 20+by, white_feather_d)
    # Head highlight
    rect(img, ox+24, 5+by, ox+30, 7+by, (255, 250, 242))
    rect(img, ox+22, 7+by, ox+26, 10+by, (255, 250, 242))

    # Crest feathers on top
    rect(img, ox+38, 2+by, ox+41, 5+by, crest)
    rect(img, ox+40, 1+by, ox+42, 4+by, crest_h)
    rect(img, ox+36, 3+by, ox+39, 6+by, crest)
    rect(img, ox+42, 3+by, ox+44, 5+by, feather_dark)

    # === EYES (fierce raptor eyes) ===
    # Brow ridge
    rect(img, ox+20, 14+by, ox+44, 16+by, feather_dark)
    rect(img, ox+21, 13+by, ox+29, 15+by, feather_dark)
    rect(img, ox+35, 13+by, ox+43, 15+by, feather_dark)

    # Left eye
    rect(img, ox+22, 16+by, ox+29, 22+by, eye_ring)
    rect(img, ox+23, 17+by, ox+28, 21+by, eye_white)
    rect(img, ox+24, 18+by, ox+27, 20+by, eye_pupil)
    px(img, ox+25, 18+by, eye_highlight)
    # Right eye
    rect(img, ox+35, 16+by, ox+42, 22+by, eye_ring)
    rect(img, ox+36, 17+by, ox+41, 21+by, eye_white)
    rect(img, ox+37, 18+by, ox+40, 20+by, eye_pupil)
    px(img, ox+38, 18+by, eye_highlight)

    # === BEAK (hooked raptor beak) ===
    # Upper beak
    rect(img, ox+28, 22+by, ox+36, 24+by, beak_orange)
    rect(img, ox+27, 24+by, ox+37, 26+by, beak_orange)
    rect(img, ox+28, 26+by, ox+36, 27+by, beak_dark)
    # Hook tip
    rect(img, ox+29, 27+by, ox+35, 29+by, beak_dark)
    rect(img, ox+30, 29+by, ox+34, 30+by, beak_tip)
    # Beak highlight
    rect(img, ox+29, 22+by, ox+33, 23+by, (240, 185, 65))
    # Nostril
    px(img, ox+30, 24+by, beak_dark)
    px(img, ox+34, 24+by, beak_dark)
    # Lower beak / mouth line
    rect(img, ox+29, 26+by, ox+35, 26+by, (160, 100, 20))

    # === NECK ===
    rect(img, ox+26, 30+by, ox+38, 33+by, white_feather_d)
    rect(img, ox+27, 30+by, ox+37, 31+by, white_feather)

    # === TACTICAL VEST ===
    # Shoulders
    rect(img, ox+16, 33+by, ox+48, 36+by, vest)
    rect(img, ox+16, 33+by, ox+20, 36+by, vest_d)
    rect(img, ox+44, 33+by, ox+48, 36+by, vest_d)
    # Main body
    rect(img, ox+18, 36+by, ox+46, 46+by, vest)
    rect(img, ox+18, 43+by, ox+46, 46+by, vest_d)
    rect(img, ox+20, 36+by, ox+26, 39+by, vest_h)
    # Center zipper
    rect(img, ox+31, 36+by, ox+33, 46+by, strap)
    # Straps
    rect(img, ox+24, 33+by, ox+26, 46+by, strap)
    rect(img, ox+38, 33+by, ox+40, 46+by, strap)
    # Collar
    rect(img, ox+26, 33+by, ox+38, 35+by, vest_h)
    # Ammo pouches
    rect(img, ox+19, 38+by, ox+23, 43+by, pouch)
    rect(img, ox+19, 38+by, ox+23, 39+by, (115, 105, 80))
    rect(img, ox+41, 38+by, ox+45, 43+by, pouch)
    rect(img, ox+41, 38+by, ox+45, 39+by, (115, 105, 80))
    # Radio
    rect(img, ox+34, 37+by, ox+38, 41+by, (50, 50, 55))
    rect(img, ox+35, 38+by, ox+37, 40+by, (70, 70, 75))
    # Badge
    rect(img, ox+27, 37+by, ox+30, 40+by, badge)
    rect(img, ox+28, 38+by, ox+29, 39+by, (200, 180, 70))

    # === WINGS/ARMS ===
    # Left wing-arm
    rect(img, ox+10, 35+by+arm_off, ox+16, 44+by+arm_off, feather_mid)
    rect(img, ox+10, 35+by+arm_off, ox+16, 37+by+arm_off, feather_light)
    rect(img, ox+10, 44+by+arm_off, ox+16, 47+by+arm_off, feather_brown)
    # Wing feather tips
    rect(img, ox+9, 47+by+arm_off, ox+15, 49+by+arm_off, feather_dark)
    rect(img, ox+10, 49+by+arm_off, ox+14, 50+by+arm_off, feather_dark)
    # Talon hand
    rect(img, ox+11, 50+by+arm_off, ox+15, 52+by+arm_off, talon)
    rect(img, ox+10, 52+by+arm_off, ox+12, 54+by+arm_off, talon_d)
    rect(img, ox+14, 52+by+arm_off, ox+16, 54+by+arm_off, talon_d)

    # Right wing-arm
    rect(img, ox+48, 35+by-arm_off, ox+54, 44+by-arm_off, feather_mid)
    rect(img, ox+48, 35+by-arm_off, ox+54, 37+by-arm_off, feather_light)
    rect(img, ox+48, 44+by-arm_off, ox+54, 47+by-arm_off, feather_brown)
    # Wing feather tips
    rect(img, ox+49, 47+by-arm_off, ox+55, 49+by-arm_off, feather_dark)
    rect(img, ox+50, 49+by-arm_off, ox+54, 50+by-arm_off, feather_dark)
    # Talon hand
    rect(img, ox+49, 50+by-arm_off, ox+53, 52+by-arm_off, talon)
    rect(img, ox+48, 52+by-arm_off, ox+50, 54+by-arm_off, talon_d)
    rect(img, ox+52, 52+by-arm_off, ox+54, 54+by-arm_off, talon_d)

    # === WEAPON (held in right wing) ===
    rect(img, ox+50, 46+by-arm_off, ox+54, 48+by-arm_off, gun_d)
    rect(img, ox+54, 45+by-arm_off, ox+61, 48+by-arm_off, gun)
    rect(img, ox+54, 45+by-arm_off, ox+61, 46+by-arm_off, (70, 70, 75))
    rect(img, ox+61, 46+by-arm_off, ox+63, 47+by-arm_off, gun_d)
    rect(img, ox+56, 48+by-arm_off, ox+58, 52+by-arm_off, gun_d)
    rect(img, ox+53, 48+by-arm_off, ox+55, 51+by-arm_off, gun_d)
    rect(img, ox+57, 43+by-arm_off, ox+60, 45+by-arm_off, (45, 45, 50))

    # === LEGS ===
    # Left leg
    rect(img, ox+21, 46+by, ox+28, 52+by+leg_off, pants)
    rect(img, ox+21, 46+by, ox+28, 47+by+leg_off, vest_h)
    rect(img, ox+21, 50+by, ox+28, 52+by+leg_off, pants_d)
    rect(img, ox+22, 48+by, ox+25, 50+by+leg_off, pants_d)
    # Right leg
    rect(img, ox+36, 46+by, ox+43, 52+by-leg_off, pants)
    rect(img, ox+36, 46+by, ox+43, 47+by-leg_off, vest_h)
    rect(img, ox+36, 50+by, ox+43, 52+by-leg_off, pants_d)
    rect(img, ox+39, 48+by, ox+42, 50+by-leg_off, pants_d)

    # === BOOTS ===
    rect(img, ox+20, 52+by+leg_off, ox+29, 56+by+leg_off, boot)
    rect(img, ox+20, 52+by+leg_off, ox+29, 53+by+leg_off, boot_h)
    rect(img, ox+20, 55+by+leg_off, ox+29, 56+by+leg_off, (35, 30, 25))
    rect(img, ox+35, 52+by-leg_off, ox+44, 56+by-leg_off, boot)
    rect(img, ox+35, 52+by-leg_off, ox+44, 53+by-leg_off, boot_h)
    rect(img, ox+35, 55+by-leg_off, ox+44, 56+by-leg_off, (35, 30, 25))

    # === TAIL FEATHERS (visible behind) ===
    rect(img, ox+28, 46+by, ox+36, 48+by, feather_brown)
    rect(img, ox+29, 48+by, ox+35, 50+by, feather_dark)


def generate_walk_sheet():
    img = Image.new('RGBA', (256, 64), (0, 0, 0, 0))
    for frame in range(4):
        draw_eagle_soldier(img, ox=frame*64, walk_phase=frame)
    img.save('/Users/zwcn3212/Godot/test1/Unit/eagle_soldier_walk.png')
    print("Generated eagle_soldier_walk.png (256x64, 4 frames)")


def generate_tres():
    tres = '''[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://Unit/eagle_soldier_walk.png" id="1_walk"]

[sub_resource type="AtlasTexture" id="AtlasTexture_frame0"]
atlas = ExtResource("1_walk")
region = Rect2(0, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_frame1"]
atlas = ExtResource("1_walk")
region = Rect2(64, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_frame2"]
atlas = ExtResource("1_walk")
region = Rect2(128, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_frame3"]
atlas = ExtResource("1_walk")
region = Rect2(192, 0, 64, 64)

[resource]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_frame0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_frame1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_frame2")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_frame3")
}],
"loop": true,
"name": &"walk",
"speed": 5.0
}]
'''
    with open('/Users/zwcn3212/Godot/test1/Unit/eagle_soldier_sprites.tres', 'w') as f:
        f.write(tres)
    print("Generated eagle_soldier_sprites.tres")


if __name__ == '__main__':
    generate_walk_sheet()
    generate_tres()
    print("Done!")
