"""Rebuild C's deliverables sequentially; no Godot launch, network or API."""
import subprocess
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
for script in ('env/build_env.py','icons/build_icons.py','portrait/build_portrait.py','screens/build_screens.py','env/verify_polish.py'):
    subprocess.run([sys.executable,'-B',str(ROOT/'art_src'/script)],cwd=ROOT,check=True)
