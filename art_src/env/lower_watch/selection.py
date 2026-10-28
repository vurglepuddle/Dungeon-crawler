"""Presentation-only table compatible with A's existing cell hash and slots."""
FLOORS = ('dry_a','dry_b','dry_c','stain','chip','crack','wet_small','wet_hook','wet_corner','wet_split','wet_wide')
WEIGHTS = {1:(28,24,21,10,8,6,3,0,0,0,0), 2:(14,12,10,6,5,5,10,10,10,9,9),
           3:(26,22,18,10,10,7,3,1,1,1,1)}
CEILINGS = ('plain','root','drip')
CEILING_WEIGHTS = {1:(98,0,2),2:(82,10,8),3:(94,3,3)}


def mix_hash(value):
    result = 2166136261
    for code in value.encode('utf-8'): result = ((result ^ code)*16777619) & 0xffffffff
    for _ in range(2): result = ((result ^ (result >> 16))*0x45d9f3b) & 0xffffffff
    return (result ^ (result >> 16)) & 0x7fffffff


def pick(seed, floor, plane, x, y):
    roll = mix_hash(f'{seed}/{floor}/{plane}/{x}/{y}') % 100
    table = WEIGHTS if plane == 'floor' else CEILING_WEIGHTS
    names = FLOORS if plane == 'floor' else CEILINGS
    for name, weight in zip(names,table[min(3,max(1,floor))]):
        if roll < weight: return name
        roll -= weight
    raise AssertionError('Weights must total 100')


def texture_name(seed, floor, plane, x, y):
    prefix = 'calm_v3_f3_' if floor >= 3 else 'calm_v3_'
    return prefix+plane+'_'+pick(seed,floor,plane,x,y)
