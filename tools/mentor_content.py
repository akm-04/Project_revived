"""Pure Mentor (My Class) source facts from the verified c7e src_64 archive.

Finite, strict extraction only. This module records source definitions and the
exact current help strings; it does not infer server algorithms from field
names. Runtime policy belongs to the future 10F application owner.
"""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_builtin_content as gen  # noqa: E402

MENTOR_SCHEMA_VERSION = 2
MENTOR_TEACHER_TABLE = 'data/tables/teacher_mission.lua'
MENTOR_TEACHER_SHA256 = '212ad92db12055acce3343f72e769d87d3c71a5ed901c4f4642337bc383490c2'
MENTOR_SOURCE_TABLES = (
    MENTOR_TEACHER_TABLE,
    'data/tables/misc.lua',
    'data/tables/function.lua',
    'data/tables/translation.lua',
    'data/tables/gift.lua',
)
MENTOR_SOURCE_ROLE = 'I9_10F_MENTOR_SOURCE_BOUNDARY'

_EXPECTED_MISSION_KEYS = (
    'id', 'desc', 'type', 'gift', 'category', 'lev', 'condition', 'extra_info', 'refresh', 'is_hide',
)
_EXPECTED_FUNCTION_KEYS = (
    'id', 'name', 'level', 'condition', 'icon', 'level_tips', 'is_on_levelup_wnd',
    'open_control', 'tip', 'is_function_show', 'fx_num', 'function_pic', 'function_desc',
)
_EXPECTED_MISSION_IDS = tuple(range(100001, 100026))
_EXPECTED_GIFT_IDS = frozenset(range(90008004, 90008029))
_EXPECTED_CATEGORY_COUNTS = {1: 4, 2: 8, 3: 6, 4: 3, 5: 1, 6: 2, 7: 1}
_EXPECTED_TYPE_COUNTS = {1: 21, 2: 4}
_HIDDEN_MISSIONS = {100005: ('9000', '1000000'), 100006: ('9001', '1000001')}
_FINISH_MISSION_ID = 100025
_MIN_INT64 = -(2 ** 63)
_MAX_INT64 = 2 ** 63 - 1
MENTOR_CATALOG_SHA256 = 'fe6c878703af4efcdcd575ffac292b31806238c9d8ad7134f088a572a1057519'

_EXPECTED_RULES = {
    'teacher_relation_daily': 100,
    'teacher_relation_max': 3000,
    'teacher_lev': 60,
    'teacher_relation_broken': 86400,
    'teacher_relation_send_times': 3,
    'teacher_relation_send_broken': 172800,
    'teacher_terminate_time_limit': 86400,
    'teacher_finding_num': 20,
    'student_lev_limit': 90,
    'teacher_finding_range': 100,
    'teacher_lev_relation': 3,
    'teacher_gift_intimacy': 100,
    'teacher_player_open_lev': 10,
    'teacher_finish_mission': _FINISH_MISSION_ID,
    'teacher_min_level': 60,
}

_EXPECTED_FUNCTION = {
    'id': '50',
    'name': 'My Class',
    'level': '8|10',
    'condition': '60',
    'icon': '1',
    'level_tips': '0',
    'is_on_levelup_wnd': '1',
    'open_control': '1',
    'tip': 'Unlock when Academy level reaches 10',
    'is_function_show': '',
    'fx_num': '',
    'function_pic': '',
    'function_desc': '',
}

_HELP_SOURCE_KEYS = {
    'rule': 'TEACHER_RULE',
    'rule_title': 'TEACHER_RULE_TITLE',
    'open_tips': 'TEACHER_OPEN_TIPS',
    'mentor_name': 'TEACHER_NAME1',
    'student_name': 'TEACHER_NAME2',
    'main_tip1': 'TEACHER_MAIN_TIP1',
    'main_tip2': 'TEACHER_MAIN_TIP2',
    'send_tip1': 'TEACHER_SEND_TIP1',
    'send_tip2': 'TEACHER_SEND_TIP2',
    'send_tip3': 'TEACHER_SEND_TIP3',
    'send_tip4': 'TEACHER_SEND_TIP4',
    'send_tip5': 'TEACHER_SEND_TIP5',
    'send_tip6': 'TEACHER_SEND_TIP6',
    'send_tip7': 'TEACHER_SEND_TIP7',
    'friend_tip': 'TEACHER_FRIEND_TIP',
    'relation_broken_tip1': 'TEACHER_RELATION_BROKEN_TIP1',
    'relation_broken_tip2': 'TEACHER_RELATION_BROKEN_TIP2',
    'relation': 'TEACHER_RELATION',
}
_EXPECTED_HELP = {
    'mentor_name': 'Mentor',
    'student_name': 'Student',
    'rule_title': 'Guide for My Class',
    'open_tips': 'Unlock when lv10 and there is a player in server over lv 60',
}
_EXPECTED_HELP_DIGEST = '2817d9051f3c72850935095fe003d08651796a11f1d8e431b23a31dea8f88371'


