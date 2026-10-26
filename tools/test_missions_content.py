import copy
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from missions_content import build_missions, build_activity, rewards


class MissionCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = gen.SourceArchive(Path(archive)).read_verified()

    def test_source_rows_and_condition_binding(self):
        catalog = build_missions(self.blobs, gen.parse_generated_lua_table)
        self.assertEqual(len(catalog['definitions']), 476)
        rows = {row['objective_id']: row for row in catalog['definitions']}
        self.assertEqual(rows[10002]['accepted_fact_kind'], 'CAMPAIGN_NORMAL_WIN')
        self.assertEqual(rows[70003]['accepted_fact_kind'], 'SUMMON')
        self.assertEqual(rows[10006]['presentation']['deferred_until'], 'I9-4B')
        self.assertEqual(rows[10011]['reward_plan']['Lines'], [dict(Kind='TEMPORAL', ResourceKey='energy', Amount=120)])
        self.assertEqual(rows[10002]['reward_plan']['Lines'], [])
        self.assertEqual(rows[10015]['presentation']['vip_sweep_reward'], True)
        self.assertEqual(rows[30001]['target'], 2)
        self.assertEqual(rows[40005]['target'], 3)
        self.assertEqual(rows[30014]['prerequisite_policy']['unavailable_reason'], 'UNKNOWN_SOURCE_CAMPAIGN_200114')
        self.assertEqual(rows[10014]['presentation']['deferred_until'], 'I10_COMMERCE_ACTIVE_ENTITLEMENTS')
        self.assertEqual(rows[30001]['presentation']['parameters'], [100019, 2])
        self.assertEqual(len(rows[10031]['presentation']['inscription_pool']), 12)
        self.assertIn(dict(item_id=160400101, weight=8), rows[10031]['presentation']['inscription_pool'])
        self.assertEqual(rows[10002]['presentation']['inscription_pool'], [])

    def test_unknown_condition_and_broken_chain_refused(self):
        source = gen.parse_generated_lua_table(self.blobs['data/tables/mission.lua'].data)
        for column, bad in [('task_req', '999'), ('next_task_id', '99999999'), ('task_id', source[0]['id'])]:
            rows = copy.deepcopy(source)
            rows[0][column] = bad
            def parse(data):
                return rows if data == self.blobs['data/tables/mission.lua'].data else gen.parse_generated_lua_table(data)
            with self.subTest(column=column), self.assertRaises(ValueError):
                build_missions(self.blobs, parse)

    def test_activity_fixed_gifts_and_unqualified_fields(self):
        activity = build_activity(self.blobs, gen.parse_generated_lua_table)
        self.assertEqual([r['medal'] for r in activity['rules']], [30, 60, 90, 120, 150, 500, 1000])
        gifts = {row['id']: row for row in activity['gifts']}
        self.assertEqual((gifts[90080003]['vip_threshold'], gifts[90080003]['vip_bonus']), (6, 120))
        self.assertIn(dict(Kind='STACK_ITEM', ItemID=50001979, Amount=1), gifts[90080005]['plan']['Lines'])
        source = gen.parse_generated_lua_table(self.blobs['data/tables/gift.lua'].data)
        for field, value in [('unreviewed_bonus', '1'), ('exp', '-1'), ('vip', '16'), ('item_nums', '1|2|3|4|5|6|7|8')]:
            rows = copy.deepcopy(source)
            next(r for r in rows if r['id'] == '90080003')[field] = value
            def parse(data):
                return rows if data == self.blobs['data/tables/gift.lua'].data else gen.parse_generated_lua_table(data)
            with self.subTest(field=field), self.assertRaises(ValueError):
                build_activity(self.blobs, parse)

    def test_reward_zero_is_not_fabricated(self):
        row = gen.parse_generated_lua_table(self.blobs['data/tables/mission.lua'].data)[0]
        self.assertEqual(rewards(row, '_new')['Lines'], [])
        row['num_new'] = '-1'
        with self.assertRaises(ValueError):
            rewards(row, '_new')


if __name__ == '__main__':
    unittest.main(verbosity=2)
