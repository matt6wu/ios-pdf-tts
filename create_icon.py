#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

def create_mpdf_icon():
    # 创建1024x1024的图像
    size = 1024
    img = Image.new('RGB', (size, size), color='#1976d2')
    draw = ImageDraw.Draw(img)
    
    # 绘制圆角矩形背景
    # PIL doesn't have native rounded rectangle, so we'll use a simple rectangle
    
    # 尝试使用系统字体
    try:
        # 尝试使用较大的字体
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 200)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 200)
        except:
            # 如果找不到字体，使用默认字体
            font = ImageFont.load_default()
    
    # 绘制文字
    text = "MPDF"
    
    # 计算文字位置居中
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    # 绘制白色文字
    draw.text((x, y), text, fill='white', font=font)
    
    return img

# 创建图标
icon = create_mpdf_icon()

# 保存到AppIcon文件夹
icon_path = "/Users/matt/Documents/app/PDFtts/PDFtts/Assets.xcassets/AppIcon.appiconset/"
icon.save(icon_path + "doc-icon-parts-center-image@2x.png")
icon.save(icon_path + "doc-icon-parts-center-image@2x 1.png")
icon.save(icon_path + "doc-icon-parts-center-image@2x 2.png")

print("图标已创建完成！")