//go:build postgres

package playerdisplay_test

import (
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const i910cMigration127File = "00127_i9_10c_glue_admission.sql"

// Commands are the stock shapes the owning Dorm command validates; the
// admissions are written through the production store, never by raw fixture SQL.
var i910cPredecessorAdmissions = map[string]app.Command{
	app.Open:     {Family: app.Open, ItemID: 1, Floor: 1, Position: 1},
	app.Save:     {Family: app.Save, HouseID: 1, Furniture: map[string]string{"furniture_record": "migration-fixture"}},
	app.Equip:    {Family: app.Equip, HouseID: 1, Index: 1},
	app.Enter:    {Family: app.Enter, HouseID: 1, Partners: []int64{1}},
	app.Exchange: {Family: app.Exchange, ItemID: 1, Amount: 1},
	app.Start:    {Family: app.Start, HouseID: 1},
	app.Finish:   {Family: app.Finish, HouseID: 1},
}

func i910cDurableActor(a identity.ActorContext) app.DurableActor {
	return app.DurableActor{Account: a.AccountID.UUID(), Session: a.SessionID.UUID(), Context: a.ContextID.UUID(), AccountUID: string(a.AccountUID), Server: int32(a.LogicalServerID), Player: int64(a.PlayerID), Generation: a.ContextGeneration, SessionVersion: a.SessionLivenessVersion, ContextVersion: a.ContextLivenessVersion}
}

func i910cAdmission(t *testing.T, actor identity.ActorContext, revision string, at time.Time, command app.Command) app.Admission {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision}, policy.Ref{Name: "dorm", Version: app.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	current, err := (operation.Factory{Clock: clock.System{}}).New(policies)
	if err != nil {
		t.Fatal(err)
	}
	current.StartedAt = at
	return app.Admission{Operation: current, DecisionAt: at, Actor: i910cDurableActor(actor), Command: command, ContentRevision: revision, State: "PENDING"}
}

func i910cSaveAdmission(t *testing.T, p *pg.Pool, owner dormstore.Store, admission app.Admission) error {
	t.Helper()
	transaction, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = owner.SaveAdmissionTx(ctx, transaction, admission); err != nil {
		transaction.Rollback(ctx)
		return err
	}
	return transaction.Commit(ctx)
}

func i910cFamilyConstraint(t *testing.T, p *pg.Pool) string {
	t.Helper()
	var definition string
	if err := p.QueryRow(ctx, `SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname='player_dorm_admissions_family_check'`).Scan(&definition); err != nil {
		t.Fatal(err)
	}
	return definition
}

func i910cLockAdmission(t *testing.T, p *pg.Pool, owner dormstore.Store, player identity.PlayerID, family string) (app.Admission, bool, error) {
	t.Helper()
	transaction, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	return owner.LockAdmissionTx(ctx, transaction, player, family)
}

// TestI910CMigration127PreservesAdmissionsAndAdmitsBuyGlue runs on a dedicated
// database at goose 126: it populates the seven predecessor admission families
// through dormstore, applies the owning 00127 migration, and reads every row and
// the new DORM_BUY_GLUE lane back through the production admission store.
// One-shot per database: drop and recreate to repeat.
func TestI910CMigration127PreservesAdmissionsAndAdmitsBuyGlue(t *testing.T) {
	dsn := os.Getenv("GXB_I910C_MIG127_DSN")
	if dsn == "" {
		t.Skip("dedicated populated schema126 migration127 fixture not configured")
	}
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	var gooseVersion int64
	if err = p.QueryRow(ctx, `SELECT max(version_id) FROM goose_db_version`).Scan(&gooseVersion); err != nil {
		t.Fatal(err)
	}
	if gooseVersion != 126 {
		t.Fatalf("predecessor goose=%d want 126", gooseVersion)
	}
	predecessor := i910cFamilyConstraint(t, p)
	if !strings.Contains(predecessor, app.Open) || !strings.Contains(predecessor, app.Finish) || strings.Contains(predecessor, app.BuyGlue) {
		t.Fatalf("unexpected predecessor family constraint: %s", predecessor)
	}
	revision, err := (contentstore.Store{}).ActiveRevision(ctx, p)
	if err != nil || revision != i910cCandidateRevision {
		t.Fatalf("active content revision=%q err=%v", revision, err)
	}
	actor := bornActor(t, p)
	owner := dormstore.Store{Queryer: p}
	at := time.Now().UTC()
	expected := make(map[string]ids.UUID, len(i910cPredecessorAdmissions))
	for family, command := range i910cPredecessorAdmissions {
		admission := i910cAdmission(t, actor, revision, at, command)
		if err = i910cSaveAdmission(t, p, owner, admission); err != nil {
			t.Fatalf("seed predecessor family %s: %v", family, err)
		}
		expected[family] = admission.Operation.ID
	}
	buyGlue := i910cAdmission(t, actor, revision, at, app.Command{Family: app.BuyGlue})
	refusal := i910cSaveAdmission(t, p, owner, buyGlue)
	if refusal == nil || !strings.Contains(refusal.Error(), "player_dorm_admissions_family_check") {
		t.Fatalf("predecessor schema admitted DORM_BUY_GLUE: %v", refusal)
	}

	migration, err := os.ReadFile("../../../migrations/" + i910cMigration127File)
	if err != nil {
		t.Fatal(err)
	}
	migrationTransaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer migrationTransaction.Rollback(ctx)
	for _, statement := range strings.Split(string(migration), ";") {
		statement = strings.TrimSpace(statement)
		if statement == "" {
			continue
		}
		if _, err = migrationTransaction.Exec(ctx, statement); err != nil {
			t.Fatalf("apply %s: %v", i910cMigration127File, err)
		}
	}

	if err = migrationTransaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	migrated := i910cFamilyConstraint(t, p)
	if !strings.Contains(migrated, app.BuyGlue) {
		t.Fatalf("migrated family constraint lacks %s: %s", app.BuyGlue, migrated)
	}
	for family, operationID := range expected {
		stored, exists, err := i910cLockAdmission(t, p, owner, actor.PlayerID, family)
		if err != nil || !exists || stored.State != "PENDING" || stored.Command.Family != family || stored.Operation.ID != operationID {
			t.Fatalf("predecessor family %s after migration: %+v exists=%v err=%v", family, stored, exists, err)
		}
		if err = i910cSaveAdmission(t, p, owner, stored); err != nil {
			t.Fatalf("predecessor family %s no longer admissible after migration: %v", family, err)
		}
	}
	if err = i910cSaveAdmission(t, p, owner, buyGlue); err != nil {
		t.Fatalf("migration127 DORM_BUY_GLUE admission: %v", err)
	}
	stored, exists, err := i910cLockAdmission(t, p, owner, actor.PlayerID, app.BuyGlue)
	if err != nil || !exists || stored.State != "PENDING" || stored.Command.Family != app.BuyGlue || stored.Operation.ID != buyGlue.Operation.ID {
		t.Fatalf("migrated DORM_BUY_GLUE lane: %+v exists=%v err=%v", stored, exists, err)
	}
	t.Logf("REAL_PG migration127: goose=%d seven predecessor families preserved, predecessor refused DORM_BUY_GLUE (%v), %s applied, new lane=%s content=%s", gooseVersion, refusal, i910cMigration127File, stored.Operation.ID, revision)
}
