package occult

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const sweepFactKind = "OCCULT_SWEEP"

func mustJSON(value any) string {
	raw, _ := json.Marshal(value)
	return string(raw)
}

func materialRoutes(catalog d.Catalog, chapterID int64) []i5.MaterialRoute {
	routes := catalog.RoutesOf(chapterID)
	out := make([]i5.MaterialRoute, 0, len(routes))
	for _, route := range routes {
		out = append(out, i5.MaterialRoute{Mission: route.MissionID, Item: route.FragmentItem, Count: 1})
	}
	return out
}

// freezeFragment pins the active stage-1 occurrence of a mission this chapter
// feeds. A mission opened later, finished, or fed by another chapter is not
// pinned and earns nothing from this run.
func (s Mode) freezeFragment(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView) error {
	drop, err := s.Awakening.FreezeAwakeningOccultMaterialTx(c, sc.Tx, a.PlayerID, materialRoutes(view.catalog, view.state.ChapterID))
	if err != nil || drop == nil {
		return err
	}
	raw, err := json.Marshal(drop)
	if err != nil {
		return err
	}
	if view.state.Frozen == nil {
		view.state.Frozen = map[string]json.RawMessage{}
	}
	view.state.Frozen[numberKey(int64(a.PlayerID))] = raw
	return nil
}

// frozenFragment revalidates the pinned occurrence at settlement.
func (s Mode) frozenFragment(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView) (*d.Reward, error) {
	raw, pinned := view.state.Frozen[numberKey(int64(a.PlayerID))]
	if !pinned {
		return nil, nil
	}
	var drop objective.AwakeFrozenDrop
	if err := json.Unmarshal(raw, &drop); err != nil {
		return nil, err
	}
	fragment, routed := view.catalog.FragmentReward(drop.Occurrence.Mission, view.state.ChapterID)
	if !routed || fragment.ItemID != drop.ItemID {
		return nil, nil
	}
	current, err := s.Awakening.CheckAwakeningOccultMaterialTx(c, sc.Tx, a.PlayerID, drop)
	if err != nil || !current {
		return nil, err
	}
	return &fragment, nil
}

func (s Mode) grantRewards(c context.Context, sc gen.TimedScope, a identity.ActorContext, operationName, businessKey string, rewards []d.Reward) error {
	lines := make([]grant.Line, 0, len(rewards))
	for _, reward := range rewards {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: reward.ItemID, Amount: reward.Quantity})
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "occult", Operation: operationName, BusinessKey: businessKey, Occurrence: businessKey, PolicyVersion: d.PolicyID}, Lines: lines}
	_, err := s.Values.SettleGrantTx(c, sc.Tx, a, plan, sc.Operation.Operation(), i5.GrantTxOptions{AllowOverflowMail: true})
	return err
}

func (s Mode) recordFact(c context.Context, sc gen.TimedScope, a identity.ActorContext, kind, businessKey string) error {
	prepared, err := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
	if err != nil {
		return err
	}
	return s.Facts.RecordTx(prepared, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "occult", SourceBusinessKey: businessKey, Kind: kind, Delta: 1})
}

// settleIfCleared pays the chapter once, when its final campaign falls: to every
// eligible member of the room the displayed rewards, the awakening fragment of
// the pinned occurrence, the best score that unlocks the sweep, and the clear
// fact. The acting player's rewards are also put in the reply.
func (s Mode) settleIfCleared(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, body map[string]any) error {
	awards, err := s.settleCleared(c, sc, a, view)
	if err != nil {
		return err
	}
	if rewards, paid := awards[a.PlayerID]; paid {
		body["award_info"] = map[string]any{"awards": rewardRows(rewards)}
	}
	return nil
}

// settleCleared returns what each paid member received; it is empty while the
// chapter is not cleared and after it was paid once.
func (s Mode) settleCleared(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView) (map[identity.PlayerID][]d.Reward, error) {
	state := &view.state
	if state.ClearSettled || !state.ChapterCleared(view.catalog) {
		return nil, nil
	}
	state.ClearSettled = true
	members, err := playerroot.CanonicalPlayerIDs(view.room.Members())
	if err != nil {
		return nil, err
	}
	awards := map[identity.PlayerID][]d.Reward{}
	for _, member := range members {
		rewards, paid, err := s.payClear(c, sc, a, member, view)
		if err != nil {
			return nil, err
		}
		if paid {
			awards[member] = rewards
		}
	}
	return awards, s.Store.FinishRunTx(c, sc.Tx, view.room.ID, view.at)
}

