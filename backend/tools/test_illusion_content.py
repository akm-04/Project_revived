import copy
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from illusion_content import build_illusion


class IllusionCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = gen.SourceArchive(Path(archive)).read_verified()

    def test_source_rows_and_policy_binding(self):
        catalog = build_illusion(self.blobs, gen.parse_generated_lua_table)
        campaigns = {row['id']: row for row in catalog['campaigns']}
        self.assertEqual(sorted(campaigns), list(range(100001, 100013)))
        self.assertEqual(campaigns[100001]['name'], 'Pirate Captain ')
        self.assertEqual(campaigns[100001]['next_id'], 100002)
        self.assertEqual(campaigns[100001]['fight_id'], 1500001)
        self.assertEqual(campaigns[100001]['monster_id'], 89220003)
        self.assertEqual(campaigns[100010]['next_id'], 100012)
        self.assertEqual(campaigns[100011]['next_id'], 0)
        self.assertEqual(campaigns[100012]['next_id'], 100001)
        self.assertEqual(catalog['person_rewards'][0], dict(id=1, range=1, coin=1600, item_ids=[50001005, 50001006], item_nums=[12, 4]))
        self.assertEqual(catalog['person_rewards'][-1], dict(id=30, range=100000, coin=100, item_ids=[], item_nums=[]))
        self.assertEqual(catalog['community_rewards'][0], dict(id=1, range=1, coin=10000, person_coin=1000))
        self.assertEqual(catalog['community_rewards'][-1], dict(id=51, range=10000, coin=500, person_coin=450))
        self.assertEqual(catalog['policy_id'], 'I9_ILLUSION_POLICY_V1')
        self.assertEqual(catalog['policy_version'], 1)
        self.assertEqual(catalog['open_level'], 65)
        self.assertEqual(catalog['free_chances'], 5)
        self.assertEqual(catalog['chances_per_buy'], 5)
        self.assertEqual(catalog['damage_cap'], 12000000)
        self.assertEqual(catalog['open_second'], 28800)
        self.assertEqual(catalog['close_second'], 79080)
        self.assertEqual(catalog['settle_second'], 79200)
        self.assertEqual(catalog['team_hero_limit'], 5)
        self.assertEqual(catalog['team_power_limit'], 30)
        self.assertEqual(catalog['reward_percent_hundredths'], 20)
        self.assertEqual(catalog['buy_costs'][:7], [50, 100, 200, 300, 400, 500, 1000])
        self.assertEqual(catalog['buy_caps'], [0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])

    def test_campaign_chain_and_misc_drift_refused(self):
        source = gen.parse_generated_lua_table(self.blobs['data/tables/paradise_campaign.lua'].data)
        rows = copy.deepcopy(source)
        next(row for row in rows if row['campaign_id'] == '100010')['next_campaign_id'] = '100011'

        def campaign_parse(data):
            return rows if data == self.blobs['data/tables/paradise_campaign.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_illusion(self.blobs, campaign_parse)

        misc = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/misc.lua'].data))
        next(row for row in misc if row['key'] == 'paradise_daily_challenge_num')['value'] = '6'

        def misc_parse(data):
            return misc if data == self.blobs['data/tables/misc.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_illusion(self.blobs, misc_parse)

        vip = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/vip.lua'].data))
        next(row for row in vip if row['id'] == '3')['paradise_buy_num'] = '2'

        def vip_parse(data):
            return vip if data == self.blobs['data/tables/vip.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_illusion(self.blobs, vip_parse)

    def test_person_reward_drift_refused(self):
        rewards = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/paradise_person_reward.lua'].data))
        rewards[0]['range'] = '2'

        def reward_parse(data):
            return rewards if data == self.blobs['data/tables/paradise_person_reward.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):
            build_illusion(self.blobs, reward_parse)


if __name__ == '__main__':
    unittest.main(verbosity=2)
