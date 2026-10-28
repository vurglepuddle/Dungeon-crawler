"""Optional owner-converter comparison; shipping poses use build_creatures.py."""
import sys
sys.dont_write_bytecode = True
import argparse
import subprocess
from pathlib import Path
from PIL import Image
from build_creatures import BASE, split_characters
from pipeline import ROOT, NEAREST, contact, reduce, save

parser = argparse.ArgumentParser()
parser.add_argument('--converter', default='E:/SD/Raster_to_Pixel/target/release/raster_to_pixel.exe')
args = parser.parse_args()
crops, _ = split_characters(BASE / 'sources/bell_husk_sheet.png', 3)
source = BASE / 'sources/reduction_compare_windup.png'
crops[1].save(source)
target = BASE / 'reduction_detail_64.png'
subprocess.run([args.converter, str(source), str(target), '--size', '64', '--palette', str(ROOT / 'art_src/spike/palette.gpl'), '--cell', 'detail', '--alpha-mode', 'binary', '--cleanup', 'conservative', '--dither', 'none'], check=True)
detail = reduce(Image.open(target))
nearest = reduce(crops[1].resize(detail.size, NEAREST))
save(detail, target)
save(nearest, BASE / 'reduction_nearest_64.png')
contact(BASE / 'reduction_compare_4x.png', 'REDUCTION COMPARISON', [('64px cropped wind-up', [('nearest', nearest), ('detail', detail)])])
