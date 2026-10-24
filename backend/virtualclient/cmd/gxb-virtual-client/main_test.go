package main

import (
	"slices"
	"testing"

	"gxb.local/backend/v2/virtualclient/client"
)

func TestExpandTaps(t *testing.T) {
	got := expandTaps("region_button,640x360*3,a*b")
	want := []string{"region_button", "640x360", "640x360", "640x360", "a*b"}
	if !slices.Equal(got, want) {
		t.Fatalf("expandTaps = %v, want %v", got, want)
	}
}

func TestLuaErrorFailures(t *testing.T) {
	if failures := luaErrorFailures(nil, nil); len(failures) != 0 {
		t.Fatalf("no errors, none expected: %v", failures)
	}
	if failures := luaErrorFailures([]string{"boom\nstack"}, nil); !slices.Equal(failures, []string{"unexpected Lua error: boom"}) {
		t.Fatalf("unexpected error: %v", failures)
	}
	if failures := luaErrorFailures([]string{"---\nLUA ERROR: app/x.lua:1: bad\nplatform: android"}, nil); !slices.Equal(failures, []string{"unexpected Lua error: app/x.lua:1: bad"}) {
		t.Fatalf("stock traceback: %v", failures)
	}
	if failures := luaErrorFailures([]string{"x vc-injected y"}, []string{"vc-injected"}); len(failures) != 0 {
		t.Fatalf("expected error matched: %v", failures)
	}
	if failures := luaErrorFailures(nil, []string{"vc-injected"}); len(failures) != 1 {
		t.Fatalf("missing expected error: %v", failures)
	}
}

func TestAnsweredOK(t *testing.T) {
	report := client.Report{Requests: []client.Exchange{{MID: 59, Status: 200, ErrorCode: 7}, {MID: 272, Status: 200}}}
	if answeredOK(report, 59) || !answeredOK(report, 272) || answeredOK(report, 1) {
		t.Fatal("answeredOK must want status 200 and error_code 0")
	}
}

func TestUnknownStep(t *testing.T) {
	if err := (run{}).step(nil, "jump:1"); err == nil {
		t.Fatal("unknown step kind accepted")
	}
}
