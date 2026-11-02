import copy
import unittest
import os
from pathlib import Path
from signin_content import build_signin
import generate_builtin_content as gen

class SignInCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive=os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive:raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs=gen.SourceArchive(Path(archive)).read_verified()

    def test_source_months_and_duplicate_conflict(self):
        catalog=build_signin(self.blobs,gen.parse_generated_lua_table)
        self.assertEqual([x['month'] for x in catalog['months']],list(range(1,13)))
        self.assertEqual([x['source_year'] for x in catalog['months']],[2023]*12)
        self.assertEqual(len(catalog['months'][1]['awards']),28)
        self.assertEqual(catalog['months'][9]['awards'][1]['award_item_id'],50009377)
        source=gen.parse_generated_lua_table(self.blobs['data/tables/sign_in.lua'].data)
        duplicate=copy.deepcopy(source[0]);duplicate['award_item_num']='999';source.append(duplicate)
        def parse(data):
            return source if data==self.blobs['data/tables/sign_in.lua'].data else gen.parse_generated_lua_table(data)
        with self.assertRaises(ValueError):build_signin(self.blobs,parse)

if __name__=='__main__':unittest.main()
