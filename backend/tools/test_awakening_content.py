import copy
import os
from pathlib import Path
import unittest
from unittest.mock import patch
import generate_builtin_content as gen
from awakening_content import build_awakening

class AwakeningCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive=os.environ.get('GXB_R4A_SOURCE_ARCHIVE')
        if not archive: raise unittest.SkipTest('exact source archive not supplied')
        cls.blobs=gen.SourceArchive(Path(archive)).read_verified()

    def test_source_chains_and_blood_navigation(self):
        c=build_awakening(self.blobs,gen.parse_generated_lua_table)
        rows={r['id']:r for r in c['definitions']}
        self.assertEqual(len(rows),667)
        self.assertEqual(rows[1197001]['next'],1197003)
        self.assertEqual(rows[1197003]['previous'],1197002)
        self.assertEqual(rows[2001001]['routes'],[1300003])
        self.assertEqual(len([r for r in c['drops'] if r['mission']==2001001]),271)
        self.assertEqual(c['wish_item'],50005037)

    def test_bundle_rejects_awakening_template_outside_canonical_owner(self):
        content=build_awakening(self.blobs,gen.parse_generated_lua_table)
        content['definitions'][0]['after']=999999999
        with patch.object(gen,'build_awakening',return_value=content),self.assertRaisesRegex(gen.CompileError,'Unqualified awakening Character template'):
            gen.build_artifacts(self.blobs,gen.EXPECTED_SOURCE_ARCHIVE_SHA256)

    def test_rejects_broken_chain_rate_and_eligibility(self):
        for path,key,value in [('bloodline_incubus_monster','id','9999999'),('awaken_mission','next_task_id','9999999'),('campaign_dropbox','increase_rate','10000'),('misc','value','91')]:
            source=self.blobs['data/tables/'+path+'.lua'].data
            rows=copy.deepcopy(gen.parse_generated_lua_table(source))
            if path=='bloodline_incubus_monster': row=rows[0]
            elif path=='awaken_mission': row=next(r for r in rows if r['stage']=='1')
            elif path=='misc': row=next(r for r in rows if r['key']=='awaken_open_level')
            else:
                used=next(r['box'] for r in build_awakening(self.blobs,gen.parse_generated_lua_table)['drops'] if r['rate']==6666)
                row=next(r for r in rows if int(r['dropbox_id'])==used)
            row[key]=value
            def parse(data): return rows if data==source else gen.parse_generated_lua_table(data)
            with self.subTest(path=path),self.assertRaises(ValueError):build_awakening(self.blobs,parse)

if __name__=='__main__':unittest.main()
