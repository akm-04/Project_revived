package agentapi

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func TestDashboardPingsReadAnswersFromTheSampler(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	handler.Pings = operatoragent.NewPingSampler(operatoragent.PingPlan{
		Environment: func(string) string { return "" },
		ServerURL:   func() (string, string) { return "", "" },
	}, time.Now)

	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/dashboard.pings", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var report operatoragent.PingReport
	if err := json.Unmarshal(recorder.Body.Bytes(), &report); err != nil {
		t.Fatal(err)
	}
	if len(report.Targets) != 1 || report.Targets[0].ID != "internet" || report.Targets[0].Address != "1.1.1.1:443" {
		t.Fatalf("targets = %+v", report.Targets)
	}
	if len(report.Omitted) == 0 {
		t.Fatalf("no omission reason for the unknown targets: %+v", report)
	}
}

func TestDashboardPingsReadRefusesWhenTheSamplerIsMissing(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	handler.Pings = nil
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/dashboard.pings", session, "")
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
}
