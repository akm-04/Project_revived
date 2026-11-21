package mentor

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type filterDirectory struct {
	byID   map[identity.PlayerID]playerdirectory.Profile
	byName map[string][]playerdirectory.Profile
}

func (directory filterDirectory) ProfileTx(_ context.Context, _ tx.Tx, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	profile, found := directory.byID[player]
	return profile, found, nil
}

func (directory filterDirectory) ProfilesByExactNameTx(_ context.Context, _ tx.Tx, name string, _ int) ([]playerdirectory.Profile, error) {
	return directory.byName[name], nil
}

func (filterDirectory) ProfilesAfterTx(context.Context, tx.Tx, identity.PlayerID, int) ([]playerdirectory.Profile, error) {
	return nil, nil
}

func (filterDirectory) PlayerIDBoundsTx(context.Context, tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	return 0, 0, false, nil
}

// A forged class-pair request naming the caller must not surface as a defect:
// the observation reports no relation and the relation owner refuses the target.
func TestClassRelationActiveTreatsASelfTargetAsNoRelation(t *testing.T) {
	actor := identity.ActorContext{PlayerID: 100042, LogicalServerID: 1}
	active, err := (Service{}).ClassRelationActive(context.Background(), actor, actor.PlayerID, operation.Context{})
	if err != nil {
		t.Fatalf("self target surfaced as an observation defect: %v", err)
	}
	if active {
		t.Fatal("self target reported an active class relation")
	}
}

// C3: the exact-name and numeric-id search paths return same-server candidates
// only, like the no-filter scan (and never the actor itself).
func TestMentorFindCandidatesFilterStaysOnTheActorServer(t *testing.T) {
	actor := identity.ActorContext{PlayerID: 100042, LogicalServerID: 1}
	local := playerdirectory.Profile{PlayerID: 100007, Name: "Teacher", Level: 60, AvatarID: 110001001}
	foreign := playerdirectory.Profile{PlayerID: 200007, Name: "Teacher", Level: 60, AvatarID: 110001001}
	self := playerdirectory.Profile{PlayerID: actor.PlayerID, Name: "Teacher", Level: 60, AvatarID: 110001001}
	service := Service{Directory: filterDirectory{
		byID:   map[identity.PlayerID]playerdirectory.Profile{local.PlayerID: local, foreign.PlayerID: foreign, self.PlayerID: self},
		byName: map[string][]playerdirectory.Profile{"Teacher": {foreign, self, local}},
	}}
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	cases := []struct {
		name   string
		filter string
		want   []identity.PlayerID
	}{
		{"numeric id honours the server", "200007", nil},
		{"numeric id of the actor", "100042", nil},
		{"numeric id on the actor server", "100007", []identity.PlayerID{100007}},
		{"exact name honours the server", "Teacher", []identity.PlayerID{100007}},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			found, err := service.findCandidates(context.Background(), nil, actor, 1, test.filter, at)
			if err != nil {
				t.Fatal(err)
			}
			if len(found) != len(test.want) {
				t.Fatalf("findCandidates(%q) = %#v, want player ids %v", test.filter, found, test.want)
			}
			for index, player := range test.want {
				if found[index].PlayerID != player {
					t.Fatalf("findCandidates(%q) = %#v, want player ids %v", test.filter, found, test.want)
				}
			}
		})
	}
}
