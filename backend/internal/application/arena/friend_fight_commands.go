package arena

import (
	"context"
	"encoding/json"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialrelation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
)

const FriendFightNoticeRoute = "arena.friend-fight.notice.v1"

type FriendFightCommand struct {
	Player   identity.PlayerID `json:"player_id"`
	Mode     int               `json:"model"`
	GameType int               `json:"game_type"`
}

type FriendFightResult struct {
	Invitation d.FriendInvitation `json:"invitation"`
	Room       *d.TournamentRoom  `json:"room,omitempty"`
}

func (service Service) prepareFriendFight(requestContext context.Context, scope gen.TimedScope, first, second identity.PlayerID, requireEligibility bool) error {
	ordered, err := playerroot.CanonicalPlayerIDs([]identity.PlayerID{first, second})
	if err != nil || first == second {
		return d.ErrInvalid
	}
	for index := 0; index < len(ordered); {
		server, err := socialrelation.CanonicalServer(ordered[index])
		if err != nil {
			return err
		}
		end := index + 1
		for end < len(ordered) {
			next, err := socialrelation.CanonicalServer(ordered[end])
			if err != nil {
				return err
			}
			if next != server {
				break
			}
			end++
		}
		roots, err := service.Players.LockPlayerRootsTx(requestContext, scope.Tx, server, ordered[index:end])
		if err != nil {
			return err
		}
		if len(roots) != end-index {
			return d.ErrRefused
		}
		for position, root := range roots {
			if root.Validate() != nil || root.PlayerID != ordered[index+position] || root.LogicalServerID != server {
				return d.ErrConflict
			}
		}
		index = end
	}
	privacy, err := service.Friendships.PrepareFriendFightPrivacyTx(requestContext, scope.Tx, first, second)
	if err != nil {
		return err
	}
	if requireEligibility && (!privacy.Eligible || scope.Operation.DecisionAt().Before(privacy.ChangedAt)) {
		return d.ErrRefused
	}
	return nil
}

func (service Service) friendFightCommand(requestContext context.Context, actor identity.ActorContext, peer identity.PlayerID, operationContext operation.Context, name string, request any, apply func(context.Context, gen.TimedScope, d.Catalog, int64) (FriendFightResult, error)) (FriendFightResult, error) {
	var result FriendFightResult
	if !service.ready() || service.Players == nil || service.Friendships == nil {
		return result, d.ErrUnavailable
	}
	if !peer.Valid() || actor.PlayerID == peer {
		return result, d.ErrInvalid
	}
	receiptIdentity := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "arena-friend-fight", Operation: name, SemanticKey: operationContext.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return result, err
	}
	_, outcome, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		stored, found, err := service.Receipts.FindTx(requestContext, scope.Tx, receiptIdentity)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: receiptIdentity}
			}
			return json.Unmarshal(stored.ResultPayload, &result)
		}
		if err := service.prepareFriendFight(requestContext, scope, actor.PlayerID, peer, name != "reject"); err != nil {
			return err
		}
		revision, catalog, err := service.catalogTx(requestContext, scope.Tx)
		if err != nil {
			return err
		}
		if catalog.FriendBattleLevel < 1 {
			return d.ErrUnavailable
		}
		for _, player := range []identity.PlayerID{actor.PlayerID, peer} {
			profile, found, err := service.Directory.ProfileTx(requestContext, scope.Tx, player)
			if err != nil {
				return err
			}
			if name != "reject" && (!found || profile.Level < catalog.FriendBattleLevel) {
				return d.ErrRefused
			}
		}
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil {
			return err
		}
		if !found {
			root = d.Competition{ID: d.CompetitionID, ContentRevision: revision, SettledThrough: max(0, catalog.LatestClosed(scope.Operation.DecisionAt())), StateVersion: 1, CreatedAt: scope.Operation.DecisionAt(), UpdatedAt: scope.Operation.DecisionAt()}
			if err := service.Store.CreateCompetitionTx(requestContext, scope.Tx, root); err != nil {
				return err
			}
		}
		previous := root.StateVersion
		root.StateVersion++
		root.UpdatedAt = scope.Operation.DecisionAt()
		if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, previous); err != nil {
			return err
		}
		result, err = apply(requestContext, scope, catalog, root.StateVersion)
		if err != nil {
			return err
		}
		payload, err := json.Marshal(result)
		if err != nil {
			return err
		}
		record, err := receipt.New(scope.Operation.Operation(), receiptIdentity, "I9_7C_ARENA", "gxb.arena.friend-fight-command.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = d.FriendFightContractIdentifier, string(actor.AccountUID), actor.ContextID.UUID()
		_, err = service.Receipts.PutTx(requestContext, scope.Tx, record)
		return err
	})
	if err != nil || !outcome.Reconciled {
		return result, err
	}
	stored, found, err := service.ReceiptRead.Find(requestContext, receiptIdentity)
	if err != nil || !found {
		return result, errors.Join(err, d.ErrConflict)
	}
	err = json.Unmarshal(stored.ResultPayload, &result)
	return result, err
}

