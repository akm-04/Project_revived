package bookskill

import (
	"context"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
)

// K7 (I9_11_CLOCK_ROLLBACK_V1): a store written before a backwards clock step
// (here one hour after the decision) is read, not refused.
func TestBookInputsReadsForwardDatedRoot(t *testing.T) {
	service, owner, _, at := a44Service(a44Catalog(true))
	owner.root.UpdatedAt = at.Add(time.Hour)
	inputs, e := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if e != nil {
		t.Fatalf("forward-dated root refused: %v", e)
	}
	if !inputs.Root.UpdatedAt.Equal(at.Add(time.Hour)) {
		t.Fatalf("read returned a rewritten root: %v", inputs.Root.UpdatedAt)
	}
}

// K2' (I9_11_CLOCK_ROLLBACK_V1): a job started after a backwards clock step
// settles at its stored start, so the read accepts it and nothing completes early.
func TestBookInputsSettlesForwardDatedJob(t *testing.T) {
	service, owner, _, at := a44Service(a44Catalog(true))
	started := at.Add(8 * time.Hour)
	owner.root.Facts.Buildings[1] = book.Building{Level: 1, Job: &book.Job{Occurrence: "op", Revision: a44Revision, StartedAt: started, Duration: 60, Target: 2, Subject: 1}}
	inputs, e := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if e != nil {
		t.Fatalf("forward-dated job refused: %v", e)
	}
	if inputs.MaterializationDue || inputs.Applied.Buildings[1].Job == nil || !inputs.Applied.Buildings[1].Job.StartedAt.Equal(started) {
		t.Fatalf("forward-dated job settled early: due=%v building=%+v", inputs.MaterializationDue, inputs.Applied.Buildings[1])
	}
}

// K7 write half: the committing root keeps the stored forward timestamp.
func TestBookWriteKeepsStoredForwardUpdatedAt(t *testing.T) {
	service, owner, at := a129SpeedService()
	service.RecycleInfo = &a129Recycle{snapshot: map[string]any{}}
	forward := at.Add(time.Hour)
	owner.root.UpdatedAt = forward
	a129Speed(t, service, at)
	if !owner.root.UpdatedAt.Equal(forward) {
		t.Fatalf("write moved the stored timestamp back: %v want %v", owner.root.UpdatedAt, forward)
	}
}
