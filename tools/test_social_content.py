import copy
import json
import os
import sys
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_builtin_content as gen  # noqa: E402
from course_content import build_course  # noqa: E402
from social_content import build_social  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SOCIAL_TABLES = (
    'data/tables/friend_shop_item.lua',
    'data/tables/friend_recall.lua',
    'data/tables/invitation_mission.lua',
)


class SocialCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs = gen.SourceArchive(Path(archive)).read_verified()

    def build(self, parse_table=None):
        return build_social(
            self.blobs,
            parse_table or gen.parse_generated_lua_table,
            gen.CompileError,
        )

    def parse_modified(self, name, mutate):
        source = self.blobs['data/tables/' + name + '.lua'].data
        rows = copy.deepcopy(gen.parse_generated_lua_table(source))
        mutate(rows)

        def parse_table(data):
            if data == source:
                return rows
            return gen.parse_generated_lua_table(data)

        return parse_table

    def test_exact_source_catalog_facts(self):
        for path in SOCIAL_TABLES:
            self.assertIn(path, self.blobs)

        catalog = self.build()
        self.assertEqual(catalog['schema_version'], 1)

        products = catalog['exchange_products']
        self.assertEqual([row['id'] for row in products], [1, 2, 3])
        self.assertEqual([row['gift_id'] for row in products], [90032001, 90032002, 90032003])
        self.assertEqual([row['sell_type'] for row in products], [19, 19, 19])
        self.assertEqual([row['sell_price'] for row in products], [100, 500, 700])
        self.assertEqual([row['show_item'] for row in products], [50001311, 50001046, 50001024])

        dropboxes = {row['id']: row for row in catalog['dropboxes']}
        self.assertEqual(sorted(dropboxes), [510001, 510002, 510003])
        self.assertEqual([len(dropboxes[key]['rolls']) for key in sorted(dropboxes)], [50, 1, 1])
        self.assertEqual(sum(len(row['rolls']) for row in dropboxes.values()), 52)
        for dropbox in dropboxes.values():
            self.assertEqual(sum(roll['drop_rate'] for roll in dropbox['rolls']), 10000)
            self.assertTrue(all(roll['roll_type'] == 1 for roll in dropbox['rolls']))
            self.assertTrue(all(roll['item_num'] == 1 for roll in dropbox['rolls']))
        self.assertEqual(dropboxes[510001]['rolls'][0], dict(
            id=510001001, item_id=40001001, item_num=1, drop_rate=200, roll_type=1,
        ))
        self.assertEqual(dropboxes[510002]['rolls'][0]['item_id'], 50001046)
        self.assertEqual(dropboxes[510003]['rolls'][0]['item_id'], 50001024)
        self.assertNotIn(50001311, {roll['item_id'] for roll in dropboxes[510001]['rolls']})

        gifts = {row['id']: row for row in catalog['gifts']}
        self.assertEqual(len(gifts), 28)
        self.assertEqual(gifts[90070005], dict(
            id=90070005, crystal=100,
            items=[dict(item_id=50001011, quantity=5), dict(item_id=50001173, quantity=1)],
            drops=[],
        ))
        self.assertEqual(gifts[90070007]['crystal'], 50)
        self.assertEqual(gifts[90070007]['items'], [dict(item_id=40001106, quantity=10)])
        self.assertEqual(gifts[90032001], dict(id=90032001, crystal=0, items=[], drops=[510001]))
        self.assertEqual(gifts[90032003]['drops'], [510003])

        recalls = catalog['recall_milestones']
        self.assertEqual([row['id'] for row in recalls], list(range(100001, 100026)))
        self.assertEqual(Counter(row['type'] for row in recalls), {1: 4, 2: 2, 3: 4, 4: 15})
        self.assertEqual(recalls[0], dict(id=100001, type=1, condition=1, gift_id=90070001))
        self.assertEqual(recalls[-1], dict(id=100025, type=4, condition=500000, gift_id=90070025))
        self.assertEqual({row['gift_id'] for row in recalls}, set(range(90070001, 90070026)))

        missions = catalog['invitation_missions']
        self.assertEqual([row['id'] for row in missions], list(range(100001, 100251)))
        self.assertEqual(Counter(row['type'] for row in missions), {1: 10, 2: 40, 3: 50, 4: 150})
        self.assertTrue(all(row['requirement'] == 0 for row in missions))
        self.assertEqual(Counter(row['extra'] for row in missions), {0: 225, 1: 25})
        self.assertEqual(missions[0], dict(
            id=100001, type=1, required_count=1, threshold=None, diamond=16,
            requirement=0, extra=0, previous_task_ids=[],
            next_task_ids=[100002, 100004, 100005, 100006, 100007],
        ))
        self.assertEqual(missions[3]['required_count'], 1)
        self.assertEqual(missions[3]['threshold'], 20)
        self.assertEqual(missions[3]['previous_task_ids'], [100001])
        self.assertEqual(missions[-1]['id'], 100250)
        # REVIEW08 listed 25 roots; the rows give 21 because 100004-100007 have pre_task_id 100001.
        self.assertEqual(sum(1 for row in missions if not row['previous_task_ids']), 21)
        self.assertEqual(sum(1 for row in missions if not row['next_task_ids']), 24)

    def test_all_referenced_gifts_and_items_are_qualified(self):
        catalog = self.build()
        gifts = {row['id']: row for row in catalog['gifts']}
        referenced = {row['gift_id'] for row in catalog['exchange_products']}
        referenced.update(row['gift_id'] for row in catalog['recall_milestones'])
        self.assertEqual(len(referenced), 28)
        self.assertEqual(set(gifts), referenced)

        reward_item_ids = set()
        for dropbox in catalog['dropboxes']:
            reward_item_ids.update(roll['item_id'] for roll in dropbox['rolls'])
        for gift in catalog['gifts']:
            reward_item_ids.update(item['item_id'] for item in gift['items'])
        self.assertEqual(len(reward_item_ids), 59)
        self.assertFalse(reward_item_ids & set(gifts))

        source_item_ids = {
            int(row['id']) for row in gen.parse_encoded_item_table(
                self.blobs['data/tables/item.lua'].data
            )
        }
        self.assertFalse(reward_item_ids - source_item_ids)
        self.assertFalse({row['show_item'] for row in catalog['exchange_products']} - source_item_ids)

    def test_old_course_catalog_is_unchanged(self):
        items = gen.parse_encoded_item_table(self.blobs['data/tables/item.lua'].data)
        course = build_course(self.blobs, gen.parse_generated_lua_table, items)
        checked_in = json.loads(
            (ROOT / 'internal/content/builtin/generated/course_input_catalog.json').read_text()
        )
        self.assertEqual(course, checked_in)

    def test_duplicate_and_dangling_identities_refused(self):
        def duplicate_product(rows):
            rows[1]['id'] = '1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('friend_shop_item', duplicate_product))

        def dangling_product_gift(rows):
            rows[0]['gift_id'] = '99999999'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('friend_shop_item', dangling_product_gift))

        def duplicate_recall(rows):
            rows[1]['id'] = '100001'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('friend_recall', duplicate_recall))

        def dangling_recall_gift(rows):
            rows[0]['gift'] = '99999999'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('friend_recall', dangling_recall_gift))

        def duplicate_mission(rows):
            rows[1]['id'] = '100001'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', duplicate_mission))

    def test_gift_quantity_channel_and_drop_shape_refused(self):
        def mismatched_vector(rows):
            next(row for row in rows if row['id'] == '90070005')['item_nums'] = '5|1|1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('gift', mismatched_vector))

        def zero_quantity(rows):
            next(row for row in rows if row['id'] == '90070005')['item_nums'] = '0|1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('gift', zero_quantity))

        def unsupported_channel(rows):
            next(row for row in rows if row['id'] == '90070001')['mana'] = '1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('gift', unsupported_channel))

        def mixed_drop_channel(rows):
            next(row for row in rows if row['id'] == '90032001')['crystal'] = '5'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('gift', mixed_drop_channel))

        def drop_on_recall_gift(rows):
            next(row for row in rows if row['id'] == '90070001')['drops'] = '510001'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('gift', drop_on_recall_gift))

    def test_dropbox_weight_and_roll_shape_refused(self):
        def bad_weight(rows):
            next(row for row in rows if row['id'] == '510001001')['drop_rate'] = '201'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('dropbox', bad_weight))

        def bad_roll_type(rows):
            next(row for row in rows if row['id'] == '510002001')['roll_type'] = '2'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('dropbox', bad_roll_type))

        def zero_item_quantity(rows):
            next(row for row in rows if row['id'] == '510003001')['item_num'] = '0'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('dropbox', zero_item_quantity))

        def duplicate_outcome(rows):
            first = next(row for row in rows if row['id'] == '510001001')
            next(row for row in rows if row['id'] == '510001002')['item_id'] = first['item_id']

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('dropbox', duplicate_outcome))

    def test_mission_arity_and_metadata_refused(self):
        def one_field_for_type_two(rows):
            next(row for row in rows if row['id'] == '100004')['task_num'] = '1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', one_field_for_type_two))

        def two_fields_for_type_one(rows):
            next(row for row in rows if row['id'] == '100001')['task_num'] = '1|20'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', two_fields_for_type_one))

        def zero_threshold(rows):
            next(row for row in rows if row['id'] == '100004')['task_num'] = '1|0'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', zero_threshold))

        def nonzero_requirement(rows):
            next(row for row in rows if row['id'] == '100001')['req'] = '1'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', nonzero_requirement))

        def invalid_extra(rows):
            next(row for row in rows if row['id'] == '100001')['extra'] = '2'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', invalid_extra))

    def test_mission_graph_refused(self):
        def dangling_reference(rows):
            next(row for row in rows if row['id'] == '100001')['next_task_id'] = '999999'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', dangling_reference))

        def asymmetric_edge(rows):
            next(row for row in rows if row['id'] == '100002')['pre_task_id'] = '0'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', asymmetric_edge))

        def self_edge(rows):
            row = next(row for row in rows if row['id'] == '100001')
            row['next_task_id'] = row['next_task_id'] + '|100001'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', self_edge))

        def duplicate_edge(rows):
            row = next(row for row in rows if row['id'] == '100001')
            row['next_task_id'] = row['next_task_id'] + '|100002'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', duplicate_edge))

        def cycle(rows):
            next(row for row in rows if row['id'] == '100001')['pre_task_id'] = '100002'
            row = next(row for row in rows if row['id'] == '100002')
            row['next_task_id'] = row['next_task_id'] + '|100001'

        with self.assertRaises(ValueError):
            self.build(self.parse_modified('invitation_mission', cycle))

    def test_missing_and_mistyped_required_fields_refused(self):
        mutations = [
            ('friend_shop_item', lambda rows: rows[0].pop('id')),
            ('gift', lambda rows: next(row for row in rows if row['id'] == '90070005').update(items=None)),
            ('invitation_mission', lambda rows: rows[0].update(task_num=None)),
        ]
        for table_name, mutate in mutations:
            with self.subTest(table=table_name):
                with self.assertRaises(gen.CompileError):
                    self.build(self.parse_modified(table_name, mutate))


if __name__ == '__main__':
    unittest.main(verbosity=2)
