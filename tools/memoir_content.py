"""Compile Memoir source joins; reconstruction algorithms are versioned mode policy."""

def build_memoir(blobs, parse, items, hero_catalog):
    def table(name):
        return parse(blobs[f'data/tables/{name}.lua'].data)

    def numbers(value, separator='|'):
        return [int(part) for part in value.split(separator) if part and part != '0']

    def battle_numbers(value):
        result = []
        for part in value.split('|'):
            try:
                result.append(int(part))
            except ValueError:
                # Match xyd.splitToNumber and the existing I8 Corpus.BattleLineup.
                continue
        return result

    settings = {row['key']: row['value'] for row in table('misc')}
    scrolls = {row['table_id']: row['stone_item_id'] for row in hero_catalog['templates']}
    girls = []
    fight_identifiers = set()
    box_identifiers = set()
    for row in table('maze_partner_campaign'):
        identifier = int(row['id'])
        fights = [numbers(group, ',') for group in row['monster_battle_id'].split('|')]
        boxes = [numbers(group, ',') for group in row['monster_dropbox'].split('|')]
        if len(fights) != 3 or len(boxes) != 3 or any(len(group) != 3 for group in boxes):
            raise ValueError('Memoir girl/floor shape drift')
        fight_identifiers.update(value for group in fights for value in group)
        box_identifiers.update(value for group in boxes for value in group)
        girls.append(dict(id=identifier, scroll=scrolls[identifier], fights=fights, boxes=boxes,
                          banned=numbers(row['ban_hero_id'])))
    bosses = [dict(id=int(row['boss_id']), battle=int(row['fight_id'])) for row in table('maze_campaign')]
    fight_identifiers.update(row['battle'] for row in bosses)
    floors = [dict(id=int(row['id']), energy=numbers(row['energy_cost']),
                   scroll=[int(value) for value in row['monster_stone_nums'].split('|')],
                   gifts=numbers(row['gift']), box_scroll=[int(value) for value in row['box_stone_nums'].split('|')],
                   bosses=numbers(row['monster_boss_campaign']), opponents=numbers(row['arena_player_range']))
              for row in table('maze_floor')]
    gift_identifiers = set(numbers(settings['school_memory_maze_pass_box']))
    gift_identifiers.update(value for row in floors for value in row['gifts'])
    gifts = []
    for row in table('gift'):
        identifier = int(row['id'])
        if identifier not in gift_identifiers:
            continue
        item_identifiers = numbers(row['items'])
        amounts = numbers(row['item_nums'])
        if len(item_identifiers) != len(amounts):
            raise ValueError('Memoir gift amount mismatch')
        drops = numbers(row['drops'])
        if len(drops) != 1:
            raise ValueError('Memoir gift drop-group shape drift')
        box_identifiers.update(drops)
        gifts.append(dict(id=identifier, box=drops[0], items=list(map(list, zip(item_identifiers, amounts)))))
    boxes = {identifier: [] for identifier in box_identifiers}
    for row in table('dropbox'):
        identifier = int(row['dropbox_id'])
        if identifier not in boxes:
            continue
        rate, amount = int(row['drop_rate']), int(row['item_num'])
        if row['roll_type'] != '1' or not 0 <= rate <= 10000 or amount <= 0:
            raise ValueError('Memoir drop law source boundary drift')
        boxes[identifier].append(dict(item=int(row['item_id']), amount=amount, rate=rate))
    fights = {}
    for row in table('battle'):
        identifier = int(row['fight_id'])
        if identifier in fight_identifiers:
            fights[str(identifier)] = [battle_numbers(row[f'fight_{wave}']) for wave in (1, 2, 3) if row[f'fight_{wave}']]
    resources = {int(row['id']): int(row['type']) for row in items}
    used = {row['item'] for group in boxes.values() for row in group}
    used.update(value for gift in gifts for value, _ in gift['items'])
    used.update(girl['scroll'] for girl in girls)
    used.update([int(settings['school_memory_maze_key_big']), int(settings['school_memory_maze_key_small'])])
    if any(resources.get(identifier) not in (1, 3, 4, 5, 6) for identifier in used):
        raise ValueError('Memoir reward custody is not an existing stack owner')
    selected = numbers(settings['school_memory_maze_girls'])
    if set(selected) != {girl['id'] for girl in girls}:
        raise ValueError('Memoir selected girl identity mismatch')
    revive = [int(row['buy_maze_reborn_cost']) for row in table('refresh_cost')]
    if len(floors) != 3 or len(girls) != 11 or len(bosses) != 6 or len(gifts) != 9 or len(boxes) != 75 or len(fights) != 226 or sum(map(len, boxes.values())) != 128 or len(revive) != 330:
        raise ValueError('Memoir source census drift')
    return dict(schema_version=1, contract_id='I9_MEMOIR_V1', source_archive='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf',
                columns=int(settings['school_memory_maze_col']), rows=int(settings['school_memory_maze_row']),
                big_key=int(settings['school_memory_maze_key_big']), small_key=int(settings['school_memory_maze_key_small']),
                selected=selected, counts=[dict(kind=int(row['id']), bounds=[int(value) for value in row['create_num'].split('|')]) for row in table('maze')],
                floors=floors, girls=girls, bosses=bosses, gifts=gifts,
                boxes=[dict(id=identifier, rows=rows) for identifier, rows in sorted(boxes.items())],
                fights=fights, revive_costs=revive, final_gifts=numbers(settings['school_memory_maze_pass_box']))
