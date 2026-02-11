#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os
import random

def create_app_icon(size, scale):
    """Create app icon with colorful grid pattern on dark background"""
    pixel_size = int(float(size.split('x')[0]) * scale)
    
    # Dark background
    img = Image.new('RGB', (pixel_size, pixel_size), color=(15, 15, 15))
    draw = ImageDraw.Draw(img)
    
    # Color palette matching the visualization
    colors = [
        (76, 200, 89),    # Green
        (66, 150, 255),   # Blue
        (156, 102, 255),  # Purple
        (255, 102, 204),  # Pink/Magenta
    ]
    
    # Create a grid pattern with random shapes (3x3 instead of 4x4 for larger shapes)
    grid_size = 3
    cell_size = pixel_size // (grid_size + 1)
    
    random.seed(42)  # Consistent pattern
    
    for row in range(grid_size):
        for col in range(grid_size):
            x = (col + 1) * cell_size
            y = (row + 1) * cell_size
            color = random.choice(colors)
            # Weighted to have more variety - ensure good mix of hollow and filled circles
            shape_val = random.random()
            if shape_val < 0.33:
                shape = 'filled_circle'
            elif shape_val < 0.66:
                shape = 'hollow_circle'
            else:
                shape = 'triangle'
            
            # Draw shapes with some padding (increased for more prominent look)
            padding = cell_size // 4  # Increased from cell_size // 6
            
            if shape == 'filled_circle':
                # Draw filled circle
                draw.ellipse(
                    [(x - padding, y - padding),
                     (x + padding, y + padding)],
                    fill=color
                )
            elif shape == 'hollow_circle':
                # Draw hollow circle (outline only) with better stroke width
                stroke_width = max(2, padding // 2)
                draw.ellipse(
                    [(x - padding, y - padding),
                     (x + padding, y + padding)],
                    outline=color,
                    width=stroke_width
                )
            else:
                # Draw triangle (play button style)
                triangle_size = padding
                points = [
                    (x - triangle_size, y - triangle_size),
                    (x - triangle_size, y + triangle_size),
                    (x + triangle_size, y),
                ]
                draw.polygon(points, fill=color)
    
    # Removed the green accent line at the bottom
    
    return img

# Icon specifications
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

print("\n✅ App icons created with new design!")

