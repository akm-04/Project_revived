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

    def test_inverse_calls_preserve_opposite_methods(self):
        outgoing = {'library': {'achievement': ['PrepareMarriageTx']}, 'achievement': {'library': ['HeroInputsTx']}}
        incoming = system_map.inverse_calls(['library', 'achievement'], outgoing)
        self.assertEqual(incoming['library']['achievement'], ['HeroInputsTx'])
        self.assertEqual(incoming['achievement']['library'], ['PrepareMarriageTx'])
        self.assertEqual(system_map.inverse_calls(['library', 'achievement'], incoming), outgoing)


if __name__ == '__main__':
    unittest.main()
