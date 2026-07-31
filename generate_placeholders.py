# generate_placeholders.py
# 生成像素风格占位美术资源
# 运行: python generate_placeholders.py

from PIL import Image
import os

ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "art")

def create_pixel_sprite(width, height, pixels_func):
    """创建一个像素精灵，pixels_func(x, y) 返回 (r, g, b, a)"""
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for y in range(height):
        for x in range(width):
            color = pixels_func(x, y)
            if color is not None:
                img.putpixel((x, y), color)
    return img

# ============================================================
# 战士角色精灵 (64x64, 像素风格)
# ============================================================
def warrior_pixels(x, y):
    # 头
    if 24 <= x <= 40 and 4 <= y <= 16:
        return (220, 180, 140, 255)  # 肤色
    # 头发
    if 20 <= x <= 44 and 2 <= y <= 12:
        if x % 4 < 2 and y % 4 < 2:
            return (80, 50, 20, 255)  # 深棕
    # 身体（盔甲）
    if 20 <= x <= 44 and 16 <= y <= 36:
        if x <= 30 or x >= 34:
            return (120, 120, 130, 255)  # 铁甲灰
        else:
            return (100, 100, 110, 255)
    # 手臂
    if 12 <= x <= 20 and 18 <= y <= 32:
        return (120, 120, 130, 255)
    if 44 <= x <= 52 and 18 <= y <= 32:
        return (120, 120, 130, 255)
    # 腿
    if 22 <= x <= 30 and 36 <= y <= 52:
        return (80, 70, 65, 255)  # 深色裤
    if 34 <= x <= 42 and 36 <= y <= 52:
        return (80, 70, 65, 255)
    # 剑（右手）
    if 46 <= x <= 52 and 12 <= y <= 44:
        if x >= 48:
            return (200, 200, 210, 255)  # 剑刃
        else:
            return (150, 120, 60, 255)  # 剑柄
    # 盾（左手，简化）
    if 8 <= x <= 14 and 14 <= y <= 30:
        return (100, 80, 40, 255)  # 棕色盾
    return None

# ============================================================
# 绿色史莱姆精灵 (48x32)
# ============================================================
def slime_green_pixels(x, y):
    cx, cy = 24, 20
    dist = ((x - cx) ** 2 + (y - cy) ** 2 * 1.5) ** 0.5
    
    # 主体
    if dist < 16:
        # 渐变绿色
        shade = int(200 - dist * 4)
        shade = max(80, min(220, shade))
        return (30, shade, 40, 255)
    
    # 眼睛
    if (18 <= x <= 22 or 26 <= x <= 30) and 10 <= y <= 16:
        return (255, 255, 255, 255)
    # 瞳孔
    if (19 <= x <= 21 or 27 <= x <= 29) and 11 <= y <= 15:
        return (0, 0, 0, 255)
    
    return None

# ============================================================
# 红色史莱姆精灵 (48x32)
# ============================================================
def slime_red_pixels(x, y):
    cx, cy = 24, 20
    dist = ((x - cx) ** 2 + (y - cy) ** 2 * 1.5) ** 0.5
    
    if dist < 16:
        shade = int(200 - dist * 4)
        shade = max(80, min(220, shade))
        return (shade, 30, 30, 255)
    
    if (18 <= x <= 22 or 26 <= x <= 30) and 10 <= y <= 16:
        return (255, 255, 255, 255)
    if (19 <= x <= 21 or 27 <= x <= 29) and 11 <= y <= 15:
        return (0, 0, 0, 255)
    return None

# ============================================================
# 骷髅兵精灵 (48x56)
# ============================================================
def skeleton_pixels(x, y):
    # 头骨
    head_r = 9
    cx, cy = 24, 12
    dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
    if dist < head_r:
        return (230, 225, 210, 255)
    # 眼窝
    if (20 <= x <= 22 or 26 <= x <= 28) and 9 <= y <= 12:
        return (30, 30, 30, 255)
    # 身体
    if 18 <= x <= 30 and 20 <= y <= 36:
        return (210, 205, 190, 255)
    # 肋骨线
    if 20 <= x <= 28 and y in [24, 28, 32]:
        if (x - y) % 4 < 2:
            return (180, 175, 160, 255)
    # 腿
    if 18 <= x <= 24 and 36 <= y <= 52:
        return (210, 205, 190, 255)
    if 24 <= x <= 30 and 36 <= y <= 52:
        return (210, 205, 190, 255)
    # 手臂
    if 10 <= x <= 18 and 22 <= y <= 34:
        return (210, 205, 190, 255)
    if 30 <= x <= 38 and 22 <= y <= 34:
        return (210, 205, 190, 255)
    return None

# ============================================================
# 生成所有资源
# ============================================================
def generate_all():
    os.makedirs(f"{ASSETS}/characters", exist_ok=True)
    os.makedirs(f"{ASSETS}/enemies", exist_ok=True)
    
    # 战士
    warrior = create_pixel_sprite(64, 64, warrior_pixels)
    # 放大4倍以符合像素风格（最近邻插值）
    warrior = warrior.resize((256, 256), Image.NEAREST)
    warrior.save(f"{ASSETS}/characters/warrior.png")
    print("创建: warrior.png")
    
    # 绿色史莱姆
    slime_g = create_pixel_sprite(48, 32, slime_green_pixels)
    slime_g = slime_g.resize((192, 128), Image.NEAREST)
    slime_g.save(f"{ASSETS}/enemies/slime_green.png")
    print("创建: slime_green.png")
    
    # 红色史莱姆
    slime_r = create_pixel_sprite(48, 32, slime_red_pixels)
    slime_r = slime_r.resize((192, 128), Image.NEAREST)
    slime_r.save(f"{ASSETS}/enemies/slime_red.png")
    print("创建: slime_red.png")
    
    # 骷髅兵
    skeleton = create_pixel_sprite(48, 56, skeleton_pixels)
    skeleton = skeleton.resize((192, 224), Image.NEAREST)
    skeleton.save(f"{ASSETS}/enemies/skeleton.png")
    print("创建: skeleton.png")
    
    # 攻击意图图标 (16x16 → 64x64)
    attack_icon = create_pixel_sprite(16, 16, lambda x, y: 
        (220, 60, 60, 255) if (7 <= x <= 8 and 2 <= y <= 13) or (2 <= x <= 13 and 7 <= y <= 8) 
        else None)
    attack_icon = attack_icon.resize((64, 64), Image.NEAREST)
    attack_icon.save(f"{ASSETS}/ui/intent_attack.png")
    print("创建: intent_attack.png")
    
    # 防御意图图标
    defend_icon = create_pixel_sprite(16, 16, lambda x, y:
        (60, 180, 220, 255) if (4 <= x <= 11 and 2 <= y <= 13) 
        else None)
    defend_icon = defend_icon.resize((64, 64), Image.NEAREST)
    defend_icon.save(f"{ASSETS}/ui/intent_defend.png")
    print("创建: intent_defend.png")
    
    print("\n所有占位资源已生成！")

if __name__ == "__main__":
    generate_all()
