package arena

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
)

func tournamentFace(face d.Face) map[string]any {
	return map[string]any{"player_id": int64(face.Player), "player_name": face.Name, "lev": face.Level, "avatar_id": face.AvatarID, "avatar_frame_id": face.FrameID, "avatar_frame": face.FrameID, "region": int64(face.Server), "region_name": face.ServerName, "guild_name": face.GuildName, "conquer_lev": face.ConquerLevel, "conquer_loop_id": face.ConquerLoop, "conquerLev": face.ConquerLevel}
}

func tournamentStage(period d.TournamentPeriod, at time.Time) (int, int) {
	stage := period.Calendar.StageAt(at)
	substage := 0
	if stage == 3 || stage == 7 {
		substage = min(3, int(at.Sub(period.Calendar.Stages[stage-1])/(20*time.Minute))+1)
	}
	if stage == 6 {
		substage = 1
	}
	return stage, substage
}

func PlayoffsPhase(view d.TournamentView) map[string]any {
	stage, substage := tournamentStage(view.Period, view.At)
	return map[string]any{"stage": stage, "sub_stage": substage, "is_open": flag(stage > 0 && stage < 8 && !view.Period.Cancelled)}
}

func TournamentSupport(view d.TournamentView) map[string]any {
	target := identity.PlayerID(0)
	for _, supporter := range view.Period.Supporters {
		if supporter.Player == view.Viewer {
			target = supporter.Target
		}
	}
	stage, substage := tournamentStage(view.Period, view.At)
	entry := 1
	switch stage {
	case 3:
		entry = 1 + substage
	case 4:
		entry = 5
	case 5:
		entry = 6
	case 6:
		entry = 7
	case 7:
		entry = 7 + substage
	case 8:
		entry = 10
	}
	return map[string]any{"support_player": int64(target), "support_player_stage": entry}
}

func PlayoffsInfo(view d.TournamentView) map[string]any {
	players := map[string]any{}
	// Zero is a display-only BYE; it is never enrolled, supported or paid.
	players["0"] = map[string]any{"player_id": int64(0), "player_name": "-", "lev": int64(0), "avatar_id": int64(110001001), "avatar_frame_id": int64(0), "region": int64(0), "region_name": "", "guild_name": "", "conquer_lev": int64(0), "conquer_loop_id": int64(0), "fans": int64(0), "sign_up_times": int64(0), "win_times": int64(0), "dec": ""}
	signed := false
	for _, entrant := range view.Period.Entrants {
		row := tournamentFace(view.Faces[entrant.PlayerID])
		fans := int64(0)
		for _, supporter := range view.Period.Supporters {
			if supporter.Target == entrant.PlayerID {
				fans++
			}
		}
		row["fans"], row["sign_up_times"], row["win_times"], row["dec"] = fans, entrant.RegistrationSequence, entrant.GroupWins, entrant.Declaration
		players[strconv.FormatInt(int64(entrant.PlayerID), 10)] = row
		signed = signed || entrant.PlayerID == view.Viewer
	}
	status := map[string]any{"2": []int64{}, "3": []int64{}, "4": []int64{}, "5": []int64{}, "6": []int64{}, "7": []int64{}}
	if view.Period.RosterLocked && !view.Period.Cancelled {
		roster := []int64{}
		for _, group := range view.Period.Groups {
			for _, player := range group {
				roster = append(roster, int64(player))
			}
		}
		status["2"] = roster
	}
	for stage := 4; stage <= 6; stage++ {
		winners := []int64{}
		for _, contest := range view.Period.Contests {
			if contest.Stage == stage && contest.Complete {
				winners = append(winners, int64(contest.Winner))
			}
		}
		status[strconv.Itoa(stage)] = winners
	}
	for _, entrant := range view.Period.Entrants {
		if entrant.Placement == 1 {
			status["7"] = []int64{int64(entrant.PlayerID)}
		}
	}
	return map[string]any{"battle_status": status, "players_info": players, "player_info": map[string]any{"is_signed": flag(signed)}, "playoff_info": PlayoffsPhase(view), "support_info": TournamentSupport(view)}
}

func PlayoffsSignList(view d.TournamentView) map[string]any {
	rows := []map[string]any{}
	self := map[string]any{}
	for _, entrant := range view.Period.Entrants {
		row := tournamentFace(view.Faces[entrant.PlayerID])
		row["rank"], row["sign_up_times"] = entrant.PreviousSeasonRank, entrant.RegistrationSequence
		rows = append(rows, row)
		if entrant.PlayerID == view.Viewer {
			self = row
		}
	}
	return map[string]any{"sign_list": rows, "self_info": self}
}

func PlayoffsGroup(view d.TournamentView, group int) map[string]any {
	rows := map[string]any{}
	info := PlayoffsInfo(view)["players_info"].(map[string]any)
	for _, entrant := range view.Period.Entrants {
		if entrant.Group == group {
			key := strconv.FormatInt(int64(entrant.PlayerID), 10)
			rows[key] = info[key]
		}
	}
	return rows
}

