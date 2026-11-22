"""Top Floor source tables plus the labelled C5B private ladder policy inputs."""
import json
from decimal import Decimal
from pathlib import Path
from one_on_one_content import _translations

TEAM_COLUMNS = ('robot1', 'robot2', 'robot3', 'robot4', 'robot5')

# PRIVATE_POLICY: role-balanced lineups for robots inside the rank band. The
# checkout holds the extracted team_catalog data so generation never reads tmp/.
ROBOT_LINEUP_SOURCE = Path(__file__).resolve().with_name('top_floor_robot_lineups.json')
POSITION_DISTANCE_TYPES = {'front': 2, 'middle': 3, 'rear': 4}
ROBOT_LINEUP_POLICY = dict(
    label='PRIVATE_POLICY',
    policy_id='I9_10_ROBOT_LINEUPS_V1_PRIVATE_POLICY',
    selection='fnv1a64(decimal rank) modulo lineup count',
)

# PRIVATE_POLICY: the user's rank strength bands. Quality values are
# xyd.EquipQuality (enums.lua:729-745): 16 red+1, 15 red, 13 orange+1,
# 12 orange, 3 green+1. Values interpolate linearly between anchors and clamp
# to the robot's own source level/quality/star; ranks beyond meeting_rank use
# the source values unchanged.
ROBOT_RANK_BANDS = dict(
    label='PRIVATE_POLICY',
    policy_id='I9_10_ROBOT_RANK_BANDS_V1_PRIVATE_POLICY',
    meeting_rank=500,
    anchors=[
        dict(rank=1, quality=16, level=100, star=3, pet_level=100),
        dict(rank=10, quality=16, level=100, star=3, pet_level=100),
        dict(rank=11, quality=16, level=99, star=3, pet_level=99),
        dict(rank=25, quality=15, level=90, star=3, pet_level=90),
        dict(rank=26, quality=13, level=89, star=3, pet_level=89),
        dict(rank=500, quality=3, level=14, star=1, pet_level=14),
    ])


def _ints(raw):
    return [int(x) for x in raw.split('|')]


def _ten_thousandths(raw):
    value = Decimal(raw) * 10000
    if value != value.to_integral_value() or value < 0:
        raise ValueError('arena reward rate precision drift: ' + raw)
    return int(value)


def _lineup_failure(entry, partner_rows, partner_keys, indexed_field):
    heroes = entry.get('heroes')
    if not isinstance(heroes, list) or len(heroes) != 5:
        return 'expected five heroes'
    partner_ids = [hero.get('partner_id') for hero in heroes]
    if len(set(partner_ids)) != 5:
        return 'duplicate partner id'
    counts = {position: 0 for position in POSITION_DISTANCE_TYPES}
    previous = 0
    for hero in heroes:
        position = hero.get('position')
        if position not in POSITION_DISTANCE_TYPES:
            return 'unknown position ' + str(position)
        distance = POSITION_DISTANCE_TYPES[position]
        if distance < previous:
            return 'heroes not ordered front to rear'
        previous = distance
        counts[position] += 1
        partner_id = hero.get('partner_id')
        values = partner_rows.get(partner_id)
        if values is None:
            return 'partner %s is not in the client partner table' % partner_id
        if indexed_field(partner_keys, values, 'first_table_id', row_id=partner_id) != '0':
            return 'partner %s is not a base obtainable hero' % partner_id
        if indexed_field(partner_keys, values, 'librart_show', row_id=partner_id) != '1':
            return 'partner %s is not library visible' % partner_id
        if int(indexed_field(partner_keys, values, 'distance_type', row_id=partner_id)) != distance:
            return 'partner %s distance_type does not match %s' % (partner_id, position)
    for position, count in counts.items():
        if not 1 <= count <= 2:
            return '%s count %d is outside 1-2' % (position, count)
    return ''


