package socialprojection

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type inviteWindow struct {
	rows      []socialinbox.Notice
	valid     map[socialinbox.NoticeID]bool
	invites   map[socialinbox.NoticeID]gi.Snapshot
	saturated bool
}

// Every Guild read precedes the single response observation. Eligibility at
// that instant never triggers another owner read or moves a Notice's ordering.
func (s Service) prepareInviteWindow(c context.Context, t tx.Tx, p identity.PlayerID) (inviteWindow, error) {
	out := inviteWindow{rows: []socialinbox.Notice{}, valid: map[socialinbox.NoticeID]bool{}, invites: map[socialinbox.NoticeID]gi.Snapshot{}}
	if s.NoticePages == nil || s.Gifts == nil || s.Invites == nil {
		return out, ErrInvalidRead
	}
	after := socialinbox.NoticeCursor{}
	always := 0
	for len(out.rows) < 4096 {
		limit := 128
		if remain := 4096 - len(out.rows); remain < limit {
			limit = remain
		}
		page, e := s.NoticePages.NoticePageTx(c, t, p, after, limit)
		if e != nil {
			return out, e
		}
		if len(page) > limit {
			return out, ErrInvalidRead
		}
		gifts := []socialinbox.Notice{}
		prev := after
		for _, n := range page {
			if n.RecipientPlayerID != p || !n.NoticeID.WireSafe() || n.NoticeTime.IsZero() || !prev.At.IsZero() && (n.NoticeTime.After(prev.At) || n.NoticeTime.Equal(prev.At) && n.NoticeID >= prev.ID) {
				return out, ErrInvalidRead
			}
			prev = socialinbox.NoticeCursor{At: n.NoticeTime, ID: n.NoticeID}
			if n.Source.Kind == socialinbox.GiftSourceKind {
				gifts = append(gifts, n)
			}
		}
		validity, e := s.Gifts.GiftNoticeValidityTx(c, t, p, gifts)
		if e != nil {
			return out, e
		}
		if len(validity) != len(gifts) {
			return out, ErrInvalidRead
		}
		for _, n := range page {
			switch {
			case socialinbox.InviteFamily(n.Source):
				snap, e := s.Invites.ReadCurrentInviteNoticeTx(c, t, n)
				if e != nil {
					return out, e
				}
				out.invites[n.NoticeID] = snap
			case n.Source.Kind == socialinbox.GiftSourceKind:
				out.valid[n.NoticeID] = validity[n.NoticeID]
			case socialinbox.RelationFamily(n.Source):
				if socialinbox.ValidateRelationLifecycle(n) != nil {
					return out, ErrInvalidRead
				}
				out.valid[n.NoticeID] = n.Active
			}
			if out.valid[n.NoticeID] && n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted {
				always++
			}
			out.rows = append(out.rows, n)
		}
		if always >= 50 || len(page) < limit {
			return out, nil
		}
		after = prev
	}
	out.saturated = true
	return out, nil
}
func (w inviteWindow) selectAt(at time.Time) ([]socialinbox.Notice, error) {
	if at.IsZero() {
		return nil, ErrInvalidRead
	}
	out := []socialinbox.Notice{}
	for _, n := range w.rows {
		valid := w.valid[n.NoticeID]
		if snap, ok := w.invites[n.NoticeID]; ok {
			eligible, e := snap.Eligible(at)
			if e != nil {
				return nil, e
			}
			valid = eligible && n.Active
		}
		if valid && n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted && len(out) < 50 {
			out = append(out, n)
		}
	}
	if w.saturated && len(out) < 50 {
		return nil, ErrSearchSaturated
	}
	return out, nil
}
