//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// unpinnedDispatchAuthority resolves the stock bearer to one actor without
// touching the operation's policy set, as the HTTP edge does.
type unpinnedDispatchAuthority struct{ actor identity.ActorContext }

func (a unpinnedDispatchAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func unpinnedRequest(mid uint16, actor identity.ActorContext, at time.Time, params map[string]any) httpedge.DispatchRequest {
	params["token"] = "bearer"
	params["region"] = int64(actor.LogicalServerID)
	op := operation.Context{ID: uuid(), StartedAt: at}
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, ReceivedAt: at, Params: params,
		Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}}}
}

// TestI9_10CoopCommandsThroughUnpinnedDispatcher drives every Sophia co-op
// command the way the HTTP edge does: an operation with no policy set.
func TestI9_10CoopCommandsThroughUnpinnedDispatcher(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := adventureOwner(t, p, server, 100, 10001001, 10001002)
	b, bPicks := adventureOwner(t, p, server, 100, 10001003, 10001004)
	c, cPicks := adventureOwner(t, p, server, 100, 10001005, 10001006)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "dispatch-coop")
	for index, member := range []identity.ActorContext{b, c} {
		putAdventureOccurrence(t, p, member.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), fmt.Sprintf("dispatch-coop-%d", index))
	}

	created := dispatch(t, mode, a, unpinnedRequest(2423, a, clock.at, map[string]any{"table_id": int64(da.EventIllusion)}))
	roomInfo, _ := created["room_info"].(map[string]any)
	roomID, _ := roomInfo["room_id"].(int64)
	if roomID <= 0 {
		t.Fatalf("2423 room %#v", created)
	}

	// 2427 is the Sophia invite that used to answer 503 on the unpinned context.
	dispatch(t, mode, a, unpinnedRequest(2427, a, clock.at, map[string]any{"player_id": int64(b.PlayerID), "table_id": int64(da.EventIllusion)}))
	for _, member := range []identity.ActorContext{b, c} {
		dispatch(t, mode, member, unpinnedRequest(2425, member, clock.at, map[string]any{"room_id": roomID, "table_id": int64(da.EventIllusion)}))
	}
	dispatch(t, mode, a, unpinnedRequest(2428, a, clock.at, map[string]any{"table_id": int64(da.EventIllusion)}))
	for _, member := range []struct {
		actor identity.ActorContext
		picks []int64
	}{{a, aPicks}, {b, bPicks}, {c, cPicks}} {
		for position, hero := range member.picks {
			dispatch(t, mode, member.actor, unpinnedRequest(2429, member.actor, clock.at, map[string]any{
				"partner_id": hero, "pos": int64(position + 1), "table_id": int64(da.EventIllusion)}))
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		dispatch(t, mode, member, unpinnedRequest(2430, member, clock.at, map[string]any{"table_id": int64(da.EventIllusion)}))
	}
	started := dispatch(t, mode, a, unpinnedRequest(2411, a, clock.at, map[string]any{"table_id": int64(da.EventIllusion)}))
	if report, _ := started["battle_report"].(string); report == "" {
		t.Fatalf("2411 report %#v", started)
	}
	dispatch(t, mode, a, unpinnedRequest(2426, a, clock.at, map[string]any{"table_id": int64(da.EventIllusion)}))
}

func dispatch(t *testing.T, mode appadventure.Mode, actor identity.ActorContext, request httpedge.DispatchRequest) map[string]any {
	t.Helper()
	dispatcher := stockruntime.AdventureDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: mode}
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 {
		t.Fatalf("mid %d status %d body %#v cause %v", request.Envelope.MID, response.HTTPStatus, response.Body, response.Cause)
	}
	if response.Body == nil {
		return map[string]any{}
	}
	return response.Body
}
