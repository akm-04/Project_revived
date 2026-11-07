package dormhouse

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const (
	ChangeName      = "DORM_CHANGE_NAME"
	HideHouse       = "DORM_HIDE_HOUSE"
	PraiseHouse     = "DORM_PRAISE_HOUSE"
	CommentHouse    = "DORM_COMMENT_HOUSE"
	PraiseComment   = "DORM_PRAISE_COMMENT"
	DeleteComment   = "DORM_DELETE_COMMENT"
	commentPageSize = 20
)

func socialFamily(family string) bool {
	switch family {
	case ChangeName, HideHouse, PraiseHouse, CommentHouse, PraiseComment, DeleteComment:
		return true
	}
	return false
}

func (c Command) socialTarget(actor identity.PlayerID) identity.PlayerID {
	if c.HostID > 0 {
		return identity.PlayerID(c.HostID)
	}
	return actor
}

// socialRoomWire carries the room-owned facts C2 reads outside the room row.
type socialRoomWire struct {
	Social       map[int64]dorm.SocialRoomState
	PraiseCounts map[int64]int64
	ActorPraises map[int64]dorm.HousePraise
}

func (s Service) socialRoomWireTx(ctx context.Context, t tx.Queryer, owner, viewer identity.PlayerID) (socialRoomWire, error) {
	out := socialRoomWire{}
	if s.Social == nil {
		return out, nil
	}
	states, err := s.Social.ListSocialRoomsTx(ctx, t, owner)
	if err != nil {
		return out, err
	}
	counts, err := s.Social.PraiseCountsTx(ctx, t, owner)
	if err != nil {
		return out, err
	}
	praises, err := s.Social.ActorPraisesTx(ctx, t, owner, viewer)
	if err != nil {
		return out, err
	}
	out.Social = states
	out.PraiseCounts = counts
	out.ActorPraises = praises
	return out, nil
}

func (s Service) socialLockPlan(ctx context.Context, t tx.Tx, actor identity.ActorContext, command Command, at time.Time) error {
	if err := s.Fence.FenceActorTx(ctx, t, actor, at); err != nil {
		if err.Error() == "actor liveness fence rejected" {
			return ErrActor
		}
		return err
	}
	target := command.socialTarget(actor.PlayerID)
	if !target.Valid() || int64(target) > dorm.MaxWireID || logicalserver.PlayerRegion(target) != actor.LogicalServerID {
		return dorm.ErrUnqualified
	}
	ids, err := playerroot.CanonicalPlayerIDs([]identity.PlayerID{actor.PlayerID, target})
	if err != nil {
		return dorm.ErrUnqualified
	}
	roots, err := s.Players.LockPlayerRootsTx(ctx, t, actor.LogicalServerID, ids)
	if err != nil {
		return err
	}
	if len(roots) != len(ids) {
		return dorm.ErrUnqualified
	}
	for _, id := range ids {
		if _, err = s.Owner.LockRootTx(ctx, t, id); err != nil {
			return err
		}
	}
	return nil
}

func (s Service) authorWireTx(ctx context.Context, t tx.Tx, ids []identity.PlayerID) (map[identity.PlayerID]map[string]any, error) {
	out := map[identity.PlayerID]map[string]any{}
	if s.Directory == nil {
		return out, ErrUnavailable
	}
	for _, id := range ids {
		if _, ok := out[id]; ok {
			continue
		}
		profile, found, err := s.Directory.ProfileTx(ctx, t, id)
		if err != nil {
			return nil, err
		}
		if !found || profile.PlayerID != id || profile.Validate() != nil {
			return nil, dorm.ErrUnqualified
		}
		out[id] = map[string]any{
			"player_id":       int64(id),
			"player_name":     profile.Name,
			"avatar_id":       profile.AvatarID,
			"avatar_frame_id": profile.AvatarFrameID,
			"lev":             profile.Level,
			"region":          int64(logicalserver.PlayerRegion(id)),
			"conquer_lev":     profile.ConquerLevel,
			"conquer_loop_id": profile.ConquerLoopID,
		}
	}
	return out, nil
}

func boolFlag(value bool) int64 {
	if value {
		return 1
	}
	return 0
}

