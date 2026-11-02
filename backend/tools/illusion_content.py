"""Illusion source tables; D366 values live in I9_ILLUSION_POLICY_V1."""
from decimal import Decimal

FIRST_CAMPAIGN_ID = 100001
LAST_CAMPAIGN_ID = 100012
CAMPAIGN_TYPE = 8
FREE_CHANCES = 5
CHANCES_PER_BUY = 5
DAMAGE_CAP = 12000000
OPEN_LEVEL = 65
TEAM_HERO_LIMIT = 5
TEAM_POWER_LIMIT = 30
REWARD_PERCENT_HUNDREDTHS = 20
PERSON_RANGES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 70, 100, 200, 300, 400, 500, 700, 1000, 2000, 3000, 4000, 5000, 7000, 10000, 15000, 100000]
COMMUNITY_RANGES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 10000]
BUY_COST_HEAD = [50, 100, 200, 300, 400, 500, 1000]
VIP_LEVELS = 16


def _pipe_ints(raw):
    if not raw or raw == '0':
        return []
    return [int(value) for value in raw.split('|')]


def build_illusion(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    campaigns = []
    for row in table('paradise_campaign'):
        campaigns.append(dict(
            id=int(row['campaign_id']),
            campaign_type=int(row['campaign_type']),
            name=row['name'],
            description=row['campaign_des'],
            skills=[int(row['skill1']), int(row['skill2']), int(row['skill3']), int(row['skill4'])],
            previous_id=int(row['last_campaign_id']),
            next_id=int(row['next_campaign_id']),
            fight_id=int(row['fight_id']),
            model_id=int(row['model_id']),
            monster_id=int(row['monster_id']),
            hidden=int(row['if_hide']) != 0,
            model_black=row['model_black'],
            boss_name_text=row['boss_name_text'],
        ))
    campaigns.sort(key=lambda campaign: campaign['id'])
    if [campaign['id'] for campaign in campaigns] != list(range(FIRST_CAMPAIGN_ID, LAST_CAMPAIGN_ID + 1)):
        raise ValueError('illusion campaign census drift')
    if any(campaign['campaign_type'] != CAMPAIGN_TYPE or campaign['hidden'] or len(campaign['skills']) != 4 for campaign in campaigns):
        raise ValueError('illusion campaign shape drift')
    expected_next = {campaign_id: campaign_id + 1 for campaign_id in range(FIRST_CAMPAIGN_ID, FIRST_CAMPAIGN_ID + 9)}
    expected_next[FIRST_CAMPAIGN_ID + 9] = LAST_CAMPAIGN_ID
    expected_next[LAST_CAMPAIGN_ID - 1] = 0
    expected_next[LAST_CAMPAIGN_ID] = FIRST_CAMPAIGN_ID
    for campaign in campaigns:
        if campaign['next_id'] != expected_next[campaign['id']]:
            raise ValueError('illusion campaign chain drift')
    if campaigns[-2]['next_id'] != 0 or campaigns[-1]['next_id'] != FIRST_CAMPAIGN_ID:
        raise ValueError('illusion campaign terminal drift')

    person_rewards = []
    for row in table('paradise_person_reward'):
        item_ids = _pipe_ints(row['item_ids'])
        item_nums = _pipe_ints(row['item_nums'])
        if len(item_ids) != len(item_nums):
            raise ValueError('illusion person reward item drift')
        person_rewards.append(dict(id=int(row['id']), range=int(row['range']), coin=int(row['paradise_coin_num']), item_ids=item_ids, item_nums=item_nums))
    person_rewards.sort(key=lambda reward: reward['range'])
    if [reward['range'] for reward in person_rewards] != PERSON_RANGES:
        raise ValueError('illusion person reward census drift')

    community_rewards = []
    for row in table('paradise_community_reward'):
        community_rewards.append(dict(id=int(row['id']), range=int(row['range']), coin=int(row['times_paradise']), person_coin=int(row['times_paradise_person'])))
    community_rewards.sort(key=lambda reward: reward['range'])
    if [reward['range'] for reward in community_rewards] != COMMUNITY_RANGES:
        raise ValueError('illusion community reward census drift')

    misc = {row['key']: row['value'] for row in table('misc')}
    expected_misc = {
        'paradise_daily_challenge_num': '5',
        'paradise_get_challenge_num': '5',
        'paradise_boss_max_hp': '12000000',
        'paradise_team_limit': '5',
        'team_power_limit': '30',
        'paradise_start': '28800',
        'dungeon_boss_stop': '79080',
        'paradise_stop': '79200',
    }
    for key, value in expected_misc.items():
        if misc.get(key) != value:
            raise ValueError('illusion misc profile drift ' + key)
    reward_percent = Decimal(misc['paradise_mana_reward']) * 100
    if reward_percent != REWARD_PERCENT_HUNDREDTHS:
        raise ValueError('illusion reward percent drift')

    buy_costs = [int(row['buy_paradise_cost']) for row in sorted(table('refresh_cost'), key=lambda row: int(row['id'])) if row.get('buy_paradise_cost')]
    if buy_costs[:len(BUY_COST_HEAD)] != BUY_COST_HEAD or len(buy_costs) != 330:
        raise ValueError('illusion buy cost drift')
    vip = sorted(table('vip'), key=lambda row: int(row['id']))
    buy_caps = [int(row['paradise_buy_num']) for row in vip]
    if len(buy_caps) != VIP_LEVELS or buy_caps[:3] != [0, 0, 0] or buy_caps[3:] != list(range(1, VIP_LEVELS - 2)) or len(buy_costs) < buy_caps[-1]:
        raise ValueError('illusion vip buy cap drift')

    return dict(
        schema_version=1,
        contract_id='I9_ILLUSION_V1',
        policy_id='I9_ILLUSION_POLICY_V1',
        policy_version=1,
        open_level=OPEN_LEVEL,
        free_chances=int(misc['paradise_daily_challenge_num']),
        chances_per_buy=int(misc['paradise_get_challenge_num']),
        damage_cap=int(misc['paradise_boss_max_hp']),
        open_second=int(misc['paradise_start']),
        close_second=int(misc['dungeon_boss_stop']),
        settle_second=int(misc['paradise_stop']),
        team_hero_limit=int(misc['paradise_team_limit']),
        team_power_limit=int(misc['team_power_limit']),
        reward_percent_hundredths=int(reward_percent),
        campaigns=campaigns,
        person_rewards=person_rewards,
        community_rewards=community_rewards,
        buy_costs=buy_costs,
        buy_caps=buy_caps,
    )
