package stockruntime

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/projection/lobby"
)

func TestPracticeWirePartitionMatchesQualifiedNonAutoMIDs(t *testing.T) {
	cases := []struct {
		mid  uint16
		kind practiceWireKind
		hero bool
	}{
		{124, practiceWireGet, true}, {125, practiceWireManual, true}, {126, practiceWireSave, true}, {128, practiceWireTicket, true},
		{129, practiceWireGet, false}, {130, practiceWireManual, false}, {131, practiceWireSave, false}, {133, practiceWireTicket, false},
	}
	for _, tc := range cases {
		kind, hero, ok := practiceWireMID(tc.mid)
		if !ok || kind != tc.kind || hero != tc.hero {
			t.Fatalf("mid=%d got kind=%v hero=%v ok=%v", tc.mid, kind, hero, ok)
		}
	}
	for _, mid := range []uint16{127, 132, 134} {
		if _, _, ok := practiceWireMID(mid); ok {
			t.Fatalf("MID%d must not be owned by CA6-3 non-AUTO dispatcher", mid)
		}
	}
}

func TestDecodePracticeManualWireIsExactAndTyped(t *testing.T) {
	req, err := decodePracticeWireRequest(125, map[string]any{
		"partner_id":    json.Number("42"),
		"locks":         []any{json.Number("1"), json.Number("0"), json.Number("1")},
		"practice_type": json.Number("3"),
	})
	if err != nil {
		t.Fatal(err)
	}
	if !req.Hero || req.Kind != practiceWireManual || req.ActorID != 42 || req.Locks != [3]int64{1, 0, 1} || req.PracticeType != 3 {
		t.Fatalf("decoded request=%+v", req)
	}

	pet, err := decodePracticeWireRequest(130, map[string]any{
		"pet_id":        int64(9),
		"locks":         []any{int64(0), int64(0), int64(0)},
		"practice_type": int64(1),
	})
	if err != nil {
		t.Fatal(err)
	}
	if pet.Hero || pet.ActorID != 9 {
		t.Fatalf("decoded Pet request=%+v", pet)
	}
}

func TestDecodePracticeAutoWireIsExactAndTyped(t *testing.T) {
	hero, err := decodePracticeAutoWireRequest(127, map[string]any{
		"partner_id":    json.Number("42"),
		"locks":         []any{json.Number("1"), json.Number("0"), json.Number("1")},
		"practice_type": json.Number("3"),
		"practice_num":  json.Number("10"),
		"save_types":    []any{json.Number("1"), json.Number("0"), json.Number("1"), json.Number("1")},
	})
	if err != nil {
		t.Fatal(err)
	}
	if !hero.Hero || hero.ActorID != 42 || hero.Locks != [3]int64{1, 0, 1} || hero.PracticeType != 3 || hero.PracticeNum != 10 || hero.SaveTypes != [4]int64{1, 0, 1, 1} {
		t.Fatalf("decoded Hero AUTO=%+v", hero)
	}
	pet, err := decodePracticeAutoWireRequest(132, map[string]any{
		"pet_id":        int64(9),
		"locks":         []any{int64(0), int64(0), int64(0)},
		"practice_type": int64(1),
		"practice_num":  int64(2),
		"save_types":    []any{int64(0), int64(0), int64(0), int64(1)},
	})
	if err != nil {
		t.Fatal(err)
	}
	if pet.Hero || pet.ActorID != 9 || pet.PracticeNum != 2 || pet.SaveTypes != [4]int64{0, 0, 0, 1} {
		t.Fatalf("decoded Pet AUTO=%+v", pet)
	}
	for _, mid := range []uint16{127, 132} {
		if _, _, ok := practiceWireMID(mid); ok {
			t.Fatalf("CA6-3 non-AUTO partition captured MID%d", mid)
		}
		if _, ok := practiceAutoMID(mid); !ok {
			t.Fatalf("CA6-4 AUTO partition missing MID%d", mid)
		}
	}
}

