package i5

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func TestPreservationMaxHeroColorPolicyIsExplicitStableCompatibilityDecision(t *testing.T) {
	p := PreservationMaxHeroColorProvider{}
	if got := p.MaxHeroColor(); got != 5 {
		t.Fatalf("max Hero color=%d want 5", got)
	}
	if got := p.MaxHeroColorPolicyRevision(); got != "GXB1_PRESERVATION_MAX_HERO_COLOR_V1" {
		t.Fatalf("policy revision=%q", got)
	}
	pid := identity.PlayerID(100001)
	op := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(100, 0).UTC()}
	got, err := p.MaxHeroColorTx(context.Background(), nil, pid, op)
	if err != nil || got != 5 {
		t.Fatalf("tx policy got=%d err=%v", got, err)
	}
}

func TestPreservationMaxHeroColorPolicyFailsClosedOnInvalidOperationIdentity(t *testing.T) {
	p := PreservationMaxHeroColorProvider{}
	validOp := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(100, 0).UTC()}
	if _, err := p.MaxHeroColorTx(context.Background(), nil, 0, validOp); err == nil {
		t.Fatal("invalid player accepted")
	}
	if _, err := p.MaxHeroColorTx(context.Background(), nil, identity.PlayerID(100001), operation.Context{}); err == nil {
		t.Fatal("invalid operation accepted")
	}
}

func TestCurrentMaxHeroColorPolicyEnablesSourcePurpleAndRetainsLegacy(t *testing.T) {
	p := CurrentMaxHeroColorProvider{}
	op := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(100, 0).UTC()}
	if p.MaxHeroColor() != 7 || p.MaxHeroColorPolicyRevision() != "GXB1_PRESERVATION_MAX_HERO_COLOR_V2" {
		t.Fatal("current policy")
	}
	if n, e := p.MaxHeroColorTx(context.Background(), nil, 100001, op); e != nil || n != 7 {
		t.Fatal(n, e)
	}
	if _, e := p.MaxHeroColorTx(context.Background(), nil, 0, op); e == nil {
		t.Fatal("invalid player")
	}
	if _, e := p.MaxHeroColorTx(context.Background(), nil, 100001, operation.Context{}); e == nil {
		t.Fatal("invalid operation")
	}
	if (PreservationMaxHeroColorProvider{}).MaxHeroColor() != 5 {
		t.Fatal("historical policy changed")
	}
}
