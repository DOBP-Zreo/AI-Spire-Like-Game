import os, math
from PIL import Image

BASE = 'E:/WorkBuddy_Space/godot_demo/Spire_Like/spirelike'

def save(img, path):
    img.save(path)

# ============================================================
# 卡牌插图 90x60
# ============================================================
W, H = 90, 60
card_colors = {'attack':(220,60,50), 'skill':(60,140,230), 'power':(210,175,40)}

card_designs = {}

# --- 挥砍 (strike) - diagonal sword slash ---
def _strike():
    img = Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    c=(220,60,50)
    # Blade diagonal
    for i in range(20):
        for wd in range(-3,4):
            x, y = 8+i*4+wd, 50-i*2
            if 0<=x<W and 0<=y<H: px[x,y]=(min(255,180+i),min(255,40),min(255,20),255)
    for x in range(5,11):
        for y in range(44,56): px[x,y]=(180,140,60,255)  # hilt
    for x in range(15,25):
        for y in range(10,20): px[x,y]=(255,255,220,180)  # flash
    return img

# --- 守势 (defend) - shield ---
def _defend():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    c=(60,140,230)
    # Shield shape
    for y2 in range(4,56):
        w=18-int(abs(y2-30)/2.5)+3
        for x2 in range(45-w,45+w):
            if 0<=x2<W: px[x2,y2]=(min(255,50+x2),min(255,110),min(255,200),220)
    # Border
    for y2 in range(4,56):
        w=18-int(abs(y2-30)/2.5)+3
        if 0<=45-w<W: px[45-w,y2]=(180,210,255,255)
        if 0<=45+w<W: px[45+w,y2]=(180,210,255,255)
    # Cross
    for x2 in range(35,55): px[x2,28]=(255,255,255,255); px[x2,32]=(255,255,255,255)
    for y2 in range(18,42): px[45,y2]=(255,255,255,255)
    return img

