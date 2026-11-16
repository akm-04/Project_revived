package main

import "testing"

func TestParseRevokeSessionArgs(t *testing.T) {
	sessionUUID := "11111111-1111-1111-1111-111111111111"
	for name, test := range map[string]struct {
		arguments   []string
		wantPlayer  int64
		wantSession string
		wantErr     bool
	}{
		"player":              {arguments: []string{"-player", "100001", "-operator", "operator-7", "-reason", "support"}, wantPlayer: 100001},
		"session":             {arguments: []string{"-session", sessionUUID, "-operator", "operator-7", "-reason", "support"}, wantSession: sessionUUID},
		"neither":             {arguments: []string{"-operator", "operator-7", "-reason", "support"}, wantErr: true},
		"both":                {arguments: []string{"-player", "100001", "-session", sessionUUID, "-operator", "operator-7", "-reason", "support"}, wantErr: true},
		"missing operator":    {arguments: []string{"-player", "100001", "-reason", "support"}, wantErr: true},
		"missing reason":      {arguments: []string{"-player", "100001", "-operator", "operator-7"}, wantErr: true},
		"blank operator":      {arguments: []string{"-player", "100001", "-operator", "  ", "-reason", "support"}, wantErr: true},
		"bad session uuid":    {arguments: []string{"-session", "not-a-uuid", "-operator", "operator-7", "-reason", "support"}, wantErr: true},
		"zero player":         {arguments: []string{"-player", "0", "-operator", "operator-7", "-reason", "support"}, wantErr: true},
		"positional argument": {arguments: []string{"-player", "100001", "-operator", "operator-7", "-reason", "support", "extra"}, wantErr: true},
		"unknown flag":        {arguments: []string{"-player", "100001", "-operator", "operator-7", "-reason", "support", "-nope"}, wantErr: true},
	} {
		t.Run(name, func(t *testing.T) {
			got, err := parseRevokeSessionArgs(test.arguments)
			if test.wantErr {
				if err == nil {
					t.Fatalf("arguments %v accepted: %#v", test.arguments, got)
				}
				return
			}
			if err != nil {
				t.Fatalf("arguments %v: %v", test.arguments, err)
			}
			sessionMatches := (test.wantSession == "" && got.Session.UUID().IsZero()) || got.Session.UUID().String() == test.wantSession
			if int64(got.Player) != test.wantPlayer || !sessionMatches || got.Operator != "operator-7" || got.Reason != "support" {
				t.Fatalf("parsed=%#v want player=%d session=%s", got, test.wantPlayer, test.wantSession)
			}
		})
	}
}
