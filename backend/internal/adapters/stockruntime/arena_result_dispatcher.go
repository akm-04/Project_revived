package stockruntime

import (
	"context"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ArenaFightResultMIDs is the I9-11D legacy arena report MID. It is decoded by
// the existing zlib edge and answered by the F4e duplicate terminal.
var ArenaFightResultMIDs = []uint16{279}

// ArenaResultDispatcher answers MID 279 with the duplicate terminal the client
// treats as errorIdFightExist (BattleCreateReport.lua:1432-1437). It settles
// nothing: Top Floor settles at MID 280 only.
type ArenaResultDispatcher struct {
	Authority rt.GameplayAuthorityPort
}

func NewArenaResultDispatcher(authority rt.GameplayAuthorityPort) ArenaResultDispatcher {
	return ArenaResultDispatcher{Authority: authority}
}

func (d ArenaResultDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if _, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req); fail != nil {
		return *fail
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"error_code":    int64(fightExist),
		"partner_favor": map[string]any{},
		"items":         []any{},
	}}
}
