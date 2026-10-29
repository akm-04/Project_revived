import copy
import os
import unittest
from pathlib import Path

import generate_builtin_content as compiler
from arena_content import build_tournament


class TournamentCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = compiler.SourceArchive(Path(archive)).read_verified()

    def test_source_calendar_rewards_and_support(self):
        catalog = build_tournament(self.blobs, compiler.parse_generated_lua_table)
        self.assertEqual(catalog['rules']['stage_offsets_seconds'], [0, 86400, 185400, 271800, 275400, 358200, 361800, 365400])
        self.assertEqual(catalog['rules']['support_coefficients'], [5000, 580000, 18000000])
        self.assertEqual(catalog['rewards'][0], dict(rank=1, crystal=0, mana=20000000))
        self.assertEqual(catalog['casual_rewards'][0], dict(rank=1, crystal=2000, mana=2000000))
        self.assertEqual(catalog['casual_rewards'][-1]['rank'], 1000)
        self.assertEqual(catalog, build_tournament(self.blobs, compiler.parse_generated_lua_table))

    def test_rejects_calendar_and_reward_drift(self):
        for name, field, value in [('playoff_time', 'day', '14'), ('playoff_reward', 'mana', '-1'), ('relax_match_gift', 'rank', '2')]:
            with self.subTest(table=name):
                payload = self.blobs['data/tables/' + name + '.lua'].data
                rows = copy.deepcopy(compiler.parse_generated_lua_table(payload))
                rows[0][field] = value
                def parse(data):
                    return rows if data == payload else compiler.parse_generated_lua_table(data)
                with self.assertRaises(ValueError):
                    build_tournament(self.blobs, parse)


if __name__ == '__main__':
    unittest.main()