func TestDecodePracticeAutoWireRejectsNonStockSurface(t *testing.T) {
	base := func() map[string]any {
		return map[string]any{
			"partner_id": int64(1), "locks": []any{int64(1), int64(0), int64(0)},
			"practice_type": int64(2), "practice_num": int64(4),
			"save_types": []any{int64(1), int64(0), int64(0), int64(1)},
		}
	}
	mutations := []func(map[string]any){
		func(m map[string]any) { m["practice_num"] = int64(3) },
		func(m map[string]any) { m["save_types"] = []any{int64(0), int64(0), int64(0), int64(0)} },
		func(m map[string]any) { m["save_types"] = []any{int64(0), int64(0), int64(0), int64(1)} }, // locked Str not selected
		func(m map[string]any) { m["save_types"] = []any{int64(1), int64(0), int64(1)} },
		func(m map[string]any) { m["locks"] = []any{int64(1), int64(2), int64(0)} },
		func(m map[string]any) { m["extra"] = true },
	}
	for i, mutate := range mutations {
		m := base()
		mutate(m)
		if _, err := decodePracticeAutoWireRequest(127, m); err == nil {
			t.Fatalf("case %d unexpectedly accepted: %v", i, m)
		}
	}
	if _, err := decodePracticeAutoWireRequest(125, base()); err == nil {
		t.Fatal("non-AUTO MID accepted by AUTO decoder")
	}
}

func TestDecodePracticeWireRejectsInventedOrFutureSurface(t *testing.T) {
	bad := []struct {
		mid    uint16
		params map[string]any
	}{
		{124, map[string]any{"partner_id": int64(1)}},
		{125, map[string]any{"partner_id": int64(1), "locks": []any{int64(1), int64(0)}, "practice_type": int64(1)}},
		{125, map[string]any{"partner_id": int64(1), "locks": []any{int64(1), int64(2), int64(0)}, "practice_type": int64(1)}},
		{126, map[string]any{"partner_id": int64(1), "proposal_nonce": "invented"}},
		{128, map[string]any{"partner_id": int64(1), "item_id": int64(50001181)}},
		{127, map[string]any{}},
		{132, map[string]any{}},
		{134, map[string]any{"pet_id": int64(1)}},
	}
	for _, tc := range bad {
		if _, err := decodePracticeWireRequest(tc.mid, tc.params); err == nil {
			t.Fatalf("MID%d unexpectedly accepted params=%v", tc.mid, tc.params)
		}
	}
}

type fakePracticeGameplay struct {
	getInfo    apppractice.Info
	manual     apppractice.ManualResult
	save       apppractice.SaveResult
	ticket     apppractice.ManualResult
	auto       apppractice.AutoResult
	lastCmd    apppractice.ManualCommand
	lastAuto   apppractice.AutoCommand
	lastTarget apppractice.Target
	calls      []string
	err        error
}

func (f *fakePracticeGameplay) GetInfo(context.Context, identity.PlayerID, operation.Context) (apppractice.Info, error) {
	f.calls = append(f.calls, "get")
	return f.getInfo, f.err
}
func (f *fakePracticeGameplay) Manual(_ context.Context, _ identity.ActorContext, cmd apppractice.ManualCommand, _ operation.Context) (apppractice.ManualResult, error) {
	f.calls = append(f.calls, "manual")
	f.lastCmd = cmd
	return f.manual, f.err
}
func (f *fakePracticeGameplay) Save(_ context.Context, _ identity.ActorContext, target apppractice.Target, _ operation.Context) (apppractice.SaveResult, error) {
	f.calls = append(f.calls, "save")
	f.lastTarget = target
	return f.save, f.err
}
func (f *fakePracticeGameplay) Ticket(_ context.Context, _ identity.ActorContext, target apppractice.Target, _ operation.Context) (apppractice.ManualResult, error) {
	f.calls = append(f.calls, "ticket")
	f.lastTarget = target
	return f.ticket, f.err
}
func (f *fakePracticeGameplay) Auto(_ context.Context, _ identity.ActorContext, cmd apppractice.AutoCommand, _ operation.Context) (apppractice.AutoResult, error) {
	f.calls = append(f.calls, "auto")
	f.lastAuto = cmd
	return f.auto, f.err
}

