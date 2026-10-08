import unittest,json,copy
from pathlib import Path
from content_generation_policy import qualified_social_gift_scalar_delta
ROOT=Path(__file__).resolve().parents[1]
class QualificationTests(unittest.TestCase):
 def test_exact_new_scalar_preserves_historical_catalog(self):
  p=json.loads((ROOT/'internal/content/builtin/generated/resource_catalog.json').read_text());self.assertTrue(qualified_social_gift_scalar_delta(ROOT,p))
 def test_mutations_never_waive_old_rows_or_invent_ids(self):
  base=json.loads((ROOT/'internal/content/builtin/generated/resource_catalog.json').read_text())
  for kind in ['numeric_id','extra_scalar','old_activation','missing_row']:
   with self.subTest(kind=kind):
    p=copy.deepcopy(base);row=next(r for r in p['resources']if r.get('resource_key')=='friendship_coin')
    if kind=='numeric_id':row['source_asset_id']=1
    if kind=='extra_scalar':p['resources'].append(dict(row,definition_key='scalar_currency:guess',resource_key='guess'))
    if kind=='old_activation':next(r for r in p['resources']if r.get('resource_key')=='mana')['settlement_activation']='FAIL_CLOSED'
    if kind=='missing_row':p['resources'].pop(0)
    self.assertFalse(qualified_social_gift_scalar_delta(ROOT,p))
if __name__=='__main__':unittest.main()
