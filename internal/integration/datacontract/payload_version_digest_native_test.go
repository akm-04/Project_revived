//go:build postgres

package datacontract_test

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	inscription "gxb.local/backend/v2/internal/domain/inscription"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

// TestPayloadVersionKeepsWitnessDigests drives the R8-2b digest and lenient
// decode adapters themselves rather than a copy of their SQL: the rows are
// seeded on a database stopped at 00162, the adapters observe them, 00163 adds
// payload_version, and the same adapters must return byte-equal results.
func TestPayloadVersionKeepsWitnessDigests(t *testing.T) {
	base := os.Getenv("GXB_R8_MANIFEST_DSN")
	if base == "" {
		t.Fatal("required GXB_R8_MANIFEST_DSN for the maintenance database is missing")
	}
	dsn, cleanup := payloadDigestDisposableDatabase(t, base)
	t.Cleanup(cleanup)
	migrations := payloadDigestMigrationsRoot(t)
	payloadDigestRunTool(t, "goose", "-dir", migrations, "postgres", dsn, "up-to", "00162")

	fixture := payloadDigestNewFixture(t)
	ctx := context.Background()
	before := payloadDigestOpen(t, dsn)
	payloadDigestSeed(t, ctx, before, fixture)
	beforeObservation := payloadDigestObserve(t, ctx, before, fixture, fixture.missionRevisionBefore)
	before.Close()

	payloadDigestRunTool(t, "goose", "-dir", migrations, "postgres", dsn, "up")
	after := payloadDigestOpen(t, dsn)
	afterObservation := payloadDigestObserve(t, ctx, after, fixture, fixture.missionRevisionAfter)
	after.Close()

	if beforeObservation.receiptWitness != afterObservation.receiptWitness {
		t.Fatalf("gxb_operation_receipts witness changed by payload_version: before=%d/%s after=%d/%s",
			beforeObservation.receiptWitness.Count, hex.EncodeToString(beforeObservation.receiptWitness.Digest[:]),
			afterObservation.receiptWitness.Count, hex.EncodeToString(afterObservation.receiptWitness.Digest[:]))
	}
	payloadDigestCompare(t, "guild_invite_projection_sources payload set", beforeObservation.sourceSet, afterObservation.sourceSet)
	payloadDigestCompare(t, "social_guild_invite_invalidations/materializations payload set", beforeObservation.inboxSet, afterObservation.inboxSet)
	payloadDigestCompare(t, "mission definitions decoded values", beforeObservation.missions, afterObservation.missions)
	payloadDigestCompare(t, "course heroes decoded values", beforeObservation.courseHeroes, afterObservation.courseHeroes)
	payloadDigestCompare(t, "inscription heroes decoded values", beforeObservation.inscriptionHeroes, afterObservation.inscriptionHeroes)
	payloadDigestCompare(t, "library heroes decoded values", beforeObservation.libraryHeroes, afterObservation.libraryHeroes)
	payloadDigestCompare(t, "social gift claim decoded values", beforeObservation.giftClaim, afterObservation.giftClaim)
}

type payloadDigestObservation struct {
	receiptWitness    gi.SetWitness
	sourceSet         gi.OwnerPayloadSet
	inboxSet          gi.OwnerPayloadSet
	missions          []objective.MissionDefinition
	courseHeroes      []course.HeroRoot
	inscriptionHeroes []inscription.HeroRoot
	libraryHeroes     []library.HeroFacts
	giftClaim         sg.ClaimOperation
}

type payloadDigestFixture struct {
	missionRevisionBefore string
	missionRevisionAfter  string
	marker                gi.Marker
	receiptIDs            []ids.UUID
	claimID               ids.UUID
	playerID              identity.PlayerID
	logicalServerID       identity.LogicalServerID
}

