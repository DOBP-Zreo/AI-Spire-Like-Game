# regenerate_assets.py
# 生成全套像素风格占位美术资源
# 运行: python regenerate_assets.py
# 做好后用你自己的美术资源覆盖 assets/art/ 下对应文件即可

from PIL import Image, ImageDraw
import os, math

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "art")

def save(img, path, scale=4):
    """放大并保存为像素风格"""
    img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(os.path.join(BASE, path))
    print("  ✓", path)

# ──────────────────── 工具函数 ────────────────────
def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def rect(draw, x, y, w, h, color):
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)

def circle(draw, cx, cy, r, color):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

def text(img, s, y, color=(255, 255, 255)):
    """简易像素文字（3x5 字体）"""
    font_3x5 = {
        'A': [(0,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(0,3),(2,3),(0,4),(2,4)],
        'B': [(0,0),(1,0),(0,1),(2,1),(0,2),(1,2),(0,3),(2,3),(0,4),(1,4)],
        'C': [(1,0),(2,0),(0,1),(0,2),(0,3),(1,4),(2,4)],
        'D': [(0,0),(1,0),(0,1),(2,1),(0,2),(2,2),(0,3),(2,3),(0,4),(1,4)],
        'E': [(0,0),(1,0),(2,0),(0,1),(0,2),(1,2),(2,2),(0,3),(0,4),(1,4),(2,4)],
        'F': [(0,0),(1,0),(2,0),(0,1),(0,2),(1,2),(2,2),(0,3),(0,4)],
        'G': [(1,0),(2,0),(0,1),(0,2),(0,3),(2,3),(0,4),(1,4),(2,4)],
        'H': [(0,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(0,3),(2,3),(0,4),(2,4)],
        'I': [(0,0),(1,0),(2,0),(1,1),(1,2),(1,3),(0,4),(1,4),(2,4)],
        'K': [(0,0),(2,0),(0,1),(1,1),(0,2),(0,3),(1,3),(0,4),(2,4)],
        'L': [(0,0),(0,1),(0,2),(0,3),(0,4),(1,4),(2,4)],
        'M': [(0,0),(2,0),(0,1),(1,1),(2,1),(0,2),(2,2),(0,3),(2,3),(0,4),(2,4)],
        'N': [(0,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(0,3),(2,3),(0,4),(2,4)],
        'P': [(0,0),(1,0),(0,1),(2,1),(0,2),(1,2),(0,3),(0,4)],
        'R': [(0,0),(1,0),(0,1),(2,1),(0,2),(1,2),(0,3),(1,3),(0,4),(2,4)],
        'S': [(1,0),(2,0),(0,1),(1,2),(2,2),(2,3),(0,4),(1,4)],
        'T': [(0,0),(1,0),(2,0),(1,1),(1,2),(1,3),(1,4)],
        'U': [(0,0),(2,0),(0,1),(2,1),(0,2),(2,2),(0,3),(2,3),(0,4),(1,4),(2,4)],
        'V': [(0,0),(2,0),(0,1),(2,1),(0,2),(2,2),(0,3),(2,3),(1,4)],
        'W': [(0,0),(2,0),(0,1),(2,1),(0,2),(2,2),(0,3),(1,3),(2,3),(0,4),(2,4)],
        'X': [(0,0),(2,0),(1,1),(1,2),(1,3),(0,4),(2,4)],
        'Y': [(0,0),(2,0),(1,1),(1,2),(1,3),(1,4)],
        'Z': [(0,0),(1,0),(2,0),(2,1),(1,2),(0,3),(0,4),(1,4),(2,4)],
        '.': [(1,4)],
        '!': [(1,0),(1,1),(1,3),(1,4)],
        '+': [(1,1),(1,2),(0,2),(2,2),(1,3)],
        '-': [(0,2),(1,2),(2,2)],
        '0': [(0,0),(1,0),(2,0),(0,1),(2,1),(0,2),(2,2),(0,3),(2,3),(0,4),(1,4),(2,4)],
        '1': [(1,0),(0,1),(1,1),(1,2),(1,3),(0,4),(1,4),(2,4)],
        '2': [(0,0),(1,0),(2,0),(2,1),(1,2),(0,3),(0,4),(1,4),(2,4)],
        '3': [(0,0),(1,0),(2,0),(2,1),(1,2),(2,3),(0,4),(1,4),(2,4)],
        '4': [(0,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(2,3),(2,4)],
        '5': [(0,0),(1,0),(2,0),(0,1),(0,2),(1,2),(2,2),(2,3),(0,4),(1,4),(2,4)],
        '6': [(0,0),(1,0),(2,0),(0,1),(0,2),(1,2),(2,2),(0,3),(2,3),(0,4),(1,4),(2,4)],
        '7': [(0,0),(1,0),(2,0),(2,1),(2,2),(2,3),(2,4)],
        '8': [(0,0),(1,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(0,3),(2,3),(0,4),(1,4),(2,4)],
        '9': [(0,0),(1,0),(2,0),(0,1),(2,1),(0,2),(1,2),(2,2),(2,3),(0,4),(1,4),(2,4)],
        ':': [(1,1),(1,3)],
        ' ': [],
        '/': [(2,0),(2,1),(1,2),(1,3),(0,4)],
    }
    cx = max(0, (img.width - len(s) * 4) // 2)
    for i, ch in enumerate(s):
        ch_upper = ch.upper()
        if ch_upper in font_3x5:
            for px, py in font_3x5[ch_upper]:
                if 0 <= cx + i * 4 + px < img.width and 0 <= y + py < img.height:
                    img.putpixel((cx + i * 4 + px, y + py), color)

# ──────────────────── 背景 ────────────────────
def gen_backgrounds():
    print("\n[背景]")
    # 战斗背景
    img = new(320, 180)
    draw = ImageDraw.Draw(img)
    for y in range(180):
        shade = int(15 + y * 0.08)
        draw.line([(0, y), (320, y)], fill=(shade, shade, shade + 5, 255))
    # 地面砖块
    for x in range(0, 320, 20):
        for y in range(130, 180, 10):
            shade = int(40 + (x + y) % 10)
            rect(draw, x, y, 18, 8, (shade, shade - 10, shade - 20, 255))
    save(img, "backgrounds/battle_bg.png")
    
    # 地图背景
    img = new(320, 180)
    draw = ImageDraw.Draw(img)
    for y in range(180):
        shade = int(10 + (y % 20) * 0.5)
        draw.line([(0, y), (320, y)], fill=(shade, shade, shade + 8, 255))
    # 网格点
    for x in range(20, 320, 30):
        for y in range(20, 180, 25):
            img.putpixel((x, y), (40, 40, 50, 128))
    save(img, "backgrounds/map_bg.png")
    
    # 菜单背景
    img = new(320, 180)
    draw = ImageDraw.Draw(img)
    for y in range(180):
        shade = int(8 + math.sin(y * 0.03) * 4)
        draw.line([(0, y), (320, y)], fill=(shade, shade, shade + 4, 255))
    save(img, "backgrounds/menu_bg.png")

# ──────────────────── 卡牌 ────────────────────
def gen_cards():
    print("\n[卡牌]")
    w, h = 30, 45
    
    # 攻击牌背景（红色调）
    img = new(w, h)
    draw = ImageDraw.Draw(img)
    rect(draw, 0, 0, w, h, (40, 15, 15, 255))
    rect(draw, 0, 0, 2, h, (180, 50, 50, 255))
    # 费用圆
    circle(draw, 7, 7, 5, (30, 20, 25, 255))
    save(img, "cards/card_attack_bg.png")
    
    # 技能牌背景（蓝色调）
    img = new(w, h)
    draw = ImageDraw.Draw(img)
    rect(draw, 0, 0, w, h, (15, 20, 45, 255))
    rect(draw, 0, 0, 2, h, (50, 80, 180, 255))
    circle(draw, 7, 7, 5, (20, 25, 35, 255))
    save(img, "cards/card_skill_bg.png")
    
    # 能力牌背景（黄色调）
    img = new(w, h)
    draw = ImageDraw.Draw(img)
    rect(draw, 0, 0, w, h, (45, 35, 10, 255))
    rect(draw, 0, 0, 2, h, (180, 150, 50, 255))
    circle(draw, 7, 7, 5, (35, 30, 15, 255))
    save(img, "cards/card_power_bg.png")

# ──────────────────── 角色 — 战士 ────────────────────
def gen_warrior():
    print("\n[战士]")
    w, h = 16, 16
    
    def draw_warrior(img, frame):
        draw = ImageDraw.Draw(img)
        # 头盔
        rect(draw, 5, 1, 7, 4, (120, 120, 130, 255))
        rect(draw, 4, 0, 9, 2, (140, 140, 150, 255))
        # 脸
        rect(draw, 6, 3, 5, 2, (220, 180, 140, 255))
        # 身体
        rect(draw, 5, 5, 7, 5, (100, 100, 110, 255))
        rect(draw, 6, 5, 5, 1, (140, 140, 150, 255))
        # 剑
        rect(draw, 13, 1, 2, 10, (200, 200, 210, 255))
        rect(draw, 12, 8, 4, 2, (150, 120, 60, 255))
        # 盾
        rect(draw, 0, 4, 4, 6, (100, 80, 40, 255))
        # 腿
        rect(draw, 6, 10, 3, 5, (70, 60, 55, 255))
        rect(draw, 9, 10, 3, 5, (70, 60, 55, 255))
    
    img = new(w, h)
    draw_warrior(img, 0)
    save(img, "characters/warrior/warrior_idle.png")
    
    img = new(w, h)
    draw_warrior(img, 1)
    # 攻击姿态：剑举高
    draw = ImageDraw.Draw(img)
    rect(draw, 13, -2, 2, 4, (200, 200, 210, 255))
    save(img, "characters/warrior/warrior_attack.png")
    
    img = new(w, h)
    draw_warrior(img, 2)
    # 受伤：红闪
    for x in range(w):
        for y in range(h):
            if img.getpixel((x, y))[3] > 0:
                r, g, b, a = img.getpixel((x, y))
                img.putpixel((x, y), (min(255, r + 80), g, b, a))
    save(img, "characters/warrior/warrior_hurt.png")

# ──────────────────── 敌人 ────────────────────
def gen_enemies():
    print("\n[敌人]")
    
    # 绿色史莱姆
    img = new(12, 8)
    draw = ImageDraw.Draw(img)
    for y in range(8):
        for x in range(12):
            dist = ((x - 6) ** 2 + (y - 5) ** 2 * 2) ** 0.5
            if dist < 5:
                shade = int(200 - dist * 12)
                img.putpixel((x, y), (20, max(60, min(220, shade)), 30, 255))
    img.putpixel((3, 2), (255, 255, 255, 255))
    img.putpixel((8, 2), (255, 255, 255, 255))
    img.putpixel((3, 3), (0, 0, 0, 255))
    img.putpixel((8, 3), (0, 0, 0, 255))
    save(img, "enemies/slime_green.png")
    
    # 红色史莱姆
    img = new(12, 8)
    for y in range(8):
        for x in range(12):
            dist = ((x - 6) ** 2 + (y - 5) ** 2 * 2) ** 0.5
            if dist < 5:
                shade = int(200 - dist * 12)
                img.putpixel((x, y), (max(60, min(220, shade)), 20, 20, 255))
    img.putpixel((3, 2), (255, 255, 255, 255))
    img.putpixel((8, 2), (255, 255, 255, 255))
    img.putpixel((3, 3), (0, 0, 0, 255))
    img.putpixel((8, 3), (0, 0, 0, 255))
    save(img, "enemies/slime_red.png")
    
    # 骷髅兵
    img = new(12, 14)
    draw = ImageDraw.Draw(img)
    circle(draw, 6, 4, 3, (230, 225, 210, 255))
    img.putpixel((5, 3), (30, 30, 30, 255))
    img.putpixel((7, 3), (30, 30, 30, 255))
    rect(draw, 4, 7, 4, 4, (210, 205, 190, 255))
    rect(draw, 3, 11, 3, 3, (210, 205, 190, 255))
    rect(draw, 6, 11, 3, 3, (210, 205, 190, 255))
    save(img, "enemies/skeleton.png")
    
    # 火焰元素
    img = new(12, 12)
    for y in range(12):
        for x in range(12):
            dist = ((x - 6) ** 2 + (y - 6) ** 2) ** 0.5
            if dist < 5:
                r = 255 - int(dist * 30)
                g = max(0, 200 - int(dist * 40))
                img.putpixel((x, y), (r, g, 20, 255))
    img.putpixel((5, 5), (255, 255, 200, 255))
    img.putpixel((7, 5), (255, 255, 200, 255))
    img.putpixel((5, 6), (200, 150, 0, 255))
    img.putpixel((7, 6), (200, 150, 0, 255))
    save(img, "enemies/fire_elemental.png")
    
    # 哥布林队长
    img = new(16, 20)
    draw = ImageDraw.Draw(img)
    circle(draw, 8, 4, 4, (100, 180, 100, 255))
    img.putpixel((6, 3), (255, 255, 255, 255))
    img.putpixel((10, 3), (255, 255, 255, 255))
    img.putpixel((6, 4), (0, 0, 0, 255))
    img.putpixel((10, 4), (0, 0, 0, 255))
    rect(draw, 5, 8, 6, 6, (80, 140, 80, 255))
    rect(draw, 4, 14, 4, 5, (60, 100, 60, 255))
    rect(draw, 8, 14, 4, 5, (60, 100, 60, 255))
    # 小皇冠
    rect(draw, 6, 0, 4, 2, (220, 200, 50, 255))
    save(img, "enemies/goblin_captain.png")
    
    # 史莱姆王
    img = new(24, 16)
    for y in range(16):
        for x in range(24):
            dist = ((x - 12) ** 2 * 0.6 + (y - 10) ** 2) ** 0.5
            if dist < 10:
                shade = int(220 - dist * 8)
                img.putpixel((x, y), (max(40, min(200, shade)), max(20, min(100, shade - 80)), shade - 40, 255))
    img.putpixel((8, 4), (255, 255, 255, 255))
    img.putpixel((16, 4), (255, 255, 255, 255))
    img.putpixel((9, 5), (0, 0, 0, 255))
    img.putpixel((17, 5), (0, 0, 0, 255))
    # 王冠
    draw = ImageDraw.Draw(img)
    rect(draw, 9, 0, 6, 3, (220, 200, 50, 255))
    save(img, "enemies/slime_king.png")

# ──────────────────── UI 图标 ────────────────────
def gen_ui_icons():
    print("\n[UI 图标]")
    s = 8
    
    # HP 图标（红心）
    img = new(s, s)
    img.putpixel((3, 1), (220, 50, 50, 255))
    img.putpixel((4, 1), (220, 50, 50, 255))
    for x in [2, 3, 4, 5]: img.putpixel((x, 2), (220, 50, 50, 255))
    for x in [1, 2, 3, 4, 5, 6]: img.putpixel((x, 3), (220, 50, 50, 255))
    for x in [1, 2, 3, 4, 5, 6]: img.putpixel((x, 4), (220, 50, 50, 255))
    for x in [2, 3, 4, 5]: img.putpixel((x, 5), (220, 50, 50, 255))
    img.putpixel((3, 6), (220, 50, 50, 255))
    save(img, "ui/icons/hp_icon.png")
    
    # 能量图标（黄色闪电）
    img = new(s, s)
    for x in [1, 2, 3, 4, 5, 6]: img.putpixel((x, 2), (230, 200, 30, 255))
    for x in range(8): img.putpixel((x, 4), (230, 200, 30, 255))
    for x in [1, 2, 3, 4, 5, 6]: img.putpixel((x, 6), (230, 200, 30, 255))
    save(img, "ui/icons/energy_icon.png")
    
    # 金币图标（金圈）
    img = new(s, s)
    for y in range(8):
        for x in range(8):
            if 2 <= x <= 5 and 2 <= y <= 5:
                img.putpixel((x, y), (230, 190, 20, 255))
    img.putpixel((3, 3), (200, 160, 10, 255))
    save(img, "ui/icons/gold_icon.png")
    
    # 格挡图标（蓝盾）
    img = new(s, s)
    draw = ImageDraw.Draw(img)
    rect(draw, 3, 1, 3, 6, (60, 160, 220, 255))
    rect(draw, 1, 3, 7, 2, (60, 160, 220, 255))
    save(img, "ui/icons/block_icon.png")
    
    # 攻击意图
    img = new(s, s)
    draw = ImageDraw.Draw(img)
    rect(draw, 3, 0, 2, 7, (220, 50, 50, 255))
    rect(draw, 0, 3, 8, 2, (220, 50, 50, 255))
    save(img, "ui/intents/intent_attack.png")
    
    # 防御意图
    img = new(s, s)
    draw = ImageDraw.Draw(img)
    rect(draw, 1, 1, 6, 6, (50, 160, 220, 255))
    save(img, "ui/intents/intent_defend.png")
    
    # 强化意图
    img = new(s, s)
    draw = ImageDraw.Draw(img)
    rect(draw, 3, 1, 2, 6, (50, 200, 50, 255))
    rect(draw, 1, 0, 6, 2, (50, 200, 50, 255))
    save(img, "ui/intents/intent_buff.png")
    
    # 减益意图
    img = new(s, s)
    draw = ImageDraw.Draw(img)
    rect(draw, 3, 1, 2, 6, (180, 50, 200, 255))
    rect(draw, 1, 6, 6, 2, (180, 50, 200, 255))
    save(img, "ui/intents/intent_debuff.png")

# ──────────────────── 地图节点图标 ────────────────────
def gen_map_nodes():
    print("\n[地图节点]")
    s = 10
    nodes = [
        ("battle",   (180, 50, 50)),
        ("elite",    (200, 120, 20)),
        ("boss",     (150, 20, 20)),
        ("shop",     (50, 140, 200)),
        ("rest",     (60, 170, 60)),
        ("treasure", (200, 180, 40)),
        ("event",    (150, 60, 200)),
    ]
    for name, color in nodes:
        img = new(s, s)
        draw = ImageDraw.Draw(img)
        rect(draw, 1, 1, s - 2, s - 2, color)
        # 角高光
        rect(draw, 1, 1, 3, 1, tuple(min(255, c + 60) for c in color) + (255,))
        rect(draw, 1, 1, 1, 3, tuple(min(255, c + 60) for c in color) + (255,))
        save(img, f"ui/map_nodes/node_{name}.png")

# ──────────────────── 主函数 ────────────────────
def main():
    print("生成像素占位美术资源...\n")
    
    os.makedirs(os.path.join(BASE, "backgrounds"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "cards"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "characters/warrior"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "enemies"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "ui/icons"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "ui/intents"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "ui/map_nodes"), exist_ok=True)
    
    gen_backgrounds()
    gen_cards()
    gen_warrior()
    gen_enemies()
    gen_ui_icons()
    gen_map_nodes()
    
    print("\n全部完成！覆盖 assets/art/ 下同名文件即可替换美术。")

if __name__ == "__main__":
    main()
