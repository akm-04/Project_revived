"""Pure Social source facts from the verified R4A archive; no runtime policy."""

_EXPECTED_EXCHANGE_PRODUCTS = 3
_EXPECTED_DROPBOXES = 3
_EXPECTED_DROPBOX_ROLLS = 52
_EXPECTED_RECALL_MILESTONES = 25
_EXPECTED_GIFTS = 28
_EXPECTED_INVITATION_MISSIONS = 250
_EXPECTED_REWARD_ITEMS = 59
_DROPBOX_WEIGHT_TOTAL = 10000
_MAX_DROPBOX_WEIGHT = 10000
_MAX_REQUIRED_COUNT = 10
_EXPECTED_EXCHANGE_LIMIT = 10
_INVITATION_TYPE_COUNTS = {1: 10, 2: 40, 3: 50, 4: 150}
_RECALL_TYPE_COUNTS = {1: 4, 2: 2, 3: 4, 4: 15}
_SUPPORTED_GIFT_FIELDS = frozenset({'id', 'desc', 'items', 'item_nums', 'drops', 'crystal'})
_ZERO_STRINGS = frozenset({'', '0'})


def _integer(raw, label, error, minimum=None, maximum=None):
    try:
        value = int(raw)
    except (TypeError, ValueError) as exc:
        raise error(f'{label} is not an integer: {raw!r}') from exc
    if minimum is not None and value < minimum:
        raise error(f'{label} must be at least {minimum}, got {value}')
    if maximum is not None and value > maximum:
        raise error(f'{label} must be at most {maximum}, got {value}')
    return value


def _vector(raw, label, error):
    if raw in _ZERO_STRINGS:
        return []
    parts = raw.split('|')
    if any(part == '' for part in parts):
        raise error(f'{label} contains an empty element')
    return [_integer(part, f'{label}[{index}]', error) for index, part in enumerate(parts)]


def _unique_ids(rows, label, error):
    identifiers = {}
    for row in rows:
        identifier = _integer(row['id'], f'{label}.id', error, minimum=1)
        if identifier in identifiers:
            raise error(f'{label} duplicate id {identifier}')
        identifiers[identifier] = row
    return identifiers


def _exchange_products(rows, error):
    if len(rows) != _EXPECTED_EXCHANGE_PRODUCTS:
        raise error(f'exchange product source count drift: {len(rows)}')
    by_id = _unique_ids(rows, 'exchange product', error)
    products = []
    gift_ids = set()
    for identifier in sorted(by_id):
        row = by_id[identifier]
        gift_id = _integer(row['gift_id'], f'exchange product {identifier}.gift_id', error, minimum=1)
        if gift_id in gift_ids:
            raise error(f'exchange product duplicate gift {gift_id}')
        gift_ids.add(gift_id)
        products.append(dict(
            id=identifier,
            gift_id=gift_id,
            sell_type=_integer(row['sell_type'], f'exchange product {identifier}.sell_type', error, minimum=0),
            sell_price=_integer(row['sell_price'], f'exchange product {identifier}.sell_price', error, minimum=1),
            show_item=_integer(row['show_item'], f'exchange product {identifier}.show_item', error, minimum=1),
        ))
    return products


def _recall_milestones(rows, error):
    if len(rows) != _EXPECTED_RECALL_MILESTONES:
        raise error(f'recall milestone source count drift: {len(rows)}')
    by_id = _unique_ids(rows, 'recall milestone', error)
    milestones = []
    type_counts = {}
    for identifier in sorted(by_id):
        row = by_id[identifier]
        milestone_type = _integer(row['type'], f'recall milestone {identifier}.type', error, minimum=1)
        if milestone_type not in _RECALL_TYPE_COUNTS:
            raise error(f'recall milestone {identifier} unsupported type {milestone_type}')
        type_counts[milestone_type] = type_counts.get(milestone_type, 0) + 1
        milestones.append(dict(
            id=identifier,
            type=milestone_type,
            condition=_integer(row['condition'], f'recall milestone {identifier}.condition', error, minimum=1),
            gift_id=_integer(row['gift'], f'recall milestone {identifier}.gift', error, minimum=1),
        ))
    if type_counts != _RECALL_TYPE_COUNTS:
        raise error(f'recall milestone type counts drift: {type_counts}')
    expected_ids = list(range(100001, 100001 + _EXPECTED_RECALL_MILESTONES))
    if [row['id'] for row in milestones] != expected_ids:
        raise error('recall milestone identities drift')
    return milestones


