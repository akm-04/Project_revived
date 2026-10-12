package profilefeedback

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (s Service) author(c context.Context, q tx.Queryer, b i5.PublicPlayerBasis, rev string, at time.Time, server identity.LogicalServerID) (Author, error) {
	out := Author{PlayerID: int64(b.Profile.PlayerID), Name: b.Profile.DisplayName, Avatar: b.Profile.AvatarID, Frame: b.Profile.AvatarFrameID, Level: b.Progression.Level, Region: int32(server)}
	// Nil is the retained legacy component seam. Production binds qualified6A.
	if s.Display == nil {
		return out, nil
	}
	d, e := s.Display.ReadEffectivePlayerDisplayTx(c, q, b.Profile.PlayerID, rev, at)
	if e != nil {
		return Author{}, e
	}
	if d.ProfileVersion != b.Profile.StateVersion || d.ProgressionVersion != b.Progression.StateVersion || d.ContentRevision != rev || !d.ObservedAt.Equal(at) || d.AvatarID < 1 || d.AvatarFrameID < 0 {
		return Author{}, ErrProvider
	}
	out.Avatar = d.AvatarID
	out.Frame = d.AvatarFrameID
	return out, nil
}