func payloadDigestNewFixture(t *testing.T) payloadDigestFixture {
	t.Helper()
	revisionBefore := strings.Repeat("a", 64)
	revisionAfter := strings.Repeat("c", 64)
	coreRevision := strings.Repeat("b", 64)
	markerID := payloadDigestUUID(t)
	coreReceiptID := payloadDigestUUID(t)
	contextID := payloadDigestUUID(t)
	startedAt := time.Unix(1700000000, 123456000).UTC()
	references, err := policy.NewSet(
		policy.Ref{Name: "content", Version: revisionBefore},
		policy.Ref{Name: "guild-core", Version: coreRevision},
		policy.Ref{Name: "guild-invite", Version: gi.PolicyID},
	)
	if err != nil {
		t.Fatal(err)
	}
	marker := gi.Marker{
		Operation:         operation.Context{ID: markerID, StartedAt: startedAt, Policies: references},
		Kind:              gi.Join,
		GuildID:           1000001,
		Server:            1,
		Actor:             100001,
		Subject:           100002,
		ActorAccountUID:   "payload-digest-uid",
		EventID:           100,
		DecisionAt:        startedAt.Add(time.Minute).UTC(),
		MaxIssueSerial:    10,
		ContentRevision:   revisionBefore,
		GuildCoreRevision: coreRevision,
		PolicyID:          gi.PolicyID,
		Core: gi.CoreReceipt{
			ID:                  coreReceiptID,
			OwnerKind:           "guild",
			OwnerKey:            "1000001",
			Domain:              "guild",
			Operation:           "join_immediate",
			SemanticKey:         "payload-digest",
			Schema:              "gxb.i6c.guild.join_immediate.v2",
			OperationClass:      "I6C_GUILD",
			PolicyVersion:       coreRevision,
			ActorAccountUID:     "payload-digest-uid",
			ContextID:           contextID,
			OperationStartedAt:  startedAt,
			OperationPolicyRefs: references,
		},
	}
	if err := marker.Validate(); err != nil {
		t.Fatalf("marker fixture invalid: %v", err)
	}
	fixture := payloadDigestFixture{
		missionRevisionBefore: revisionBefore,
		missionRevisionAfter:  revisionAfter,
		marker:                marker,
		claimID:               payloadDigestUUID(t),
		playerID:              99999900001,
		logicalServerID:       999999,
	}
	for range 6 {
		fixture.receiptIDs = append(fixture.receiptIDs, payloadDigestUUID(t))
	}
	return fixture
}

func payloadDigestSeed(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	payloadDigestSeedIdentity(t, ctx, pool, fixture)
	for _, revision := range []string{fixture.missionRevisionBefore, fixture.missionRevisionAfter} {
		payloadDigestSeedRevision(t, ctx, pool, revision)
		payloadDigestSeedMissions(t, ctx, pool, revision)
	}
	payloadDigestSeedReceipts(t, ctx, pool, fixture)
	payloadDigestSeedInviteRows(t, ctx, pool, fixture)
	payloadDigestSeedHeroRows(t, ctx, pool, fixture)
	payloadDigestSeedGiftClaim(t, ctx, pool, fixture)
}

