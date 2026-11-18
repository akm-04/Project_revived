//go:build postgres

package publicshowcase_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	contentstore "gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	i4store "gxb.local/backend/v2/internal/adapters/postgres/i4store"
	i5store "gxb.local/backend/v2/internal/adapters/postgres/i5store"
	publicprofilestore "gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	socialrelationstore "gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	stockruntime "gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	identity "gxb.local/backend/v2/internal/domain/identity"
	tx "gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	wireproto "gxb.local/backend/v2/internal/protocol/wire"
)

type fixedAuthority struct{ actor identity.ActorContext }

func (a fixedAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

// Provider fields past the privacy gate are nil on purpose: the privacy and
// empty-slot cases must answer before any rich provider is consulted.
func refusalReads(p *pg.Pool) app.ReadService {
	return app.ReadService{
		Runner:  tx.Runner{DB: p},
		Fresh:   p,
		Time:    pg.AuthoritativeTime{Queryer: p},
		Content: contentstore.Store{},
		Basic: app.BasicReader{
			Roots:       app.RootService{Store: publicprofilestore.Store{}},
			Players:     i4store.PlayerRootLocker{},
			Fence:       i5store.Store{},
			PlayerBasis: i5store.Store{},
			Relations:   socialrelationstore.Store{},
			Content:     contentstore.Store{},
		},
		Slots: publicprofilestore.Store{},
	}
}

func dispatchRead(t *testing.T, d stockruntime.PublicProfileReadDispatcher, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	operation := op()
	return d.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wireproto.RequestEnvelope{MID: mid, ReceivedAt: time.Now().UTC(), Params: params, Claims: wireproto.CredentialClaims{Token: "bearer", Region: 1}, Operation: operation}})
}

func socialRoots(t *testing.T, p *pg.Pool, ids ...identity.PlayerID) {
	t.Helper()
	for _, id := range ids {
		sqlExec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`, int64(id))
	}
}

func TestA121PrivacyAndEmptySlotAreRefusals(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	socialRoots(t, p, a.PlayerID, b.PlayerID)
	assign(t, p, b, app.Command{Kind: app.HideCommand, Hide: []int16{2}}, op())
	d := stockruntime.PublicProfileReadDispatcher{Authority: fixedAuthority{a}, Service: refusalReads(p)}
	cases := []struct {
		mid    uint16
		params map[string]any
	}{
		{1829, map[string]any{"to_player_id": int64(b.PlayerID), "sub_type": int64(2)}},
		{1838, map[string]any{"to_player_id": int64(b.PlayerID), "index": int64(1)}},
	}
	for _, tc := range cases {
		got := dispatchRead(t, d, tc.mid, tc.params)
		if got.HTTPStatus != 409 || got.Body["error_code"] != int64(35028) || got.Body["error_msg"] != "" {
			t.Fatalf("MID %d denial %+v", tc.mid, got)
		}
		if len(got.Body) != 2 {
			t.Fatalf("MID %d refusal carries profile fields %+v", tc.mid, got.Body)
		}
	}
}

func TestA121ProviderFaultStaysDefect(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	socialRoots(t, p, a.PlayerID, b.PlayerID)
	d := stockruntime.PublicProfileReadDispatcher{Authority: fixedAuthority{a}, Service: refusalReads(p)}
	got := dispatchRead(t, d, 1829, map[string]any{"to_player_id": int64(b.PlayerID), "sub_type": int64(2)})
	if got.HTTPStatus != 500 {
		t.Fatalf("provider fault %+v", got)
	}
}
