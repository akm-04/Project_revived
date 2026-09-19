package objective

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func baseInstance() Instance {
	return Instance{PlayerID: identity.PlayerID(100001), ProgramID: "daily", ObjectiveID: 7, DefinitionRevision: "r1", ClaimState: Unclaimed, StateVersion: 1}
}
func TestCompletionDoesNotClaimOrGrant(t *testing.T) {
	i := baseInstance()
	d := Definition{ProgramID: "daily", ObjectiveID: 7, DefinitionRevision: "r1", Strategy: CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 2}
	f := Fact{PlayerID: i.PlayerID, SourceDomain: "combat", SourceBusinessKey: "attempt:1", Kind: "battle_win", Delta: 2}
	n, ch, e := ApplyFact(i, d, f, time.Unix(10, 0))
	if e != nil || !ch || n.CompletedAt == nil {
		t.Fatalf("n=%+v ch=%v e=%v", n, ch, e)
	}
	if n.ClaimState != Unclaimed || n.ClaimedAt != nil {
		t.Fatal("completion implicitly claimed reward")
	}
	c, e := Claim(n, time.Unix(11, 0))
	if e != nil || c.ClaimState != Claimed {
		t.Fatalf("c=%+v e=%v", c, e)
	}
}
func TestWrongFactKindDoesNotProgress(t *testing.T) {
	i := baseInstance()
	d := Definition{ProgramID: "daily", ObjectiveID: 7, DefinitionRevision: "r1", Strategy: CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 2}
	n, ch, e := ApplyFact(i, d, Fact{PlayerID: i.PlayerID, SourceDomain: "shop", SourceBusinessKey: "p:1", Kind: "purchase", Delta: 1}, time.Unix(10, 0))
	if e != nil || ch || n.Progress != 0 || n.StateVersion != 1 {
		t.Fatalf("n=%+v ch=%v e=%v", n, ch, e)
	}
}
