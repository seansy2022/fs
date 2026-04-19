import os
import re
import subprocess
import glob

# 配置路径
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_FONTS_DIR = os.path.join(PROJECT_ROOT, "fonts_source")
TARGET_FONTS_DIR = os.path.join(PROJECT_ROOT, "packages", "rc_ui", "lib", "resources", "fonts")
SCAN_DIRS = [
    os.path.join(PROJECT_ROOT, "packages", "rc_ui", "lib"),
    os.path.join(PROJECT_ROOT, "rc_ui_gallery", "lib"),
    os.path.join(PROJECT_ROOT, "rc_configurator_flutter", "lib"),
    os.path.join(PROJECT_ROOT, "controller_app", "lib"),
]

# 字体映射 (原始文件 -> 输出文件)
FONTS = {
    "Roboto-Regular.ttf": "Roboto-Regular.ttf",
    "Roboto-Bold.ttf": "Roboto-Bold.ttf",
    "NotoSansSC-Regular.otf": "NotoSansSC-Regular.otf",
    "NotoSansSC-Bold.otf": "NotoSansSC-Bold.otf",
}

def collect_characters():
    chars = set()
    # 基础 ASCII 字符和常用符号
    for i in range(32, 127):
        chars.add(chr(i))
    
    # 扫描所有 .dart 文件
    for scan_dir in SCAN_DIRS:
        if not os.path.exists(scan_dir):
            continue
        for root, _, files in os.walk(scan_dir):
            for file in files:
                if file.endswith(".dart"):
                    path = os.path.join(root, file)
                    try:
                        with open(path, "r", encoding="utf-8") as f:
                            content = f.read()
                            # 提取字符串中的字符 (简单处理，提取所有非空白字符)
                            # 或者更精确地提取引号间的内容
                            strings = re.findall(r"['\"](.*?)['\"]", content)
                            for s in strings:
                                for char in s:
                                    chars.add(char)
                    except Exception as e:
                        print(f"Error reading {path}: {e}")
    
    return "".join(sorted(list(chars)))

def subset_fonts(text):
    if not os.path.exists(TARGET_FONTS_DIR):
        os.makedirs(TARGET_FONTS_DIR)
    
    # 将提取的字符写入临时文件
    chars_file = os.path.join(PROJECT_ROOT, "scripts", "chars.txt")
    with open(chars_file, "w", encoding="utf-8") as f:
        f.write(text)
    
    print(f"Collected {len(text)} unique characters.")
    
    for source_name, target_name in FONTS.items():
        source_path = os.path.join(SOURCE_FONTS_DIR, source_name)
        target_path = os.path.join(TARGET_FONTS_DIR, target_name)
        
        if not os.path.exists(source_path):
            print(f"Warning: Source font {source_path} not found. Skipping.")
            continue
        
        print(f"Subsetting {source_name} -> {target_name}...")
        
        # 使用 pyftsubset 进行裁剪
        cmd = [
            "python3", "-m", "fontTools.subset",
            source_path,
            f"--text-file={chars_file}",
            f"--output-file={target_path}",
            "--layout-features=*",
            "--no-hinting",
            "--desubroutinize",
        ]
        
        try:
            subprocess.run(cmd, check=True)
            original_size = os.path.getsize(source_path) / 1024 / 1024
            subset_size = os.path.getsize(target_path) / 1024 / 1024
            print(f"Success! {original_size:.2f}MB -> {subset_size:.2f}MB")
        except subprocess.CalledProcessError as e:
            print(f"Error subsetting {source_name}: {e}")

if __name__ == "__main__":
    used_text = collect_characters()
    subset_fonts(used_text)
