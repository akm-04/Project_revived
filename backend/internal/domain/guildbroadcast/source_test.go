package guildbroadcast

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"strings"
	"testing"
	"time"
)

func validSource(t *testing.T) Source {
	t.Helper()
	at := time.Date(2026, 10, 9, 8, 0, 0, 0, time.UTC)
	rev := strings.Repeat("a", 64)
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "guild-core", Version: rev}, policy.Ref{Name: "guild-broadcast", Version: PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	id, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	return Source{Operation: operation.Context{ID: id, StartedAt: at, Policies: refs}, GuildID: 1000001, Server: 1, LeaderID: 100001, LeaderName: "Leader", NameSnapshotChangedAt: at, DecisionAt: at, ContentRevision: rev, GuildCoreRevision: rev, PolicyID: PolicyID, Request: Request{Title: "title", Content: "body"}, Recipients: []Member{{PlayerID: 100001, JoinEventID: 1, JoinedAt: at}, {PlayerID: 100002, JoinEventID: 2, JoinedAt: at}}}
}
func TestImmutableSourceIdentityAndRoster(t *testing.T) {
	original := validSource(t)
	a, e := original.Fingerprint()
	if e != nil {
		t.Fatal(e)
	}
	changed := original
	changed.Request.Content = "different"
	b, e := changed.Fingerprint()
	if e != nil || a == b {
		t.Fatal("content conflict not fingerprinted")
	}
	for _, change := range []func(*Source){func(s *Source) { s.DecisionAt = s.DecisionAt.Add(-time.Second) }, func(s *Source) { s.Recipients = []Member{s.Recipients[1], s.Recipients[0]} }, func(s *Source) { s.Recipients = []Member{s.Recipients[0], s.Recipients[0]} }, func(s *Source) { s.Recipients = s.Recipients[1:] }, func(s *Source) { s.Server = 2 }, func(s *Source) { s.Recipients[0].PlayerID = 200001 }, func(s *Source) { s.Recipients[1].JoinEventID = s.Recipients[0].JoinEventID }, func(s *Source) { s.Operation.Policies = policy.Set{} }} {
		s := original
		change(&s)
		if s.Validate() == nil {
			t.Fatal("invalid source accepted")
		}
	}
}
func TestPendingCannotClaimTerminalProof(t *testing.T) {
	id, _ := ids.NewUUID()
	at := time.Date(2026, 10, 9, 8, 0, 0, 0, time.UTC)
	b := Binding{SourceID: id, RecipientID: 100001, State: Pending, LastEnqueueAt: at, NextWakeupAt: at.Add(time.Minute)}
	if e := b.Validate(); e != nil {
		t.Fatal(e)
	}
	b.MailID = id
	if b.Validate() == nil {
		t.Fatal("pending with Mail proof accepted")
	}
	b.State = Delivered
	b.TargetReceiptID = id
	b.AcknowledgedAt = &at
	b.WireID = 9007199254740992
	if b.Validate() == nil {
		t.Fatal("unsafe wire ID accepted")
	}
}

func TestFingerprintCanonicalizesSnapshotTimezoneWithoutLosingPrecision(t *testing.T) {
	a := validSource(t)
	a.Recipients[0].JoinedAt = a.Recipients[0].JoinedAt.Add(123456789 * time.Nanosecond)
	a.DecisionAt = a.DecisionAt.Add(time.Second)
	before, e := a.Fingerprint()
	if e != nil {
		t.Fatal(e)
	}
	a.Recipients[0].JoinedAt = a.Recipients[0].JoinedAt.In(time.FixedZone("UTC+1", 3600))
	a.NameSnapshotChangedAt = a.NameSnapshotChangedAt.In(time.FixedZone("UTC-1", -3600))
	after, e := a.Fingerprint()
	if e != nil || before != after {
		t.Fatal("same instants changed fingerprint", e)
	}
	a.Recipients[0].JoinedAt = a.Recipients[0].JoinedAt.Add(time.Nanosecond)
	changed, e := a.Fingerprint()
	if e != nil || changed == after {
		t.Fatal("precision discarded", e)
	}
}
