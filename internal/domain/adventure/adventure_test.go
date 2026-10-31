package adventure

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func testContext() operation.Context {
	var seed [32]byte
	for index := range seed {
		seed[index] = byte(index + 1)
	}
	return operation.Context{StartedAt: time.Unix(1700000000, 0).UTC(), EntropySeed: seed}
}

func testPlayer() identity.PlayerID { return identity.PlayerID(7001) }

func fixedEvent(t *testing.T, id int64) Event {
	t.Helper()
	event, ok := Profile(id)
	if !ok {
		t.Fatalf("event %d missing", id)
	}
	return event
}

func TestTriggerMapOnlyUsesFactKindsWithProducers(t *testing.T) {
	cases := map[string]int64{
		SweepFactKind:    EventDefense,
		BattleFactKind:   EventBattle,
		SummonFactKind:   EventSummon,
		IllusionFactKind: EventIllusion,
	}
	for kind, want := range cases {
		event, ok := EventForFactKind(kind)
		if !ok || event.ID != want {
			t.Fatalf("kind %s -> %+v %v", kind, event, ok)
		}
	}
	for _, kind := range []string{"ADD_FAVOR", "STORE_SPEND", "FAVOR", "SHOP"} {
		if _, ok := EventForFactKind(kind); ok {
			t.Fatalf("kind %s must not fire before its producer", kind)
		}
	}
}

func TestRollIsDeterministicPerFactKey(t *testing.T) {
	op := testContext()
	event := fixedEvent(t, EventDefense)
	first, err := Roll(event, "campaign/sweep/1", op)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Roll(event, "campaign/sweep/1", op)
	if err != nil || first != second {
		t.Fatalf("roll not stable: %v %v", first, second)
	}
	sure, err := Roll(Event{Rate: 100}, "any", op)
	if err != nil || !sure {
		t.Fatal("rate 100 must always trigger", err)
	}
	never, err := Roll(Event{Rate: 0}, "any", op)
	if err != nil || never {
		t.Fatal("rate 0 must never trigger", err)
	}
	triggered := 0
	for index := 0; index < 1000; index++ {
		ok, err := Roll(event, fmt.Sprintf("fact-%d", index), op)
		if err != nil {
			t.Fatal(err)
		}
		if ok {
			triggered++
		}
	}
	if triggered == 0 || triggered > 200 {
		t.Fatalf("rate 3 draw out of bounds: %d/1000", triggered)
	}
	if _, err := Roll(event, "", op); !errors.Is(err, ErrInvalid) {
		t.Fatal("empty fact key must refuse")
	}
}

func TestOccurrenceLifetimeAndOneActivePerType(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	event := fixedEvent(t, EventDefense)
	occurrence, err := NewOccurrence("campaign/sweep/1", testPlayer(), event, at)
	if err != nil {
		t.Fatal(err)
	}
	if want := at.Add(10800 * time.Second); !occurrence.EndTime.Equal(want) {
		t.Fatalf("end %s want %s", occurrence.EndTime, want)
	}
	if err := occurrence.Validate(); err != nil {
		t.Fatal(err)
	}
	if !occurrence.Active(at) || !occurrence.Active(at.Add(10799*time.Second)) {
		t.Fatal("occurrence must be active before its end")
	}
	if occurrence.Active(at.Add(10800 * time.Second)) {
		t.Fatal("occurrence must expire at its end")
	}
	if err := RequireActive(occurrence, at.Add(10800*time.Second)); !errors.Is(err, ErrExpired) {
		t.Fatalf("expired read: %v", err)
	}
	occurrences := []Occurrence{occurrence}
	if CanTrigger(occurrences, event, at.Add(time.Second)) {
		t.Fatal("a second active occurrence of the same type must refuse")
	}
	if !CanTrigger(occurrences, event, at.Add(10800*time.Second)) {
		t.Fatal("an expired occurrence must allow a new trigger")
	}
	other := fixedEvent(t, EventBattle)
	if !CanTrigger(occurrences, other, at.Add(time.Second)) {
		t.Fatal("different event types are independent")
	}
	if _, ok := ActiveOfType(occurrences, EventDefense, at.Add(time.Second)); !ok {
		t.Fatal("active type must be found")
	}
	if types := ActiveTypes(occurrences, at.Add(time.Second)); len(types) != 1 {
		t.Fatalf("active types %v", types)
	}
	if !occurrence.Finish(at.Add(time.Minute)) {
		t.Fatal("first finish must change the occurrence")
	}
	if occurrence.Finish(at.Add(2 * time.Minute)) {
		t.Fatal("second finish must be a no-op")
	}
	if occurrence.Active(at.Add(time.Second)) {
		t.Fatal("a finished occurrence must not stay active")
	}
}

func TestOccurrenceSpecialData(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	cases := map[int64]func(int64) bool{
		EventShop:     func(id int64) bool { return id >= 1001 && id <= 1007 },
		EventSummon:   func(id int64) bool { return id >= 100001 && id <= 100072 },
		EventIllusion: func(id int64) bool { return id == IllusionHiddenBoss },
		EventDefense:  func(id int64) bool { return id == 0 },
	}
	for eventType, valid := range cases {
		occurrence, err := NewOccurrence("fact/"+fmt.Sprint(eventType), testPlayer(), fixedEvent(t, eventType), at)
		if err != nil {
			t.Fatal(err)
		}
		if !valid(occurrence.SpecialData) {
			t.Fatalf("event %d special data %d", eventType, occurrence.SpecialData)
		}
	}
}

