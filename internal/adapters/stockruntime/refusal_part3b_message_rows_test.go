package stockruntime

import "testing"

func TestPart3BRefusalCodesHaveClientMessageRows(t *testing.T) {
	rowSets := [][]failureRow{dodgeballFailureRows, eventCentreFailureRows, forumFailureRows, memoirFailureRows}
	for _, rows := range rowSets {
		for _, row := range rows {
			if row.class != failureRefusal || row.code == unprovenRefusalCode || row.code == 0 || row.balance {
				continue
			}
			if !clientMessageIDs[row.code] {
				t.Errorf("refusal code %d has no client message row", row.code)
			}
		}
	}
}
