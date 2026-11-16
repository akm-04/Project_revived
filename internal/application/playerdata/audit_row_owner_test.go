package playerdata

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestAuditA071RestoreRefusesAnotherPlayersStackRow(t *testing.T) {
	plan := Plan{SchemaVersion: PlanFormat, Tables: []PlanTable{
		{Table: "players", Action: ActionRestore, Select: `SELECT * FROM "players" WHERE "player_id"=$1::bigint`},
		{Table: "player_item_stacks", Action: ActionRestore, Select: `SELECT * FROM "player_item_stacks" WHERE "player_id"=$1::bigint`},
	}}
	if err := plan.Validate(); err != nil {
		t.Fatal(err)
	}
	document := Document{Format: ExportFormat, SchemaVersion: 167, PlayerID: 100001, LogicalServerID: 1, PlanSHA256: "current-plan", Tables: []TableRows{
		{Table: "players", Action: ActionRestore, Rows: []json.RawMessage{json.RawMessage(`{"player_id":100001,"logical_server_id":1}`)}},
		{Table: "player_item_stacks", Action: ActionRestore, Rows: []json.RawMessage{json.RawMessage(`{"player_id":100002,"item_id":40001053,"quantity":5}`)}},
	}}
	transaction := &auditRestoreTransaction{}
	store := &auditRestoreStore{}
	service := RestoreService{Database: auditRestoreDatabase{transaction}, Store: store, Roots: auditRestoreRoots{}}
	_, err := service.Restore(context.Background(), plan, "current-plan", 100001, document, time.Unix(100, 0))
	if !errors.Is(err, ErrRestoreRefused) || transaction.committed {
		t.Fatalf("cross-player restore err=%v committed=%v foreign row passed to InsertRow=%s", err, transaction.committed, store.stack)
	}
}

type auditRestoreDatabase struct{ transaction *auditRestoreTransaction }

func (database auditRestoreDatabase) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return database.transaction, nil
}

type auditRestoreTransaction struct {
	tx.Tx
	committed bool
}

func (transaction *auditRestoreTransaction) Commit(context.Context) error {
	transaction.committed = true
	return nil
}
func (*auditRestoreTransaction) Rollback(context.Context) error { return nil }

type auditRestoreRoots struct{}

func (auditRestoreRoots) LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error) {
	return []playerroot.Root{{PlayerID: 100001, LogicalServerID: 1}}, nil
}

type auditRestoreStore struct {
	RestoreStore
	stack json.RawMessage
}

func (*auditRestoreStore) GooseVersion(context.Context, tx.Queryer) (int64, error) {
	return 167, nil
}
func (*auditRestoreStore) PlayerServer(context.Context, tx.Queryer, int64) (int32, bool, error) {
	return 1, true, nil
}
func (*auditRestoreStore) SelectRows(context.Context, tx.Queryer, string, int64) ([]json.RawMessage, error) {
	return nil, nil
}
func (*auditRestoreStore) PrimaryKey(_ context.Context, _ tx.Queryer, table string) ([]string, error) {
	if table == "players" {
		return []string{"player_id"}, nil
	}
	return []string{"player_id", "item_id"}, nil
}
func (*auditRestoreStore) InboundReferences(context.Context, tx.Queryer, string) ([]InboundReference, error) {
	return nil, nil
}
func (*auditRestoreStore) Columns(context.Context, tx.Queryer, string) ([]string, error) {
	return nil, nil
}
func (*auditRestoreStore) DeleteUnreferenced(context.Context, tx.Tx, string, string, []InboundReference, int64) error {
	return nil
}
func (store *auditRestoreStore) InsertRow(_ context.Context, _ tx.Tx, table string, _ []string, row json.RawMessage) error {
	if table == "player_item_stacks" {
		store.stack = append(json.RawMessage(nil), row...)
	}
	return nil
}
func (*auditRestoreStore) EndPlayerSessions(context.Context, tx.Tx, int64, time.Time) (int, error) {
	return 0, nil
}