def help_digest(help_map):
    text = ''.join(f'{key}={help_map[key]}\n' for key in sorted(help_map))
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def catalog_digest(catalog):
    text = json.dumps(catalog, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def read_mentor_blobs(archive, error=None):
    """Return verified source blobs including teacher_mission.lua.

    teacher_mission.lua is not in the shared generator manifest, so this module
    pins its exact archive hash. The archive SHA itself is verified by the
    shared SourceArchive helper.
    """
    error = error or gen.CompileError
    archive = Path(archive)
    blobs = gen.SourceArchive(archive).read_verified()
    with zipfile.ZipFile(archive) as zf:
        member = gen.SOURCE_PREFIX + MENTOR_TEACHER_TABLE
        try:
            data = zf.read(member)
        except KeyError as exc:
            raise error(f'mentor source missing archive member {member}') from exc
    actual = hashlib.sha256(data).hexdigest()
    if actual != MENTOR_TEACHER_SHA256:
        raise error(
            f'mentor source SHA-256 mismatch for {MENTOR_TEACHER_TABLE}: '
            f'expected {MENTOR_TEACHER_SHA256}, got {actual}'
        )
    blobs[MENTOR_TEACHER_TABLE] = gen.SourceBlob(
        path=MENTOR_TEACHER_TABLE, sha256=actual, role=MENTOR_SOURCE_ROLE, data=data,
    )
    return blobs


def build_mentor(blobs, parse_table, error):
    try:
        return _compile_mentor(blobs, parse_table, error)
    except (KeyError, TypeError, AttributeError, ValueError) as exc:
        raise error(f'mentor source fields are missing or mistyped: {exc}') from exc


def _parse(blobs, path, parse_table, error):
    try:
        data = blobs[path].data
    except KeyError as exc:
        raise error(f'mentor source table missing: {path}') from exc
    try:
        return parse_table(data)
    except error:
        raise
    except Exception as exc:  # parser failures are source qualification failures
        raise error(f'mentor source parse failed for {path}: {exc}') from exc


def _integer(raw, label, error, minimum=None):
    try:
        value = int(raw)
    except (TypeError, ValueError, OverflowError) as exc:
        raise error(f'{label} is not an integer: {raw!r}') from exc
    if str(value) != str(raw).strip().lstrip('+'):
        raise error(f'{label} is not a canonical integer: {raw!r}')
    if value < _MIN_INT64 or value > _MAX_INT64:
        raise error(f'{label} overflows int64: {raw!r}')
    if minimum is not None and value < minimum:
        raise error(f'{label} must be at least {minimum}, got {value}')
    return value


def _index(rows, key, label, error):
    indexed = {}
    for row in rows:
        if not isinstance(row, dict) or key not in row:
            raise error(f'{label} row missing {key}')
        value = row[key]
        if value in indexed:
            raise error(f'{label} duplicate {key} {value}')
        indexed[value] = row
    return indexed


def _missions(rows, gift_ids, error):
    indexed = _index(rows, 'id', 'mission', error)
    if len(rows) != len(_EXPECTED_MISSION_IDS):
        raise error(f'mentor mission count drift: {len(rows)}')
    missions = []
    type_counts, category_counts = {}, {}
    for mission_id in _EXPECTED_MISSION_IDS:
        raw = indexed.get(str(mission_id))
        if raw is None:
            raise error(f'mentor mission missing id {mission_id}')
        if set(raw) != set(_EXPECTED_MISSION_KEYS):
            raise error(f'mentor mission {mission_id} unsupported fields: {sorted(raw)}')
        mission_type = _integer(raw['type'], f'mission {mission_id}.type', error, minimum=1)
        category = _integer(raw['category'], f'mission {mission_id}.category', error, minimum=1)
        gift_id = _integer(raw['gift'], f'mission {mission_id}.gift', error, minimum=1)
        if gift_id not in gift_ids:
            raise error(f'mentor mission {mission_id} references missing gift {gift_id}')
        if gift_id not in _EXPECTED_GIFT_IDS:
            raise error(f'mentor mission {mission_id} gift identity drift: {gift_id}')
        mission = dict(
            id=mission_id,
            desc=raw['desc'],
            type=mission_type,
            gift_id=gift_id,
            category=category,
            level=_integer(raw['lev'], f'mission {mission_id}.lev', error, minimum=0),
            condition=_integer(raw['condition'], f'mission {mission_id}.condition', error, minimum=0),
            extra_info=_integer(raw['extra_info'], f'mission {mission_id}.extra_info', error, minimum=0),
            refresh=_integer(raw['refresh'], f'mission {mission_id}.refresh', error, minimum=0),
            is_hide=_integer(raw['is_hide'], f'mission {mission_id}.is_hide', error, minimum=0),
        )
        if not isinstance(mission['desc'], str) or mission['desc'] == '':
            raise error(f'mentor mission {mission_id} has no description')
        if mission['refresh'] not in (0, 1) or mission['is_hide'] not in (0, 1):
            raise error(f'mentor mission {mission_id} has a non-boolean flag')
        if mission_type not in _EXPECTED_TYPE_COUNTS:
            raise error(f'mentor mission {mission_id} unsupported type {mission_type}')
        if (mission_type == 1 and category not in (1, 2, 3, 4)) or (mission_type == 2 and category not in (5, 6, 7)):
            raise error(f'mentor mission {mission_id} category {category} does not match type {mission_type}')
        type_counts[mission_type] = type_counts.get(mission_type, 0) + 1
        category_counts[category] = category_counts.get(category, 0) + 1
        missions.append(mission)
    if type_counts != _EXPECTED_TYPE_COUNTS or category_counts != _EXPECTED_CATEGORY_COUNTS:
        raise error(f'mentor mission type/category counts drift: {type_counts} {category_counts}')
    hidden = {mission['id']: mission for mission in missions if mission['is_hide'] == 1}
    if set(hidden) != set(_HIDDEN_MISSIONS):
        raise error(f'mentor hidden mission identities drift: {sorted(hidden)}')
    for mission_id, (raw_level, raw_condition) in _HIDDEN_MISSIONS.items():
        if str(hidden[mission_id]['level']) != raw_level or str(hidden[mission_id]['condition']) != raw_condition:
            raise error(f'mentor hidden mission {mission_id} raw definition drift')
    finish = next(mission for mission in missions if mission['id'] == _FINISH_MISSION_ID)
    if finish['type'] != 2 or finish['category'] != 7 or finish['is_hide'] != 0 or finish['level'] != 90:
        raise error('mentor finish mission definition drift')
    gifts = [mission['gift_id'] for mission in missions]
    if len(set(gifts)) != len(gifts):
        raise error('mentor missions duplicate a gift reference')
    return missions


def _rules(rows, error):
    values = _index(rows, 'key', 'misc', error)
    rules = {}
    for key, expected in _EXPECTED_RULES.items():
        raw = values.get(key)
        if raw is None:
            raise error(f'misc.lua missing {key}')
        actual = _integer(raw['value'], f'misc.lua {key}', error, minimum=0)
        if actual != expected:
            raise error(f'misc.lua {key} drift: expected {expected}, got {actual}')
        rules[key] = actual
    return dict(
        relation_daily=rules['teacher_relation_daily'],
        relation_max=rules['teacher_relation_max'],
        teacher_level=rules['teacher_lev'],
        relation_broken_seconds=rules['teacher_relation_broken'],
        relation_send_times=rules['teacher_relation_send_times'],
        relation_send_broken_seconds=rules['teacher_relation_send_broken'],
        terminate_time_limit_seconds=rules['teacher_terminate_time_limit'],
        finding_num=rules['teacher_finding_num'],
        student_level_limit=rules['student_lev_limit'],
        finding_range=rules['teacher_finding_range'],
        level_relation=rules['teacher_lev_relation'],
        gift_intimacy=rules['teacher_gift_intimacy'],
        player_open_level=rules['teacher_player_open_lev'],
        finish_mission_id=rules['teacher_finish_mission'],
        teacher_min_level=rules['teacher_min_level'],
    )


def _function(rows, error):
    indexed = _index(rows, 'id', 'function', error)
    raw = indexed.get('50')
    if raw is None:
        raise error('function.lua missing function 50')
    if set(raw) != set(_EXPECTED_FUNCTION_KEYS):
        raise error(f'function 50 unsupported fields: {sorted(raw)}')
    for key, expected in _EXPECTED_FUNCTION.items():
        if raw[key] != expected:
            raise error(f'function 50 {key} drift: expected {expected!r}, got {raw[key]!r}')
    return dict(
        id=50,
        name=raw['name'],
        level=raw['level'],
        condition=raw['condition'],
        icon=raw['icon'],
        level_tips=raw['level_tips'],
        is_on_levelup_wnd=raw['is_on_levelup_wnd'],
        open_control=raw['open_control'],
        tip=raw['tip'],
        is_function_show=raw['is_function_show'],
        fx_num=raw['fx_num'],
        function_pic=raw['function_pic'],
        function_desc=raw['function_desc'],
    )


def _help(rows, error):
    indexed = _index(rows, 'name', 'translation', error)
    help_map = {}
    for field, source_name in _HELP_SOURCE_KEYS.items():
        raw = indexed.get(source_name)
        if raw is None:
            raise error(f'translation.lua missing {source_name}')
        text = raw['translation']
        if not isinstance(text, str) or text == '':
            raise error(f'translation.lua {source_name} is empty or mistyped')
        help_map[field] = text
    for field, expected in _EXPECTED_HELP.items():
        if help_map[field] != expected:
            raise error(f'translation.lua {field} drift: expected {expected!r}, got {help_map[field]!r}')
    if help_digest(help_map) != _EXPECTED_HELP_DIGEST:
        raise error('translation.lua Mentor help strings drift from the pinned source set')
    return help_map


def _compile_mentor(blobs, parse_table, error):
    teacher_rows = _parse(blobs, MENTOR_TEACHER_TABLE, parse_table, error)
    misc_rows = _parse(blobs, 'data/tables/misc.lua', parse_table, error)
    function_rows = _parse(blobs, 'data/tables/function.lua', parse_table, error)
    translation_rows = _parse(blobs, 'data/tables/translation.lua', parse_table, error)
    gift_rows = _parse(blobs, 'data/tables/gift.lua', parse_table, error)
    gift_ids = {_integer(row['id'], 'gift.id', error, minimum=1) for row in gift_rows}
    missions = _missions(teacher_rows, gift_ids, error)
    return dict(
        schema_version=MENTOR_SCHEMA_VERSION,
        missions=missions,
        rules=_rules(misc_rows, error),
        function_50=_function(function_rows, error),
        help=_help(translation_rows, error),
        gifts=_gifts(gift_rows, missions, error),
        exam=_exam(blobs, parse_table, error),
    )


def _split_pipe(raw, error, label):
    raw = raw.strip()
    if raw == '':
        return []
    values = raw.split('|')
    return [_integer(value, label, error, minimum=1) for value in values]


def _gifts(rows, missions, error):
    indexed = _index(rows, 'id', 'gift', error)
    result = []
    for mission in missions:
        gift_id = mission['gift_id']
        raw = indexed.get(str(gift_id))
        if raw is None:
            raise error(f'gift {gift_id} missing')
        items = _split_pipe(raw['items'], error, f'gift {gift_id}.items')
        nums = _split_pipe(raw['item_nums'], error, f'gift {gift_id}.item_nums')
        if len(items) != len(nums) or not items:
            raise error(f'gift {gift_id} item/quantity mismatch')
        for key in ('mana', 'energy', 'vip_exp', 'arena_coin', 'march_coin', 'lucky_coin',
                    'friendship_coin', 'skin_fragment', 'equip', 'badge', 'soul', 'vip',
                    'ex_badge', 'skin_coin', 'spirit_energy', 'drops'):
            if raw[key].strip() not in ('', '0'):
                raise error(f'gift {gift_id} unexpected {key}={raw[key]!r}')
        result.append(dict(
            id=gift_id,
            crystal=_integer(raw['crystal'], f'gift {gift_id}.crystal', error, minimum=0),
            exp=_integer(raw['exp'], f'gift {gift_id}.exp', error, minimum=0),
            items=[dict(item_id=item, quantity=num) for item, num in zip(items, nums)],
        ))
    return result


def _exam(blobs, parse_table, error):
    campaigns = _index(_parse(blobs, 'data/tables/campaign.lua', parse_table, error), 'campaign_id', 'campaign', error)
    campaign = campaigns.get('22608')
    if campaign is None:
        raise error('campaign.lua missing 22608')
    display = sorted(_split_pipe(campaign['item_display'], error, 'campaign 22608.item_display'))
    drops = _parse(blobs, 'data/tables/campaign_dropbox.lua', parse_table, error)
    drop_items = sorted(
        _integer(row['item_id'], 'campaign_dropbox.item_id', error, minimum=1)
        for row in drops
        if row['dropbox_id'] == '9700001'
    )
    if display != drop_items:
        raise error('graduation exam drop mismatch')
    return dict(
        campaign_id=22608,
        mission_id=_FINISH_MISSION_ID,
        items=[dict(item_id=item, quantity=1) for item in drop_items],
    )
