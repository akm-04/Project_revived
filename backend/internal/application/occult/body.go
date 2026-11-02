package occult

import (
	"context"
	"encoding/json"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func playerInfo(profile playerdirectory.Profile, online bool) map[string]any {
	presence := int64(0)
	if online {
		presence = 1
	}
	return map[string]any{"player_id": int64(profile.PlayerID), "player_name": profile.Name, "avatar_id": profile.AvatarID,
		"avatar_frame_id": profile.AvatarFrameID, "lev": profile.Level, "conquer_lev": profile.ConquerLevel, "conquer_loop_id": profile.ConquerLoopID,
		"is_online": presence}
}

// chapterFraction is the 0..1 chapter completion the client's progress field
// reads; a cleared chapter ends the sub-map.
func chapterFraction(state d.RunState, catalog d.Catalog) int64 {
	if state.ChapterCleared(catalog) {
		return 1
	}
	return 0
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
	body := map[string]any{"base_info": base, "occult_ticket": tickets.Tickets, "progress": int64(0)}
	if view == nil {
		return body, nil
	}
	state := view.state
	progress := chapterFraction(state, catalog)
	body["progress"] = progress
	base["room_id"], base["chapter_id"], base["dispatch_limit"] = view.room.ID, state.ChapterID, state.DispatchLimit
	members := view.room.Members()
	online, err := s.Presence.OnlineAt(c, members, view.at)
	if err != nil {
		return nil, err
	}
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
		info := playerInfo(record, online[member])
		dispatched, dead := state.HeroCounts(int64(member))
		memberIDs = append(memberIDs, int64(member))
		memberInfos = append(memberInfos, info)
		heroStat[numberKey(int64(member))] = map[string]any{"player_info": info,
			"hero_stat": map[string]any{"dispatch": dispatched, "dead": dead, "stay_pos": state.StayPosition(int64(member))}}
	}
	body["room_info"] = map[string]any{"owner": int64(view.room.Owner), "members": memberIDs, "member_infos": memberInfos, "chapter_id": state.ChapterID,
		"room_size": view.room.Capacity, "start_time": state.StartedAt, "campaign_type": state.CampaignType, "is_close": progress}
	body["hero_stat"] = heroStat
	if !state.Started() {
		return body, nil
	}
	body["open_campaigns"] = openCampaigns(catalog, state)
	if state.Team != nil && !state.Team.Settled() {
		info, err := s.subCampaignInfo(c, q, state)
		if err != nil {
			return nil, err
		}
		body["sub_campaign_info"] = info
	}
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
		dispatch[heroKey] = map[string]any{"hp": status.HP, "total_hp": status.LimitHP, "mp": status.MP}
	}
	return dispatch
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

func rowObject(raw json.RawMessage) map[string]any {
	var row map[string]any
	if json.Unmarshal(raw, &row) != nil || row == nil {
		return map[string]any{}
	}
	return row
}

// teamFightInfo is one member's formation as the team window draws it: a row per
// position, the pet row and the readiness flag.
func teamFightInfo(team d.TeamFight, playerID int64) map[string]any {
	pick := team.Pick(playerID)
	formation := make([]any, 0, len(pick.Rows))
	for _, row := range pick.Rows {
		formation = append(formation, rowObject(row))
	}
	prepared := int64(0)
	if team.IsPrepared(playerID) {
		prepared = 1
	}
	info := map[string]any{"formation": formation, "is_prepare": prepared}
	if pick.PetID > 0 {
		info["pet"] = rowObject(pick.PetRow)
	}
	return info
}

// subCampaignInfo is the live team fight: who started it, who accepted, and once
// everyone did, every member's formation.
func (s Mode) subCampaignInfo(c context.Context, q tx.Queryer, state d.RunState) (map[string]any, error) {
	team := state.Team
	if team == nil || team.Settled() {
		return map[string]any{}, nil
	}
	name, err := s.playerName(c, q, team.StartPlayer)
	if err != nil {
		return nil, err
	}
	info := map[string]any{"campaign_id": team.CampaignID, "sub_id": team.SubID, "start_player": team.StartPlayer, "start_player_name": name, "accept_players": team.Accepted}
	if !team.Selecting() {
		return info, nil
	}
	formations := map[string]any{}
	for _, player := range team.Accepted {
		formations[numberKey(player)] = teamFightInfo(*team, player)
	}
	info["team_fight_infos"] = formations
	return info, nil
}

func (s Mode) playerName(c context.Context, q tx.Queryer, playerID int64) (string, error) {
	record, found, err := s.Directory.ProfileTx(c, q, identity.PlayerID(playerID))
	if err != nil || !found {
		return "", err
	}
	return record.Name, nil
}
