// Package provision stands in for the stock login SDK: it creates the live account session whose sid and login_token the SDK would hand the client.
package provision

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
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

// completedGuideID is stock xyd.GuideStoryType.GUIDE_PET_THREE: a progressed player has finished the main, skill, arena and pet
// tutorials, which otherwise capture every touch (GuideWindow) once their function opens.
const completedGuideID = 100503

// Summon is one stone summon (stock MID59 STONE_SUMMON_HERO) the stock client makes itself once Progress granted its fragments.
type Summon struct {
	TableID  int64 `json:"table_id"`
	Stone    int64 `json:"stone"`
	StoneNum int64 `json:"stone_num"`
}

// queryer lets the production content store read through a pgx transaction.
type queryer struct{ pgx.Tx }

func (q queryer) QueryRow(context context.Context, query string, arguments ...any) tx.Row {
	return q.Tx.QueryRow(context, query, arguments...)
}

// Progress raises the player stock MID1 birthed for the account the way the integration fixtures do (oneOnOnePlayer): the
// Player Core level, its directory projection and the functions it opens in one transaction, explicit fragment and mana resource rows. Heroes are
// not inserted: the returned summons are for the stock client to make through MID59, so the production birth runs.
func Progress(context context.Context, databaseURL, accountID string, level int64, tables []int64) ([]Summon, error) {
	connection, err := pgx.Connect(context, databaseURL)
	if err != nil {
		return nil, err
	}
	defer connection.Close(context)
	transaction, err := connection.Begin(context)
	if err != nil {
		return nil, err
	}
	defer transaction.Rollback(context)
	var playerID int64
	if err := transaction.QueryRow(context, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&playerID); err != nil {
		return nil, fmt.Errorf("born player: %w", err)
	}
	if level > 0 {
		for _, statement := range []string{
			`UPDATE player_progression SET level=$2, state_version=state_version+1, updated_at=clock_timestamp() WHERE player_id=$1`,
			`UPDATE player_directory_profiles SET lev=$2, state_version=state_version+1, updated_at=clock_timestamp() WHERE player_id=$1`,
		} {
			if tag, err := transaction.Exec(context, statement, playerID, level); err != nil || tag.RowsAffected() != 1 {
				return nil, fmt.Errorf("level: %v (rows %d)", err, tag.RowsAffected())
			}
		}
		if tag, err := transaction.Exec(context, `UPDATE player_story_cursors SET guide_id=$2, state_version=state_version+1, updated_at=clock_timestamp()
			WHERE player_id=$1`, playerID, completedGuideID); err != nil || tag.RowsAffected() != 1 {
			return nil, fmt.Errorf("guide: %v (rows %d)", err, tag.RowsAffected())
		}
	}
	content := contentstore.Store{}
	revision, err := content.ActiveRevision(context, queryer{transaction})
	if err != nil {
		return nil, err
	}
	if err := openFunctions(context, transaction, content, revision, playerID, level); err != nil {
		return nil, err
	}
	var summons []Summon
	var mana int64
	for _, table := range tables {
		policy, err := content.HeroNormalSummonTx(context, queryer{transaction}, revision, table)
		if err != nil {
			return nil, fmt.Errorf("summon policy %d: %w", table, err)
		}
		if _, err := transaction.Exec(context, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)
			VALUES($1,$2,$3,1,clock_timestamp(),clock_timestamp())
			ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=player_item_stacks.quantity+excluded.quantity,
			state_version=player_item_stacks.state_version+1, updated_at=excluded.updated_at`, playerID, policy.Template.FragmentItemID, policy.FragmentCount); err != nil {
			return nil, fmt.Errorf("fragments %d: %w", table, err)
		}
		mana += policy.Mana
		summons = append(summons, Summon{TableID: table, Stone: policy.Template.FragmentItemID, StoneNum: policy.FragmentCount})
	}
	if mana > 0 {
		if _, err := transaction.Exec(context, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)
			VALUES($1,'mana',$2,1,clock_timestamp())
			ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=player_currency_balances.amount+excluded.amount,
			state_version=player_currency_balances.state_version+1, updated_at=excluded.updated_at`, playerID, mana); err != nil {
			return nil, fmt.Errorf("mana: %w", err)
		}
	}
	return summons, transaction.Commit(context)
}

// openFunctions writes the eligibility rows the production level-up writes for the level (i5 Grant: pure-level gates) and the
// unlock rows stock SelfPlayer:isFuncOpen reads back through MID1 func_ids.
// shortcut: production announces only Pet Function 38 (I8.5 finding F1), so these unlocks stand in for the announcement I8.5-6
// adds at the level stock FunctionOpenTable reads; drop them once production announces.
func openFunctions(context context.Context, transaction pgx.Tx, content contentstore.Store, revision string, playerID, level int64) error {
	policy, err := content.ResolveFunctionGatePolicyTx(context, queryer{transaction}, revision)
	if err != nil {
		return err
	}
	for _, gate := range policy.Gates {
		openLevel, readable := stockOpenLevel(gate.RawOpenValue)
		// Gates with an announcement capability (Pet Function 38 grants the starter egg) open only through production.
		if !readable || openLevel > level || gate.AnnouncementCapability != "NONE" {
			continue
		}
		key := "vc:provision:function:" + gate.SourceFactKey
		if gate.GateKind == "PURE_LEVEL" {
			if _, err := transaction.Exec(context, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
				VALUES($1,$2,$3,$4,clock_timestamp()) ON CONFLICT(player_id,function_id) DO NOTHING`, playerID, gate.FunctionID, revision, key); err != nil {
				return fmt.Errorf("function %d eligibility: %w", gate.FunctionID, err)
			}
		}
		if _, err := transaction.Exec(context, `INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version)
			VALUES($1,$2,clock_timestamp(),$3,1) ON CONFLICT(player_id,function_id) DO NOTHING`, playerID, gate.FunctionID, key); err != nil {
			return fmt.Errorf("function %d unlock: %w", gate.FunctionID, err)
		}
	}
	return nil
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
