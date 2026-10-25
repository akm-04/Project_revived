// Package provision stands in for the stock login SDK: it creates the live account session whose sid and login_token the SDK would hand the client.
package provision

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	campaign "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Session is one SDK login: the raw credentials stock LoadingScene receives from xydNewLogin.
type Session struct {
	AccountID  string
	SID        string
	LoginToken string
}

// Account inserts a fresh ACTIVE account with a SID_LOGIN_TOKEN_PAIR session, as the I7C2J API test provisions one.
// digestSecret must be the backend's GXB_CREDENTIAL_DIGEST_SECRET.
func Account(context context.Context, databaseURL string, digestSecret []byte) (Session, error) {
	account, err := ids.NewUUID()
	if err != nil {
		return Session{}, err
	}
	session, err := ids.NewUUID()
	if err != nil {
		return Session{}, err
	}
	result := Session{AccountID: account.String(), SID: "vc-sid-" + session.String(), LoginToken: "vc-login-" + session.String()}
	connection, err := pgx.Connect(context, databaseURL)
	if err != nil {
		return Session{}, err
	}
	defer connection.Close(context)
	transaction, err := connection.Begin(context)
	if err != nil {
		return Session{}, err
	}
	defer transaction.Rollback(context)
	if _, err := transaction.Exec(context, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		return Session{}, fmt.Errorf("account: %w", err)
	}
	if _, err := transaction.Exec(context, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp(),clock_timestamp())`, session.String(), account.String(), string(identity.AuthProductionPair)); err != nil {
		return Session{}, fmt.Errorf("session: %w", err)
	}
	credentials := []struct{ kind, label, raw string }{{"SID", "sid", result.SID}, {"LOGIN_TOKEN", "login_token", result.LoginToken}}
	for _, credential := range credentials {
		digest, err := identity.DigestCredential(digestSecret, credential.label, credential.raw)
		if err != nil {
			return Session{}, err
		}
		credentialID, err := ids.NewUUID()
		if err != nil {
			return Session{}, err
		}
		if _, err := transaction.Exec(context, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,clock_timestamp())`, credentialID.String(), session.String(), credential.kind, digest[:]); err != nil {
			return Session{}, fmt.Errorf("credential %s: %w", credential.kind, err)
		}
	}
	return result, transaction.Commit(context)
}

// Summon is one stone summon (stock MID59 STONE_SUMMON_HERO) the stock client makes itself once Progress granted its fragments.
type Summon struct {
	TableID  int64 `json:"table_id"`
	Stone    int64 `json:"stone"`
	StoneNum int64 `json:"stone_num"`
}

// provisionOperator is the audited admin identity the virtual client grants under (D88): progression goes through the
// production I5 owner, so level-ups, function openings and their effects are the ones a real player gets.
var provisionOperator = appi5.AdminOperator{ID: "virtual-client-provision", ReasonCode: "vc-scenario-progress"}

// Progress raises the player stock MID1 birthed for the account through production owners (I9_MODE_FOUNDATION_V1 MF7): one
// i5 AdminGrant carries the PLAYER_EXP to the scenario level and the fragments and mana of every summon. Heroes are not
// inserted: the returned summons are for the stock client to make through MID59, so the production birth runs.
func Progress(context context.Context, databaseURL, accountID string, level int64, tables []int64, challengeFixture bool) ([]Summon, error) {
	if challengeFixture && level < 80 {
		return nil, fmt.Errorf("Challenge fixture requires level >=80")
	}
	pool, err := postgres.Open(context, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-virtual-client-provision"})
	if err != nil {
		return nil, err
	}
	defer pool.Close()
	var playerID int64
	if err := pool.QueryRow(context, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&playerID); err != nil {
		return nil, fmt.Errorf("born player: %w", err)
	}
	content := contentstore.Store{Queryer: pool}
	revision, err := content.ActiveRevision(context, pool)
	if err != nil {
		return nil, err
	}
	var lines []grant.Line
	if level > 1 {
		exp, err := missingExp(context, pool, content, revision, identity.PlayerID(playerID), level)
		if err != nil {
			return nil, err
		}
		lines = append(lines, grant.Line{Kind: grant.PlayerExp, Amount: exp})
	}
	var summons []Summon
	var mana int64
	for _, table := range tables {
		policy, err := content.HeroNormalSummonTx(context, pool, revision, table)
		if err != nil {
			return nil, fmt.Errorf("summon policy %d: %w", table, err)
		}
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: policy.Template.FragmentItemID, Amount: policy.FragmentCount})
		mana += policy.Mana
		summons = append(summons, Summon{TableID: table, Stone: policy.Template.FragmentItemID, StoneNum: policy.FragmentCount})
	}
	if mana > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: mana})
	}
	if err := grantLines(context, pool, revision, identity.PlayerID(playerID), lines); err != nil {
		return nil, err
	}
	if challengeFixture {
		if err := seedChallengeFixture(context, pool, content, revision, identity.PlayerID(playerID)); err != nil {
			return nil, err
		}
	}
	if level > 0 {
		return summons, openDeferredFunctionFixtures(context, pool, content, revision, playerID, level)
	}
	return summons, nil
}

