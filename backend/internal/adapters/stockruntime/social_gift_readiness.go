package stockruntime

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/socialfriendbase"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const SocialGiftStockGroup = "SOCIAL_GIFT_STOCK_I7A7B"

// PreparedGiftStock binds all finite consumers before activation. It cannot be
// constructed by a partial public sender. The content owner performs activation.
type PreparedGiftStock struct {
	dispatcher SocialDispatcher
	content    socialgift.ContentReader
	prepared   bool
}

func PrepareGiftStock(d SocialDispatcher, g socialgift.Service, b socialfriendbase.Service, r socialreload.Service) (PreparedGiftStock, error) {
	if d.Authority == nil || d.Relations == nil || d.Dismissal == nil || d.Scalar == nil || d.Emitter == nil || g.Timed.Runner.DB == nil || g.Reads.DB == nil || g.Store == nil || g.Content == nil || g.Players == nil || g.Relations == nil || g.Privacy == nil || g.Inbox.Store == nil || g.NoticeEvidence == nil || g.Grants == nil || g.Admission == nil || g.Fence == nil || b.FriendDM.Timed.Runner.DB == nil || b.FriendDM.Queryer == nil || b.FriendDM.Store == nil || b.Projection.Runner.DB == nil || b.Projection.PlayerRoots == nil || b.Projection.Directory == nil || b.Projection.Gifts == nil || b.Projection.NoticePages == nil || b.Projection.Presentation == nil || b.Projection.Observer == nil || b.Projection.Relations == nil || b.Projection.Inbox == nil || r.Runner.DB == nil || r.Gifts == nil || r.Relations == nil || r.Inbox == nil || r.Observer == nil {
		return PreparedGiftStock{}, errors.New("incomplete " + SocialGiftStockGroup)
	}
	d.Gifts = g
	d.Projection = b
	d.giftStockReady = false
	return PreparedGiftStock{dispatcher: d, content: g.Content, prepared: true}, nil
}

// Enable verifies the active compatible immutable catalog via its owner port.
// It never changes an active pointer, consumes a notice or grants currency.
func (p PreparedGiftStock) Enable(c context.Context, q tx.Queryer) (SocialDispatcher, error) {
	if !p.prepared || p.content == nil || q == nil {
		return SocialDispatcher{}, errors.New("unprepared Gift consumer group")
	}
	rev, e := p.content.ActiveRevision(c, q)
	if e != nil {
		return SocialDispatcher{}, e
	}
	v, e := p.content.ReadGiftContent(c, q, rev)
	if e != nil {
		return SocialDispatcher{}, e
	}
	if e = v.Validate(); e != nil {
		return SocialDispatcher{}, e
	}
	d := p.dispatcher
	d.giftStockReady = true
	return d, nil
}
