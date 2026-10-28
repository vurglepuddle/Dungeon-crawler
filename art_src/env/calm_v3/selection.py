"""Presentation-only reference implementation. Port values, not this Python, to Godot."""
FLOOR_WEIGHTS = {
    1: [('dry_a',28),('dry_b',24),('dry_c',21),('stain',10),('chip',8),('crack',6),('wet_small',3)],
    2: [('dry_a',14),('dry_b',12),('dry_c',10),('stain',6),('chip',5),('crack',5),
        ('wet_small',10),('wet_hook',10),('wet_corner',10),('wet_split',9),('wet_wide',9)],
}
CEILING_WEIGHTS = {1:[('plain',98),('drip',2)],2:[('plain',82),('root',10),('drip',8)]}


def mix_hash(value):
    result = 2166136261
    for code in value.encode('utf-8'):
        result = ((result ^ code) * 16777619) & 0xffffffff
    for _ in range(2):
        result = ((result ^ (result >> 16)) * 0x45d9f3b) & 0xffffffff
    return (result ^ (result >> 16)) & 0x7fffffff


def pick(seed, floor, plane, x, y):
    floor = min(2, max(1, floor))
    key = f'{seed}/{floor}/{plane}/{x}/{y}'
    roll = mix_hash(key) % 100
    table = (FLOOR_WEIGHTS if plane == 'floor' else CEILING_WEIGHTS)[floor]
    for kind, weight in table:
        if roll < weight:
            return kind
        roll -= weight
    raise AssertionError('Weights must total 100')


def texture_name(seed, floor, plane, x, y):
    return f'calm_v3_{plane}_{pick(seed,floor,plane,x,y)}'
