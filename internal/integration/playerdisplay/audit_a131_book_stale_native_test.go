//go:build postgres

package playerdisplay_test

import (
	"context"
	"net/http"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const staleStateRefusalCode int64 = 40002

type fixedBookAuthority struct{ actor identity.ActorContext }

func (f fixedBookAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return f.actor, nil
}

// A decision time bound before B's committed research is a typed stale refusal,
// and the read leaves B's research untouched.
func TestA131OvertakenBookReadServesStaleRefusal(t *testing.T) {
	p := pool(t)
	a, _, s := bookFixture(t, p)
	seedIdleBookRoot(t, p, a, activeBookRevision(t, s))
	bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1})
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010001})
	research := bookRoot(t, p, a)
	if research.Facts.Research == nil {
		t.Fatal("fixture B did not start research")
	}
	s.Timed.Binder.Time = fixedBookReadTime{at: research.UpdatedAt.Add(-time.Millisecond)}

	dispatcher := stockruntime.BookDispatcher{Authority: fixedBookAuthority{actor: a}, Service: s}
	for _, mid := range []uint16{1056, 1059} {
		request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, ReceivedAt: time.Now().UTC(), Operation: op(), Claims: wire.CredentialClaims{Token: "bearer", Region: int64(a.LogicalServerID)}}}
		response := dispatcher.Dispatch(ctx, request)
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != staleStateRefusalCode {
			t.Fatalf("MID %d status=%d body=%#v", mid, response.HTTPStatus, response.Body)
		}
	}
	after := bookRoot(t, p, a)
	if !reflect.DeepEqual(after, research) {
		t.Fatalf("stale read changed B's committed book state:\nbefore %+v\nafter  %+v", research, after)
	}
}