// payClear pays one member; a member who no longer passes the function gate is
// skipped. Another member's writes are hidden from the acting player's reply.
func (s Mode) payClear(c context.Context, sc gen.TimedScope, a identity.ActorContext, member identity.PlayerID, view *roomView) ([]d.Reward, bool, error) {
	memberActor := identity.ActorContext{PlayerID: member, LogicalServerID: a.LogicalServerID}
	scores := view.scores
	if member != a.PlayerID {
		c = changes.Detach(c)
		if err := s.admit(c, sc.Tx, memberActor, view.catalog, view.at); err != nil {
			if errors.Is(err, d.ErrRefused) {
				return nil, false, nil
			}
			return nil, false, err
		}
		var err error
		if scores, err = s.Store.LockPlayerTx(c, sc.Tx, int64(a.LogicalServerID), member, view.at); err != nil {
			return nil, false, err
		}
	}
	state := &view.state
	rewards, err := view.catalog.ClearRewards(state.ChapterID)
	if err != nil {
		return nil, false, err
	}
	fragment, err := s.frozenFragment(c, sc, memberActor, view)
	if err != nil {
		return nil, false, err
	}
	if fragment != nil {
		rewards = append(rewards, *fragment)
	}
	if improved, changed := scores.Record(state.ChapterID, state.Points); changed {
		if err = s.Store.SaveScoresTx(c, sc.Tx, member, improved, view.at); err != nil {
			return nil, false, err
		}
		if member == a.PlayerID {
			view.scores = improved
		}
	}
	businessKey := fmt.Sprintf("%d:clear:%d", member, view.room.ID)
	if err = s.grantRewards(c, sc, memberActor, "clear", businessKey, rewards); err != nil {
		return nil, false, err
	}
	return rewards, true, s.recordFact(c, sc, memberActor, clearedFactKind, businessKey)
}

// fillState completes a fight reply with the room state, tickets and the
// result window's award_detail.
func (s Mode) fillState(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, body map[string]any, point int64) error {
	tickets, err := s.Tickets.OccultTicketsTx(c, sc.Tx, a.PlayerID)
	if err != nil {
		return err
	}
	state, err := s.stateBody(c, sc.Tx, a, view.catalog, view.scores, tickets, view)
	if err != nil {
		return err
	}
	for key, value := range state {
		body[key] = value
	}
	closed := int64(0)
	if view.state.ClearSettled {
		closed = 1
	}
	body["hero_status"] = selfDispatch(view.state, int64(a.PlayerID))
	body["award_detail"] = map[string]any{"extra_point": int64(0), "point": point, "is_close": closed, "close_time": view.at.Unix(), "start_time": view.state.StartedAt, "progress": tickets.Progress}
	piggyback(c, body)
	return nil
}

// Sweep answers 2385: one ticket buys floor(60%) of the chapter's rewards, at
// least one of each, once a best score exists, plus the fragment of the active
// matching mission.
func (s Mode) Sweep(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "sweep", struct{ ChapterID int64 }{chapterID}, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return nil, err
		}
		if err := s.admit(c, sc.Tx, a, catalog, at); err != nil {
			return nil, err
		}
		if _, err := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return nil, err
		}
		scores, err := s.Store.LockPlayerTx(c, sc.Tx, int64(a.LogicalServerID), a.PlayerID, at)
		if err != nil {
			return nil, err
		}
		rewards, err := catalog.SweepRewards(chapterID)
		if err != nil {
			return nil, err
		}
		if !scores.SweepUnlocked(chapterID) {
			return nil, fmt.Errorf("%w: chapter %d has no best score", d.ErrRefused, chapterID)
		}
		tickets, err := s.Tickets.DebitOccultTicketTx(c, sc.Tx, a.PlayerID, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		drop, err := s.Awakening.FreezeAwakeningOccultMaterialTx(c, sc.Tx, a.PlayerID, materialRoutes(catalog, chapterID))
		if err != nil {
			return nil, err
		}
		if drop != nil {
			rewards = append(rewards, d.Reward{ItemID: drop.ItemID, Quantity: drop.Count})
		}
		businessKey := fmt.Sprintf("%d:sweep:%s", a.PlayerID, sc.Operation.Operation().ID)
		if err = s.grantRewards(c, sc, a, "sweep", businessKey, rewards); err != nil {
			return nil, err
		}
		if err = s.recordFact(c, sc, a, sweepFactKind, businessKey); err != nil {
			return nil, err
		}
		body := map[string]any{"awards": rewardRows(rewards)}
		ticketBody(body, tickets)
		return body, nil
	})
}
