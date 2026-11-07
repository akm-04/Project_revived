package socialrecall

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrRecallRead = errors.New("social recall: invalid reload snapshot")

const (
	maxRecallDoing   = 3
	maxRecallDone    = 512
	maxRecallGot     = 512
	maxRecallAwarded = 25
)

// RecallBase is the owner projection used by the existing MID176 load base. It
// carries only committed task/award facts plus the current completed-target
// observations; it never completes, expires or mutates a task.
type RecallBase struct {
	Doing     []RecallDoing
	Done      []RecallDone
	Got       []identity.PlayerID
	Awarded   []int64
	Recalling []identity.PlayerID
}

type RecallDoing struct {
	PlayerID      identity.PlayerID
	RecallingTime int64
}

type RecallDone struct {
	PlayerID identity.PlayerID
	Baseline domain.Baseline
	Current  domain.Baseline
}

type RecallBaseReader interface {
	ReadRecallBaseTx(context.Context, tx.Scope, identity.ActorContext, string, time.Time, []identity.PlayerID) (RecallBase, error)
}

func (base RecallBase) Validate(server identity.LogicalServerID) error {
	if len(base.Doing) > maxRecallDoing || len(base.Done) > maxRecallDone || len(base.Got) > maxRecallGot || len(base.Awarded) > maxRecallAwarded || len(base.Recalling) > maxRecallGot {
		return ErrRecallRead
	}
	previous := identity.PlayerID(0)
	for _, row := range base.Doing {
		if !row.PlayerID.Valid() || row.RecallingTime <= 0 || row.PlayerID <= previous {
			return ErrRecallRead
		}
		previous = row.PlayerID
	}
	previous = 0
	for _, row := range base.Done {
		if !row.PlayerID.Valid() || row.PlayerID <= previous || row.Baseline.Validate() != nil || row.Current.Validate() != nil {
			return ErrRecallRead
		}
		previous = row.PlayerID
	}
	previous = 0
	for _, player := range base.Got {
		if !player.Valid() || player <= previous {
			return ErrRecallRead
		}
		previous = player
	}
	previousAward := int64(0)
	for _, award := range base.Awarded {
		if award <= previousAward {
			return ErrRecallRead
		}
		previousAward = award
	}
	previous = 0
	for _, player := range base.Recalling {
		if !player.Valid() || player <= previous {
			return ErrRecallRead
		}
		previous = player
	}
	return nil
}
