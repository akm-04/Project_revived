package libraryforum

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/libraryforum"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the forum owner. It is the only writer of the forum tables.
type Store interface {
	LockBoardTx(context.Context, tx.Tx, d.Key) error
	CountLiveCommentsTx(context.Context, tx.Queryer, d.Key) (int64, error)
	RetireOldestCommentsTx(context.Context, tx.Tx, d.Key, int64, time.Time) error
	ClearAuthorReactionsTx(context.Context, tx.Tx, d.Key, identity.PlayerID) error
	ListCommentsTx(context.Context, tx.Queryer, d.Key, identity.PlayerID, int64, int64) ([]d.Listed, error)
	LockCommentTx(context.Context, tx.Tx, d.Key, identity.PlayerID) (d.Comment, bool, error)
	UpsertCommentTx(context.Context, tx.Tx, d.Comment) error
	FindReactionTx(context.Context, tx.Queryer, d.Key, identity.PlayerID, identity.PlayerID) (bool, error)
	InsertReactionTx(context.Context, tx.Tx, d.Reaction) error
	DeleteReactionTx(context.Context, tx.Tx, d.Key, identity.PlayerID, identity.PlayerID) error
}

// DirectoryPort is the I4 read owner for a comment author's display identity.
type DirectoryPort interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// CharacterPort is the Character owner's bounded read surface: the author's own
// roster for display, and the actor's instance for 834's instance-to-table
// resolution.
type CharacterPort interface {
	FindHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, bool, error)
	FindPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
	ListPetsTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Pet, error)
}

type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type PlayerRoots interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}
