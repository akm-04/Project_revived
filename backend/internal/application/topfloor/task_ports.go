package topfloor

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type TaskStore interface {
	TaskDueServersTx(context.Context, tx.Queryer, time.Time) ([]identity.LogicalServerID, error)
	ReadTaskPeriodTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, number int64, lock bool) (domain.TaskModePeriod, bool, error)
	CreateTaskPeriodTx(requestContext context.Context, transaction tx.Tx, period domain.TaskModePeriod) error
	SaveTaskPeriodTx(requestContext context.Context, transaction tx.Tx, period domain.TaskModePeriod, previousVersion int64) error
	TaskRangeTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, period, first, last int64) ([]domain.Ranked, error)
	TaskRankOfTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, period int64, occupant domain.Occupant) (int64, bool, error)
	AppendTaskPlayerTx(requestContext context.Context, transaction tx.Tx, server identity.LogicalServerID, period, rank int64, player identity.PlayerID) error
	SwapTaskRanksTx(requestContext context.Context, transaction tx.Tx, server identity.LogicalServerID, period int64, challenger, defender domain.Ranked) error
	ReadTaskPlayerTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, period domain.TaskModePeriod, lock bool) (domain.TaskModePlayer, bool, error)
	InsertTaskPlayerTx(requestContext context.Context, transaction tx.Tx, player domain.TaskModePlayer, period domain.TaskModePeriod) error
	SaveTaskPlayerTx(requestContext context.Context, transaction tx.Tx, player domain.TaskModePlayer, period domain.TaskModePeriod, previousVersion int64) error
	ReadTaskFightTx(requestContext context.Context, query tx.Queryer, id ids.UUID, lock bool) (domain.TaskModeFight, bool, error)
	LatestTaskFightTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) (domain.TaskModeFight, bool, error)
	OpenTaskFightsTx(requestContext context.Context, query tx.Queryer, before time.Time, limit int) ([]domain.TaskModeFight, error)
	InsertTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight) error
	FinishTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight, previous int64) error
	TaskPreferenceTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, mode int64) (domain.TaskModeDefense, bool, error)
	SaveTaskPreferenceTx(requestContext context.Context, transaction tx.Tx, player identity.PlayerID, mode int64, defense domain.TaskModeDefense) error
	InsertTaskRecordTx(requestContext context.Context, transaction tx.Tx, record domain.TaskModeRecord, limit int64) error
	TaskRecordsTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) ([]domain.TaskModeRecord, error)
	TaskRecordTx(requestContext context.Context, query tx.Queryer, id int64) (domain.TaskModeRecord, bool, error)
	TaskPeriodsTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID) ([]int64, error)
	InsertTaskDayTx(requestContext context.Context, transaction tx.Tx, day domain.TaskModeDay) error
}
