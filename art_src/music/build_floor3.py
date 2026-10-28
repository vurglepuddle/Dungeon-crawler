"""The Lower Watch: an original score; preserve all five accepted pieces.

Offline authoring only. Reuses the existing preview synth, no external music.
"""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
from pathlib import Path
from build_score import ROOT, BASE, RATE, note, preview


def score():
    return dict(schema=1, id='floor3', title='The Watch Beneath the Bell',
        mode='D modal; Phrygian shadow against the E-natural bell call',
        bpm=52, beats=64, loop=True, notes=[
            # Ground changes slowly. Tension is harmonic, not added loudness.
            note(0,38,7.5,'drone',.22), note(8,45,7,'drone',.16),
            note(16,39,6.5,'drone',.12), note(24,38,7,'drone',.20),
            note(32,38,7.5,'drone',.21), note(40,34,7,'drone',.14),
            note(48,36,6.5,'drone',.14), note(56,38,7,'drone',.19),
            # The Porter's D-A-E-F call drops an octave from floor two.
            note(2,50,3,velocity=.32), note(6.5,57,2.5,velocity=.26),
            note(11,52,3,velocity=.29), note(15,53,3,velocity=.28),
            note(22,50,2.5,velocity=.27), note(24.5,51,2,velocity=.20),
            note(29,50,2.5,velocity=.25),
            # Second half varies the answer rather than repeating a short cell.
            note(33,62,2,velocity=.16),
            note(34.5,50,3,velocity=.29), note(39,57,2.5,velocity=.24),
            note(43,52,3,velocity=.27), note(47,53,3,velocity=.26),
            note(54,51,2.5,velocity=.21), note(58,48,2,velocity=.22),
            note(61,50,1.5,velocity=.25),
            # Midrange support survives small speakers without raising the bass.
            note(4.5,57,2,'reed',.10), note(19.5,51,1.25,'reed',.08),
            note(36.5,57,2,'reed',.09), note(51,55,1.5,'reed',.09),
        ])


def main():
    piece=score()
    piece['notes'].sort(key=lambda n:(n['beat'],n['pitch']))
    path=ROOT/'data/music/floor3.json'
    path.write_text(json.dumps(piece,indent=2)+'\n',encoding='utf-8')
    record=preview(piece)
    record.update(bpm=piece['bpm'],beats=piece['beats'],
                  score_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                  preview_sha256=hashlib.sha256((ROOT/record['preview']).read_bytes()).hexdigest())
    (BASE/'floor3_manifest.json').write_text(json.dumps({
        'authorship':'Original UNDERCROFT composition by Codex B, 2026-10-29',
        'motif_midi':[50,57,52,53], 'track':record,
        'runtime':'Music.play_floor(3) or Music.play("floor3")',
        'preserved':'The existing five scores and preview WAVs are not written.'},indent=2)+'\n')
    print(json.dumps(record,indent=2))


if __name__=='__main__':main()
