"""Pure Dorm compiler: source facts plus two explicitly approved policies."""
from decimal import Decimal

def build_glue(misc, vip_rows, refresh_rows, error):
    try:
        daily_floor=int(misc['glue_time_get']);purchase_amount=int(misc['glue_buy_number']);purchase_start_limit=int(misc['glue_buy_limit'])
    except KeyError as missing:raise error(f'Dorm glue source key {missing.args[0]} missing')
    def field(row,name):
        try:return int(row[name])
        except KeyError:raise error(f'Dorm glue source column {name} missing')
    vip_daily_caps=sorted((dict(vip=field(r,'id'),cap=field(r,'num_glue'))for r in vip_rows),key=lambda x:x['vip'])
    purchase_costs=sorted((dict(ordinal=field(r,'id'),cost=field(r,'buy_glue_cost'))for r in refresh_rows),key=lambda x:x['ordinal'])
    if len({x['vip']for x in vip_daily_caps})!=len(vip_daily_caps):raise error('Dorm glue VIP cap duplicate')
    if len({x['ordinal']for x in purchase_costs})!=len(purchase_costs):raise error('Dorm glue purchase cost duplicate')
    return dict(daily_floor=daily_floor,purchase_amount=purchase_amount,purchase_start_limit=purchase_start_limit,vip_daily_caps=vip_daily_caps,purchase_costs=purchase_costs)

def build_dorm(blobs, parse_table, pipe_ints, hero_templates, partner_keys, partner_rows, super_keys, super_rows, indexed_field, items, error):
    def rows(name): return parse_table(blobs['data/tables/'+name+'.lua'].data)
    def bp(raw):
        n=Decimal(raw)*100
        if n!=n.to_integral_value():raise error('Dorm growth precision exceeds basispoints')
        return int(n)
    misc={r['key']:r['value'] for r in rows('misc')}
    glue=build_glue(misc,rows('vip'),rows('refresh_cost'),error)
    exchange=[dict(item_id=i,cement_per_key=int(misc['house_key_'+color])) for color in ('green','blue') for i in pipe_ints(misc['house_key_'+color+'_id'])]
    rooms=[]
    for r in rows('dorm_house'):
        comforts=pipe_ints(r['comfort']);attrs=[[bp(x)for x in a.split(',')]for a in r['attr'].split('|')]
        if len(attrs)<len(comforts)or any(len(x)!=3 for x in attrs):raise error('Dorm room growth shape')
        rooms.append(dict(table_id=int(r['id']),main_type=int(r['maintype']),attribute_type=int(r['type']),length=int(r['area_length']),width=int(r['area_width']),height=int(r['area_height']),dresser=int(r['dresser']),growth=[dict(comfort=x,attributes_bp=attrs[i])for i,x in enumerate(comforts)]))
    types=[dict(main_type=int(r['id']),residents=int(r['hero_num']),max_expansion=int(r['expand']))for r in rows('dorm_house_type')]
    keys=[dict(item_id=int(r['key']),main_type=int(r['type']),templates=pipe_ints(r['house']))for r in rows('dorm_house_key')]
    expansions=[dict(level=int(r['id']),area=int(r['area']),comfort=int(r['comfort']),duration_seconds=int(r['cost_times']),cost_items=pipe_ints(r['cost_items']),cost_counts=pipe_ints(r['cost_nums']),attributes_bp=[[bp(x)for x in a.split(',')]for a in r['attr'].split('|')])for r in rows('dorm_expand')]
    furniture=[]
    for r in rows('dorm_furniture_item'):
        furniture.append(dict(item_id=int(r['item_id']),comfort=int(r['comfort']),floor=int(r['floor']),paper_item=int(r['paper']),can_rotate=bool(int(r['can_rotate'])),can_pile=bool(int(r['can_pile'])),can_be_pile=bool(int(r['can_be_pile'])),special_type=int(r['special_type']),panels=pipe_ints(r['place_wall']),length=int(r['cover_length']),width=int(r['cover_width']),height=int(r['cover_height']),pile_limit=bool(int(r['is_pile_limit'])),pile_start=pipe_ints(r['pile_limit_coordinate_start']),pile_end=pipe_ints(r['pile_limit_coordinate_end'])))
    templates=[];equipment_ids=set()
    for core in hero_templates:
        first=core['first_table_id'] or core['table_id'];ks,rs=(super_keys,super_rows)if core['hero_kind']=='SUPER'else(partner_keys,partner_rows)
        ids=pipe_ints(indexed_field(ks,rs[first],'dorm_item',row_id=first)or '0')
        if len(ids)!=5 or any(x<=0 for x in ids):raise error('Dorm selectedHero requires5sourceequipmentitems')
        equipment_ids.update(ids);templates.append(dict(template_id=core['table_id'],items=ids))
    by_item={int(r['id']):r for r in items}
    equipment=[dict(item_id=i,required_level=int(by_item[i]['level']))for i in sorted(equipment_ids)]
    furniture_recipes,blueprint_recipes=build_furniture_recipes(furniture,by_item,pipe_ints,error)
    if (len(rooms),len(types),len(keys),len(expansions),len(furniture),len(templates))!=(16,4,18,3,267,568):raise error('Dorm selected source count drift')
    if (len(furniture_recipes),len(blueprint_recipes))!=(53,53):raise error('Dorm furniture recipe count drift')
    return dict(schema_version=3,lounge_policy_id='C2C_LOUNGE_EXP_V1',random_key_policy_id='C2C_RANDOM_KEY_V1',original_server_policy_recovered=False,glue=glue,exchange_keys=exchange,rooms=sorted(rooms,key=lambda x:x['table_id']),types=types,keys=keys,expansions=expansions,furniture=sorted(furniture,key=lambda x:x['item_id']),hero_equipment=templates,equipment_items=equipment,furniture_recipes=dict(furniture=furniture_recipes,blueprints=blueprint_recipes))


