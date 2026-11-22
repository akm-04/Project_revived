//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

// U6: an invalidated gameplay session on a real gameplay MID answers 401 with
// message.lua 20003 and its text, so the stock client alerts and restarts into
// login instead of toasting silently and leaving the player stuck.
func TestR4Part4RevokedSessionGameplayMIDIsSessionFailure(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	bearer := displayToken(t, p, a)
	exec(t, p, `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='r4-part4-session' WHERE session_id=$1`, a.SessionID.UUID().String())

	authority := i4store.RealtimeAuthority{
		Queryer:         p,
		DigestSecret:    []byte("i7b2b-fixture-digest-key-00001"),
		BearerSecret:    []byte("i7b2b-fixture-bearer-key-00001"),
		DerivationKeyID: "i7b2b-native",
	}
	router := httpedge.NewRouter()
	if err := router.Register(23, stockruntime.PlayerDisplayDispatcher{Authority: authority, Service: service(p, p)}); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(httpedge.Handler{
		Limits: limits.Default(), Admission: admission,
		Operations: operation.Factory{Clock: clock.System{}},
		Router:     router,
	})
	defer server.Close()

	payload := fmt.Sprintf(`{"mid":23,"token":%q,"region":%d,"player_name":"renamed"}`, bearer, int64(a.LogicalServerID))
	response, err := http.Post(server.URL, "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {payload}}.Encode()))
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	var body map[string]any
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized || body["error_code"] != float64(20003) || body["error_msg"] != "Unstable network,try to relog in!" {
		t.Fatalf("status=%d body=%#v", response.StatusCode, body)
	}
}
