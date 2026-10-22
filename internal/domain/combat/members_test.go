package combat

import (
	"testing"
	"time"
)

func TestMemberRosterAndSettlement(t *testing.T) {
	if err := ValidMembers(9, []int64{9, 12, 15}); err != nil {
		t.Fatal(err)
	}
	refused := map[string][]int64{
		"single member":      {9},
		"convener not first": {12, 9},
		"duplicate":          {9, 12, 12},
		"invalid player":     {9, 0},
		"over the limit":     {9, 1, 2, 3, 4, 5, 6, 7, 8},
	}
	for name, members := range refused {
		if ValidMembers(9, members) == nil {
			t.Fatal("roster accepted", name)
		}
	}

	member := fixtureSnapshot()
	member.Battle.TeamA = append(member.Battle.TeamA, fixtureActor(OwnedMember, 9))
	if err := member.Validate(); err != nil {
		t.Fatal(err)
	}
	for name, mutate := range map[string]func(*Snapshot){
		"member in schema 2": func(s *Snapshot) { s.Schema = ContextSnapshotSchema },
		"member enemy":       func(s *Snapshot) { s.Battle.WavesB[0] = append(s.Battle.WavesB[0], fixtureActor(OwnedMember, 9)) },
	} {
		s := member
		s.Battle.WavesB = [][]Actor{append([]Actor{}, member.Battle.WavesB[0]...)}
		mutate(&s)
		if s.Validate() == nil {
			t.Fatal("accepted", name)
		}
	}

	at := time.Unix(1700000000, 0).UTC()
	settlement := MemberSettlement{AttemptID: fixtureAttempt, Member: 12, SemanticReceiptID: "member-12", SettledAt: at}
	if err := settlement.Validate(); err != nil {
		t.Fatal(err)
	}
	settlement.SemanticReceiptID = ""
	if settlement.Validate() == nil {
		t.Fatal("settlement without receipt accepted")
	}
	for kind, want := range map[string]bool{"FIXTURE_SETTLED": true, SupersededKind: false, RejectedKind: false, PracticeKind: false} {
		if got := (Attempt{State: Terminal, TerminalKind: kind}).Settleable(); got != want {
			t.Fatal("settleable", kind, got)
		}
	}
	if (Attempt{State: ResolutionReady}).Settleable() {
		t.Fatal("unterminated attempt settleable")
	}
}
