package coursestore

import (
	"context"
	"errors"
	"time"

	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ClaimGiftBoxDayTx consumes one game day's free box. The caller holds the
// course root lock, so a false result means the day was already claimed.
func (Store) ClaimGiftBoxDayTx(ctx context.Context, t tx.Tx, p identity.PlayerID, day int64, at time.Time) error {
	if !p.Valid() || at.IsZero() {
		return course.ErrUnqualified
	}
	tag, e := t.Exec(ctx, `UPDATE player_course_roots SET gift_box_day=$2,state_version=state_version+1,updated_at=$3 WHERE player_id=$1 AND gift_box_day<>$2`, int64(p), day, at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("course: gift box day already claimed")
	}
	return nil
}
