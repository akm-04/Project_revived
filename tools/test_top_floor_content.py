import copy
import os
import unittest
from pathlib import Path

import generate_builtin_content as compiler
from top_floor_content import build_task_modes


class TaskModeCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = compiler.SourceArchive(Path(archive)).read_verified()

    def build(self, parse=compiler.parse_generated_lua_table):
        return build_task_modes(self.blobs, parse, compiler.parse_base64_indexed_lua_table, compiler.indexed_field)

    def test_source_rules_rewards_and_camps(self):
        catalog = self.build()
        self.assertEqual(len(catalog['schedule']), 91)
        self.assertEqual(catalog['schedule'][0]['date'], '20170811')
        self.assertEqual(catalog['schedule'][-1]['date'], '20190503')
        self.assertEqual(catalog['rules'][5]['buff_groups'], [[40011644, 40011645], [40011646], [40011647, 40011648, 40011649], [40011650]])
        self.assertEqual(catalog['rules'][0]['buff_groups'], [[40010688, 40010689, 40010690, 40010707]])
        self.assertEqual(catalog['rules'][2]['buff_groups'], [])
        self.assertTrue(catalog['rules'][3]['reset_defense'])
        self.assertEqual(catalog['rewards'][-1]['items'], [])
        self.assertEqual(catalog['rewards'][0]['items'][0], [50001174, 2])
        self.assertTrue(all(reward['best_rank_rate'] == 0 for reward in catalog['rewards']))
        self.assertEqual(len(catalog['hero_camps']), 569)
        self.assertTrue(all(isinstance(identifier, str) for identifier in catalog['hero_camps']))
        self.assertEqual(set(catalog['hero_camps'].values()), {1, 2, 3, 4})
        self.assertEqual((catalog['entry_rank'], catalog['entry_challenges'], catalog['server_level']), (200, 10, 60))
        self.assertEqual(catalog, self.build())

    def test_reward_vectors_reject_truncation_and_unpaired_zero(self):
        payload = self.blobs['data/tables/arena_mode_reward.lua'].data
        for mutation in ('missing_quantity', 'unpaired_zero'):
            with self.subTest(mutation=mutation):
                rows = copy.deepcopy(compiler.parse_generated_lua_table(payload))
                if mutation == 'missing_quantity':
                    rows[0]['daily_item_num'] = '1'
                else:
                    rows[-1]['daily_item_num'] = '1'
                def parse(data):
                    if data == payload:
                        return rows
                    return compiler.parse_generated_lua_table(data)
                with self.assertRaises(ValueError):
                    self.build(parse)


if __name__ == '__main__':
    unittest.main()
