import copy
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from adventure_content import build_adventure


class AdventureCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = gen.SourceArchive(Path(archive)).read_verified()

    def parse_with(self, name, rows):
        source = self.blobs['data/tables/' + name + '.lua'].data

        def parse(data):
            return rows if data == source else gen.parse_generated_lua_table(data)
        return parse

    def test_source_rows_and_policy_binding(self):
        catalog = build_adventure(self.blobs, gen.parse_generated_lua_table)
        self.assertEqual(catalog['policy_id'], 'I9_ADVENTURE_POLICY_V1')
        self.assertEqual(catalog['policy_version'], 1)
        self.assertEqual(catalog['open_academy_level'], 11)
        self.assertEqual(catalog['fantasy_open_level'], 65)
        self.assertEqual([event['id'] for event in catalog['events']], list(range(10001, 10007)))
        self.assertEqual([event['rate'] for event in catalog['events']], [3, 1, 6, 7, 4, 10])
        self.assertEqual([event['time_limit_seconds'] for event in catalog['events']], [10800, 3600, 3600, 7200, 3600, 10800])
        self.assertEqual([event['window_name'] for event in catalog['events']], [
            'adventure_defense', 'adventure_favor', 'adventure_shop',
            'adventure_battle', 'adventure_summon', 'adventure_illusion',
        ])
        self.assertEqual([row['id'] for row in catalog['shop']], list(range(1001, 1008)))
        self.assertEqual([row['price'] for row in catalog['shop']], [20, 20, 20, 50, 50, 50, 300])
        self.assertEqual(catalog['shop'][-1]['item'], 50001112)
        self.assertEqual(len(catalog['cards']), 72)
        self.assertEqual(sum(1 for row in catalog['cards'] if row['price'] == 88), 16)
        self.assertEqual(sum(1 for row in catalog['cards'] if row['price'] == 388), 56)
        self.assertEqual(catalog['cards'][0], dict(id=100001, item=10001001, price=88, rate=10000))
        self.assertEqual(len(catalog['campaigns']), 19)
        self.assertEqual(catalog['campaigns'][0], dict(
            id=100001, minimum_level=9, maximum_level=15,
            battle_ids=[981001, 981002, 981003], gift=90030001,
            models=[10001001, 10001012, 10001028],
        ))
        self.assertEqual(catalog['campaigns'][-1]['maximum_level'], 100)
        self.assertEqual(len(catalog['gifts']), 21)
        self.assertEqual(catalog['gifts'][0], dict(id=90030001, items=[50001002, 50001003, 50001010, 50001014], item_nums=[10, 10, 4, 5]))
        self.assertEqual(catalog['gifts'][-1]['id'], 90030022)
        self.assertEqual(catalog['limits']['defense_tries_per_position'], 3)
        self.assertEqual(catalog['limits']['defense_room_capacity'], 6)
        self.assertEqual(catalog['limits']['defense_level_band'], 5)
        self.assertEqual(catalog['limits']['pvp_ranking_section'], 3)
        self.assertEqual(catalog['limits']['favor_limit'], 2000)
        self.assertEqual(catalog['limits']['illusion_hidden_boss'], 100011)
        self.assertEqual(len(catalog['limits']['favor_gift_random']), 9)
        self.assertEqual(catalog['limits']['sweep_card_item'], 50001013)

    def test_event_and_shop_drift_refused(self):
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_event.lua'].data))
        rows.pop()
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_event', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_event.lua'].data))
        next(row for row in rows if row['id'] == '10001')['rate'] = '4'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_event', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_shop.lua'].data))
        next(row for row in rows if row['id'] == '1007')['price'] = '200'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_shop', rows))

    def test_card_and_campaign_drift_refused(self):
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_cards_dropbox.lua'].data))
        next(row for row in rows if row['id'] == '100001')['price'] = '388'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_cards_dropbox', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_campaign.lua'].data))
        rows[0]['battle_ids'] = '981001|981002'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_campaign', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/adventure_campaign.lua'].data))
        rows[1]['level_condition'] = '16|20'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('adventure_campaign', rows))

    def test_gift_drift_refused(self):
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/gift.lua'].data))
        next(row for row in rows if row['id'] == '90030021')['item_nums'] = '10|10|4'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('gift', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/gift.lua'].data))
        rows = [row for row in rows if row['id'] != '90030022']
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('gift', rows))

    def test_misc_drift_refused(self):
        misc = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/misc.lua'].data))
        next(row for row in misc if row['key'] == 'adventure_level_limit')['value'] = '6'
        with self.assertRaises(ValueError):
            build_adventure(self.blobs, self.parse_with('misc', misc))


if __name__ == '__main__':
    unittest.main(verbosity=2)
