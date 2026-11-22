package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

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