func (service Service) expireFriendInvitationsForPair(requestContext context.Context, scope gen.TimedScope, first, second identity.PlayerID) error {
	invitations, err := service.Store.PendingFriendInvitationsForPlayersTx(requestContext, scope.Tx, first, second)
	if err != nil {
		return err
	}
	for _, invitation := range invitations {
		if scope.Operation.DecisionAt().Before(invitation.ExpiresAt) {
			continue
		}
		previous := invitation.StateVersion
		invitation.StateVersion++
		invitation.Status = d.FriendInvitationExpired
		if err := service.Store.SaveFriendInvitationTx(requestContext, scope.Tx, invitation, previous); err != nil {
			return err
		}
	}
	return nil
}

func (service Service) InviteFriendFight(requestContext context.Context, actor identity.ActorContext, command FriendFightCommand, operationContext operation.Context) (d.FriendInvitation, error) {
	if command.Mode < 1 || command.Mode > 2 || command.GameType < 1 || command.GameType > 2 {
		return d.FriendInvitation{}, d.ErrInvalid
	}
	identifier, err := ids.NewUUID()
	if err != nil {
		return d.FriendInvitation{}, err
	}
	result, err := service.friendFightCommand(requestContext, actor, command.Player, operationContext, "invite", command, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog, sequence int64) (FriendFightResult, error) {
		if err := service.expireFriendInvitationsForPair(requestContext, scope, actor.PlayerID, command.Player); err != nil {
			return FriendFightResult{}, err
		}
		existing, found, err := service.Store.LatestFriendInvitationTx(requestContext, scope.Tx, actor.PlayerID, command.Player)
		if err != nil {
			return FriendFightResult{}, err
		}
		if found && existing.Status == d.FriendInvitationPending {
			if existing.Mode != command.Mode || existing.GameType != command.GameType {
				return FriendFightResult{}, d.ErrRefused
			}
			return FriendFightResult{Invitation: existing}, nil
		}
		for _, player := range []identity.PlayerID{actor.PlayerID, command.Player} {
			busy, err := service.Store.FriendFightBusyTx(requestContext, scope.Tx, player, scope.Operation.DecisionAt(), ids.UUID{})
			if err != nil {
				return FriendFightResult{}, err
			}
			if busy {
				return FriendFightResult{}, d.ErrRefused
			}
		}
		invitation := d.FriendInvitation{Identifier: identifier, Inviter: d.AdmissionFrom(actor), Recipient: command.Player, Mode: command.Mode, GameType: command.GameType, Status: d.FriendInvitationPending, CreatedAt: scope.Operation.DecisionAt(), ExpiresAt: scope.Operation.DecisionAt().Add(d.FriendFightInvitationLifetime), Sequence: sequence, StateVersion: 1}
		if err := service.Store.SaveFriendInvitationTx(requestContext, scope.Tx, invitation, 0); err != nil {
			return FriendFightResult{}, err
		}
		return FriendFightResult{Invitation: invitation}, nil
	})
	return result.Invitation, err
}

