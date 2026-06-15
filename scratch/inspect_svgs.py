import os
import glob
import re

svg_dir = "/Users/abdallahalawdy/.gemini/antigravity-ide/brain/d7f17f87-3fec-4a67-814c-2fa0359434f0"
svg_files = glob.glob(os.path.join(svg_dir, "*.svg"))

for path in svg_files:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    filename = os.path.basename(path)
    # Search for id="elements" or id="..." in the svg
    ids = re.findall(r'id="([^"]+)"', content)
    viewbox = re.search(r'viewBox="([^"]+)"', content)
    vb_val = viewbox.group(1) if viewbox else "None"
    print(f"File: {filename} | ViewBox: {vb_val} | IDs: {ids[:5]}")
    # print a small preview of the first path
    paths = re.findall(r'<path[^>]+d="([^"]+)"', content)
    if paths:
        print(f"  Path preview: {paths[0][:60]}...")
