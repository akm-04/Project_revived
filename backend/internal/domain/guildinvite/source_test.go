package guildinvite

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"math"
	"strings"
	"testing"
	"time"
)

func sourceFixture(t *testing.T) Issue {
	t.Helper()
	id, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	rid, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	cid, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	rev, core := strings.Repeat("a", 64), strings.Repeat("b", 64)
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "guild-core", Version: core}, policy.Ref{Name: "guild-invite", Version: PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	start := time.Unix(2000, 123456789).UTC()
	at := time.Unix(2001, 0).UTC()
	op := operation.Context{ID: id, StartedAt: start, Policies: refs}
	s := Issue{Operation: op, Tuple: Tuple{GuildID: 1000001, Recipient: 100002, Generation: 8}, Serial: 7, Server: 1, Inviter: 100001, ActorAccountUID: "fixture-uid", DecisionAt: at, ExpiresAt: at.Add(time.Hour), GuildName: "公会", LastJoinEventID: 5, LastJoinedAt: at.Add(-time.Hour), SendEventID: 6, ContentRevision: rev, GuildCoreRevision: core, PolicyID: PolicyID, Core: CoreReceipt{ID: rid, OwnerKind: "guild", OwnerKey: "1000001", Domain: "guild", Operation: "invite", SemanticKey: "actorver:1:target:100002:gen:8", Schema: "gxb.i6c.guild.invite.v1", OperationClass: "I6C_GUILD", PolicyVersion: core, ActorAccountUID: "fixture-uid", ContextID: cid, OperationStartedAt: start.Truncate(time.Microsecond), OperationPolicyRefs: refs}}
	if e := s.Validate(); e != nil {
		t.Fatal(e)
	}
	return s
}
func TestRetainedCursorAndCanonicalHistoricalIdentity(t *testing.T) {
	if n, e := NextGeneration(3, 0, 8192); e != nil || n != 8193 {
		t.Fatal(n, e)
	}
	if n, e := NextGeneration(8193, 0, 8193); e != nil || n != 8194 {
		t.Fatal(n, e)
	}
	for _, v := range [][3]int64{{math.MaxInt64, 0, 0}, {0, 0, math.MaxInt64}, {-1, 0, 0}} {
		if _, e := NextGeneration(v[0], v[1], v[2]); e == nil {
			t.Fatal(v)
		}
	}
	for _, raw := range []string{"actorver:01:target:100002:gen:8", "actorver:1:target:100002:gen:0", "actorver:1:target:100002:gen:9223372036854775808", "actorver:1:target:100002:gen:8:extra"} {
		if _, _, _, e := InviteReceiptGeneration(raw); e == nil {
			t.Fatal(raw)
		}
	}
	s := sourceFixture(t)
	s.Core.SemanticKey = "actorver:1:target:100003:gen:8"
	if s.Validate() == nil {
		t.Fatal("foreign target receipt accepted")
	}
}
func TestStrictExpiryPermanentJoinAndPartialRestore(t *testing.T) {
	s := sourceFixture(t)
	v := Snapshot{Issue: s, GuildPresent: true, CurrentGeneration: 8, CurrentSourceID: s.Operation.ID, LatestJoinEventID: 5}
	for _, d := range []time.Duration{-time.Nanosecond, 0, time.Nanosecond} {
		ok, e := v.Eligible(s.ExpiresAt.Add(d))
		if e != nil || ok != (d < 0) {
			t.Fatal(d, ok, e)
		}
	}
	v.LatestJoinEventID = 6
	v.CurrentMember = false
	if ok, e := v.Eligible(s.DecisionAt); e != nil || ok {
		t.Fatal("JOIN then leave resurrected", ok, e)
	}
	v.LatestJoinEventID = 4
	if _, e := v.Eligible(s.DecisionAt); e == nil {
		t.Fatal("missing history became eligibility")
	}
	v.LatestJoinEventID = 5
	v.CurrentSourceID = ids.UUID{}
	if _, e := v.Eligible(s.DecisionAt); e == nil {
		t.Fatal("current generation orphan accepted")
	}
	v.CurrentSourceID = s.Operation.ID
	if _, e := v.Eligible(s.DecisionAt.Add(-time.Microsecond)); e == nil {
		t.Fatal("future source at backwards clock accepted")
	}
}
func TestFullPrecisionAndCanonicalSourceFingerprint(t *testing.T) {
	s := sourceFixture(t)
	fp, e := s.Fingerprint()
	if e != nil {
		t.Fatal(e)
	}
	s.Operation.StartedAt = s.Operation.StartedAt.Add(time.Nanosecond)
	other, e := s.Fingerprint()
	if e != nil || fp == other {
		t.Fatal("private nanos lost", e)
	}
	s = sourceFixture(t)
	s.GuildName = "bad\x00name"
	if s.Validate() == nil {
		t.Fatal("NUL text boundary lost")
	}
	s = sourceFixture(t)
	s.Core.PolicyVersion = strings.Repeat("c", 64)
	if s.Validate() == nil {
		t.Fatal("core policy mismatch accepted")
	}
}
