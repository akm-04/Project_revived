package librarylocal

import (
	"context"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recordingFacts struct{ facts []objective.Fact }

func (*recordingFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (r *recordingFacts) RecordTx(_ context.Context, _ tx.Tx, _ operation.Context, facts ...objective.Fact) error {
	r.facts = append(r.facts, facts...)
	return nil
}

// C4: the favor fact carries the favored partner id so Adventure 10002 can
// name the hero instead of sending special_data 0.
func TestRecordIntimacyCarriesFavorPartner(t *testing.T) {
	recorder := &recordingFacts{}
	service := Service{Facts: recorder}
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: id, StartedAt: time.Unix(1700000000, 0).UTC()}
	if err := service.recordIntimacy(context.Background(), nil, op, identity.PlayerID(170001), 10001001); err != nil {
		t.Fatal(err)
	}
	if len(recorder.facts) != 1 {
		t.Fatalf("facts %d", len(recorder.facts))
	}
	fact := recorder.facts[0]
	if fact.Kind != objective.IntimacyImprovedKind || fact.Delta != 1 || fact.Value != 10001001 {
		t.Fatalf("favor fact %+v", fact)
	}
	if fact.PlayerID != identity.PlayerID(170001) || fact.SourceDomain != "library" {
		t.Fatalf("favor fact identity %+v", fact)
	}
}
