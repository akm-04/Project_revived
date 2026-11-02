"""Adventure event source tables; D368 values live in I9_ADVENTURE_POLICY_V1."""
from collections import Counter
from decimal import Decimal

EVENT_IDS = [10001, 10002, 10003, 10004, 10005, 10006]
EVENT_RATES = {10001: 3, 10002: 1, 10003: 6, 10004: 7, 10005: 4, 10006: 10}
EVENT_TIME_LIMITS = {10001: 10800, 10002: 3600, 10003: 3600, 10004: 7200, 10005: 3600, 10006: 10800}
EVENT_WINDOWS = {
    10001: 'adventure_defense',
    10002: 'adventure_favor',
    10003: 'adventure_shop',
    10004: 'adventure_battle',
    10005: 'adventure_summon',
    10006: 'adventure_illusion',
}
SHOP_IDS = list(range(1001, 1008))
SHOP_PRICES = [20, 20, 20, 50, 50, 50, 300]
CARD_IDS = list(range(100001, 100073))
CARD_PRICE_COUNTS = {88: 16, 388: 56}
CAMPAIGN_IDS = list(range(100001, 100020))
GIFT_IDS = list(range(90030001, 90030020)) + [90030021, 90030022]
FIRST_CAMPAIGN_LEVEL = 9
LAST_CAMPAIGN_LEVEL = 100
EXPECTED_MISC = {
    'adventure_monster_challenge_times_limit': '3',
    'adventure_level_limit': '5',
    'adventure_challenge_choose_time_limit': '60',
    'adventure_room_people_limit': '6',
    'adventure_monster_nums': '3',
    'adventure_challenge_battle_time_limit': '90',
    'adventure_fight_ranking_section': '3',
    'adventure_extra_add_amour': '100',
    'adventure_paradise_challenge_times': '1',
    'adventure_paradise_total_damage': '5000000',
    'adventure_paradise_boss': '100011',
    'adventure_paradise_gift_single': '90030022',
    'adventure_paradise_gift': '90030022',
    'adventure_fight_gift': '90030021',
    'adventure_gift_random': '50005013|50005016|50001113|50005012|50005015|50005018|50005011|50005014|50005017',
    'library_favor_limit': '2000',
    'adventure_alice_total_challenge_times_limit': '4',
    'adventure_monster_total_challenge_times_limit': '5',
    'adventure_monster_damage_param': '3',
    'adventure_paradise_coins_reward': '2',
    'adventure_paradise_mana_reward': '0.2',
    'adventure_saodangquan_item_id': '50001013',
}


def _pipe_ints(raw):
    if not raw or raw == '0':
        return []
    return [int(value) for value in raw.split('|')]


