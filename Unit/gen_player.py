#!/usr/bin/env python3
"""Generate detailed chibi Delta Force style player sprites (64x64)"""
from PIL import Image, ImageDraw

def px(img, x, y, color):
    """Set a single pixel"""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def rect(img, x1, y1, x2, y2, color):
    """Fill rectangle"""
    for y in range(y1, y2+1):
        for x in range(x1, x2+1):
            px(img, x, y, color)

def draw_soldier(img, ox=0, walk_phase=0):
    """Draw detailed chibi soldier. walk_phase: 0-3"""
    # Animation
    leg_off = [0, 2, 0, -2][walk_phase % 4]
    arm_off = [0, -1, 0, 1][walk_phase % 4]
    bounce = [0, -1, 0, -1][walk_phase % 4]
    
    # Colors
    helmet = (62, 78, 42)
    helmet_h = (82, 98, 62)
    helmet_d = (42, 55, 28)
    visor = (35, 40, 30)
    skin = (240, 205, 165)
    skin_d = (210, 175, 135)
    skin_l = (250, 220, 185)
    eye_w = (252, 252, 252)
    eye_p = (25, 25, 35)
    eye_h = (255, 255, 255)
    vest = (95, 90, 72)
    vest_d = (72, 68, 52)
    vest_h = (115, 110, 92)
    strap = (55, 50, 40)
    pants = (78, 82, 65)
    pants_d = (58, 62, 45)
    boot = (48, 42, 35)
    boot_h = (68, 62, 52)
    gun = (55, 55, 60)
    gun_d = (38, 38, 42)
    pouch = (105, 95, 72)
    badge = (185, 165, 55)
    hair = (50, 35, 25)
    mouth = (175, 115, 95)
    cheek = (245, 175, 145)
    
    by = bounce
    
    # === HELMET ===
    # Helmet dome
    rect(img, ox+22, 3+by, ox+41, 5+by, helmet_h)
    rect(img, ox+20, 5+by, ox+43, 8+by, helmet)
    rect(img, ox+18, 8+by, ox+45, 12+by, helmet)
    rect(img, ox+17, 12+by, ox+46, 16+by, helmet)
    rect(img, ox+16, 16+by, ox+47, 19+by, helmet_d)
    # Helmet highlight
    rect(img, ox+24, 5+by, ox+30, 7+by, helmet_h)
    rect(img, ox+22, 7+by, ox+26, 10+by, helmet_h)
    # Helmet rim
    rect(img, ox+15, 19+by, ox+48, 21+by, helmet_d)
    # NVG mount on helmet
    rect(img, ox+28, 3+by, ox+35, 5+by, (40, 45, 35))
    rect(img, ox+30, 4+by, ox+33, 5+by, (60, 65, 50))
    
    # === FACE ===
    # Face shape (rounded)
    rect(img, ox+19, 21+by, ox+44, 24+by, skin)
    rect(img, ox+18, 24+by, ox+45, 30+by, skin)
    rect(img, ox+19, 30+by, ox+44, 35+by, skin)
    rect(img, ox+21, 35+by, ox+42, 38+by, skin_d)
    # Face shadow under helmet
    rect(img, ox+19, 21+by, ox+44, 23+by, skin_d)
    # Cheek blush
    rect(img, ox+20, 30+by, ox+23, 33+by, cheek)
    rect(img, ox+40, 30+by, ox+43, 33+by, cheek)
    
    # === EYES (big chibi) ===
    # Left eye white
    rect(img, ox+22, 25+by, ox+29, 31+by, eye_w)
    rect(img, ox+23, 26+by, ox+28, 30+by, eye_w)
    # Left pupil
    rect(img, ox+24, 27+by, ox+27, 30+by, eye_p)
    rect(img, ox+25, 28+by, ox+26, 29+by, eye_h)
    # Left eye outline
    rect(img, ox+22, 25+by, ox+29, 25+by, (40, 35, 30))
    rect(img, ox+22, 31+by, ox+29, 31+by, (40, 35, 30))
    
    # Right eye white
    rect(img, ox+34, 25+by, ox+41, 31+by, eye_w)
    rect(img, ox+35, 26+by, ox+40, 30+by, eye_w)
    # Right pupil
    rect(img, ox+36, 27+by, ox+39, 30+by, eye_p)
    rect(img, ox+37, 28+by, ox+38, 29+by, eye_h)
    # Right eye outline
    rect(img, ox+34, 25+by, ox+41, 25+by, (40, 35, 30))
    rect(img, ox+34, 31+by, ox+41, 31+by, (40, 35, 30))
    
    # Eyebrows
    rect(img, ox+22, 23+by, ox+29, 24+by, hair)
    rect(img, ox+34, 23+by, ox+41, 24+by, hair)
    
    # Nose
    px(img, ox+31, 32+by, skin_d)
    px(img, ox+32, 32+by, skin_d)
    
    # Mouth
    rect(img, ox+29, 34+by, ox+34, 35+by, mouth)
    rect(img, ox+30, 35+by, ox+33, 35+by, (155, 95, 75))
    
    # === NECK ===
    rect(img, ox+28, 38+by, ox+35, 40+by, skin_d)
    
    # === TACTICAL VEST ===
    # Shoulders
    rect(img, ox+16, 40+by, ox+47, 43+by, vest)
    rect(img, ox+16, 40+by, ox+20, 43+by, vest_d)
    rect(img, ox+43, 40+by, ox+47, 43+by, vest_d)
    # Main body
    rect(img, ox+18, 43+by, ox+45, 52+by, vest)
    # Vest shadow
    rect(img, ox+18, 49+by, ox+45, 52+by, vest_d)
    # Vest highlight
    rect(img, ox+20, 43+by, ox+26, 46+by, vest_h)
    # Center zipper
    rect(img, ox+31, 43+by, ox+32, 52+by, strap)
    # Straps
    rect(img, ox+24, 40+by, ox+26, 52+by, strap)
    rect(img, ox+37, 40+by, ox+39, 52+by, strap)
    # Collar
    rect(img, ox+26, 40+by, ox+37, 42+by, vest_h)
    
    # Ammo pouches
    rect(img, ox+19, 45+by, ox+23, 49+by, pouch)
    rect(img, ox+19, 45+by, ox+23, 46+by, (120, 110, 85))
    rect(img, ox+40, 45+by, ox+44, 49+by, pouch)
    rect(img, ox+40, 45+by, ox+44, 46+by, (120, 110, 85))
    # Radio on chest
    rect(img, ox+34, 44+by, ox+38, 48+by, (50, 50, 55))
    rect(img, ox+35, 45+by, ox+37, 47+by, (70, 70, 75))
    # Badge/patch
    rect(img, ox+27, 44+by, ox+30, 47+by, badge)
    rect(img, ox+28, 45+by, ox+29, 46+by, (200, 180, 70))
    
    # === ARMS ===
    # Left arm
    rect(img, ox+12, 42+by+arm_off, ox+16, 50+by+arm_off, vest)
    rect(img, ox+12, 42+by+arm_off, ox+16, 44+by+arm_off, vest_h)
    rect(img, ox+12, 50+by+arm_off, ox+16, 53+by+arm_off, skin)
    rect(img, ox+12, 53+by+arm_off, ox+16, 54+by+arm_off, skin_d)
    # Right arm
    rect(img, ox+47, 42+by-arm_off, ox+51, 50+by-arm_off, vest)
    rect(img, ox+47, 42+by-arm_off, ox+51, 44+by-arm_off, vest_h)
    rect(img, ox+47, 50+by-arm_off, ox+51, 53+by-arm_off, skin)
    rect(img, ox+47, 53+by-arm_off, ox+51, 54+by-arm_off, skin_d)
    
    # === WEAPON (assault rifle) ===
    # Stock
    rect(img, ox+49, 45+by-arm_off, ox+53, 47+by-arm_off, gun_d)
    # Body
    rect(img, ox+53, 44+by-arm_off, ox+60, 47+by-arm_off, gun)
    rect(img, ox+53, 44+by-arm_off, ox+60, 45+by-arm_off, (70, 70, 75))
    # Barrel
    rect(img, ox+60, 45+by-arm_off, ox+63, 46+by-arm_off, gun_d)
    # Magazine
    rect(img, ox+55, 47+by-arm_off, ox+57, 51+by-arm_off, gun_d)
    # Grip
    rect(img, ox+52, 47+by-arm_off, ox+54, 50+by-arm_off, gun_d)
    # Scope
    rect(img, ox+56, 42+by-arm_off, ox+59, 44+by-arm_off, (45, 45, 50))
    rect(img, ox+57, 43+by-arm_off, ox+58, 43+by-arm_off, (80, 80, 85))
    
    # === LEGS ===
    # Left leg
    rect(img, ox+21, 52+by, ox+28, 57+by+leg_off, pants)
    rect(img, ox+21, 52+by, ox+28, 53+by+leg_off, vest_h)
    rect(img, ox+21, 55+by, ox+28, 57+by+leg_off, pants_d)
    # Cargo pocket left
    rect(img, ox+22, 53+by, ox+25, 55+by+leg_off, pants_d)
    # Right leg
    rect(img, ox+35, 52+by, ox+42, 57+by-leg_off, pants)
    rect(img, ox+35, 52+by, ox+42, 53+by-leg_off, vest_h)
    rect(img, ox+35, 55+by, ox+42, 57+by-leg_off, pants_d)
    # Cargo pocket right
    rect(img, ox+38, 53+by, ox+41, 55+by-leg_off, pants_d)
    
    # === BOOTS ===
    # Left boot
    rect(img, ox+20, 57+by+leg_off, ox+29, 61+by+leg_off, boot)
    rect(img, ox+20, 57+by+leg_off, ox+29, 58+by+leg_off, boot_h)
    rect(img, ox+20, 60+by+leg_off, ox+29, 61+by+leg_off, (35, 30, 25))
    # Right boot
    rect(img, ox+34, 57+by-leg_off, ox+43, 61+by-leg_off, boot)
    rect(img, ox+34, 57+by-leg_off, ox+43, 58+by-leg_off, boot_h)
    rect(img, ox+34, 60+by-leg_off, ox+43, 61+by-leg_off, (35, 30, 25))

def generate_static():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw_soldier(img, ox=0, walk_phase=0)
    img.save('/Users/zwcn3212/Godot/test1/Unit/player2.png')
    print("Generated player2.png (64x64)")

def generate_walk_sheet():
    img = Image.new('RGBA', (256, 64), (0, 0, 0, 0))
    for frame in range(4):
        draw_soldier(img, ox=frame*64, walk_phase=frame)
    img.save('/Users/zwcn3212/Godot/test1/Unit/player2_walk.png')
    print("Generated player2_walk.png (256x64, 4 frames)")

def generate_tres():
    tres = '''[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://Unit/player2_walk.png" id="1_walk"]

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
    with open('/Users/zwcn3212/Godot/test1/Unit/player2_sprites.tres', 'w') as f:
        f.write(tres)
    print("Generated player2_sprites.tres")

if __name__ == '__main__':
    generate_static()
    generate_walk_sheet()
    generate_tres()
    print("Done!")
