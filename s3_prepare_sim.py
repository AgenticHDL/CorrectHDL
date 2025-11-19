import shutil
import sys
from pathlib import Path
from config import ROOT, TEMPLATES_DIR, aes_dir, aesv_dir


def main():
    print("--- Start generating simulation scripts ---")

    # 1. Find all 'aesX' design directories
    design_indices = []
    for p in ROOT.iterdir():
        if p.is_dir() and p.name.startswith("aes"):
            try:
                # Extract the number from "aes12" → 12
                index = int(p.name[3:])
                design_indices.append(index)
            except (ValueError, IndexError):
                # Ignore directories not matching "aes<number>"
                pass
    
    design_indices.sort()
    if not design_indices:
        print(f"[ERROR] No 'aesX' folders found under '{ROOT}'.", file=sys.stderr)
        sys.exit(2)

    print(f"[INFO] Found {len(design_indices)} design versions: {design_indices}")

    # 2. Read template file content
    template_sim_path = TEMPLATES_DIR / "sim.py"
    try:
        template_content = template_sim_path.read_text(encoding="utf-8")
        print(f"[INFO] Successfully read template file: {template_sim_path}")
    except FileNotFoundError:
        print(f"[ERROR] Template file not found: {template_sim_path}", file=sys.stderr)
        sys.exit(1)

    # 3. Iterate over all design versions and generate simulation scripts
    for x in design_indices:
        dest_dir = aesv_dir(x)   # e.g., /.../aesh4/vsplit/aesv1

        print(f"\n[+] Processing design aes{x}...")
        
        # Create destination directory
        dest_dir.mkdir(parents=True, exist_ok=True)
        print(f"  - Destination directory: {dest_dir}")
        
        # --- Core fix: precise string replacement ---
        
        # Copy template content for modification
        modified_content = template_content

        # Replace SRC_DIR
        # Note: convert Path to string and ensure correct path separators
        target_src_dir_str = str(dest_dir).replace('\\', '/')
        modified_content = modified_content.replace(
            'SRC_DIR        = "/nas"',
            f'SRC_DIR        = "{target_src_dir_str}"'
        )

        # Replace TOP module name
        modified_content = modified_content.replace(
            'TOP = "top"',
            f'TOP = "top{x}"'
        )
        
        # Replace FILES list
        # Ensure original whitespace and quotes match exactly
        modified_content = modified_content.replace(
            'FILES = ["aes.sv", "test.sv"]',
            f'FILES = ["aes{x}.sv", "test{x}.sv"]'
        )
        
        # Write the modified content to the new sim.py
        output_sim_path = dest_dir / "sim.py"
        output_sim_path.write_text(modified_content, encoding="utf-8")
        print(f"  - Generated sim.py: {output_sim_path}")

    print("\n--- All simulation scripts generated successfully! ---")

if __name__ == "__main__":
    main()
