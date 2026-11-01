package march

import (
	cd "gxb.local/backend/v2/internal/domain/combat"
	"testing"
)

func TestDailyAllowanceDoesNotResurrectOrDiscardProgress(t *testing.T) {
	r := Run{ResetDay: 100, ResetUsed: true, DrinkDay: 100, Drinks: 8, Passed: 8, Heroes: map[string]Status{"7": {Hero: 7, Health: 2}}}
	r.Refresh(101)
	if r.ResetUsed || r.Passed != 8 || r.Alive(7) || r.Drinks != 0 {
		t.Fatal(r)
	}
	r.ResetUsed = true
	r.Drinks = 2
	r.Refresh(99)
	if !r.ResetUsed || r.Drinks != 2 || r.ResetDay != 101 {
		t.Fatal("backwards clock recreated entitlement", r)
	}
}
func TestCarryPartialDamageAndChestAdmission(t *testing.T) {
	r := Run{Occurrence: "a", Pending: "a/1/1", Heroes: map[string]Status{}, Enemies: []Enemy{{Heroes: map[string]map[string]any{"3": {"hero_id": 3}}}}}
	loss := cd.Report{Allies: []cd.ActorStatus{{Player: 9, Identity: 7, HP: 12, MP: 300}}, Enemies: []cd.ActorStatus{{Identity: 3, HP: 8, MP: 200}}}
	if err := r.ApplyReport(loss, 0); err != nil {
		t.Fatal(err)
	}
	if r.Heroes["7"].HP != 12 || r.Enemies[0].Heroes["3"]["hp"] != float64(8) || r.Won {
		t.Fatal(r)
	}
	if r.AdvanceChest(1) == nil {
		t.Fatal("loss awarded a chest")
	}
	r.Pending = "a/1/2"
	win := loss
	win.Win = true
	win.Enemies = []cd.ActorStatus{{Identity: 3}}
	if err := r.ApplyReport(win, 0); err != nil {
		t.Fatal(err)
	}
	if r.AdvanceChest(2) == nil {
		t.Fatal("forged stage")
	}
	if err := r.AdvanceChest(1); err != nil {
		t.Fatal(err)
	}
	if r.AdvanceChest(1) == nil || r.Passed != 1 || r.LifetimeChests != 1 {
		t.Fatal("duplicate chest", r)
	}
}
func TestWinCannotKillEveryoneAndReagentCannotOverspend(t *testing.T) {
	r := Run{Pending: "x", Drinks: 1, Enemies: []Enemy{{Heroes: map[string]map[string]any{"3": {}}}}}
	report := cd.Report{Win: true, Allies: []cd.ActorStatus{{Identity: 7}}, Enemies: []cd.ActorStatus{{Identity: 3}}}
	if r.ApplyReport(report, 0) == nil {
		t.Fatal("all-dead win")
	}
	report.Allies[0].HP = 1
	if r.ApplyReport(report, 2) == nil {
		t.Fatal("reagent overdraft")
	}
}

func TestRejectedDomainReportDoesNotPartiallyChangeCarry(t *testing.T) {
	r := Run{Pending: "x", Heroes: map[string]Status{"7": {Hero: 7, HP: 20, MP: 300, Health: 1}}, Enemies: []Enemy{{Heroes: map[string]map[string]any{"3": {}}}}}
	bad := cd.Report{Allies: []cd.ActorStatus{{Identity: 7, HP: 1}}, Enemies: []cd.ActorStatus{{Identity: 99}}}
	if r.ApplyReport(bad, 0) == nil || r.Heroes["7"].HP != 20 || r.Pending != "x" {
		t.Fatal("invalid enemy partially changed carry", r)
	}
	r.Heroes["7"] = Status{Hero: 7, Health: 2}
	bad.Enemies[0].Identity = 3
	if r.ApplyReport(bad, 0) == nil || r.Alive(7) {
		t.Fatal("dead girl resurrected")
	}
}

func TestStockProjectionHasListEnemiesAndNestedOwnCarry(t *testing.T) {
	r := Run{Heroes: map[string]Status{"9": {Hero: 9, Health: 2}}, Enemies: []Enemy{{Heroes: map[string]map[string]any{"1": {"hero_id": 1}, "2": {"hero_id": 2}}}}}
	out := r.Projection()
	own := out["hero_status"].(map[string]any)
	if own["self_list"].(map[string]any)["9"].(Status).Health != 2 || own["rent_list"] == nil {
		t.Fatal("stock self_list/rent_list envelope", own)
	}
	enemies := out["enemies"].([]map[string]any)
	if rows := enemies[0]["heroes"].([]map[string]any); len(rows) != 2 || rows[1]["hero_id"] != 2 {
		t.Fatal("stock numeric enemy index", rows)
	}
}

func TestLoanRendersFlatAndDeadLoanCannotFight(t *testing.T) {
	loan := Loan{Player: 7, Unit: 9}
	if !loan.Fights(7, 9) || loan.Fights(7, 8) || loan.Fights(6, 9) {
		t.Fatal("loan identity")
	}
	rent := Run{Loan: &loan}.rentList()
	if rent["health"] != int64(0) {
		t.Fatal("a loan that has not fought renders at full health", rent)
	}
	loan.Health = 2
	if loan.Fights(7, 9) {
		t.Fatal("dead loan fights")
	}
}
