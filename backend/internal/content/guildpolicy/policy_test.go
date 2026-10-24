package guildpolicy

import "testing"

func TestBuiltinPolicySourceFactsAndIconAllowlist(t *testing.T) {
	b, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	p := b.Policy
	if p.CreateLevel != 32 || p.CreateCrystalCost != 500 || p.RenameCrystalCost != 500 || p.MemberCap != 50 || p.DeputyLimit != 5 || p.LeaderOfflineSeconds != 259200 || p.JoinLimitWindow != "ROLLING_7D_V1_POSTGRES_DECISION_TIME" || p.InviteSendWindow != "ROLLING_24H_V1_POSTGRES_DECISION_TIME" {
		t.Fatalf("unexpected policy: %+v", p)
	}
	if !p.AllowsIcon(20010001) || !p.AllowsIcon(50010043) || p.AllowsIcon(1) {
		t.Fatal("guild icon allowlist mismatch")
	}
	if p.SourceCurrentMessageSHA256 != "538875e1f791c1faf2c0ad113eb73b1d3a53d1c07d9738f4c70315fa59e00e1d" || p.SourceHistoricalMessageSHA256 != "c4b988d1b228caeb15dbf193a486ad81f2a10608575e6aa404f4d768cb757481" {
		t.Fatalf("message provenance mismatch: current=%s historical=%s", p.SourceCurrentMessageSHA256, p.SourceHistoricalMessageSHA256)
	}
	if b.Revision == "" {
		t.Fatal("revision required")
	}
}
