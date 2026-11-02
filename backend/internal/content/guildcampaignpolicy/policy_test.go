package guildcampaignpolicy

import "testing"

func TestBuiltinPolicyLoads(t *testing.T) {
	builtin, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	if builtin.Revision == "" || builtin.Policy.AttemptsPerChapterDay != 2 || builtin.Policy.ApplicationsPerDay != 4 {
		t.Fatalf("policy=%+v revision=%q", builtin.Policy, builtin.Revision)
	}
	if !builtin.Policy.InRestWindow(builtin.Policy.RestSecondsOfDay[0]) || builtin.Policy.InRestWindow(builtin.Policy.RestSecondsOfDay[1]) {
		t.Fatal("rest window is half-open")
	}
	if !builtin.Policy.NoticeMail.Enabled || builtin.Policy.NoticeMail.OpenTitle == "" {
		t.Fatal("notice mail missing")
	}
}
