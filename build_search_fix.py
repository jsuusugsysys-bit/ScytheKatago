#!/usr/bin/env python3
import subprocess
import sys
import os

print("===== Compiling KataGo (Search Fix) =====")

# Change to build directory
os.chdir("D:\\ScytheKatago\\KataGo\\cpp\\build")

# Clean search.obj to force recompile
search_obj = "D:\\ScytheKatago\\KataGo\\cpp\\build\\katago.dir\\Release\\search.obj"
if os.path.exists(search_obj):
    os.remove(search_obj)
    print(f"Deleted {search_obj}")

# Setup VS environment and build
cmd = '''
call "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Auxiliary\\Build\\vcvars64.bat" && cmake --build . --config Release --parallel 4
'''

result = subprocess.run(
    cmd,
    shell=True,
    capture_output=True,
    text=True,
    encoding='utf-8',
    errors='replace'
)

# Print output
if result.stdout:
    print("OUTPUT:")
    print(result.stdout.replace('\r\n', '\n'))
if result.stderr:
    print("\nERROR OUTPUT:")
    print(result.stderr.replace('\r\n', '\n'))

print(f"\nReturn code: {result.returncode}")

# Check if build succeeded
if result.returncode == 0:
    print("\n✓ BUILD SUCCESS")
    exe_path = "Release\\katago.exe"
    if os.path.exists(exe_path):
        print(f"✓ Found {exe_path}")
        # Copy to scythe_lizzie
        import shutil
        dest = "D:\\ScytheKatago\\scythe_lizzie\\katago.exe"
        shutil.copy2(exe_path, dest)
        print(f"✓ Copied to {dest}")
else:
    print("\n✗ BUILD FAILED")

sys.exit(result.returncode)
