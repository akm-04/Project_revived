//go:build postgres

package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
)

// TestOTARoutesAnswer404WithoutRoot proves both routes are always mounted
// (finding 9): the catch-all answers 418, so a 404 must come from the OTA
// handler, not from an unregistered path.
func TestOTARoutesAnswer404WithoutRoot(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("/", http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusTeapot)
	}))
	registerOTARoutes(mux, &appotarelease.Serving{})
	for _, target := range []string{
		"/updates/assets/1.631.1-aaaaaaaaaaaa.zip.001",
		"/res/a.png." + strings.Repeat("a", 32),
	} {
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, httptest.NewRequest(http.MethodGet, target, nil))
		if response.Code != http.StatusNotFound {
			t.Fatalf("%s status=%d want 404", target, response.Code)
		}
	}
}
