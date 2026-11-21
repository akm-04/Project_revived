//go:build postgres

package playerdisplay_test

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
	"strconv"
	"sync"
	"testing"
	"time"
)

// leagueMIDAuthority resolves the stock bearer through the same port the
// production dispatcher uses; the credential check is not what these tests prove.
type leagueMIDAuthority struct{ actor identity.ActorContext }

func (a leagueMIDAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func leagueMID(dispatcher stockruntime.LeagueDispatcher, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	if params == nil {
		params = map[string]any{}
	}
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation:  op(),
		MID:        mid,
		Transport:  wire.TransportHTTP,
		Direction:  wire.DirectionC2S,
		ReceivedAt: time.Now().UTC(),
		Params:     params,
		Claims:     wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)},
	}}
	return dispatcher.Dispatch(context.Background(), request)
}

func requireLeagueOK(t *testing.T, response httpedge.Response, mid uint16) {
	t.Helper()
	if response.HTTPStatus != 200 {
		t.Fatalf("MID %d answered %d %#v", mid, response.HTTPStatus, response.Body)
	}
}

// A first-win claim is followed immediately by the menu refresh and opponent
// reads. One backwards clock step after the claim must not turn the owner's own
// stored timestamps into "league: conflicting state" for those reads, nor for
// the fight the stock window starts from a fast opponent tap.
func TestI9_12LeagueClaimThenReadBackwardClockNative(t *testing.T) {
	p := pool(t)
	s, clock, _, a, b, hero, _ := leagueActors(t, p)
	dispatcher := stockruntime.LeagueDispatcher{Authority: leagueMIDAuthority{a}, Service: s}
	fight := leagueFight(t, s, a, b, hero)
	winner := a
	if !fight.Match.Win {
		winner = b
	}
	dispatcher = stockruntime.LeagueDispatcher{Authority: leagueMIDAuthority{winner}, Service: s}
	requireLeagueOK(t, leagueMID(dispatcher, winner, 2804, nil), 2804)
	at, err := clock.Now(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	clock.Set(at.Add(-time.Hour))
	requireLeagueOK(t, leagueMID(dispatcher, winner, 2800, nil), 2800)
	requireLeagueOK(t, leagueMID(dispatcher, winner, 2801, map[string]any{"enemy_id": int64(leagueOther(winner, a, b).PlayerID)}), 2801)
}

func leagueOther(winner, a, b identity.ActorContext) identity.ActorContext {
	if winner.PlayerID == a.PlayerID {
		return b
	}
	return a
}

// A fast opponent tap sends the menu refresh and the opponent read together; a
// second tap repeats them while the fight flow starts.
func TestI9_12LeagueDoubleTapBackwardClockNative(t *testing.T) {
	p := pool(t)
	s, clock, _, a, b, hero, _ := leagueActors(t, p)
	at, err := clock.Now(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	clock.Set(at.Add(-time.Hour))
	dispatcher := stockruntime.LeagueDispatcher{Authority: leagueMIDAuthority{a}, Service: s}
	var group sync.WaitGroup
	responses := make(chan httpedge.Response, 4)
	for range 2 {
		group.Add(1)
		go func() {
			defer group.Done()
			responses <- leagueMID(dispatcher, a, 2800, nil)
		}()
		group.Add(1)
		go func() {
			defer group.Done()
			responses <- leagueMID(dispatcher, a, 2801, map[string]any{"enemy_id": int64(b.PlayerID)})
		}()
	}
	group.Wait()
	close(responses)
	for response := range responses {
		requireLeagueOK(t, response, 2800)
	}
	requireLeagueOK(t, leagueMID(dispatcher, a, 2802, map[string]any{"enemy_id": int64(b.PlayerID), "formation": strconv.FormatInt(hero, 10)}), 2802)
	requireLeagueOK(t, leagueMID(dispatcher, a, 2800, nil), 2800)
}
