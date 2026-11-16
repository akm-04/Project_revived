#!/usr/bin/env python3
"""Self-check of preflight v2's units, ordering, list fallback and fixture environment. Fakes only: no PostgreSQL."""
import tempfile
import threading
import unittest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_pool  # noqa: E402
import gate_preflight  # noqa: E402


class UnitTests(unittest.TestCase):
    def test_sharded_units_cover_the_test_list_exactly_once(self):
        names = [f'TestExample{index:03d}' for index in range(50)]
        parallel = dict(gate_pool.EMPTY_PARALLEL, shards={'internal/fake': 6})
        units = gate_preflight.build_preflight_units(['./internal/fake'], parallel, lambda package: names)
        covered = [test for unit in units for test in (unit['tests'] or ())]
        self.assertEqual(sorted(covered), sorted(names))
        self.assertEqual(len(covered), len(set(covered)))
        self.assertTrue(all(unit['run'] for unit in units))

    def test_serial_tests_and_serial_packages_run_after_the_pool(self):
        parallel = dict(gate_pool.EMPTY_PARALLEL, serial=['internal/slow'],
                        serial_tests=['internal/fake.TestSerial'])
        units = gate_preflight.build_preflight_units(
            ['./internal/fake', './internal/slow'], parallel,
            lambda package: ['TestAlpha', 'TestSerial'] if package.endswith('fake') else ['TestSlow'])
        order, lock = [], threading.Lock()

        def record(unit):
            with lock:
                order.append(unit['unit'])

        gate_preflight.run_units(units, jobs=4, action=record, serial_packages=parallel['serial'])
        late = {unit['unit'] for unit in units if unit['serial'] or unit['package'] == './internal/slow'}
        first_late = min(order.index(name) for name in late)
        self.assertTrue(all(order.index(name) < first_late for name in order if name not in late), order)


class ListFallbackTests(unittest.TestCase):
    def test_lists_come_from_the_tree_when_present_else_from_this_tool(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            lists = tree / 'tools/strict_gate'
            lists.mkdir(parents=True)
            (lists / 'known_debt.json').write_text('{"entries": []}')
            paths = gate_preflight.list_paths(tree)
            self.assertEqual(paths['known_debt.json'], lists / 'known_debt.json')
            self.assertEqual(paths['skip_allowlist.json'], gate_preflight.TOOL_LISTS / 'skip_allowlist.json')
            self.assertEqual(paths['parallel.json'], gate_preflight.TOOL_LISTS / 'parallel.json')
            notes = '\n'.join(gate_preflight.list_notes(paths))
            self.assertIn(str(lists / 'known_debt.json'), notes)
            self.assertIn(str(gate_preflight.TOOL_LISTS / 'parallel.json'), notes)


class UnitEnvironmentTests(unittest.TestCase):
    def test_unit_environment_carries_the_suite_fixture_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            tree, scratch = Path(directory) / 'tree', Path(directory) / 'scratch'
            tree.mkdir()
            scratch.mkdir()
            environment = gate_preflight.unit_environment({}, tree, scratch, {'unit': 'unit_a'}, {})
            generated = tree / 'internal/content/builtin/generated'
            self.assertEqual(environment['GXB_BOOK_COMPILER_PAYLOAD'], str(generated / 'book_input_catalog.json'))
            self.assertEqual(environment['GXB_I9_10A_SCRATCH_JSON'], str(generated / 'workshop_input_catalog.json'))
            self.assertEqual(environment['GXB_SOCIAL_CATALOG_PATH'], str(generated / 'social_input_catalog.json'))


if __name__ == '__main__':
    unittest.main()
