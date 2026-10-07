package channelchat

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type observationFixture struct {
	expected tx.Tx
	at       time.Time
}

func (f observationFixture) ReadTx(context.Context, tx.Tx, ar.Admission, bool) (playerpresentation.Minimal, error) {
	return playerpresentation.Minimal{}, nil
}
func (f observationFixture) ObserveTx(_ context.Context, t tx.Tx, _ ar.Admission, _ bool) (Observation, error) {
	if t != f.expected {
		return Observation{}, errors.New("foreignTx")
	}
	return Observation{At: f.at, Sender: playerpresentation.Minimal{PlayerID: 100001, Name: "canonical"}}, nil
}

type ownerFixture struct {
	expected         tx.Tx
	at               time.Time
	txActive         *fakeTx
	seen             int
	fail             error
	scratch          Scratch
	audience         CampAudience
	recipientAllowed bool
}

func (f *ownerFixture) check(t tx.Tx, at time.Time) error {
	f.seen++
	if t != f.expected || at != f.at || f.txActive.commits != 0 {
		return errors.New("not same activeTx/DB observation")
	}
	return f.fail
}
func (f *ownerFixture) ReadArenaTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RecordSelection) (Owned[Arena], error) {
	e := f.check(t, at)
	return Owned[Arena]{Value: Arena{RecordID: s.RecordID, EnemyName: "canonicalenemy", PlayerName: "forgedownername"}, Source: SourceObservation{"record:1", 1}}, e
}
func (f *ownerFixture) ReadScratchTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, _ ScratchSelection) (Owned[Scratch], error) {
	e := f.check(t, at)
	return Owned[Scratch]{Value: f.scratch, Source: SourceObservation{"scratch:1", 1}}, e
}
func (f *ownerFixture) ReadCampTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s CampSelection) (Owned[Camp], CampAudience, error) {
	e := f.check(t, at)
	return Owned[Camp]{Value: Camp{DisplayRoomID: f.audience.DisplayRoomID, CampID: f.audience.CampID, Text: s.Text, IsEmoticon: s.IsEmoticon, EmoticonID: s.EmoticonID}, Source: SourceObservation{"camp:1", 1}}, f.audience, e
}
func (f *ownerFixture) AuthorizeCampRecipientTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, _ CampAudience) error {
	e := f.check(t, at)
	if e != nil {
		return e
	}
	if !f.recipientAllowed {
		return errors.New("recipientwrongcamp")
	}
	return nil
}
func structuredServiceFixture(t *testing.T, ambiguous bool) (Service, *ownerFixture, *fakeDB, ar.Admission) {
	t.Helper()
	ft := &fakeTx{}
	if ambiguous {
		ft.commitError = errors.New("lostreadcommit")
	}
	db := &fakeDB{t: ft}
	at := time.Unix(100, 0)
	owner := &ownerFixture{expected: ft, at: at, txActive: ft, audience: CampAudience{EventID: 11, CampID: 1, DisplayRoomID: 0}}
	a := ar.Admission{}
	a.Domain.Actor.PlayerID = identity.PlayerID(100001)
	return Service{Runner: tx.Runner{DB: db}, Operations: operation.Factory{Clock: clock.System{}}, Reader: observationFixture{ft, at}, Owners: Owners{Arena: owner, Scratch: owner, Camp: owner}}, owner, db, a
}
func TestStructuredCanonicalOwnerSameTransactionAndUnknownPrivacy(t *testing.T) {
	for _, unknown := range []bool{false, true} {
		t.Run(map[bool]string{false: "definite", true: "unknown"}[unknown], func(t *testing.T) {
			s, o, db, a := structuredServiceFixture(t, unknown)
			p, e := s.PrepareStructured(context.Background(), a, Selector{Kind: ArenaReference, Arena: &RecordSelection{100001, 2}})
			if db.begins != 1 || db.t.commits != 1 || !db.options.ReadOnly || db.options.Isolation != tx.RepeatableRead || o.seen != 1 {
				t.Fatal(db, o)
			}
			if unknown {
				if e == nil || p.Message.Arena != nil {
					t.Fatal(p, e)
				}
			} else if e != nil || p.Message.Arena.PlayerName != "canonical" || p.Message.Arena.PlayerID != 100001 || p.Message.Arena.EnemyName != "canonicalenemy" {
				t.Fatal(p, e)
			}
		})
	}
}
func TestStructuredUnavailableForgedReferenceAndUnionBeforeDatabase(t *testing.T) {
	s, _, db, a := structuredServiceFixture(t, false)
	cases := []Selector{{Kind: PeakReference, Peak: &RecordSelection{100001, 1}}, {Kind: ArenaReference, Arena: &RecordSelection{100002, 1}}, {Kind: ArenaReference, Arena: &RecordSelection{100001, 1}, Camp: &CampSelection{Text: "x"}}, {Kind: CampMessage, Camp: &CampSelection{Text: "x", ClaimedCamp: -1}}}
	for _, c := range cases {
		if _, e := s.PrepareStructured(context.Background(), a, c); e == nil {
			t.Fatal(c)
		}
	}
	if db.begins != 0 {
		t.Fatal(db)
	}
}
func TestStructuredScratchDefensiveCopyAndEmptyArrays(t *testing.T) {
	s, o, _, a := structuredServiceFixture(t, false)
	o.scratch = Scratch{RandomCards: []int64{1}, Cards: []int64{}, ScratchStatus: []int64{0}}
	p, e := s.PrepareStructured(context.Background(), a, Selector{Kind: ScratchShare, Scratch: &ScratchSelection{}})
	if e != nil {
		t.Fatal(e)
	}
	o.scratch.RandomCards[0] = 99
	if p.Message.Scratch.RandomCards[0] != 1 || p.Message.Scratch.Cards == nil {
		t.Fatal(p)
	}
}
func TestStructuredOwnerFailureReturnsNoProjection(t *testing.T) {
	s, o, db, a := structuredServiceFixture(t, false)
	o.fail = errors.New("staleowner")
	p, e := s.PrepareStructured(context.Background(), a, Selector{Kind: ArenaReference, Arena: &RecordSelection{100001, 1}})
	if e == nil || p.Message.Arena != nil || db.t.commits != 0 {
		t.Fatal(p, e)
	}
}
func TestStructuredCampCannotSubstituteDisplayZeroForEventAuthority(t *testing.T) {
	for _, event := range []int64{0, 11} {
		s, o, _, a := structuredServiceFixture(t, false)
		o.audience.EventID = event
		p, e := s.PrepareStructured(context.Background(), a, Selector{Kind: CampMessage, Camp: &CampSelection{Text: "x", ClaimedCamp: 1, DisplayRoomID: 0}})
		if (e == nil) != (event > 0) {
			t.Fatal(p, e)
		}
	}
}
func TestStructuredCampRecipientCanonicalAndDefiniteGate(t *testing.T) {
	for _, allowed := range []bool{false, true} {
		s, o, db, a := structuredServiceFixture(t, false)
		o.recipientAllowed = allowed
		p := PreparedStructured{Message: Structured{Kind: CampMessage}, Audience: &o.audience}
		e := s.AuthorizeStructuredRecipient(context.Background(), a, p)
		if (e == nil) != allowed || o.seen != 1 || db.begins != 1 {
			t.Fatal(e)
		}
	}
}

