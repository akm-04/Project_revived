package i4store

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type actorLivenessRow struct {
	live []string
	err  error
}

func (r actorLivenessRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	*(dest[0].(*[]string)) = r.live
	return nil
}

type actorLivenessQueryer struct {
	query string
	args  []any
	row   actorLivenessRow
}

func (q *actorLivenessQueryer) QueryRow(_ context.Context, query string, args ...any) tx.Row {
	q.query = query
	q.args = args
	return q.row
}

func livenessActor(t *testing.T, contextID, sessionID, accountID string, playerID int64) identity.ActorContext {
	t.Helper()
	parse := func(raw string) ids.UUID {
		u, err := ids.ParseUUID(raw)
		if err != nil {
			t.Fatal(err)
		}
		return u
	}
	cid, _ := identity.ContextIDFrom(parse(contextID))
	sid, _ := identity.SessionIDFrom(parse(sessionID))
	aid, _ := identity.AccountIDFrom(parse(accountID))
	return identity.ActorContext{
		ContextID: cid, SessionID: sid, AccountID: aid, AccountUID: "uid",
		LogicalServerID: 1, PlayerID: identity.PlayerID(playerID),
		ContextGeneration: 1, ContextLivenessVersion: 1, SessionLivenessVersion: 1,
	}
}

func TestValidateActorsReportsLiveContextsInInputOrder(t *testing.T) {
	first := livenessActor(t, "11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222", "33333333-3333-4333-8333-333333333333", 100001)
	second := livenessActor(t, "44444444-4444-4444-8444-444444444444", "55555555-5555-4555-8555-555555555555", "66666666-6666-4666-8666-666666666666", 100002)
	q := &actorLivenessQueryer{row: actorLivenessRow{live: []string{second.ContextID.UUID().String()}}}
	live, err := (RealtimeAuthority{Queryer: q}).ValidateActors(context.Background(), []identity.ActorContext{first, {}, second}, time.Unix(1000, 0))
	if err != nil || len(live) != 3 || live[0] || live[1] || !live[2] {
		t.Fatalf("live=%v err=%v", live, err)
	}
	for _, needle := range []string{"unnest($1::uuid[],$2::uuid[],$3::uuid[],$4::int[],$5::bigint[],$6::bigint[],$7::bigint[],$8::bigint[],$9::text[])", "JOIN gameplay_contexts c ON c.context_id=e.context_id", "c.liveness_version=e.context_liveness_version", "s.liveness_version=e.session_liveness_version", "c.ended_at IS NULL AND s.revoked_at IS NULL"} {
		if !strings.Contains(q.query, needle) {
			t.Fatalf("query missing %q", needle)
		}
	}
	contextIDs, ok := q.args[0].([]string)
	if !ok || len(contextIDs) != 2 || contextIDs[0] != first.ContextID.UUID().String() {
		t.Fatalf("context ids = %v", q.args[0])
	}
}

func TestValidateActorsEmptyAndFailure(t *testing.T) {
	live, err := (RealtimeAuthority{}).ValidateActors(context.Background(), nil, time.Unix(1000, 0))
	if err != nil || len(live) != 0 {
		t.Fatalf("live=%v err=%v", live, err)
	}
	q := &actorLivenessQueryer{row: actorLivenessRow{err: errors.New("db down")}}
	if _, err := (RealtimeAuthority{Queryer: q}).ValidateActors(context.Background(), []identity.ActorContext{livenessActor(t, "11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222", "33333333-3333-4333-8333-333333333333", 100001)}, time.Unix(1000, 0)); err == nil {
		t.Fatal("database error hidden")
	}
}
