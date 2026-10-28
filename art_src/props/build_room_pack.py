"""Rebuild this art batch only, then verify all C packs. No Godot/network."""
import subprocess
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
for script in ('props/build_props.py','env/room_faces/build_faces.py','screens/room_batch/build_identity.py','env/verify_polish.py'):
    subprocess.run([sys.executable,'-B',str(ROOT/'art_src'/script)],cwd=ROOT,check=True)
