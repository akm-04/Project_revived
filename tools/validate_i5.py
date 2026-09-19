#!/usr/bin/env python3
from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
errs=[]

def need(path,*tokens):
    p=root/path
    if not p.exists(): errs.append(f'missing {path}'); return
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{path}: missing {t}')

need(Path('migrations/00005_i5_player_economy_mail_objective_redeem.sql'),
     '-- +goose Up','CREATE TABLE player_profiles','CREATE TABLE player_progression',
     'CREATE TABLE player_story_cursors','CREATE TABLE player_function_unlocks',
     'CREATE TABLE player_guide_return_state','CREATE TABLE player_currency_balances',
     'CREATE TABLE player_temporal_resources','CREATE TABLE player_item_stacks',
     'CREATE TABLE mail_records','CREATE TABLE mail_attachments',
     'CREATE TABLE player_mission_instances','CREATE TABLE redeem_campaigns',
     'CREATE TABLE redeem_codes','CREATE TABLE redeem_redemptions')
need(Path('internal/domain/player/core.go'),'GuideEndID int64 = 100197','CompatibilityBootstrap','MID17OwnedFields','SaveStory')
need(Path('internal/domain/economy/resources.go'),'ScalarWallet','TemporalResource','StackItem','OverflowToMail','Materialize')
need(Path('internal/domain/grant/plan.go'),'SourceIdentity','ReceiptIdentity','OverflowMailSourceKey')
need(Path('internal/domain/mail/mail.go'),'func (n Namespace) WireIsRegion() (bool, error)','BatchSemanticKey','ParseMID370')
need(Path('internal/domain/objective/objective.go'),'ObjectiveFact' if False else 'type Fact struct','CommittedDeltaFact','func ApplyFact','func Claim')
need(Path('internal/domain/redeem/redeem.go'),'StockFunctionLevel int64 = 10','LookupDigest','func Eligible')
for q,owner in [('player_core.sql','player-core'),('economy.sql','typed-economy'),('mail.sql','mail'),('objective.sql','objective-core'),('redeem.sql','redeem')]:
    need(Path('sql/i5')/q,f'-- owner: {owner}')
need(Path('testdata/sourcefacts/pass446_i5_player_core.json'),'ExchangeCodeWindow.lua','Mailbox.lua','historical mail/overflow expiry and purge duration')
need(Path('tools/check_i5_oracle_player_core.py'),'I5 ORACLE PLAYER-CORE CHECK: PASS')


# I5-B/I5 complete transaction/service closure.
need(Path('migrations/00006_i5_transactional_policies.sql'),
     '-- +goose Up','CREATE TABLE i5_resource_registry','CREATE TABLE objective_definitions',
     'redeem_stock_slot_positive')
need(Path('internal/application/i5/service.go'),
     'func (s Service) SettleGrant','receipt.Resolver','FenceActorTx',
     'func (s Service) ClaimMail','func (s Service) ClaimMailBatch',
     'func (s Service) ApplyObjectiveFactTx','func (s Service) Redeem',
     'func (s Service) AdminGrant','func (s Service) AdminSendMail','AdminOperator',
     'func StockBulkAwards','func StockMID369Rewards')
need(Path('internal/application/i5/ports.go'),'type Store interface','LockRedeemByDigestTx','LockObjectiveForClaimTx')
need(Path('internal/adapters/postgres/i5store/store.go'),
     'FOR SHARE OF gc,s,a','i5_resource_registry','FOR UPDATE',
     'func (Store) SaveMailStateTx','func (Store) AdvanceRedeemCodeTx')
need(Path('internal/adapters/stockruntime/i5_dispatcher.go'),
     'case 26:','case 161:','case 230:','case 368:','case 369:','case 370:','case 2736:',
     'stockMailNamespace','StockRepresentableBulkAwards','applySettlementProjection')
need(Path('internal/application/bootstrap/detail_contributor.go'),'type MID1DetailContributor interface','OverlayMID1')
need(Path('internal/adapters/postgres/i5store/bootstrap_projection.go'),'OverlayMID1','player_profiles','player_progression')
need(Path('cmd/gxb-api/main_postgres.go'),'GXB_REDEEM_DIGEST_SECRET','i5store.Store','appi5.Service','I5Dispatcher','[]uint16{26, 81, 161, 230, 368, 369, 370, 2736}')
need(Path('internal/application/i5/service_test.go'),
     'TestSettleGrantSemanticReplayCreditsExactlyOnce',
     'TestSettleGrantAmbiguousCommitReconcilesWithoutReplay',
     'TestSettleGrantRejectsUnimplementedOwnerWithoutMutation',
     'TestStackOverflowCreatesDurableMailAndOnlyFitsCanonicalStack',
     'TestMailClaimRefusesRecursiveOverflowAndLeavesMailUnclaimed',
     'TestObjectiveFactReceiptPreventsDoubleProgress','TestObjectiveClaimReplayGrantsOnce',
     'TestAdminGrantUsesCanonicalGrantWithoutGameplayFenceAndAudits','TestAdminSendMailUsesMailOwnerAndSemanticReplay')
