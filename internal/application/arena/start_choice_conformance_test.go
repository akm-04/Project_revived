package arena

import (
	"context"
	"reflect"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceArenaTournament STARTs playoffs and a friend fight
// twice for one room. The team is the room selection, which only accepts turns
// while the room is selecting (arena/selection.go:66) and closes it when the
// selection completes (arena/selection.go:83-85); START reads that frozen
// selection (arena/tournament_combat.go:78), so the second reconcile replays
// the started room without a second combat attempt.
func TestStartChoiceConformanceArenaTournament(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	for _, testCase := range []struct {
		name   string
		mode   cd.ModeKey
		friend bool
	}{
		{"playoffs", cd.ModeArenaPlayoffs, false},
		{"friend-fight", cd.ModeArenaFriendFight, true},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			combat := &startChoiceCombat{}
			service := startChoiceService(at, startChoiceRoom(testCase.friend, at), combat)
			first, err := service.StartTournamentCombat(context.Background(), ids.UUID{1}, startChoiceOperation(t, ids.UUID{1}, at))
			if err != nil {
				t.Fatalf("first START: %v", err)
			}
			if len(combat.requests) != d.SelectionTeamCount {
				t.Fatalf("captured %d START requests, want one per round", len(combat.requests))
			}
			for _, request := range combat.requests {
				if request.Mode != testCase.mode {
					t.Fatalf("built mode %q", request.Mode)
				}
			}
			second, err := service.StartTournamentCombat(context.Background(), ids.UUID{1}, startChoiceOperation(t, ids.UUID{2}, at))
			if err != nil {
				t.Fatalf("second START: %v", err)
			}
			if len(combat.requests) != d.SelectionTeamCount {
				t.Fatalf("a repeated START opened %d combat attempts, want the one per round", len(combat.requests))
			}
			if !reflect.DeepEqual(first, second) {
				t.Fatal("an equivalent repeated START did not replay the started room")
			}
		})
	}
}

func startChoiceRoom(friend bool, at time.Time) d.TournamentRoom {
	const server = identity.LogicalServerID(1)
	formation := func(heroes ...int64) d.SelectedFormation { return d.SelectedFormation{Heroes: heroes} }
	room := d.TournamentRoom{
		Identifier: ids.UUID{1},
		Status:     d.RoomFighting,
		Actors:     [2]d.AdmissionContext{d.AdmissionFrom(startChoiceActor(7, server)), d.AdmissionFrom(startChoiceActor(8, server))},
		Selection: d.SelectionRoom{
			Players: [2]identity.PlayerID{7, 8},
			Teams: [2][d.SelectionTeamCount]d.SelectedFormation{
				{formation(101, 102), formation(101, 102), formation(101, 102)},
				{formation(201, 202), formation(201, 202), formation(201, 202)},
			},
			Team:     d.SelectionTeamCount,
			Turn:     d.SelectionDoneTurn,
			Deadline: at,
		},
		StartsAt:        at,
		ContentRevision: startChoiceRevision,
	}
	if friend {
		room.FriendInvitation, room.FriendMode = ids.UUID{9}, 1
	}
	return room
}