func payloadDigestSeedRevision(t *testing.T, ctx context.Context, pool *pg.Pool, revision string) {
	t.Helper()
	payloadDigestExec(t, ctx, pool, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
VALUES($1,decode($1,'hex'),1,'probe','probe',jsonb_build_object('revision_id',$1,'schema_version',1,'compiler_version','probe','parser_version','probe'))`, revision)
}

func payloadDigestSeedIdentity(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	payloadDigestExec(t, ctx, pool, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES($1,'payload-version-digest',NULL,false,false,false,99999925001,99999999999,1,now())`, int32(fixture.logicalServerID))
	payloadDigestExec(t, ctx, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777777','payload-version-digest','ACTIVE',now())`)
	payloadDigestExec(t, ctx, pool, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)
VALUES($1,'77777777-7777-4777-8777-777777777777',$2,now(),'payload-version-digest')`, int64(fixture.playerID), int32(fixture.logicalServerID))
	for index, playerID := range []int64{100001, 100002, 100003} {
		accountID := fmt.Sprintf("88888888-8888-4888-8888-%012d", index+1)
		payloadDigestExec(t, ctx, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now())`, accountID, "payload-version-guild-"+strconv.Itoa(index))
		payloadDigestExec(t, ctx, pool, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)
VALUES($1,$2,1,now(),'payload-version-digest')`, playerID, accountID)
	}
}

func payloadDigestSeedMissions(t *testing.T, ctx context.Context, pool *pg.Pool, revision string) {
	t.Helper()
	prerequisite, err := json.Marshal(objective.MissionPrerequisite{Gate: []int64{0}})
	if err != nil {
		t.Fatal(err)
	}
	source := grant.SourceIdentity{Domain: "mission", Operation: "payload-version-probe", BusinessKey: "payload-version-probe", Occurrence: "payload-version-probe", PolicyVersion: "I9_MISSIONS_V1"}
	reward, err := json.Marshal(grant.Plan{Source: source})
	if err != nil {
		t.Fatal(err)
	}
	presentation, err := json.Marshal(objective.MissionPresentation{Condition: 2, Parameters: []int64{1}, BaseReward: grant.Plan{Source: source}})
	if err != nil {
		t.Fatal(err)
	}
	arguments := make([]any, 0, 476*4)
	placeholders := make([]string, 0, 476)
	for index := int64(0); index < 476; index++ {
		first := index*4 + 2
		placeholders = append(placeholders, fmt.Sprintf("($1,'mission:2',2,$%d,'I9_MISSIONS_V1','HIGH_WATER','payload-version-probe',1,'LIFETIME',$%d::jsonb,$%d::jsonb,0,$%d::jsonb)", first, first+1, first+2, first+3))
		arguments = append(arguments, index+1, string(prerequisite), string(reward), string(presentation))
	}
	payloadDigestExec(t, ctx, pool, `INSERT INTO gxb_content_objective_definitions(revision_id,program_id,stock_family,objective_id,definition_revision,strategy,accepted_fact_kind,target,generation_kind,prerequisite_policy,reward_plan,huoyue,presentation) VALUES `+strings.Join(placeholders, ","), append([]any{revision}, arguments...)...)
}

func payloadDigestSeedReceipts(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	for index, receiptID := range fixture.receiptIDs {
		payloadDigestExec(t, ctx, pool, `INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at)