// missingExp is the PLAYER_EXP that takes the player from its current cumulative exp to the start of level.
func missingExp(context context.Context, pool *postgres.Pool, content contentstore.Store, revision string, playerID identity.PlayerID, level int64) (int64, error) {
	rule, err := content.ResolveProgressionPolicyTx(context, pool, revision)
	if err != nil {
		return 0, err
	}
	if level < 2 || int(level-2) >= len(rule.Rows) {
		return 0, fmt.Errorf("level %d outside the progression table", level)
	}
	current, err := (i5store.Store{}).ReadProgressionTx(context, pool, playerID)
	if err != nil {
		return 0, err
	}
	return rule.Rows[level-2].TotalExp - current.Exp, nil
}

func grantLines(context context.Context, pool *postgres.Pool, revision string, playerID identity.PlayerID, lines []grant.Line) error {
	if len(lines) == 0 {
		return nil
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		return err
	}
	request, err := (operation.Factory{Clock: clock.System{}}).New(policies)
	if err != nil {
		return err
	}
	content := contentstore.Store{Queryer: pool}
	store := i5store.Store{Queryer: pool}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}
	owner := appi5.Service{Runner: tx.Runner{DB: pool}, Store: store, Content: content, Privileges: privileges, Functions: appi5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: store, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}, Audit: audit.NopEmitter{}}
	commandKey := fmt.Sprintf("player-%d-%s", playerID, request.ID)
	if _, err := owner.AdminGrant(context, provisionOperator, playerID, commandKey, "vc-provision-v1", lines, request); err != nil {
		return fmt.Errorf("admin grant: %w", err)
	}
	return nil
}

// completeTutorials opens only kind 6/7 level-gate fixtures.
// shortcut: kind 6/7 gates have no qualified eligibility owner until I9-7; this is not tutorial proof.
func openDeferredFunctionFixtures(context context.Context, pool *postgres.Pool, content contentstore.Store, revision string, playerID, level int64) error {
	policy, err := content.ResolveFunctionGatePolicyTx(context, pool, revision)
	if err != nil {
		return err
	}
	transaction, err := pool.Begin(context, tx.Options{})
	if err != nil {
		return err
	}
	defer transaction.Rollback(context)
	for _, gate := range policy.Gates {
		openLevel, readable := stockOpenLevel(gate.RawOpenValue)
		if gate.GateKind == "PURE_LEVEL" || !readable || openLevel > level || gate.AnnouncementCapability != "NONE" {
			continue
		}
		if _, err := transaction.Exec(context, `INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version)
			VALUES($1,$2,clock_timestamp(),$3,1) ON CONFLICT(player_id,function_id) DO NOTHING`, playerID, gate.FunctionID, "vc:provision:function:"+gate.SourceFactKey); err != nil {
			return fmt.Errorf("function %d unlock: %w", gate.FunctionID, err)
		}
	}
	return transaction.Commit(context)
}

