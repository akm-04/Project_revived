package herorecommend

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the HeroRecommend-owned snapshot table.
type Store interface {
	LatestSnapshotTx(context.Context, tx.Queryer, identity.LogicalServerID) (d.Snapshot, bool, error)
	InsertSnapshotTx(context.Context, tx.Tx, d.Snapshot) error
}

// Source is one mode owner's bounded recommendation surface.
type Source interface {
	HeroRecommendSourceTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time, int) (d.Source, error)
}

// Sources binds the six categories to their owning stores. A nil entry is an
// unavailable category, not an empty one.
type Sources struct {
	TopFloor   Source
	OneOnOne   Source
	Arena      Source
	Fantasy    Source
	GuildEvent Source
	Champion   Source
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

type Guilds interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error)
}

// Roster is the stock MID1 projection used for hero and pet rows.
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

// HeroRoster adds the owner-local origin identity the stock MID1 wire omits.
type HeroRoster interface {
	Roster
	HeroOriginTableIDsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error)
}

// HeroPower is the canonical public force producer (Self view only).
type HeroPower interface {
	HeroTx(context.Context, characterasset.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}

// Cohort is the I4-owned bounded logical-server enumeration used by reconciliation.
type Cohort interface {
	ListLogicalServersAfterTx(context.Context, tx.Queryer, identity.LogicalServerID, int) ([]identity.LogicalServerID, error)
}

type Service struct {
	Timed     gen.TimedRunner
	Fresh     tx.Queryer
	Store     Store
	Sources   Sources
	Content   Content
	Directory Directory
	Guilds    Guilds
	Heroes    HeroRoster
	Pets      Roster
	HeroPower HeroPower
	Cohort    Cohort
}

func (s Service) complete() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Store != nil && s.Content != nil &&
		s.Directory != nil && s.Guilds != nil && s.Heroes != nil && s.Pets != nil && s.HeroPower != nil
}

func (s Service) sources() []struct {
	category int64
	source   Source
} {
	return []struct {
		category int64
		source   Source
	}{
		{d.TopFloor, s.Sources.TopFloor},
		{d.OneOnOne, s.Sources.OneOnOne},
		{d.Arena, s.Sources.Arena},
		{d.Fantasy, s.Sources.Fantasy},
		{d.GuildEvent, s.Sources.GuildEvent},
		{d.Champion, s.Sources.Champion},
	}
}
