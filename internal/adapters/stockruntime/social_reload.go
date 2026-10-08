package stockruntime

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	reload "gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"math"
	"sync"
	"time"
)

func ValidateSocialReload(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return rt.ErrInvalidS2CPayload
	}
	m, e := o.StrictMap()
	if e != nil || len(m) != 2 {
		return rt.ErrInvalidS2CPayload
	}
	number := func(v any, want int64) bool {
		switch n := v.(type) {
		case int64:
			return n == want
		case int32:
			return int64(n) == want
		case int:
			return int64(n) == want
		case float64:
			return !math.IsNaN(n) && !math.IsInf(n, 0) && n == float64(want)
		default:
			return false
		}
	}
	if !number(m["player_id"], 0) {
		return rt.ErrInvalidS2CPayload
	}
	selectors := 0
	for k, v := range m {
		if k == "player_id" {
			continue
		}
		if (k != "friend_list" && k != "friend_req" && k != "friend_notice") || !number(v, 1) {
			return rt.ErrInvalidS2CPayload
		}
		selectors++
	}
	if selectors != 1 {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}
func NewSocialEventRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry([]rt.DirectRegistration{{MID: mids.MIDForceReload, Roles: []rt.Role{rt.World}, Validate: ValidateSocialReload}}, nil)
}

type SocialReloadQueries interface {
	Reload(context.Context, sr.ReloadReference, operation.Context) (reload.Intent, bool, error)
}
type SocialDeliveryTime interface {
	Now(context.Context) (time.Time, error)
}
type SocialReloadHandler struct {
	Service         SocialReloadQueries
	Operations      operation.Factory
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
	IsStaleActor    func(error) bool
}

func (s SocialReloadHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	ref, e := sr.DecodeReloadReference(raw)
	if e != nil {
		return e
	}
	if s.Service == nil || s.Registry == nil || s.Authority == nil || s.Time == nil || s.MaxHandles < 1 {
		return sr.ErrInvalidState
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	op, e := s.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	intent, ok, e := s.Service.Reload(ctx, ref, op)
	if e != nil {
		return e
	}
	if !ok {
		return nil
	}
	handles := s.Registry.ByPlayerRole(intent.Recipient, domainrt.World)
	if len(handles) > s.MaxHandles {
		return errors.New("Social fanout exceeds serving connection bound")
	}
	selectors := []string{}
	switch intent.Purpose {
	case socialreloadref.ReloadGiftSenderList:
		selectors = []string{"friend_list"}
	case socialreloadref.ReloadGiftRecipientNotice:
		selectors = []string{"friend_notice"}
	case sr.ReloadRequest:
		selectors = []string{"friend_req"}
	case sr.ReloadDeny:
		selectors = []string{"friend_notice"}
	case sr.ReloadAccept, sr.ReloadDelete:
		selectors = []string{"friend_list", "friend_notice"}
	default:
		return sr.ErrInvalidState
	}
	jobs := make(chan SessionHandle)
	var wg sync.WaitGroup
	workers := 8
	if len(handles) < workers {
		workers = len(handles)
	}
	errs := make(chan error, workers)
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for h := range jobs {
				m, ok := h.Metadata()
				if !ok || !s.Registry.IsCurrent(h) || m.PlayerID != intent.Recipient || m.PhysicalRole != domainrt.World || m.RoomID != int64(m.LogicalServerID) {
					continue
				}
				at, e := s.Time.Now(ctx)
				if e != nil {
					select {
					case errs <- e:
					default:
					}
					continue
				}
				actor := identity.ActorContext{AccountID: m.AccountID, AccountUID: m.AccountUID, SessionID: m.SessionID, ContextID: m.ContextID, LogicalServerID: m.LogicalServerID, PlayerID: m.PlayerID, ContextGeneration: m.ContextGeneration, SessionLivenessVersion: m.SessionLivenessVersion, ContextLivenessVersion: m.ContextLivenessVersion}
				if e := s.Authority.ValidateActor(ctx, actor, at); e != nil {
					if s.IsStaleActor != nil && s.IsStaleActor(e) {
						s.Registry.Remove(h)
					} else {
						select {
						case errs <- e:
						default:
						}
					}
					continue
				}
				for _, key := range selectors {
					frame := &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: int64(0)}, {Name: key, Value: int64(1)}}}
					if e := s.Publisher.PublishDirect(ctx, h, mids.MIDForceReload, frame); e != nil {
						if s.OnDeliveryError != nil {
							s.OnDeliveryError(e)
						}
						break
					}
				}
			}
		}()
	}
send:
	for _, h := range handles {
		select {
		case jobs <- h:
		case <-ctx.Done():
			break send
		}
	}
	close(jobs)
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			return e
		}
	}
	return nil
}