def build_robot_lineups(partner_keys, partner_rows, indexed_field):
    # PRIVATE_POLICY: every extracted lineup is revalidated against the client
    # partner table; a failing lineup is dropped as a whole and recorded.
    source = json.loads(ROBOT_LINEUP_SOURCE.read_bytes())
    source_sha256 = source.get('source_sha256')
    if not isinstance(source_sha256, str) or len(source_sha256) != 64:
        raise ValueError('top floor robot lineup provenance drift')
    entries = source.get('lineups')
    if not isinstance(entries, list) or not entries:
        raise ValueError('top floor robot lineup source empty')
    lineups, dropped = [], []
    for entry in entries:
        reason = _lineup_failure(entry, partner_rows, partner_keys, indexed_field)
        if reason:
            dropped.append(dict(id=entry.get('id', 'UNKNOWN'), reason=reason))
            continue
        lineups.append(dict(id=entry['id'], name=entry.get('name', ''), tier=entry.get('tier', ''),
                            heroes=[dict(partner_id=int(hero['partner_id']), position=hero['position']) for hero in entry['heroes']]))
    if not lineups:
        raise ValueError('top floor robot lineups: every lineup failed validation')
    return dict(**ROBOT_LINEUP_POLICY, source=source.get('source', ''), source_sha256=source_sha256,
                lineups=lineups, dropped=dropped)


def build_top_floor(blobs, parse, pet_templates, robot_lineups):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    misc = {r['key']: r['value'] for r in table('misc')}
    functions = {r['id']: r for r in table('function')}
    if functions['84']['open_control'] != '1' or functions['4']['level'] != '1|10':
        raise ValueError('Top Floor function gate drift')
    rewards = []
    for r in sorted(table('arena_reward'), key=lambda r: int(r['id'])):
        items = [[i, n] for i, n in zip(_ints(r['daily_item']), _ints(r['daily_item_num'])) if i > 0 and n > 0]
        rewards.append(dict(id=int(r['id']), range=int(r['range']), daily_crystal=int(r['daily_diamond']), daily_mana=int(r['daily_mana']),
                            daily_arena_coin=int(r['daily_arena_coin']), items=items, frame_id=int(r['frame_id']),
                            best_rank_rate=_ten_thousandths(r['rank_reward_diamond_new'])))
    if [r['id'] for r in rewards] != list(range(1, 31)) or rewards[0]['frame_id'] != 120001004 or rewards[-1]['range'] != 100000:
        raise ValueError('arena_reward profile drift')
    vip = [dict(level=int(r['id']), purchases=int(r['num_arena']), reset=int(r['arena_reset'])) for r in sorted(table('vip'), key=lambda r: int(r['id']))]
    costs = [int(r['buy_arena_cost']) for r in sorted(table('refresh_cost'), key=lambda r: int(r['id']))]
    heroes = {r['id']: r for r in table('robot_hero')}
    robot_heroes = [dict(id=int(r['id']), level=int(r['lev']), partner_id=int(r['partner_id']), quality=int(r['quality']), star=int(r['star']), equip_flags=_ints(r['equips']))
                    for r in sorted(heroes.values(), key=lambda r: int(r['id']))]
    robots = []
    dropped = 0
    for index, r in enumerate(sorted(table('robot'), key=lambda r: int(r['team_id']))):
        if int(r['team_id']) != index + 1:
            raise ValueError('robot team ids are not contiguous')
        members = [r[c] for c in TEAM_COLUMNS if r[c]]
        kept = [int(m) for m in members if m in heroes]
        dropped += len(members) - len(kept)
        if not kept:
            raise ValueError('robot team without source heroes')
        robots.append(dict(level=int(r['team_level']), heroes=kept))
    if len(robots) != 10325 or dropped != 72:
        raise ValueError('robot ladder profile drift')
    names = {}
    for r in sorted(table('random_name'), key=lambda r: int(r['id'])):
        names.setdefault(r['name_type'], []).append(r['text'])
    pet_pool = [dict(table_id=int(t['table_id']), initial_star=int(t['initial_star'])) for t in pet_templates if not t['is_awakened']]
    if len(pet_pool) != 27 or [p['table_id'] for p in pet_pool] != sorted(p['table_id'] for p in pet_pool):
        raise ValueError('top floor pet pool drift')
    anchors = ROBOT_RANK_BANDS['anchors']
    if [a['rank'] for a in anchors] != sorted(a['rank'] for a in anchors) or anchors[-1]['rank'] != ROBOT_RANK_BANDS['meeting_rank']:
        raise ValueError('top floor robot rank band anchors drift')
    return dict(schema_version=1, contract_id='C5B_TOP_FLOOR_MODE_V1', policy_id='C5B_TOP_FLOOR_PRIVATE_POLICY_V1',
                pet_pool=pet_pool, robot_rank_bands=ROBOT_RANK_BANDS, robot_lineups=robot_lineups,
                function_id=4, required_level=10, free_tickets=5, buy_restore=int(misc['arena_buy_num']), cooldown_seconds=int(misc['arena_cooldown']),
                reset_cost=int(misc['arena_refresh_cost']), match_hundredths=[int(Decimal(misc['arena_match_param_' + k]) * 100) for k in '123'],
                cutoff_seconds=int(misc['arena_gift_time1']), freeze_end_seconds=int(misc['arena_gift_time2']), records_max=int(misc['arena_defense_list_max']),
                mail_title=misc['arena_mail_title'], mail_text=misc['arena_mail_text'], mail_sender=misc['arena_mail_sender'],
                robot_avatar_id=110001001, robot_frame_id=120001001, rewards=rewards, vip=vip, buy_costs=costs,
                robots=robots, robot_heroes=robot_heroes, first_names=names['0'], last_names=names['1'])


