package socialinvitestore_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/socialinvitestore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type inviteFactsDirectory struct{}

func (inviteFactsDirectory) ProfileTx(_ context.Context, _ tx.Tx, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: player, Name: "invitee", Level: 10, AvatarID: 110001001}, true, nil
}
func (inviteFactsDirectory) ProfilesByExactNameTx(context.Context, tx.Tx, string, int) ([]playerdirectory.Profile, error) {
	return nil, nil
}
func (inviteFactsDirectory) PlayerIDBoundsTx(context.Context, tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	return 0, 0, false, nil
}
func (inviteFactsDirectory) ProfilesAfterTx(context.Context, tx.Tx, identity.PlayerID, int) ([]playerdirectory.Profile, error) {
	return nil, nil
}
func (inviteFactsDirectory) ProfilesByRecentActivityTx(context.Context, tx.Tx, identity.LogicalServerID, identity.PlayerID, int) ([]playerdirectory.Profile, error) {
	return nil, nil
}

type inviteFactsAccount struct{}

func (inviteFactsAccount) ReadAccountTx(context.Context, tx.Queryer, identity.PlayerID) (identity.AccountID, error) {
	return identity.AccountID{}, nil
}

type inviteFactsProgression struct{ value player.Progression }

func (p inviteFactsProgression) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return p.value, nil
}

type inviteFactsHeroes struct {
	value characterasset.HeroLevelPopulation
}

func (h inviteFactsHeroes) ReadHeroLevelsTx(context.Context, characterasset.CoherentReadScope, identity.PlayerID) (characterasset.HeroLevelPopulation, error) {
	return h.value, nil
}

type inviteFactsPrivilege struct{ value privilege.Snapshot }

func (p inviteFactsPrivilege) ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error) {
	return p.value, nil
}

type inviteFactsServers struct{}

func (inviteFactsServers) ServerNameTx(context.Context, tx.Queryer, identity.LogicalServerID) (string, error) {
	return "S1", nil
}

type inviteFactsTx struct{}

func (inviteFactsTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (inviteFactsTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (inviteFactsTx) Commit(context.Context) error                                { return nil }
func (inviteFactsTx) Rollback(context.Context) error                              { return nil }

// K2': a privilege row stored while the clock was forward is observed at its
// own instant; the invitation facts must not refuse it after a backward step.
func TestInviteeFactsAcceptAForwardDatedPrivilegeAtItsObservedTime(t *testing.T) {
	const playerID = identity.PlayerID(100001)
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
	observed := at.Add(8 * time.Hour)
	snapshot := privilege.Snapshot{
		State: privilege.State{
			PlayerID: playerID, LogicalServerID: 1, Charge: 100, VIPLevel: 0,
			MonthlyState: privilege.MonthlyAbsent, ContentRevision: revision,
			PolicyVersion: privilege.ManualPolicy, OriginClass: privilege.ManualClass,
			Issuer: "native-invite", Reason: "native-invite", StateVersion: 1,
			CreatedAt: at, UpdatedAt: observed,
		},
		ObservationRevision: revision, ObservedAt: observed, SkillPointCap: 10,
		ProviderRevision: privilege.ManualPolicy + "/" + revision,
	}
	reader := socialinvitestore.FactsReader{
		Directory:   inviteFactsDirectory{},
		Accounts:    inviteFactsAccount{},
		Progression: inviteFactsProgression{value: player.Progression{PlayerID: playerID, Level: 10, StateVersion: 1, UpdatedAt: at}},
		Heroes:      inviteFactsHeroes{value: characterasset.HeroLevelPopulation{PlayerID: playerID, Revision: revision, ObservedAt: at, RootVersion: 1, OwnedCount: 2, HighestLevel: 10}},
		Privilege:   inviteFactsPrivilege{value: snapshot},
		Servers:     inviteFactsServers{},
	}
	scope := tx.Scope{
		Tx:        inviteFactsTx{},
		Operation: operation.Context{ID: operationID, StartedAt: at, Policies: policies},
		Attempt:   1,
		Options:   tx.Options{Isolation: tx.Serializable},
	}
	facts, err := reader.ReadInviteeFactsTx(context.Background(), scope, playerID, revision, at)
	if err != nil {
		t.Fatalf("forward-dated privilege refused: %v", err)
	}
	if facts.ChargeTotal != 100 || facts.AcademyLevel != 10 || facts.OwnedHeroCount != 2 {
		t.Fatalf("facts = %+v", facts)
	}
}
