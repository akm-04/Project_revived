package guildprojection

import (
	"context"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type bindingRow struct {
	guildID, eventID int64
	err              error
}

func (r bindingRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	*(dest[0].(*int64)) = r.guildID
	*(dest[1].(*int64)) = r.eventID
	return nil
}

type bindingQueryer struct {
	query string
	args  []any
	row   bindingRow
}

func (q *bindingQueryer) QueryRow(_ context.Context, sql string, args ...any) tx.Row {
	q.query = sql
	q.args = args
	return q.row
}

func bindingActor(t *testing.T) identity.ActorContext {
	t.Helper()
	u, err := ids.ParseUUID("22222222-2222-4222-8222-222222222222")
	if err != nil {
		t.Fatal(err)
	}
	cid, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: cid, LogicalServerID: 2, PlayerID: 200001}
}

func TestRealtimeMembershipReadsCurrentSameGuildJoinIncarnation(t *testing.T) {
	q := &bindingQueryer{row: bindingRow{guildID: 2_000_001, eventID: 77}}
	got, ok, err := (RealtimeMembership{Queryer: q}).CurrentGuildBinding(context.Background(), bindingActor(t))
	if err != nil || !ok || got != (apprealtime.GuildBinding{GuildID: 2_000_001, JoinEventID: 77}) {
		t.Fatalf("got=%+v ok=%v err=%v", got, ok, err)
	}
	for _, needle := range []string{"JOIN LATERAL", "ORDER BY event_id DESC", "e.event_kind='JOIN'", "g.retired_at IS NULL", "g.logical_server_id=$2"} {
		if !strings.Contains(q.query, needle) {
			t.Fatalf("query missing %q", needle)
		}
	}
}

func TestRealtimeMembershipNoCurrentJoinFailsClosed(t *testing.T) {
	q := &bindingQueryer{row: bindingRow{err: kernelstore.ErrNoRows}}
	_, ok, err := (RealtimeMembership{Queryer: q}).CurrentGuildBinding(context.Background(), bindingActor(t))
	if err != nil || ok {
		t.Fatalf("ok=%v err=%v", ok, err)
	}
	q.row = bindingRow{guildID: 0, eventID: 0}
	if _, _, err := (RealtimeMembership{Queryer: q}).CurrentGuildBinding(context.Background(), bindingActor(t)); err == nil {
		t.Fatal("invalid binding accepted")
	}
	q.row = bindingRow{err: errors.New("db down")}
	if _, _, err := (RealtimeMembership{Queryer: q}).CurrentGuildBinding(context.Background(), bindingActor(t)); err == nil {
		t.Fatal("db error hidden")
	}
}
