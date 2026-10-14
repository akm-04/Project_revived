package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type CoursePlayerState struct {
	Player              identity.PlayerID
	Level, LevelVersion int64
	UpdatedAt           time.Time
	Function            *DormFunctionFact
}
type CoursePlayerStateReader interface {
	ReadCoursePlayerStateTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (CoursePlayerState, error)
}
