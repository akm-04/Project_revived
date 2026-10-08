package socialgift

import (
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"reflect"
	"testing"
	"time"
)

func TestPolicyIdentityAndPureNormalization(t *testing.T) {
	before := time.Date(2026, 10, 8, 15, 59, 59, 0, time.UTC)
	a, _ := Day(before)
	b, _ := Day(before.Add(time.Second))
	if a != "2026-10-08" || b != "2026-10-09" {
		t.Fatal(a, b)
	}
	u, _ := ids.NewUUID()
	op := operation.Context{ID: u, StartedAt: before, EntropySeed: [32]byte{7}}
	e, err := NewEpoch(100001, a, op, before)
	if err != nil {
		t.Fatal(err)
	}
	again, _ := NewEpoch(100001, a, op, before)
	if !reflect.DeepEqual(e, again) || e.Generation.UUID() == op.ID {
		t.Fatal("generation aliases operation")
	}
	r, err := e.Ref()
	if err != nil || r.Domain() != "social-gift" || r.Scope().Key() != "100001" {
		t.Fatal(r, err)
	}
	x, err := CanonicalIDs([]socialinbox.NoticeID{9, 2, 9, 4})
	if err != nil || !reflect.DeepEqual(x, []socialinbox.NoticeID{9, 2, 4}) {
		t.Fatal(x, err)
	}
	for _, id := range []socialinbox.NoticeID{0, -1, 1 << 53} {
		if _, err = CanonicalIDs([]socialinbox.NoticeID{id}); err == nil {
			t.Fatal(id)
		}
	}
	p := GrantPlan(100001, u, 50)
	if p.Source.Occurrence != u.String() || p.Source.Domain != "social-gift" || p.Lines[0].ItemID != 0 {
		t.Fatal(p)
	}
}
func FuzzClaimIDs(f *testing.F) {
	f.Add(int64(3), int64(2))
	f.Fuzz(func(t *testing.T, a, b int64) {
		x, e := CanonicalIDs([]socialinbox.NoticeID{socialinbox.NoticeID(a), socialinbox.NoticeID(b), socialinbox.NoticeID(a)})
		if e == nil {
			if len(x) > 2 {
				t.Fatal(x)
			}
			for _, id := range x {
				if !id.WireSafe() {
					t.Fatal(id)
				}
			}
		}
	})
}

func TestFingerprintIncludesPrivateActorUUIDs(t *testing.T) {
	u, _ := ids.NewUUID()
	v, _ := ids.NewUUID()
	a, _ := identity.AccountIDFrom(u)
	b, _ := identity.AccountIDFrom(v)
	sid, _ := identity.SessionIDFrom(u)
	cid, _ := identity.ContextIDFrom(u)
	actor := identity.ActorContext{AccountID: a, AccountUID: "100001", PlayerID: 100001, LogicalServerID: 1, SessionID: sid, ContextID: cid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	op := operation.Context{ID: u, StartedAt: time.Now()}
	base, _ := fingerprint("send", actor, identity.PlayerID(200001), op)
	actor.AccountID = b
	changed, _ := fingerprint("send", actor, identity.PlayerID(200001), op)
	if base == changed {
		t.Fatal("private Actor UUID omitted")
	}
	actor.AccountID = a
	actor.SessionID, _ = identity.SessionIDFrom(v)
	changed, _ = fingerprint("send", actor, identity.PlayerID(200001), op)
	if base == changed {
		t.Fatal("session omitted")
	}
	actor.SessionID = sid
	actor.ContextID, _ = identity.ContextIDFrom(v)
	changed, _ = fingerprint("send", actor, identity.PlayerID(200001), op)
	if base == changed {
		t.Fatal("context omitted")
	}
}