func (s Service) applySocial(ctx context.Context, t tx.Tx, actor identity.ActorContext, admission Admission) (map[string]any, error) {
	if s.Social == nil || s.Directory == nil {
		return nil, ErrUnavailable
	}
	c := admission.Command
	at := admission.DecisionAt
	target := c.socialTarget(actor.PlayerID)
	targetRoot, err := s.Owner.ReadRootTx(ctx, t, target)
	if err != nil {
		return nil, err
	}
	if at.Before(targetRoot.UpdatedAt) {
		return nil, ErrStale
	}
	if target != actor.PlayerID {
		actorRoot, err := s.Owner.ReadRootTx(ctx, t, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		if at.Before(actorRoot.UpdatedAt) {
			return nil, ErrStale
		}
	}
	rooms, err := s.Owner.ListRoomsTx(ctx, t, target)
	if err != nil {
		return nil, err
	}
	room, ok := rooms[c.HouseID]
	if !ok {
		return nil, dorm.ErrInvalidFacts
	}
	if at.Before(room.UpdatedAt) {
		return nil, ErrStale
	}
	roomTarget := dorm.RoomTarget{Server: logicalserver.PlayerRegion(target), Owner: target, HouseID: c.HouseID}
	values, err := s.Values.ReadDormPlayerStateTx(ctx, t, target, at)
	if err != nil {
		return nil, err
	}
	if _, ok := values.Functions[71]; !ok {
		return nil, dorm.ErrUnqualified
	}
	state, found, err := s.Social.ReadSocialRoomTx(ctx, t, roomTarget)
	if err != nil {
		return nil, err
	}
	if !found {
		state = dorm.SocialRoomState{Target: roomTarget, StateVersion: 0}
	}
	viewer := actor.PlayerID
	switch c.Family {
	case ChangeName:
		// PRIVATE_POLICY: the display half-unit limit is the only name gate; the
		// original name moderation corpus is UNKNOWN and is not invented here.
		name, err := dorm.NormalizeRoomName(c.HouseName)
		if err != nil {
			return nil, err
		}
		state.Name = name
		return map[string]any{}, s.saveSocialRoom(ctx, t, state, at)
	case HideHouse:
		state.Hidden = !state.Hidden
		if err = s.saveSocialRoom(ctx, t, state, at); err != nil {
			return nil, err
		}
		wire, err := s.socialRoomReplyTx(ctx, t, target, viewer, c.HouseID)
		if err != nil {
			return nil, err
		}
		return map[string]any{"house_info": wire}, nil
	case PraiseHouse:
		count, err := s.Social.PraiseCountTx(ctx, t, roomTarget)
		if err != nil {
			return nil, err
		}
		if count == 0 {
			// A zero COUNT is valid; ActorPraisesTx still owns membership.
		}
		praise, err := s.Social.ReadPraiseTx(ctx, t, roomTarget, viewer)
		if err != nil {
			return nil, err
		}
		facts := dorm.PraiseFacts{Count: count, Actor: praise}
		plan, err := dorm.PlanPraise(facts, roomTarget, viewer, at)
		if err != nil {
			return nil, err
		}
		if plan.Created {
			if err = s.Social.InsertPraiseTx(ctx, t, plan.Praise); err != nil {
				return nil, err
			}
		}
		return map[string]any{"praise_num": plan.Count, "is_has_praise": int64(1)}, nil
	case CommentHouse:
		rows, err := s.Social.ListLiveCommentsTx(ctx, t, roomTarget, viewer)
		if err != nil {
			return nil, err
		}
		id, err := s.Social.NextCommentIDTx(ctx, t)
		if err != nil {
			return nil, err
		}
		plan, err := dorm.PlanComment(rows, roomTarget, viewer, id, c.Content, at)
		if err != nil {
			return nil, err
		}
		for _, pruned := range plan.PrunedCommentIDs {
			if err = s.Social.DeleteCommentReactionsTx(ctx, t, roomTarget, pruned); err != nil {
				return nil, err
			}
			if err = s.Social.DeleteCommentTx(ctx, t, roomTarget, pruned); err != nil {
				return nil, err
			}
		}
		if err = s.Social.InsertCommentTx(ctx, t, plan.Comment); err != nil {
			return nil, err
		}
		return s.commentPageTx(ctx, t, roomTarget, viewer, 0, commentPageSize)
	case PraiseComment:
		comment, err := s.Social.ReadCommentTx(ctx, t, roomTarget, c.CommentID)
		if err != nil {
			return nil, err
		}
		likes := int64(0)
		var reaction *dorm.CommentReaction
		if comment != nil {
			likes, err = s.Social.CommentLikesTx(ctx, t, roomTarget, c.CommentID)
			if err != nil {
				return nil, err
			}
			reaction, err = s.Social.ReadCommentReactionTx(ctx, t, roomTarget, c.CommentID, viewer)
			if err != nil {
				return nil, err
			}
		}
		plan, err := dorm.PlanReaction(dorm.ReactionFacts{Comment: comment, Likes: likes, Actor: reaction}, roomTarget, viewer, c.CommentID, at)
		if err != nil {
			return nil, err
		}
		if plan.Created {
			if err = s.Social.InsertCommentReactionTx(ctx, t, roomTarget, plan.Reaction); err != nil {
				return nil, err
			}
		}
		authors, err := s.authorWireTx(ctx, t, []identity.PlayerID{comment.Author})
		if err != nil {
			return nil, err
		}
		return map[string]any{"comment_info": map[string]any{"comment_id": comment.ID, "is_has_praise": int64(1), "from_player_info": authors[comment.Author], "content": comment.Content}}, nil
	case DeleteComment:
		comment, err := s.Social.ReadCommentTx(ctx, t, roomTarget, c.CommentID)
		if err != nil {
			return nil, err
		}
		plan, err := dorm.PlanDeleteComment(comment, roomTarget, viewer, c.CommentID, at)
		if err != nil {
			return nil, err
		}
		if plan.Changed {
			if err = s.Social.MarkCommentDeletedTx(ctx, t, plan.Comment); err != nil {
				return nil, err
			}
			if err = s.Social.DeleteCommentReactionsTx(ctx, t, roomTarget, plan.Comment.ID); err != nil {
				return nil, err
			}
		}
		return map[string]any{}, nil
	}
	return nil, dorm.ErrUnqualified
}

func (s Service) saveSocialRoom(ctx context.Context, t tx.Tx, state dorm.SocialRoomState, at time.Time) error {
	previous := state.StateVersion
	state.StateVersion = previous + 1
	state.UpdatedAt = at.UTC()
	return s.Social.SaveSocialRoomTx(ctx, t, state, previous)
}

func (s Service) socialRoomReplyTx(ctx context.Context, t tx.Tx, owner, viewer identity.PlayerID, houseID int64) (map[string]any, error) {
	rooms, err := s.Owner.ListRoomsTx(ctx, t, owner)
	if err != nil {
		return nil, err
	}
	room, ok := rooms[houseID]
	if !ok {
		return nil, dorm.ErrInvalidFacts
	}
	heroes, facts, err := s.roomHeroesTx(ctx, t, owner)
	if err != nil {
		return nil, err
	}
	wire, err := s.socialRoomWireTx(ctx, t, owner, viewer)
	if err != nil {
		return nil, err
	}
	return roomWire(room, heroes, facts, wire), nil
}

func (s Service) roomHeroesTx(ctx context.Context, t tx.Queryer, owner identity.PlayerID) (map[int64]character.Hero, map[int64]dorm.HeroFacts, error) {
	heroes, err := s.Heroes.ListHeroesTx(ctx, t, owner)
	if err != nil {
		return nil, nil, err
	}
	hm := map[int64]character.Hero{}
	facts := map[int64]dorm.HeroFacts{}
	for _, hero := range heroes {
		factsValue, err := s.Owner.ReadHeroTx(ctx, t, hero.Ref())
		if err != nil {
			return nil, nil, err
		}
		hm[hero.PartnerID] = hero
		facts[hero.PartnerID] = factsValue
	}
	return hm, facts, nil
}

func (s Service) commentPageTx(ctx context.Context, t tx.Tx, target dorm.RoomTarget, viewer identity.PlayerID, start, offset int64) (map[string]any, error) {
	rows, err := s.Social.ListLiveCommentsTx(ctx, t, target, viewer)
	if err != nil {
		return nil, err
	}
	page, err := dorm.PageComments(rows, target, viewer, start, offset)
	if err != nil {
		return nil, err
	}
	ids := make([]identity.PlayerID, 0, len(page.Best)+len(page.Rows))
	for _, row := range page.Best {
		ids = append(ids, row.Comment.Author)
	}
	for _, row := range page.Rows {
		ids = append(ids, row.Comment.Author)
	}
	authors, err := s.authorWireTx(ctx, t, ids)
	if err != nil {
		return nil, err
	}
	best := make([]any, 0, len(page.Best))
	for _, row := range page.Best {
		best = append(best, commentWire(row, authors))
	}
	list := make([]any, 0, len(page.Rows))
	for _, row := range page.Rows {
		list = append(list, commentWire(row, authors))
	}
	return map[string]any{"best_comments": best, "comment_list": list, "comment_num": page.Total}, nil
}

func commentWire(row dorm.ListedComment, authors map[identity.PlayerID]map[string]any) map[string]any {
	return map[string]any{"comment_id": row.Comment.ID, "from_player_info": authors[row.Comment.Author], "content": row.Comment.Content, "praise_num": row.Likes, "is_has_praise": boolFlag(row.HasReacted)}
}

// SocialRead serves 2519/2522/2524 without advancing Dorm time or mutating.
func (s Service) SocialRead(ctx context.Context, actor identity.ActorContext, op operation.Context, mid uint16, host, house, start, offset int64) (map[string]any, error) {
	if !s.socialComplete() {
		return nil, ErrUnavailable
	}
	if mid != 2519 && mid != 2522 && mid != 2524 {
		return nil, ErrUnavailable
	}
	if start < 0 || offset < 1 || offset > dorm.MaxSocialPageRows {
		return nil, dorm.ErrInvalidFacts
	}
	var body map[string]any
	var runErr error
	_, result, runErr := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope gen.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if fenceErr := s.Fence.FenceActorTx(ctx, scope.Tx, actor, at); fenceErr != nil {
			return fenceErr
		}
		switch mid {
		case 2519:
			body, runErr = s.randomHouseTx(ctx, scope.Tx, actor, at, op.EntropySeed)
			return runErr
		case 2522:
			body, runErr = s.praisePageTx(ctx, scope.Tx, actor, house, start, offset)
			return runErr
		default:
			body, runErr = s.commentListTx(ctx, scope.Tx, actor, host, house, start, offset)
			return runErr
		}
	})
	if runErr != nil {
		return nil, runErr
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}

