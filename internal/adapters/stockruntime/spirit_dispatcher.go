package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
	"strconv"
	"strings"
)

type SpiritPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
	Programs(context.Context, identity.ActorContext, operation.Context) ([]map[string]any, error)
}
type SpiritDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   SpiritPort
}

func (s SpiritDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: s.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if s.Service == nil {
		return failSpirit(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	c := app.Command{}
	keys := []string{}
	switch req.Envelope.MID {
	case 3089:
		c.Family = app.Enhance
		keys = []string{"spirit_id", "spirit_ids"}
	case 3090:
		c.Family = app.Lock
		keys = []string{"spirit_id"}
	case 3091:
		c.Family = app.Unlock
		keys = []string{"spirit_id"}
	case 3094:
		c.Family = app.Equip
		keys = []string{"partner_id", "spirit_id", "pos"}
	case 3095:
		c.Family = app.AllOff
		keys = []string{"partner_id"}
	case 3112:
	case 3113:
		c.Family = app.Save
		keys = []string{"name", "collocation", "id"}
	case 3114:
		c.Family = app.Delete
		keys = []string{"id"}
	case 3115:
		c.Family = app.Apply
		keys = []string{"id", "partner_id"}
	default:
		return badHero("unsupported_spirit_mid")
	}
	if !onlyStockGameplayParams(p, keys...) {
		return badHero("invalid_spirit_parameter")
	}
	if req.Envelope.MID == 3112 {
		rows, e := s.Service.Programs(ctx, a, req.Envelope.Operation)
		if e != nil {
			return failSpirit(e)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: rows}
	}
	num := func(key string) (int64, error) {
		v, ok := p[key].(json.Number)
		if !ok {
			return 0, d.ErrInvalid
		}
		n, e := v.Int64()
		if n < 0 || n > d.MaxID {
			return 0, d.ErrInvalid
		}
		return n, e
	}
	for _, key := range keys {
		switch key {
		case "name":
			v, ok := p[key].(string)
			if !ok {
				return badHero("invalid_spirit_name")
			}
			c.Name = v
		case "collocation":
			v, ok := p[key].(string)
			if !ok {
				return badHero("invalid_spirit_collocation")
			}
			parts := strings.Split(v, "|")
			if len(parts) != 6 {
				return badHero("invalid_spirit_collocation")
			}
			for i, x := range parts {
				n, e := strconv.ParseInt(x, 10, 64)
				if e != nil || n < 0 || strconv.FormatInt(n, 10) != x {
					return badHero("invalid_spirit_collocation")
				}
				c.Slots[i] = n
			}
		case "spirit_ids":
			vs, ok := p[key].([]any)
			if !ok {
				return badHero("invalid_spirit_ids")
			}
			for _, v := range vs {
				n, ok := v.(json.Number)
				if !ok {
					return badHero("invalid_spirit_ids")
				}
				id, e := n.Int64()
				if e != nil {
					return badHero("invalid_spirit_ids")
				}
				c.SpiritIDs = append(c.SpiritIDs, id)
			}
		default:
			if key == "id" && c.Family == app.Save {
				if _, ok := p[key]; !ok {
					continue
				}
			}
			n, e := num(key)
			if e != nil {
				return badHero("invalid_spirit_number")
			}
			switch key {
			case "id":
				c.ProgramID = n
			case "partner_id":
				c.PartnerID = n
			case "spirit_id":
				c.SpiritID = n
			case "pos":
				c.Position = n
			}
		}
	}
	if c.Validate() != nil {
		return badHero("invalid_spirit_request")
	}
	r, e := s.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failSpirit(e)
	}
	body, e := s.Service.Response(ctx, a, r, req.Envelope.Operation)
	if e != nil {
		return failSpirit(e)
	}
	return okI5(body)
}
func failSpirit(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, d.ErrInvalid) || errors.Is(e, economy.ErrInsufficientBalance) {
		return badHero("spirit_command_rejected")
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "spirit_unavailable_or_unresolved"}}
}
