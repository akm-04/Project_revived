"""Compile source identities; reconstructed board and draw policies live in the mode."""
from fractions import Fraction


def permille(value):
    scaled = Fraction(value) * 1000
    if scaled.denominator != 1:
        raise ValueError('Dodgeball probability exceeds exact per-mille precision')
    return int(scaled)


def build_dodgeball(blobs, parse, items, hero_catalog):
    def table(name):
        return parse(blobs[f'data/tables/{name}.lua'].data)

    item_types = {int(row['id']): int(row['type']) for row in items}
    hero_scrolls = {row['table_id']: row['stone_item_id'] for row in hero_catalog['templates']}
    targets = []
    for row in table('dodge_ball'):
        hero = int(row['partner_id']) if row['partner_id'] else 0
        item = int(row['item_id'])
        seasonal = int(row['group']) == 5
        if hero and hero_scrolls.get(hero) != item:
            raise ValueError('Dodgeball Hero/scroll identity mismatch')
        if (not seasonal and (not hero or item_types[item] != 3)) or (seasonal and item_types[item] != 4):
            raise ValueError('Dodgeball reward owner mismatch')
        targets.append(dict(id=int(row['id']), group=int(row['group']), hero_table_id=hero,
                            item_id=item, amount=int(row['num']), weight=int(row['wij']),
                            probability_permille=permille(row['probability'])))
    groups = []
    for row in table('dodge_group'):
        minimum, maximum = map(int, row['num'].split('|'))
        groups.append(dict(id=int(row['group']), minimum=minimum, maximum=maximum,
                           weight=int(row['wij']), activity=int(row['act'] or '0')))
    buffs = []
    for row in table('dodge_buff'):
        identifier = int(row['id'])
        effect = permille(row['effect']) if identifier in (2, 3) else int(row['effect'])
        buffs.append(dict(id=identifier, weight=int(row['wij']), effect=effect))
    settings = {row['key']: row['value'] for row in table('misc')}
    minimum_buffs, maximum_buffs = map(int, settings['dodge_buffnum'].split('|'))
    if len(targets) != 90 or len(groups) != 5 or len(buffs) != 6 or int(settings['dodge_character']) != 25:
        raise ValueError('Dodgeball source census drift')
    if int(settings['dodge_ticket_cost']) != 1:
        raise ValueError('Dodgeball ticket price drift')
    activities = [dict(id=int(row['act_id']), kind=int(row['activity_type']), parameter=row['prop_up'], count=int(row['effect_num'])) for row in table('dodge_activity')]
    return dict(schema_version=1, contract_id='I9_DODGEBALL_V1', targets=targets, groups=groups, buffs=buffs,
                activities=activities,
                ticket_item=int(settings['dodge_ticket']), initial_balls=int(settings['dodge_ballnum']),
                minimum_buffs=minimum_buffs, maximum_buffs=maximum_buffs,
                friend_probability_permille=permille(settings['dodge_friendpro']),
                friend_balls=int(settings['dodge_friend_ballnum']), incoming_limit=int(settings['dodge_invited']),
                marked_multiplier=int(settings['dodge_bonus']))
