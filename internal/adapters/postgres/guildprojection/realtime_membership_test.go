package guildprojection

import (
	"context"
	"testing"

	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type bindingProjectionRow struct{ guildID, eventID int64 }

func (r bindingProjectionRow) Scan(dest ...any) error {
	*(dest[0].(*int64)) = r.guildID
	*(dest[1].(*int64)) = r.eventID
	return nil
}

type bindingProjectionQueryer struct{ row bindingProjectionRow }

func (q bindingProjectionQueryer) QueryRow(context.Context, string, ...any) tx.Row { return q.row }
func projectionActor(t *testing.T) identity.ActorContext {
	t.Helper()
	u, err := ids.ParseUUID("22222222-2222-4222-8222-222222222222")
	if err != nil {
		t.Fatal(err)
	}
	cid, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: cid, LogicalServerID: 2, PlayerID: 200001}
}
func TestRealtimeMembershipTranslatesGuildOwnerBinding(t *testing.T) {
	got, ok, err := (RealtimeMembership{Queryer: bindingProjectionQueryer{row: bindingProjectionRow{guildID: 2_000_001, eventID: 77}}}).CurrentGuildBinding(context.Background(), projectionActor(t))
	want := apprealtime.GuildBinding{GuildID: 2_000_001, JoinEventID: 77}
	if err != nil || !ok || got != want {
		t.Fatalf("got=%+v ok=%v err=%v", got, ok, err)
	}
}