// stockOpenLevel is the level stock FunctionOpenTable reads from a function.lua "kind|value[|...]" gate: kinds 1, 6 and 7 are
// level gates; stage (2), VIP (3) and the rest are not.
func stockOpenLevel(raw string) (int64, bool) {
	fields := strings.Split(raw, "|")
	if len(fields) < 2 || (fields[0] != "1" && fields[0] != "6" && fields[0] != "7") {
		return 0, false
	}
	level, err := strconv.ParseInt(fields[1], 10, 64)
	return level, err == nil
}

// Configure grants scenario resources and imports VIP through the production owners (D88), after stock birth.
func Configure(ctx context.Context, databaseURL, accountID string, vip int64, lines []grant.Line) error {
	if vip == 0 && len(lines) == 0 {
		return nil
	}
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-configure"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var pid, server int64
	if err = pool.QueryRow(ctx, `SELECT player_id,logical_server_id FROM players WHERE account_id=$1`, accountID).Scan(&pid, &server); err != nil {
		return err
	}
	content := contentstore.Store{Queryer: pool}
	revision, err := content.ActiveRevision(ctx, pool)
	if err != nil {
		return err
	}
	if vip != 0 {
		catalog, err := content.PrivilegeCatalogTx(ctx, pool, revision)
		if err != nil {
			return err
		}
		if vip < 0 || vip >= int64(len(catalog.Rows)) {
			return fmt.Errorf("invalid scenario VIP %d", vip)
		}
		svc := commerceprivilege.Service{Runner: tx.Runner{DB: pool}, Fresh: pool, Time: postgres.AuthoritativeTime{Queryer: pool}, Players: i4store.PlayerRootLocker{}, Store: commerceprivilegestore.Store{}, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}, Effects: appi5.PrivilegeTransitionOwner{Store: i5store.Store{}, Content: content}, Directory: i4store.DirectoryLevelProjection{}, Audit: audit.NopEmitter{}}
		request, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
		if err != nil {
			return err
		}
		_, err = svc.ImportManual(ctx, commerceprivilege.Authority{Operator: provisionOperator, Capability: privilege.ManualCapability, PolicyVersion: privilege.ManualPolicy}, commerceprivilege.Import{PlayerID: identity.PlayerID(pid), LogicalServerID: identity.LogicalServerID(server), CommandKey: "vc-vip-" + request.ID.String(), Charge: catalog.Rows[vip].Charge, MonthlyState: privilege.MonthlyAbsent}, request)
		if err != nil {
			return err
		}
	}
	return grantLines(ctx, pool, revision, identity.PlayerID(pid), lines)
}

// seedChallengeFixture supplies only declared preconditions for the source Challenge UI consumer test (D134).
// shortcut: these Normal clears are fixture data, not genuine campaign-origin proof.
func seedChallengeFixture(ctx context.Context, pool *postgres.Pool, content contentstore.Store, revision string, pid identity.PlayerID) error {
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		return err
	}
	op, err := (operation.Factory{Clock: clock.System{}}).New(policies)
	if err != nil {
		return err
	}
	store := campaignstore.Store{}
	_, err = (tx.Runner{DB: pool}).Run(ctx, op, appcampaign.ModeProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		cat, e := content.CampaignCatalogTx(c, sc.Tx, revision)
		if e != nil {
			return e
		}
		r, e := store.LockTx(c, sc.Tx, pid, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		if r.PendingGeneration != "" {
			return fmt.Errorf("Challenge fixture refuses active pending battle")
		}
		ids := []int64{cat.ChallengeGateCampaignID, 100001, 100002, 100004}
		for _, id := range ids {
			n, ok := cat.Node(id)
			if !ok || n.Type != campaign.Normal {
				return fmt.Errorf("invalid Challenge fixture Normal node %d", id)
			}
			r.Progress = r.Progress.WithNode(campaign.NodeState{CampaignID: id, Star: 3})
		}
		return store.SaveTx(c, sc.Tx, pid, r, ids, sc.Operation.StartedAt)
	})
	return err
}
