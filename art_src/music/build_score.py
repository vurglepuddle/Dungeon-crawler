"""Original authored note lists; deterministic JSON and offline review WAVs.

No quotations, MIDI imports, samples, external composition or downloads.
Preview synthesis mirrors music.gd, but the game reads ONLY data/music/*.json.
"""
import sys
sys.dont_write_bytecode = True
import json
import math
from pathlib import Path
import wave
from array import array

ROOT = Path(__file__).resolve().parents[2]
BASE = Path(__file__).resolve().parent
RATE = 22050


def note(beat, pitch, beats, voice='bell', velocity=0.5):
    return dict(beat=beat, pitch=pitch, beats=beats, voice=voice, velocity=velocity)


def scores():
    return [
        dict(schema=1, id='title', title='The Unclaimed Door', mode='D Dorian',
             bpm=72, beats=24, loop=True, notes=[
                 note(0, 50, 7, 'drone', .30), note(8, 48, 7, 'drone', .25), note(16, 50, 7.5, 'drone', .28),
                 note(0, 74, 2.5), note(3, 81, 2.5, velocity=.42), note(6, 76, 2.5, velocity=.46), note(9, 77, 3),
                 note(13, 71, 2, 'reed', .23), note(16, 69, 2.5, velocity=.38), note(19, 76, 2), note(22, 74, 1.5),
                 note(4, 57, 2, 'reed', .18), note(12, 55, 2, 'reed', .18), note(20, 57, 2, 'reed', .18)]),
        dict(schema=1, id='floor', title='A Bell Below the Stone', mode='D Dorian',
             bpm=66, beats=32, loop=True, notes=[
                 note(0, 38, 7.5, 'drone', .28), note(8, 45, 7.5, 'drone', .23),
                 note(16, 36, 7.5, 'drone', .25), note(24, 38, 7.5, 'drone', .28),
                 note(1, 74, 2.5, velocity=.33), note(5, 81, 2, velocity=.25), note(8, 76, 2.5, velocity=.30), note(12, 77, 3, velocity=.32),
                 note(18, 74, 2.5, velocity=.28), note(22, 71, 2, velocity=.26), note(26, 69, 2.5, velocity=.27), note(29, 74, 2.5, velocity=.30),
                 note(3, 57, 2, 'reed', .17), note(11, 59, 2, 'reed', .16), note(19, 55, 2, 'reed', .17), note(27, 57, 2, 'reed', .17)]),
        dict(schema=1, id='win', title='Something Returned', mode='D Dorian',
             bpm=84, beats=8, loop=False, notes=[
                 note(0, 50, 6.5, 'drone', .30), note(0, 74, 1.6, velocity=.50), note(1, 81, 1.6, velocity=.43),
                 note(2, 76, 1.6, velocity=.46), note(3, 77, 1.6, velocity=.48), note(4, 83, 1.2, velocity=.35),
                 note(5, 86, 2.5, velocity=.48), note(5, 69, 2.5, 'reed', .23), note(5, 62, 2.5, 'reed', .22)])]


def round_sample(value):
    return int(math.floor(value+.5))


def preview(score):
    seconds_per_beat = 60/score['bpm']
    frames = round_sample(score['beats']*seconds_per_beat*RATE)
    mixed = [0.0]*frames
    for n in score['notes']:
        start = round_sample(n['beat']*seconds_per_beat*RATE)
        length = round_sample(n['beats']*seconds_per_beat*RATE)
        freq = 440 * 2**((n['pitch']-69)/12)
        bell = n['voice'] == 'bell'
        ratio = 2.756 if bell else (3.0 if n['voice'] == 'reed' else 2.0)
        partial = .32 if bell else (.12 if n['voice'] == 'reed' else .10)
        decay = math.exp(-(2.8 if bell else (.45 if n['voice'] == 'reed' else .12))/RATE)
        level = n['velocity']
        attack = 110 if bell else 441
        release = min(length//3, 2205)
        angle, other = math.tau*freq/RATE, math.tau*freq*ratio/RATE
        s, c, s2, c2 = 0., 1., 0., 1.
        ds, dc, ds2, dc2 = math.sin(angle), math.cos(angle), math.sin(other), math.cos(other)
        for age in range(min(length, frames-start)):
            env = min(1., age/attack, (length-age)/max(1, release))
            mixed[start+age] += (s+s2*partial)*level*env
            s, c = s*dc+c*ds, c*dc-s*ds
            s2, c2 = s2*dc2+c2*ds2, c2*dc2-s2*ds2
            level *= decay
    gain = .22*10**(-18/20)
    pcm = array('h', [round(max(-.8, min(.8, sample*.22))*10**(-18/20)*32767) for sample in mixed])
    if sys.byteorder != 'little': pcm.byteswap()
    path = BASE / 'previews' / f"{score['id']}.wav"
    path.parent.mkdir(exist_ok=True)
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE); wav.writeframes(pcm.tobytes())
    return dict(id=score['id'], seconds=round(frames/RATE, 5), notes=len(score['notes']),
                peak=round(max(abs(s) for s in mixed)*gain, 6), preview=path.relative_to(ROOT).as_posix())


def main():
    (ROOT / 'data/music').mkdir(parents=True, exist_ok=True)
    records = []
    for score in scores():
        score['notes'].sort(key=lambda n: (n['beat'], n['pitch']))
        (ROOT / 'data/music' / f"{score['id']}.json").write_text(json.dumps(score, indent=2)+'\n', encoding='utf-8')
        records.append(preview(score))
    (BASE / 'manifest.json').write_text(json.dumps({'authorship': 'Original UNDERCROFT compositions by Codex B, 2026-10-28', 'motif_midi': [74, 81, 76, 77], 'tracks': records}, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(records, indent=2))


if __name__ == '__main__': main()
