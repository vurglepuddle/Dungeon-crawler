"""Registered painted poses, NEAREST then shared indexed palette, no dithering.

Requirements: Pillow, NumPy, SciPy. Sources are preserved byte for byte.
Run from any directory. Never writes the old root assets/art PNGs.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from pathlib import Path
import numpy as np
from scipy import ndimage
from PIL import Image
from pipeline import ROOT, NEAREST, canvas, contact, manifest, paste, reduce, save, strip

BASE = Path(__file__).resolve().parent
CREATURES = ROOT / 'art_src/creatures'
STATES = ['idle', 'windup', 'recoil']


def split_characters(path, count):
    source = Image.open(path).convert('RGBA')
    rgba = np.array(source)
    labels, _ = ndimage.label(rgba[:, :, 3] >= 128)
    counts = np.bincount(labels.ravel())
    major = sorted(np.argsort(counts[1:])[-count:]+1,
                   key=lambda i: np.where(labels == i)[1].mean())
    centers = [np.where(labels == i)[1].mean() for i in major]
    groups = {int(i): [int(i)] for i in major}
    # Keep detached ghost cloth belonging to the nearest main silhouette.
    # Discard sub-32-source-pixel alpha flecks; these are cutout noise.
    for i in range(1, len(counts)):
        if i in major or counts[i] < 32:
            continue
        xs = np.where(labels == i)[1]
        owner = int(major[min(range(count), key=lambda k: abs(xs.mean()-centers[k]))])
        groups[owner].append(i)
    crops, bounds = [], []
    for i in major:
        mask = np.isin(labels, groups[int(i)])
        yy, xx = np.where(mask)
        box = (int(xx.min()), int(yy.min()), int(xx.max()+1), int(yy.max()+1))
        isolated = rgba.copy()
        isolated[:, :, 3] = np.where(mask, rgba[:, :, 3], 0)
        crops.append(Image.fromarray(isolated).crop(box))
        bounds.append(box)
    return crops, bounds


def registered(crops, size):
    # ONE scale per animation: never enlarge a crouch or recoil to idle height.
    scale = min((size[0]-2)/max(im.width for im in crops),
                (size[1]-2)/max(im.height for im in crops))
    frames = []
    for im in crops:
        resized = im.resize((max(1, round(im.width*scale)), max(1, round(im.height*scale))), NEAREST)
        frame = canvas(size)
        paste(frame, reduce(resized), ((size[0]-resized.width)//2, size[1]-1-resized.height))
        frames.append(frame)
    return frames, scale


def build_set(name, source_path, location, size64):
    crops, bounds = split_characters(source_path, 3)
    native, scale = registered(crops, size64)
    out = ROOT / 'assets/art' / ('anim' if name == 'bell_husk' else 'creatures')
    assets, rows = [], []
    for height in [64, 40, 24]:
        size = (round(size64[0]*height/64), height)
        # Smaller distances are exact nearest-neighbour derivatives of the
        # registered 64px poses, so important silhouette clusters stay together.
        frames = [im if height == 64 else im.resize(size, NEAREST) for im in native]
        for state, im in zip(STATES, frames):
            entry = save(im, out / f'{name}_{state}_{height}.png')
            entry.update(state=state, anchor=[size[0]//2, height], anchor_kind='feet / hover bottom centre')
            assets.append(entry)
        assets.append(save(strip(frames), out / f'{name}_strip_{height}.png'))
        rows.append((f'{height} px / native canvas', list(zip(STATES, frames))))
    contact(location / f'{name}_contact_4x.png', name.upper().replace('_', ' '), rows)
    data = {'source': source_path.relative_to(ROOT).as_posix(),
            'source_sha256': hashlib.sha256(source_path.read_bytes()).hexdigest(),
            'source_bounds': bounds, 'shared_source_scale_at_64': scale,
            'states': STATES, 'assets': assets}
    manifest(location / f'{name}_manifest.json', data)
    return native


def build_porter():
    path = BASE / 'sources/porter_restored.png'
    crops, bounds = split_characters(path, 1)
    assets, rows, natives = [], [], []
    for height in [64, 40, 24]:
        # Exactly the existing waiting asset's canvas dimensions.
        with Image.open(ROOT / f'assets/art/porter_{height}.png') as old:
            size = old.size
            waiting = reduce(old)
        # Porter's source has the same broad body proportions as its reference.
        scale = min(size[0]/crops[0].width, size[1]/crops[0].height)
        im = crops[0].resize((round(crops[0].width*scale), round(crops[0].height*scale)), NEAREST)
        frame = canvas(size)
        paste(frame, reduce(im), ((size[0]-im.width)//2, size[1]-im.height))
        entry = save(frame, ROOT / f'assets/art/anim/porter_restored_{height}.png')
        entry.update(state='restored', anchor=[size[0]//2, height], anchor_kind='feet bottom centre')
        assets.append(entry)
        rows.append((f'{height} px / old + restored', [('waiting', waiting), ('restored', frame)]))
        natives.append(frame)
    contact(BASE / 'porter_contact_4x.png', 'BELL PORTER / RESTORED', rows)
    manifest(BASE / 'porter_manifest.json', {'source': path.relative_to(ROOT).as_posix(), 'source_bounds': bounds, 'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'assets': assets})
    return natives[0]


def main():
    husk = build_set('bell_husk', BASE / 'sources/bell_husk_sheet.png', BASE, (64, 64))
    hound = build_set('ash_hound', CREATURES / 'sources/ash_hound_sheet.png', CREATURES, (96, 64))
    ghost = build_set('wick_ghost', CREATURES / 'sources/wick_ghost_sheet.png', CREATURES, (80, 64))
    porter = build_porter()
    contact(BASE / 'tells_64_contact_4x.png', 'POSE TELLS / 64 PX', [
        ('Bell Husk', list(zip(STATES, husk))),
        ('Ash Hound', list(zip(STATES, hound))),
        ('Wick Ghost', list(zip(STATES, ghost))),
        ('Bell Porter', [('restored', porter)])])
    print('Painted sets: 30 poses, 9 horizontal strips, all indexed with binary alpha')


if __name__ == '__main__':
    main()
