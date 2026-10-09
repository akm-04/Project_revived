//go:build postgres && river

package riveradapter

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/riverqueue/river"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"gxb.local/backend/v2/internal/adapters/postgres"
	gen "gxb.local/backend/v2/internal/application/generation"
	gb "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// guildInsertOnly exposes only transaction insertion; no runtime/client/Start
// escapes this private wrapper. The client has no queues or running workers.
const GuildPhysicalQueue = "guild_materialization"

type guildInsertOnly struct{ queue Queue }

func NewGuildInsertOnly(pool *pgxpool.Pool) (obligation.Queue, error) {
	if pool == nil {
		return nil, errors.New("nil Guild insert-only PostgreSQL pool")
	}
	// Register the static mechanism kind for library insert validation. The empty
	// dispatcher returns errors if ever invoked; no semantic worker is activated.
	dispatch, e := gen.NewDispatchRegistry()
	if e != nil {
		return nil, e
	}
	workers, e := NewWorkers(dispatch)
	if e != nil {
		return nil, e
	}
	client, e := river.NewClient(riverpgxv5.New(pool), &river.Config{Workers: workers})
	if e != nil {
		return nil, e
	}
	return guildInsertOnly{queue: Queue{Client: client}}, nil
}
func (q guildInsertOnly) InsertTx(c context.Context, t tx.Tx, o obligation.Obligation) error {
	if e := gb.ValidateObligation(o); e != nil {
		return e
	}
	raw, ok := postgres.UnwrapTx(t)
	if !ok {
		return errors.New("Guild transaction not pgx-backed")
	}
	// Keep semantic queue in immutable args; qualify the explicit finite physical
	// River mapping separately. No global queue rewrite or job-derived authority.
	_, e := q.queue.Client.InsertTx(c, raw, jobArgsFromObligation(o), &river.InsertOpts{Queue: GuildPhysicalQueue, ScheduledAt: o.DueAt.UTC()})
	return e
}
