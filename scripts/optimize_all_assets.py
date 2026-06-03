import os
from PIL import Image

def optimize_image(file_path, max_size=(800, 800), quality=75):
    try:
        # Get original size
        orig_size = os.path.getsize(file_path)
        if orig_size < 50 * 1024:  # Skip files already under 50KB
            return 0, 0
            
        img = Image.open(file_path)
        orig_format = img.format
        
        # Check dimensions
        w, h = img.size
        needs_resize = w > max_size[0] or h > max_size[1]
        
        if needs_resize:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
            
        # Save back to the same path keeping the original format
        if orig_format == 'PNG':
            # For PNG, if it does not have alpha (transparency), converting to RGB and saving as JPEG is better,
            # but we must keep the file name and extension to avoid breaking Flutter asset references.
            # So we will just save as PNG with optimization.
            img.save(file_path, format='PNG', optimize=True)
        elif orig_format in ['JPEG', 'MPO']:
            img.save(file_path, format='JPEG', quality=quality, optimize=True)
        else:
            # For other formats, just save optimized
            img.save(file_path, format=orig_format, optimize=True)
            
        new_size = os.path.getsize(file_path)
        saved = orig_size - new_size
        return saved, 1
    except Exception as e:
        print(f"Error optimizing {file_path}: {e}")
        return 0, 0

def optimize_assets(root_dir):
    print(f"Starting assets optimization in: {root_dir}...")
    total_saved = 0
    total_optimized = 0
    
    # Supported image extensions
    valid_exts = ('.png', '.jpg', '.jpeg')
    
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith(valid_exts):
                file_path = os.path.join(dirpath, filename)
                saved, count = optimize_image(file_path)
                if count > 0:
                    total_saved += saved
                    total_optimized += count
                    
    total_saved_mb = total_saved / (1024 * 1024)
    print(f"\nDone! Optimized {total_optimized} images.")
    print(f"Total space saved: {total_saved_mb:.2f} MB!")

if __name__ == "__main__":
    optimize_assets("assets")
