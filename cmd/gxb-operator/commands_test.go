package main

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

func TestPrintModuleTableShowsCommandsRoutesAndPlannedRows(t *testing.T) {
	var output bytes.Buffer
	printModuleTable(&output, operatoragent.AgentModules{Modules: []operator.Module{
		{ID: "ota", Title: "OTA", Commands: []operator.CommandSpec{{Name: "ota.build", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "build"}}},
		{ID: "mail", Title: "Mail", Planned: "O3"},
	}})
	table := output.String()
	for _, want := range []string{"MODULE", "ota.build", "live", "agent", "mail", "planned", "O3"} {
		if !strings.Contains(table, want) {
			t.Fatalf("table lacks %q:\n%s", want, table)
		}
	}
}

func TestWaitForOperationRetriesNotFound(t *testing.T) {
	var calls atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if calls.Add(1) <= 2 {
			http.NotFound(writer, request)
			return
		}
		writer.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(writer, `{"id":"`+strings.Repeat("a", 32)+`","kind":"ota.build","state":"DONE","steps":[]}`)
	}))
	defer server.Close()
	client := &agentClient{baseURL: server.URL, http: server.Client()}
	if err := waitForOperation(client, strings.Repeat("a", 32), 5*time.Second); err != nil {
		t.Fatal(err)
	}
}

func TestWaitForOperationHonoursTimeout(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(writer, `{"id":"`+strings.Repeat("a", 32)+`","kind":"ota.build","state":"RUNNING","steps":[]}`)
	}))
	defer server.Close()
	client := &agentClient{baseURL: server.URL, http: server.Client()}
	err := waitForOperation(client, strings.Repeat("a", 32), 10*time.Millisecond)
	if err == nil || !strings.Contains(err.Error(), "did not finish") {
		t.Fatalf("error = %v, want the bounded-timeout error", err)
	}
}

func TestRunBackupRestorePrintsPreviewAndNeedsYes(t *testing.T) {
	var requests []string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		requests = append(requests, request.Method+" "+request.URL.Path)
		writer.Header().Set("Content-Type", "application/json")
		switch {
		case request.Method == http.MethodGet && request.URL.Path == "/agent/v1/backup/restore-preview":
			_, _ = io.WriteString(writer, `{"id":"20260101T000000.000000000Z-manual","lost_accounts":3,"new_accounts":["a"],"new_account_count":1}`)
		case request.Method == http.MethodPost && request.URL.Path == "/agent/v1/backup/restore":
			_, _ = io.WriteString(writer, `{"id":"op","state":"DONE"}`)
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	client := &agentClient{baseURL: server.URL, http: server.Client()}
	id := "20260101T000000.000000000Z-manual"
	if err := runBackupRestore(client, []string{id, "--reason", "rollback"}); err == nil || !strings.Contains(err.Error(), "--yes") {
		t.Fatalf("error = %v", err)
	}
	if len(requests) != 1 || requests[0] != "GET /agent/v1/backup/restore-preview" {
		t.Fatalf("requests = %v", requests)
	}
	if err := runBackupRestore(client, []string{id, "--reason", "rollback", "--yes"}); err != nil {
		t.Fatal(err)
	}
	if len(requests) != 3 || requests[1] != "GET /agent/v1/backup/restore-preview" || requests[2] != "POST /agent/v1/backup/restore" {
		t.Fatalf("requests = %v", requests)
	}
}
