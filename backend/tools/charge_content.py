"""Recharge products (I9_COMMERCE_CHARGE_V1 C4/C5) and VIP award gifts (C11)."""

POLICY = "I10_CHARGE_TAP_V1"
CARD_DAY_KEYS = {1: ('monthly_card_time2', 30), 2: ('season_privilege_card', 90), 3: ('halfyear_privilege_card', 180)}
CARD_BY_MONTH_CARD = {1: "MONTH", 4: "PRIVILEGE", 5: "PRIVILEGE"}
EXPECTED_PRODUCT_IDS = [
    80001001, 80001002, 80001003, 80001004, 80001005, 80001006, 80001007,
    80001010, 80001011, 80001012, 80001013, 80001014, 80001015, 80001021,
    80001022, 80001023, 80001024, 80001025, 80001026, 80001027, 80001028,
    80001029, 80001030,
]


def _int(row, key, minimum=0):
    value = int(row[key] or 0)
    if value < minimum:
        raise ValueError('charge.lua %s below minimum: %r' % (key, row['charge_id']))
    return value


def _pipe_ints(raw):
    return [int(value) for value in raw.split('|') if value != '']


def _card_days_by_type(blobs, parse):
    misc = {row['key']: row['value'] for row in parse(blobs['data/tables/misc.lua'].data)}
    out = {}
    for card_type, (key, expected) in CARD_DAY_KEYS.items():
        raw = misc.get(key)
        if raw is None:
            raise ValueError('misc.lua missing required key %s' % key)
        try:
            days = int(raw)
        except ValueError:
            raise ValueError('misc.lua %s is not an integer: %r' % (key, raw))
        if days != expected:
            raise ValueError('misc.lua %s drift: %r != %d' % (key, raw, expected))
        out[card_type] = days
    return out


def build_charge(blobs, parse):
    card_days_by_type = _card_days_by_type(blobs, parse)
    rows = sorted(parse(blobs['data/tables/charge.lua'].data), key=lambda row: int(row['charge_id']))
    if [int(row['charge_id']) for row in rows] != EXPECTED_PRODUCT_IDS:
        raise ValueError('charge.lua product profile drift')
    products = []
    for row in rows:
        charge_id = int(row['charge_id'])
        month_card = _int(row, 'month_card')
        card_type = _int(row, 'card_type')
        card = CARD_BY_MONTH_CARD.get(month_card, '')
        if card and card_type not in card_days_by_type:
            raise ValueError('charge.lua card without a duration: %d' % charge_id)
        if not card and card_type != 0:
            raise ValueError('charge.lua duration without a card: %d' % charge_id)
        card_days = card_days_by_type[card_type] if card else 0
        products.append(dict(id=charge_id, diamond=_int(row, 'diamond'), extra_diamond=_int(row, 'extra_diamond'),
                             first_extra_diamond=_int(row, 'first_extra_diamond'), card=card, card_days=card_days))
    by_id = {product['id']: product for product in products}
    month_days, season_days, halfyear_days = card_days_by_type[1], card_days_by_type[2], card_days_by_type[3]
    if by_id[80001001]['card_days'] != month_days or by_id[80001014]['card_days'] != season_days or by_id[80001015]['card_days'] != halfyear_days:
        raise ValueError('charge.lua month card duration drift')
    if by_id[80001010]['card_days'] != month_days or by_id[80001011]['card_days'] != season_days or by_id[80001012]['card_days'] != halfyear_days:
        raise ValueError('charge.lua privilege card duration drift')
    if by_id[80001013]['card'] != 'PRIVILEGE' or by_id[80001013]['card_days'] != by_id[80001010]['card_days']:
        raise ValueError('charge.lua discount privilege card drift')
    if by_id[80001028]['diamond'] or by_id[80001029]['diamond'] or by_id[80001028]['card'] or by_id[80001029]['card']:
        raise ValueError('charge.lua no-reward product drift')
    if sum(1 for product in products if product['card']) != 7:
        raise ValueError('charge.lua card row count drift')

    monthly_privilege = {int(row['id']): row for row in parse(blobs['data/tables/monthly_privilege.lua'].data)}
    if int(monthly_privilege[1]['skill_max']) != 10:
        raise ValueError('monthly_privilege.skill_max drift')

    gifts = {int(row['id']): row for row in parse(blobs['data/tables/gift.lua'].data)}
    vip_rows = sorted(parse(blobs['data/tables/vip.lua'].data), key=lambda row: int(row['id']))
    if [int(row['id']) for row in vip_rows] != list(range(16)):
        raise ValueError('vip.lua level profile drift')
    vip_awards = []
    for row in vip_rows[1:]:
        level = int(row['id'])
        gift_id = int(row['reward_item'])
        gift = gifts.get(gift_id)
        if gift is None:
            raise ValueError('vip.lua reward gift missing: %d' % level)
        items, item_nums = _pipe_ints(gift['items']), _pipe_ints(gift['item_nums'])
        if not items or len(items) != len(item_nums) or any(value <= 0 for value in items + item_nums):
            raise ValueError('vip gift item vector drift: %d' % gift_id)
        crystal = int(gift['crystal'] or 0)
        if crystal < 0:
            raise ValueError('vip gift crystal drift: %d' % gift_id)
        vip_awards.append(dict(level=level, gift_id=gift_id, items=items, item_nums=item_nums, crystal=crystal))
    if len(vip_awards) != 15 or [award['level'] for award in vip_awards] != list(range(1, 16)):
        raise ValueError('vip award level profile drift')
    if sum(1 for award in vip_awards if award['crystal'] > 0) != 15:
        raise ValueError('vip award crystal profile drift')

    return dict(policy=POLICY, privilege_skill_max=int(monthly_privilege[1]['skill_max']),
                products=products, vip_awards=vip_awards)
