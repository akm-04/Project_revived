#!/usr/bin/env python3
"""Pass150 Phase B4: synthetic EOL Recharge catalog hooks only."""
from __future__ import annotations
import json, os, subprocess, sys, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'; SRC=os.environ.get('GXB_SRC64','').strip()
from gxb_backend.content import GameDataCatalog
from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.state.commerce_purchase import UnsupportedPurchaseProduct
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices
CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def req(v,m):
    if not v: raise AssertionError(m)
def make():
    p=apply_established_profile(PlayerState()); p.account_uid='15040001'; p.player_id='15040001'; p.commerce_state={};p.backpack_items=[]
    return p,RequestServices(p,DATA,lambda:None,catalog=CATALOG)
def test_fresh_source_catalogs_and_eol_mapping():
    if SRC:
        with tempfile.TemporaryDirectory(prefix='pass150_b4_') as td:
            td=Path(td); skin=td/'skin.json'; gift=td/'gift.json'; eol=td/'eol.json'
            subprocess.run([sys.executable,str(ROOT/'tools/build_skin_source_catalog.py'),'--src64',SRC,'--data-dir',str(DATA),'--out',str(skin)],check=True)
            req(skin.read_bytes()==(DATA/'skin_source_catalog.json').read_bytes(),'skin source catalog stale vs fresh src64')
            subprocess.run([sys.executable,str(ROOT/'tools/build_gift_opening_source_catalog.py'),'--src64',SRC,'--output',str(gift)],check=True)
            req(gift.read_bytes()==(DATA/'gift_opening_source_catalog.json').read_bytes(),'gift source catalog stale vs fresh src64')
            subprocess.run([sys.executable,str(ROOT/'tools/build_recharge_eol_product_meta.py'),'--data-dir',str(DATA),'--output',str(eol)],check=True)
            req(eol.read_bytes()==(DATA/'recharge_eol_product_meta.json').read_bytes(),'synthetic EOL mapping drift')
def test_catalog_counts_ranges_and_source_links():
    c=RechargeSourceCatalog(DATA); rows=c.eol_products(); skins=c.eol_skin_products(); elems=c.eol_elemental_products()
    req((len(rows),len(skins),len(elems))==(272,262,10),'EOL product census drift')
    req({x.charge_id for x in skins}==set(range(97000001,97000263)),'skin charge id range drift')
    req({x.gift_id for x in skins}==set(range(97100001,97100263)),'skin gift id range drift')
    req({x.charge_id for x in elems}==set(range(97002001,97002011)),'element charge id range drift')
    req({x.gift_id for x in elems}==set(range(97102001,97102011)),'element gift id range drift')
    all_native={x.charge_id for x in c.direct_products()}|{x.charge_id for x in c.giftbag_products()}
    req(not (all_native & {x.charge_id for x in rows}),'synthetic/native charge collision')
    source_skin=json.loads((DATA/'skin_source_catalog.json').read_text())
    req({x.source_item_id for x in skins}=={int(x['skin_item_id']) for x in source_skin['skins']},'EOL skin set != canonical permanent skin set')
    expected={50001912,50001913,50009201,50009197,50009251,50009252,50009253,50009254,50009255,50009256}
    req({x.source_item_id for x in elems}==expected,'EOL elemental item set drift')
def test_synthetic_products_stay_hidden_until_ota():
    _p,s=make(); advertised={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data()['giftbags']}
    synthetic={x.charge_id for x in s.recharge_source_catalog.eol_products()}
    req(not (advertised & synthetic),'B4 synthetic product advertised before OTA')
    for cid in (97000001,97002001):
        try:
            s.commerce_settlement.settle({'intent_id':f'preota-{cid}','charge_id':cid,'platform':'lua_preservation'});ok=False
        except UnsupportedPurchaseProduct:ok=True
        req(ok,f'B4 synthetic {cid} authorized before OTA')
def test_b4_is_catalog_hook_not_parallel_commerce():
    _p,s=make()
    req(s.recharge_source_catalog.get_eol_product(97000001) is not None,'skin hook lookup missing')
    req(s.recharge_source_catalog.get_eol_product(97002010) is not None,'element hook lookup missing')
    req(s.recharge_source_catalog.get_giftbag(97000001) is None,'synthetic product leaked into source-native giftbag map')
    req(s.commerce_settlement.entitlements is s.commerce and s.commerce_settlement.uow is s.uow,'B4 changed Commerce authority graph')
def main():
    tests=[test_fresh_source_catalogs_and_eol_mapping,test_catalog_counts_ranges_and_source_links,test_synthetic_products_stay_hidden_until_ota,test_b4_is_catalog_hook_not_parallel_commerce]
    for t in tests:t();print('PASS',t.__name__)
    print(f'PASS Pass150 Recharge Phase B4 hooks ({len(tests)}/{len(tests)})')
if __name__=='__main__':main()