func TestDefenseTriesPerPosition(t *testing.T) {
	var progress DefenseProgress
	position := int64(2)
	for try := int64(1); try <= DefenseTriesPerPosition; try++ {
		var err error
		progress, err = progress.Admit(position)
		if err != nil {
			t.Fatalf("try %d: %v", try, err)
		}
		if !progress.CanChallenge(position) && try < DefenseTriesPerPosition {
			t.Fatalf("try %d ended the counter early", try)
		}
	}
	if progress.CanChallenge(position) {
		t.Fatal("counter must be exhausted after three tries")
	}
	if _, err := progress.Admit(position); !errors.Is(err, ErrRefused) {
		t.Fatalf("fourth try: %v", err)
	}
	if _, err := progress.Admit(0); !errors.Is(err, ErrInvalid) {
		t.Fatalf("position zero: %v", err)
	}
	if progress.Tries[0] != 0 || progress.Tries[2] != 0 {
		t.Fatal("other positions must stay untouched")
	}
	if err := progress.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestSoloClampAndWinRule(t *testing.T) {
	cases := []struct {
		star, damage, poolHP, poolHurt, wantStar, wantDamage int64
	}{
		{star: 2, damage: 50, poolHP: 100, poolHurt: 10, wantStar: 1, wantDamage: 50},
		{star: -1, damage: 90, poolHP: 100, poolHurt: 10, wantStar: 0, wantDamage: 90},
		{star: 1, damage: 500, poolHP: 100, poolHurt: 10, wantStar: 1, wantDamage: 90},
		{star: 1, damage: 5, poolHP: 100, poolHurt: 100, wantStar: 1, wantDamage: 0},
		{star: 1, damage: -5, poolHP: 100, poolHurt: 0, wantStar: 1, wantDamage: 0},
	}
	for _, item := range cases {
		star, damage := ClampSolo(item.star, item.damage, item.poolHP, item.poolHurt)
		if star != item.wantStar || damage != item.wantDamage {
			t.Fatalf("clamp %+v got %d/%d", item, star, damage)
		}
	}
	if IsWin(0) || !IsWin(1) || !IsWin(3) {
		t.Fatal("is_win must be star>0")
	}
}

func TestDefenseClampAndRoomState(t *testing.T) {
	star, damage := ClampDefense(9, DefenseDamageCap+1)
	if star != DefenseMaxStar || damage != DefenseDamageCap {
		t.Fatalf("clamp %d/%d", star, damage)
	}
	if star, damage = ClampDefense(-1, -1); star != 0 || damage != 0 {
		t.Fatalf("clamp negative %d/%d", star, damage)
	}
	var state RoomState
	state.SetTries(7001, []int64{1, 0, 3})
	if got := state.TriesOf(7001); got[0] != 1 || got[2] != 3 {
		t.Fatalf("tries %v", got)
	}
	state.SetPick(7001, RoomPick{Heroes: []int64{11, 12}, PetID: 21})
	state.AddPush(2, 7001, true, map[string]any{"room_id": int64(5)})
	state.AddPush(3, 7001, false, map[string]any{"player_id": int64(7001)})
	raw, err := state.Encode()
	if err != nil {
		t.Fatal(err)
	}
	loaded, err := LoadRoomState(raw)
	if err != nil {
		t.Fatal(err)
	}
	if loaded.Pick(7001).PetID != 21 || len(loaded.Pushes) != 2 || loaded.Pushes[1].Sequence != 2 || loaded.Pushes[1].All {
		t.Fatalf("room state %+v", loaded)
	}
	if loaded.Invited(7001) {
		t.Fatal("no invite was added")
	}
}

func TestGeneratedCatalogPricesAreRecomputed(t *testing.T) {
	raw, err := os.ReadFile("../../content/builtin/generated/adventure_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog Catalog
	if err := json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if price, ok := catalog.ShopPrice(1007); !ok || price != 300 {
		t.Fatalf("shop price %d %v", price, ok)
	}
	if price, ok := catalog.ShopPrice(9999); ok || price != 0 {
		t.Fatal("unknown shop id must refuse")
	}
	if price, ok := catalog.CardPrice(100001); !ok || price != 88 {
		t.Fatalf("card price %d %v", price, ok)
	}
	if price, ok := catalog.CardPrice(100017); !ok || price != 388 {
		t.Fatalf("card price %d %v", price, ok)
	}
	if price, ok := catalog.CardPrice(1); ok || price != 0 {
		t.Fatal("unknown card id must refuse")
	}
	gift, ok := catalog.Gift(90030021)
	if !ok || len(gift.Items) != 4 || gift.Items[0] != 50001002 || gift.ItemNums[0] != 10 {
		t.Fatalf("gift %+v %v", gift, ok)
	}
	if _, ok := catalog.Gift(1); ok {
		t.Fatal("unknown gift id must refuse")
	}
	drift := catalog
	drift.Events = append([]Event(nil), catalog.Events...)
	drift.Events[0].Rate = 4
	if !errors.Is(drift.Validate(), ErrUnavailable) {
		t.Fatal("rating drift must refuse the catalog")
	}
}
