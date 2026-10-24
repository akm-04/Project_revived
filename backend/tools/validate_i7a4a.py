#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, re, sys
R=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)

mig=R/'migrations/00033_i7a4a_social_foundation.sql'
req(mig.exists(),'missing canonical 00033 migration')
if mig.exists():
    s=mig.read_text()
    req(s.startswith('-- +goose Up\n'),'00033 missing leading Goose Up')
    req('-- +goose Down' not in s,'00033 contains forbidden Down')
    for x in ['player_social_roots','social_friendships','social_friend_requests','social_blocks','social_request_epochs','social_notices','social_notice_id_seq','player_directory_profiles_name_player_idx','name COLLATE "C",player_id']:
        req(x in s,f'00033 missing {x}')
    for x in ['INSERT INTO player_social_roots','INSERT INTO social_friendships','INSERT INTO social_friend_requests','INSERT INTO social_blocks','INSERT INTO social_request_epochs','INSERT INTO social_notices','UPDATE player_directory_profiles','DELETE FROM']:
        req(x not in s,f'00033 contains synthetic/backfill marker {x}')
    req('UNIQUE(name' not in s and 'CREATE UNIQUE INDEX player_directory_profiles_name' not in s,'00033 invents player-name uniqueness')
    lock=json.loads((R/'docs/architecture/CUMULATIVE_MIGRATION_LOCK.json').read_text())
    req(lock.get('highest_migration')==mig.name,'cumulative migration high-water is not 00033')
    req(lock.get('migrations',{}).get(mig.name)==hashlib.sha256(mig.read_bytes()).hexdigest(),'00033 cumulative migration hash drift')

own=json.loads((R/'docs/architecture/CANONICAL_TABLE_OWNERSHIP.json').read_text())['tables']
for name in ['player_social_roots','social_friendships','social_friend_requests','social_blocks','social_request_epochs']:
    e=own.get(name,{})
    req(e.get('owner')=='social-relation',f'{name} owner drift')
    req(e.get('allowed_read_paths')==['internal/adapters/postgres/socialrelationstore/'] and e.get('allowed_write_paths')==['internal/adapters/postgres/socialrelationstore/'],f'{name} path ownership drift')
e=own.get('social_notices',{})
req(e.get('owner')=='social-inbox','social_notices owner drift')
req(e.get('allowed_read_paths')==['internal/adapters/postgres/socialinboxstore/'] and e.get('allowed_write_paths')==['internal/adapters/postgres/socialinboxstore/'],'social_notices path ownership drift')

reader=(R/'internal/application/playerdirectory/reader.go').read_text()
for x in ['type DiscoveryReader interface','ProfilesByExactName','PlayerIDBounds','ProfilesAfter']:
    req(x in reader,f'I4 DiscoveryReader missing {x}')
for x in ['MID188','MID190','SOCIAL_REQUEST_DAY_V1']:
    req(x not in reader,f'I4 discovery port contains Social policy {x}')

i4=(R/'internal/adapters/postgres/i4store/directory_discovery.go').read_text()
req('player_directory_profiles' in i4 and 'name COLLATE "C" = $1 COLLATE "C"' in i4,'I4 exact-name owner query missing')
for x in ['social_friendships','social_friend_requests','social_blocks','social_notices','player_social_roots','ORDER BY random(']:
    req(x.lower() not in i4.lower(),f'I4 discovery contains foreign/Social marker {x}')

rel=(R/'internal/adapters/postgres/socialrelationstore/store.go').read_text().lower()
for x in ['player_social_roots','social_friendships','social_friend_requests','social_blocks','social_request_epochs']:
    req(x in rel,f'SocialRelation store missing {x}')
for x in ['player_directory_profiles','social_notices','player_social_presence','realtime_presence_leases']:
    req(x not in rel,f'SocialRelation foreign-owner SQL {x}')
inbox=(R/'internal/adapters/postgres/socialinboxstore/store.go').read_text().lower()
for x in ['social_notices','social_notice_id_seq']:
    req(x in inbox,f'SocialInbox store missing {x}')
for x in ['player_directory_profiles','social_friendships','social_friend_requests','social_blocks','social_request_epochs']:
    req(x not in inbox,f'SocialInbox foreign-owner SQL {x}')

main=(R/'cmd/gxb-api/main_postgres.go').read_text()
req('[]uint16{56, 1056, 176, 1302, 1344, 2754, 2784, 8193}' in main,'MID176 existing lobby facade drift')
for mid in [177,178,179,180,181,182,184,185,186,187,188,189,190]:
    req(re.search(rf'\b{mid}\b',main) is None,f'premature I7A-4A stock route {mid}')

if errs:
    print('I7A-4A VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('I7A-4A VALIDATION: PASS')
print('stock-invisible Social durable/I4 discovery foundation present; no Social facts backfilled and no Social routes activated')
