package provision

import (
	"gxb.local/backend/v2/internal/domain/objective"
	"strings"
	"testing"
)

func TestSignInBonusFixtureIsExplicitAndBounded(t *testing.T) {
	root := objective.SignRoot{Month: 202610, Day: 1, ContentRevision: strings.Repeat("a", 64), StateVersion: 1}
	month := objective.SignMonth{Month: 10, Awards: []objective.SignAward{{}, {}, {DoubleVIP: 1}}}
	next, err := signInBonusFixture(root, month)
	if err != nil || next.Count != 2 || next.Signed != 0 || next.StateVersion != 2 {
		t.Fatal(next, err)
	}
	root.Count = 3
	if _, err = signInBonusFixture(root, month); err == nil {
		t.Fatal("advanced calendar overwritten")
	}
	root.Count = 0
	month.Awards[2].DoubleVIP = -1
	if _, err = signInBonusFixture(root, month); err == nil {
		t.Fatal("no bonus row accepted")
	}
}
