#!/usr/bin/env python3
import subprocess
import sys

print("===== Compiling KataGo =====")
result = subprocess.run(
    ["D:\\ScytheKatago\\quick_rebuild.bat"],
    shell=True,
    capture_output=True,
    text=True,
    encoding='utf-8',
    errors='ignore'
)

print("STDOUT:")
print(result.stdout)
print("\nSTDERR:")
print(result.stderr)
print(f"\nReturn code: {result.returncode}")

sys.exit(result.returncode)