need(Path('internal/adapters/stockruntime/i5_dispatcher_test.go'),
     'TestI5MID369PreservesFalseNormalNamespaceAndNamedReward',
     'TestI5MID370CanonicalizesCompoundAddressSetAndNumericAwards')
need(Path('docs/PASS447_I5_WAVE_E_EXECUTION_MAP.json'),'E-PG-01','E-OP-01','E-S3-02','DEFERRED_W2')

mig=(root/'migrations/00005_i5_player_economy_mail_objective_redeem.sql').read_text()
for bad in ['CREATE TABLE grant_records','CREATE TABLE universal_wallet','CREATE TABLE player_blob']:
    if bad.lower() in mig.lower(): errs.append(f'I5 forbidden schema/policy: {bad}')
for mp in [root/'migrations/00005_i5_player_economy_mail_objective_redeem.sql', root/'migrations/00006_i5_transactional_policies.sql']:
    if '-- +goose Down' in mp.read_text(): errs.append(f'{mp.relative_to(root)} violates forward-only production migration law')
# Frozen Pass414/415 ownership truth: I5 canonical bootstrap state must not be
# implemented by leaking I5 table mutations into the I4 PostgreSQL adapter.
# Required source-driven economy/temporal bootstrap is ALLOWED and REQUIRED;
# R0 intentionally reports its absence until R2/R5 supplies the owner seam.
boot=(root/'internal/adapters/postgres/i4store/bootstrap_runtime.go').read_text()
for table in ['player_profiles','player_progression','player_story_cursors','player_guide_return_state',
              'player_currency_balances','player_temporal_resources','player_item_stacks']:
    if re.search(rf'(?is)INSERT\s+INTO\s+{table}\b', boot):
        errs.append(f'RF-007 cross-owner bootstrap write remains in i4store: {table}')
# Design contract requires an EconomyBootstrapContributor for source-required
# regenerative state; absence is an implementation defect, not a reason to ban
# temporal INSERTs. Keep this contract-oriented check red until repaired.
bootstrap_sources=[]
for candidate in [root/'internal/application/bootstrap', root/'internal/application/i5', root/'internal/adapters/postgres/i5store']:
    if candidate.exists():
        for fp in candidate.rglob('*.go'):
            bootstrap_sources.append(fp.read_text(errors='replace'))
joined_boot='\n'.join(bootstrap_sources)
if 'EconomyOwnerBootstrapContributor' not in joined_boot:
    errs.append('RF-015 required EconomyOwnerBootstrapContributor production seam missing')
if not re.search(r'(?is)INSERT\s+INTO\s+player_temporal_resources\b', joined_boot):
    errs.append('RF-015 required temporal-resource bootstrap persistence path missing')
# Redeem must not own Commerce.
for p in [root/'internal/domain/redeem/redeem.go',root/'internal/application/i5/service.go',root/'sql/i5/redeem.sql',root/'migrations/00005_i5_player_economy_mail_objective_redeem.sql']:
    txt=p.read_text()
    # migration comments may name Commerce to explain separation; reject actual commerce identifiers/imports only.
    if re.search(r'(?i)\b(?:commerce_orders|shop_orders|vip_purchases)\b',txt): errs.append(f'{p.relative_to(root)} references Commerce authority')
# No numeric is_region sentinel in Mail domain.
mail=(root/'internal/domain/mail/mail.go').read_text()
if re.search(r'"is_region"\s*:\s*(?:int64\()?0',mail): errs.append('Mail projection regressed normal namespace to numeric 0')
# I5 SQL must be configured as external sqlc output.
sqlc=(root/'sqlc.yaml').read_text()
if 'queries: "sql/i5"' not in sqlc or 'out: "../gxb-v2-sqlc-generated/i5db"' not in sqlc:
    errs.append('I5 owner-scoped sqlc configuration missing')

if errs:
    print('I5 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('I5 VALIDATION: PASS')