func (s Service) randomHouseTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, at time.Time, entropy [32]byte) (map[string]any, error) {
	server := actor.LogicalServerID
	bandMin, bandMax := logicalserver.BandMin(server), logicalserver.BandMax(server)
	_, upper, ok, err := s.Directory.PlayerIDBoundsTx(ctx, t)
	if err != nil {
		return nil, err
	}
	if !ok || upper < bandMin {
		return nil, dorm.ErrUnqualified
	}
	if upper > bandMax {
		upper = bandMax
	}
	if bandMin > upper {
		return nil, dorm.ErrUnqualified
	}
	span := int64(upper-bandMin) + 1
	seed := int64(0)
	for _, b := range entropy[:8] {
		seed = seed<<8 | int64(b)
	}
	if seed < 0 {
		seed = -seed
	}
	start := identity.PlayerID(int64(bandMin) + (seed % span))
	candidates, err := s.directoryCandidatesTx(ctx, t, start, upper, bandMin, actor, at)
	if err != nil {
		return nil, err
	}
	for _, profile := range candidates {
		values, err := s.Values.ReadDormPlayerStateTx(ctx, t, profile.PlayerID, at)
		if err != nil {
			return nil, err
		}
		if _, ok := values.Functions[71]; !ok {
			continue
		}
		return s.randomHouseReplyTx(ctx, t, actor.PlayerID, profile.PlayerID, at)
	}
	return nil, dorm.ErrUnqualified
}

