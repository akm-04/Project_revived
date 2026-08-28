#!/usr/bin/env python3
"""Pass209 effective-src64 reality verifier for P2 Stage D."""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

EXPECTED = {
    'app/common/network/mid.lua': '026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
    'app/windows/SelectTeamNewWindow.lua': '0fabc7b70c2acf48765c41b414e3cae7504f567cb6fbe344b0f98456ed18667a',
    'app/scenes/BattleCreate.lua': 'bb9ae19c20ec165eeb7ba5b81a4ce85b6b7fea3a3a7eb278123bb8c0af0bbef9',
    'app/windows/NewMapDetailWindow.lua': '88b97be8577828f478360c25fd51674e2ed8291b2a590976b3530c91396d07bf',
    'app/windows/MapDetailWindow.lua': '5a137edc609f9d2082c5df6bf50ef05b6ef54642a7ba5bf6dca8fe0f1c4c3898',
    'app/windows/SweepWindow.lua': '8548611ec6bb778433a234f3bdecf452fcde1522c64e8ca9eac5d9a84579fce5',
    'app/common/tables/CampaignTable.lua': 'e27c0e43d0b630102653699d7ed8b1735071090be027c99cc415a4308dc45ce4',
    'app/windows/TaskAwakeCell.lua': 'ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6',
    'data/tables/campaign.lua': '7a58e878a7171839342a856cd74b512037528438259d036009a7249472504683',
    'data/tables/campaign1.lua': '2d4874f87083756a33b4c1998597573a89c5a569eeeddff132f31bf7839e372b',
    'data/tables/campaign_dropbox.lua': '374b6b13bae56e2f5ac8d6b884821d2fb448d239871d1992b84bcf365e90404e',
    'data/tables/awaken_mission.lua': 'fdbcaf96386a7aa775c23b071bfe9952ef6acfc57982d17300b8308417fdb123',
    'data/tables/bloodline_mission.lua': 'b773cd8ebb0936c76c7ad0727a5d9efa67e87b748f508c3cd66147f075b81299',
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def req(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)

def between(text: str, start: str, end: str) -> str:
    a = text.index(start)
    b = text.index(end, a)
    return text[a:b]

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--src-root', type=Path, required=True)
    ap.add_argument('--data-root', type=Path, default=Path(__file__).resolve().parents[1] / 'data')
    args = ap.parse_args()
    root = args.src_root
    req(sum(1 for p in root.rglob('*') if p.is_file()) == 4370, 'effective src64 census drift')
    for rel, expected in EXPECTED.items():
        req(sha(root / rel) == expected, f'hash drift {rel}')

    mid = (root / 'app/common/network/mid.lua').read_text(errors='replace')
    req('xyd.mid.FIGHT = 113' in mid and 'xyd.mid.FIGHT_RESULT = 114' in mid and 'xyd.mid.SWEEP_CAMPAIGN = 117' in mid,
        'MID113/114/117 identity drift')

    select = (root / 'app/windows/SelectTeamNewWindow.lua').read_text(errors='replace')
    start_block = between(select, 'local var_159_22 = {', 'xyd.Backend.get():request(xyd.mid.FIGHT, var_159_22')
    req('campaign_id = var_159_2.campaignID' in start_block and 'campaign_type = var_159_2.campaignType' in start_block and 'formation = var_159_21' in start_block,
        'MID113 source-known battle tuple drift')
    req('awake_mission' not in start_block and 'twice_awake' not in start_block,
        'MID113 unexpectedly gained Awakening mission wire identity')
    req('rent_pet_id' in start_block and 'handleRentParams(var_159_22)' in start_block,
        'MID113 frozen formation/rent facts drift')

    new_map = (root / 'app/windows/NewMapDetailWindow.lua').read_text(errors='replace')
    new_awake = between(new_map, 'function var_0_0.awakeMissionInit', 'function var_0_0.checkShowBattleStory')
    req('task:isHasAwakeOpen(xyd.AwakeType.HERO)' in new_awake and 'xyd.getMissionGoIDs(var_51_0) == arg_51_0.campaignID' in new_awake,
        'NewMapDetail active ordinary campaign marker routing drift')
    old_map = (root / 'app/windows/MapDetailWindow.lua').read_text(errors='replace')
    old_awake = between(old_map, 'function var_0_0.awakeMissionInit', 'function var_0_0.checkShowBattleStory')
    req('xyd.tables.mission:stage(var_49_0) == 2' in old_awake,
        'legacy MapDetail stage-two-only marker characterization drift')

    sweep = (root / 'app/windows/SweepWindow.lua').read_text(errors='replace')
    sweep_block = between(sweep, 'local var_26_0 = xyd.mid.SWEEP_CAMPAIGN', 'xyd.Backend.get():request(var_26_0, var_26_1')
    req('if arg_26_0.awakeMissionID then' in sweep_block and 'var_26_1.awake_mission = arg_26_0.awakeMissionID' in sweep_block,
        'MID117 optional ordinary awake_mission wire field drift')
    req('twice_awake' not in sweep_block and 'blood' not in sweep_block.lower(),
        'MID117 unexpectedly gained Blood mission wire field')

    campaign_table = (root / 'app/common/tables/CampaignTable.lua').read_text(errors='replace')
    req('parse("campaign.lua"' in campaign_table and 'bloodline_mission_id' in campaign_table and 'bloodline_dropbox' in campaign_table,
        'runtime CampaignTable no longer parses Blood vectors from campaign.lua')
    twice_item = between(new_map, 'function var_0_0.getAwakeTwiceMissionItem', 'function var_0_0.initSweepPanel')
    req('task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE)' in twice_item
        and ':awakeTwiceMissionIds(arg_49_0.campaignID)' in twice_item
        and ':awakeTwiceDropboxIds(arg_49_0.campaignID)' in twice_item
        and 'if var_49_0 == iter_49_1 then' in twice_item,
        'Blood Campaign item consumer no longer resolves active mission by index in campaign vectors')
    task_awake = (root / 'app/windows/TaskAwakeCell.lua').read_text(errors='replace')
    req('local var_25_0 = xyd.getMissionGoIDs(arg_25_1)' in task_awake
        and 'campaignID = var_25_0' in task_awake,
        'Blood mission go_id navigation characterization drift')

    battle = (root / 'app/scenes/BattleCreate.lua').read_text(errors='replace')
    objective = between(battle, 'function var_0_0.getAwakeMissionResult', 'function var_0_0.campaignResult')
    for token in ('AwakeStage3MissionType.SELF_KILL', 'AwakeStage3MissionType.DAMAGE_ACHIEVE', 'AwakeStage3MissionType.ALONE_KILL', 'AwakeStage3MissionType.ALL_ALIVE'):
        req(token in objective, f'ordinary final objective source evaluator drift: {token}')
    req('awakeFighter.isDoneSelfKill' in objective and 'awakeFighter.harms' in objective and 'getHp() <= 0' in objective,
        'kill/damage/alive remain client-local telemetry facts')
    result = between(battle, 'function var_0_0.campaignResult', 'function var_0_0.treasureResult')
    req('if arg_98_0:getAwakeMissionResult() then' in result and 'var_98_2.awake_mission = arg_98_0.awakeMissionID' in result,
        'MID114 client objective attestation marker drift')
    req('formation = arg_98_0.formation' in result and 'pet_id = var_98_1' in result,
        'MID114 server-visible formation/pet result tuple drift')

    campaign = (root / 'data/tables/campaign.lua').read_text(errors='replace')
    campaign1 = (root / 'data/tables/campaign1.lua').read_text(errors='replace')
    for text, name in ((campaign, 'campaign.lua'), (campaign1, 'campaign1.lua')):
        for field in ('awaken_mission_id', 'awaken_dropbox', 'bloodline_mission_id', 'bloodline_dropbox'):
            req(f'"{field}"' in text, f'{name} missing {field}')
        req('"931002"' not in text, f'{name} unexpectedly references Blood dropbox 931002')
    dropbox = (root / 'data/tables/campaign_dropbox.lua').read_text(errors='replace')
    req('"931001"' in dropbox and '"931002"' in dropbox and '"2650"' in dropbox and '"4990"' in dropbox,
        'Blood source dropbox rows/rates drift')

    generated = json.load(open(args.data_root / 'awakening_source_catalog.json'))
    ordinary_routes = generated['ordinary_stage1_routes']
    blood_routes = generated['blood_stage1_routes']
    req(sum(1 for r in ordinary_routes.values() if r.get('route_class') == 'CAMPAIGN') == 131,
        'ordinary Campaign root census drift')
    req(sum(1 for r in blood_routes.values() if r.get('route_class') == 'CAMPAIGN') == 74,
        'Blood Campaign root census drift')
    ordinary_dropboxes = {
        int(c['dropbox_id']) for r in ordinary_routes.values() if r.get('route_class') == 'CAMPAIGN'
        for c in r.get('campaigns', [])
    }
    blood_dropboxes = {
        int(c['dropbox_id']) for r in blood_routes.values() if r.get('route_class') == 'CAMPAIGN'
        for c in r.get('campaigns', [])
    }
    req(931002 not in blood_dropboxes and blood_dropboxes == {931001},
        f'Blood executable route dropbox drift {sorted(blood_dropboxes)}')
    ordinary_mapping_count = sum(len(r.get('campaigns', [])) for r in ordinary_routes.values() if r.get('route_class') == 'CAMPAIGN')
    blood_campaign_routes = [r for r in blood_routes.values() if r.get('route_class') == 'CAMPAIGN']
    blood_mapping_count = sum(len(r.get('campaigns', [])) for r in blood_campaign_routes)
    blood_campaign_sets = {
        tuple(sorted(int(c['campaign_id']) for c in r.get('campaigns', [])))
        for r in blood_campaign_routes
    }
    req(ordinary_mapping_count == 262, f'ordinary Campaign mapping census drift {ordinary_mapping_count}')
    req(blood_mapping_count == 20054 and len(blood_campaign_sets) == 1
        and len(next(iter(blood_campaign_sets))) == 271,
        f'Blood broad Campaign vector characterization drift mappings={blood_mapping_count} sets={len(blood_campaign_sets)}')
    special = generated['special_dropboxes']
    req(all({int(row['increase_rate']) for row in special[str(did)]} == {6666} for did in ordinary_dropboxes),
        'ordinary executable special rates drift')
    req({int(row['increase_rate']) for row in special['931001']} == {2650},
        'Blood executable 931001 rate drift')
    req('931002' not in special, 'unreferenced 931002 leaked into generated executable special catalog')

    goals = {1: 0, 2: 0, 3: 0, 4: 0}
    for row in generated['ordinary'].values():
        if int(row.get('stage', 0) or 0) == 2:
            goal = int(row.get('copy_challenge', 0) or 0)
            if goal in goals:
                goals[goal] += 1
    req(goals == {1: 20, 2: 3, 3: 15, 4: 126}, f'ordinary final objective census drift {goals}')

    print(json.dumps({
        'pass': '209.0',
        'stage': 'P2-D',
        'status': 'PASS',
        'src64_file_count': 4370,
        'verified_source_files': len(EXPECTED),
        'mid113_has_no_awake_wire_id': True,
        'mid117_ordinary_marker_optional_source_confirmed': True,
        'mid117_blood_marker_absent_source_confirmed': True,
        'ordinary_final_objectives': goals,
        'ordinary_campaign_roots': 131,
        'blood_campaign_roots': 74,
        'ordinary_campaign_mappings': ordinary_mapping_count,
        'blood_campaign_mappings': blood_mapping_count,
        'blood_shared_eligible_campaign_nodes': len(next(iter(blood_campaign_sets))),
        'blood_executable_dropbox': 931001,
        'blood_executable_rate': 2650,
        'source_present_unreferenced_dropbox_931002_rate': 4990,
    }, indent=2, sort_keys=True))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
