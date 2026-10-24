package bootstrap

import (
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
)

func TestMID1ReconciliationNeverBlindlyTreatsPartialStateAsAbsent(t *testing.T) {
	cases := []struct {
		e    MID1PostconditionEvidence
		want tx.ResolutionState
	}{{MID1PostconditionEvidence{ReceiptFound: true, ReceiptFingerprintMatches: true}, tx.ResolutionCommitted}, {MID1PostconditionEvidence{}, tx.ResolutionUnknown}, {MID1PostconditionEvidence{AuthoritativeNegativeProven: true}, tx.ResolutionAbsent}, {MID1PostconditionEvidence{PlayerFound: true, PlayerMatchesAccountServer: true}, tx.ResolutionUnknown}, {MID1PostconditionEvidence{LiveContextFound: true, LiveContextMatchesTarget: true}, tx.ResolutionUnknown}, {MID1PostconditionEvidence{ReceiptFound: true}, tx.ResolutionUnknown}}
	for _, c := range cases {
		if got := ReconcileMID1Evidence(c.e).State; got != c.want {
			t.Fatalf("%+v got %v want %v", c.e, got, c.want)
		}
	}
}
func TestMID1FingerprintExcludesRawCredentialAndIsStable(t *testing.T) {
	s := sid(2)
	a, e := MID1Fingerprint(s, 1)
	if e != nil {
		t.Fatal(e)
	}
	b, _ := MID1Fingerprint(s, 1)
	c, _ := MID1Fingerprint(s, 2)
	if a != b || a == c {
		t.Fatal("semantic fingerprint instability")
	}
}