def _gifts(rows, referenced_gift_ids, exchange_gift_ids, error):
    selected = [
        row for row in rows
        if _integer(row['id'], 'gift.id', error, minimum=1) in referenced_gift_ids
    ]
    if len(selected) != _EXPECTED_GIFTS:
        raise error(f'gift reference count drift: {len(selected)}')
    by_id = _unique_ids(selected, 'gift', error)
    gifts = []
    for gift_id in sorted(by_id):
        row = by_id[gift_id]
        for field, value in row.items():
            if field in _SUPPORTED_GIFT_FIELDS:
                continue
            if value not in _ZERO_STRINGS:
                raise error(f'gift {gift_id} unsupported nonzero channel {field}')
        item_ids = _vector(row['items'], f'gift {gift_id}.items', error)
        quantities = _vector(row['item_nums'], f'gift {gift_id}.item_nums', error)
        if len(item_ids) != len(quantities):
            raise error(f'gift {gift_id} item vectors differ in length')
        items = []
        for item_id, quantity in zip(item_ids, quantities):
            if item_id <= 0:
                raise error(f'gift {gift_id} item id must be positive')
            if quantity <= 0:
                raise error(f'gift {gift_id} item quantity must be positive')
            items.append(dict(item_id=item_id, quantity=quantity))
        crystal = _integer(row['crystal'], f'gift {gift_id}.crystal', error, minimum=0)
        drops = _vector(row['drops'], f'gift {gift_id}.drops', error)
        if any(dropbox_id <= 0 for dropbox_id in drops):
            raise error(f'gift {gift_id} dropbox id must be positive')
        if not drops and crystal <= 0 and not items:
            raise error(f'gift {gift_id} has no reward channel')
        if drops and (crystal > 0 or items):
            raise error(f'gift {gift_id} mixes drops with direct rewards')
        if drops and gift_id not in exchange_gift_ids:
            raise error(f'gift {gift_id} drops are not an exchange product')
        gifts.append(dict(id=gift_id, crystal=crystal, items=items, drops=drops))
    if set(by_id) != referenced_gift_ids:
        raise error(f'gift references drift: missing {sorted(referenced_gift_ids - set(by_id))}')
    return gifts


def _dropboxes(rows, referenced_dropbox_ids, error):
    if not referenced_dropbox_ids:
        raise error('exchange products reference no dropbox')
    grouped = {dropbox_id: [] for dropbox_id in referenced_dropbox_ids}
    row_ids = set()
    for index, row in enumerate(rows, start=1):
        dropbox_id = _integer(row['dropbox_id'], f'dropbox row {index}.dropbox_id', error, minimum=1)
        if dropbox_id not in grouped:
            continue
        row_id = _integer(row['id'], f'dropbox row {index}.id', error, minimum=1)
        if row_id in row_ids:
            raise error(f'dropbox duplicate row id {row_id}')
        row_ids.add(row_id)
        roll_type = _integer(row['roll_type'], f'dropbox row {row_id}.roll_type', error, minimum=0)
        if roll_type != 1:
            raise error(f'dropbox row {row_id} unsupported roll_type {roll_type}')
        grouped[dropbox_id].append(dict(
            id=row_id,
            item_id=_integer(row['item_id'], f'dropbox row {row_id}.item_id', error, minimum=1),
            item_num=_integer(row['item_num'], f'dropbox row {row_id}.item_num', error, minimum=1),
            drop_rate=_integer(
                row['drop_rate'], f'dropbox row {row_id}.drop_rate', error,
                minimum=0, maximum=_MAX_DROPBOX_WEIGHT,
            ),
            roll_type=roll_type,
        ))
    dropboxes = []
    for dropbox_id in sorted(grouped):
        rolls = sorted(grouped[dropbox_id], key=lambda roll: roll['id'])
        if not rolls:
            raise error(f'dropbox {dropbox_id} has no rows')
        if sum(roll['drop_rate'] for roll in rolls) != _DROPBOX_WEIGHT_TOTAL:
            raise error(f'dropbox {dropbox_id} weights do not sum to {_DROPBOX_WEIGHT_TOTAL}')
        item_ids = [roll['item_id'] for roll in rolls]
        if len(set(item_ids)) != len(item_ids):
            raise error(f'dropbox {dropbox_id} duplicates an outcome item')
        dropboxes.append(dict(id=dropbox_id, rolls=rolls))
    if len(dropboxes) != _EXPECTED_DROPBOXES:
        raise error(f'dropbox source count drift: {len(dropboxes)}')
    if sum(len(dropbox['rolls']) for dropbox in dropboxes) != _EXPECTED_DROPBOX_ROLLS:
        raise error('dropbox weighted row count drift')
    return dropboxes


