// Package conquerschool shapes Conquer School owner views as the src_64
// ConquerSchool model reads them (MIDs 1568-1573, 2790).
package conquerschool

import (
	"slices"

	d "gxb.local/backend/v2/internal/domain/conquerschool"
)

// Info is the info object: team_status is one 0/1 per enemy team of the mission.
func Info(v d.InfoView) map[string]any {
	status := make([]int64, v.Teams)
	for i := range status {
		if slices.Contains(v.Mode.BeatenTeams, int64(i+1)) {
			status[i] = 1
		}
	}
	return map[string]any{"conquer_loop_id": v.Run.Loop, "current_id": v.Run.CurrentID, "passed_id": v.Run.PassedID, "left_times": v.Mode.LeftTimes,
		"is_buff_on": v.Mode.Buff, "report_award_times": v.Mode.AwardTimes, "team_status": status, "used_heroes": v.Mode.UsedHeroes, "used_pets": v.Mode.UsedPets,
		"buy_conquer_times": v.Mode.BuyTimes}
}

func InfoBody(v d.InfoView) map[string]any {
	return map[string]any{"info": Info(v)}
}

// Result sends conquer_lev, conquer_loop_id, conquer_region and awards only on
// promotion: the client re-enters chat rooms whenever conquer_lev is present.
func Result(v d.ResultView) map[string]any {
	body := map[string]any{"is_promote": v.Promoted, "is_buff_on": v.Info.Mode.Buff, "info": Info(v.Info)}
	if !v.Promoted {
		return body
	}
	awards := make([]map[string]any, 0, len(v.Rewards))
	for _, reward := range v.Rewards {
		awards = append(awards, map[string]any{"table_id": reward[0], "item_num": reward[1]})
	}
	body["awards"], body["conquer_lev"], body["conquer_loop_id"], body["conquer_region"] = awards, v.Progress.Level, v.Progress.Loop, v.Region
	return body
}

func Reports(reports []d.Report) map[string]any {
	rows := make([]map[string]any, 0, len(reports))
	for _, r := range reports {
		rows = append(rows, map[string]any{"player_name": r.Profile.Name, "conquer_lev": r.Profile.ConquerLevel, "conquer_loop_id": r.Profile.ConquerLoop, "lev": r.Profile.Level,
			"region": r.Profile.Server, "avatar_id": r.Profile.AvatarID, "avatar_frame_id": r.Profile.FrameID, "report_key": r.Key, "heroes": r.Heroes, "pet": r.Pet})
	}
	return map[string]any{"reports": rows}
}

// Report carries the replay as the JSON text the client json.decodes.
func Report(r d.Report) map[string]any {
	return map[string]any{"report": map[string]any{"report": string(r.Body)}}
}
