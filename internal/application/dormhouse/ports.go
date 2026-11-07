package dormhouse

import (
	"context"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type OwnerReader interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (dorm.Root, error)
	ReadRoomTx(context.Context, tx.Queryer, identity.PlayerID, int64) (dorm.Room, error)
	ListRoomsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]dorm.Room, error)
	ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (dorm.HeroFacts, error)
}
type ContentReader interface {
	DormCatalogTx(context.Context, tx.Queryer, string) (dorm.Catalog, error)
}

type SocialStore interface {
	ReadSocialRoomTx(context.Context, tx.Queryer, dorm.RoomTarget) (dorm.SocialRoomState, bool, error)
	ListSocialRoomsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]dorm.SocialRoomState, error)
	SaveSocialRoomTx(context.Context, tx.Tx, dorm.SocialRoomState, int64) error
	PraiseCountsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error)
	ActorPraisesTx(context.Context, tx.Queryer, identity.PlayerID, identity.PlayerID) (map[int64]dorm.HousePraise, error)
	PraiseCountTx(context.Context, tx.Queryer, dorm.RoomTarget) (int64, error)
	ReadPraiseTx(context.Context, tx.Queryer, dorm.RoomTarget, identity.PlayerID) (*dorm.HousePraise, error)
	PagePraisesTx(context.Context, tx.Queryer, dorm.RoomTarget, int64, int64) ([]dorm.HousePraise, error)
	InsertPraiseTx(context.Context, tx.Tx, dorm.HousePraise) error
	ListLiveCommentsTx(context.Context, tx.Queryer, dorm.RoomTarget, identity.PlayerID) ([]dorm.ListedComment, error)
	ReadCommentTx(context.Context, tx.Queryer, dorm.RoomTarget, int64) (*dorm.HouseComment, error)
	CommentLikesTx(context.Context, tx.Queryer, dorm.RoomTarget, int64) (int64, error)
	ReadCommentReactionTx(context.Context, tx.Queryer, dorm.RoomTarget, int64, identity.PlayerID) (*dorm.CommentReaction, error)
	NextCommentIDTx(context.Context, tx.Tx) (int64, error)
	InsertCommentTx(context.Context, tx.Tx, dorm.HouseComment) error
	MarkCommentDeletedTx(context.Context, tx.Tx, dorm.HouseComment) error
	DeleteCommentReactionsTx(context.Context, tx.Tx, dorm.RoomTarget, int64) error
	DeleteCommentTx(context.Context, tx.Tx, dorm.RoomTarget, int64) error
	InsertCommentReactionTx(context.Context, tx.Tx, dorm.RoomTarget, dorm.CommentReaction) error
	VisitablePlayersTx(context.Context, tx.Queryer, []int64) (map[int64]bool, error)
}
type CharacterEXPOwner interface {
	ApplyDormEXPLockedTx(context.Context, tx.Tx, character.HeroRef, int64, int64, string, time.Time) (character.Hero, bool, error)
}

// FurnitureUsage is I5's untimed canonical reference query. CreationRevision is
// an immutable room-owned reference, never a discovered active/current revision.
// The same caller snapshot resolves its source-built-in dresser exemption.
// Layout writers must hold I5economy700 and revalidate stock inside their
// serializable transaction; no lower Dorm lock is acquired by this port.
type FurnitureUsage struct {
	Owner   OwnerReader
	Content ContentReader
}

func (s FurnitureUsage) MinimumRetainedStackTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, item int64) (int64, error) {
	if s.Owner == nil || s.Content == nil || q == nil || !pid.Valid() || item <= 0 {
		return 0, dorm.ErrUnqualified
	}
	if _, e := s.Owner.ReadRootTx(ctx, q, pid); e != nil {
		return 0, e
	}
	rooms, e := s.Owner.ListRoomsTx(ctx, q, pid)
	if e != nil {
		return 0, e
	}
	catalogs := map[string]dorm.Catalog{}
	var used int64
	for _, r := range rooms {
		if r.Validate() != nil {
			return 0, dorm.ErrUnqualified
		}
		c, ok := catalogs[r.CreationRevision]
		if !ok {
			c, e = s.Content.DormCatalogTx(ctx, q, r.CreationRevision)
			if e != nil {
				return 0, e
			}
			catalogs[r.CreationRevision] = c
		}
		rule, ok := c.Rooms[r.TableID]
		if !ok || rule.MainType != r.MainType {
			return 0, dorm.ErrUnqualified
		}
		var count, dresser int64
		for key := range r.Layout {
			p, e := dorm.ParsePlacementKey(key)
			if e != nil {
				return 0, e
			}
			if p.ItemID == item {
				count++
			}
			if p.ItemID == rule.Dresser {
				dresser++
			}
		}
		if rule.Dresser > 0 && dresser != 1 {
			return 0, dorm.ErrUnqualified
		}
		if item == rule.Dresser {
			count--
		}
		if count < 0 || used > (1<<63-1)-count {
			return 0, dorm.ErrUnqualified
		}
		used += count
	}
	return used, nil
}
