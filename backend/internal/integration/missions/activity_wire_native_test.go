//go:build postgres

package missions_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// Authentication is a controlled boundary here; the real service still fences the native actor/session rows.
// This proves native dispatcher/value composition, not stock-client or bearer-transport acceptance.
type activityFixtureAuthority struct{ actor identity.ActorContext }

func (a activityFixtureAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func TestActivityNativeMIDs160169170(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	dispatcher := stockruntime.I5Dispatcher{Authority: activityFixtureAuthority{a}, Service: service, Missions: service}
	request := func(mid uint16, index any) httpedge.Response {
		t.Helper()
		params := map[string]any{}
		if index != nil {
			params["index"] = index
		}
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: runtimeOperation(t, at), MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "fixture", Region: 1}}})
	}
	read := request(160, nil)
	if read.HTTPStatus != 200 || read.Body["extra_info"] == nil {
		t.Fatalf("MID160 %#v", read)
	}
	for _, mid := range []uint16{169, 170} {
		refused := request(mid, int64(1))
		if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(1) {
			t.Fatalf("MID%d incomplete %#v", mid, refused)
		}
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	store := i5store.Store{}
	root, err := store.LockMissionRootTx(ctx, tr, a.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	version := root.StateVersion
	root.DayHuoyue = 30
	root.WeekHuoyue = 500
	root.StateVersion++
	if err = store.SaveMissionRootTx(ctx, tr, root, version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, mid := range []uint16{169, 170} {
		for range 2 {
			reply := request(mid, int64(1))
			if reply.HTTPStatus != 200 || reply.Body["awards"] == nil || reply.Body["huoyue_info"] == nil || reply.Body["error_code"] != nil {
				t.Fatalf("MID%d success/replay %#v", mid, reply)
			}
		}
	}
	invalid := request(170, int64(3))
	if invalid.HTTPStatus != 409 || invalid.Body["error_code"] != int64(1) {
		t.Fatalf("weekly display offset accepted %#v", invalid)
	}
}
