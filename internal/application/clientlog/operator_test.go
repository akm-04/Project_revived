package clientlog

import (
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

func TestJournalCursorRoundTrip(t *testing.T) {
	entry := JournalEntry{ReceivedAt: time.Date(2026, 11, 22, 10, 0, 0, 123456789, time.UTC), JournalID: 42}
	cursor, err := ParseJournalCursor(formatJournalCursor(entry))
	if err != nil {
		t.Fatal(err)
	}
	if !cursor.Present || cursor.JournalID != 42 || !cursor.ReceivedAt.Equal(entry.ReceivedAt) {
		t.Fatalf("cursor = %+v", cursor)
	}
	if _, err := ParseJournalCursor("nonsense"); err == nil {
		t.Fatal("a malformed cursor was accepted")
	}
}

func TestClearFilterScopes(t *testing.T) {
	if _, err := clearFilter(ClearPayload{Source: "backend", Scope: "all"}); err == nil {
		t.Fatal("a non-client source was accepted by the backend clear")
	}
	if _, err := clearFilter(ClearPayload{Source: "client", Scope: "player"}); err == nil {
		t.Fatal("a player clear without a target was accepted")
	}
	filter, err := clearFilter(ClearPayload{Source: "client", Scope: "player", UID: "acct", PlayerID: 9})
	if err != nil || filter.AccountUID != "acct" || filter.PlayerID != 9 {
		t.Fatalf("player filter = %+v err=%v", filter, err)
	}
	if _, err := clearFilter(ClearPayload{Source: "client", Scope: "older_than", OlderThan: "yesterday"}); err == nil {
		t.Fatal("a non-RFC3339 boundary was accepted")
	}
	boundary := "2026-11-01T00:00:00Z"
	filter, err = clearFilter(ClearPayload{Source: "client", Scope: "older_than", OlderThan: boundary})
	if err != nil || filter.Before == nil || filter.Before.Format(time.RFC3339) != boundary {
		t.Fatalf("older_than filter = %+v err=%v", filter, err)
	}
	if _, err := clearFilter(ClearPayload{Source: "client", Scope: "everything"}); err == nil {
		t.Fatal("an unknown scope was accepted")
	}
}

func TestOutcomesForLevel(t *testing.T) {
	errorOutcomes, err := OutcomesForLevel("error")
	if err != nil || len(errorOutcomes) != 2 || errorOutcomes[0] != "CLIENT_ERROR" {
		t.Fatalf("error outcomes = %v err=%v", errorOutcomes, err)
	}
	if outcomes, err := OutcomesForLevel(""); err != nil || len(outcomes) != 0 {
		t.Fatalf("empty level = %v err=%v", outcomes, err)
	}
	if _, err := OutcomesForLevel("debug"); err == nil {
		t.Fatal("an unknown level was accepted")
	} else {
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodeReadInvalid {
			t.Fatalf("level refusal = %v", err)
		}
	}
}
