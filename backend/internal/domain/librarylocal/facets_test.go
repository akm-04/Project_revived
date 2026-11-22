package librarylocal

import (
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestPlayerFactsBoardAndBackgroundShape(t *testing.T) {
	now := time.Unix(1000, 0).UTC()
	f, e := NewPlayerFacts(identity.PlayerID(7), now)
	if e != nil {
		t.Fatal(e)
	}
	if f.BgMain != DefaultBgMain || f.BgRoom != DefaultBgRoom || f.BoardPartner != 0 || f.BoardCard != 0 || f.BoardModelID != 0 {
		t.Fatalf("defaults %+v", f)
	}
	board := f
	board.BoardPartner, board.BoardCard, board.BoardModelID = 1, 2, 42
	if e = board.Validate(); e != nil {
		t.Fatal("set board", e)
	}
	for name, mutate := range map[string]func(*PlayerFacts){
		"zero card with partner": func(x *PlayerFacts) { x.BoardPartner, x.BoardCard = 1, 0 },
		"card without partner":   func(x *PlayerFacts) { x.BoardCard, x.BoardModelID = 2, 42 },
		"card above status":      func(x *PlayerFacts) { x.BoardPartner, x.BoardCard = 1, 4 },
		"negative partner":       func(x *PlayerFacts) { x.BoardPartner = -1 },
		"zero background":        func(x *PlayerFacts) { x.BgMain = 0 },
	} {
		x := f
		mutate(&x)
		if !errors.Is(x.Validate(), ErrInvalidFacts) {
			t.Fatalf("%s accepted", name)
		}
	}
}

func TestFacetFactsValidate(t *testing.T) {
	now := time.Unix(1000, 0).UTC()
	pid := identity.PlayerID(7)
	if e := (DialogFact{PlayerID: pid, PartnerID: 1, DialogID: 2, SelectID: 3, UpdatedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (MissionFact{PlayerID: pid, PartnerID: 1, MissionID: 1001, Process: 1, MissionState: 4, UpdatedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (ActAwardFact{PlayerID: pid, PartnerID: 1, ActID: ActCount, AwardedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (TalkClaimFact{PlayerID: pid, TalkID: 1001, ClaimedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (CGClaimFact{PlayerID: pid, CGID: 1, ClaimedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (BackgroundFact{PlayerID: pid, BgID: 3, UnlockedAt: now}).Validate(); e != nil {
		t.Fatal(e)
	}
	if e := (MissionFact{PlayerID: pid, PartnerID: 1, MissionID: 1001, MissionState: 5, UpdatedAt: now}).Validate(); !errors.Is(e, ErrInvalidFacts) {
		t.Fatal("mission state 5 accepted")
	}
	if e := (ActAwardFact{PlayerID: pid, PartnerID: 1, ActID: ActCount + 1, AwardedAt: now}).Validate(); !errors.Is(e, ErrInvalidFacts) {
		t.Fatal("act 5 accepted")
	}
}

func TestCatalogRequiresFourActs(t *testing.T) {
	c := Catalog{Acts: map[int64]ActRule{1: {ID: 1}, 2: {ID: 2}, 3: {ID: 3}, 4: {ID: 4}}}
	if e := c.Validate(); e != nil {
		t.Fatal(e)
	}
	delete(c.Acts, 4)
	if e := c.Validate(); !errors.Is(e, ErrUnqualified) {
		t.Fatal("missing act accepted")
	}
}
