package privilege

import "testing"

func TestDecideGrantFirstBonusAndVIPDiamondOnly(t *testing.T) {
	p := ChargeProduct{ID: 80001002, Diamond: 10000, FirstExtraDiamond: 10000}
	first, e := DecideGrant(p, 0, ChargeTuning{}, false)
	if e != nil || first.Crystal != 20000 || first.VIPXP != 10000 {
		t.Fatalf("first=%+v e=%v", first, e)
	}
	second, e := DecideGrant(p, 1, ChargeTuning{}, false)
	if e != nil || second.Crystal != 10000 || second.VIPXP != 10000 {
		t.Fatalf("second=%+v e=%v", second, e)
	}
}

func TestDecideGrantRefusesProductGrantingNothing(t *testing.T) {
	if _, e := DecideGrant(ChargeProduct{ID: 80001028}, 0, ChargeTuning{}, false); e != ErrChargeRefused {
		t.Fatalf("e=%v", e)
	}
}

func TestDecideGrantTuning(t *testing.T) {
	p := ChargeProduct{ID: 7, Diamond: 100}
	if _, e := DecideGrant(p, 0, ChargeTuning{Version: 1, Mode: TuningDisabled}, true); e != ErrChargeRefused {
		t.Fatalf("disabled e=%v", e)
	}
	crystal := int64(5)
	tuned, e := DecideGrant(p, 0, ChargeTuning{Version: 1, Mode: TuningGrant, Products: map[string]ChargeOverride{"7": {Crystal: &crystal}}}, true)
	if e != nil || tuned.Crystal != 5 || tuned.VIPXP != 100 {
		t.Fatalf("tuned=%+v e=%v", tuned, e)
	}
	invalid, e := DecideGrant(p, 0, ChargeTuning{Version: 0, Mode: TuningDisabled}, true)
	if e != nil || invalid.Crystal != 100 {
		t.Fatalf("invalid overlay must keep source: %+v e=%v", invalid, e)
	}
}

func TestCardsStackDaysAndLeftDaysRoundUp(t *testing.T) {
	const now = int64(1000000)
	c := Cards{}.Extended(CardMonth, 30, now)
	if c.MonthCardStart != now || c.MonthCardEnd != now+30*secondsPerDay {
		t.Fatalf("new=%+v", c)
	}
	c = c.Extended(CardMonth, 30, now+1)
	if c.MonthCardStart != now || c.MonthCardEnd != now+60*secondsPerDay {
		t.Fatalf("stacked=%+v", c)
	}
	if LeftDays(now+1, now) != 1 || LeftDays(now, now) != 0 || LeftDays(now+secondsPerDay, now) != 1 {
		t.Fatal("left days")
	}
	c = Cards{MonthCardStart: 1, MonthCardEnd: 2}.Extended(CardMonth, 1, now)
	if c.MonthCardStart != now || c.MonthCardEnd != now+secondsPerDay {
		t.Fatalf("expired=%+v", c)
	}
}
