import copy
import os
import sys
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_builtin_content as gen  # noqa: E402
import mentor_content as mc  # noqa: E402


class MentorCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:
            raise unittest.SkipTest('exact c7e source archive not supplied')
        cls.blobs = mc.read_mentor_blobs(archive)
        cls._parsed = {}
        cls.catalog = cls.build()

    @classmethod
    def parse_table(cls, data):
        key = id(data)
        if key not in cls._parsed:
            cls._parsed[key] = gen.parse_generated_lua_table(data)
        return copy.deepcopy(cls._parsed[key])

    @classmethod
    def build(cls, parse_table=None):
        return mc.build_mentor(cls.blobs, parse_table or cls.parse_table, gen.CompileError)

    def build_with(self, table, mutate):
        source = self.blobs[table].data
        rows = copy.deepcopy(self._parsed[id(source)])
        mutate(rows)

        def parse_table(data):
            if data == source:
                return copy.deepcopy(rows)
            return self.parse_table(data)

        return self.build(parse_table)

    def assert_rejected(self, builder):
        with self.assertRaises(gen.CompileError):
            builder()

    def test_source_tables_are_exactly_pinned(self):
        teacher = self.blobs[mc.MENTOR_TEACHER_TABLE]
        self.assertEqual(teacher.sha256, mc.MENTOR_TEACHER_SHA256)
        self.assertEqual(teacher.role, mc.MENTOR_SOURCE_ROLE)
        for path in mc.MENTOR_SOURCE_TABLES:
            self.assertIn(path, self.blobs)

    def test_exact_source_catalog_facts(self):
        catalog = self.catalog
        self.assertEqual(catalog['schema_version'], 1)
        missions = catalog['missions']
        self.assertEqual([row['id'] for row in missions], list(range(100001, 100026)))
        self.assertEqual(Counter(row['type'] for row in missions), Counter({1: 21, 2: 4}))
        self.assertEqual(
            Counter(row['category'] for row in missions),
            Counter({1: 4, 2: 8, 3: 6, 4: 3, 5: 1, 6: 2, 7: 1}),
        )
        hidden = [row for row in missions if row['is_hide'] == 1]
        self.assertEqual([row['id'] for row in hidden], [100005, 100006])
        self.assertEqual([(row['level'], row['condition']) for row in hidden], [(9000, 1000000), (9001, 1000001)])
        self.assertEqual([row['gift_id'] for row in missions], list(range(90008004, 90008029)))
        finish = missions[-1]
        self.assertEqual(
            (finish['id'], finish['type'], finish['category'], finish['level'], finish['extra_info'], finish['is_hide']),
            (100025, 2, 7, 90, 22608, 0),
        )
        self.assertEqual(catalog['rules'], dict(
            relation_daily=100,
            relation_max=3000,
            teacher_level=60,
            relation_broken_seconds=86400,
            relation_send_times=3,
            relation_send_broken_seconds=172800,
            terminate_time_limit_seconds=86400,
            finding_num=20,
            student_level_limit=90,
            finding_range=100,
            level_relation=3,
            gift_intimacy=100,
            player_open_level=10,
            finish_mission_id=100025,
            teacher_min_level=60,
        ))
        self.assertEqual(catalog['function_50'], dict(
            id=50,
            name='My Class',
            level='8|10',
            condition='60',
            icon='1',
            level_tips='0',
            is_on_levelup_wnd='1',
            open_control='1',
            tip='Unlock when Academy level reaches 10',
            is_function_show='',
            fx_num='',
            function_pic='',
            function_desc='',
        ))
        help_source = {row['name']: row['translation'] for row in self._parsed[id(
            self.blobs['data/tables/translation.lua'].data
        )]}
        self.assertEqual(catalog['help']['rule'], help_source['TEACHER_RULE'])
        self.assertEqual(catalog['help']['open_tips'], help_source['TEACHER_OPEN_TIPS'])
        self.assertEqual(catalog['help']['mentor_name'], 'Mentor')
        self.assertEqual(catalog['help']['student_name'], 'Student')
        self.assertEqual(mc.help_digest(catalog['help']), mc._EXPECTED_HELP_DIGEST)

    def test_catalog_digest_binds_golden_fixture(self):
        self.assertEqual(mc.catalog_digest(self.catalog), mc.MENTOR_CATALOG_SHA256)

    def test_integer_contract_is_bounded_and_canonical(self):
        accepted = {'0': 0, '+5': 5, ' 5 ': 5, str(2 ** 63 - 1): 2 ** 63 - 1}
        for raw, expected in accepted.items():
            self.assertEqual(mc._integer(raw, 'value', gen.CompileError), expected)
        for raw in ('01', '1.0', '1e3', 'nan', 'inf', str(2 ** 63), str(-(2 ** 63) - 1), float('inf'), float('nan')):
            with self.assertRaises(gen.CompileError):
                mc._integer(raw, 'value', gen.CompileError)

    def test_missing_table_is_rejected(self):
        blobs = dict(self.blobs)
        del blobs[mc.MENTOR_TEACHER_TABLE]
        self.assert_rejected(lambda: mc.build_mentor(blobs, self.parse_table, gen.CompileError))

    def test_duplicate_mission_id_is_rejected(self):
        def mutate(rows):
            rows[1]['id'] = rows[0]['id']
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_mistyped_mission_field_is_rejected(self):
        def mutate(rows):
            rows[0]['condition'] = 'one'
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_mission_integer_overflow_is_rejected(self):
        def mutate(rows):
            rows[0]['condition'] = str(2 ** 63)
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_unknown_mission_field_is_rejected(self):
        def mutate(rows):
            rows[0]['unexpected'] = 'x'
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_missing_hidden_mission_is_rejected(self):
        def mutate(rows):
            rows[:] = [row for row in rows if row['id'] != '100005']
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_missing_gift_reference_is_rejected(self):
        def mutate(rows):
            rows[0]['gift'] = '99999999'
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_hidden_mission_drift_is_rejected(self):
        def mutate(rows):
            for row in rows:
                if row['id'] == '100005':
                    row['is_hide'] = '0'
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_finish_mission_drift_is_rejected(self):
        def mutate(rows):
            rows[-1]['category'] = '6'
        self.assert_rejected(lambda: self.build_with(mc.MENTOR_TEACHER_TABLE, mutate))

    def test_duplicate_misc_key_is_rejected(self):
        def mutate(rows):
            rows.append(dict(rows[0]))
        self.assert_rejected(lambda: self.build_with('data/tables/misc.lua', mutate))

    def test_mistyped_misc_value_is_rejected(self):
        def mutate(rows):
            for row in rows:
                if row['key'] == 'teacher_lev':
                    row['value'] = 'many'
        self.assert_rejected(lambda: self.build_with('data/tables/misc.lua', mutate))

    def test_rule_drift_is_rejected(self):
        def mutate(rows):
            for row in rows:
                if row['key'] == 'teacher_lev_relation':
                    row['value'] = '4'
        self.assert_rejected(lambda: self.build_with('data/tables/misc.lua', mutate))

    def test_duplicate_function_is_rejected(self):
        def mutate(rows):
            rows.append(dict(rows[0]))
        self.assert_rejected(lambda: self.build_with('data/tables/function.lua', mutate))

    def test_missing_help_string_is_rejected(self):
        def mutate(rows):
            rows[:] = [row for row in rows if row['name'] != 'TEACHER_RULE']
        self.assert_rejected(lambda: self.build_with('data/tables/translation.lua', mutate))

    def test_help_drift_is_rejected(self):
        def mutate(rows):
            for row in rows:
                if row['name'] == 'TEACHER_OPEN_TIPS':
                    row['translation'] = 'Unlock at lv10'
        self.assert_rejected(lambda: self.build_with('data/tables/translation.lua', mutate))

    def test_duplicate_help_string_is_rejected(self):
        def mutate(rows):
            rows.append(next(dict(row) for row in rows if row['name'] == 'TEACHER_RULE'))
        self.assert_rejected(lambda: self.build_with('data/tables/translation.lua', mutate))


if __name__ == '__main__':
    unittest.main()
