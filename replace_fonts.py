import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content

    # Remove google_fonts import
    content = re.sub(r"import\s+'package:google_fonts/google_fonts\.dart';\s*\n?", "", content)

    # Replace GoogleFonts.fontName(...) with TextStyle(...)
    # Note: This regex replaces `GoogleFonts.quicksand(` with `TextStyle(fontFamily: 'GoogleSansFlex', `
    pattern = r"GoogleFonts\.\w+\s*\("
    def replacer(match):
        return "TextStyle(fontFamily: 'GoogleSansFlex', "
    
    content = re.sub(pattern, replacer, content)

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    lib_dir = "lumina_lanka/lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
