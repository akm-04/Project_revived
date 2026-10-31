"""Occult (Sorcery War) source tables; D367 values live in I9_OCCULT_POLICY_V1."""
from decimal import Decimal, ROUND_CEILING

CHAPTER_IDS = [1, 2, 3, 4, 5, 6]
CAMPAIGNS_PER_TYPE = 59
MULTI_CAMPAIGN_TYPE = 1
SINGLE_CAMPAIGN_TYPE = 2
ROUTES_PER_CHAPTER = {1: 0, 2: 8, 3: 7, 4: 7, 5: 0, 6: 0}
AWAKEN_NUM_RAW = 30
# Source typo kept verbatim: single campaign 10025 unlocks 1002, which no row carries.
KNOWN_DANGLING_UNLOCKS = {(10025, 1002)}
OPEN_ACADEMY_LEVEL = 85
SWEEP_PERCENT = 60
EXPECTED_MISC = {
    'creats_ticket_get': '3000',
    'creats_ticket_max': '2',
    'creats_team_limit': '5',
    'creats_team_people_limit': '3',
    'creats_campaign_duration': '3000',
    'creats_event_param': '0.3',
    'creats_event_dispatch': '3',
    'creats_remove_time_limit': '120',
    'creats_dispatch_hero_limit': '30',
    'creats_survival_param': '2.5',
    'creats_dispatch_param': '4.5',
    'creats_schedule_param': '10',
    'creats_time_param': '1.5',
    'creats_timeout1': '60',
    'creats_timeout2': '150',
    'creats_sweep_reward_rate': '0.6',
}


def _pipe_ints(raw):
    if not raw or raw == '0':
        return []
    return [int(value) for value in raw.split('|')]


def _pipe_decimals(raw):
    if not raw or raw == '0':
        return []
    return [str(Decimal(value)) for value in raw.split('|')]


