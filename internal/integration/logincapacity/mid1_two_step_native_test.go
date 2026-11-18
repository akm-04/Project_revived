//go:build postgres

package logincapacity_test

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/compatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appcompat "gxb.local/backend/v2/internal/application/compat"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var twoStepSecret = []byte("c1-4-native-digest-and-bearer-secret")

var twoStepAt = time.Date(2026, 11, 15, 4, 0, 0, 0, time.UTC)

type twoStepClock struct{ at time.Time }

func (clock twoStepClock) Now(context.Context) (time.Time, error) { return clock.at, nil }

func twoStepPool(t *testing.T, maxConnections int32) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_MID1_TWO_STEP_DSN")
	if dsn == "" {
		t.Fatal("GXB_MID1_TWO_STEP_DSN is required")
	}
	p, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: maxConnections, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func twoStepUUID(t *testing.T, raw string) ids.UUID {
	t.Helper()
	id, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func twoStepOperation(t *testing.T, raw string) operation.Context {
	t.Helper()
	entropySeed := sha256.Sum256([]byte(raw))
	return operation.Context{ID: twoStepUUID(t, raw), StartedAt: twoStepAt, EntropySeed: entropySeed}
}

func twoStepExec(t *testing.T, p *postgres.Pool, statement string, arguments ...any) {
	t.Helper()
	if _, err := p.Raw().Exec(context.Background(), statement, arguments...); err != nil {
		t.Fatal(err)
	}
}

// twoStepAllocatePlayerID takes the next id from the logical server counter so a
// fixture never inserts an id an earlier package already used.
func twoStepAllocatePlayerID(t *testing.T, p *postgres.Pool, logicalServerID int32) identity.PlayerID {
	t.Helper()
	var playerID int64
	err := p.Raw().QueryRow(context.Background(), `UPDATE logical_servers SET next_player_id=next_player_id+1,state_version=state_version+1 WHERE logical_server_id=$1 AND next_player_id+1<=max_player_id RETURNING next_player_id-1`, logicalServerID).Scan(&playerID)
	if err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

func twoStepContentRevision(t *testing.T, p *postgres.Pool) string {
	t.Helper()
	revision, err := (contentstore.Store{Queryer: p}).ActiveRevision(context.Background(), p)
	if err != nil {
		t.Fatal(err)
	}
	return revision
}

type twoStepPlayer struct {
	playerID    identity.PlayerID
	accountUUID ids.UUID
	sessionUUID ids.UUID
	credentials appboot.AccountCredentials
	operation   operation.Context
}

// seedTwoStepPlayer writes only fixture state: an existing returned player with
// its account, session, credentials and directory profile.
func seedTwoStepPlayer(t *testing.T, p *postgres.Pool, playerID identity.PlayerID, accountUUID, sessionUUID ids.UUID, operationRaw string) twoStepPlayer {
	t.Helper()
	credentials := appboot.AccountCredentials{SID: "sid-" + sessionUUID.String(), LoginToken: "login-" + sessionUUID.String()}
	twoStepExec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, accountUUID.String(), accountUUID.String(), twoStepAt.Add(-48*time.Hour))
	twoStepExec(t, p, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version,first_entry_pending)VALUES($1,$2,1,$3,'c1-4-native',false)`, int64(playerID), accountUUID.String(), twoStepAt.Add(-48*time.Hour))
	twoStepExec(t, p, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, sessionUUID.String(), accountUUID.String(), twoStepAt.Add(-time.Hour))
	for index, credential := range []struct{ kind, label, raw string }{{"SID", "sid", credentials.SID}, {"LOGIN_TOKEN", "login_token", credentials.LoginToken}} {
		digest, err := identity.DigestCredential(twoStepSecret, credential.label, credential.raw)
		if err != nil {
			t.Fatal(err)
		}
		credentialID := twoStepUUID(t, fmt.Sprintf("00000000-0000-4000-8000-%012d", (int64(playerID)*10+int64(index))%1000000000000))
		twoStepExec(t, p, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,$5)`, credentialID.String(), sessionUUID.String(), credential.kind, digest[:], twoStepAt.Add(-time.Hour))
	}
	twoStepExec(t, p, `INSERT INTO player_directory_profiles(player_id,name,lev,vip,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id,state_version,created_at,updated_at)VALUES($1,'nexus',1,0,110001001,0,0,1,1,$2,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	twoStepExec(t, p, `INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'nexus',110001001,0,0,1,$2,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	twoStepExec(t, p, `INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,0,1,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	twoStepExec(t, p, `INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	twoStepExec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	return twoStepPlayer{playerID: playerID, accountUUID: accountUUID, sessionUUID: sessionUUID, credentials: credentials, operation: twoStepOperation(t, operationRaw)}
}

func seedTwoStepOwnerRoots(t *testing.T, p *postgres.Pool, playerID identity.PlayerID, revision string) {
	t.Helper()
	ctx := context.Background()
	bootstrapContext := logicalserver.BootstrapContext{PlayerID: playerID, LogicalServerID: 1, Operation: operation.Context{ID: twoStepUUID(t, "00000000-0000-4000-8000-000000000001"), StartedAt: twoStepAt}}
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	for _, contributor := range []appboot.CharacterBootstrapPersistenceContributor{
		librarystore.BootstrapContributor{},
		dormstore.BootstrapContributor{Revision: revision},
		coursestore.BootstrapContributor{Revision: revision},
		inscriptionstore.BootstrapContributor{Revision: revision},
		elementstore.BootstrapContributor{Revision: revision},
		spiritstore.BootstrapContributor{Revision: revision},
	} {
		if err := contributor.PersistCharacterBootstrap(ctx, transaction, bootstrapContext); err != nil {
			t.Fatalf("fixture owner root %s: %v", contributor.Name(), err)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func seedTwoStepRoster(t *testing.T, p *postgres.Pool, playerID identity.PlayerID, revision string, heroCount int) {
	t.Helper()
	bundle, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	twoStepExec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,$2,0,1,$3,$3)`, int64(playerID), heroCount+1, twoStepAt.Add(-time.Hour))
	transaction, err := p.Begin(context.Background(), tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(context.Background())
	if len(bundle.HeroCore.Templates) < heroCount {
		t.Fatalf("content has %d hero templates, %d required", len(bundle.HeroCore.Templates), heroCount)
	}
	for index := 0; index < heroCount; index++ {
		template := bundle.HeroCore.Templates[index]
		hero := character.Hero{PlayerID: playerID, PartnerID: int64(index + 1), TableID: template.TableID, OriginTableID: template.TableID, Star: template.InitialStar, Level: 1, Color: 1, CreationContentRevision: revision, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: twoStepAt.Add(-time.Hour), UpdatedAt: twoStepAt.Add(-time.Hour)}
		if err := (characterstore.Store{}).InsertHeroTx(context.Background(), transaction, hero); err != nil {
			t.Fatal(err)
		}
		if err := characterbirth.FreshHeroFacets().InitFreshHeroTx(context.Background(), transaction, hero.Ref(), twoStepAt.Add(-time.Hour)); err != nil {
			t.Fatal(err)
		}
	}
	if err := transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func seedTwoStepPet(t *testing.T, p *postgres.Pool, playerID identity.PlayerID, revision string) {
	t.Helper()
	bundle, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(bundle.PetCore.Templates) == 0 {
		t.Fatal("content has no pet templates")
	}
	template := bundle.PetCore.Templates[0]
	twoStepExec(t, p, `INSERT INTO player_pet_roots(player_id,next_pet_id,first_free_hatch_used,state_version,created_at,updated_at)VALUES($1,2,false,1,$2,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	transaction, err := p.Begin(context.Background(), tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(context.Background())
	pet := character.Pet{PlayerID: playerID, PetID: 1, TableID: template.TableID, OriginTableID: template.TableID, Star: template.InitialStar, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: revision, StateVersion: 1, CreatedAt: twoStepAt.Add(-time.Hour), UpdatedAt: twoStepAt.Add(-time.Hour)}
	if err := (characterstore.Store{}).InsertPetTx(context.Background(), transaction, pet); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func seedTwoStepGuild(t *testing.T, p *postgres.Pool, playerID identity.PlayerID) int64 {
	t.Helper()
	ctx := context.Background()
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	guilds := guildstore.Store{}
	serial, version, err := guilds.LockAllocatorTx(ctx, transaction, 1, twoStepAt)
	if err != nil {
		t.Fatal(err)
	}
	guildID := int64(1000000 + serial)
	record := guild.Guild{ID: guild.ID(guildID), LogicalServerID: 1, Name: "Nexus", Icon: 10001, ApplyType: guild.ApplyByApplication, MinAllowLevel: 1, PolicyRevision: "guild-v1", StateVersion: 1, CreatedAt: twoStepAt.Add(-time.Hour), UpdatedAt: twoStepAt.Add(-time.Hour)}
	if err := guilds.InsertGuildTx(ctx, transaction, record); err != nil {
		t.Fatal(err)
	}
	if err := guilds.AdvanceAllocatorTx(ctx, transaction, 1, serial, version, twoStepAt); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,1,$3,1,1,$3)`, int64(playerID), guildID, twoStepAt.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return guildID
}

// twoStepCanonicalGolden rewrites the fixture's allocated ids back to the ids
// frozen in the golden file so the comparison stays independent of the counter.
func twoStepCanonicalGolden(raw []byte, playerID identity.PlayerID, guildID int64) []byte {
	for _, replacement := range []struct{ from, to string }{
		{fmt.Sprintf(`"player_id": %d`, int64(playerID)), `"player_id": 140001`},
		{fmt.Sprintf(`"guild_leader": %d`, int64(playerID)), `"guild_leader": 140001`},
		{fmt.Sprintf(`"guild_id": %d`, guildID), `"guild_id": 1000001`},
	} {
		raw = []byte(strings.ReplaceAll(string(raw), replacement.from, replacement.to))
	}
	return raw
}

func seedTwoStepDorm(t *testing.T, p *postgres.Pool, playerID identity.PlayerID) {
	t.Helper()
	twoStepExec(t, p, `INSERT INTO player_dorm_glue_purchases(player_id,game_day,purchase_count,state_version,updated_at)VALUES($1,$2,2,1,$3)`, int64(playerID), twoStepAt.Unix()/86400, twoStepAt.Add(-time.Hour))
}

func seedTwoStepSavedPreset(t *testing.T, p *postgres.Pool, playerID identity.PlayerID) {
	t.Helper()
	twoStepExec(t, p, `INSERT INTO player_saved_preset_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, int64(playerID), twoStepAt.Add(-time.Hour))
	twoStepExec(t, p, `INSERT INTO player_saved_preset_lanes(player_id,lane_ordinal,name,pet_id)VALUES($1,1,'Lane',1)`, int64(playerID))
	twoStepExec(t, p, `INSERT INTO player_saved_preset_heroes(player_id,lane_ordinal,hero_ordinal,partner_id)VALUES($1,1,1,1)`, int64(playerID))
}

func twoStepContributors(p *postgres.Pool) []appboot.MID1DetailContributor {
	content := contentstore.Store{Queryer: p}
	return []appboot.MID1DetailContributor{
		appdorm.GlueBootstrap{Owner: dormstore.Store{}},
		guildprojection.BootstrapProjection{},
		guildprojection.TeaProjection{},
		characterstore.HeroBootstrapProjection{Content: content},
		characterstore.PetBootstrapProjection{Content: content},
		characterstore.SavedPresetBootstrapProjection{},
		appcompat.BootstrapProjection{Store: compatstore.Store{}},
	}
}

func twoStepService(t *testing.T, p *postgres.Pool, hooks tx.Hooks) i4store.BootstrapService {
	t.Helper()
	return i4store.BootstrapService{
		Runner:                  tx.Runner{DB: p, Hooks: hooks},
		Receipts:                kernelstore.Store{},
		ReceiptReader:           kernelstore.Reader{Queryer: p},
		DigestSecret:            twoStepSecret,
		BearerSecret:            twoStepSecret,
		DerivationKeyID:         "c1-4-native",
		BootstrapProfileVersion: "c1-4-native",
		LoginTime:               twoStepClock{at: twoStepAt},
		LoginReconcilers:        []appboot.CharacterLoginReconciler{i4store.PlayerLoginActivity{}},
		DetailContributors:      twoStepContributors(p),
	}
}

type twoStepReply struct {
	Token  string         `json:"token"`
	Region int32          `json:"region"`
	UID    string         `json:"uid"`
	IsNew  int64          `json:"is_new"`
	Detail map[string]any `json:"detail"`
}

func twoStepEncode(t *testing.T, result appboot.MID1Result) []byte {
	t.Helper()
	raw, err := json.MarshalIndent(twoStepReply{Token: result.Token, Region: result.Region, UID: string(result.UID), IsNew: result.IsNew, Detail: result.Detail}, "", " ")
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

// TestI9C14MID1TwoStepReplyMatchesPreSplitLogin builds a full login reply for a
// returned player who owns heroes, a pet, a guild, dorm facts and saved presets,
// and compares the two-step reply with the reply frozen before the split.
func TestI9C14MID1TwoStepReplyMatchesPreSplitLogin(t *testing.T) {
	p := twoStepPool(t, 8)
	revision := twoStepContentRevision(t, p)
	fixture := seedTwoStepPlayer(t, p, twoStepAllocatePlayerID(t, p, 1), twoStepUUID(t, "11111111-1111-4111-8111-111111111101"), twoStepUUID(t, "11111111-1111-4111-8111-111111111102"), "11111111-1111-4111-8111-111111111103")
	seedTwoStepOwnerRoots(t, p, fixture.playerID, revision)
	seedTwoStepRoster(t, p, fixture.playerID, revision, 60)
	seedTwoStepPet(t, p, fixture.playerID, revision)
	guildID := seedTwoStepGuild(t, p, fixture.playerID)
	seedTwoStepDorm(t, p, fixture.playerID)
	seedTwoStepSavedPreset(t, p, fixture.playerID)
	result, err := twoStepService(t, p, tx.NopHooks{}).MID1(context.Background(), appboot.RuntimeMID1Request{Credentials: fixture.credentials, Region: 1, Operation: fixture.operation})
	if err != nil {
		t.Fatal(err)
	}
	got := twoStepCanonicalGolden(twoStepEncode(t, result), fixture.playerID, guildID)
	goldenPath := filepath.Join("testdata", "mid1_two_step_reply_golden.json")
	if os.Getenv("GXB_MID1_GOLDEN_UPDATE") == "1" {
		if err := os.MkdirAll(filepath.Dir(goldenPath), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(goldenPath, append(got, '\n'), 0o644); err != nil {
			t.Fatal(err)
		}
		return
	}
	want, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(got)+"\n" != string(want) {
		t.Fatalf("MID1 two-step reply differs from the pre-split reply:\n got: %s\nwant: %s", got, want)
	}
}

// C4: a stored row can hold unsorted duplicate ids (R8 restore); MID 1 answers
// the sorted de-duplicated set from the compat owner and never fails.
func TestI9C14MID1ProjectsStoredMessagePushPreferences(t *testing.T) {
	p := twoStepPool(t, 8)
	revision := twoStepContentRevision(t, p)
	fixture := seedTwoStepPlayer(t, p, twoStepAllocatePlayerID(t, p, 1), twoStepUUID(t, "22222222-2222-4222-8222-222222222201"), twoStepUUID(t, "22222222-2222-4222-8222-222222222202"), "22222222-2222-4222-8222-222222222203")
	seedTwoStepOwnerRoots(t, p, fixture.playerID, revision)
	seedTwoStepRoster(t, p, fixture.playerID, revision, 1)
	seedTwoStepPet(t, p, fixture.playerID, revision)
	seedTwoStepSavedPreset(t, p, fixture.playerID)
	twoStepExec(t, p, `INSERT INTO player_compat_preferences(player_id,first_main_touch,message_push_ids,state_version,created_at,updated_at)VALUES($1,1,'{9,1,9}',4,$2,$2)`, int64(fixture.playerID), twoStepAt.Add(-time.Hour))

	result, err := twoStepService(t, p, tx.NopHooks{}).MID1(context.Background(), appboot.RuntimeMID1Request{Credentials: fixture.credentials, Region: 1, Operation: fixture.operation})
	if err != nil {
		t.Fatal(err)
	}
	record, ok := result.Detail["17"].(map[string]any)
	if !ok {
		t.Fatalf("MID 1 detail 17 = %#v", result.Detail["17"])
	}
	if record["first_main_touch"] != int64(1) {
		t.Fatalf("first_main_touch = %#v", record["first_main_touch"])
	}
	if !reflect.DeepEqual(record["message_pushes"], []int64{1, 9}) {
		t.Fatalf("message_pushes = %#v, want [1 9]", record["message_pushes"])
	}
}

type twoStepRetryCounter struct {
	mutex      sync.Mutex
	maxAttempt map[ids.UUID]int
	aborts     atomic.Int64
}

func (counter *twoStepRetryCounter) OnEvent(event tx.Event) {
	if event.SQLState == "40001" || event.SQLState == "40P01" {
		counter.aborts.Add(1)
	}
	if event.Attempt < 2 {
		return
	}
	counter.mutex.Lock()
	defer counter.mutex.Unlock()
	if event.Attempt > counter.maxAttempt[event.Operation.ID] {
		counter.maxAttempt[event.Operation.ID] = event.Attempt
	}
}

func (counter *twoStepRetryCounter) retries() int64 {
	counter.mutex.Lock()
	defer counter.mutex.Unlock()
	var total int64
	for _, attempt := range counter.maxAttempt {
		total += int64(attempt - 1)
	}
	return total
}

// TestI9C14MID1ThirtyConcurrentLoginsNoSerializationFailure runs thirty logins
// whose reply hydration reads a sixty-hero roster through the read-only step.
func TestI9C14MID1ThirtyConcurrentLoginsNoSerializationFailure(t *testing.T) {
	const logins = 30
	p := twoStepPool(t, 16)
	revision := twoStepContentRevision(t, p)
	fixtures := make([]twoStepPlayer, logins)
	for index := 0; index < logins; index++ {
		fixtures[index] = seedTwoStepPlayer(t, p, twoStepAllocatePlayerID(t, p, 1),
			twoStepUUID(t, fmt.Sprintf("22222222-2222-4222-8222-%012d", index+1)),
			twoStepUUID(t, fmt.Sprintf("22222222-2222-4222-8222-%012d", index+101)),
			fmt.Sprintf("22222222-2222-4222-8222-%012d", index+201))
		seedTwoStepOwnerRoots(t, p, fixtures[index].playerID, revision)
		seedTwoStepRoster(t, p, fixtures[index].playerID, revision, 60)
		seedTwoStepPet(t, p, fixtures[index].playerID, revision)
		seedTwoStepSavedPreset(t, p, fixtures[index].playerID)
	}
	counter := &twoStepRetryCounter{maxAttempt: map[ids.UUID]int{}}
	service := twoStepService(t, p, counter)
	var wait sync.WaitGroup
	start := make(chan struct{})
	failures := make(chan error, logins)
	for index := range fixtures {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			<-start
			_, err := service.MID1(context.Background(), appboot.RuntimeMID1Request{Credentials: fixtures[index].credentials, Region: 1, Operation: fixtures[index].operation})
			if err != nil {
				failures <- fmt.Errorf("login %d: %w", index, err)
			}
		}(index)
	}
	close(start)
	wait.Wait()
	close(failures)
	for err := range failures {
		if tx.IsDefiniteAbortError(err) {
			t.Errorf("serialization failure surfaced to caller: %v", err)
			continue
		}
		t.Error(err)
	}
	t.Logf("logins=%d retries=%d serialization_aborts=%d", logins, counter.retries(), counter.aborts.Load())
}

// TestI9C14MID1ReplayReturnsEqualReplyAndWritesNothing retries one committed
// login with the same operation and asserts an equal reply and no new state.
func TestI9C14MID1ReplayReturnsEqualReplyAndWritesNothing(t *testing.T) {
	p := twoStepPool(t, 8)
	revision := twoStepContentRevision(t, p)
	fixture := seedTwoStepPlayer(t, p, twoStepAllocatePlayerID(t, p, 1), twoStepUUID(t, "33333333-3333-4333-8333-333333333301"), twoStepUUID(t, "33333333-3333-4333-8333-333333333302"), "33333333-3333-4333-8333-333333333303")
	seedTwoStepOwnerRoots(t, p, fixture.playerID, revision)
	seedTwoStepRoster(t, p, fixture.playerID, revision, 60)
	seedTwoStepPet(t, p, fixture.playerID, revision)
	seedTwoStepSavedPreset(t, p, fixture.playerID)
	service := twoStepService(t, p, tx.NopHooks{})
	first, err := service.MID1(context.Background(), appboot.RuntimeMID1Request{Credentials: fixture.credentials, Region: 1, Operation: fixture.operation})
	if err != nil {
		t.Fatal(err)
	}
	counts := func() [4]int64 {
		var out [4]int64
		for index, query := range []struct {
			statement string
			argument  any
		}{
			{`SELECT count(*) FROM players WHERE player_id=$1`, int64(fixture.playerID)},
			{`SELECT count(*) FROM gameplay_contexts WHERE player_id=$1`, int64(fixture.playerID)},
			{`SELECT count(*) FROM gameplay_context_credentials c JOIN gameplay_contexts g ON g.context_id=c.context_id WHERE g.player_id=$1`, int64(fixture.playerID)},
			{`SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1`, fixture.sessionUUID.String()},
		} {
			if err := p.Raw().QueryRow(context.Background(), query.statement, query.argument).Scan(&out[index]); err != nil {
				t.Fatal(err)
			}
		}
		return out
	}
	before := counts()
	var stateVersion int64
	if err := p.Raw().QueryRow(context.Background(), `SELECT state_version FROM players WHERE player_id=$1`, int64(fixture.playerID)).Scan(&stateVersion); err != nil {
		t.Fatal(err)
	}
	second, err := service.MID1(context.Background(), appboot.RuntimeMID1Request{Credentials: fixture.credentials, Region: 1, Operation: fixture.operation})
	if err != nil {
		t.Fatal(err)
	}
	if string(twoStepEncode(t, first)) != string(twoStepEncode(t, second)) {
		t.Fatal("replayed MID1 reply differs")
	}
	if after := counts(); after != before {
		t.Fatalf("replay added rows: before=%v after=%v", before, after)
	}
	var replayStateVersion int64
	if err := p.Raw().QueryRow(context.Background(), `SELECT state_version FROM players WHERE player_id=$1`, int64(fixture.playerID)).Scan(&replayStateVersion); err != nil {
		t.Fatal(err)
	}
	if replayStateVersion != stateVersion {
		t.Fatalf("replay changed player state_version %d -> %d", stateVersion, replayStateVersion)
	}
}
