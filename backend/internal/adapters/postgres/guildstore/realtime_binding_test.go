package guildstore

import (
	"context"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type realtimeBindingRow struct {
	guildID, eventID int64
	err              error
}

func (r realtimeBindingRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	*(dest[0].(*int64)) = r.guildID
	*(dest[1].(*int64)) = r.eventID
	return nil
}

type realtimeBindingQueryer struct {
	query string
	args  []any
	row   realtimeBindingRow
}

func (q *realtimeBindingQueryer) QueryRow(_ context.Context, sql string, args ...any) tx.Row {
	q.query = sql
	q.args = args
	return q.row
}
func realtimeBindingActor(t *testing.T) identity.ActorContext {
	t.Helper()
	u, err := ids.ParseUUID("22222222-2222-4222-8222-222222222222")
	if err != nil {
		t.Fatal(err)
	}
	cid, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: cid, LogicalServerID: 2, PlayerID: 200001}
}
func TestCurrentRealtimeBindingReadsLatestSameGuildJoinIncarnation(t *testing.T) {
	q := &realtimeBindingQueryer{row: realtimeBindingRow{guildID: 2_000_001, eventID: 77}}
	got, ok, err := (Store{Queryer: q}).CurrentRealtimeBinding(context.Background(), realtimeBindingActor(t))
	if err != nil || !ok || got != (RealtimeBinding{GuildID: 2_000_001, JoinEventID: 77}) {
		t.Fatalf("got=%+v ok=%v err=%v", got, ok, err)
	}
	for _, needle := range []string{"JOIN LATERAL", "AND guild_id=gm.guild_id", "AND event_kind='JOIN'", "ORDER BY event_id DESC", ") e ON TRUE", "g.retired_at IS NULL", "g.logical_server_id=$2"} {
		if !strings.Contains(q.query, needle) {
			t.Fatalf("query missing %q", needle)
		}
	}
}
func TestCurrentRealtimeBindingFailsClosed(t *testing.T) {
	q := &realtimeBindingQueryer{row: realtimeBindingRow{err: kernelstore.ErrNoRows}}
	_, ok, err := (Store{Queryer: q}).CurrentRealtimeBinding(context.Background(), realtimeBindingActor(t))
	if err != nil || ok {
		t.Fatalf("ok=%v err=%v", ok, err)
	}
	q.row = realtimeBindingRow{guildID: 0, eventID: 0}
	if _, _, err := (Store{Queryer: q}).CurrentRealtimeBinding(context.Background(), realtimeBindingActor(t)); err == nil {
		t.Fatal("invalid binding accepted")
	}
	q.row = realtimeBindingRow{err: errors.New("db down")}
	if _, _, err := (Store{Queryer: q}).CurrentRealtimeBinding(context.Background(), realtimeBindingActor(t)); err == nil {
		t.Fatal("db error hidden")
	}
}