def build_occult(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)

    chapters = []
    routes = []
    for row in table('creats_chapter_select'):
        chapter_id = int(row['chapter_id'])
        mission_ids = _pipe_ints(row['awaken_mission_ids'])
        fragment_items = _pipe_ints(row['awaken_items'])
        fragment_nums = _pipe_ints(row['awaken_nums'])
        if not len(mission_ids) == len(fragment_items) == len(fragment_nums):
            raise ValueError('occult awakening route drift')
        if any(number != AWAKEN_NUM_RAW for number in fragment_nums):
            raise ValueError('occult awakening quantity drift')
        item_display = _pipe_ints(row['item_display'])
        item_ids = _pipe_ints(row['item'])
        item_rates = _pipe_decimals(row['item_num'])
        if len(item_ids) != len(item_rates):
            raise ValueError('occult reward rate drift')
        chapters.append(dict(
            id=chapter_id,
            table_id=int(row['table_id']),
            model_id=int(row['chapter_model']),
            name=row['chapter_name'],
            description=row['chapter_des'],
            buff_id=int(row['chapter_buff']),
            mana=int(row['mana']),
            item_ids=item_ids,
            item_rates=item_rates,
            item_display=item_display,
        ))
        for mission_id, fragment_item in zip(mission_ids, fragment_items):
            routes.append(dict(mission_id=mission_id, chapter_id=chapter_id, fragment_item=fragment_item))
    chapters.sort(key=lambda chapter: chapter['id'])
    routes.sort(key=lambda route: route['mission_id'])
    if [chapter['id'] for chapter in chapters] != CHAPTER_IDS:
        raise ValueError('occult chapter census drift')
    if any(chapter['mana'] != 0 or not chapter['item_display'] for chapter in chapters):
        raise ValueError('occult chapter shape drift')
    route_counts = {chapter_id: sum(1 for route in routes if route['chapter_id'] == chapter_id) for chapter_id in CHAPTER_IDS}
    if route_counts != ROUTES_PER_CHAPTER or len({route['mission_id'] for route in routes}) != sum(ROUTES_PER_CHAPTER.values()):
        raise ValueError('occult awakening route census drift')

    from generate_combat_corpus import parse_monster
    monster_keys, monster_rows = parse_monster(blobs['data/tables/monster.lua'].data)
    battles = {row['fight_id']: row for row in table('battle')}

    def stage_total_hp(fight_id):
        battle = battles.get(str(fight_id))
        if battle is None:
            raise ValueError('occult battle missing ' + str(fight_id))
        total = 0
        for wave in ('fight_1', 'fight_2', 'fight_3'):
            for monster_id in _pipe_ints(battle[wave]):
                row = monster_rows.get(monster_id)
                if row is None:
                    raise ValueError('occult monster missing ' + str(monster_id))
                # The client posts ceil(hp); sum the same ceil per monster.
                total += int(Decimal(row[monster_keys['total_hp'] - 1]).to_integral_value(rounding=ROUND_CEILING))
        if total <= 0:
            raise ValueError('occult stage has no monster HP ' + str(fight_id))
        return total

    campaigns = []
    for row in table('creats_campaign'):
        fight_ids = _pipe_ints(row['fight_ids'])
        campaigns.append(dict(
            id=int(row['campaign_id']),
            campaign_type=int(row['campaign_type']),
            chapter_id=int(row['chapter_id']),
            name=row['campaign_name'],
            description=row['campaign_des'],
            start_point=int(row['is_start_point']) != 0,
            unlock_ids=_pipe_ints(row['unlock_id']),
            fight_ids=fight_ids,
            stage_total_hp=[stage_total_hp(fight_id) for fight_id in fight_ids],
            event_id=int(row['event_id']),
            dialogue=row['creat_dialogue'],
            x=row['x'],
            y=row['y'],
            model_id=int(row['model']),
        ))
    campaigns.sort(key=lambda campaign: campaign['id'])
    by_type = {campaign_type: [campaign for campaign in campaigns if campaign['campaign_type'] == campaign_type] for campaign_type in (MULTI_CAMPAIGN_TYPE, SINGLE_CAMPAIGN_TYPE)}
    if len(campaigns) != 2 * CAMPAIGNS_PER_TYPE or any(len(rows) != CAMPAIGNS_PER_TYPE for rows in by_type.values()):
        raise ValueError('occult campaign census drift')
    if len({campaign['id'] for campaign in campaigns}) != len(campaigns) or any(campaign['chapter_id'] not in CHAPTER_IDS for campaign in campaigns):
        raise ValueError('occult campaign shape drift')
    campaign_ids = {campaign['id'] for campaign in campaigns}
    dangling = {(campaign['id'], next_id) for campaign in campaigns for next_id in campaign['unlock_ids'] if next_id not in campaign_ids}
    if dangling != KNOWN_DANGLING_UNLOCKS:
        raise ValueError('occult campaign adjacency drift')

    misc = {row['key']: row['value'] for row in table('misc')}
    for key, value in EXPECTED_MISC.items():
        if misc.get(key) != value:
            raise ValueError('occult misc profile drift ' + key)
    sweep_percent = Decimal(misc['creats_sweep_reward_rate']) * 100
    if sweep_percent != SWEEP_PERCENT:
        raise ValueError('occult sweep percent drift')

    return dict(
        schema_version=1,
        contract_id='I9_OCCULT_V1',
        policy_id='I9_OCCULT_POLICY_V1',
        policy_version=1,
        open_academy_level=OPEN_ACADEMY_LEVEL,
        energy_per_ticket=int(misc['creats_ticket_get']),
        ticket_cap=int(misc['creats_ticket_max']),
        room_capacity=int(misc['creats_team_people_limit']),
        level_band=int(misc['creats_team_limit']),
        room_seconds=int(misc['creats_campaign_duration']),
        selection_seconds=int(misc['creats_timeout1']),
        fight_seconds=int(misc['creats_timeout2']),
        reentry_seconds=int(misc['creats_remove_time_limit']),
        dispatch_hero_limit=int(misc['creats_dispatch_hero_limit']),
        event_percent=int(Decimal(misc['creats_event_param']) * 100),
        event_dispatch=int(misc['creats_event_dispatch']),
        survival_parameter=misc['creats_survival_param'],
        dispatch_parameter=misc['creats_dispatch_param'],
        schedule_parameter=misc['creats_schedule_param'],
        time_parameter=misc['creats_time_param'],
        sweep_percent=int(sweep_percent),
        chapters=chapters,
        campaigns=campaigns,
        awakening_routes=routes,
    )
