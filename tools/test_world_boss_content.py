import copy
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from world_boss_content import build_world_boss


class WorldBossCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = gen.SourceArchive(Path(archive)).read_verified()

    def test_source_rows(self):
        catalog = build_world_boss(self.blobs, gen.parse_generated_lua_table)
        bosses = {row['id']: row for row in catalog['bosses']}
        self.assertEqual(sorted(bosses), [10011, 10012, 10013, 10014, 10015])
        self.assertEqual([bosses[index]['need_brave'] for index in sorted(bosses)], [20000000, 40000000, 60000000, 80000000, 100000000])
        self.assertEqual(bosses[10011]['name'], 'Karatine')
        self.assertEqual(bosses[10011]['fight_id'], 115012)
        self.assertEqual(bosses[10011]['monster_id'], 92000063)
        self.assertEqual(bosses[10011]['next_id'], 10012)
        self.assertEqual(bosses[10015]['next_id'], 0)
        self.assertEqual(bosses[10015]['defeat_stone'], 40001033)
        self.assertEqual(catalog['rank_rewards'][0], dict(range=1, diamond=480, mana=40000, stone=24))
        self.assertEqual(catalog['rank_rewards'][-1], dict(range=100000, diamond=10, mana=3600, stone=0))
        self.assertEqual(catalog['policy_id'], 'I9_WORLD_BOSS_POLICY_V1')
        self.assertEqual(catalog['policy_version'], 1)
        self.assertEqual(catalog['activity_id'], 1026)
        self.assertEqual(catalog['open_level'], 48)
        self.assertEqual(catalog['attempts'], 5)
        self.assertEqual(catalog['window_start_seconds'], 0)
        self.assertEqual(catalog['window_stop_seconds'], 79080)
        self.assertEqual(catalog['mail']['sender'], 'Commander')
        self.assertEqual(catalog['mail']['title'], 'Fate Rewards')
        self.assertEqual(catalog['texts']['title'], 'Fate Rules')
        self.assertEqual(catalog['texts']['rank_titles'], ['Karatine', 'Haxie', 'Gambler', 'Smartie', 'Saint'])

    def test_threshold_misc_and_reward_drift_refused(self):
        source = gen.parse_generated_lua_table(self.blobs['data/tables/dungeon_campaign.lua'].data)
        rows = copy.deepcopy(source)
        next(row for row in rows if row['campaign_id'] == '10011')['dungeon_brave_node'] = '21000000'

        def campaign_parse(data):
            return rows if data == self.blobs['data/tables/dungeon_campaign.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_world_boss(self.blobs, campaign_parse)

        rewards = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/dungeon_reward.lua'].data))
        rewards[0]['range'] = '2'

        def reward_parse(data):
            return rewards if data == self.blobs['data/tables/dungeon_reward.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_world_boss(self.blobs, reward_parse)

        misc = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/misc.lua'].data))
        next(row for row in misc if row['key'] == 'dungeon_challenge_limit')['value'] = '6'

        def misc_parse(data):
            return misc if data == self.blobs['data/tables/misc.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_world_boss(self.blobs, misc_parse)


if __name__ == '__main__':
    unittest.main(verbosity=2)
