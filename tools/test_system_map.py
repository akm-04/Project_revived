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

    def test_client_senders_without_live_handler_are_classified(self):
        client = {
            '1': {'name': 'LIVE', 'senders': ['app/windows/Live.lua']},
            '2': {'name': 'FALLBACK', 'senders': ['app/model/Fallback.lua']},
            '3': {'name': 'UNREGISTERED', 'senders': ['app/model/Missing.lua']},
            '4': {'name': 'UNATTRIBUTED', 'senders': ['app/windows/Unknown.lua']},
            '5': {'name': 'NO_HANDLER_FILE', 'senders': ['app/model/NoHandler.lua']},
            '6': {'name': 'NOT_SENT', 'senders': []},
        }
        grouped = {
            1: [{'fallback': False, 'owner': 'guildcore', 'handler_file': 'dispatcher.go'}],
            2: [{'fallback': True, 'owner': 'guildcore'}],
            4: [{'fallback': False, 'owner': ''}],
            5: [{'fallback': False, 'owner': 'guildcore'}],
        }

        finding = system_map.client_senders_without_live_handler(client, grouped)

        self.assertEqual(finding['count'], 4)
        self.assertEqual(finding['window_sender_mid_count'], 1)
        self.assertEqual(finding['non_window_sender_mid_count'], 3)
        self.assertEqual(finding['registration_status_counts'], {
            'inactive_fallback': 1,
            'no_registration': 1,
            'unattributed_registration': 1,
            'registration_without_dispatch_handler': 1,
        })
        self.assertTrue(all(row['runtime_reachability'] == 'unknown' for row in finding['mids']))

    def test_show_unhandled_returns_generated_client_finding(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            (output / 'INDEX.json').write_text(json.dumps({'systems': []}))
            finding = {'count': 1, 'mids': [{'mid': 39}]}
            (output / 'FINDINGS.json').write_text(json.dumps({
                'client_senders_without_live_handler': finding,
            }))
            with patch.object(system_map, 'OUTPUT_DIRECTORY', output):
                captured = io.StringIO()
                with contextlib.redirect_stdout(captured):
                    system_map.show_entry('unhandled')
        self.assertEqual(json.loads(captured.getvalue()), finding)

    def test_show_mid_includes_its_class(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            systems = output / 'systems'
            systems.mkdir()
            (output / 'INDEX.json').write_text(json.dumps({
                'systems': [{'name': 'i5'}],
                'lookups': {'mid_to_system': {'161': 'i5'}},
            }))
            (systems / 'i5.json').write_text(json.dumps({'name': 'i5', 'mids': [{'mid': 161}]}))
            class_row = {'mid': 161, 'writes': 'state', 'isolation': [], 'read_only': [], 'retry': []}
            (output / 'MID_CLASSES.json').write_text(json.dumps({'mids': [class_row]}))
            with patch.object(system_map, 'OUTPUT_DIRECTORY', output), \
                    patch.object(system_map, 'SYSTEMS_DIRECTORY', systems), \
                    patch.object(system_map, 'load_client_callers', return_value={}):
                captured = io.StringIO()
                with contextlib.redirect_stdout(captured):
                    system_map.show_entry('161')
        self.assertEqual(json.loads(captured.getvalue())['class'], class_row)

    def test_mid_class_validation_rejects_unknown_write_class(self):
        with self.assertRaisesRegex(SystemExit, 'unknown writes class'):
            system_map.validate_mid_classes([{'mid': 1, 'writes': 'sometimes'}])
        with self.assertRaisesRegex(SystemExit, 'duplicate mid'):
            system_map.validate_mid_classes([{'mid': 1, 'writes': 'none'}, {'mid': 1, 'writes': 'none'}])

    def test_unresolved_lock_target_is_not_an_empty_table(self):
        lock = {'table': '', 'store': 'store/example', 'method': 'LockTx'}
        callers = {('store/example', 'LockTx'): {'owner'}}
        self.assertEqual(system_map.row_lock_methods_by_system(['owner'], [lock], callers), {'owner': {}})
        self.assertEqual(system_map.row_locks_by_system(['owner'], [lock], callers), {'owner': []})

    def test_trace_guard_rejects_sibling_route(self):
        with patch.object(system_map, 'TRACE_ANCHORS', {}), patch.object(system_map, 'FORBIDDEN_TRACE_ANCHORS', {1302: ['Service.Claim']}), patch.object(system_map, 'helper_trace', return_value='Service.Claim fixture.go:1'):
            with self.assertRaisesRegex(SystemExit, 'falsely reaches'):
                system_map.validate_trace_anchors()

    def test_inverse_calls_preserve_opposite_methods(self):
        outgoing = {'library': {'achievement': ['PrepareMarriageTx']}, 'achievement': {'library': ['HeroInputsTx']}}
        incoming = system_map.inverse_calls(['library', 'achievement'], outgoing)
        self.assertEqual(incoming['library']['achievement'], ['HeroInputsTx'])
        self.assertEqual(incoming['achievement']['library'], ['PrepareMarriageTx'])
        self.assertEqual(system_map.inverse_calls(['library', 'achievement'], incoming), outgoing)


if __name__ == '__main__':
    unittest.main()
