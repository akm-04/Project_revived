"""Regression checks for system-map navigation and edge direction."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import system_map


class SystemMapViewTests(unittest.TestCase):
    def test_alias_keeps_canonical_relationships_and_wrapper(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            systems = output / 'systems'
            systems.mkdir()
            (output / 'INDEX.json').write_text(json.dumps({'systems': [{'name': 'i5'}]}))
            (systems / 'i5.json').write_text(json.dumps({'name': 'i5', 'tables': {}}))
            (output / 'EDGES.json').write_text(json.dumps({
                'calls': {'i5': {'grant_owner': ['SettleTx']}},
                'called_by': {'i5': {'campaign': ['PrepareTx']}},
                'composition': {'i5': ['cmd/example.go']},
            }))
            with patch.object(system_map, 'OUTPUT_DIRECTORY', output), patch.object(system_map, 'SYSTEMS_DIRECTORY', systems):
                canonical_output = io.StringIO()
                with contextlib.redirect_stdout(canonical_output):
                    system_map.show_entry('i5')
                alias_output = io.StringIO()
                with contextlib.redirect_stdout(alias_output):
                    system_map.show_entry('missions')
            canonical = json.loads(canonical_output.getvalue())
            alias = json.loads(alias_output.getvalue())
            self.assertEqual(alias['alias'], 'missions')
            self.assertEqual(alias['system'], 'i5')
            self.assertIn('note', alias)
            self.assertEqual(alias['record'], canonical)
            self.assertEqual(canonical['calls'], {'grant_owner': ['SettleTx']})
            self.assertEqual(canonical['called_by'], {'campaign': ['PrepareTx']})

    def test_generation_refuses_type_analysis_errors_before_writing(self):
        with patch.object(system_map, 'run_helper', return_value={'typed': {'analysis_errors': ['fixture: unresolved type']}}):
            with self.assertRaisesRegex(SystemExit, 'unresolved type'):
                system_map.build_system_map()

    def test_push_attribution_retains_unknown_registrations(self):
        known = {'file': 'internal/adapters/stockruntime/channelchat_notice.go', 'kind': 'notice', 'line': 1, 'app_imports': []}
        unknown = {'file': 'internal/adapters/stockruntime/tournament_notice.go', 'kind': 'notice', 'line': 2, 'notice_type': 13, 'app_imports': []}
        grouped, unattributed = system_map.partition_pushes([known, unknown], ['channelchat'])
        self.assertEqual(len(grouped['channelchat']), 1)
        self.assertEqual(unattributed, [unknown])
        self.assertEqual(sum(map(len, grouped.values())) + len(unattributed), 2)

    def test_unresolved_lock_target_is_not_an_empty_table(self):
        lock = {'table': '', 'store': 'store/example', 'method': 'LockTx'}
        callers = {('store/example', 'LockTx'): {'owner'}}
        self.assertEqual(system_map.row_lock_methods_by_system(['owner'], [lock], callers), {'owner': {}})
        self.assertEqual(system_map.row_locks_by_system(['owner'], [lock], callers), {'owner': []})

    def test_inverse_calls_preserve_opposite_methods(self):
        outgoing = {'library': {'achievement': ['PrepareMarriageTx']}, 'achievement': {'library': ['HeroInputsTx']}}
        incoming = system_map.inverse_calls(['library', 'achievement'], outgoing)
        self.assertEqual(incoming['library']['achievement'], ['HeroInputsTx'])
        self.assertEqual(incoming['achievement']['library'], ['PrepareMarriageTx'])
        self.assertEqual(system_map.inverse_calls(['library', 'achievement'], incoming), outgoing)


if __name__ == '__main__':
    unittest.main()
