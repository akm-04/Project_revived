#!/usr/bin/env python3
import sys
from pathlib import Path
from unittest import TestCase, main

sys.path.insert(0, str(Path(__file__).resolve().parent))
import charge_content  # noqa: E402


class Blob:
    def __init__(self, data):
        self.data = data


def misc_blobs(month, season, halfyear):
    rows = [
        {'key': 'monthly_card_time2', 'value': month},
        {'key': 'season_privilege_card', 'value': season},
        {'key': 'halfyear_privilege_card', 'value': halfyear},
    ]
    blobs = {'data/tables/misc.lua': Blob(b'')}
    return blobs, lambda data: rows


class CardDurationTests(TestCase):
    def test_reads_the_three_misc_keys(self):
        self.assertEqual(charge_content._card_days_by_type(*misc_blobs('30', '90', '180')), {1: 30, 2: 90, 3: 180})

    def test_refuses_source_drift(self):
        with self.assertRaises(ValueError):
            charge_content._card_days_by_type(*misc_blobs('31', '90', '180'))

    def test_refuses_missing_key(self):
        blobs, parse = misc_blobs('30', '90', '180')
        with self.assertRaises(ValueError):
            charge_content._card_days_by_type(blobs, lambda data: parse(data)[:2])


if __name__ == '__main__':
    main()