def _exchange_limit(rows, error):
    values = {row['key']: row['value'] for row in rows}
    raw = values.get('friend_buy_limit')
    if raw is None:
        raise error('misc.lua missing friend_buy_limit')
    limit = _integer(raw, 'misc.lua friend_buy_limit', error, minimum=1)
    if limit != _EXPECTED_EXCHANGE_LIMIT:
        raise error(f'misc.lua friend_buy_limit drift: {limit}')
    return limit



def _recall_rules(rows, error):
    settings = {
        'friend_recall_days': ('offline_days', 7),
        'friend_recall_task_time': ('task_days', 3),
        'friend_recall_task_limit': ('max_active_tasks', 3),
    }
    rules = {}
    for row in rows:
        setting = settings.get(row['key'])
        if setting is None:
            continue
        field, expected = setting
        if field in rules:
            raise error(f'duplicate recall setting {row["key"]}')
        value = _integer(row['value'], row['key'], error, minimum=1)
        if value != expected:
            raise error(f'recall setting drift {row["key"]}: {value}')
        rules[field] = value
    if len(rules) != len(settings):
        raise error('missing source recall setting')
    return rules


def _invitation_missions(rows, error):
    if len(rows) != _EXPECTED_INVITATION_MISSIONS:
        raise error(f'invitation mission source count drift: {len(rows)}')
    by_id = _unique_ids(rows, 'invitation mission', error)
    expected_ids = list(range(100001, 100001 + _EXPECTED_INVITATION_MISSIONS))
    if sorted(by_id) != expected_ids:
        raise error('invitation mission identities drift')
    previous = {}
    following = {}
    missions = []
    type_counts = {}
    for mission_id in sorted(by_id):
        row = by_id[mission_id]
        mission_type = _integer(row['type'], f'invitation mission {mission_id}.type', error, minimum=1)
        if mission_type not in _INVITATION_TYPE_COUNTS:
            raise error(f'invitation mission {mission_id} unsupported type {mission_type}')
        type_counts[mission_type] = type_counts.get(mission_type, 0) + 1
        required_count, threshold = _mission_task_num(row['task_num'], mission_id, mission_type, error)
        extra = _integer(row['extra'], f'invitation mission {mission_id}.extra', error, minimum=0, maximum=1)
        requirement = _integer(row['req'], f'invitation mission {mission_id}.req', error, minimum=0)
        if requirement != 0:
            raise error(f'invitation mission {mission_id} unsupported requirement {requirement}')
        previous_ids = _vector(row['pre_task_id'], f'invitation mission {mission_id}.pre_task_id', error)
        next_ids = _vector(row['next_task_id'], f'invitation mission {mission_id}.next_task_id', error)
        if len(set(previous_ids)) != len(previous_ids) or len(set(next_ids)) != len(next_ids):
            raise error(f'invitation mission {mission_id} duplicates a graph reference')
        previous[mission_id] = previous_ids
        following[mission_id] = next_ids
        missions.append(dict(
            id=mission_id,
            type=mission_type,
            required_count=required_count,
            threshold=threshold,
            diamond=_integer(row['diamond'], f'invitation mission {mission_id}.diamond', error, minimum=1),
            requirement=requirement,
            extra=extra,
            previous_task_ids=previous_ids,
            next_task_ids=next_ids,
        ))
    if type_counts != _INVITATION_TYPE_COUNTS:
        raise error(f'invitation mission type counts drift: {type_counts}')
    _validate_graph(previous, following, error)
    return missions


def _mission_task_num(raw, mission_id, mission_type, error):
    parts = raw.split('|')
    if mission_type == 1:
        if len(parts) != 1:
            raise error(f'invitation mission {mission_id} type 1 requires one task_num value')
        return _integer(
            parts[0], f'invitation mission {mission_id}.required_count', error,
            minimum=1, maximum=_MAX_REQUIRED_COUNT,
        ), None
    if len(parts) != 2:
        raise error(f'invitation mission {mission_id} type {mission_type} requires count and threshold')
    return (
        _integer(
            parts[0], f'invitation mission {mission_id}.required_count', error,
            minimum=1, maximum=_MAX_REQUIRED_COUNT,
        ),
        _integer(parts[1], f'invitation mission {mission_id}.threshold', error, minimum=1),
    )


