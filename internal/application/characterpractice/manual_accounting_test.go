package characterpractice

import (
	"encoding/json"
	"errors"
	"math"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func accountingRoot(at time.Time) Root {
	return Root{PlayerID: identity.PlayerID(7), BlessRemaining: 100, BlessCapacityAtEpoch: 100, StateVersion: 3, CreatedAt: at.Add(-24 * time.Hour), UpdatedAt: at.Add(-time.Hour)}
}

func accountingFacts() PolicyFacts {
	return PolicyFacts{UnlockLevel: 90, AttrCap: 200, FreeIntervalSeconds: 79200, LegendaryVIPMin: 5, TicketItemID: 50001181, TicketAdd: character.PracticeAttrs{1, 1, 1}}
}

func TestManualAccountingFreeAndPaidNoLocks(t *testing.T) {
	now := time.Unix(1_800_000_000, 0).UTC()
	root := accountingRoot(now)
	root.BaseMana, root.BaseCrystal = 123, 456
	method := Method{ID: 1, CurrencyType: 1, BaseCost: 20000}
	free, err := planManualAccounting(root, method, Method{}, nil, 0, accountingFacts(), now)
	if err != nil {
		t.Fatal(err)
	}
	if free.TotalCost != 0 || !free.ConsumedFree || free.NextRoot.FreeLastConsumedAt == nil || !free.NextRoot.FreeLastConsumedAt.Equal(now) || free.NextRoot.BaseMana != 123 || free.NextRoot.BaseCrystal != 456 || free.NextRoot.BlessRemaining != 100 {
		t.Fatalf("free=%+v next=%+v", free, free.NextRoot)
	}

	last := now.Add(-time.Hour)
	root.FreeLastConsumedAt = &last
	paid, err := planManualAccounting(root, method, Method{}, nil, 0, accountingFacts(), now)
	if err != nil {
		t.Fatal(err)
	}
	if paid.TotalCost != 20000 || paid.ConsumedFree || paid.NextRoot.FreeLastConsumedAt == nil || !paid.NextRoot.FreeLastConsumedAt.Equal(last) || paid.NextRoot.BaseMana != 123 || paid.NextRoot.BaseCrystal != 456 {
		t.Fatalf("paid=%+v next=%+v", paid, paid.NextRoot)
	}
}

func TestManualAccountingLockRecurrencePersistsOnlyChargedFamily(t *testing.T) {
	now := time.Unix(1_800_000_000, 0).UTC()
	root := accountingRoot(now)
	root.BaseMana, root.BaseCrystal = 0, 91
	row := LockCost{Count: 1, ManaStep: 70000, CrystalStep: 15, BlessCost: 10}
	got, err := planManualAccounting(root, Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, Method{}, &row, 1, accountingFacts(), now)
	if err != nil {
		t.Fatal(err)
	}
	if got.TotalCost != 70000 || got.NextRoot.BaseMana != 70000 || got.NextRoot.BaseCrystal != 91 || got.NextRoot.BlessRemaining != 90 {
		t.Fatalf("got=%+v next=%+v", got, got.NextRoot)
	}

	// A second one-lock roll inside the 22h window starts from the persisted
	// running base: new base=140000; surcharge=140000; method base=20000.
	last := now
	root = got.NextRoot
	root.FreeLastConsumedAt = &last
	got2, err := planManualAccounting(root, Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, Method{}, &row, 1, accountingFacts(), now.Add(time.Minute))
	if err != nil {
		t.Fatal(err)
	}
	if got2.TotalCost != 160000 || got2.NextRoot.BaseMana != 140000 || got2.NextRoot.BaseCrystal != 91 || got2.NextRoot.BlessRemaining != 80 {
		t.Fatalf("got2=%+v next=%+v", got2, got2.NextRoot)
	}
}

func TestManualAccountingThreeLockLegendaryUsesAdvancedMethodBase(t *testing.T) {
	now := time.Unix(1_800_000_000, 0).UTC()
	root := accountingRoot(now)
	last := now.Add(-time.Hour)
	root.FreeLastConsumedAt = &last
	root.BaseCrystal = 0
	row := LockCost{Count: 3, ManaStep: 200000, CrystalStep: 40, BlessCost: 60}
	legendary := Method{ID: 3, CurrencyType: 2, BaseCost: 100, VIPMin: 5}
	advanced := Method{ID: 2, CurrencyType: 2, BaseCost: 50, VIPMin: 0}
	got, err := planManualAccounting(root, legendary, advanced, &row, 3, accountingFacts(), now)
	if err != nil {
		t.Fatal(err)
	}
	// running crystal bases are 40,80,120 => surcharge 240, plus substituted 50.
	if got.TotalCost != 290 || got.NextRoot.BaseCrystal != 120 || got.NextRoot.BlessRemaining != 40 || got.NextRoot.BaseMana != 0 {
		t.Fatalf("got=%+v next=%+v", got, got.NextRoot)
	}
}

func TestManualAccountingBlessBoundaryAndOverflow(t *testing.T) {
	now := time.Unix(1_800_000_000, 0).UTC()
	row := LockCost{Count: 1, ManaStep: 70000, CrystalStep: 15, BlessCost: 10}
	root := accountingRoot(now)
	root.BlessRemaining = 10 // equality is admitted by source guard
	got, err := planManualAccounting(root, Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, Method{}, &row, 1, accountingFacts(), now)
	if err != nil || got.NextRoot.BlessRemaining != 0 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	root = accountingRoot(now)
	root.BlessRemaining = 9
	if _, err := planManualAccounting(root, Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, Method{}, &row, 1, accountingFacts(), now); !errors.Is(err, ErrPracticeBless) {
		t.Fatalf("err=%v", err)
	}
	root = accountingRoot(now)
	root.BaseMana = math.MaxInt64
	if _, err := planManualAccounting(root, Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, Method{}, &row, 1, accountingFacts(), now); err == nil {
		t.Fatal("overflow accepted")
	}
}

func TestTicketDeltaSaturatesAndRequiresQualifiedPlusOne(t *testing.T) {
	delta, next, err := ticketDelta(character.PracticeAttrs{0, 199, 200}, character.PracticeAttrs{1, 1, 1})
	if err != nil {
		t.Fatal(err)
	}
	if delta != (PracticeDelta{1, 1, 0}) || next != (character.PracticeAttrs{1, 200, 200}) {
		t.Fatalf("delta=%v next=%v", delta, next)
	}
	if _, _, err := ticketDelta(character.PracticeAttrs{0, 0, 0}, character.PracticeAttrs{1, 2, 1}); err == nil {
		t.Fatal("non-qualified ticket delta accepted")
	}
}

func TestManualReceiptReplaysNegativeEffectiveDelta(t *testing.T) {
	payload := manualReceiptResult{Info: Info{PracticeAttr: character.PracticeAttrs{}}, AddAttr: PracticeDelta{-1, 1, 0}, ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", RollPolicy: RollPolicyV1}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	got, err := decodeManualReceipt(receipt.Receipt{ResultSchema: manualReceiptSchema, ResultPayload: raw}, manualReceiptSchema)
	if err != nil {
		t.Fatal(err)
	}
	if got.AddAttr != (PracticeDelta{-1, 1, 0}) || !got.Replayed {
		t.Fatalf("got=%+v", got)
	}
}
