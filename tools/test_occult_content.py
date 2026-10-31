import copy
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from occult_content import build_occult


class OccultCompilerTests(unittest.TestCase):
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
        catalog = build_occult(self.blobs, gen.parse_generated_lua_table)
        self.assertEqual(catalog['policy_id'], 'I9_OCCULT_POLICY_V1')
        self.assertEqual(catalog['policy_version'], 1)
        self.assertEqual([chapter['id'] for chapter in catalog['chapters']], [1, 2, 3, 4, 5, 6])
        self.assertEqual(catalog['chapters'][1]['item_display'], [50010002, 240001002, 40001132, 230001002])
        self.assertEqual(len(catalog['campaigns']), 118)
        self.assertEqual(sum(1 for campaign in catalog['campaigns'] if campaign['campaign_type'] == 1), 59)
        self.assertEqual(catalog['energy_per_ticket'], 3000)
        self.assertEqual(catalog['ticket_cap'], 2)
        self.assertEqual(catalog['room_capacity'], 3)
        self.assertEqual(catalog['room_seconds'], 3000)
        self.assertEqual(catalog['selection_seconds'], 60)
        self.assertEqual(catalog['fight_seconds'], 150)
        self.assertEqual(catalog['reentry_seconds'], 120)
        self.assertEqual(catalog['event_percent'], 30)
        self.assertEqual(catalog['event_dispatch'], 3)
        self.assertEqual(catalog['sweep_percent'], 60)

    def test_twenty_two_awakening_routes_by_mission_id(self):
        routes = build_occult(self.blobs, gen.parse_generated_lua_table)['awakening_routes']
        self.assertEqual(len(routes), 22)
        self.assertEqual({route['chapter_id'] for route in routes}, {2, 3, 4})
        by_mission = {route['mission_id']: route for route in routes}
        self.assertEqual(by_mission[1171001], dict(mission_id=1171001, chapter_id=2, fragment_item=60001170))
        self.assertEqual(sum(1 for route in routes if route['chapter_id'] == 2), 8)
        self.assertEqual(sum(1 for route in routes if route['chapter_id'] == 3), 7)
        self.assertEqual(sum(1 for route in routes if route['chapter_id'] == 4), 7)

    def test_route_drift_refused(self):
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/creats_chapter_select.lua'].data))
        next(row for row in rows if row['chapter_id'] == '2')['awaken_nums'] = '30|30|30|30|30|30|30|29'
        with self.assertRaises(ValueError):
            build_occult(self.blobs, self.parse_with('creats_chapter_select', rows))
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/creats_chapter_select.lua'].data))
        next(row for row in rows if row['chapter_id'] == '2')['awaken_items'] = '60001170'
        with self.assertRaises(ValueError):
            build_occult(self.blobs, self.parse_with('creats_chapter_select', rows))

    def test_campaign_and_misc_drift_refused(self):
        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/creats_campaign.lua'].data))
        rows.pop()
        with self.assertRaises(ValueError):
            build_occult(self.blobs, self.parse_with('creats_campaign', rows))

        rows = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/creats_campaign.lua'].data))
        next(row for row in rows if row['campaign_id'] == '10002')['unlock_id'] = '99999'
        with self.assertRaises(ValueError):
            build_occult(self.blobs, self.parse_with('creats_campaign', rows))

        misc = copy.deepcopy(gen.parse_generated_lua_table(self.blobs['data/tables/misc.lua'].data))
        next(row for row in misc if row['key'] == 'creats_ticket_get')['value'] = '2000'
        with self.assertRaises(ValueError):
            build_occult(self.blobs, self.parse_with('misc', misc))


if __name__ == '__main__':
    unittest.main(verbosity=2)
