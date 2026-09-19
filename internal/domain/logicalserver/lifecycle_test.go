package logicalserver

import (
	"errors"
	"testing"
	"time"
)

func TestFirstOpenedAtNeverResets(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	s := Server{ID: 1, Name: "Server 1", NextPlayerID: 100001, MaxPlayerID: 199999, StateVersion: 1}
	o, e := ApplyLifecycle(s, Open, now)
	if e != nil || o.FirstOpenedAt == nil {
		t.Fatal(e)
	}
	m, e := ApplyLifecycle(o, Maintenance, now.Add(time.Hour))
	if e != nil {
		t.Fatal(e)
	}
	o2, e := ApplyLifecycle(m, Open, now.Add(2*time.Hour))
	if e != nil {
		t.Fatal(e)
	}
	if !o2.FirstOpenedAt.Equal(*o.FirstOpenedAt) {
		t.Fatal("maintenance/reopen reset server age")
	}
}

func TestRetiredServerIsTerminalAndRepeatIsIdempotent(t *testing.T) {
	now := time.Unix(200, 0).UTC()
	s := Server{ID: 1, Name: "Server 1", NextPlayerID: 100001, MaxPlayerID: 199999, StateVersion: 3}
	r, err := ApplyLifecycle(s, Retired, now)
	if err != nil {
		t.Fatal(err)
	}
	if r.RetiredAt == nil || !r.RetiredAt.Equal(now) || r.DirectoryVisible || r.ExistingLoginAllowed || r.NewCharacterAllowed {
		t.Fatalf("retired=%+v", r)
	}
	again, err := ApplyLifecycle(r, Retired, now.Add(time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if again.StateVersion != r.StateVersion || !again.RetiredAt.Equal(*r.RetiredAt) {
		t.Fatalf("repeat changed tombstone: before=%+v after=%+v", r, again)
	}
	if _, err := ApplyLifecycle(r, Open, now.Add(2*time.Hour)); !errors.Is(err, ErrServerRetired) {
		t.Fatalf("reopen err=%v", err)
	}
}

func TestRetiredServerValidationRejectsAdmissionFlags(t *testing.T) {
	now := time.Unix(300, 0).UTC()
	s := Server{ID: 1, Name: "Server 1", NextPlayerID: 100001, MaxPlayerID: 199999, StateVersion: 2, RetiredAt: &now, DirectoryVisible: true}
	if err := s.Validate(); err == nil {
		t.Fatal("retired visible server validated")
	}
}
