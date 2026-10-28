"""Rebuild this revision only, preserving the first pack's existing PNGs."""
import subprocess
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
for script in ('env/painted_v2/build_painted.py','portrait/v2/build_states.py','ui_offer/build_offer.py','env/verify_polish.py'):
    subprocess.run([sys.executable,'-B',str(ROOT/'art_src'/script)],cwd=ROOT,check=True)
