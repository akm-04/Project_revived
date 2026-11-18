package bookskill

import (
	"context"
	"errors"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const a130BookID int64 = 100

type a130Values struct{ at time.Time }

func (v a130Values) ListStacksTx(_ context.Context, _ tx.Queryer, player identity.PlayerID) ([]economy.StackState, error) {
	return []economy.StackState{{PlayerID: player, ItemID: a130BookID, Quantity: 1, StateVersion: 1, AcquiredAt: v.at, UpdatedAt: v.at}}, nil
}
func (a130Values) ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error) {
	return economy.ScalarBalance{}, false, nil
}

// A normally eligible second skill waits on no client confirmation of the first.
func a130Catalog() book.Catalog {
	catalog := a44Catalog(false)
	catalog.Books[a130BookID] = book.BookRule{ID: a130BookID, Star: 1, Type: 1, Skills: []int64{200, 201}}
	catalog.Skills[201] = book.BookSkillRule{ID: 201, Book: a130BookID, Partner: 1, CostClass: 1, Times: []int64{60}, Prerequisites: []int64{200}}
	catalog.Costs[[2]int64{1, 1}] = book.BookCostRule{Level: 1, Class: 1, Resources: map[string]int64{}}
	return catalog
}

func a130Service() (*Service, *a44Owner, time.Time) {
	at := time.Unix(1000, 0).UTC()
	owner := &a44Owner{root: a44Root(at)}
	content := &a44Content{catalogs: map[string]book.Catalog{a44Revision: a130Catalog()}}
	return &Service{Owner: owner, Content: content, Values: a130Values{at: at}}, owner, at
}

func a130Learn(t *testing.T, s *Service, at time.Time, skill int64) error {
	t.Helper()
	d := Admission{DecisionAt: at, Actor: DurableActor{Player: 1}, Command: Command{Family: Learn, SkillID: skill}, ContentRevision: a44Revision}
	_, e := s.apply(context.Background(), nil, identity.ActorContext{PlayerID: 1}, d)
	return e
}

func TestA130CompletedResearchDoesNotGateNextLearn(t *testing.T) {
	s, owner, at := a130Service()
	if e := a130Learn(t, s, at, 200); e != nil {
		t.Fatal("start first research", e)
	}
	if e := a130Learn(t, s, at.Add(61*time.Second), 201); e != nil {
		t.Fatalf("naturally completed research refused the next Learn: %v", e)
	}
	root := owner.root.Facts
	if root.Skills[200] != 1 {
		t.Fatalf("completed skill not applied once: %#v", root.Skills)
	}
	if root.Research == nil || root.Research.Subject != 201 {
		t.Fatalf("second research not admitted: %#v", root.Research)
	}
	if root.RecentSkill != 0 {
		t.Fatalf("completed research kept its acknowledgement gate: %d", root.RecentSkill)
	}
}

func TestA130RunningResearchStillRefusesAnotherSkill(t *testing.T) {
	s, owner, at := a130Service()
	if e := a130Learn(t, s, at, 200); e != nil {
		t.Fatal("start first research", e)
	}
	if e := a130Learn(t, s, at.Add(time.Second), 201); !errors.Is(e, book.ErrInvalid) {
		t.Fatalf("different running research admitted: %v", e)
	}
	if e := a130Learn(t, s, at.Add(time.Second), 200); e != nil {
		t.Fatalf("running research repeat refused: %v", e)
	}
	if root := owner.root.Facts; root.Research == nil || root.Research.Subject != 200 {
		t.Fatalf("running research moved: %#v", root.Research)
	}
}
