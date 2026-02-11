#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

def create_app_icon(size, scale):
    """Create app icon with target size (logical) and scale (multiplier)"""
    # Actual pixel size
    pixel_size = int(float(size.split('x')[0]) * scale)
    
    # Create image with blue background for fintech feel
    img = Image.new('RGB', (pixel_size, pixel_size), color=(59, 130, 246))
    draw = ImageDraw.Draw(img)
    
    center = pixel_size // 2
    
    # Outer darker blue circle
    draw.ellipse(
        [(center - pixel_size//3, center - pixel_size//3), 
         (center + pixel_size//3, center + pixel_size//3)],
        fill=(37, 99, 235)
    )
    
    # Create circular rings pattern (blockchain/network theme)
    for i in range(3, 0, -1):
        radius = (pixel_size // 6) * i
        draw.ellipse(
            [(center - radius, center - radius),
             (center + radius, center + radius)],
            outline=(255, 255, 255),
            width=max(1, pixel_size // 20)
        )
    
    # Center white dot
    dot_radius = pixel_size // 12
    draw.ellipse(
        [(center - dot_radius, center - dot_radius),
         (center + dot_radius, center + dot_radius)],
        fill=(255, 255, 255)
    )
    
    return img

# Icon specifications from Contents.json
icon_specs = [
    ("20x20", 2, "iphone", "AppIcon-20x20@2x.png"),
    ("20x20", 3, "iphone", "AppIcon-20x20@3x.png"),
    ("29x29", 2, "iphone", "AppIcon-29x29@2x.png"),
    ("29x29", 3, "iphone", "AppIcon-29x29@3x.png"),
    ("40x40", 2, "iphone", "AppIcon-40x40@2x.png"),
    ("40x40", 3, "iphone", "AppIcon-40x40@3x.png"),
    ("60x60", 2, "iphone", "AppIcon-60x60@2x.png"),
    ("60x60", 3, "iphone", "AppIcon-60x60@3x.png"),
    ("20x20", 1, "ipad", "AppIcon-20x20@1x.png"),
    ("20x20", 2, "ipad", "AppIcon-20x20@2x.png"),
    ("29x29", 1, "ipad", "AppIcon-29x29@1x.png"),
    ("29x29", 2, "ipad", "AppIcon-29x29@2x.png"),
    ("40x40", 1, "ipad", "AppIcon-40x40@1x.png"),
    ("40x40", 2, "ipad", "AppIcon-40x40@2x.png"),
    ("76x76", 1, "ipad", "AppIcon-76x76@1x.png"),
    ("76x76", 2, "ipad", "AppIcon-76x76@2x.png"),
    ("83.5x83.5", 2, "ipad", "AppIcon-83.5x83.5@2x.png"),
    ("1024x1024", 1, "ios-marketing", "AppIcon-1024x1024.png"),
]

base_path = "/Users/fomo/Dev/three-tx-ios/XRPLResultCodes/Assets.xcassets/AppIcon.appiconset"

for size, scale, idiom, filename in icon_specs:
    img = create_app_icon(size, scale)
    filepath = os.path.join(base_path, filename)
    img.save(filepath)
    print(f"✓ {filename}")

print("\n✅ App icons created!")