func TestPracticeDispatcherProjectsGETAndPreservesMID124Telemetry(t *testing.T) {
	now := time.Unix(700, 0).UTC()
	tracker := capturedHTTPTracker(t)
	svc := &fakePracticeGameplay{getInfo: apppractice.Info{LastTime: 0, PracticeAttr: character.PracticeAttrs{}, Lock: []int64{}, Times: 0, BaseCrystal: 12, BaseMana: 34, BlessValue: 56}}
	d := PracticeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Tracker: tracker}
	r := env(124, nil, now)
	got := d.Dispatch(context.Background(), r)
	if got.HTTPStatus != 200 || got.Body["last_time"] != int64(0) || got.Body["base_crystal"] != int64(12) || got.Body["base_mana"] != int64(34) || got.Body["bless_value"] != int64(56) {
		t.Fatalf("%+v", got)
	}
	attrs, ok := got.Body["practice_attr"].([]any)
	if !ok || len(attrs) != 3 || attrs[0] != int64(0) || attrs[1] != int64(0) || attrs[2] != int64(0) {
		t.Fatalf("practice_attr=%#v", got.Body["practice_attr"])
	}
	ev := protocolEvidence(tracker)
	if len(ev) != 1 || ev[0].MID != 124 || ev[0].Kind != lobby.BootLegitTimer {
		t.Fatalf("events=%v", ev)
	}
}

func TestPracticeDispatcherManualSaveTicketTypedProjection(t *testing.T) {
	now := time.Unix(701, 0).UTC()
	svc := &fakePracticeGameplay{
		manual: apppractice.ManualResult{Info: apppractice.Info{BaseMana: 9}, AddAttr: apppractice.PracticeDelta{-1, 1, 0}},
		save:   apppractice.SaveResult{PracticeAttr: character.PracticeAttrs{10, 20, 30}},
		ticket: apppractice.ManualResult{Info: apppractice.Info{BaseCrystal: 8}, AddAttr: apppractice.PracticeDelta{1, 0, 1}},
	}
	d := PracticeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}

	manual := env(125, nil, now)
	manual.Envelope.Params["partner_id"] = int64(42)
	manual.Envelope.Params["locks"] = []any{int64(1), int64(0), int64(1)}
	manual.Envelope.Params["practice_type"] = int64(2)
	got := d.Dispatch(context.Background(), manual)
	if got.HTTPStatus != 200 || svc.lastCmd.Target != (apppractice.Target{Hero: true, ActorID: 42}) || svc.lastCmd.Locks != (apppractice.PracticeLocks{true, false, true}) || svc.lastCmd.Method != 2 {
		t.Fatalf("got=%+v cmd=%+v", got, svc.lastCmd)
	}
	if delta := got.Body["add_attr"].([]any); delta[0] != int64(-1) || delta[1] != int64(1) || delta[2] != int64(0) {
		t.Fatalf("delta=%v", delta)
	}

	save := env(131, nil, now)
	save.Envelope.Params["pet_id"] = int64(77)
	got = d.Dispatch(context.Background(), save)
	if got.HTTPStatus != 200 || svc.lastTarget != (apppractice.Target{Hero: false, ActorID: 77}) {
		t.Fatalf("got=%+v target=%+v", got, svc.lastTarget)
	}
	if attrs := got.Body["practice_attr"].([]any); attrs[0] != int64(10) || attrs[1] != int64(20) || attrs[2] != int64(30) {
		t.Fatalf("attrs=%v", attrs)
	}

	ticket := env(128, nil, now)
	ticket.Envelope.Params["partner_id"] = int64(88)
	got = d.Dispatch(context.Background(), ticket)
	if got.HTTPStatus != 200 || svc.lastTarget != (apppractice.Target{Hero: true, ActorID: 88}) {
		t.Fatalf("got=%+v target=%+v", got, svc.lastTarget)
	}
}