# --- 猛劈 (heavy_strike) ---
def _heavy():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Big downward blade
    for y2 in range(5,50):
        w=max(2,30-y2//2)
        for x2 in range(45-w,45+w):
            if 0<=x2<W: px[x2,y2]=(220,50,30,min(255,150+y2*2))
    # Edge highlight
    for y2 in range(5,45):
        if 0<=45-32+y2//2<W: px[45-30+y2//2,y2]=(255,180,160,200)
    # Impact lines bottom
    for i in range(6):
        for x2 in range(20+i*8,28+i*8):
            for y2 in range(45+i,48+i):
                if 0<=x2<W and 0<=y2<H: px[x2,y2]=(255,200,100,200)
    return img

# --- 柄击 (pommel_strike) ---
def _pommel():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Blade top (thin)
    for x2 in range(38,52):
        for y2 in range(4,22): px[x2,y2]=(200,180,140,255)
    for x2 in range(40,50):
        for y2 in range(2,6): px[x2,y2]=(240,220,180,255)
    # Guard
    for x2 in range(28,62):
        for y2 in range(20,28): px[x2,y2]=(160,120,40,255)
    # Handle
    for x2 in range(40,50):
        for y2 in range(26,40): px[x2,y2]=(100,60,20,255)
    # Pommel sphere
    for x2 in range(35,55):
        for y2 in range(38,50):
            if (x2-45)**2+(y2-44)**2<60: px[x2,y2]=(180,140,60,255)
    # Impact spark
    for x2 in range(40,50):
        for y2 in range(14,18): px[x2,y2]=(255,255,200,255)
    return img

# --- 突进 (dash) ---
def _dash():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Figure silhouette
    for x2 in range(55,80):
        for y2 in range(10,50):
            if (x2-67)**2//3+(y2-30)**2//4<40: px[x2,y2]=(200,60,50,220)
    # Head
    for x2 in range(70,82):
        for y2 in range(5,18):
            if (x2-75)**2+(y2-12)**2<30: px[x2,y2]=(220,80,60,255)
    # Dash lines behind
    for i in range(5):
        for x2 in range(5+i*12,12+i*12):
            for y2 in range(25,35): px[x2,y2]=(180,200,255,200-i*30)
    return img

# --- 坚壁 (iron_wall) ---
def _wall():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Brick wall
    for row_y in range(2,58,10):
        for col_x in range(4,86,9):
            for dx in range(7):
                for dy in range(7):
                    x2,y2=col_x+dx,row_y+dy
                    if 0<=x2<W and 0<=y2<H: px[x2,y2]=(80,100,130,220)
    # Mortar lines
    for y2 in range(6,58,10):
        for x2 in range(2,88): px[x2,y2]=(40,50,60,255)
    for x2 in range(4,86,9):
        for y2 in range(2,58): px[x2,y2]=(40,50,60,255)
    # Shine
    for x2 in range(20,30):
        for y2 in range(20,30): px[x2,y2]=(160,180,200,150)
    return img

# --- 裂地斩 (shock_strike) ---
def _shock():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Ground crack zigzag
    for x2 in range(4,86):
        y2=35+int(6*math.sin(x2/4)+3*math.sin(x2/1.5))
        for dy in range(-3,4):
            if 0<=y2+dy<H: px[x2,y2+dy]=(180,80,40,240)
    # Energy lines
    for i in range(8):
        y2=20+int(6*math.sin((x2+i)*0.8)) 
        for x2 in range(8,82):
            y2=28+int(4*math.sin(x2/3+i))
            if 0<=y2<H: px[x2,y2]=(255,200,80,180)
    # Impact center
    for x2 in range(38,52):
        for y2 in range(25,45):
            if (x2-45)**2+(y2-35)**2<60: px[x2,y2]=(255,220,100,200)
    return img

# --- 绝杀 (fatal_blow) ---
def _fatal():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Background burst
    for x2 in range(8,82):
        for y2 in range(4,56):
            if (x2-45)**2/2+(y2-30)**2/3<120: px[x2,y2]=(40,5,5,200)
    # X cross
    for i in range(18):
        x2=20+i*3; y2=15+i*2
        for dx in range(-2,3):
            for dy in range(-2,3):
                if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(255,50,50,255)
        x2=68-i*3; y2=15+i*2
        for dx in range(-2,3):
            for dy in range(-2,3):
                if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(255,50,50,255)
    # Skull center
    for x2 in range(35,55):
        for y2 in range(22,45):
            if (x2-45)**2+(y2-35)**2<50: px[x2,y2]=(200,180,150,255)
    px[41,33]=(30,20,20,255); px[49,33]=(30,20,20,255)  # eyes
    return img

# --- 焚焰 (burn) ---
def _burn():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Flame body
    for x2 in range(10,80):
        for y2 in range(2,58):
            d=abs(x2-45)/1.5+abs(y2-30)/2
            if d<25: px[x2,y2]=(255,min(200,140+int(y2)),min(150,20+int(y2/2)),220)
    # Inner bright
    for x2 in range(25,65):
        for y2 in range(10,40):
            if (x2-45)**2+(y2-28)**2<150: px[x2,y2]=(255,230,100,255)
    # Core white
    for x2 in range(35,55):
        for y2 in range(18,32):
            if (x2-45)**2+(y2-25)**2<40: px[x2,y2]=(255,255,240,255)
    # Smoke wisps top
    for x2 in range(20,70):
        for y2 in range(2,12):
            if (x2-45)**2/4+(y2-8)**2<15: px[x2,y2]=(120,100,130,120)
    return img

# --- 战吼 (battle_cry) ---
def _cry():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Sound waves
    for ring in range(4):
        r2=200-(ring*40)
        for x2 in range(10,80):
            for y2 in range(5,55):
                if abs((x2-45)**2+(y2-25)**2-r2)<20: px[x2,y2]=(200,170,30,min(200,180-ring*40))
    # Center figure head
    for x2 in range(30,60):
        for y2 in range(5,40):
            if (x2-40)**2/2+(y2-18)**2/2<50: px[x2,y2]=(220,190,40,255)
    # Eyes
    for x2 in range(34,40): px[x2,14]=(255,255,255,255)
    for x2 in range(44,50): px[x2,14]=(255,255,255,255)
    # Mouth shout
    for x2 in range(36,48):
        for y2 in range(22,28): px[x2,y2]=(60,20,20,255)
    return img

# --- 横扫 (cleave) ---
def _cleave():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Wide horizontal blade
    for y2 in range(18,42):
        for x2 in range(4,86): px[x2,y2]=(200,55,40,220)
    # Edge highlight
    for x2 in range(4,86): px[x2,18]=(255,200,180,255)
    # Slash trail
    for x2 in range(10,80):
        for y2 in range(12,48):
            if (y2-30)**2<15 and abs(x2-45)<35: px[x2,y2]=(255,150,100,150)
    return img

# --- 连斩 (twin_strike) ---
def _twin():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    for off in [0,14]:
        for i in range(14):
            x2=8+off+i*4; y2=48-i*3
            for dx in range(-3,4):
                for dy in range(-2,3):
                    if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(200,55,40,240)
        # Sparks for each slash
        for x2 in range(35+off,45+off):
            for y2 in range(5,10): px[x2,y2]=(255,255,200,200)
    return img

# --- 血祭斩 (hemokinesis) ---
def _blood():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Blood blade
    for i in range(16):
        x2=10+i*4; y2=46-i*2
        for dx in range(-4,5):
            for dy in range(-3,4):
                if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(180,25,25,240)
    # Blood drips
    for x2 in [20,35,50,65]:
        for y2 in range(30,52): px[x2,y2]=(160,15,15,200)
    # Dark aura
    for x2 in range(8,82):
        for y2 in range(4,56):
            if (x2-45)**2/3+(y2-30)**2/5<80: px[x2,y2]=(40,5,5,100)
    return img

# --- 轻蔑 (shrug_off) ---
def _shrug():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Shield-like upper shape
    for x2 in range(15,75):
        for y2 in range(5,30):
            if (x2-45)**2/4+(y2-18)**2/3<60: px[x2,y2]=(60,130,220,220)
    # Armored body
    for x2 in range(20,70):
        for y2 in range(28,50): px[x2,y2]=(40,80,160,230)
    # Cross line armor detail
    for x2 in range(25,65): px[x2,38]=(120,170,240,255)
    for y2 in range(30,50): px[45,y2]=(120,170,240,255)
    return img

# --- 魔化 (demon_form) ---
def _demon():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Dark aura
    for x2 in range(5,85):
        for y2 in range(2,58):
            d=abs(x2-45)+abs(y2-30)
            v=max(0,80-d)
            if v>0: px[x2,y2]=(max(0,80-d//2),10,max(0,80-d//2),v*3)
    # Demon face silhouette
    for x2 in range(25,65):
        for y2 in range(8,42):
            if (x2-45)**2+(y2-28)**2<180: px[x2,y2]=(180,40,180,220)
    # Horns
    for x2 in range(28,42): px[x2,16-(x2-35)]=(160,20,160,255)
    for x2 in range(48,62): px[x2,16-(55-x2)]=(160,20,160,255)
    # Glowing eyes
    for x2 in range(37,43): px[x2,22]=(255,80,80,255)
    for x2 in range(47,53): px[x2,22]=(255,80,80,255)
    return img

# --- 幻影甲 (ghostly_armor) ---
def _ghost():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Translucent chestplate
    for x2 in range(15,75):
        for y2 in range(8,52):
            if (x2-45)**2/3+(y2-30)**2/4<80: px[x2,y2]=(130,180,240,140)
    # Outline
    for x2 in range(15,75):
        for y2 in [8,14,30,46,52]:
            if (x2-45)**2/3+(y2-30)**2/4<80 and 0<=y2<H: px[x2,y2]=(200,220,255,200)
    # Center gem
    for x2 in range(38,52):
        for y2 in range(22,36):
            if (x2-45)**2+(y2-29)**2<30: px[x2,y2]=(180,220,255,255)
    return img

# --- 凝神 (focus_strike) ---
def _focus():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Concentric rings
    for ring in range(5,30,5):
        for x2 in range(10,80):
            for y2 in range(5,55):
                if abs((x2-45)**2/2+(y2-30)**2/3-ring*5)<8: px[x2,y2]=(80,150,230,200-ring*5)
    # Center eye
    for x2 in range(30,60):
        for y2 in range(18,42):
            if (x2-45)**2/3+(y2-30)**2<20: px[x2,y2]=(255,255,255,240)
    px[45,30]=(30,60,120,255)  # pupil
    return img

# --- 旋风斩 (whirlwind) ---
def _whirl():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Orbiting slashes
    for i in range(8):
        a=math.radians(i*45)
        for d in range(8,24):
            x2=int(45+d*math.cos(a)); y2=int(30+d*math.sin(a)*0.7)
            for dx in range(-2,3):
                for dy in range(-1,2):
                    if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(220,60,40,220)
    # Center spin energy
    for x2 in range(30,60):
        for y2 in range(18,42):
            if (x2-45)**2+(y2-30)**2<80: px[x2,y2]=(255,200,80,180)
    return img

# --- 暗影契约 (dark_pact) ---
def _pact():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Dark portal
    for x2 in range(10,80):
        for y2 in range(5,55):
            d=abs(x2-45)+abs(y2-30)
            if d<40: px[x2,y2]=(30+max(0,70-d),5,max(0,70-d),200)
    # Pentagram
    for i in range(12):
        a=math.radians(i*30)
        x2=int(45+15*math.cos(a)); y2=int(30+15*math.sin(a))
        for dx in range(-2,3):
            for dy in range(-2,3):
                if 0<=x2+dx<W and 0<=y2+dy<H: px[x2+dx,y2+dy]=(200,40,200,255)
    # Center seal
    for x2 in range(35,55):
        for y2 in range(20,40):
            if (x2-45)**2+(y2-30)**2<60: px[x2,y2]=(255,100,255,200)
    return img

# --- 冰霜守护 (frost_ward) ---
def _frost():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Ice crystal shield
    for x2 in range(15,75):
        for y2 in range(4,56):
            r=(x2-45)**2/2.5+(y2-30)**2/5
            if r<100: px[x2,y2]=(120,200,240,min(255,200+int(r)))
    # Hexagonal pattern
    for x2 in range(25,65):
        for y2 in range(12,48):
            if abs(x2-45)+abs(y2-30)<22: px[x2,y2]=(200,240,255,255)
    # Frost edges
    for x2 in range(20,30):
        for y2 in range(8,18): px[x2,y2]=(220,245,255,200)
    for x2 in range(60,70):
        for y2 in range(8,18): px[x2,y2]=(220,245,255,200)
    return img

# --- 狂暴 (berserker) ---
def _rage():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Angry face bg
    for x2 in range(15,75):
        for y2 in range(5,55):
            r=(x2-45)**2/3+(y2-30)**2/2
            if r<120: px[x2,y2]=(200,50,20,min(255,int(r*2)))
    # Eyes red
    for x2 in range(34,40): px[x2,18]=(255,255,255,255)
    for x2 in range(50,56): px[x2,18]=(255,255,255,255)
    # Angry V brow
    for x2 in range(32,42): px[x2,14+(x2-32)]=(255,60,60,255)
    for x2 in range(48,58): px[x2,24-(x2-48)]=(255,60,60,255)
    # Teeth
    for x2 in range(36,54):
        for y2 in range(32,40):
            if x2%2==0: px[x2,y2]=(255,255,200,255)
    return img

# --- 毒刃 (venom_strike) ---
def _venom():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Blade
    for i in range(16):
        for wd in range(-2,3):
            x2,y2=8+i*4+wd,48-i*2
            if 0<=x2<W and 0<=y2<H: px[x2,y2]=(80,180,60,255)
    # Poison drip
    for x2 in range(50,70):
        for y2 in range(20,45):
            if (x2-60)**2+(y2-32)**2<60: px[x2,y2]=(100,210,50,200)
    # Drips falling
    for i in range(4):
        y2=40+i*4; x2=60+i*2
        if 0<=y2<H: px[min(89,x2),y2]=(120,230,70,200)
    return img

# --- 回音斩 (echo_slash) ---
def _echo():
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    # Main slash
    for x2 in range(10,50):
        y2=40-int(abs(x2-30)/2)
        for dy in range(-2,3):
            if 0<=y2+dy<H: px[x2,y2+dy]=(220,60,40,255)
    # Echo 1
    for x2 in range(25,65):
        y2=38-int(abs(x2-45)/2.5)
        for dy in range(-2,3):
            if 0<=y2+dy<H: px[x2,y2+dy]=(200,100,80,180)
    # Echo 2
    for x2 in range(40,80):
        y2=36-int(abs(x2-60)/3)
        for dy in range(-2,3):
            if 0<=y2+dy<H: px[x2,y2+dy]=(180,130,110,120)
    return img

card_funcs = {
    'strike':_strike,'defend':_defend,'heavy_strike':_heavy,'pommel_strike':_pommel,
    'dash':_dash,'iron_wall':_wall,'shock_strike':_shock,'fatal_blow':_fatal,
    'burn':_burn,'battle_cry':_cry,'cleave':_cleave,'twin_strike':_twin,
    'hemokinesis':_blood,'shrug_off':_shrug,'demon_form':_demon,'ghostly_armor':_ghost,
    'focus_strike':_focus,'whirlwind':_whirl,'dark_pact':_pact,'frost_ward':_frost,
    'berserker':_rage,'venom_strike':_venom,'echo_slash':_echo,
}
for cid, func in card_funcs.items():
    img=func()
    save(img, f'{BASE}/assets/art/cards/art/{cid}.png')
    print(f'  card art: {cid}.png')

# ============================================================
# 敌人 — 精细像素画
# ============================================================
print('\n=== Enemies ===')

# 腐化黏胶 48x32
def _enemy_slime_green():
    img=Image.new('RGBA',(48,32),(0,0,0,0)); px=img.load()
    for x2 in range(4,44):
        for y2 in range(4,28):
            if (x2-24)**2/3+(y2-16)**2/2<50: px[x2,y2]=(80,180,60,220)
    for x2 in range(10,38):
        for y2 in range(8,24):
            if (x2-24)**2/5+(y2-18)**2<30: px[x2,y2]=(140,220,100,200)
    px[18,12]=(60,60,60,255); px[30,12]=(60,60,60,255)  # eyes
    return img

# 炽热黏胶 48x32
def _enemy_slime_red():
    img=Image.new('RGBA',(48,32),(0,0,0,0)); px=img.load()
    for x2 in range(4,44):
        for y2 in range(4,28):
            if (x2-24)**2/3+(y2-16)**2/2<50: px[x2,y2]=(200,50,30,220)
    for x2 in range(12,36):
        for y2 in range(8,22):
            if (x2-24)**2/4+(y2-17)**2<25: px[x2,y2]=(255,140,60,200)
    px[18,12]=(255,200,50,255); px[30,12]=(255,200,50,255)
    return img

# 亡骨哨卫 48x56
def _enemy_skeleton():
    img=Image.new('RGBA',(48,56),(0,0,0,0)); px=img.load()
    # Skull
    for x2 in range(12,36):
        for y2 in range(2,20):
            if (x2-24)**2/2+(y2-12)**2<30: px[x2,y2]=(210,195,170,255)
    px[18,9]=(20,15,15,255); px[30,9]=(20,15,15,255)  # eye sockets
    px[22,12]=(30,20,20,255); px[26,12]=(30,20,20,255)  # nose
    # Ribcage
    for x2 in range(14,34):
        for y2 in range(20,38):
            if (x2-24)**2/4+(y2-28)**2/3<30: px[x2,y2]=(190,170,150,220)
    # Arm bones
    for y2 in range(22,38):
        for dx in range(-2,3):
            if 0<=10+dx<48: px[10+dx,y2]=(200,180,160,200)
            if 0<=38+dx<48: px[38+dx,y2]=(200,180,160,200)
    # Legs
    for y2 in range(38,56):
        for dx in range(-2,3):
            if 0<=18+dx<48: px[18+dx,y2]=(195,175,155,200)
            if 0<=30+dx<48: px[30+dx,y2]=(195,175,155,200)
    return img

# 炎精之火 48x48
def _enemy_fire_elemental():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    for x2 in range(4,44):
        for y2 in range(2,46):
            d=abs(x2-24)+abs(y2-24)
            if d<25: px[x2,y2]=(255,min(200,80+d*5),min(100,10+d*3),220)
    for x2 in range(14,34):
        for y2 in range(10,30):
            if (x2-24)**2+(y2-22)**2<60: px[x2,y2]=(255,240,80,255)
    px[20,18]=(255,255,255,255); px[28,18]=(255,255,255,255)
    return img

# 虚空织法者 48x56
def _enemy_shadow_mage():
    img=Image.new('RGBA',(48,56),(0,0,0,0)); px=img.load()
    for x2 in range(6,42):
        for y2 in range(2,54):
            d=(x2-24)**2/2+(y2-28)**2/3
            if d<60: px[x2,y2]=(60,30,90,min(255,int(300-d*3)))
    # Hood
    for x2 in range(10,38):
        for y2 in range(2,16):
            if (x2-24)**2/4+(y2-10)**2<40: px[x2,y2]=(40,15,60,255)
    # Glowing eyes
    for x2 in range(18,22): px[x2,18]=(200,80,255,255)
    for x2 in range(26,30): px[x2,18]=(200,80,255,255)
    # Hands with energy
    for x2 in range(8,18):
        for y2 in range(30,40): px[x2,y2]=(180,60,220,200)
    for x2 in range(30,40):
        for y2 in range(30,40): px[x2,y2]=(180,60,220,200)
    return img

# 深渊先锋 64x80
def _enemy_goblin():
    img=Image.new('RGBA',(64,80),(0,0,0,0)); px=img.load()
    # Helmet
    for x2 in range(16,48):
        for y2 in range(4,18): px[x2,y2]=(100,80,50,255)
    for x2 in range(22,42):
        for y2 in range(0,6): px[x2,y2]=(120,100,60,255)  # plume
    # Face
    for x2 in range(22,42):
        for y2 in range(18,30): px[x2,y2]=(160,130,80,255)
    px[28,22]=(40,40,40,255); px[36,22]=(40,40,40,255)
    px[30,26]=(60,30,20,255)  # teeth
    # Body armor
    for x2 in range(14,50):
        for y2 in range(30,56): px[x2,y2]=(80,70,50,240)
    # Sword
    for x2 in range(46,56):
        for y2 in range(20,50): px[x2,y2]=(180,170,150,240)
    for x2 in range(48,54):
        for y2 in range(17,20): px[x2,y2]=(220,200,80,255)
    # Legs
    for y2 in range(56,80):
        for dx in range(-3,4):
            if 0<=22+dx<64: px[22+dx,y2]=(70,60,40,220)
            if 0<=42+dx<64: px[42+dx,y2]=(70,60,40,220)
    return img

# 黯钢骑士 64x80
def _enemy_dark_knight():
    img=Image.new('RGBA',(64,80),(0,0,0,0)); px=img.load()
    # Helmet
    for x2 in range(14,50):
        for y2 in range(4,20):
            if (x2-32)**2/3+(y2-12)**2<50: px[x2,y2]=(50,40,60,255)
    # Visor slit
    for x2 in range(22,42): px[x2,16]=(200,60,60,255)
    # Body armor
    for x2 in range(10,54):
        for y2 in range(20,56): px[x2,y2]=(45,35,55,240)
    # Pauldrons
    for x2 in range(6,18):
        for y2 in range(18,32): px[x2,y2]=(60,45,70,255)
    for x2 in range(46,58):
        for y2 in range(18,32): px[x2,y2]=(60,45,70,255)
    # Cape
    for x2 in range(16,48):
        for y2 in range(50,78): px[x2,y2]=(80,20,40,220)
    return img

# 瘟疫啃噬者 48x56
def _enemy_rat():
    img=Image.new('RGBA',(48,56),(0,0,0,0)); px=img.load()
    # Body
    for x2 in range(8,40):
        for y2 in range(14,40): px[x2,y2]=(100,80,60,240)
    # Head
    for x2 in range(30,44):
        for y2 in range(4,18): px[x2,y2]=(120,90,60,255)
    # Eyes
    px[36,8]=(200,20,20,255); px[40,8]=(200,20,20,255)
    # Ears
    for x2 in range(34,42):
        for y2 in range(0,6): px[x2,y2]=(140,100,70,255)
    # Tail
    for y2 in range(38,52):
        x2=14+int(5*math.sin(y2/5))
        for dx in range(-1,2):
            if 0<=x2+dx<48: px[x2+dx,y2]=(120,90,50,200)
    # Legs
    for y2 in range(38,56):
        for dx in range(-2,3):
            if 0<=14+dx<48: px[14+dx,y2]=(80,60,40,220)
            if 0<=28+dx<48: px[28+dx,y2]=(80,60,40,220)
    return img

# 黏胶之主 96x64
def _enemy_slime_king():
    img=Image.new('RGBA',(96,64),(0,0,0,0)); px=img.load()
    for x2 in range(8,88):
        for y2 in range(6,58):
            if (x2-48)**2/5+(y2-32)**2/3<80: px[x2,y2]=(100,200,60,200)
    for x2 in range(20,76):
        for y2 in range(12,48):
            if (x2-48)**2/6+(y2-30)**2/2<40: px[x2,y2]=(180,240,120,200)
    # Crown
    for x2 in range(34,62):
        for y2 in range(2,10): px[x2,y2]=(220,200,40,255)
    for x2 in [38,44,50,56]: px[x2,0]=(220,200,40,255); px[x2,1]=(220,200,40,255)
    # Eyes
    for x2 in range(38,44): px[x2,20]=(60,60,60,255)
    for x2 in range(52,58): px[x2,20]=(60,60,60,255)
    # Mouth
    for x2 in range(42,54):
        for y2 in range(28,34): px[x2,y2]=(40,80,20,255)
    return img

# 诅咒骑士 64x80
def _enemy_cursed_knight():
    img=Image.new('RGBA',(64,80),(0,0,0,0)); px=img.load()
    for x2 in range(12,52):
        for y2 in range(4,76):
            if (x2-32)**2/2+(y2-40)**2/3<200: px[x2,y2]=(50,20,60,220)
    # Helm with horns
    for x2 in range(14,50):
        for y2 in range(4,22): px[x2,y2]=(60,25,70,255)
    for x2 in range(22,32): px[x2,4-(x2-22)]=(80,30,90,255)
    for x2 in range(32,42): px[x2,4-(42-x2)]=(80,30,90,255)
    # Purple glow eyes
    for x2 in range(26,30): px[x2,16]=(200,60,255,255)
    for x2 in range(34,38): px[x2,16]=(200,60,255,255)
    # Cursed mark on chest
    for x2 in range(26,38):
        for y2 in range(34,44): px[x2,y2]=(120,20,180,200)
    return img

# 冰霜狼 48x56
def _enemy_frost_wolf():
    img=Image.new('RGBA',(48,56),(0,0,0,0)); px=img.load()
    # Body
    for x2 in range(6,42):
        for y2 in range(16,44): px[x2,y2]=(180,210,235,240)
    # Head
    for x2 in range(30,46):
        for y2 in range(4,22): px[x2,y2]=(190,220,240,255)
    # Blue eyes
    px[38,10]=(60,120,220,255); px[40,10]=(60,120,220,255)
    # Ears
    for x2 in range(34,40): px[x2,2]=(160,200,230,255)
    for x2 in range(38,44): px[x2,0]=(160,200,230,255)
    # Tail
    for x2 in range(0,10):
        for y2 in range(24,34): px[x2,y2]=(200,220,240,220)
    # Legs
    for y2 in range(42,56):
        for dx in range(-2,3):
            if 0<=12+dx<48: px[12+dx,y2]=(160,190,220,220)
            if 0<=28+dx<48: px[28+dx,y2]=(160,190,220,220)
    return img

enemy_funcs = {
    'slime_green': _enemy_slime_green, 'slime_red': _enemy_slime_red,
    'skeleton': _enemy_skeleton, 'fire_elemental': _enemy_fire_elemental,
    'shadow_mage': _enemy_shadow_mage, 'goblin_captain': _enemy_goblin,
    'dark_knight': _enemy_dark_knight, 'giant_rat': _enemy_rat,
    'slime_king': _enemy_slime_king, 'cursed_knight': _enemy_cursed_knight,
    'frost_wolf': _enemy_frost_wolf,
}
for eid, func in enemy_funcs.items():
    img=func()
    save(img, f'{BASE}/assets/art/enemies/{eid}.png')
    print(f'  enemy: {eid}.png')

# ============================================================
# 遗物 48x48 — 精细像素画
# ============================================================
print('\n=== Relics ===')

# 炽热核心 (burning_blood) — 火焰包裹的核心
def _relic_burning_blood():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    for x2 in range(8,40):
        for y2 in range(4,44):
            d=abs(x2-24)+abs(y2-24)
            if d<18: px[x2,y2]=(255,min(200,60+d*8),min(100,20+d*4),220)
    for x2 in range(16,32):
        for y2 in range(12,36):
            if (x2-24)**2+(y2-24)**2<50: px[x2,y2]=(255,200,40,255)
    for x2 in range(18,30):
        for y2 in range(16,32):
            if (x2-24)**2+(y2-24)**2<25: px[x2,y2]=(255,240,120,255)
    px[22,22]=(255,255,255,255); px[26,22]=(255,255,255,255)
    return img

# 破魔锥 (vajra) — 尖锐锥形法器
def _relic_vajra():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    for y2 in range(4,44):
        w=2+int(y2/3)
        for x2 in range(24-w,24+w+1):
            if 0<=x2<48: px[x2,y2]=(200,170,40,min(255,100+y2*3))
    for y2 in range(4,30):
        if 0<=24<48: px[24,y2]=(255,240,100,255)
    # Handle
    for y2 in range(30,44):
        for x2 in range(20,28): px[x2,y2]=(140,100,20,255)
    return img

# 沉锚坠饰 (anchor) — 船锚
def _relic_anchor():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Ring top
    for x2 in range(18,30):
        for y2 in range(4,12):
            if (x2-24)**2+(y2-8)**2<20: px[x2,y2]=(180,160,100,255)
    # Shaft
    for x2 in range(22,26):
        for y2 in range(10,42): px[x2,y2]=(140,120,70,255)
    # Cross bar
    for x2 in range(10,38):
        for y2 in range(16,20): px[x2,y2]=(160,140,80,255)
    # Bottom hooks
    for x2 in range(8,22):
        for y2 in range(36,44): px[x2,y2]=(150,130,75,240)
    for x2 in range(26,40):
        for y2 in range(36,44): px[x2,y2]=(150,130,75,240)
    return img

# 琥珀之虫 (preserved_insect) — 琥珀中的昆虫
def _relic_insect():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Amber
    for x2 in range(6,42):
        for y2 in range(6,42):
            if (x2-24)**2/3+(y2-24)**2/2<50: px[x2,y2]=(220,150,30,200)
    # Highlight
    for x2 in range(12,22):
        for y2 in range(10,20):
            if (x2-17)**2+(y2-15)**2<20: px[x2,y2]=(255,200,100,150)
    # Insect body inside
    for x2 in range(16,32):
        for y2 in range(18,32): px[x2,y2]=(60,30,10,220)
    # Legs
    for i in range(6):
        y2=20+i*3; x2=16-i*1
        if 0<=x2<48: px[x2,y2]=(40,20,5,200)
        x2=32+i*1
        if 0<=x2<48: px[x2,y2]=(40,20,5,200)
    return img

# 凝血药剂 (blood_vial) — 装血的小瓶
def _relic_vial():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Bottle
    for x2 in range(18,30):
        for y2 in range(6,14): px[x2,y2]=(140,140,160,200)  # neck
    # Body
    for x2 in range(10,38):
        for y2 in range(12,40):
            if (x2-24)**2/3+(y2-26)**2/3<50: px[x2,y2]=(160,140,150,180)
    # Blood inside
    for x2 in range(14,34):
        for y2 in range(18,36): px[x2,y2]=(180,20,20,200)
    # Cork
    for x2 in range(19,29):
        for y2 in range(4,8): px[x2,y2]=(180,140,80,255)
    # Highlight
    for x2 in range(15,21):
        for y2 in range(16,24): px[x2,y2]=(220,200,200,120)
    return img

# 亡者印记 (red_skull) — 红色骷髅头
def _relic_skull():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    for x2 in range(10,38):
        for y2 in range(6,42):
            if (x2-24)**2/2+(y2-26)**2/3<60: px[x2,y2]=(200,160,140,255)
    px[18,22]=(30,15,15,255); px[30,22]=(30,15,15,255)  # eyes
    px[22,30]=(30,15,15,255); px[26,30]=(30,15,15,255)  # nose
    # Teeth
    for x2 in range(20,28):
        for y2 in range(34,38):
            if x2%2==0: px[x2,y2]=(40,20,15,255)
    # Red glow behind
    for x2 in range(8,40):
        for y2 in range(4,44):
            if (x2-24)**2+(y2-26)**2<160: px[x2,y2]=(min(255,px[x2,y2][0]),min(255,px[x2,y2][1]),min(255,px[x2,y2][2]),min(255,px[x2,y2][3]+60))
    return img

# 永绽之花 (happy_flower) — 永远绽放的花
def _relic_flower():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Stem
    for x2 in range(22,26):
        for y2 in range(26,44): px[x2,y2]=(80,160,40,255)
    # Petals
    for i in range(6):
        a=math.radians(i*60)
        cx=int(24+10*math.cos(a)); cy=int(22+10*math.sin(a))
        for x2 in range(cx-5,cx+6):
            for y2 in range(cy-5,cy+6):
                if (x2-cx)**2+(y2-cy)**2<25 and 0<=x2<48 and 0<=y2<48: px[x2,y2]=(255,200,50,240)
    # Center
    for x2 in range(20,28):
        for y2 in range(18,26):
            if (x2-24)**2+(y2-22)**2<12: px[x2,y2]=(255,240,80,255)
    # Leaves
    for x2 in range(12,22):
        for y2 in range(30,38):
            if (x2-18)**2+(y2-34)**2<15: px[x2,y2]=(60,180,30,230)
    for x2 in range(26,36):
        for y2 in range(32,40):
            if (x2-30)**2+(y2-36)**2<15: px[x2,y2]=(60,180,30,230)
    return img

# 追忆之网 (dream_catcher) — 捕梦网
def _relic_dream():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Ring
    for x2 in range(6,42):
        for y2 in range(6,42):
            r2=(x2-24)**2+(y2-24)**2
            if 220<r2<320: px[x2,y2]=(160,120,60,255)
    # Web lines
    for i in range(8):
        a=math.radians(i*45)
        for d in range(3,15):
            x2=int(24+d*math.cos(a)); y2=int(24+d*math.sin(a))
            if 0<=x2<48 and 0<=y2<48: px[x2,y2]=(200,160,80,200)
    # Feathers hanging
    for x2 in [16,24,32]:
        for y2 in range(36,46): px[x2,y2]=(180,140,70,220)
    return img

# 荆棘斗篷 (thorn_cloak) — 有刺的斗篷
def _relic_thorn():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Cloak base
    for x2 in range(10,38):
        for y2 in range(8,42): px[x2,y2]=(70,100,60,220)
    # Thorns
    for i in range(10):
        x2=8+i*3; y2=12+i*2
        if 0<=x2<48 and 0<=y2<48: px[x2,y2]=(150,200,100,255)
        x2=40-i*3; y2=12+i*2
        if 0<=x2<48 and 0<=y2<48: px[x2,y2]=(150,200,100,255)
    # Border
    for x2 in range(14,34):
        px[x2,8]=(120,160,80,255); px[x2,40]=(120,160,80,255)
    return img

# 法力水晶 (mana_crystal) — 发光水晶
def _relic_crystal():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    for x2 in range(8,40):
        for y2 in range(4,44):
            if abs(x2-24)+abs(y2-24)<17: px[x2,y2]=(80,120,230,200)
    for x2 in range(14,34):
        for y2 in range(10,38):
            if abs(x2-24)+abs(y2-24)<12: px[x2,y2]=(130,180,255,220)
    # Facets
    for x2 in range(16,32):
        for y2 in range(8,40):
            if (x2-24)**2+(y2-24)**2<80 and (x2+y2)%4==0: px[x2,y2]=(200,220,255,180)
    # Bright center
    for x2 in range(20,28):
        for y2 in range(18,30): px[x2,y2]=(220,240,255,255)
    return img

# 凤凰羽毛 (phoenix_feather) — 凤凰尾羽
def _relic_phoenix():
    img=Image.new('RGBA',(48,48),(0,0,0,0)); px=img.load()
    # Quill
    for x2 in range(22,26):
        for y2 in range(8,44): px[x2,y2]=(200,120,40,255)
    # Feather vanes
    for y2 in range(8,40):
        w=int(8+6*math.sin((y2-8)*0.3))
        for x2 in range(22-w,22+w+1):
            if 0<=x2<48: px[x2,y2]=(255,min(220,180-abs(x2-24)*5),min(100,60-abs(x2-24)*3),230)
    # Golden tip
    for x2 in range(18,30):
        for y2 in range(4,10): px[x2,y2]=(255,220,80,255)
    # Flame wisps
    for x2 in [16,32]:
        for y2 in [6,8,10]: px[x2,y2]=(255,200,60,180)
    return img

relic_funcs = {
    'burning_blood': _relic_burning_blood, 'vajra': _relic_vajra,
    'anchor': _relic_anchor, 'preserved_insect': _relic_insect,
    'blood_vial': _relic_vial, 'red_skull': _relic_skull,
    'happy_flower': _relic_flower, 'dream_catcher': _relic_dream,
    'thorn_cloak': _relic_thorn, 'mana_crystal': _relic_crystal,
    'phoenix_feather': _relic_phoenix,
}
for rid, func in relic_funcs.items():
    img=func()
    save(img, f'{BASE}/assets/art/relics/{rid}.png')
    print(f'  relic: {rid}.png')

print(f'\nDone — 23 cards + 11 enemies + 11 relics all redesigned')
