import hashlib
import json
from pathlib import Path
import tempfile
import unittest

import validate_r4a as validator
import validate_r4b as storage_validator


class TicketBoundaryTests(unittest.TestCase):
    def test_nonempty_objectives_require_the_registered_mission_successor(self):
        manifest = json.loads((validator.GENERATED / 'manifest.json').read_text())
        objectives = json.loads((validator.GENERATED / 'objective_catalog.json').read_text())['definitions']
        self.assertEqual(storage_validator.objective_profile_errors(manifest, objectives), [])
        self.assertEqual(storage_validator.objective_profile_errors({}, []), [])
        for key, value in [('enabled_capabilities', []), ('compiler_version', 'unregistered-mission')]:
            bad = dict(manifest)
            bad[key] = value
            self.assertTrue(storage_validator.objective_profile_errors(bad, objectives))

    def test_coherent_manifest_cannot_qualify_another_unknown_item(self):
        original = validator.GENERATED
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            for source in original.glob('*.json'):
                (target / source.name).write_bytes(source.read_bytes())
            validator.GENERATED = target
            try:
                self.assertEqual(validator.check_static(), [])
                path = target / 'resource_catalog.json'
                resources = json.loads(path.read_text())
                unknown = next(r for r in resources['resources'] if r.get('reason') == 'ITEM_TYPE_ZERO_UNQUALIFIED')
                unknown['settlement_activation'] = 'ENABLED_R4'
                path.write_bytes(validator.canonical(resources) + b'\n')
                manifest_path = target / 'manifest.json'
                manifest = json.loads(manifest_path.read_text())
                manifest['artifact_sha256s']['resource_catalog.json'] = hashlib.sha256(path.read_bytes()).hexdigest()
                manifest.pop('revision_id')
                manifest['revision_id'] = hashlib.sha256(validator.canonical(manifest)).hexdigest()
                manifest_path.write_bytes(validator.canonical(manifest) + b'\n')
                errors = validator.check_static()
                self.assertIn('type0 qualification exceeded the single audited ticket', errors)
                self.assertFalse(any('hash drift' in error or 'digest mismatch' in error for error in errors))
            finally:
                validator.GENERATED = original


if __name__ == '__main__':
    unittest.main(verbosity=2)
