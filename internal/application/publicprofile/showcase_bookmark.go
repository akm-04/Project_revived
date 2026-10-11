package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type ShowcaseBookmarkReader interface {
	BookmarkTx(context.Context, characterasset.CoherentReadScope, character.HeroRef) (characterhero.BookmarkObservation, error)
}
type BookmarkedShowcase struct {
	Selected     SelectedShowcase
	HeroBookmark *characterhero.BookmarkObservation
}

// Rich activation still belongs I7B-6. This composes genuine selected owned metadata only.
func (s ShowcaseReader) ReadSelectedWithBookmarkTx(c context.Context, sc tx.Scope, a identity.ActorContext, target identity.PlayerID, index int, rev string, at time.Time, b ShowcaseBookmarkReader) (BookmarkedShowcase, error) {
	var out BookmarkedShowcase
	selected, e := s.ReadSelectedTx(c, sc, a, target, index, rev, at)
	if e != nil {
		return out, e
	}
	out.Selected = selected
	if selected.Pet != nil {
		return out, nil
	}
	if selected.Hero == nil || b == nil {
		return out, ErrShowcaseUnavailable
	}
	scope, e := characterasset.NewCoherentReadScope(sc, rev, at)
	if e != nil {
		return out, e
	}
	value, e := b.BookmarkTx(c, scope, selected.Hero.Base.Ref)
	if e != nil {
		return out, e
	}
	if value.Ref != selected.Hero.Base.Ref || value.StateVersion != selected.Hero.Base.StateVersion || value.ContentRevision != rev || !value.ObservedAt.Equal(at) || value.IsLike < 0 || value.IsLike > 1 {
		return out, ErrInvalidState
	}
	out.HeroBookmark = &value
	return out, nil
}
