import os
import glob
from PIL import Image

def compress_folder(folder_path):
    print(f"Compressing images in {folder_path}...")
    png_files = glob.glob(os.path.join(folder_path, '*.png'))
    
    total_saved = 0
    
    for png_file in png_files:
        try:
            # 1. Загружаем
            img = Image.open(png_file)
            
            # Конвертируем в RGB (если вдруг есть прозрачность - она станет черным/белым)
            img = img.convert("RGB")
            
            # 2. Уменьшаем разрешение (до 600x600 макс, сохраняя пропорции)
            img.thumbnail((600, 600), Image.Resampling.LANCZOS)
            
            # 3. Сохраняем как JPG
            jpg_file = png_file.replace('.png', '.jpg')
            img.save(jpg_file, 'JPEG', quality=80, optimize=True)
            
            # 4. Считаем разницу в весе
            old_size = os.path.getsize(png_file)
            new_size = os.path.getsize(jpg_file)
            total_saved += (old_size - new_size)
            
            # 5. Удаляем старый тяжелый PNG
            os.remove(png_file)
            
        except Exception as e:
            print(f"Error processing {png_file}: {e}")
            
    return total_saved, len(png_files)

if __name__ == "__main__":
    win_saved, win_count = compress_folder("assets/images/defaults/endgame/win")
    loss_saved, loss_count = compress_folder("assets/images/defaults/endgame/loss")
    
    total_saved_mb = (win_saved + loss_saved) / (1024 * 1024)
    print(f"\\n✅ Done! Compressed {win_count + loss_count} images.")
    print(f"📉 Total space saved: {total_saved_mb:.2f} MB!")
