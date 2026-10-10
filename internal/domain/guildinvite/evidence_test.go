package guildinvite

import (
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/foundation/ids"
	"math"
	"testing"
	"time"
)

func TestStrictStoredEvidenceRoundtripAndTampering(t *testing.T) {
	s := sourceFixture(t)
	fp, _ := s.Fingerprint()
	raw, e := json.Marshal(s)
	if e != nil {
		t.Fatal(e)
	}
	w, e := DecodeIssue(raw, hex.EncodeToString(fp[:]))
	if e != nil || w.Operation.StartedAt.Nanosecond() != s.Operation.StartedAt.Nanosecond() {
		t.Fatal(w, e)
	}
	var fields map[string]json.RawMessage
	if e = json.Unmarshal(raw, &fields); e != nil {
		t.Fatal(e)
	}
	fields["AuthorityFromJob"] = json.RawMessage(`true`)
	extra, _ := json.Marshal(fields)
	if _, e = DecodeIssue(extra, hex.EncodeToString(fp[:])); e == nil {
		t.Fatal("unknown stored source field accepted")
	}
	for _, bad := range [][]byte{append(append([]byte{}, raw...), []byte(` {}`)...), []byte(`null`), []byte(`{}`)} {
		if _, e = DecodeIssue(bad, hex.EncodeToString(fp[:])); e == nil {
			t.Fatal("incomplete/trailing source accepted")
		}
	}
	s.Core.OperationPolicyRefs = s.Operation.Policies
	s.Core.OperationStartedAt = s.Core.OperationStartedAt.Add(time.Microsecond)
	if s.Validate() == nil {
		t.Fatal("receipt/source timestamp mismatch accepted")
	}
}

func markerFixture(t *testing.T, s Issue) Marker {
	id, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	m := Marker{Operation: s.Operation, Kind: Join, GuildID: s.Tuple.GuildID, Server: s.Server, Actor: s.Inviter, Subject: s.Tuple.Recipient, ActorAccountUID: s.ActorAccountUID, EventID: 100, DecisionAt: s.DecisionAt.Add(time.Second), MaxIssueSerial: s.Serial, ContentRevision: s.ContentRevision, GuildCoreRevision: s.GuildCoreRevision, PolicyID: PolicyID, Core: s.Core}
	m.Operation.ID = id
	m.Core.Operation = "accept_application"
	m.Core.SemanticKey = "target:100002:gen:4"
	m.Core.Schema = "gxb.i6c.guild.accept_application.v1"
	if e = m.Validate(); e != nil {
		t.Fatal(e)
	}
	return m
}

func TestFiniteMarkerBoundaryAndTargetProofIdentity(t *testing.T) {
	s := sourceFixture(t)
	m := markerFixture(t, s)
	if ok, e := m.AppliesTo(s); e != nil || !ok {
		t.Fatal(ok, e)
	}
	later := s
	later.Serial++
	if ok, e := m.AppliesTo(later); e != nil || ok {
		t.Fatal("future issue crossed marker high water", ok, e)
	}
	afterJoin := s
	afterJoin.LastJoinEventID = m.EventID
	afterJoin.LastJoinedAt = s.DecisionAt
	if ok, e := m.AppliesTo(afterJoin); e != nil || ok {
		t.Fatal("issue including JOIN invalidated", ok, e)
	}
	id, _ := ids.NewUUID()
	sfp, _ := s.Fingerprint()
	mfp, _ := m.Fingerprint()
	key, _ := s.Tuple.SourceKey()
	p := InvalidationProof{MarkerID: m.Operation.ID, SourceID: s.Operation.ID, SourceSerial: s.Serial, SourceKey: key, Recipient: s.Tuple.Recipient, MarkerFingerprint: mfp, SourceFingerprint: sfp, ReceiptID: id, DecisionAt: m.DecisionAt}
	if p.Matches(m, s) != nil {
		t.Fatal("valid no-op invalidation rejected")
	}
	p.Consumed = true
	if p.Validate() == nil {
		t.Fatal("consumption without Notice accepted")
	}
	p.NoticeID = 8
	p.RootVersion = 1
	p.NoticeStateVersion = 2
	if p.Matches(m, s) != nil {
		t.Fatal("valid consumption rejected")
	}
	p.MarkerFingerprint[0] ^= 1
	if p.Matches(m, s) == nil {
		t.Fatal("foreign marker proof accepted")
	}
}

func TestDeliveryAndProgressCannotCreditJobCompletion(t *testing.T) {
	s := sourceFixture(t)
	fp, _ := s.Fingerprint()
	id, _ := ids.NewUUID()
	d := Delivery{SourceID: s.Operation.ID, Recipient: s.Tuple.Recipient, State: Pending, LastEnqueueAt: s.DecisionAt, NextWakeupAt: s.DecisionAt.Add(time.Minute)}
	p := TargetProof{SourceID: s.Operation.ID, Recipient: s.Tuple.Recipient, SourceFingerprint: fp, ReceiptID: id, State: Materialized, NoticeID: 1, RootVersion: 1, DecisionAt: s.DecisionAt}
	if p.Matches(s) != nil || d.Matches(p) != nil {
		t.Fatal("valid target rejected")
	}
	d.ReceiptID = id
	if d.Validate() == nil {
		t.Fatal("pending job turned into terminal proof")
	}
	for _, state := range []DeliveryState{Suppressed, RecipientGone} {
		v := p
		v.State = state
		if v.Validate() == nil {
			t.Fatal("no Notice terminal state retained Notice ID")
		}
		v.NoticeID = 0
		if v.Validate() != nil {
			t.Fatal(v)
		}
	}
	p.NoticeID = math.MaxInt64
	if p.Validate() == nil {
		t.Fatal("unsafe wire ID accepted")
	}
	p.NoticeID = 1
	p.SourceFingerprint = [32]byte{}
	if p.Validate() == nil {
		t.Fatal("missing source proof accepted")
	}
	m := markerFixture(t, s)
	done := m.DecisionAt
	progress := MarkerProgress{MarkerID: m.Operation.ID, MaxIssueSerial: m.MaxIssueSerial, CursorSerial: m.MaxIssueSerial - 1, Complete: true, CompletedAt: &done, LastEnqueueAt: done, NextWakeupAt: done.Add(time.Minute)}
	if progress.Validate() == nil {
		t.Fatal("incomplete high water credited complete")
	}
	progress.CursorSerial++
	progress.CursorProof = &CursorProof{Request: CursorRequest{MarkerID: m.Operation.ID, To: m.MaxIssueSerial, Complete: true}, ReceiptID: id, DecisionAt: done}
	if progress.Validate() != nil {
		t.Fatal(progress)
	}
}
