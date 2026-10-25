"""Campaign source tables (I9_CAMPAIGN_V1) plus the labelled I9-3 private campaign policy."""

WIRE_TYPES = (('normal', 1), ('super', 2), ('challenge', 24))


def _ids(raw):
    return [int(x) for x in raw.split('|') if x not in ('', '0')]


def _pairs(ids_raw, nums_raw):
    return [[i, n] for i, n in zip(_ids(ids_raw), _ids(nums_raw)) if i > 0 and n > 0]


def build_campaign(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    if 'return 3' not in blobs['app/model/SelfPlayer.lua'].data.decode('utf-8-sig').split('getExpMulti', 1)[1][:80]:
        raise ValueError('SelfPlayer.getExpMulti drift')
    functions = {r['id']: r for r in table('function')}
    if functions['31']['level'] != '1|11':
        raise ValueError('Elite Campaign function gate drift')
    campaigns = {r['campaign_id']: r for r in table('campaign')}
    boxes = {}
    for r in table('campaign_dropbox'):
        boxes.setdefault(int(r['dropbox_id']), []).append([int(r['id']), int(r['item_id']), int(r['increase_rate'])])
    chapters, nodes, used_boxes, absent_repeat = [], [], set(), []
    for c in sorted(table('chapter'), key=lambda r: int(r['id'])):
        chapter = dict(id=int(c['id']), next_id=int(c['next_id']), event_type=int(c['event_type']), event_condition=_ids(c['event_condition']),
                       event_boss_id=int(c['event_boss_id']), event_battle_id=int(c['event_battle_id']), event_gift=_ids(c['event_gift']),
                       event_energy_need=int(c['event_energy_need']), event_open_times=int(c['event_open_times']))
        for column, wire in WIRE_TYPES:
            chapter[column] = _ids(c[column])
            for campaign_id in chapter[column]:
                r = campaigns[str(campaign_id)]
                first_box, repeat_box = int(r['init_dropbox']), int(r['dropbox'])
                if first_box and first_box not in boxes:
                    raise ValueError('campaign first-clear dropbox missing: %d' % campaign_id)
                if repeat_box and repeat_box not in boxes:
                    absent_repeat.append(campaign_id)
                    repeat_box = 0
                used_boxes.update(b for b in (first_box, repeat_box) if b)
                nodes.append(dict(id=campaign_id, type=wire, map_type=(3 if int(r['is_boss'] or 0) else int(r['campaign_type'])), chapter=chapter['id'], open_level=int(r['open_lv']), energy_cost=int(r['energy_cost']),
                                  defeat_cost=int(r['defeat_cost']), partner_exp=int(r['partner_exp']), mana_gain=int(r['mana_gain']),
                                  star_gift=int(r['star_gift']), daily_limit=int(r['daily_limit']), first_box=first_box, repeat_box=repeat_box,
                                  next=_ids(r['next_campaign_id']), previous=int(r['last_campaign_id']), related=int(r['relate_campaign_id']),
                                  story_partners=_ids(r['story_drop_partner']), sweep_reward=_pairs(r['sweep_reward'], r['sweep_reward_num'])))
        chapters.append(chapter)
    counts = {wire: sum(1 for n in nodes if n['type'] == wire) for _, wire in WIRE_TYPES}
    if len(chapters) != 23 or counts != {1: 429, 2: 155, 24: 144} or len({n['id'] for n in nodes}) != len(nodes):
        raise ValueError('campaign chapter/node profile drift')
    if nodes[0]['id'] != 100001 or len(absent_repeat) != 24 or not any(n['id'] == 1600016 and n['type'] == 1 for n in nodes):
        raise ValueError('campaign first node or repeat dropbox profile drift')
    drop_boxes = [dict(id=b, rows=[[item, rate] for _, item, rate in sorted(boxes[b])]) for b in sorted(used_boxes)]
    if len(drop_boxes) != 996 or sum(len(b['rows']) for b in drop_boxes) != 8135:
        raise ValueError('campaign dropbox profile drift')
    star_bonus = [dict(id=int(r['bonus_id']), next_id=int(r['next_bonus_id']), type=int(r['bonus_type']), star_num=int(r['star_num']),
                       crystal=int(r['award_crystal']), mana=int(r['award_mana']), items=_pairs(r['award_id'], r['award_num']))
                  for r in sorted(table('campaign_star_bonus'), key=lambda r: int(r['bonus_id']))]
    if len(star_bonus) != 46:
        raise ValueError('campaign star bonus profile drift')
    # D118: only displayed large/boss nodes carry stars; every chapter threshold matches.
    for kind in (1, 2):
        cumulative = 0
        bonuses = [b for b in star_bonus if b['type'] == kind]
        for ch, bonus in zip(chapters, bonuses):
            cumulative += 3 * sum(n['chapter'] == ch['id'] and n['type'] == kind and n['map_type'] != 1 for n in nodes)
            if cumulative != bonus['star_num']:
                raise ValueError('Campaign displayed-star threshold drift')
    elite_reset_costs = [int(r['refresh_elite_cost']) for r in sorted(table('refresh_cost'), key=lambda r: int(r['id']))]
    vip = [dict(level=int(r['id']), num_elite=int(r['num_elite']), quick_sweep=int(r['quick_sweep']))
           for r in sorted(table('vip'), key=lambda r: int(r['id']))]
    monthly = {r['id']: r for r in table('monthly_privilege')}['1']
    if len(elite_reset_costs) != 330 or elite_reset_costs[0] != 20 or [v['level'] for v in vip] != list(range(16)) or monthly['num_elite'] != '3':
        raise ValueError('campaign reset/VIP profile drift')
    gifts = {int(r['id']): r for r in table('gift')}
    chapter_gifts = []
    for gid in sorted({g for ch in chapters if ch['event_type'] == 1 for g in ch['event_gift']}):
        g = gifts[gid]
        if any(v not in ('', '0') for k, v in g.items() if k not in ('id', 'desc', 'items', 'item_nums')):
            raise ValueError('Unsupported Campaign gift columns: %d' % gid)
        chapter_gifts.append(dict(id=gid, items=_pairs(g['items'], g['item_nums'])))
    if len(chapter_gifts) != 12:
        raise ValueError('Campaign chapter gift profile drift')
    return dict(schema_version=1, contract_id='I9_CAMPAIGN_V1', policy_id='I9_CAMPAIGN_PRIVATE_POLICY_V1',
                first_normal_id=100001, super_function_id=31, challenge_gate_campaign_id=1600016, exp_multiplier=3,
                sweep_card_item_id=50001013, normal_sweep_max=10,
                private_policy=dict(result_window_seconds=3600, sweep_crystal_per_card=1,
                                    labels=['result_window_seconds PRIVATE_POLICY D103', 'sweep_crystal_per_card PRIVATE_POLICY C7',
                                            'absent repeat dropboxes UNKNOWN: no repeat drop']),
                absent_repeat_box_campaigns=absent_repeat, monthly=dict(num_elite=int(monthly['num_elite']), quick_sweep=int(monthly['quick_sweep'])),
                chapter_gifts=chapter_gifts, chapters=chapters, nodes=nodes, drop_boxes=drop_boxes, star_bonus=star_bonus, elite_reset_costs=elite_reset_costs, vip=vip)
