#!/usr/bin/env python3
"""Pass211 Stage F effective-src64 reality verifier."""
from __future__ import annotations
import argparse,hashlib,json,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EXPECTED_FILES=4370

def require(v,msg):
    if not v: raise AssertionError(msg)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def text(rel):return (SRC/rel).read_text(encoding='utf-8-sig')

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--src-root',type=Path,required=True); ap.add_argument('--data-root',type=Path,default=ROOT/'data'); ns=ap.parse_args()
    global SRC,DATA
    SRC=ns.src_root.resolve(); DATA=ns.data_root.resolve()
    files=[p for p in SRC.rglob('*') if p.is_file()];require(len(files)==EXPECTED_FILES,f'src64 census {len(files)} != {EXPECTED_FILES}')
    rels=['app/model/Occult.lua','app/windows/OccultWindow.lua','app/common/tables/CreatsChapterSelectTable.lua','app/common/tables/MiscTable.lua','app/common/network/mid.lua','app/model/SelfPlayer.lua','app/common/network/Backend.lua','data/tables/creats_chapter_select.lua','data/tables/misc.lua']
    hashes={r:sha(SRC/r) for r in rels}
    occult=text('app/model/Occult.lua'); win=text('app/windows/OccultWindow.lua'); mids=text('app/common/network/mid.lua'); misc=text('data/tables/misc.lua'); chapters=text('data/tables/creats_chapter_select.lua'); table=text('app/common/tables/CreatsChapterSelectTable.lua'); selfp=text('app/model/SelfPlayer.lua')
    require('xyd.mid.GET_INFO' in occult and 'xyd.mid.OCCULT_SWEEP' in occult,'Occult model MID callers missing')
    require(re.search(r'xyd\.mid\.GET_INFO\s*=\s*2362',mids) and re.search(r'xyd\.mid\.OCCULT_SWEEP\s*=\s*2385',mids),'Occult MID ids drift')
    require(re.search(r'chapter_id\s*=\s*arg_14_0\.centreChapterPos',win),'MID2385 chapter_id request shape drift')
    require('getChapterTopScore(arg_12_0.centreChapterPos) > 0' in win,'sweep unlock top-score gate drift')
    require('arg_24_1.awards' in win and 'occult_sweep_window' in win,'MID2385 awards consumer drift')
    require('creatsSweepRewardRate * 100' in win,'raw 0.6 sweep-rate UI consumer drift')
    require(re.search(r'"creats_ticket_get",\s*"3000"',misc,re.S),'3000 ticket threshold drift')
    require(re.search(r'"creats_ticket_max",\s*"2"',misc,re.S),'ticket cap2 drift')
    require(re.search(r'"creats_sweep_reward_rate",\s*"0\.6"',misc,re.S),'raw sweep rate drift')
    require('function var_0_0.awakenNum' in table,'raw awakenNum accessor missing')
    # Effective app corpus defines awakenNum but has no call-site consumer; preserve raw 30 as source-only.
    app_lua=list((SRC/'app').rglob('*.lua')); uses=[]
    for p in app_lua:
        t=p.read_text(encoding='utf-8-sig',errors='replace')
        if ':awakenNum(' in t: uses.append(str(p.relative_to(SRC)))
    require(uses==[],'unexpected awakenNum consumer appeared: '+repr(uses))
    require(occult.count(':awakenMissionId(')>=1 and occult.count(':awakenItem(')>=1,'active Awakening award lookup drift')
    require('var_90_4.is_going == 1' in occult,'Occult Awakening task-active condition drift')
    require('arg_62_0.selfPlayer.occultTicket = arg_62_1.occult_ticket' in occult,'top-level occult_ticket response consumer drift')
    require('arg_60_0.occultTicket = tonumber(arg_60_1.params.occult_ticket)' in selfp,'economy occult_ticket projection consumer drift')
    catalog=json.loads((DATA/'occult_source_catalog.json').read_text())
    require(catalog['counts']=={'chapters':6,'ordinary_awakening_routes':22},'generated Occult catalog count drift')
    require(catalog['constants']['ticket_energy_threshold']==3000 and catalog['constants']['ticket_cap']==2 and catalog['constants']['sweep_reward_rate_raw']==0.6,'generated constants drift')
    routes=catalog['awakening_routes']; require(len(routes)==22,'generated route count drift')
    require({int(v['chapter_id']) for v in routes.values()}=={2,3,4},'Occult Awakening chapters drift')
    require(all(int(v['awaken_num_raw'])==30 for v in routes.values()),'raw 30 route drift')
    awakening=json.loads((DATA/'awakening_source_catalog.json').read_text())
    aroutes={k:v['occult'] for k,v in awakening['ordinary_stage1_routes'].items() if v.get('route_class')=='OCCULT'}
    require(set(routes)==set(aroutes),'Occult/Awakening mission cross-ref drift')
    for mid,row in routes.items():
        a=aroutes[mid]
        require(all(int(row[k])==int(a[k]) for k in ('chapter_id','chapter_table_id','fragment_item','awaken_num_raw')),f'Occult/Awakening row drift {mid}')
    report={'pass':'211.0','stage':'P2_STAGE_F_OCCULT_DEPENDENCY','effective_src64':str(SRC),'effective_src64_file_count':len(files),'source_hashes':hashes,'counts':catalog['counts'],'constants':catalog['constants'],'awaken_num_callers':uses,'evidence':{
      'ticket_threshold_cap':'SOURCE_FACT','raw_sweep_rate':'SOURCE_FACT_UI_TEXT_ONLY','raw_awaken_nums':'SOURCE_FACT_NO_EFFECTIVE_CALLER','deterministic_one_ticket_one_fragment':'COMPATIBILITY_POLICY','synthetic_max_points_active_chapter':'COMPATIBILITY_POLICY'}}
    (ROOT/'docs/json/PASS211_SRC64_REALITY_CHECK.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print('PASS Pass211 src_64 reality:',json.dumps({'files':len(files),'routes':len(routes),'chapters':sorted({int(v['chapter_id']) for v in routes.values()}),'awaken_num_callers':uses},sort_keys=True))
if __name__=='__main__':main()