func TestPracticeDispatcherAutoProjectsExactStockBatchResult(t *testing.T) {
	now := time.Unix(702, 0).UTC()
	svc := &fakePracticeGameplay{auto: apppractice.AutoResult{
		Info:         apppractice.Info{BaseMana: 77, BlessValue: 88},
		AddAttrs:     []apppractice.PracticeDelta{{1, -1, 0}, {0, 1, 1}},
		IsAdds:       []int64{1, 0},
		PracticeAttr: character.PracticeAttrs{101, 99, 100},
	}}
	d := PracticeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := env(127, nil, now)
	r.Envelope.Params["partner_id"] = int64(42)
	r.Envelope.Params["locks"] = []any{int64(1), int64(0), int64(0)}
	r.Envelope.Params["practice_type"] = int64(2)
	r.Envelope.Params["practice_num"] = int64(2)
	r.Envelope.Params["save_types"] = []any{int64(1), int64(0), int64(0), int64(1)}
	got := d.Dispatch(context.Background(), r)
	if got.HTTPStatus != 200 || len(svc.calls) != 1 || svc.calls[0] != "auto" {
		t.Fatalf("got=%+v calls=%v", got, svc.calls)
	}
	wantCmd := apppractice.AutoCommand{
		Target: apppractice.Target{Hero: true, ActorID: 42},
		Locks:  apppractice.PracticeLocks{true, false, false},
		Method: 2, BatchSize: 2,
		Save: apppractice.AutoSavePredicates{true, false, false, true},
	}
	if svc.lastAuto != wantCmd {
		t.Fatalf("auto cmd=%+v want=%+v", svc.lastAuto, wantCmd)
	}
	if got.Body["info"].(map[string]any)["base_mana"] != int64(77) {
		t.Fatalf("info=%#v", got.Body["info"])
	}
	attrs := got.Body["add_attrs"].([]any)
	if len(attrs) != 2 || attrs[0].([]any)[0] != int64(1) || attrs[0].([]any)[1] != int64(-1) || attrs[1].([]any)[2] != int64(1) {
		t.Fatalf("add_attrs=%#v", attrs)
	}
	isAdds := got.Body["is_adds"].([]any)
	if len(isAdds) != 2 || isAdds[0] != int64(1) || isAdds[1] != int64(0) {
		t.Fatalf("is_adds=%#v", isAdds)
	}
	final := got.Body["practice_attr"].([]any)
	if final[0] != int64(101) || final[1] != int64(99) || final[2] != int64(100) {
		t.Fatalf("practice_attr=%#v", final)
	}
}

func TestPracticeDispatcherUnauthenticatedMID124DoesNotEmitLegitTimerEvidence(t *testing.T) {
	now := time.Unix(702, 0).UTC()
	tracker := capturedHTTPTracker(t)
	svc := &fakePracticeGameplay{}
	d := PracticeDispatcher{Service: svc, Tracker: tracker}
	r := env(124, nil, now)
	got := d.Dispatch(context.Background(), r)
	if got.HTTPStatus != 401 {
		t.Fatalf("status=%d body=%v", got.HTTPStatus, got.Body)
	}
	if len(svc.calls) != 0 {
		t.Fatalf("unauthenticated request reached gameplay service: %v", svc.calls)
	}
	if ev := protocolEvidence(tracker); len(ev) != 0 {
		t.Fatalf("unauthenticated MID124 emitted legit-timer evidence: %v", ev)
	}
}
