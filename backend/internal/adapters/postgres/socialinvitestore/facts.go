package socialinvitestore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	application "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ProgressionReader interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}

type PrivilegeReader interface {
	ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error)
}

type AccountReader interface {
	ReadAccountTx(context.Context, tx.Queryer, identity.PlayerID) (identity.AccountID, error)
}

type ServerNameReader interface {
	ServerNameTx(context.Context, tx.Queryer, identity.LogicalServerID) (string, error)
}

// FactsReader composes existing typed owner ports for invitation facts. The
// type-3 value is the highest currently owned battle girl level (PRIVATE_POLICY,
// D493 item 5); academy level is read separately for the binding gate.
type FactsReader struct {
	Directory   playerdirectory.TxDiscoveryReader
	Accounts    AccountReader
	Progression ProgressionReader
	Heroes      characterasset.HeroLevelReader
	Privilege   PrivilegeReader
	Servers     ServerNameReader
}

var _ application.FactsReader = FactsReader{}

func (reader FactsReader) ReadPlayerProfileTx(ctx context.Context, query tx.Tx, player identity.PlayerID) (application.Profile, error) {
	var out application.Profile
	if reader.Directory == nil || reader.Servers == nil || query == nil || !player.Valid() {
		return out, application.ErrFacts
	}
	profile, found, err := reader.Directory.ProfileTx(ctx, query, player)
	if err != nil {
		return out, err
	}
	if !found || profile.Validate() != nil || profile.PlayerID != player {
		return out, application.ErrFacts
	}
	region, err := reader.Servers.ServerNameTx(ctx, query, logicalserver.PlayerRegion(player))
	if err != nil {
		return out, err
	}
	if region == "" {
		return out, application.ErrFacts
	}
	out = application.Profile{PlayerID: player, Name: profile.Name, AvatarID: profile.AvatarID, RegionName: region}
	if out.Validate(player) != nil {
		return application.Profile{}, application.ErrFacts
	}
	return out, nil
}

func (reader FactsReader) ReadAccountTx(ctx context.Context, query tx.Queryer, player identity.PlayerID) (identity.AccountID, error) {
	if reader.Accounts == nil || query == nil || !player.Valid() {
		return identity.AccountID{}, application.ErrFacts
	}
	return reader.Accounts.ReadAccountTx(ctx, query, player)
}

func (reader FactsReader) ReadAcademyLevelTx(ctx context.Context, query tx.Queryer, player identity.PlayerID) (int64, error) {
	if reader.Progression == nil || query == nil || !player.Valid() {
		return 0, application.ErrFacts
	}
	progression, err := reader.Progression.ReadProgressionTx(ctx, query, player)
	if err != nil {
		return 0, err
	}
	if progression.PlayerID != player || progression.Validate() != nil {
		return 0, application.ErrFacts
	}
	return progression.Level, nil
}

func (reader FactsReader) ReadInviteeFactsTx(ctx context.Context, scope tx.Scope, player identity.PlayerID, revision string, at time.Time) (application.InviteeFacts, error) {
	var out application.InviteeFacts
	if reader.Directory == nil || reader.Progression == nil || reader.Heroes == nil || reader.Privilege == nil || reader.Servers == nil || scope.Tx == nil || !player.Valid() || at.IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return out, application.ErrFacts
	}
	if content, bound := scope.Operation.Policies.Get("content"); !bound || content != revision {
		return out, application.ErrFacts
	}
	coherent, err := characterasset.NewCoherentReadScope(scope, revision, at)
	if err != nil {
		return out, application.ErrFacts
	}
	heroes, err := reader.Heroes.ReadHeroLevelsTx(ctx, coherent, player)
	if err != nil {
		return out, err
	}
	if heroes.PlayerID != player || heroes.Revision != revision || !heroes.ObservedAt.Equal(at.UTC()) || heroes.RootVersion <= 0 || heroes.OwnedCount < 0 || heroes.HighestLevel < 0 {
		return out, application.ErrFacts
	}
	progression, err := reader.Progression.ReadProgressionTx(ctx, scope.Tx, player)
	if err != nil {
		return out, err
	}
	if progression.PlayerID != player || progression.Validate() != nil {
		return out, application.ErrFacts
	}
	privilegeSnapshot, err := reader.Privilege.ReadCosmeticPrivilegeTx(ctx, scope.Tx, player, revision, at)
	if err != nil {
		return out, err
	}
	// K2': the provider observes at the latest stored fact, so validate there.
	if privilegeSnapshot.Validate(player, revision, privilegeSnapshot.ObservedAt) != nil || privilegeSnapshot.State.LogicalServerID != logicalserver.PlayerRegion(player) {
		return out, application.ErrFacts
	}
	profile, err := reader.ReadPlayerProfileTx(ctx, scope.Tx, player)
	if err != nil {
		return out, err
	}
	out = application.InviteeFacts{Player: player, Name: profile.Name, AvatarID: profile.AvatarID, RegionName: profile.RegionName, AcademyLevel: progression.Level, OwnedHeroCount: heroes.OwnedCount, HighestOwnedHeroLevel: heroes.HighestLevel, ChargeTotal: privilegeSnapshot.State.Charge}
	if out.Validate() != nil {
		return application.InviteeFacts{}, application.ErrFacts
	}
	return out, nil
}