func startChoiceActor(player int64, server identity.LogicalServerID) identity.ActorContext {
	account, _ := identity.AccountIDFrom(ids.UUID{byte(player), 1})
	session, _ := identity.SessionIDFrom(ids.UUID{byte(player), 2})
	contextID, _ := identity.ContextIDFrom(ids.UUID{byte(player), 3})
	return identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID(ids.UUID{byte(player), 4}.String()), SessionID: session, ContextID: contextID,
		LogicalServerID: server, PlayerID: identity.PlayerID(player), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func startChoiceService(at time.Time, room d.TournamentRoom, combat *startChoiceCombat) Service {
	return Service{
		Timed:        gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:        startChoiceQueryer{},
		Store:        &startChoiceStore{room: room, competition: d.Competition{StateVersion: 1}},
		Content:      startChoiceContent{},
		Fence:        startChoiceFence{},
		Costs:        startChoiceCosts{},
		Grants:       startChoiceGrants{},
		Values:       startChoiceValues{},
		Mail:         startChoiceMail{},
		Achievements: startChoiceAchievements{},
		Facts:        startChoiceFacts{},
		Combat:       combat,
		Heroes:       startChoiceRoster{},
		Pets:         startChoiceRoster{},
		OwnedHeroes:  startChoiceOwnedHeroes{},
		Directory:    startChoiceDirectory{},
		Guilds:       startChoiceGuilds{},
		Servers:      startChoiceServers{},
		Receipts:     startChoiceReceipts{},
		ReceiptRead:  startChoiceReceiptRead{},
		BattleCounts: startChoiceBattleCounts{},
	}
}

type startChoiceBattleCounts struct{}

func (startChoiceBattleCounts) ObserveBattleTx(context.Context, tx.Tx, identity.PlayerID, []int64, time.Time) error {
	return nil
}

// startChoiceCombat records each StartManyTx call the mode builder produced.
type startChoiceCombat struct {
	Combat
	requests []appcombat.StartRequest
}

func (c *startChoiceCombat) StartManyTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, requests []appcombat.StartRequest) ([]appcombat.Started, error) {
	c.requests = append(c.requests, requests...)
	out := make([]appcombat.Started, 0, len(requests))
	for index := range requests {
		out = append(out, appcombat.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests) + index)}}})
	}
	return out, nil
}

type startChoiceStore struct {
	Store
	room        d.TournamentRoom
	competition d.Competition
}

func (s *startChoiceStore) ReadCompetitionTx(context.Context, tx.Queryer, bool) (d.Competition, bool, error) {
	return s.competition, true, nil
}

func (s *startChoiceStore) SaveCompetitionTx(context.Context, tx.Tx, d.Competition, int64) error {
	return nil
}

func (s *startChoiceStore) ReadTournamentRoomTx(context.Context, tx.Queryer, ids.UUID, bool) (d.TournamentRoom, bool, error) {
	return s.room, true, nil
}

func (s *startChoiceStore) SaveTournamentRoomTx(_ context.Context, _ tx.Tx, room d.TournamentRoom, _ int64) error {
	s.room = room
	return nil
}

type startChoiceContent struct{ Content }

func (startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

type startChoiceFence struct{ Fence }

type startChoiceCosts struct{ i5.TxMaterialCostDebiter }

type startChoiceGrants struct{ Grants }

type startChoiceValues struct{ Values }

type startChoiceMail struct{ Mail }

type startChoiceAchievements struct{ Achievements }

type startChoiceFacts struct{ Facts }

type startChoiceOwnedHeroes struct{ OwnedHeroReader }

type startChoiceGuilds struct{ Guilds }

func (startChoiceGuilds) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{}, false, nil
}

type startChoiceServers struct{ Servers }

func (startChoiceServers) ServerNameTx(context.Context, tx.Queryer, identity.LogicalServerID) (string, error) {
	return "server", nil
}

type startChoiceDirectory struct{}

func (startChoiceDirectory) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{Name: "player", Level: 60}, true, nil
}

type startChoiceRoster struct{ Roster }

func (startChoiceRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	heros := map[string]any{
		"101": map[string]any{"partner_id": int64(101), "table_id": int64(10001001)},
		"102": map[string]any{"partner_id": int64(102), "table_id": int64(10001002)},
		"201": map[string]any{"partner_id": int64(201), "table_id": int64(10002001)},
		"202": map[string]any{"partner_id": int64(202), "table_id": int64(10002002)},
	}
	detail["49"] = map[string]any{"heros": heros}
	detail["780"] = map[string]any{"pets": []any{}}
	return nil
}

type startChoiceReceipts struct{}

func (startChoiceReceipts) FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func (startChoiceReceipts) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, nil
}

type startChoiceReceiptRead struct{ receipt.Reader }

type startChoiceQueryer struct{}

func (startChoiceQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type startChoiceTx struct{}

func (startChoiceTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (startChoiceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (startChoiceTx) Commit(context.Context) error                                { return nil }
func (startChoiceTx) Rollback(context.Context) error                              { return nil }

type startChoiceBeginner struct{}

func (startChoiceBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return startChoiceTx{}, nil
}

type startChoiceClock struct{ at time.Time }

func (c startChoiceClock) Now(context.Context) (time.Time, error) { return c.at, nil }

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}