func (s Service) directoryCandidatesTx(ctx context.Context, t tx.Tx, start, upper, bandMin identity.PlayerID, actor identity.ActorContext, at time.Time) ([]playerdirectory.Profile, error) {
	out := []playerdirectory.Profile{}
	appendCandidates := func(rows []playerdirectory.Profile) {
		for _, row := range rows {
			if row.PlayerID < bandMin || row.PlayerID > upper || row.PlayerID == actor.PlayerID || logicalserver.PlayerRegion(row.PlayerID) != actor.LogicalServerID {
				continue
			}
			out = append(out, row)
		}
	}
	rows, err := s.Directory.ProfilesAfterTx(ctx, t, start, 256)
	if err != nil {
		return nil, err
	}
	appendCandidates(rows)
	if len(out) == 0 && start > bandMin {
		rows, err = s.Directory.ProfilesAfterTx(ctx, t, bandMin-1, 256)
		if err != nil {
			return nil, err
		}
		appendCandidates(rows)
	}
	ids := make([]int64, 0, len(out))
	for _, row := range out {
		ids = append(ids, int64(row.PlayerID))
	}
	visitable, err := s.Social.VisitablePlayersTx(ctx, t, ids)
	if err != nil {
		return nil, err
	}
	filtered := out[:0]
	for _, row := range out {
		if visitable[int64(row.PlayerID)] {
			filtered = append(filtered, row)
		}
	}
	return filtered, nil
}

