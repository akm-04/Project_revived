package stockruntime

import (
	"bytes"
	"context"
	"crypto/sha256"
	"errors"
	"log"
	"net/http"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// UndeliveredReplay answers a state-changing resend from the mark the edge kept
// when the first reply could not be delivered (R6 decision 6). It is one
// decorator around every gameplay dispatcher, not a per-MID check. When no mark
// matches, the request runs as today. A state request reaches Next only after it
// takes its claim; a failed take or a transient bearer fault is refused as
// unavailable, because a dispatch could let an older mark survive it.
type UndeliveredReplay struct {
	Next      httpedge.Dispatcher
	Authority apprealtime.GameplayAuthorityPort
	Marks     undelivered.Taker
	Window    time.Duration
	Metrics   observability.Metrics
}

func (d UndeliveredReplay) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Marks == nil || d.Authority == nil || d.Window <= 0 || !mids.StateChanging(req.Envelope.MID) {
		return d.Next.Dispatch(ctx, req)
	}
	token := req.Envelope.Claims.Token
	if token == "" {
		return d.Next.Dispatch(ctx, req)
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, token, req.Envelope.ReceivedAt)
	if err != nil {
		if errors.Is(err, i4store.ErrGameplayBearerNotLive) {
			return d.Next.Dispatch(ctx, req)
		}
		log.Printf("undelivered replay bearer: %v", err)
		return failureReply(unavailable(err))
	}
	fingerprint, fingerprintErr := paramsFingerprint(req.Envelope.Params)
	if fingerprintErr == nil {
		observability.NoteParamsFingerprint(ctx, fingerprint)
	}
	take, err := d.Marks.TakeMark(ctx, int64(actor.PlayerID))
	if err != nil {
		log.Printf("undelivered replay claim: %v", err)
		if d.Metrics != nil {
			d.Metrics.Counter(undelivered.TakeFailuresTotal, observability.Labels{}, 1)
		}
		return failureReply(unavailable(err))
	}
	observability.NoteClaim(ctx, take.Claim)
	if fingerprintErr != nil || !take.HasMark || !d.matches(take.Mark, actor.SessionID.UUID().String(), int64(req.Envelope.MID), fingerprint, req.Envelope.ReceivedAt) {
		return d.Next.Dispatch(ctx, req)
	}
	observability.NoteReplay(ctx)
	if d.Metrics != nil {
		d.Metrics.Counter(undelivered.ReplaysTotal, observability.Labels{}, 1)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Raw: take.Mark.Reply}
}

func (d UndeliveredReplay) matches(mark undelivered.Mark, sessionID string, mid int64, fingerprint [32]byte, now time.Time) bool {
	if mark.SessionID != sessionID || mark.MID != mid || !bytes.Equal(mark.Fingerprint[:], fingerprint[:]) {
		return false
	}
	return now.Sub(mark.MarkedAt) <= d.Window
}

// paramsFingerprint is sha256 of the repository's canonical JSON encoding.
func paramsFingerprint(params map[string]any) ([32]byte, error) {
	canonical, err := cd.CanonicalJSON(params)
	if err != nil {
		return [32]byte{}, err
	}
	return sha256.Sum256(canonical), nil
}
