import os
from PIL import Image

input_path = "Задний_белый_фон_должен_быть_202606011705_vector.png"
if os.path.exists(input_path):
    # Open the image
    img = Image.open(input_path).convert("RGBA")
    
    # Save as Android foreground (transparent)
    img.save("assets/images/app_icon_android.png")
    
    # Create black background for iOS
    bg = Image.new("RGBA", img.size, (0, 0, 0, 255))
    bg.paste(img, mask=img)
    bg.convert("RGB").save("assets/images/app_icon_ios.png")
    
    print("Icons processed successfully.")
else:
    print("Input image not found.")