def build_furniture_recipes(furniture,by_item,pipe_ints,error):
    def positive(values,label):
        if not values or any(x<=0 for x in values):raise error(f'Dorm furniture recipe {label} missing')
        return values
    def item_field(item_id,name):
        row=by_item.get(item_id)
        if row is None:raise error(f'Dorm furniture item {item_id} is absent from item.lua')
        return row.get(name) or '0'
    recipes=[];blueprints=[]
    for f in sorted(furniture,key=lambda x:x['item_id']):
        item_id,paper=f['item_id'],f['paper_item']
        if paper==0:continue
        if int(item_field(item_id,'formula'))!=paper:raise error(f'Dorm furniture {item_id} formula contradicts paper {paper}')
        materials=positive(pipe_ints(item_field(item_id,'compose')),f'materials {item_id}')
        counts=positive(pipe_ints(item_field(item_id,'compose_num')),f'counts {item_id}')
        if len(materials)!=len(counts):raise error(f'Dorm furniture {item_id} material shape drift')
        glue=int(item_field(item_id,'glue'))
        if glue<0:raise error(f'Dorm furniture {item_id} negative glue')
        pieces=positive(pipe_ints(item_field(paper,'compose')),f'pieces {paper}')
        piece_counts=positive(pipe_ints(item_field(paper,'compose_num')),f'piece counts {paper}')
        if len(pieces)!=len(piece_counts):raise error(f'Dorm blueprint {paper} piece shape drift')
        level=int(item_field(paper,'level'))
        if level<=0:raise error(f'Dorm blueprint {paper} missing level')
        recipes.append(dict(item_id=item_id,materials=materials,counts=counts,glue=glue,blueprint_item=paper))
        blueprints.append(dict(item_id=paper,pieces=pieces,counts=piece_counts,level=level))
    if len({r['item_id'] for r in blueprints})!=len(blueprints) or len({r['blueprint_item'] for r in recipes})!=len(recipes):
        raise error('Dorm furniture blueprint is not one-to-one')
    return recipes,sorted(blueprints,key=lambda x:x['item_id'])
