package guildwire

import (
	"gxb.local/backend/v2/internal/application/guildtea"
	app "gxb.local/backend/v2/internal/application/guildview"
)

func Info(g app.GuildInfo) map[string]any {
	return map[string]any{"guild_id": g.GuildID, "icon": g.Icon, "icon_frame": g.IconFrame, "name": g.Name, "des": g.Description, "apply_type": int64(g.ApplyType), "min_allow_level": g.MinAllowLevel, "huoyue": g.Vitality, "member_num": g.MemberNum, "guild_leader": g.GuildLeader, "guild_leader_name": g.GuildLeaderName}
}
func Member(m app.Member) map[string]any {
	return map[string]any{"player_id": m.PlayerID, "name": m.Name, "lev": m.Level, "avatar_id": m.AvatarID, "avatar_frame_id": m.AvatarFrameID, "conquer_lev": m.ConquerLevel, "conquer_loop_id": m.ConquerLoopID, "job": int64(m.Role), "join_time": m.JoinTime, "last_time": m.LastTime, "seven_huoyue": m.SevenVitality, "copy_challenge_times": m.CopyChallengeTime}
}
func Applicant(a app.Applicant) map[string]any {
	return map[string]any{"player_id": a.PlayerID, "name": a.Name, "lev": a.Level, "avatar_id": a.AvatarID, "avatar_frame_id": a.AvatarFrameID, "conquer_lev": a.ConquerLevel, "conquer_loop_id": a.ConquerLoopID}
}
func InfoList(gs []app.GuildInfo) []any {
	out := make([]any, 0, len(gs))
	for _, g := range gs {
		out = append(out, Info(g))
	}
	return out
}
func MemberList(ms []app.Member) []any {
	out := make([]any, 0, len(ms))
	for _, m := range ms {
		out = append(out, Member(m))
	}
	return out
}
func ApplicantList(as []app.Applicant) []any {
	out := make([]any, 0, len(as))
	for _, a := range as {
		out = append(out, Applicant(a))
	}
	return out
}
func Self(s app.SelfGuild) map[string]any {
	return map[string]any{"guild_info": Info(s.GuildInfo), "self_info": map[string]any{"job": int64(s.SelfRole), "join_time": s.JoinTime, "today_huoyue": s.TodayHuoyue, "huoyue_num": s.HuoyueNum}, "member_nums": s.MemberNum}
}
func EmptySelf() map[string]any {
	return map[string]any{"guild_info": map[string]any{"guild_id": int64(0)}, "self_info": map[string]any{"job": int64(0), "join_time": int64(0), "today_huoyue": int64(0), "huoyue_num": int64(0)}, "member_nums": int64(0)}
}

func Roster(info app.GuildInfo, members []app.Member) map[string]any {
	out := Info(info)
	out["members"] = MemberList(members)
	return out
}

func Other(s app.SelfGuild) map[string]any {
	return map[string]any{
		"guild_info":  Info(s.GuildInfo),
		"self_info":   map[string]any{"job": int64(0), "join_time": int64(0), "today_huoyue": int64(0), "huoyue_num": int64(0)},
		"member_nums": s.MemberNum,
	}
}

func Detail2565(g app.GuildInfo) map[string]any {
	info := Info(g)
	// I6C does not own Guild rank position. Stock GuildDetailWindow requires a
	// numeric field, so zero stays an explicit presentation sentinel until a
	// later provider qualifies it.
	info["three_huoyue"] = g.ThreeHuoyue
	info["guild_rank"] = int64(0)
	return map[string]any{"guild_info": info}
}

// Tea is 1808/1809/1810/1811 and the MID1 1808 embed (I9_GUILD_ACTIVITY_V1 C13).
// The stock callbacks index self_wish_info, guild_wish_flag, gift_list and
// wish_list directly, so a refusal must never arrive as HTTP 200.
func Tea(state guildtea.State) map[string]any {
	body := map[string]any{"self_wish_info": map[string]any{"item_id": state.SelfWish.ItemID, "current_num": state.SelfWish.CurrentNum, "need_num": state.SelfWish.NeedNum}}
	if state.SelfOnly {
		return body
	}
	body["guild_wish_flag"] = state.WishFlag
	gifts := make([]any, 0, len(state.Gifts))
	for _, gift := range state.Gifts {
		gifts = append(gifts, teaPlayer(gift.Player, false))
	}
	body["gift_list"] = gifts
	wishes := make([]any, 0, len(state.Wishes))
	for _, wish := range state.Wishes {
		wishes = append(wishes, map[string]any{
			"wish_info":        map[string]any{"item_id": wish.Wish.ItemID, "current_num": wish.Wish.CurrentNum, "need_num": wish.Wish.NeedNum},
			"player_info":      teaPlayer(wish.Player, true),
			"can_present_gift": wish.CanPresent,
		})
	}
	body["wish_list"] = wishes
	if state.Award != nil {
		body["award"] = map[string]any{"item": state.Award.ItemID, "num": state.Award.Num}
	}
	return body
}

func teaPlayer(player guildtea.PlayerInfo, withJob bool) map[string]any {
	out := map[string]any{"player_id": player.PlayerID, "player_name": player.Name, "lev": player.Level, "avatar_id": player.AvatarID, "avatar_frame_id": player.AvatarFrameID, "conquer_lev": player.ConquerLevel, "conquer_loop_id": player.ConquerLoopID}
	if withJob {
		out["guild_job"] = player.GuildJob
	}
	return out
}

// GuildRankList is the LOAD_RANK_LIST type 4 body for sub_type 11 and 39; the
// client reads three_huoyue, name, icon, rank and the detail fields
// (NewRankWindow.lua:625-636,769-770,845-854).
func GuildRankList(subType int64, rows []app.GuildRank, mine int64) map[string]any {
	list := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		list = append(list, map[string]any{
			"rank": row.Rank, "name": row.Guild.Name, "icon": row.Guild.Icon,
			"three_huoyue": row.Guild.ThreeDay, "member_num": row.Guild.MemberNum,
			"guild_id": row.Guild.GuildID, "des": row.Guild.Description,
			"guild_leader_name": row.Leader, "min_allow_level": row.Guild.MinAllowLevel,
		})
	}
	body := map[string]any{"rank_type": subType, "rank_info": map[string]any{"rank_info": list}}
	if mine > 0 {
		body["rank_info"].(map[string]any)["my_rank"] = map[string]any{"rank": mine}
	}
	return map[string]any{"rank_list": []map[string]any{body}}
}
