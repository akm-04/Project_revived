package operatoragent

import (
	"strings"
	"testing"
	"time"
)

func TestSessionsAcceptTheLoginTokenAndRefuseSameLengthTokens(t *testing.T) {
	sessions := NewSessions(func() time.Time { return time.Unix(0, 0) })
	token, _, err := sessions.Login("generation-one")
	if err != nil {
		t.Fatal(err)
	}
	if !sessions.Authorize(token, "generation-one") {
		t.Fatal("the login token was refused")
	}
	wrong := strings.Repeat("a", len(token))
	if wrong == token {
		t.Fatal("the generated token was all a")
	}
	if sessions.Authorize(wrong, "generation-one") {
		t.Fatal("a wrong token of the same length was accepted")
	}
}

func TestSessionsRefuseATokenFromAnOlderPasswordGeneration(t *testing.T) {
	sessions := NewSessions(func() time.Time { return time.Unix(0, 0) })
	token, _, err := sessions.Login("generation-one")
	if err != nil {
		t.Fatal(err)
	}
	if sessions.Authorize(token, "generation-two") {
		t.Fatal("a token from an older generation was accepted")
	}
}
