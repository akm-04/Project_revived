package operatorapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	appclientlog "gxb.local/backend/v2/internal/application/clientlog"
)

type fakeLogsReads struct {
	filter appclientlog.JournalFilter
}

func (fake *fakeLogsReads) Timeline(_ context.Context, filter appclientlog.JournalFilter) (appclientlog.JournalPage, error) {
	fake.filter = filter
	return appclientlog.JournalPage{Entries: []appclientlog.JournalEntry{}}, nil
}

func (fake *fakeLogsReads) Tail(_ context.Context, filter appclientlog.JournalFilter) (appclientlog.JournalTail, error) {
	fake.filter = filter
	return appclientlog.JournalTail{Entries: []appclientlog.JournalEntry{}, NextCursor: "next"}, nil
}

func TestLogsTimelineReadParsesTheBoundedFilter(t *testing.T) {
	fake := &fakeLogsReads{}
	handler := Handler{Token: "secret", Reads: map[string]Read{"logs.timeline": LogsTimeline(fake)}}
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/operator/v1/reads/logs.timeline?uid=acct-1&player_id=9&from=2026-11-01T00:00:00Z&outcome=CLIENT_ERROR&mid=241&limit=10", nil)
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer secret")
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", recorder.Code, recorder.Body)
	}
	if fake.filter.AccountUID != "acct-1" || fake.filter.PlayerID != 9 || fake.filter.MID != 241 || fake.filter.Limit != 10 {
		t.Fatalf("filter = %+v", fake.filter)
	}
	if len(fake.filter.Outcomes) != 1 || fake.filter.Outcomes[0] != "CLIENT_ERROR" {
		t.Fatalf("outcomes = %v", fake.filter.Outcomes)
	}
	if fake.filter.From == nil || !fake.filter.From.Equal(time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("from = %v", fake.filter.From)
	}
}

func TestLogsReadsRefuseBadFilters(t *testing.T) {
	fake := &fakeLogsReads{}
	handler := Handler{Token: "secret", Reads: map[string]Read{"logs.timeline": LogsTimeline(fake), "logs.tail": LogsTail(fake)}}
	for _, path := range []string{
		"/operator/v1/reads/logs.timeline?limit=500",
		"/operator/v1/reads/logs.timeline?player_id=0",
		"/operator/v1/reads/logs.timeline?outcome=NOPE",
		"/operator/v1/reads/logs.timeline?cursor=nonsense",
		"/operator/v1/reads/logs.tail?level=debug",
	} {
		recorder := httptest.NewRecorder()
		request := httptest.NewRequest(http.MethodGet, path, nil)
		request.RemoteAddr = "127.0.0.1:5000"
		request.Header.Set("Authorization", "Bearer secret")
		handler.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusConflict {
			t.Fatalf("%s status = %d body = %s", path, recorder.Code, recorder.Body)
		}
		var refusal struct {
			ErrorCode string `json:"error_code"`
		}
		_ = json.Unmarshal(recorder.Body.Bytes(), &refusal)
		if !strings.HasPrefix(refusal.ErrorCode, "OPERATOR_") {
			t.Fatalf("%s refusal = %s", path, recorder.Body)
		}
	}
}

func TestLogsTimelineLevelMapsToOutcomes(t *testing.T) {
	fake := &fakeLogsReads{}
	handler := Handler{Token: "secret", Reads: map[string]Read{"logs.timeline": LogsTimeline(fake)}}
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/operator/v1/reads/logs.timeline?level=error&uid=acct-1", nil)
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Authorization", "Bearer secret")
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", recorder.Code, recorder.Body)
	}
	if len(fake.filter.Outcomes) != 2 || fake.filter.Outcomes[0] != "CLIENT_ERROR" || fake.filter.Outcomes[1] != "SERVER_ERROR" {
		t.Fatalf("outcomes = %v", fake.filter.Outcomes)
	}
}
