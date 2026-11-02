"""Current Gods Trial tables; probabilities use the separately labelled D81 policy."""
def build_godstrial(blobs, parse, items):
    table=lambda name:parse(blobs['data/tables/'+name+'.lua'].data)
    campaigns=table('spirit_campaign'); ids={int(r[k]) for r in campaigns for k in ('init_dropbox','dropbox')}
    boxes={i:[] for i in ids}
    for r in table('campaign_dropbox'):
        b=int(r['dropbox_id'])
        if b in boxes:boxes[b].append([int(r['item_id']),int(r['increase_rate'])])
    item_types={int(r['id']):int(r['type']) for r in items}
    used={i for rows in boxes.values() for i,rate in rows}
    if any(item_types[i] not in (4,24) for i in used):raise ValueError('Trial award owner drift')
    misc={r['key']:r['value'] for r in table('misc')}
    out=dict(schema_version=1,contract_id='I9_GODS_TRIAL_V1',stages=[dict(id=int(r['id']),day=int(r['day']),previous=int(r['last_campaign']),level=int(r['level']),battle=int(r['battle']),win_cost=int(r['win_cost_num']),lose_cost=int(r['lose_cost_num']),first_box=int(r['init_dropbox']),repeat_box=int(r['dropbox']),open=r['is_open']=='1') for r in campaigns],boxes=[dict(id=i,rows=rows) for i,rows in sorted(boxes.items())],spirit_items={str(i):True for i in sorted(used) if item_types[i]==24},auto_minutes=int(misc['spirit_auto_time']),auto_limit=int(misc['spirit_auto_limit']),soft_limit=int(misc['spirit_num_limit']))
    if len(campaigns)!=42 or len(boxes)!=84 or sum(map(len,boxes.values()))!=3672 or len(out['spirit_items'])!=360:raise ValueError('Trial source census drift')
    return out