func (f *ownerFixture) ReadPeakTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RecordSelection) (Owned[Peak], error) {
	e := f.check(t, at)
	return Owned[Peak]{Value: Peak{RecordID: s.RecordID}, Source: SourceObservation{"fixture:Peak", 1}}, e
}

func (f *ownerFixture) ReadIllusionTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RoomSelection) (Owned[Invitation], error) {
	e := f.check(t, at)
	return Owned[Invitation]{Value: Invitation{RoomID: s.RoomID}, Source: SourceObservation{"fixture:Illusion", 1}}, e
}

func (f *ownerFixture) ReadOccultTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RoomSelection) (Owned[Occult], error) {
	e := f.check(t, at)
	return Owned[Occult]{Value: Occult{RoomID: s.RoomID}, Source: SourceObservation{"fixture:Occult", 1}}, e
}

func (f *ownerFixture) ReadAdventureIllusionTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RoomSelection) (Owned[Invitation], error) {
	e := f.check(t, at)
	return Owned[Invitation]{Value: Invitation{RoomID: s.RoomID}, Source: SourceObservation{"fixture:AdventureIllusion", 1}}, e
}

func (f *ownerFixture) ReadDefenseTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RoomSelection) (Owned[Defense], error) {
	e := f.check(t, at)
	return Owned[Defense]{Value: Defense{RoomID: s.RoomID}, Source: SourceObservation{"fixture:Defense", 1}}, e
}

func (f *ownerFixture) ReadRagnarokTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s RoomSelection) (Owned[Invitation], error) {
	e := f.check(t, at)
	return Owned[Invitation]{Value: Invitation{RoomID: s.RoomID}, Source: SourceObservation{"fixture:Ragnarok", 1}}, e
}

func TestStructuredAllNamedOwnerPortsSameTxObservation(t *testing.T) {
	selectors := []Selector{{Kind: PeakReference, Peak: &RecordSelection{100001, 1}}, {Kind: IllusionInvitation, Illusion: &RoomSelection{1}}, {Kind: OccultInvitation, Occult: &RoomSelection{1}}, {Kind: AdventureIllusionInvitation, AdventureIllusion: &RoomSelection{1}}, {Kind: DefenseInvitation, Defense: &RoomSelection{1}}, {Kind: RagnarokInvitation, Ragnarok: &RoomSelection{1}}}
	for _, sel := range selectors {
		t.Run(string(sel.Kind), func(t *testing.T) {
			s, o, db, a := structuredServiceFixture(t, false)
			s.Owners = Owners{Peak: o, Illusion: o, Occult: o, AdventureIllusion: o, Defense: o, Ragnarok: o}
			p, e := s.PrepareStructured(context.Background(), a, sel)
			if e != nil || p.Message.Kind != sel.Kind || o.seen != 1 || db.t.commits != 1 {
				t.Fatal(p, e)
			}
		})
	}
}
