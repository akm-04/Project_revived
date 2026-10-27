"""Current district Work Place source profile; private equations stay labelled."""
import hashlib
import json
import re
from fractions import Fraction
from pathlib import Path

POLICY = Path(__file__).resolve().parents[1] / 'docs/i9/I9_WORKPLACE_PRIVATE_POLICY_V1.json'


def build_workplace(blobs, parse, indexed, field, resources):
    def table(name):
        raw = blobs['data/tables/' + name + '.lua'].data
        if name == 'treasure_type':
            text = raw.decode('utf-8-sig')
            match = re.search(r'keys\s*=\s*\{([^}]+)\}', text)
            if not match or re.findall(r'"([^"]*)"', match[1]) != ['id','name','note','product_type','chest','chest_num','req_type','req','','','','','']:
                raise ValueError('Workplace source type header drift')
            index = iter(range(5))
            keys = re.sub(r'""', lambda m: '"_unused_%d"' % next(index), match[0])
            raw = (text[:match.start()] + keys + text[match.end():]).encode()
        return parse(raw)
    misc = {r['key']: r['value'] for r in table('misc')}
    ratio = lambda v: dict(numerator=Fraction(v).numerator, denominator=Fraction(v).denominator)
    locations = [dict(id=int(r['id']), jobs=[int(x) for x in r['treasure_type'].split('|')], max_members=int(r['max_member']), base_time=int(r['base_time']), base_ice=int(r['base_ice']), chest_rate=int(r['chest_rate']), enemy_rate=int(r['enemy_rate'])) for r in table('treasure_location')]
    jobs = [dict(id=int(r['id']), product=int(r['product_type']), chests=[[int(i),int(n)] for i,n in zip(r['chest'].split('|'),r['chest_num'].split('|')) if int(i)], require_type=int(r['req_type']), require=int(r['req'])) for r in table('treasure_type')]
    crew, scrolls = [], []
    for name in ['partner','super_partner']:
        keys, rows = indexed(blobs['data/tables/' + name + '.lua'].data)
        for key, vals in rows.items():
            f = lambda n: field(keys, vals, n, row_id=key)
            if int(f('first_table_id') or 0) or not int(f('treasure_location') or 0):
                continue
            crew.append(dict(base_id=int(f('id')), location=int(f('treasure_location')), trait=int(f('treasure_skill'))))
            if name != 'partner' or f('is_sx') != '1':
                scrolls.append(int(f('stone_id')))
    traits = {int(r['id']):int(r['num']) for r in table('treasure_skill')}
    items = {r['item_id'] for r in resources if r['class']=='STACK_ITEM' and r['settlement_activation']=='ENABLED_R4'}
    glue = int(misc['event_centre_accelerate_item'])
    item_products = {2:50001002, 6:glue, 7:int(misc['treasure_inscript_item1']), 8:int(misc['treasure_inscript_item2']), 9:int(misc['treasure_inscript_item3'])}
    used = {i for job in jobs for i,n in job['chests']} | set(scrolls) | set(item_products.values())
    if not used <= items or len(locations)!=6 or len(jobs)!=35 or len(crew)!=114 or len(scrolls)!=109 or traits!={1:1,2:3,3:1800,4:5}:
        raise ValueError('Workplace source membership/reward profile drift')
    if (misc['treasure_sp_interval'],misc['treasure_sp_limit']) != ('1200','50'):
        raise ValueError('Workplace SP profile drift')
    formula = dict(base=int(misc['treasure_gold_param1']), per_girl=int(misc['treasure_gold_param2']), color=int(misc['treasure_color_param']), star=int(misc['treasure_star_param']), level=int(misc['treasure_level_param']), trait_amounts=traits, products={1:ratio('1'),2:ratio(misc['treasure_exp_param']),3:ratio(Fraction(misc['treasure_scroll_param'])/100000),4:ratio(misc['treasure_magic_dust_param']),5:ratio(misc['treasure_magic_liquid_param']),6:ratio(Fraction(misc['treasure_glue_param'])/100000),7:ratio(Fraction(misc['treasure_inscript_param'])/100000),8:ratio(Fraction(misc['treasure_inscript_param'])/100000),9:ratio(Fraction(misc['treasure_inscript_param'])/100000)})
    policy_raw = POLICY.read_bytes()
    policy = json.loads(policy_raw)
    return dict(schema_version=1, contract_id='I9_WORKPLACE_V1', policy_id=policy['contract_id'], policy_sha256=hashlib.sha256(policy_raw).hexdigest(), source_sha256={n:hashlib.sha256(blobs['data/tables/'+n+'.lua'].data).hexdigest() for n in ['treasure_location','treasure_type','treasure_skill','misc','vip','partner','super_partner']}, locations=locations,jobs=jobs,crew=sorted(crew,key=lambda r:r['base_id']),scrolls=sorted(scrolls),item_products=item_products,formula=formula,vip=[ratio(r['tresure_reward']) for r in table('vip')],policy=policy['parameters'])
