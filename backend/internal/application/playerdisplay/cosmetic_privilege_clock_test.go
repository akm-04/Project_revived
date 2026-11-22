package playerdisplay

import (
	"context"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type displayPrivilegeReader struct{ value privilege.Snapshot }

func (r displayPrivilegeReader) ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error) {
	return r.value, nil
}

type displayContent struct{ catalog player.DisplayCatalog }

func (c displayContent) ActiveRevision(context.Context, tx.Queryer) (string, error) { return "", nil }
func (c displayContent) ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error) {
	return c.catalog, nil
}

type displayStore struct {
	Store
	state State
}

func (s displayStore) ReadDisplayStateTx(context.Context, tx.Queryer, identity.PlayerID, bool) (State, error) {
	return s.state, nil
}
func (displayStore) ReadDisplayEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]Origin, error) {
	return nil, nil
}

type displayPopulation struct{ value CharacterPopulation }

func (p displayPopulation) ReadDisplayPopulationTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (CharacterPopulation, error) {
	return p.value, nil
}

type displayInventory struct{ value InventoryPopulation }

func (i displayInventory) ReadDisplayInventoryTx(context.Context, tx.Queryer, identity.PlayerID) (InventoryPopulation, error) {
	return i.value, nil
}

type displayEligibilityTx struct{}

func (displayEligibilityTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (displayEligibilityTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (displayEligibilityTx) Commit(context.Context) error   { return nil }
func (displayEligibilityTx) Rollback(context.Context) error { return nil }

func forwardPrivilegeSnapshot(t *testing.T, pid identity.PlayerID, revision string, at time.Time) privilege.Snapshot {
	t.Helper()
	observed := at.Add(8 * time.Hour)
	return privilege.Snapshot{
		State: privilege.State{
			PlayerID: pid, LogicalServerID: 1, Charge: 100, VIPLevel: 5,
			MonthlyState: privilege.MonthlyAbsent, ContentRevision: revision,
			PolicyVersion: privilege.ManualPolicy, OriginClass: privilege.ManualClass,
			Issuer: "native-display", Reason: "native-display", StateVersion: 1,
			CreatedAt: at, UpdatedAt: observed,
		},
		ObservationRevision: revision, ObservedAt: observed, SkillPointCap: 10,
		ProviderRevision: privilege.ManualPolicy + "/" + revision,
	}
}

func displayCatalog(t *testing.T) player.DisplayCatalog {
	t.Helper()
	names := make([]string, 12)
	for index := range names {
		names[index] = "n" + string(rune('a'+index))
	}
	return player.DisplayCatalog{
		SchemaVersion: 1, PolicyID: player.DisplayPolicy, RenameCost: 100,
		DefaultAvatar: 1, DefaultFrame: 1, DefaultBubble: 1,
		Names: names, Words: []string{"zz"}, Collection: []int64{1, 2, 3, 4},
		Cosmetics: []player.Cosmetic{
			{Family: "avatar", ID: 1, Type: 1, Icon: 1},
			{Family: "frame", ID: 1, Type: 1},
			{Family: "bubble", ID: 1},
		},
	}
}

// K2': the provider returns a snapshot observed at a forward stored fact; the
// eligibility predicate validates that snapshot at its own instant.
func TestEligibleObservesAForwardDatedPrivilegeAtItsOwnInstant(t *testing.T) {
	const pid = identity.PlayerID(100001)
	revision := strings.Repeat("a", 64)
	at := time.Date(2026, 11, 21, 10, 0, 0, 0, time.UTC)
	service := Service{CosmeticPrivileges: displayPrivilegeReader{value: forwardPrivilegeSnapshot(t, pid, revision, at)}}
	origins, heroes, err := service.eligible(context.Background(), nil, pid, player.Cosmetic{Family: "frame", Type: 6, VIP: 3}, 0, 0, revision, at, player.DisplayCatalog{})
	if err != nil {
		t.Fatalf("forward-dated privilege refused: %v", err)
	}
	if len(origins) != 0 || len(heroes) != 0 {
		t.Fatalf("origins=%#v heroes=%#v", origins, heroes)
	}
}

func TestReadEligibilityObservesAForwardDatedPrivilegeAtItsOwnInstant(t *testing.T) {
	const pid = identity.PlayerID(100001)
	revision := strings.Repeat("a", 64)
	at := time.Date(2026, 11, 21, 10, 0, 0, 0, time.UTC)
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		t.Fatal(err)
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: displayEligibilityTx{}, Operation: operation.Context{ID: operationID, StartedAt: at, Policies: policies}, Attempt: 1, Options: tx.Options{Isolation: tx.Serializable}}, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	service := Service{
		Content: displayContent{catalog: displayCatalog(t)},
		Store: displayStore{state: State{
			Basis: i5.PublicPlayerBasis{
				Profile:     player.Profile{PlayerID: pid, AvatarID: 1, StateVersion: 1, CreatedAt: at, UpdatedAt: at},
				Progression: player.Progression{PlayerID: pid, Level: 1, StateVersion: 1, UpdatedAt: at},
			},
		}},
		Population:         displayPopulation{value: CharacterPopulation{PlayerID: pid, Revision: revision, ObservedAt: at, RootVersion: 1, Digest: PopulationDigest([]HeroFacet(nil))}},
		Inventory:          displayInventory{value: InventoryPopulation{PlayerID: pid, RootVersion: 1, CreatedAt: at}},
		CosmeticPrivileges: displayPrivilegeReader{value: forwardPrivilegeSnapshot(t, pid, revision, at)},
	}
	out, err := service.ReadEligibilityTx(context.Background(), scope, EligibilityRequest{PlayerID: pid, Family: "frame"})
	if err != nil {
		t.Fatalf("forward-dated privilege refused: %v", err)
	}
	if out.Privilege == nil {
		t.Fatal("eligibility omitted the privilege observation")
	}
}
