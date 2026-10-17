"""Narrow source VIP thresholds/caps; manual facts remain explicit preservation authority."""
def build_privilege(blobs,parse):
 rows=[dict(level=int(r['id']),charge=int(r['charge_req']),skill_cap=int(r['skill_max']))for r in parse(blobs['data/tables/vip.lua'].data)]
 rows.sort(key=lambda r:r['level'])
 if [r['level']for r in rows]!=list(range(16))or rows[0]['charge']!=0 or rows[0]['skill_cap']!=10:raise ValueError('VIP source profile drift')
 return dict(schema_version=1,policy_id='C4A_SRC64_VIP_THRESHOLDS_V1',rows=rows)