def _validate_graph(previous, following, error):
    identifiers = set(previous)
    for mission_id in sorted(identifiers):
        for target in following[mission_id]:
            if target not in identifiers:
                raise error(f'invitation mission {mission_id} references missing next task {target}')
            if target == mission_id:
                raise error(f'invitation mission {mission_id} references itself')
        for source in previous[mission_id]:
            if source not in identifiers:
                raise error(f'invitation mission {mission_id} references missing previous task {source}')
            if source == mission_id:
                raise error(f'invitation mission {mission_id} references itself')
    for mission_id in sorted(identifiers):
        if set(following[mission_id]) != {
            source for source in identifiers if mission_id in previous[source]
        }:
            raise error(f'invitation mission {mission_id} graph edges are asymmetric')
    remaining = {
        mission_id: len(set(previous[mission_id])) for mission_id in identifiers
    }
    ready = sorted(mission_id for mission_id, count in remaining.items() if count == 0)
    visited = 0
    while ready:
        current = ready.pop()
        visited += 1
        for target in sorted(set(following[current])):
            remaining[target] -= 1
            if remaining[target] == 0:
                ready.append(target)
    if visited != len(identifiers):
        raise error('invitation mission graph contains a cycle')


def _source_item_ids(blobs, error):
    try:
        from generate_builtin_content import parse_encoded_item_table
    except ImportError as exc:
        raise error(f'item source parser unavailable: {exc}') from exc
    try:
        rows = parse_encoded_item_table(blobs['data/tables/item.lua'].data)
    except Exception as exc:
        raise error(f'item source parse failed: {exc}') from exc
    return {
        _integer(row['id'], 'item.lua.id', error, minimum=1) for row in rows
    }


def _validate_items(products, gifts, dropboxes, source_item_ids, gift_ids, error):
    reward_item_ids = set()
    for dropbox in dropboxes:
        reward_item_ids.update(roll['item_id'] for roll in dropbox['rolls'])
    for gift in gifts:
        reward_item_ids.update(item['item_id'] for item in gift['items'])
    if len(reward_item_ids) != _EXPECTED_REWARD_ITEMS:
        raise error(f'reward item count drift: {len(reward_item_ids)}')
    if reward_item_ids & gift_ids:
        raise error('reward item ids must differ from gift ids')
    display_item_ids = {product['show_item'] for product in products}
    missing = (reward_item_ids | display_item_ids) - source_item_ids
    if missing:
        raise error(f'referenced items missing from item.lua: {sorted(missing)}')


def _compile_social(blobs, parse_table, error):
    products = _exchange_products(
        parse_table(blobs['data/tables/friend_shop_item.lua'].data), error
    )
    recalls = _recall_milestones(
        parse_table(blobs['data/tables/friend_recall.lua'].data), error
    )
    referenced_gift_ids = {product['gift_id'] for product in products}
    referenced_gift_ids.update(milestone['gift_id'] for milestone in recalls)
    exchange_gift_ids = {product['gift_id'] for product in products}
    gifts = _gifts(
        parse_table(blobs['data/tables/gift.lua'].data),
        referenced_gift_ids,
        exchange_gift_ids,
        error,
    )
    referenced_dropbox_ids = {
        dropbox_id for gift in gifts for dropbox_id in gift['drops']
    }
    dropboxes = _dropboxes(
        parse_table(blobs['data/tables/dropbox.lua'].data), referenced_dropbox_ids, error
    )
    missions = _invitation_missions(
        parse_table(blobs['data/tables/invitation_mission.lua'].data), error
    )
    _validate_items(
        products,
        gifts,
        dropboxes,
        _source_item_ids(blobs, error),
        set(referenced_gift_ids),
        error,
    )
    return dict(
        schema_version=2,
        recall_rules=_recall_rules(parse_table(blobs['data/tables/misc.lua'].data), error),
        exchange_limit=_exchange_limit(
            parse_table(blobs['data/tables/misc.lua'].data), error
        ),
        exchange_products=products,
        dropboxes=dropboxes,
        recall_milestones=recalls,
        gifts=gifts,
        invitation_missions=missions,
    )


def build_social(blobs, parse_table, error):
    try:
        return _compile_social(blobs, parse_table, error)
    except (KeyError, TypeError, AttributeError) as exc:
        raise error(f'social source fields are missing or mistyped: {exc}') from exc