func (service Service) AcceptFriendFight(requestContext context.Context, actor identity.ActorContext, command FriendFightCommand, operationContext operation.Context) (d.TournamentRoom, error) {
	if command.Mode < 1 || command.Mode > 2 || command.GameType < 1 || command.GameType > 2 {
		return d.TournamentRoom{}, d.ErrInvalid
	}
	identifier, err := ids.NewUUID()
	if err != nil {
		return d.TournamentRoom{}, err
	}
	result, err := service.friendFightCommand(requestContext, actor, command.Player, operationContext, "accept", command, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog, _ int64) (FriendFightResult, error) {
		invitation, found, err := service.Store.LatestFriendInvitationTx(requestContext, scope.Tx, command.Player, actor.PlayerID)
		if err != nil || !found {
			return FriendFightResult{}, errors.Join(err, d.ErrRefused)
		}
		if invitation.Mode != command.Mode || invitation.GameType != command.GameType {
			return FriendFightResult{}, d.ErrRefused
		}
		if invitation.Status == d.FriendInvitationAccepted {
			room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, invitation.Room, false)
			if err != nil || !found {
				return FriendFightResult{}, errors.Join(err, d.ErrConflict)
			}
			return FriendFightResult{Invitation: invitation, Room: &room}, nil
		}
		if invitation.Status != d.FriendInvitationPending || !scope.Operation.DecisionAt().Before(invitation.ExpiresAt) {
			return FriendFightResult{}, d.ErrRefused
		}
		for _, player := range []identity.PlayerID{actor.PlayerID, command.Player} {
			busy, err := service.Store.FriendFightBusyTx(requestContext, scope.Tx, player, scope.Operation.DecisionAt(), invitation.Identifier)
			if err != nil {
				return FriendFightResult{}, err
			}
			if busy {
				return FriendFightResult{}, d.ErrRefused
			}
		}
		revision, err := service.Content.ActiveRevision(requestContext, scope.Tx)
		if err != nil {
			return FriendFightResult{}, err
		}
		startsAt := scope.Operation.DecisionAt().Add(TournamentReadyLead)
		selection, err := d.NewSelectionRoom(command.Player, actor.PlayerID, startsAt)
		if err != nil {
			return FriendFightResult{}, err
		}
		if command.GameType == 1 {
			selection.RequiredTeams = 1
		}
		room := d.TournamentRoom{Identifier: identifier, FriendInvitation: invitation.Identifier, FriendMode: command.Mode, Selection: selection, Status: d.RoomPreparing, Actors: [2]d.AdmissionContext{invitation.Inviter, d.AdmissionFrom(actor)}, ContentRevision: revision, StartsAt: startsAt, Contest: 1, StateVersion: 1, NoticeVersion: 1}
		if err := service.describeSelection(requestContext, scope, &room); err != nil {
			return FriendFightResult{}, err
		}
		if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, 0); err != nil {
			return FriendFightResult{}, err
		}
		previous := invitation.StateVersion
		invitation.StateVersion++
		invitation.Status = d.FriendInvitationAccepted
		invitation.Room = room.Identifier
		if err := service.Store.SaveFriendInvitationTx(requestContext, scope.Tx, invitation, previous); err != nil {
			return FriendFightResult{}, err
		}
		return FriendFightResult{Invitation: invitation, Room: &room}, nil
	})
	if err != nil || result.Room == nil {
		return d.TournamentRoom{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Room, nil
}

func (service Service) RejectFriendFight(requestContext context.Context, actor identity.ActorContext, inviter identity.PlayerID, operationContext operation.Context) error {
	_, err := service.friendFightCommand(requestContext, actor, inviter, operationContext, "reject", map[string]any{"player_id": inviter}, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog, _ int64) (FriendFightResult, error) {
		invitation, found, err := service.Store.LatestFriendInvitationTx(requestContext, scope.Tx, inviter, actor.PlayerID)
		if err != nil || !found {
			return FriendFightResult{}, errors.Join(err, d.ErrRefused)
		}
		if invitation.Status == d.FriendInvitationRejected || invitation.Status == d.FriendInvitationExpired {
			return FriendFightResult{Invitation: invitation}, nil
		}
		if invitation.Status != d.FriendInvitationPending {
			return FriendFightResult{}, d.ErrRefused
		}
		previous := invitation.StateVersion
		invitation.StateVersion++
		invitation.Status = d.FriendInvitationRejected
		if !scope.Operation.DecisionAt().Before(invitation.ExpiresAt) {
			invitation.Status = d.FriendInvitationExpired
		}
		if err := service.Store.SaveFriendInvitationTx(requestContext, scope.Tx, invitation, previous); err != nil {
			return FriendFightResult{}, err
		}
		return FriendFightResult{Invitation: invitation}, nil
	})
	return err
}
