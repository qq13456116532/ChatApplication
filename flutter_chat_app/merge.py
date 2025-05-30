import os

output_file = "output.txt"
lib_folder = "lib"

with open(output_file, "w", encoding="utf-8") as out_f:
    for root, dirs, files in os.walk(lib_folder):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                relative_path = os.path.relpath(file_path, start=os.getcwd())
                out_f.write(f"{relative_path}：【{content}】\n")
            except Exception as e:
                print(f"Failed to read {file_path}: {e}")
