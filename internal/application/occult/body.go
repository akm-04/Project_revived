package occult

import (
	"context"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func playerInfo(profile playerdirectory.Profile) map[string]any {
	return map[string]any{"player_id": int64(profile.PlayerID), "player_name": profile.Name, "avatar_id": profile.AvatarID,
		"avatar_frame_id": profile.AvatarFrameID, "lev": profile.Level, "conquer_lev": profile.ConquerLevel, "conquer_loop_id": profile.ConquerLoopID}
}

func maxPoints(catalog d.Catalog, scores d.Scores) []int64 {
	points := make([]int64, 0, len(catalog.Chapters))
	for _, chapter := range catalog.Chapters {
		points = append(points, scores.Best(chapter.ID))
	}
	return points
}

// stateBody is the reply the client's common dispatcher reads: base_info and
// tickets always, the room, map and hero state while a started room is held.
func (s Mode) stateBody(c context.Context, q tx.Queryer, a identity.ActorContext, catalog d.Catalog, scores d.Scores, tickets i5.OccultTickets, view *roomView) (map[string]any, error) {
	base := map[string]any{"room_id": int64(0), "chapter_id": int64(0), "cost_energy": tickets.Progress,
		"max_points": maxPoints(catalog, scores), "dispatch_limit": catalog.DispatchHeroLimit}
	body := map[string]any{"base_info": base, "occult_ticket": tickets.Tickets, "progress": tickets.Progress}
	if view == nil {
		return body, nil
	}
	state := view.state
	base["room_id"], base["chapter_id"], base["dispatch_limit"] = view.room.ID, state.ChapterID, state.DispatchLimit
	members := view.room.Members()
	memberIDs := make([]int64, 0, len(members))
	memberInfos := make([]map[string]any, 0, len(members))
	heroStat := map[string]any{}
	for _, member := range members {
		record, found, err := s.Directory.ProfileTx(c, q, member)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, d.ErrUnavailable
		}
		info := playerInfo(record)
		dispatched, dead := state.HeroCounts(int64(member))
		memberIDs = append(memberIDs, int64(member))
		memberInfos = append(memberInfos, info)
		heroStat[numberKey(int64(member))] = map[string]any{"player_info": info,
			"hero_stat": map[string]any{"dispatch": dispatched, "dead": dead, "stay_pos": state.StayPosition(int64(member))}}
	}
	body["room_info"] = map[string]any{"owner": int64(view.room.Owner), "members": memberIDs, "member_infos": memberInfos, "chapter_id": state.ChapterID,
		"room_size": view.room.Capacity, "start_time": state.StartedAt, "campaign_type": state.CampaignType, "is_close": int64(0)}
	body["hero_stat"] = heroStat
	body["open_campaigns"] = openCampaigns(catalog, state)
	body["self_dispatch"] = selfDispatch(state, int64(a.PlayerID))
	return body, nil
}

func openCampaigns(catalog d.Catalog, state d.RunState) map[string]any {
	open := map[string]any{}
	for _, campaign := range catalog.RoomCampaigns(state.ChapterID, state.CampaignType) {
		if !state.Reachable(catalog, campaign) {
			continue
		}
		stages := state.StagesOf(campaign.ID)
		won, inBattle := make([]int64, len(stages)), make([]int64, len(stages))
		for index, stage := range stages {
			if stage.HP <= 0 {
				won[index] = 1
			}
			inBattle[index] = stage.InBattle
		}
		open[numberKey(campaign.ID)] = map[string]any{"is_win": won, "in_battle": inBattle}
	}
	return open
}

func selfDispatch(state d.RunState, playerID int64) map[string]any {
	dispatch := map[string]any{}
	for heroKey, status := range state.HeroStatus[numberKey(playerID)] {
		dispatch[heroKey] = map[string]any{"hp": status.HP, "mp": status.MP}
	}
	return dispatch
}

// ticketBody carries the ticket and energy-progress numbers every terminal
// reply refreshes.
func ticketBody(body map[string]any, tickets i5.OccultTickets) {
	body["occult_ticket"] = tickets.Tickets
	body["progress"] = tickets.Progress
}

func rewardRows(rewards []d.Reward) []map[string]any {
	rows := make([]map[string]any, 0, len(rewards))
	for _, reward := range rewards {
		rows = append(rows, map[string]any{"table_id": reward.ItemID, "item_num": reward.Quantity})
	}
	return rows
}

// logEntry is one 2380 row; log_id 1 is a battle and 2 an affair.
func logEntry(at time.Time, logType int, campaignID int64, players ...identity.PlayerID) map[string]any {
	ids := make([]int64, 0, len(players))
	for _, player := range players {
		ids = append(ids, int64(player))
	}
	sort.Slice(ids, func(left, right int) bool { return ids[left] < ids[right] })
	return map[string]any{"time": at.Unix(), "log_id": int64(logType), "campaign_id": campaignID, "player_ids": ids}
}

func subIndex(subID int64) int { return int(subID) - 1 }
