package playerpresentation

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// CanonicalReader uses qualified owner fallback on every critical presentation.
// Directory retains its own registered identity/conquer facts; mutable Player
// fields and timed cosmetics are observed from Player in the caller snapshot.
type CanonicalReader struct {
	Directory playerdirectory.Reader
	Basis     i5.PublicPlayerBasisReader
	Display   i5.TxEffectivePlayerDisplayReader
}

func (r CanonicalReader) ReadAtTx(c context.Context, q tx.Queryer, pid identity.PlayerID, rev string, at time.Time) (Minimal, bool, error) {
	if q == nil || r.Directory == nil || r.Basis == nil || r.Display == nil || !pid.Valid() || len(rev) != 64 || at.IsZero() {
		return Minimal{}, false, ErrMissingPresentation
	}
	p, ok, e := r.Directory.Profile(c, pid)
	if e != nil || !ok {
		return Minimal{}, ok, e
	}
	if p.PlayerID != pid {
		return Minimal{}, false, ErrMissingPresentation
	}
	b, e := r.Basis.ReadPublicPlayerBasisTx(c, q, pid)
	if e != nil {
		return Minimal{}, false, e
	}
	if b.Validate() != nil || b.Profile.PlayerID != pid {
		return Minimal{}, false, ErrMissingPresentation
	}
	d, e := r.Display.ReadEffectivePlayerDisplayTx(c, q, pid, rev, at)
	if e != nil {
		return Minimal{}, false, e
	}
	if d.ProfileVersion != b.Profile.StateVersion || d.ProgressionVersion != b.Progression.StateVersion || d.ContentRevision != rev || !d.ObservedAt.Equal(at) {
		return Minimal{}, false, ErrMissingPresentation
	}
	v := player.ChatCosmetics{}
	if len(d.TitleInfo) > 0 {
		var yes bool
		if v.TitleID, yes = d.TitleInfo["title_id"].(int64); !yes {
			return Minimal{}, false, ErrMissingPresentation
		}
		if v.UniqueID, yes = d.TitleInfo["unique_id"].(int64); !yes {
			return Minimal{}, false, ErrMissingPresentation
		}
		if v.TitleEnd, yes = d.TitleInfo["end_time"].(int64); !yes {
			return Minimal{}, false, ErrMissingPresentation
		}
	}
	var yes bool
	if v.BubbleID, yes = d.BubbleInfo["bubble_id"].(int64); !yes {
		return Minimal{}, false, ErrMissingPresentation
	}
	if v.BubbleEnd, yes = d.BubbleInfo["end_time"].(int64); !yes {
		return Minimal{}, false, ErrMissingPresentation
	}
	title, bubble, e := v.Strings()
	if e != nil {
		return Minimal{}, false, e
	}
	out := Minimal{PlayerID: pid, Name: b.Profile.DisplayName, Level: b.Progression.Level, AvatarID: d.AvatarID, AvatarFrameID: d.AvatarFrameID, PlayerType: b.Profile.PlayerType, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID, TitleInfo: title, BubbleInfo: bubble}
	return out, true, out.Validate()
}
