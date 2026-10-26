"""Source monthly calendars selected by the already-approved D89 policy."""
import calendar


def build_signin(blobs, parse):
    rows = parse(blobs['data/tables/sign_in.lua'].data)
    partners = parse(blobs['data/tables/sign_in_partner.lua'].data)
    seen = {}
    for row in rows:
        key = int(row['sign_in_id'])
        if key in seen and seen[key] != row:
            raise ValueError('Conflicting sign-in date')
        seen[key] = row
    months = []
    for month in range(1, 13):
        year = max(int(row['year']) for row in seen.values() if int(row['month']) == month)
        selected = sorted((row for row in seen.values() if int(row['year']) == year and int(row['month']) == month), key=lambda row: int(row['time']))
        if [int(row['time']) for row in selected] != list(range(1, calendar.monthrange(year, month)[1] + 1)):
            raise ValueError('Noncontiguous monthly sign-in calendar')
        partner = [row for row in partners if int(row['year']) == year and int(row['month']) == month]
        if len(partner) != 1:
            raise ValueError('Missing/ambiguous sign-in partner')
        awards = []
        for row in selected:
            award = {key: int(row[key]) for key in ('award_item_id', 'award_item_num', 'award_crystal', 'double_vip_lv')}
            if not -1 <= award['double_vip_lv'] <= 15 or (award['award_item_id'] > 0) == (award['award_crystal'] > 0) or award['award_item_id'] > 0 and award['award_item_num'] <= 0:
                raise ValueError('Invalid sign-in award')
            awards.append(award)
        months.append(dict(source_year=year, month=month, partner_id=int(partner[0]['partner_id']), is_skin=int(partner[0]['is_skin']), awards=awards))
    return dict(months=months)
