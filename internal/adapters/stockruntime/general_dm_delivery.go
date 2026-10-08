package stockruntime

import (
	"context"
	"encoding/json"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"sync"
	"time"
)

type GeneralDMDelivery struct {
	Service    dm.Service
	Fence      int64
	InstanceID ids.UUID
	Operations operation.Factory
	Registry   *ConnectionRegistry
	Publisher  RealtimePublisher
	Authority  realtimeauth.GameplayLivenessPort
	Time       SocialDeliveryTime
}

// GeneralCompletionUpper bridges one process's monotonic elapsed duration with
// two authoritative database observations. Equality and backward discontinuity
// reject success; the slow post-write observation remains conservative.
func GeneralCompletionUpper(start, end time.Time, elapsed time.Duration) (time.Time, error) {
	if start.IsZero() || end.IsZero() || elapsed < 0 {
		return time.Time{}, dm.ErrTimeInvalid
	}
	if end.Before(start.Add(elapsed - 250*time.Millisecond)) {
		return time.Time{}, dm.ErrTimeInvalid
	}
	upper := start.Add(elapsed + 250*time.Millisecond)
	if end.After(upper) {
		upper = end
	}
	return upper, nil
}
func generalPayload(i dm.Intent) (*amf3.Object, error) {
	np, e := json.Marshal(map[string]any{"title_info": "@@@@", "bubble_info": "10001@0", "conquer_lev": i.SenderConquerLevel, "conquer_loop_id": i.SenderConquerLoopID})
	if e != nil {
		return nil, e
	}
	return &amf3.Object{Properties: []amf3.Property{
		{Name: "message", Value: i.Message}, {Name: "from_player_id", Value: i.Sender}, {Name: "from_player_name", Value: i.SenderName},
		{Name: "from_player_type", Value: i.SenderType}, {Name: "player_type", Value: i.SenderType},
		{Name: "from_player_avatar_id", Value: i.SenderAvatarID}, {Name: "from_player_avatar_frame_id", Value: i.SenderAvatarFrameID},
		{Name: "from_player_lev", Value: i.SenderLevel}, {Name: "type", Value: int64(0)}, {Name: "np_info", Value: string(np)},
	}}, nil
}
func (d GeneralDMDelivery) matches(meta SessionMetadata, b dm.Binding) bool {
	return meta.ContextID.UUID().String() == b.ContextID && meta.SessionID.UUID().String() == b.SessionID && meta.ContextGeneration == b.ContextGeneration && meta.ContextLivenessVersion == b.ContextLiveness && meta.SessionLivenessVersion == b.SessionLiveness && int64(meta.RegistryGeneration) == b.ConnectionGeneration && int64(meta.LogicalServerID) == b.LogicalServerID && b.OwnerFence == d.Fence && b.RealtimeInstanceID == d.InstanceID.String()
}
func (d GeneralDMDelivery) DeliverIntent(c context.Context, id string) error {
	if d.Registry == nil || d.Time == nil || d.Authority == nil || d.Fence < 1 || d.InstanceID.IsZero() {
		return dm.ErrUnavailable
	}
	op, e := d.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	done, e := d.Service.Recover(c, id, op)
	if e != nil || done {
		return e
	}
	op, e = d.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	claim, ok, e := d.Service.Claim(c, id, d.Fence, op)
	if e != nil || !ok {
		return e
	}
	// Snapshot only captured original handles. Never add a reconnect or a newly
	// admitted context to the durable target set.
	handles := []SessionHandle{}
	for _, h := range d.Registry.ByPlayerRole(identity.PlayerID(claim.Recipient), domainrt.World) {
		meta, ok := h.Metadata()
		if !ok || !d.Registry.IsCurrent(h) {
			continue
		}
		for _, b := range claim.Bindings {
			if d.matches(meta, b) {
				handles = append(handles, h)
				break
			}
		}
	}
	op, e = d.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	attempt, e := d.Service.BeginAttempt(c, claim, op)
	if e != nil {
		return e
	}
	if attempt.Status != dm.Attempting {
		return nil
	}
	payload, e := generalPayload(attempt)
	if e != nil {
		return e
	}
	bounded, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	jobs := make(chan SessionHandle)
	var wg sync.WaitGroup
	var mu sync.Mutex
	var upper time.Time
	wrote := false
	timeInvalid := false
	markTimeInvalid := func() { mu.Lock(); timeInvalid = true; mu.Unlock() }
	workers := 8
	if len(handles) < workers {
		workers = len(handles)
	}
	for n := 0; n < workers; n++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for h := range jobs {
				m, ok := h.Metadata()
				if !ok || !d.Registry.IsCurrent(h) || m.PhysicalRole != domainrt.World || m.PlayerID != identity.PlayerID(attempt.Recipient) {
					continue
				}
				actor := identity.ActorContext{AccountID: m.AccountID, AccountUID: m.AccountUID, SessionID: m.SessionID, ContextID: m.ContextID, LogicalServerID: m.LogicalServerID, PlayerID: m.PlayerID, ContextGeneration: m.ContextGeneration, SessionLivenessVersion: m.SessionLivenessVersion, ContextLivenessVersion: m.ContextLivenessVersion}
				mono := time.Now()
				n0, e := d.Time.Now(bounded)
				if e != nil {
					continue
				}
				if n0.Before(attempt.LastObservedAt) {
					markTimeInvalid()
					continue
				}
				if !n0.Before(attempt.ExpiresAt) {
					continue
				}
				if e = d.Authority.ValidateActor(bounded, actor, n0); e != nil || !d.Registry.IsCurrent(h) {
					continue
				}
				budget := attempt.ExpiresAt.Sub(n0) - 250*time.Millisecond
				if budget <= 0 {
					continue
				}
				if budget > 2*time.Second {
					budget = 2 * time.Second
				}
				sendCtx, sendCancel := context.WithTimeout(bounded, budget)
				e = d.Publisher.PublishDirect(sendCtx, h, mids.MIDChatFromPlayer, payload)
				elapsed := time.Since(mono)
				valid := e == nil && sendCtx.Err() == nil
				sendCancel()
				if !valid {
					continue
				}
				n1, e := d.Time.Now(bounded)
				if e != nil {
					continue
				}
				u, e := GeneralCompletionUpper(n0, n1, elapsed)
				if e != nil {
					markTimeInvalid()
					continue
				}
				if !u.Before(attempt.ExpiresAt) {
					markTimeInvalid()
					continue
				}
				if bounded.Err() != nil {
					continue
				}
				mu.Lock()
				if !wrote || u.Before(upper) {
					upper = u
				}
				wrote = true
				mu.Unlock()
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
	// Finish uses a fresh operation and complete caller transaction privacy/fence
	// plan. Late/unknown writes never create a positive HTTP result.
	op, e = d.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	if !wrote && timeInvalid {
		_, e = d.Service.InvalidateTime(c, attempt, op)
	} else {
		_, e = d.Service.Finish(c, attempt, wrote, upper, op)
	}
	return e
}
