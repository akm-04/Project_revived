package stockruntime

import (
	"context"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"sync"
	"time"
)

func NewFriendSocialEventRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry([]rt.DirectRegistration{{MID: mids.MIDForceReload, Roles: []rt.Role{rt.World}, Validate: ValidateSocialReload}, {MID: mids.MIDChatFromFriend, Roles: []rt.Role{rt.World}, Validate: rt.ValidateFriendDM}}, nil)
}

type FriendDMDelivery struct {
	Service         dm.Service
	Fence           int64
	Operations      operation.Factory
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	IsStaleActor    func(error) bool
	OnDeliveryError func(error)
}

func (d FriendDMDelivery) DeliverRecipient(c context.Context, id identity.PlayerID) error {
	if d.Registry == nil || d.Authority == nil || d.Time == nil || d.MaxHandles < 1 {
		return dm.ErrUnavailable
	}
	for n := 0; n < 50; n++ {
		handles := d.Registry.ByPlayerRole(id, domainrt.World)
		if len(handles) == 0 {
			return nil
		}
		if len(handles) > d.MaxHandles {
			return dm.ErrUnavailable
		}
		op, e := d.Operations.New(policy.Set{})
		if e != nil {
			return e
		}
		claim, ok, e := d.Service.Claim(c, id, d.Fence, op)
		if e != nil {
			return e
		}
		if !ok {
			return nil
		}
		// One ordered occurrence per recipient. Writer attempts are capped at8 and
		// joined before finalization; one actual writer success is sufficient.
		bounded, cancel := context.WithTimeout(c, 2*time.Second)
		jobs := make(chan SessionHandle)
		var wg sync.WaitGroup
		var mu sync.Mutex
		wrote := false
		workers := 8
		if len(handles) < workers {
			workers = len(handles)
		}
		for i := 0; i < workers; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for h := range jobs {
					meta, ok := h.Metadata()
					if !ok || !d.Registry.IsCurrent(h) || meta.PlayerID != id || meta.PhysicalRole != domainrt.World || meta.RoomID != int64(meta.LogicalServerID) {
						continue
					}
					at, e := d.Time.Now(bounded)
					if e != nil {
						continue
					}
					actor := identity.ActorContext{AccountID: meta.AccountID, AccountUID: meta.AccountUID, SessionID: meta.SessionID, ContextID: meta.ContextID, LogicalServerID: meta.LogicalServerID, PlayerID: meta.PlayerID, ContextGeneration: meta.ContextGeneration, SessionLivenessVersion: meta.SessionLivenessVersion, ContextLivenessVersion: meta.ContextLivenessVersion}
					if e = d.Authority.ValidateActor(bounded, actor, at); e != nil {
						if d.IsStaleActor != nil && d.IsStaleActor(e) {
							d.Registry.Remove(h)
						}
						continue
					}
					check, e := d.Operations.New(policy.Set{})
					if e != nil {
						continue
					}
					allowed, e := d.Service.CheckClaim(bounded, claim, check)
					if e != nil || !allowed || !d.Registry.IsCurrent(h) {
						continue
					}
					o := claim.Delivery.Occurrence
					payload := &amf3.Object{Properties: []amf3.Property{{Name: "friend_id", Value: int64(o.Sender)}, {Name: "message", Value: o.Message}, {Name: "time", Value: o.AcceptedAt.UTC().Unix()}}}
					if e = d.Publisher.PublishDirect(bounded, h, mids.MIDChatFromFriend, payload); e == nil {
						mu.Lock()
						wrote = true
						mu.Unlock()
					} else if d.OnDeliveryError != nil {
						d.OnDeliveryError(e)
					}
				}
			}()
		}
	send:
		for _, h := range handles {
			select {
			case jobs <- h:
			case <-bounded.Done():
				break send
			}
		}
		close(jobs)
		wg.Wait()
		cancel()
		final, e := d.Operations.New(policy.Set{})
		if e != nil {
			return e
		}
		_, e = d.Service.Complete(c, claim, wrote, final)
		if e != nil {
			return e
		}
		if !wrote {
			return nil
		}
	}
	return nil
}
