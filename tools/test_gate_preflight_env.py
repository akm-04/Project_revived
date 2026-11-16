#!/usr/bin/env python3
"""The preflight's fresh-database DSN follows the worker cluster variables and still defaults to the shared i853_dev cluster."""
import os
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_preflight  # noqa: E402

DEFAULT_DSN = 'postgres://postgres@/preflight?host=/home/akm/Chatgpt/EOL_Game/tmp/test-databases/i853_dev&port=55853'


class DatabaseDsnTests(unittest.TestCase):
    def test_defaults_to_the_shared_cluster(self):
        with mock.patch.dict(os.environ, {}, clear=False):
            os.environ.pop('GXB_TEST_PGHOST', None)
            os.environ.pop('GXB_TEST_PGPORT', None)
            self.assertEqual(gate_preflight.database_dsn('preflight'), DEFAULT_DSN)

    def test_follows_the_worker_cluster_variables(self):
        with mock.patch.dict(os.environ, {'GXB_TEST_PGHOST': '/tmp/worker_clusters/qprobe_01a', 'GXB_TEST_PGPORT': '56123'}):
            self.assertEqual(gate_preflight.database_dsn('r7_pf'),
                             'postgres://postgres@/r7_pf?host=/tmp/worker_clusters/qprobe_01a&port=56123')


if __name__ == '__main__':
    unittest.main()
