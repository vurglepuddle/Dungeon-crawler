"""Asset contracts for closed dressing, independently of game integration."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import hashlib
import json
from collections import deque
from PIL import Image
from pipeline import ROOT,RGB,TABLE,NEAREST
from build_closed import patch_mask

BASE=Path(__file__).resolve().parent


def largest_dark_region(im,box):
    # The old false arch had one broad, connected near-black doorway. Detect
    # that silhouette returning, while allowing narrow mortar/board cracks.
    x0,y0,x1,y1=box
    dark={(x,y) for y in range(y0,y1) for x in range(x0,x1)
        if sum(RGB[im.getpixel((x,y))])<105}
    largest=0
    while dark:
        first=dark.pop();count=1;queue=deque([first])
        while queue:
            x,y=queue.popleft()
            for point in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if point in dark:
                    dark.remove(point);queue.append(point);count+=1
        largest=max(largest,count)
    return largest


def main():
    receipt=json.loads((BASE/'preserved_hashes.json').read_text())
    for name,digest in receipt.items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
    data=json.loads((BASE/'manifest.json').read_text())
    assert len(data['registrations'])==4
    mask=patch_mask();metrics={}
    for r in data['registrations']:
        im=Image.open(ROOT/r['path']);base=Image.open(ROOT/r['base'])
        assert im.mode=='P' and im.size==(64,64) and im.getpalette()==TABLE
        assert set(im.getdata())<=set(range(1,32)) and r['interactive'] is False
        for y in range(64):
            for x in range(64):
                if not mask.getpixel((x,y)):
                    assert im.getpixel((x,y))==base.getpixel((x,y)),(r['path'],x,y)
        for box in ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)):
            assert im.crop(box).tobytes()==base.crop(box).tobytes()
        assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes()
        assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes()
        region=largest_dark_region(im,(20,21,44,54))
        old=Image.open(ROOT/f'assets/art/env/painted_f{r["floor"]}_arch.png')
        old_region=largest_dark_region(old,(20,21,44,54))
        assert region<old_region*0.5,(r,region,old_region)
        metrics[r['path']]={'largest_connected_dark_region':region,'old_arch_region':old_region}
    for native in BASE.glob('*native.png'):
        with Image.open(native) as a,Image.open(native.with_name(native.name.replace('native','4x'))) as b:
            assert b.size==(a.width*4,a.height*4)
            assert a.resize(b.size,NEAREST).tobytes()==b.tobytes()
    (BASE/'verification.json').write_text(json.dumps(metrics,indent=2)+'\n')
    print(f'Closed dressing verified: 4 opaque wall faces; original substrate outside patch; common rings; no broad dark doorway; exact 4x proofs; {len(receipt)} old C PNGs unchanged.')


if __name__=='__main__':main()
