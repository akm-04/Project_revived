package stockruntime

import (
	"context"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// GuildWarRedPointMID stays live while Guild War is inactive (D404): the client
// fires it on a clock (ServerTime.lua:151) outside any Guild War screen.
const GuildWarRedPointMID uint16 = 1152

type GuildWarRedPointDispatcher struct {
	Authority rt.GameplayAuthorityPort
}

func (d GuildWarRedPointDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	if _, fail := (HeroDispatcher{Authority: d.Authority}).actor(c, r); fail != nil {
		return *fail
	}
	return okI5(map[string]any{"is_enroll": false})
}