func TournamentRecord(room d.TournamentRoom) map[string]any {
	played := room.PlayedRounds()
	count := len(played)
	if room.Status != d.RoomSettled {
		count = room.Selection.TeamCount()
	}
	kind := int64(2)
	if room.Casual {
		kind = 3
	}
	row := map[string]any{"record_id": room.Identifier.String(), "A_player_id": int64(room.Selection.Players[0]), "B_player_id": int64(room.Selection.Players[1]), "A_win_times": room.Wins[0], "B_win_times": room.Wins[1], "battle_count": count, "have_battled": flag(room.Status == d.RoomSettled && count > 0), "stage": room.Stage, "sub_stage": room.Substage, "battle_type": kind, "time": room.StartsAt.Unix()}
	if room.IsFriendFight() {
		row["model"] = room.FriendMode
		row["game_type"] = 2
		if room.Selection.TeamCount() == 1 {
			row["game_type"] = 1
		}
		delete(row, "battle_type")
	}
	for team := 0; team < d.SelectionTeamCount; team++ {
		actual := team
		if room.Status == d.RoomSettled {
			if team >= len(played) {
				row[fmt.Sprintf("team_%d", team+1)] = ""
				row[fmt.Sprintf("pet_id_%d", team+1)] = "0|0"
				continue
			}
			actual = played[team]
		}
		formations := [2]string{}
		for side := range formations {
			identifiers := []string{}
			for _, identifier := range room.Selection.Teams[side][actual].Heroes {
				identifiers = append(identifiers, strconv.FormatInt(identifier, 10))
			}
			formations[side] = strings.Join(identifiers, ":")
		}
		row[fmt.Sprintf("team_%d", team+1)] = strings.Join(formations[:], "|")
		row[fmt.Sprintf("pet_id_%d", team+1)] = fmt.Sprintf("%d|%d", room.Selection.Teams[0][actual].Pet, room.Selection.Teams[1][actual].Pet)
	}
	return row
}

func PlayoffsMatches(view d.TournamentView) map[string]any {
	rows := []map[string]any{}
	stage, _ := tournamentStage(view.Period, view.At)
	for _, room := range view.Rooms {
		if room.Stage == stage {
			rows = append(rows, TournamentRecord(room))
		}
	}
	return map[string]any{"fight_list": rows, "playoff_info": PlayoffsPhase(view)}
}

func TournamentRecords(rooms []d.TournamentRoom, player identity.PlayerID, stage int) []map[string]any {
	rows := []map[string]any{}
	for _, room := range rooms {
		participant := room.Selection.Players[0] == player || room.Selection.Players[1] == player
		if room.Status == d.RoomSettled && participant && (stage == 0 || room.Stage == stage) {
			rows = append(rows, TournamentRecord(room))
		}
	}
	return rows
}

func TournamentRoom(view d.TournamentRoomView) map[string]any {
	room := view.Room
	pets := [2]any{}
	for side := range pets {
		identifier := room.Selection.Teams[side][room.Selection.Team-1].Pet
		if identifier != 0 {
			pets[side] = view.Pets[side][strconv.FormatInt(identifier, 10)]
		}
	}
	body := map[string]any{"room_key": room.SelectionKey(), "stage": room.Selection.Turn, "stage_start_time": room.Selection.Deadline.Add(-d.SelectionTurnLifetime).Unix(), "server_time": view.At.Unix(), "is_open": flag(room.Status != d.RoomPreparing), "A_player_id": int64(room.Selection.Players[0]), "B_player_id": int64(room.Selection.Players[1]), "A_player_info": tournamentFace(room.Faces[0]), "B_player_info": tournamentFace(room.Faces[1]), "A_partners_info": view.Heroes[0], "B_partners_info": view.Heroes[1], "A_pet_info": pets[0], "B_pet_info": pets[1], "A_prepared": flag(room.Ready[0]), "B_prepared": flag(room.Ready[1]), "params": map[string]any{"team_id": room.Selection.Team, "stage": room.Stage, "record_id": room.Identifier.String(), "record_info": TournamentRecord(room)}}
	return body
}

func TournamentReport(view d.TournamentRoomView) map[string]any {
	body := TournamentRoom(view)
	body["record_info"] = TournamentRecord(view.Room)
	body["A_pet_info"], body["B_pet_info"] = view.Pets[0], view.Pets[1]
	body["report"] = []map[string]any{}
	if len(view.Report) > 0 {
		body["report"] = []map[string]any{{"content": string(view.Report)}}
	}
	return body
}

func CasualInfo(view d.CasualView) map[string]any {
	matchTime := int64(0)
	matching := int64(0)
	if view.Entry != nil {
		matchTime = view.Entry.AdmittedAt.Unix()
		matching = flag(view.Entry.Status == d.QueueWaiting && view.At.Before(view.Entry.ExpiresAt))
	}
	return map[string]any{"match_time": matchTime, "is_matching": matching, "is_open": flag(view.Period.Open(view.At)), "start_time": view.Period.OpensAt.Unix(), "end_time": view.Period.ClosesAt.Unix()}
}

func CasualRanks(view d.CasualView) map[string]any {
	rows := []map[string]any{}
	rank := int64(0)
	point := int64(0)
	for index, standing := range view.Standings {
		if index < rankRowsForCasual {
			row := tournamentFace(view.Faces[standing.PlayerID])
			row["rank"], row["point"], row["damage"] = index+1, standing.Points, standing.Points
			rows = append(rows, row)
		}
		if standing.PlayerID == view.Viewer {
			rank, point = int64(index+1), standing.Points
		}
	}
	return map[string]any{"rank_list": rows, "my_rank": rank, "my_point": point}
}

const rankRowsForCasual = 50
