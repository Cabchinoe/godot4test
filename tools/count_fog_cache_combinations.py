#!/usr/bin/env python3

import argparse
import json
from collections import Counter
from itertools import product


OFFSETS = ((0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1))
PERMUTATIONS = tuple(
    tuple(((index - turn) if not mirrored else -(index - turn)) % 8 for index in range(8))
    for mirrored in (False, True)
    for turn in (0, 2, 4, 6)
)


def normalized_shape(samples):
    bits = [int(value > 0) for value in samples]
    for diagonal in (1, 3, 5, 7):
        bits[diagonal] &= bits[(diagonal - 1) % 8] & bits[(diagonal + 1) % 8]
    return tuple(bits)


def cache_key(center, neighbors):
    uniform = all(value in (0, center) for value in neighbors)
    candidates = []
    for permutation in PERMUTATIONS:
        transformed = tuple(neighbors[index] for index in permutation)
        shape = normalized_shape(transformed)
        candidates.append((shape, transformed))
    shape, transformed = min(candidates)
    if uniform:
        return ("uniform", center, shape)
    return ("mixed", center, shape, transformed)


def density_at(column, row, vision_range, wall_shadows):
    distance = max(abs(column), abs(row))
    if distance == 0 and not wall_shadows:
        return 0
    if distance <= vision_range:
        return 8 if wall_shadows else 0
    return min(8, 4 + distance - vision_range)


def collect_templates(vision_range, wall_shadows):
    templates = set()
    for column in range(vision_range + 6):
        for row in range(vision_range + 6):
            center = density_at(column, row, vision_range, wall_shadows)
            if center == 0:
                continue
            neighbors = tuple(
                density_at(column + delta_x, row + delta_y, vision_range, wall_shadows)
                for delta_x, delta_y in OFFSETS
            )
            templates.add((center, neighbors))
    return templates


def collect_keys(vision_range, wall_shadows, holes):
    templates = collect_templates(vision_range, wall_shadows)
    keys = set()
    oriented_states = set()
    for center, neighbors in templates:
        choices = [(0, value) if holes and value else (value,) for value in neighbors]
        for samples in product(*choices):
            oriented_states.add((center, samples))
            keys.add(cache_key(center, samples))
    return templates, oriented_states, keys


def count_combinations(vision_range, wall_shadows, holes):
    templates, oriented_states, keys = collect_keys(vision_range, wall_shadows, holes)
    categories = Counter(key[0] for key in keys)
    centers = {
        str(center): {
            "uniform": sum(key[0] == "uniform" and key[1] == center for key in keys),
            "mixed": sum(key[0] == "mixed" and key[1] == center for key in keys),
        }
        for center in (5, 6, 7, 8)
    }
    return {
        "vision_range": vision_range,
        "wall_shadows": wall_shadows,
        "holes": holes,
        "base_templates": len(templates),
        "oriented_states": len(oriented_states),
        "uniform": categories["uniform"],
        "mixed": categories["mixed"],
        "total": len(keys),
        "by_center": centers,
    }


def verify_counts():
    expected = (
        (False, False, 13),
        (False, True, 1100),
        (True, True, 1582),
    )
    for shadows, holes, total in expected:
        assert count_combinations(16, shadows, holes)["total"] == total
    templates, oriented, keys = collect_keys(16, True, True)
    assert len(templates) == 24 and len(oriented) == 4360 and len(keys) == 1582
    positions = ((0, 0),) + OFFSETS
    allowed_pairs = {(5, 6), (6, 7), (7, 8), (5, 8)}
    for center, samples in oriented:
        values = (center,) + samples
        for first in range(9):
            for second in range(first + 1, 9):
                first_x, first_y = positions[first]
                second_x, second_y = positions[second]
                if max(abs(first_x - second_x), abs(first_y - second_y)) != 1:
                    continue
                pair = tuple(sorted((values[first], values[second])))
                assert 0 in pair or pair[0] == pair[1] or pair in allowed_pairs
        assert cache_key(center, samples) in keys
        for permutation in PERMUTATIONS:
            transformed = tuple(samples[index] for index in permutation)
            assert cache_key(center, transformed) == cache_key(center, samples)
    for vision_range in range(1, 17):
        assert collect_keys(vision_range, True, True)[2] == keys
    zero_keys = collect_keys(0, True, True)[2]
    assert len(zero_keys) == 1311
    assert len(zero_keys - keys) == 70
    assert len(zero_keys | keys) == 1652
    print("PASS: distance constraints, 47 normalization, D4 invariance, 1..16 range equivalence, zero-range union.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vision-range", type=int, default=16)
    parser.add_argument("--check-ranges", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if args.vision_range < 0:
        parser.error("--vision-range must be nonnegative")
    if args.verify:
        verify_counts()
    result = {
        "scope": "possible local display fields across arbitrary level layouts, fixed Chebyshev range; initial/stable states only",
        "normal_distance_only": count_combinations(args.vision_range, False, False),
        "distance_with_holes": count_combinations(args.vision_range, False, True),
        "full_rules_with_shadows_and_holes": count_combinations(args.vision_range, True, True),
    }
    if args.check_ranges:
        result["range_summary"] = {
            str(value): count_combinations(value, True, True)
            for value in (0, 1, 2, 3, 4, 8, 16, 32)
        }
        union = set()
        additions = {}
        for value in (2, 1, 0, 3, 4, 8, 16, 32):
            _, _, keys = collect_keys(value, True, True)
            additions[str(value)] = len(keys - union)
            union.update(keys)
        result["combined_ranges"] = {
            "new_keys_by_range": additions,
            "uniform": sum(key[0] == "uniform" for key in union),
            "mixed": sum(key[0] == "mixed" for key in union),
            "total": len(union),
        }
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
