package logicalserver

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

func au(b byte) identity.AccountID {
	var u ids.UUID
	u[15] = b
	x, _ := identity.AccountIDFrom(u)
	return x
}
func su(b byte) identity.SessionID {
	var u ids.UUID
	u[15] = b
	x, _ := identity.SessionIDFrom(u)
	return x
}
func op() operation.Context {
	var u ids.UUID
	u[15] = 9
	return operation.Context{ID: u, StartedAt: time.Unix(10, 0).UTC()}
}

type contrib struct {
	required bool
	err      error
	seen     identity.PlayerID
}

func (c *contrib) Name() string                   { return "c" }
func (c *contrib) Required() bool                 { return c.required }
func (c *contrib) Apply(x BootstrapContext) error { c.seen = x.PlayerID; return c.err }
func TestPlayerBandAndCapacity(t *testing.T) {
	s := Server{ID: 1, Name: "Server 1", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: true, NextPlayerID: 199999, MaxPlayerID: 199999}
	n, id, e := s.Allocate()
	if e != nil || id != 199999 || n.NextPlayerID != 200000 {
		t.Fatalf("%v %d %+v", e, id, n)
	}
	if _, _, e = n.Allocate(); !errors.Is(e, ErrServerFull) {
		t.Fatalf("expected full %v", e)
	}
	if PlayerRegion(199999) != 1 || PlayerRegion(200001) != 2 {
		t.Fatal("region encoding")
	}
}
func TestNewCharacterRequiresObservationAndRollsBackPurePlanOnContributorFailure(t *testing.T) {
	s := Server{ID: 1, Name: "Server 1", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: true, NextPlayerID: 100001, MaxPlayerID: 199999}
	if _, e := PlanCharacter(s, au(1), su(2), nil, false, op(), "wave-s-v1", nil); !errors.Is(e, ErrObservationRequired) {
		t.Fatalf("%v", e)
	}
	c := &contrib{required: true, err: errors.New("boom")}
	if _, e := PlanCharacter(s, au(1), su(2), nil, true, op(), "wave-s-v1", []BootstrapContributor{c}); e == nil {
		t.Fatal("required failure accepted")
	}
	if s.NextPlayerID != 100001 {
		t.Fatal("input cursor mutated on failed plan")
	}
}
func TestExistingOwnerIgnoresNewCharacterFullGate(t *testing.T) {
	s := Server{ID: 1, Name: "Server 1", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: false, NextPlayerID: 100002, MaxPlayerID: 199999}
	p := PlayerRoot{PlayerID: 100001, AccountID: au(1), LogicalServerID: 1}
	r, e := PlanCharacter(s, au(1), su(2), &p, false, op(), "x", nil)
	if e != nil || r.Created {
		t.Fatalf("existing failed %v", e)
	}
}
func TestMID18ClosedToNewProjectsFullWithoutChangingAllocator(t *testing.T) {
	s := Server{ID: 2, Name: "Server 2", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: false, NextPlayerID: 200010, MaxPlayerID: 299999}
	v := ProjectRegion(s)
	if v.CurID != 299999 || s.NextPlayerID != 200010 {
		t.Fatalf("projection mutated/corrupt %+v", v)
	}
	m := ProjectMID18([]Server{s}, nil)
	if m.Players == nil || m.RecallRegions == nil {
		t.Fatal("stock arrays must be present")
	}
}
func TestFirstEntryReplayStable(t *testing.T) {
	p := PlayerRoot{FirstEntryPending: true}
	if MID1IsNew(p) != 1 || MID1IsNew(p) != 1 {
		t.Fatal("lost response retry lost is_new")
	}
	p.FirstEntryPending = false
	if MID1IsNew(p) != 0 {
		t.Fatal("terminal marker not consumed")
	}
}
