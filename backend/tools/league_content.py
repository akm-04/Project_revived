"""Source League catalog. Private calendar/score choices are explicitly versioned."""
from datetime import date
from arena_content import _translations

def build_league(blobs,parse):
    table=lambda n:parse(blobs['data/tables/'+n+'.lua'].data)
    misc={r['key']:r['value'] for r in table('misc')}
    ints=lambda s:[int(x) for x in s.split('|')]
    funcs={r['id']:r for r in table('function')}
    if funcs['91']['level']!='1|70':raise ValueError('League admission drift')
    gifts={r['id']:r for r in table('gift')}
    daily=[];final=[];used={misc['cross_arena_special_first_win']}
    for group in range(1,4):
        for r in sorted(table('cross_arena_daily_reward'+str(group)),key=lambda r:int(r['range'])):
            used.add(r['gift']);daily.append(dict(group=group,rank=int(r['range']),gift_id=int(r['gift'])))
        for r in sorted(table('cross_arena_final_reward'+str(group)),key=lambda r:int(r['range'])):
            final.append(dict(group=group,rank=int(r['range']),items=[[i,n] for i,n in zip(ints(r['item_id']),ints(r['item_num']),strict=True) if i>0 and n>0],crystal=int(r['crystal']),bubble_id=int(r['bubble_id'] or '0')))
    payload=[]
    ignored=('drops','energy','vip_exp','arena_coin','march_coin','lucky_coin','friendship_coin','skin_fragment','equip','exp','badge','soul','vip','ex_badge','tutor_coin','skin_coin','spirit_energy')
    for gid in sorted(used,key=int):
        r=gifts[gid]
        if any(r.get(k,'') not in ('','0')for k in ignored):raise ValueError('Unsupported League gift '+gid)
        payload.append(dict(id=int(gid),items=[[i,n]for i,n in zip(ints(r['items']),ints(r['item_nums']),strict=True)if i>0 and n>0],crystal=int(r['crystal']),mana=int(r['mana'])))
    schedules=sorted(table('cross_arena_schedule'),key=lambda r:int(r['id']))
    # Column names are asserted by source oracle; all raw dates retained.
    dates=[next(v for k,v in r.items() if k!='id' and len(v)==8 and v.isdigit())for r in schedules]
    titles={r['id']:r for r in table('title_system')}
    thresholds=[100104,100111,*range(100114,100122)]
    if any(titles[str(i)]['time']!='-1'for i in thresholds):raise ValueError('League title duration drift')
    bubbles={int(r['id']):int(r['time'])for r in table('chat_bubble')}
    if any(bubbles[i]!=2592000 for i in range(10002,10008)):raise ValueError('League bubble duration drift')
    return dict(schema_version=1,contract_id='C5F_CHAMPIONS_LEAGUE_MODE_V1',policy_id='C5F_LEAGUE_PRIVATE_POLICY_V2',function_id=91,levels=[int(misc['cross_arena_group'+str(i)+'_level'])for i in range(1,4)],initial_points=int(misc['cross_arena_original_points']),point_max=int(misc['cross_arena_point_param1']),point_min=int(misc['cross_arena_floor_points']),opponent_radius=int(misc['cross_arena_opponents_show']),normal_protection=int(misc['cross_arena_protect_time']),frenzy_protection=int(misc['cross_arena_protect_time_2']),frenzy_start=int(misc['cross_arena_party_time_start']),frenzy_seconds=int(misc['cross_arena_party_time']),day_start=int(misc['cross_arena_first_win_time']),season_days=30,rest_days=3,rating_scale=400,schedule=[date(int(s[:4]),int(s[4:6]),int(s[6:])).isoformat()for s in dates],first_gift=int(misc['cross_arena_special_first_win']),daily=daily,final=final,gifts=payload,title_ids=thresholds,bubble_seconds=2592000,mail=_translations(blobs['data/tables/translation.lua'].data,('CROSS_ARENA_MAIL_TITLE','CROSS_ARENA_MAIL_TXT','CROSS_ARENA_MAIL_SENDER')))
