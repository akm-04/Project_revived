package generaldm

import (
	"strings"
	"testing"
	"time"
	"unicode/utf8"
)

func fixture() Intent {
	now := time.Unix(1700000000, 0).UTC()
	return Intent{ID: "00000000-0000-4000-8000-000000000001", Digest: Digest(1, 2, "hello"), Sender: 1, Recipient: 2, Message: "hello", AcceptedAt: now, ExpiresAt: now.Add(IntentLifetime), BlockVersion: 0, Bindings: []Binding{{ContextID: "ctx", ContextGeneration: 1, SessionID: "sess", SessionLiveness: 1, ContextLiveness: 1, RealtimeInstanceID: "rt", ConnectionGeneration: 1, OwnerFence: 1, LogicalServerID: 1}}, Status: Pending, StateVersion: 1, LastObservedAt: now}
}

func TestAttemptCannotReturnToPending(t *testing.T) {
	i, err := fixture().Claim(time.Unix(1700000001, 0), 1)
	if err != nil {
		t.Fatal(err)
	}
	i, err = i.BeginAttempt(time.Unix(1700000002, 0))
	if err != nil {
		t.Fatal(err)
	}
	if i.Status != Attempting {
		t.Fatalf("status=%s", i.Status)
	}
	if _, err = i.Claim(time.Unix(1700000003, 0), 1); err == nil {
		t.Fatal("attempt was replayable")
	}
	finished, err := i.Finish(time.Unix(1700000003, 0), time.Unix(1700000003, 0), false)
	if err != nil {
		t.Fatal(err)
	}
	if finished.Status != Unknown {
		t.Fatalf("status=%s", finished.Status)
	}
}

func TestStrictDeadlineEqualityFails(t *testing.T) {
	i, _ := fixture().Claim(time.Unix(1700000001, 0), 1)
	i, _ = i.BeginAttempt(time.Unix(1700000002, 0))
	if _, err := i.Finish(time.Unix(1700000008, 0), time.Unix(1700000008, 0), true); err == nil {
		t.Fatal("expiry equality accepted")
	}
}

func Test6B_G31_G34StrictCompletionAndLeaseBoundaries(t *testing.T) {
	base := fixture()
	for _, d := range []time.Duration{-time.Nanosecond, 0, time.Nanosecond} {
		i, _ := base.Claim(base.AcceptedAt.Add(time.Second), 1)
		i, _ = i.BeginAttempt(base.AcceptedAt.Add(2 * time.Second))
		got, e := i.Finish(base.AcceptedAt.Add(3*time.Second), base.ExpiresAt.Add(d), true)
		if d < 0 {
			if e != nil || got.Status != WrittenBeforeDeadline {
				t.Fatal(got, e)
			}
		} else if e == nil || got.Status != TimeInvalid {
			t.Fatal("equality/after accepted", got, e)
		}
	}
	i, _ := base.Claim(base.ExpiresAt.Add(-time.Second), 1)
	if !i.LeaseExpiresAt.Equal(base.ExpiresAt) {
		t.Fatal("lease uncapped")
	}
	if _, e := i.BeginAttempt(*i.LeaseExpiresAt); e == nil {
		t.Fatal("lease equality")
	}
	i, _ = base.Claim(base.AcceptedAt, 1)
	if i.LeaseExpiresAt.Sub(base.AcceptedAt) != 2*time.Second {
		t.Fatal("lease duration")
	}
	if _, e := base.Claim(base.ExpiresAt, 1); e == nil {
		t.Fatal("expiry equality")
	}
}
func Test6B_G23_G36FiniteReferenceAndMessage(t *testing.T) {
	if ValidateMessage(string([]byte{0xff})) == nil {
		t.Fatal("invalid UTF8")
	}
	if ValidateMessage(strings.Repeat("界", 140)) != nil || ValidateMessage(strings.Repeat("界", 141)) == nil {
		t.Fatal("unicode scalar bounds")
	}
	for _, raw := range []string{`{"operation_id":"00000000-0000-4000-8000-000000000001","version":1,"version":1}`, `{"operation_id":"00000000-0000-4000-8000-000000000001","version":1,"payload":"text"}`, `{"operation_id":"00000000-0000-4000-8000-000000000001","version":1.5}`} {
		if _, e := DecodeReference(raw); e == nil {
			t.Fatal(raw)
		}
	}
}
func FuzzGeneralMessage(f *testing.F) {
	f.Add("ordinary")
	f.Add("界")
	f.Add("\xff")
	f.Fuzz(func(t *testing.T, s string) {
		if ValidateMessage(s) == nil && (!utf8.ValidString(s) || utf8.RuneCountInString(s) > 140 || len(s) > 2048 || strings.TrimSpace(s) == "") {
			t.Fatal("invalid accepted")
		}
	})
}

func Test6B_G13PositiveReceiptReloadFailsClosedOnInvalidProof(t *testing.T) {
	i, _ := fixture().Claim(fixture().AcceptedAt.Add(time.Second), 1)
	i, _ = i.BeginAttempt(fixture().AcceptedAt.Add(2 * time.Second))
	i, _ = i.Finish(fixture().AcceptedAt.Add(3*time.Second), fixture().AcceptedAt.Add(3*time.Second), true)
	if i.Validate() != nil {
		t.Fatal("valid receipt")
	}
	for _, at := range []time.Time{time.Time{}, i.AcceptedAt, i.ExpiresAt} {
		j := i
		j.CompletionUpper = &at
		if j.Validate() == nil {
			t.Fatal("invalid upper accepted", at)
		}
	}
	j := i
	j.AttemptCommittedAt = nil
	if j.Validate() == nil {
		t.Fatal("marker missing")
	}
	j = i
	j.OwnerFence = 0
	if j.Validate() == nil {
		t.Fatal("fence missing")
	}
	j = i
	j.LastObservedAt = j.ExpiresAt
	if j.Validate() == nil {
		t.Fatal("late positive finalization")
	}
}
