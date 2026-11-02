"""Sky Tower's source-shaped floor, reward and cost catalog."""
def build_petcampaign(blobs,parse,resources):
    nums=lambda v:[int(n) for n in v.split('|') if n and int(n)>0]
    floors=[]
    enabled={r['item_id'] for r in resources if r.get('item_id') and r.get('settlement_activation') in ('ENABLED_R4','ENABLED_R5')}
    for r in parse(blobs['data/tables/pet_campaign.lua'].data):
        def awards(ids,counts):
            ii,nn=nums(r[ids]),nums(r[counts])
            if len(ii)!=len(nn): raise ValueError('Tower reward arity drift')
            if not set(ii).issubset(enabled): raise ValueError('Tower reward resource unavailable')
            return [dict(id=i,count=n) for i,n in zip(ii,nn)]
        mm,ii,nn=map(nums,[r['awaken_mission_id'],r['awaken_dropbox'],r['awaken_material_num']])
        if not len(mm)==len(ii)==len(nn):raise ValueError('Tower material arity drift')
        floors.append(dict(id=int(r['campaign_id']),number=int(r['campaign_type']),type=int(r['floor_type']),fight=int(r['fight_id']),level=int(r['open_lv']),mana=int(r['mana_gain']),rewards=awards('item','item_num'),first=awards('first_drop','first_drop_num'),vip_rewards=awards('item','vip6_item_num'),vip_first=awards('first_drop','vip6_first_drop_num'),materials=[dict(mission=m,item=i,count=n) for m,i,n in zip(mm,ii,nn)]))
    if len(floors)!=120 or sum(f['type']==1 for f in floors)!=100:raise ValueError('Tower floor census drift')
    misc={r['key']:r['value'] for r in parse(blobs['data/tables/misc.lua'].data)}
    prices=[int(r['skycity_hard_cost']) for r in parse(blobs['data/tables/refresh_cost.lua'].data)]
    return dict(schema_version=1,contract_id='I9_PET_CAMPAIGN_V1',floors=floors,layer_seconds=int(misc['skycity_layer_time']),layer_cost=int(misc['skycity_layer_cost']),ticket=int(misc['skycity_super_paper']),unlock_tickets=int(misc['skycity_super_first_reward']),raids=int(misc['skycity_super_times_buy']),practice_mana=int(misc['skycity_super_practice_cost_mana']),buy_prices=prices,awake_prices=nums(misc['pet_awaken_sweep_cost']))
