package librarylocal

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type MarriageEvent struct {
	Player                            identity.PlayerID
	PartnerID, OldVersion, NewVersion int64
	OperationID                       ids.UUID
	ContentRevision                   string
	DecisionAt                        time.Time
}
type PreparedMarriageFact interface {
	ApplyMarriageTx(context.Context, tx.Tx) error
}
type MarriageFactConsumer interface {
	PrepareMarriageTx(context.Context, tx.Tx, MarriageEvent) (PreparedMarriageFact, error)
}
type achievementCapability interface {
	AchievementRevisionTx(context.Context, tx.Queryer, string) (bool, error)
}

// Production content explicitly identifies whether this pinned source operation
// participates. Old pending admissions retain old semantics without backfill.
func (s Service) prepareMarriage(ctx context.Context, t tx.Tx, d Admission, old int64) (PreparedMarriageFact, error) {
	cap, ok := s.Content.(achievementCapability)
	if !ok {
		return nil, nil
	}
	active, e := cap.AchievementRevisionTx(ctx, t, d.ContentRevision)
	if e != nil || !active {
		return nil, e
	}
	if s.Achievements == nil {
		return nil, ErrUnavailable
	}
	return s.Achievements.PrepareMarriageTx(ctx, t, MarriageEvent{Player: identity.PlayerID(d.Actor.Player), PartnerID: d.Command.PartnerID, OldVersion: old, NewVersion: old + 1, OperationID: d.Operation.ID, ContentRevision: d.ContentRevision, DecisionAt: d.DecisionAt})
}
