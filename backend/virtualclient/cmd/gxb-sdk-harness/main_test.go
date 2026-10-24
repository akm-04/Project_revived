package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"gxb.local/backend/v2/virtualclient/provision"
)

func TestLoginEnvelopeAndPackageInfoReuse(t *testing.T) {
	issued := 0
	server := httptest.NewServer(newHandler(func() (provision.Session, error) {
		issued++
		return provision.Session{AccountID: "0123456789abcdef", SID: "sid-1", LoginToken: "token-1"}, nil
	}))
	defer server.Close()

	response, err := http.PostForm(server.URL+"/server/mobile_api_new", url.Values{"payload": {`{"mid":"65284","payload":{}}`}})
	if err != nil {
		t.Fatal(err)
	}
	body := map[string]any{}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	data := body["data"].(map[string]any)
	if body["error_code"] != 0.0 || body["sid"] != "sid-1" || data["token"] != "token-1" || data["uid"] != "0123456789abcdef" {
		t.Fatalf("anonymous login envelope: %v", body)
	}

	request, _ := http.NewRequest(http.MethodPost, server.URL+"/server/mobile_api_new/", strings.NewReader(`{"mid":"65305.0"}`))
	request.AddCookie(&http.Cookie{Name: sessionCookie, Value: "sid-1"})
	if _, err := http.DefaultClient.Do(request); err != nil {
		t.Fatal(err)
	}
	if issued != 1 {
		t.Fatalf("package info with a known session cookie issued a new session (%d issued)", issued)
	}

	restart := func() {
		response, err := http.PostForm(server.URL+"/server/mobile_api_new", url.Values{"payload": {`{"mid":"65284","payload":{"device_id":"device-a"}}`}})
		if err != nil {
			t.Fatal(err)
		}
		response.Body.Close()
	}
	restart()
	restart()
	if issued != 2 {
		t.Fatalf("a guest device restarting without its cookie must keep its guest (%d issued)", issued)
	}

	other, err := http.Post(server.URL+"/server/mobile_api_new", "application/json", strings.NewReader(`{"mid":"65319"}`))
	if err != nil {
		t.Fatal(err)
	}
	plain := map[string]any{}
	json.NewDecoder(other.Body).Decode(&plain)
	if plain["status"] != 1.0 || plain["sid"] != nil || issued != 2 {
		t.Fatalf("non-login MID: %v (issued %d)", plain, issued)
	}
}
