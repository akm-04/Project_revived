"""World Boss source tables; D364 coefficients live in I9_WORLD_BOSS_POLICY_V1."""
import re

ACTIVITY_ID = 1026
OPEN_LEVEL = 48
FIRST_BOSS_ID = 10011
LAST_BOSS_ID = 10015
NEED_BRAVE = [20000000, 40000000, 60000000, 80000000, 100000000]
RANK_RANGES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 40, 50, 70, 100, 200, 300, 400, 500, 700, 1000, 2000, 3000, 100000]
TEXT_KEYS = (
    'WORLD_BOSS_TITLE', 'WORLD_BOSS_RULES', 'WORLD_BOSS_OPEN_TIP', 'WORLD_BOSS_BUY_TIMES_ALERT',
    'WORLD_BOSS_SWEEP', 'WORLD_BOSS_HAS_NO_HERO', 'WORLD_BOSS_KEEP_RANK', 'WORLD_BOSS_BRAVE_STATE_DES',
    'WORLD_BOSS_RANK_REWARD', 'BOSS_RANK_TITLE_1', 'BOSS_RANK_TITLE_2', 'BOSS_RANK_TITLE_3',
    'BOSS_RANK_TITLE_4', 'BOSS_RANK_TITLE_5',
)
MAIL_KEYS = ('DUNGEON_MAIL_SENDER', 'DUNGEON_KILL_TITLE', 'DUNGEON_KILL_TEXT')


def _translations(data, keys):
    text = data.decode('utf-8-sig')
    found = {}
    for key in keys:
        match = re.search(r'\{\s*"' + key + r'",\s*"((?:[^"\\]|\\.)*)"\s*\}', text)
        if match is None:
            raise ValueError('translation missing ' + key)
        found[key] = match.group(1).replace('\\n', '\n')
    return found


def build_world_boss(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    campaigns = table('dungeon_campaign')
    bosses = []
    for row in campaigns:
        boss_id = int(row['campaign_id'])
        if boss_id < FIRST_BOSS_ID or boss_id > LAST_BOSS_ID:
            continue
        bosses.append(dict(
            id=boss_id,
            campaign_type=int(row['campaign_type']),
            name=row['name'],
            title=row['campaign_name'],
            description=row['campaign_des'],
            fight_id=int(row['fight_id']),
            monster_id=int(row['monster_id']),
            need_brave=int(row['dungeon_brave_node']),
            defeat_stone=int(row['defeat_stone']),
            previous_id=int(row['last_campaign_id']),
            next_id=int(row['next_campaign_id']),
            open_explain=row['open_explain'],
            skills=[int(row['skill1']), int(row['skill2']), int(row['skill3']), int(row['skill4'])],
        ))
    bosses.sort(key=lambda boss: boss['id'])
    if [boss['id'] for boss in bosses] != list(range(FIRST_BOSS_ID, LAST_BOSS_ID + 1)):
        raise ValueError('world boss campaign census drift')
    if [boss['need_brave'] for boss in bosses] != NEED_BRAVE:
        raise ValueError('world boss threshold drift')
    if bosses[0]['previous_id'] != 0 or bosses[-1]['next_id'] != 0:
        raise ValueError('world boss chain terminal drift')
    if any(boss['campaign_type'] != 8 for boss in bosses):
        raise ValueError('world boss campaign type drift')
    for previous, current in zip(bosses, bosses[1:]):
        if current['previous_id'] != previous['id'] or previous['next_id'] != current['id']:
            raise ValueError('world boss chain drift')

    rewards = []
    for row in table('dungeon_reward'):
        rewards.append(dict(
            range=int(row['range']),
            diamond=int(row['defeat_diamond']),
            mana=int(row['defeat_mana']),
            stone=int(row['defeat_stone']),
        ))
    rewards.sort(key=lambda reward: reward['range'])
    if [reward['range'] for reward in rewards] != RANK_RANGES:
        raise ValueError('world boss rank reward census drift')

    misc = {row['key']: row['value'] for row in table('misc')}
    if misc['dungeon_challenge_limit'] != '5' or misc['dungeon_boss_start'] != '0' or misc['dungeon_boss_stop'] != '79080' or misc['element_entrance_display_lv'] != '48':
        raise ValueError('world boss misc profile drift')

    texts = _translations(blobs['data/tables/translation.lua'].data, TEXT_KEYS)
    mail = _translations(blobs['data/tables/translation.lua'].data, MAIL_KEYS)
    rank_titles = [texts.pop('BOSS_RANK_TITLE_' + str(index)) for index in range(1, 6)]
    if rank_titles != [boss['name'] for boss in bosses]:
        raise ValueError('world boss rank title drift')

    return dict(
        schema_version=1,
        contract_id='I9_WORLD_BOSS_V1',
        policy_id='I9_WORLD_BOSS_POLICY_V1',
        policy_version=1,
        activity_id=ACTIVITY_ID,
        open_level=int(misc['element_entrance_display_lv']),
        attempts=int(misc['dungeon_challenge_limit']),
        window_start_seconds=int(misc['dungeon_boss_start']),
        window_stop_seconds=int(misc['dungeon_boss_stop']),
        bosses=bosses,
        rank_rewards=rewards,
        mail=dict(sender=mail['DUNGEON_MAIL_SENDER'], title=mail['DUNGEON_KILL_TITLE'], text=mail['DUNGEON_KILL_TEXT']),
        texts=dict(
            title=texts['WORLD_BOSS_TITLE'],
            rules=texts['WORLD_BOSS_RULES'],
            open_tip=texts['WORLD_BOSS_OPEN_TIP'],
            buy_alert=texts['WORLD_BOSS_BUY_TIMES_ALERT'],
            sweep=texts['WORLD_BOSS_SWEEP'],
            no_hero=texts['WORLD_BOSS_HAS_NO_HERO'],
            keep_rank=texts['WORLD_BOSS_KEEP_RANK'],
            brave_state=texts['WORLD_BOSS_BRAVE_STATE_DES'],
            rank_reward=texts['WORLD_BOSS_RANK_REWARD'],
            rank_titles=rank_titles,
        ),
    )