VALUES($1,'player',$2,'payload-digest','payload-digest','query',$3,decode(repeat($4,32),'hex'),'payload.digest.v1',$5::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`,
			receiptID.String(), "9999990000"+strconv.Itoa(index), "payload-digest-"+strconv.Itoa(index), []string{"aa", "ab", "ac", "ad", "ae", "af"}[index], `{"probe":`+strconv.Itoa(index)+`}`)
	}
}

func payloadDigestSeedInviteRows(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	sourceIDs := []ids.UUID{payloadDigestUUID(t), payloadDigestUUID(t)}
	for index, sourceID := range sourceIDs {
		payloadDigestExec(t, ctx, pool, `INSERT INTO guild_invite_projection_sources(source_id,guild_id,logical_server_id,recipient_player_id,inviter_player_id,invite_generation,source_payload,source_fingerprint,core_receipt_id,decision_at,expires_at,last_join_event_id)
VALUES($1,1000001,1,100002,100003,$2,$3::jsonb,repeat('cd',32),$4,'2026-01-01T00:00:00Z','2026-01-01T01:00:00Z',5)`,
			sourceID.String(), index+1, `{"Operation":{"ID":"`+sourceID.String()+`"},"Probe":`+strconv.Itoa(index)+`}`, fixture.receiptIDs[index].String())
	}
	payloadDigestExec(t, ctx, pool, `INSERT INTO social_guild_invite_invalidations(marker_id,source_id,source_serial,source_key,recipient_player_id,marker_fingerprint,source_fingerprint,receipt_id,notice_id,root_version,consumed,target_payload,decision_at)
VALUES($1,$2,1,'payload-digest','100002',repeat('ab',32),repeat('cd',32),$3,NULL,0,false,'{"probe":1}'::jsonb,'2026-01-01T00:00:00Z')`,
		fixture.marker.Operation.ID.String(), sourceIDs[0].String(), fixture.receiptIDs[2].String())
	payloadDigestExec(t, ctx, pool, `INSERT INTO social_guild_invite_invalidations(marker_id,source_id,source_serial,source_key,recipient_player_id,marker_fingerprint,source_fingerprint,receipt_id,notice_id,root_version,consumed,target_payload,decision_at)
VALUES($1,$2,2,'payload-digest','100002',repeat('ab',32),repeat('cd',32),$3,NULL,0,false,'{"probe":2}'::jsonb,'2026-01-01T00:00:00Z')`,
		fixture.marker.Operation.ID.String(), sourceIDs[1].String(), fixture.receiptIDs[3].String())
	payloadDigestExec(t, ctx, pool, `INSERT INTO social_guild_invite_materializations(source_id,recipient_player_id,source_fingerprint,receipt_id,state,notice_id,root_version,target_payload,decision_at)
VALUES($1,100002,repeat('cd',32),$2,'SUPPRESSED',NULL,0,'{"materialized":true}'::jsonb,'2026-01-01T00:00:00Z')`,
		sourceIDs[0].String(), fixture.receiptIDs[4].String())
}

func payloadDigestSeedHeroRows(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	player := int64(fixture.playerID)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_course_roots(player_id,state_version,creation_revision,facts,created_at,updated_at)
VALUES($1,1,$2,'{"probe":true}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player, fixture.missionRevisionBefore)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_course_heroes(player_id,partner_id,state_version,facts,created_at,updated_at)
VALUES($1,1,1,'{"probe":1}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),($1,2,1,'{"probe":2}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_inscription_roots(player_id,state_version,creation_revision,facts,created_at,updated_at)
VALUES($1,1,$2,'{"probe":true}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player, fixture.missionRevisionBefore)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_inscription_heroes(player_id,partner_id,state_version,facts,created_at,updated_at)
VALUES($1,1,1,'{"probe":1}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),($1,2,1,'{"probe":2}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_library_roots(player_id,state_version,special_claims,seed_policy_id,created_at,updated_at)
VALUES($1,1,'[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]'::jsonb,'LIBRARY_NEUTRAL_SEED_V1','2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player)
	payloadDigestExec(t, ctx, pool, `INSERT INTO player_library_heroes(player_id,partner_id,state_version,favor_degree,is_married,feed_attrs,collect_quality_stage,collect_star_stage,pending_candidate,seed_policy_id,created_at,updated_at)
VALUES($1,1,1,0,false,'[0,0,0,0,0,0]'::jsonb,0,0,NULL,'LIBRARY_NEUTRAL_SEED_V1','2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'),($1,2,1,0,false,'[0,0,0,0,0,0]'::jsonb,0,0,NULL,'LIBRARY_NEUTRAL_SEED_V1','2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, player)
}

func payloadDigestSeedGiftClaim(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture) {
	t.Helper()
	semanticResult, err := json.Marshal(sg.Result{NoticeIDs: nil, TransferIDs: nil, GrantReceiptID: "payload-digest-grant", Amount: 0, Revision: fixture.missionRevisionBefore})
	if err != nil {
		t.Fatal(err)
	}
	payloadDigestExec(t, ctx, pool, `INSERT INTO social_gift_claim_operations(operation_id,recipient_player_id,request_fingerprint,operation_started_at,decision_at,created_at,claim_day,claim_generation_id,content_revision,grant_receipt_id,semantic_result)
VALUES($1,$2,repeat('ab',32),'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z','2026-01-01T00:00:00Z','2026-01-01',NULL,$3,'payload-digest-grant',$4::jsonb)`,
		fixture.claimID.String(), int64(fixture.playerID), fixture.missionRevisionBefore, string(semanticResult))
}

func payloadDigestObserve(t *testing.T, ctx context.Context, pool *pg.Pool, fixture payloadDigestFixture, missionRevision string) payloadDigestObservation {
	t.Helper()
	var observation payloadDigestObservation
	var err error
	observation.receiptWitness, err = kernelstore.Store{}.GuildInviteReceiptSetWitnessTx(ctx, pool, fixture.receiptIDs)
	if err != nil {
		t.Fatalf("receipt witness: %v", err)
	}
	observation.sourceSet, err = guildinvitestore.Store{}.CoveredSourcePayloadsTx(ctx, pool, fixture.marker, 10)
	if err != nil {
		t.Fatalf("invite source payload set: %v", err)
	}
	observation.inboxSet, err = socialinboxstore.Store{}.ReadCoveredInvitePayloadsTx(ctx, pool, fixture.marker, 10)
	if err != nil {
		t.Fatalf("invite inbox payload set: %v", err)
	}
	observation.missions, err = contentstore.Store{Queryer: pool}.MissionDefinitionsTx(ctx, pool, missionRevision)
	if err != nil {
		t.Fatalf("mission definitions: %v", err)
	}
	observation.courseHeroes, err = coursestore.Store{Queryer: pool}.ListHeroesTx(ctx, pool, fixture.playerID)
	if err != nil {
		t.Fatalf("course heroes: %v", err)
	}
	observation.inscriptionHeroes, err = inscriptionstore.Store{Queryer: pool}.ListHeroesTx(ctx, pool, fixture.playerID)
	if err != nil {
		t.Fatalf("inscription heroes: %v", err)
	}
	observation.libraryHeroes, err = librarystore.Store{Queryer: pool}.ListHeroesTx(ctx, pool, fixture.playerID)
	if err != nil {
		t.Fatalf("library heroes: %v", err)
	}
	claim, found, err := socialgiftstore.Store{}.ReadClaim(ctx, pool, fixture.claimID)
	if err != nil {
		t.Fatalf("social gift claim: %v", err)
	}
	if !found {
		t.Fatal("social gift claim row not found")
	}
	observation.giftClaim = claim
	return observation
}

func payloadDigestCompare(t *testing.T, name string, before, after any) {
	t.Helper()
	if !reflect.DeepEqual(before, after) {
		t.Fatalf("%s changed by payload_version: before=%+v after=%+v", name, before, after)
	}
}

func payloadDigestOpen(t *testing.T, dsn string) *pg.Pool {
	t.Helper()
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 1, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	return pool
}

func payloadDigestExec(t *testing.T, ctx context.Context, pool *pg.Pool, statement string, arguments ...any) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
		t.Fatalf("seed %q: %v", statement, err)
	}
}

func payloadDigestDisposableDatabase(t *testing.T, baseDSN string) (string, func()) {
	t.Helper()
	base, err := url.Parse(baseDSN)
	if err != nil {
		t.Fatal(err)
	}
	name := "r8_payload_digest_" + strings.ReplaceAll(payloadDigestUUID(t).String(), "-", "")
	payloadDigestRunTool(t, "createdb", "--maintenance-db", baseDSN, name)
	target := *base
	target.Path = "/" + name
	return target.String(), func() {
		exec.Command("dropdb", "--force", "--maintenance-db", baseDSN, name).Run()
	}
}

func payloadDigestRunTool(t *testing.T, name string, arguments ...string) string {
	t.Helper()
	output, err := exec.Command(name, arguments...).CombinedOutput()
	if err != nil {
		t.Fatalf("%s %v: %v %s", name, arguments, err, output)
	}
	return string(output)
}

func payloadDigestMigrationsRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller unavailable")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "migrations"))
}

func payloadDigestUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}
