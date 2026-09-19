package guildwire

import app "gxb.local/backend/v2/internal/application/guildview"

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
	return map[string]any{"guild_info": Info(s.GuildInfo), "self_info": map[string]any{"job": int64(s.SelfRole), "join_time": s.JoinTime, "today_huoyue": int64(0), "huoyue_num": int64(0)}, "member_nums": s.MemberNum}
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
	// I6C does not own Guild ranking or contribution-window metrics. Stock
	// GuildDetailWindow requires numeric fields, so zero is an explicit
	// presentation sentinel until those later providers qualify.
	info["three_huoyue"] = int64(0)
	info["guild_rank"] = int64(0)
	return map[string]any{"guild_info": info}
}
