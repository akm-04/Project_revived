#!/usr/bin/env python3
from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def need(path,*tokens):
    p=ROOT/path
    if not p.exists(): errs.append(f'missing {path}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{path}: missing {t!r}')
    return s
app=need(Path('internal/application/bootstrap/persistence_contributor.go'),
    'type CharacterBootstrapPersistenceContributor interface','PersistCharacterBootstrap','ValidatePersistenceContributors','ApplyPersistenceContributors',
    'optional bootstrap persistence contributor')
detail=need(Path('internal/application/bootstrap/detail_contributor.go'),
    'Name() string','Claims() []string','ValidateDetailContributors','projectionClaimsOverlap','MID1 projection claim collision')
i4=need(Path('internal/adapters/postgres/i4store/bootstrap_runtime.go'),
    'PersistenceContributors []appboot.CharacterBootstrapPersistenceContributor','appboot.ApplyPersistenceContributors',
    'func applyMID1PlayerRoot','func applyMID1ContextPlan','func (s BootstrapService) projectMID1Detail')
i5=need(Path('internal/adapters/postgres/i5store/bootstrap_owner.go'),
    'type PlayerCoreBootstrapContributor struct{}','PersistCharacterBootstrap','INSERT INTO player_profiles','INSERT INTO player_progression',
    'INSERT INTO player_story_cursors','INSERT INTO player_guide_return_state')
proj=need(Path('internal/adapters/postgres/i5store/bootstrap_projection.go'),
    'func (BootstrapProjection) Name() string','func (BootstrapProjection) Claims() []string','core, err := loadPlayerCore')
main=need(Path('cmd/gxb-api/main_postgres.go'),'PersistenceContributors: []appboot.CharacterBootstrapPersistenceContributor{i5store.PlayerCoreBootstrapContributor{}', 'i5store.EconomyOwnerBootstrapContributor{')
# R2B contract: I4 store no longer writes I5 owner tables.
for table in ('player_profiles','player_progression','player_story_cursors','player_guide_return_state'):
    if re.search(rf'(?is)INSERT\s+INTO\s+{table}\b',i4): errs.append(f'RF-007 remains: i4store writes {table}')
# Ordering must be root -> owner contributors -> current projection -> context/receipt.
for token in ('applyMID1PlayerRoot(txctx','appboot.ApplyPersistenceContributors(txctx','s.projectMID1Detail(txctx','applyMID1ContextPlan(txctx'):
    if token not in i4: errs.append(f'MID1 flow missing {token}')
flow=i4[i4.find('if planned.PlayerCreated {', i4.find('stored MID1 receipt exists')):]
tokens=('applyMID1PlayerRoot(txctx','appboot.ApplyPersistenceContributors(txctx','s.projectMID1Detail(txctx','applyMID1ContextPlan(txctx')
pos=[flow.find(t) for t in tokens]
if min(pos)>=0 and not (pos[0] < pos[1] < pos[2] < pos[3]): errs.append(f'MID1 R2B ordering wrong: {pos}')
# Ownership contract should have no RF-007 known-open records now.
try: own=json.loads((ROOT/'docs/architecture/CANONICAL_TABLE_OWNERSHIP.json').read_text())
except Exception as e: own={}; errs.append(f'ownership contract unreadable: {e}')
if any(v.get('finding_id')=='RF-007' for v in own.get('known_open_violations',[])): errs.append('RF-007 still allow-listed in ownership contract')
# Core acceptance tests.
tests='\n'.join((ROOT/p).read_text(errors='replace') for p in [
    Path('internal/application/bootstrap/contributor_test.go'),Path('internal/adapters/postgres/i5store/bootstrap_owner_test.go')])
for name in ('TestProjectionClaimsRejectCollisions','TestPersistenceContributorsAreDeterministicAndRequired','TestPlayerCoreBootstrapContributorOwnsExactlyPlayerCoreTables','TestBootstrapProjectionClaimsAreStableAndUnique'):
    if name not in tests: errs.append('missing R2B test '+name)
if errs:
    print('R2B VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('R2B VALIDATION: PASS')
print('transaction-aware owner bootstrap, same-tx canonical projection, projection claims and RF-007 ownership closure verified structurally')