def build_task_modes(blobs, parse, parse_indexed, indexed_field):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    rules = []
    for row in sorted(table('arena_mode'), key=lambda row: int(row['id'])):
        raw_buffs = row['buffs']
        groups = []
        if raw_buffs != '0':
            groups = [_ints(raw_buffs)] if int(row['id']) != 6 else [
                [int(value) for value in group.split(',')] for group in raw_buffs.split('|')]
        rules.append(dict(id=int(row['id']), title=row['title'], description=row['desc'], rule_text=row['rule_text'],
                          hero_slots=int(row['partner_num']), pet_allowed=row['can_pet_join'] == '1',
                          leader_allowed=row['can_leader_join'] == '1', reset_defense=row['team_reset'] == '1',
                          banned_tables=[] if row['banned_partner'] == '0' else _ints(row['banned_partner']), buff_groups=groups))
    # PRIVATE_POLICY D512: the source's unnamed 4th column (values 1..17) has no
    # client table mapping an index to a ban or camp set, so it stays dropped.
    schedule = [dict(date=row['id'], mode=int(row['mode']), submode=int(row['submode']))
                for row in sorted(table('arena_mode_schedule'), key=lambda row: row['id'])]
    rewards = []
    for row in sorted(table('arena_mode_reward'), key=lambda row: int(row['id'])):
        item_ids, quantities = _ints(row['daily_item']), _ints(row['daily_item_num'])
        if len(item_ids) != len(quantities) or any(
                item < 0 or quantity < 0 or (item == 0) != (quantity == 0)
                for item, quantity in zip(item_ids, quantities)):
            raise ValueError('arena_mode_reward item vector drift')
        rewards.append(dict(id=int(row['id']), range=int(row['range']), daily_crystal=int(row['daily_diamond']),
                            daily_mana=int(row['daily_mana']), daily_arena_coin=int(row['daily_arena_coin']),
                            items=[[item, quantity] for item, quantity in zip(item_ids, quantities) if item > 0],
                            frame_id=0, best_rank_rate=0))
    if [rule['id'] for rule in rules] != list(range(1, 7)) or len(schedule) != 91 or len(rewards) != 17:
        raise ValueError('arena task mode source profile drift')
    mail = _translations(blobs['data/tables/translation.lua'].data, ('ARENA_MODE_MAIL_TITLE', 'ARENA_MODE_MAIL_TEXT', 'ARENA_MODE_MAIL_SENDER'))
    camps = {}
    for name in ('partner', 'super_partner'):
        keys, rows = parse_indexed(blobs['data/tables/' + name + '.lua'].data)
        for identity, values in sorted(rows.items()):
            camp = int(indexed_field(keys, values, 'from', row_id=identity))
            if camp not in (1, 2, 3, 4) or str(identity) in camps:
                raise ValueError('arena task mode Hero camp drift')
            camps[str(identity)] = camp
    misc = {row['key']: row['value'] for row in table('misc')}
    return dict(schema_version=1, contract_id='I9_TOP_FLOOR_TASK_MODE_V1', policy_id='I9_TOP_FLOOR_TASK_POLICY_V1',
                rules=rules, schedule=schedule, rewards=rewards, hero_camps=camps,
                mail_title=mail['ARENA_MODE_MAIL_TITLE'], mail_text=mail['ARENA_MODE_MAIL_TEXT'], mail_sender=mail['ARENA_MODE_MAIL_SENDER'],
                entry_rank=int(misc['arena_mode_enter_rank_req']), entry_challenges=int(misc['arena_mode_enter_battle_req']),
                server_level=int(misc['arena_mode_open_lv_req']), attacking_leader_buff=int(misc['arena_mode_attack_leader_buff']),
                defending_leader_buff=int(misc['arena_mode_defence_leader_buff']))
