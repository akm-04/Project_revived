package guildrentalpolicy

import "testing"

func TestBuiltinRentalPolicy(t *testing.T) {
	builtin, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	p := builtin.Policy
	if p.Money.GuildSharePercent != 0 {
		t.Fatal("guild share must be zero", p.Money.GuildSharePercent)
	}
	if len(p.VIPLimits) != 16 {
		t.Fatal("vip limits must cover 0-15")
	}
	for index, row := range p.VIPLimits {
		if row.VIP != int64(index) || row.Lend <= 0 {
			t.Fatal("vip row", index, row)
		}
	}
	if p.StarCap(1) != 2 || p.StarCap(2) != 2 || p.StarCap(24) != 2 || p.StarCap(11) != 2 {
		t.Fatal("borrow modes must stay readable with a 2-star cap", p.StarCap(1), p.StarCap(24))
	}
	if p.StarCap(79) != 0 || p.StarCap(5) != 0 {
		t.Fatal("gods trial and champion are uncapped rows", p.StarCap(79), p.StarCap(5))
	}
	rules := p.ModeRules()
	if !rules[1].Enabled || rules[79].Enabled {
		t.Fatal("mode rules", rules[1], rules[79])
	}
	bad := p
	bad.Money.GuildSharePercent = 1
	if bad.Validate() == nil {
		t.Fatal("a nonzero guild share must not validate")
	}
}