func (s Service) randomHouseReplyTx(ctx context.Context, t tx.Tx, viewer, target identity.PlayerID, at time.Time) (map[string]any, error) {
	rooms, err := s.Owner.ListRoomsTx(ctx, t, target)
	if err != nil {
		return nil, err
	}
	heroes, facts, err := s.roomHeroesTx(ctx, t, target)
	if err != nil {
		return nil, err
	}
	wire, err := s.socialRoomWireTx(ctx, t, target, viewer)
	if err != nil {
		return nil, err
	}
	values, err := s.Values.ReadDormPlayerStateTx(ctx, t, target, at)
	if err != nil {
		return nil, err
	}
	functions := []int64{}
	for id := int64(71); id <= 74; id++ {
		if _, ok := values.Functions[id]; ok {
			functions = append(functions, id)
		}
	}
	authors, err := s.authorWireTx(ctx, t, []identity.PlayerID{target})
	if err != nil {
		return nil, err
	}
	return map[string]any{"house_infos": map[string]any{"house_list": listWire(rooms, heroes, facts, wire, false), "open_functions": functions}, "host_info": authors[target]}, nil
}

func (s Service) praisePageTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, house, start, offset int64) (map[string]any, error) {
	target := dorm.RoomTarget{Server: actor.LogicalServerID, Owner: actor.PlayerID, HouseID: house}
	rooms, err := s.Owner.ListRoomsTx(ctx, t, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	if _, ok := rooms[house]; !ok {
		return nil, dorm.ErrInvalidFacts
	}
	total, err := s.Social.PraiseCountTx(ctx, t, target)
	if err != nil {
		return nil, err
	}
	rows, err := s.Social.PagePraisesTx(ctx, t, target, start, offset)
	if err != nil {
		return nil, err
	}
	page, err := dorm.PagePraises(rows, total, target, actor.PlayerID, start, offset)
	if err != nil {
		return nil, err
	}
	ids := make([]identity.PlayerID, 0, len(page.Rows))
	for _, row := range page.Rows {
		ids = append(ids, row.Actor)
	}
	authors, err := s.authorWireTx(ctx, t, ids)
	if err != nil {
		return nil, err
	}
	list := make([]any, 0, len(page.Rows))
	for _, row := range page.Rows {
		list = append(list, map[string]any{"player_info": authors[row.Actor], "praise_time": row.FirstAt.Unix()})
	}
	return map[string]any{"praise_list": list, "total_num": page.Total}, nil
}

func (s Service) commentListTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, host, house, start, offset int64) (map[string]any, error) {
	targetPlayer := actor.PlayerID
	if host > 0 {
		targetPlayer = identity.PlayerID(host)
	}
	if !targetPlayer.Valid() || int64(targetPlayer) > dorm.MaxWireID || logicalserver.PlayerRegion(targetPlayer) != actor.LogicalServerID {
		return nil, dorm.ErrInvalidFacts
	}
	target := dorm.RoomTarget{Server: actor.LogicalServerID, Owner: targetPlayer, HouseID: house}
	rooms, err := s.Owner.ListRoomsTx(ctx, t, targetPlayer)
	if err != nil {
		return nil, err
	}
	if _, ok := rooms[house]; !ok {
		return nil, dorm.ErrInvalidFacts
	}
	if targetPlayer != actor.PlayerID {
		state, found, err := s.Social.ReadSocialRoomTx(ctx, t, target)
		if err != nil {
			return nil, err
		}
		if found && state.Hidden {
			return nil, dorm.ErrHidden
		}
	}
	return s.commentPageTx(ctx, t, target, actor.PlayerID, start, offset)
}