def build_adventure(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)

    events = []
    for row in table('adventure_event'):
        events.append(dict(
            id=int(row['id']),
            title=row['title'],
            description=row['desc'],
            rate=int(row['rate']),
            time_limit_seconds=int(row['time_limit']),
            window_name=row['window_name'],
            title_picture=row['title_pic'],
            title_background=row['title_bg'],
            content_background=row['content_bg'],
        ))
    events.sort(key=lambda event: event['id'])
    if [event['id'] for event in events] != EVENT_IDS:
        raise ValueError('adventure event census drift')
    for event in events:
        if event['rate'] != EVENT_RATES[event['id']] or event['time_limit_seconds'] != EVENT_TIME_LIMITS[event['id']]:
            raise ValueError('adventure event trigger profile drift')
        if event['window_name'] != EVENT_WINDOWS[event['id']] or not event['title']:
            raise ValueError('adventure event window drift')

    shop = []
    for row in table('adventure_shop'):
        shop.append(dict(id=int(row['id']), item=int(row['item']), price=int(row['price']), rate=int(row['rate'])))
    shop.sort(key=lambda row: row['id'])
    if [row['id'] for row in shop] != SHOP_IDS or [row['price'] for row in shop] != SHOP_PRICES:
        raise ValueError('adventure shop census/price drift')
    if any(row['item'] <= 0 or row['rate'] <= 0 for row in shop):
        raise ValueError('adventure shop shape drift')

    cards = []
    for row in table('adventure_cards_dropbox'):
        cards.append(dict(id=int(row['id']), item=int(row['item']), price=int(row['price']), rate=int(row['rate'])))
    cards.sort(key=lambda row: row['id'])
    if [row['id'] for row in cards] != CARD_IDS:
        raise ValueError('adventure card census drift')
    if dict(Counter(row['price'] for row in cards)) != CARD_PRICE_COUNTS:
        raise ValueError('adventure card price drift')
    if any(row['item'] <= 0 or row['rate'] < 0 for row in cards):
        raise ValueError('adventure card shape drift')

    campaigns = []
    for row in table('adventure_campaign'):
        levels = _pipe_ints(row['level_condition'])
        battles = _pipe_ints(row['battle_ids'])
        models = _pipe_ints(row['models'])
        if len(levels) != 2 or len(battles) != 3 or len(models) != 3:
            raise ValueError('adventure campaign shape drift')
        campaigns.append(dict(
            id=int(row['id']),
            minimum_level=levels[0],
            maximum_level=levels[1],
            battle_ids=battles,
            gift=int(row['gift']),
            models=models,
        ))
    campaigns.sort(key=lambda row: row['id'])
    if [row['id'] for row in campaigns] != CAMPAIGN_IDS:
        raise ValueError('adventure campaign census drift')
    if campaigns[0]['minimum_level'] != FIRST_CAMPAIGN_LEVEL or campaigns[-1]['maximum_level'] != LAST_CAMPAIGN_LEVEL:
        raise ValueError('adventure campaign level span drift')
    for previous, current in zip(campaigns, campaigns[1:]):
        if current['minimum_level'] != previous['maximum_level']:
            raise ValueError('adventure campaign level band drift')
    for campaign in campaigns:
        offset = campaign['id'] - CAMPAIGN_IDS[0]
        if campaign['gift'] != 90030001 + offset or min(campaign['battle_ids'] + campaign['models']) <= 0:
            raise ValueError('adventure campaign gift/identity drift')

    gifts = []
    for row in table('gift'):
        gift_id = int(row['id'])
        if gift_id not in GIFT_IDS:
            continue
        items = _pipe_ints(row['items'])
        item_nums = _pipe_ints(row['item_nums'])
        if not items or len(items) != len(item_nums) or min(items) <= 0 or min(item_nums) <= 0:
            raise ValueError('adventure gift shape drift ' + row['id'])
        gifts.append(dict(id=gift_id, items=items, item_nums=item_nums))
    gifts.sort(key=lambda gift: gift['id'])
    if [gift['id'] for gift in gifts] != GIFT_IDS:
        raise ValueError('adventure gift census drift')

    misc = {row['key']: row['value'] for row in table('misc')}
    for key, value in EXPECTED_MISC.items():
        if misc.get(key) != value:
            raise ValueError('adventure misc profile drift ' + key)

    return dict(
        schema_version=1,
        contract_id='I9_ADVENTURE_V1',
        policy_id='I9_ADVENTURE_POLICY_V1',
        policy_version=1,
        open_academy_level=11,
        fantasy_open_level=65,
        events=events,
        shop=shop,
        cards=cards,
        campaigns=campaigns,
        gifts=gifts,
        limits=dict(
            defense_tries_per_position=int(misc['adventure_monster_challenge_times_limit']),
            defense_level_band=int(misc['adventure_level_limit']),
            defense_selection_seconds=int(misc['adventure_challenge_choose_time_limit']),
            defense_room_capacity=int(misc['adventure_room_people_limit']),
            defense_monster_count=int(misc['adventure_monster_nums']),
            defense_battle_seconds=int(misc['adventure_challenge_battle_time_limit']),
            pvp_ranking_section=int(misc['adventure_fight_ranking_section']),
            favor_extra=int(misc['adventure_extra_add_amour']),
            favor_limit=int(misc['library_favor_limit']),
            illusion_challenge_times=int(misc['adventure_paradise_challenge_times']),
            illusion_hidden_boss=int(misc['adventure_paradise_boss']),
            illusion_gift_single=int(misc['adventure_paradise_gift_single']),
            illusion_gift_coop=int(misc['adventure_paradise_gift']),
            illusion_total_damage=int(misc['adventure_paradise_total_damage']),
            illusion_alice_challenge_times=int(misc['adventure_alice_total_challenge_times_limit']),
            monster_total_challenge_times=int(misc['adventure_monster_total_challenge_times_limit']),
            monster_damage_parameter=int(misc['adventure_monster_damage_param']),
            illusion_coins_reward=int(misc['adventure_paradise_coins_reward']),
            illusion_mana_reward=str(Decimal(misc['adventure_paradise_mana_reward'])),
            pvp_gift=int(misc['adventure_fight_gift']),
            favor_gift_random=_pipe_ints(misc['adventure_gift_random']),
            sweep_card_item=int(misc['adventure_saodangquan_item_id']),
        ),
    )
