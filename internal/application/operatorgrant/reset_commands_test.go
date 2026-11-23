package operatorgrant

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func TestValidateResetCountersRefusesBadVocabulary(t *testing.T) {
	cases := []struct {
		name    string
		names   []string
		message string
	}{
		{"empty", nil, "counters must list at least one name"},
		{"duplicate", []string{CounterDailyBuys, CounterDailyBuys}, "a counter name appears twice"},
		{"unknown", []string{"not_a_counter"}, "unknown counter name"},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			_, err := validateResetCounters(testCase.names)
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodeResetCounters || refusal.Message != testCase.message {
				t.Fatalf("error = %v", err)
			}
		})
	}
	order, err := validateResetCounters([]string{CounterSkillPoints, CounterDailyBuys, CounterOccultTickets, CounterCampaignDaily})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{CounterDailyBuys, CounterCampaignDaily, CounterOccultTickets, CounterSkillPoints}
	if len(order) != len(want) {
		t.Fatalf("order = %v", order)
	}
	for index := range want {
		if order[index] != want[index] {
			t.Fatalf("order = %v, want %v", order, want)
		}
	}
}

func TestValidateResetCountersAcceptsTheWholeM12bVocabulary(t *testing.T) {
	names := []string{CounterSummonFree, CounterArenaDaily, CounterDormGlue, CounterIllusion, CounterWorldBoss, CounterOneOnOne, CounterTopFloor}
	order, err := validateResetCounters(names)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{CounterTopFloor, CounterOneOnOne, CounterWorldBoss, CounterIllusion, CounterDormGlue, CounterArenaDaily, CounterSummonFree}
	if len(order) != len(want) {
		t.Fatalf("order = %v", order)
	}
	for index := range want {
		if order[index] != want[index] {
			t.Fatalf("order = %v, want %v", order, want)
		}
	}
}

func TestResetCountersHandlerFreezesOneBulkTarget(t *testing.T) {
	store := &fakeStore{}
	commands := ResetCommands{Store: store, Directory: fakeRecipients{all: []identity.PlayerID{3, 1, 2}}}
	payload := map[string]any{
		"target":   map[string]any{"player_ids": []int64{9}},
		"counters": []string{CounterDailyBuys, CounterOccultTickets},
	}
	command := testResetCommand(t, "reset-single-player", payload)
	outcome, err := commands.resetHandler(context.Background(), testScope(), command)
	if err != nil {
		t.Fatal(err)
	}
	result := outcome.(GrantResult)
	if !result.Bulk || result.PlayerCount != 1 || result.State != StatePending {
		t.Fatalf("result = %+v", result)
	}
	target, found := store.rows["reset-single-player"]
	if !found {
		t.Fatal("no bulk target was frozen")
	}
	if target.ModuleCommand != CommandResetCounters || target.PlayerCount != 1 || target.PlayerIDs[0] != 9 {
		t.Fatalf("target = %+v", target)
	}
}

func TestResetCountersHandlerRefusesInvalidPayloadBeforeStoring(t *testing.T) {
	store := &fakeStore{}
	commands := ResetCommands{Store: store, Directory: fakeRecipients{}}
	for _, counters := range [][]string{{}, {"unknown"}, {CounterDailyBuys, CounterDailyBuys}} {
		payload := map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "counters": counters}
		_, err := commands.resetHandler(context.Background(), testScope(), testResetCommand(t, "reset-bad", payload))
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeResetCounters {
			t.Fatalf("counters %v: error = %v", counters, err)
		}
	}
	if len(store.rows) != 0 {
		t.Fatalf("invalid payloads stored rows = %v", store.rows)
	}
}

func TestResetCountersModuleMergesIntoPlayers(t *testing.T) {
	module := operator.MergeModules([]operator.Module{operator.PlayerModule()}, []operator.Module{ResetCommands{}.Module()})[0]
	bindResetModule(t, module)
}

func bindResetModule(t *testing.T, module operator.Module) {
	t.Helper()
	commands := ResetCommands{}
	bound, err := module.BindCommands(commands.Handlers())
	if err != nil {
		t.Fatal(err)
	}
	for _, command := range bound.Commands {
		if command.Name == CommandResetCounters {
			if command.Handler == nil {
				t.Fatal("reset command has no handler")
			}
			return
		}
	}
	t.Fatal("reset command is not declared by the merged player module")
}

type fakeResetOwner struct{ calls []string }

func (f *fakeResetOwner) ResetOperatorDailyBuys(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterDailyBuys+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorCampaignDaily(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterCampaignDaily+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorOccultTickets(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterOccultTickets+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorSkillPoints(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterSkillPoints+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorTopFloor(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterTopFloor+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorOneOnOne(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterOneOnOne+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorWorldBoss(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterWorldBoss+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorIllusion(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterIllusion+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorDormGlue(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterDormGlue+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorArenaDaily(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterArenaDaily+":"+key)
	return nil
}

func (f *fakeResetOwner) ResetOperatorSummonFree(_ context.Context, _ appi5.AdminOperator, _ identity.PlayerID, key string, _ operation.Context) error {
	f.calls = append(f.calls, CounterSummonFree+":"+key)
	return nil
}

func TestResetCountersRecipientActionRunsTheRequestedOwnersInTableOrder(t *testing.T) {
	owner := &fakeResetOwner{}
	applier := Applier{DailyBuys: owner, CampaignDaily: owner, TopFloor: owner, OneOnOne: owner, WorldBoss: owner, Illusion: owner, DormGlue: owner, ArenaDaily: owner, SummonFree: owner, OccultTickets: owner, SkillPoints: owner}
	payload := map[string]any{"counters": []string{CounterSkillPoints, CounterSummonFree, CounterArenaDaily, CounterTopFloor, CounterOccultTickets, CounterDailyBuys}}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	apply, permanent, err := applier.recipientAction(BulkTarget{ModuleCommand: CommandResetCounters, Payload: raw}, appi5.AdminOperator{ID: "root", ReasonCode: "reset"})
	if err != nil || permanent == nil {
		t.Fatalf("recipient action: %v", err)
	}
	if err = apply(context.Background(), operation.Context{}, 7, "target-key:7"); err != nil {
		t.Fatal(err)
	}
	want := []string{
		CounterDailyBuys + ":target-key:7:daily_buys",
		CounterTopFloor + ":target-key:7:top_floor",
		CounterArenaDaily + ":target-key:7:arena_daily",
		CounterSummonFree + ":target-key:7:summon_free",
		CounterOccultTickets + ":target-key:7:occult_tickets",
		CounterSkillPoints + ":target-key:7:skill_points",
	}
	if len(owner.calls) != len(want) {
		t.Fatalf("calls = %v", owner.calls)
	}
	for index := range want {
		if owner.calls[index] != want[index] {
			t.Fatalf("calls = %v, want %v", owner.calls, want)
		}
	}
}

func TestResetCountersRecipientActionRefusesUnknownNames(t *testing.T) {
	owner := &fakeResetOwner{}
	applier := Applier{DailyBuys: owner, ArenaDaily: owner}
	raw, _ := json.Marshal(map[string]any{"counters": []string{"not_a_counter"}})
	if _, _, err := applier.recipientAction(BulkTarget{ModuleCommand: CommandResetCounters, Payload: raw}, appi5.AdminOperator{}); err == nil {
		t.Fatal("an unknown counter name was accepted")
	}
}

func testResetCommand(t *testing.T, key string, payload any) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(CommandResetCounters, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "reset native", SemanticKey: key}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}
