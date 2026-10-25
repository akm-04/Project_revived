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

func TestReloginReportRetainsEarlierErrorsAndRequests(t *testing.T) {
	r := mergeReports([]client.Report{{Requests: []client.Exchange{{MID: 118, Status: 200}}, LuaErrors: []string{"first login failure"}, Proxies: 10, Missing: map[string]float64{"x": 2}}, {Requests: []client.Exchange{{MID: 122, Status: 200}}, Proxies: 20, Missing: map[string]float64{"x": 3}}})
	if !answeredOK(r, 118) || !answeredOK(r, 122) || len(luaErrorFailures(r.LuaErrors, nil)) != 1 || r.Proxies != 30 || r.Missing["x"] != 5 {
		t.Fatalf("lost session evidence: %+v", r)
	}
}
