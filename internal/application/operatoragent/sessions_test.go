package operatoragent

import (
	"strings"
	"testing"
	"time"
)

func TestSessionsAcceptTheLoginTokenAndRefuseSameLengthTokens(t *testing.T) {
	sessions := NewSessions(func() time.Time { return time.Unix(0, 0) })
	token, _, err := sessions.Login()
	if err != nil {
		t.Fatal(err)
	}
	if !sessions.Authorize(token) {
		t.Fatal("the login token was refused")
	}
	wrong := strings.Repeat("a", len(token))
	if wrong == token {
		t.Fatal("the generated token was all a")
	}
	if sessions.Authorize(wrong) {
		t.Fatal("a wrong token of the same length was accepted")
	}
}
