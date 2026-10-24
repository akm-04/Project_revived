package bootstrap

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

func u(b byte) ids.UUID             { var x ids.UUID; x[15] = b; return x }
func aid(b byte) identity.AccountID { x, _ := identity.AccountIDFrom(u(b)); return x }
func sid(b byte) identity.SessionID { x, _ := identity.SessionIDFrom(u(b)); return x }
func cid(b byte) identity.ContextID { x, _ := identity.ContextIDFrom(u(b)); return x }
func base(full bool) MID1Command {
	now := time.Unix(100, 0).UTC()
	a := identity.Account{ID: aid(1), UID: identity.AccountUID("20000007"), Status: identity.AccountActive}
	s := identity.Session{ID: sid(2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now, LastActivityAt: now}
	srv := logicalserver.Server{ID: 1, Name: "Server 1", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: !full, NextPlayerID: 125001, MaxPlayerID: 199999}
	return MID1Command{Account: a, Session: s, Server: srv, Observed: true, NewContextID: cid(3), Operation: operation.Context{ID: u(9), StartedAt: now}, BootstrapProfileVersion: "wave-s-v1", BearerSecret: []byte("0123456789abcdef0123456789abcdef")}
}
func TestMID1NewShapeAndStableReplay(t *testing.T) {
	c := base(false)
	r, e := PlanMID1(c)
	if e != nil {
		t.Fatal(e)
	}
	if r.Region != 1 || r.UID != identity.AccountUID("20000007") || r.IsNew != 1 || r.Token == "" || r.Detail == nil {
		t.Fatalf("%+v", r)
	}
	c.ExistingPlayer = &r.Player
	c.ExistingContext = &r.ContextPlan.Selected
	c.NewContextID = cid(4)
	r2, e := PlanMID1(c)
	if e != nil {
		t.Fatal(e)
	}
	if r2.Token != r.Token || r2.ContextPlan.Kind != identity.SelectionCoalesced || r2.IsNew != 1 {
		t.Fatal("same-target/lost-response replay not stable")
	}
}
func Test20018LeavesOldContextUntouched(t *testing.T) {
	c := base(true)
	old := identity.GameplayContext{ID: cid(8), SessionID: c.Session.ID, AccountID: c.Account.ID, LogicalServerID: 2, PlayerID: 200001, ContextGeneration: 4, CreatedAt: c.Operation.StartedAt, LivenessVersion: 1}
	c.ExistingContext = &old
	c.Observed = true
	_, e := PlanMID1(c)
	if !errors.Is(e, logicalserver.ErrServerFull) {
		t.Fatalf("%v", e)
	}
	if old.EndedAt != nil {
		t.Fatal("old context ended before failed target admission")
	}
}
