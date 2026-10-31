package i5

import (
	"context"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"slices"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type occultScalarStore struct {
	*testStore
	scalars map[string]economy.ScalarBalance
	trace   []string
}

func (s *occultScalarStore) LockScalarTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, key string, _ time.Time) (economy.ScalarBalance, bool, error) {
	s.trace = append(s.trace, "scalar:"+key)
	balance, exists := s.scalars[key]
	return balance, exists, nil
}

func (s *occultScalarStore) SaveScalarTx(_ context.Context, _ tx.Tx, b economy.ScalarBalance, _ bool) error {
	s.scalars[b.ResourceKey] = b
	return nil
}

func (s *occultScalarStore) LockTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string) (economy.TemporalState, bool, error) {
	s.trace = append(s.trace, "temporal:"+key)
	return s.testStore.LockTemporalTx(ctx, t, pid, key)
}

func occultTicketFixture(t *testing.T, energy int64) (Service, *occultScalarStore, identity.PlayerID, operation.Context) {
	t.Helper()
	actor := testActor(t)
	now := time.Unix(1700002000, 0).UTC()
	base := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 5, StateVersion: 1, UpdatedAt: now},
		temporal: map[string]economy.TemporalState{
			"energy":        {PlayerID: actor.PlayerID, ResourceKey: "energy", StoredAmount: energy, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 1, UpdatedAt: now},
			"spirit_energy": {PlayerID: actor.PlayerID, ResourceKey: "spirit_energy", StoredAmount: energy, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 1, UpdatedAt: now},
		},
	}
	store := &occultScalarStore{testStore: base, scalars: map[string]economy.ScalarBalance{}}
	op, err := bindContentRevision(operation.Context{ID: testUUID(160), StartedAt: now}, testContentRevisionA)
	if err != nil {
		t.Fatal(err)
	}
	return Service{Store: store, Content: revisionedContent{&testContent{}}, Privileges: BaselinePrivilegeProvider{}}, store, actor.PlayerID, op
}

func TestEnergyDebitAccruesOccultTicketsWithCarryAndCap(t *testing.T) {
	svc, store, pid, op := occultTicketFixture(t, 100000)
	debit := func(amount int64) {
		t.Helper()
		if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, pid, "energy", amount, op); err != nil {
			t.Fatal(err)
		}
	}
	debit(2000)
	if got := store.scalars[OccultTicketKey].Amount; got != 0 {
		t.Fatalf("tickets after 2000=%d", got)
	}
	if got := store.scalars[occultEnergyProgressKey].Amount; got != 2000 {
		t.Fatalf("progress after 2000=%d", got)
	}
	debit(2000)
	if store.scalars[OccultTicketKey].Amount != 1 || store.scalars[occultEnergyProgressKey].Amount != 1000 {
		t.Fatalf("after 4000: %+v", store.scalars)
	}
	debit(9000)
	if store.scalars[OccultTicketKey].Amount != 2 || store.scalars[occultEnergyProgressKey].Amount != 0 {
		t.Fatalf("cap: %+v", store.scalars)
	}
	debit(5000)
	if store.scalars[OccultTicketKey].Amount != 2 || store.scalars[occultEnergyProgressKey].Amount != 0 {
		t.Fatalf("a full holder earns nothing: %+v", store.scalars)
	}
}

func TestNonEnergyDebitNeverTouchesOccultTickets(t *testing.T) {
	svc, store, pid, op := occultTicketFixture(t, 100000)
	if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, pid, "spirit_energy", 6000, op); err != nil {
		t.Fatal(err)
	}
	if len(store.scalars) != 0 || len(store.trace) != 1 || store.trace[0] != "temporal:spirit_energy" {
		t.Fatalf("scalars=%v trace=%v", store.scalars, store.trace)
	}
}

func TestEnergyDebitLocksScalarsBeforeTemporal(t *testing.T) {
	svc, store, pid, op := occultTicketFixture(t, 5000)
	if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, pid, "energy", 3000, op); err != nil {
		t.Fatal(err)
	}
	want := []string{"scalar:occult_ticket", "scalar:occult_energy_progress", "temporal:energy"}
	if !slices.Equal(store.trace, want) {
		t.Fatalf("lock order %v", store.trace)
	}
}

func TestShortEnergyDebitAccruesNothing(t *testing.T) {
	svc, store, pid, op := occultTicketFixture(t, 100)
	if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, pid, "energy", 3000, op); err == nil {
		t.Fatal("short energy must refuse")
	}
	if len(store.scalars) != 0 {
		t.Fatalf("scalars=%v", store.scalars)
	}
}

func backendRoot(t *testing.T) string {
	t.Helper()
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "..", "..", "..")
}

// The only code that may lower an energy row is DebitTemporalTx. TemporalState.Debit
// is the only domain operation that lowers a temporal row, and any SQL that writes
// player_temporal_resources must live in the i5 store.
func TestNoEnergyDebitBypassesDebitTemporalTx(t *testing.T) {
	root := backendRoot(t)
	allowedDebitCallers := map[string]bool{"internal/application/i5/temporal_debit.go": true}
	allowedTemporalSQL := map[string]bool{"internal/adapters/postgres/i5store/": true, "sql/i5/economy.sql": true}
	temporalWrite := regexp.MustCompile(`(?is)(UPDATE|INSERT\s+INTO|DELETE\s+FROM)\s+player_temporal_resources`)
	var debitCalls, temporalWrites []string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		relative, _ := filepath.Rel(root, path)
		if entry.IsDir() && (relative == ".git" || strings.HasPrefix(relative, "EVIDENCE") || relative == "migrations") {
			return filepath.SkipDir
		}
		if entry.IsDir() || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		source, readErr := os.ReadFile(path)
		if readErr != nil {
			return readErr
		}
		if strings.HasSuffix(path, ".go") {
			file, parseErr := parser.ParseFile(token.NewFileSet(), path, source, 0)
			if parseErr != nil {
				return parseErr
			}
			ast.Inspect(file, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				selector, ok := call.Fun.(*ast.SelectorExpr)
				if ok && selector.Sel.Name == "Debit" && len(call.Args) == 3 {
					debitCalls = append(debitCalls, relative)
				}
				return true
			})
		}
		if (strings.HasSuffix(path, ".go") || strings.HasSuffix(path, ".sql")) && temporalWrite.Match(source) {
			temporalWrites = append(temporalWrites, relative)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("TemporalState.Debit callers: %v; player_temporal_resources writers: %v", debitCalls, temporalWrites)
	if len(debitCalls) == 0 {
		t.Fatal("audit found no TemporalState.Debit caller; the walk is broken")
	}
	for _, caller := range debitCalls {
		if !allowedDebitCallers[caller] {
			t.Errorf("energy debit outside DebitTemporalTx: %s", caller)
		}
	}
	for _, writer := range temporalWrites {
		allowed := false
		for prefix := range allowedTemporalSQL {
			allowed = allowed || strings.HasPrefix(writer, prefix)
		}
		if !allowed {
			t.Errorf("player_temporal_resources written outside the i5 store: %s", writer)
		}
	}
}
