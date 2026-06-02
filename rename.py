import os

def rename_files(root_dir):
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.startswith('mask_'):
                new_name = filename.replace('mask_', 'mask_it1_', 1)
                old_path = os.path.join(dirpath, filename)
                new_path = os.path.join(dirpath, new_name)
                os.rename(old_path, new_path)
                print(f'Renamed: {old_path} -> {new_path}')

# Replace '/path/to/your/folder' with the actual path to your root folder
rename_files('input/model_data/masks_it1')