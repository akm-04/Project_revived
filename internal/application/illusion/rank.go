package illusion

import (
	"context"
	"slices"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type guildScore struct {
	Guild GuildSummary
	Total int64
}

// RankList answers MID 301 subtypes 24-27 from this mode's own best-hit list.
// 24/25/27 are the per-player board (a team score counts as each member's own
// result); 26 sums each current member's best hit into a guild total.
func (s Mode) RankList(c context.Context, a identity.ActorContext, subtype int64, op operation.Context) (map[string]any, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.IllusionCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return nil, err
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, s.Fresh, int64(a.LogicalServerID))
	if err != nil {
		return nil, err
	}
	results := []d.Result{}
	if found {
		occurrence.Roll(catalog, at)
		if results, err = s.Store.ReadRankTx(c, s.Fresh, occurrence.LogicalServerID, occurrence.OpenDay, rankLimit); err != nil {
			return nil, err
		}
	}
	switch subtype {
	case d.RankPersonal, d.RankCommunity, d.RankTeam:
		return s.playerBoard(c, a, subtype, results)
	case d.RankGuild:
		return s.guildBoard(c, a, subtype, results)
	default:
		return nil, d.ErrInvalid
	}
}

func (s Mode) playerBoard(c context.Context, a identity.ActorContext, subtype int64, results []d.Result) (map[string]any, error) {
	ordered := d.OrderRank(results)
	rows, err := s.playerRows(c, ordered, boardLimit)
	if err != nil {
		return nil, err
	}
	rank, hurt := d.RankOf(ordered, int64(a.PlayerID))
	mine := map[string]any{}
	if rank > 0 {
		mine = map[string]any{"rank": rank, "hurt": hurt}
	}
	return rankListBody(subtype, mine, rows), nil
}

func (s Mode) playerRows(c context.Context, ordered []d.Result, limit int) ([]map[string]any, error) {
	rows := make([]map[string]any, 0, min(len(ordered), limit))
	for index, entry := range ordered[:min(len(ordered), limit)] {
		profile, found, err := s.Directory.ProfileTx(c, s.Fresh, identity.PlayerID(entry.PlayerID))
		if err != nil {
			return nil, err
		}
		if !found {
			continue
		}
		rows = append(rows, playerRow(profile, entry.Hurt, int64(index+1)))
	}
	return rows, nil
}

func playerRow(profile playerdirectory.Profile, hurt, rank int64) map[string]any {
	return map[string]any{"player_id": int64(profile.PlayerID), "player_name": profile.Name, "level": profile.Level,
		"avatar_id": profile.AvatarID, "avatar_frame_id": profile.AvatarFrameID, "conquer_lev": profile.ConquerLevel,
		"conquer_loop_id": profile.ConquerLoopID, "hurt": hurt, "rank": rank}
}

func (s Mode) guildBoard(c context.Context, a identity.ActorContext, subtype int64, results []d.Result) (map[string]any, error) {
	if s.Guilds == nil {
		return nil, d.ErrUnavailable
	}
	guilds, err := s.Guilds.GuildSummaries(c, a.LogicalServerID)
	if err != nil {
		return nil, err
	}
	scores := guildScores(guilds, results)
	rows := make([]map[string]any, 0, min(len(scores), boardLimit))
	mine := map[string]any{}
	for index, score := range scores[:min(len(scores), boardLimit)] {
		rows = append(rows, map[string]any{"guild_id": score.Guild.ID, "name": score.Guild.Name, "icon": score.Guild.Icon,
			"member_num": int64(len(score.Guild.Members)), "des": score.Guild.Description, "min_allow_level": score.Guild.MinAllowLevel,
			"hurt": score.Total, "rank": int64(index + 1)})
	}
	for index, score := range scores {
		if slices.Contains(score.Guild.Members, a.PlayerID) {
			mine = map[string]any{"rank": int64(index + 1), "hurt": score.Total}
			break
		}
	}
	return rankListBody(subtype, mine, rows), nil
}

// guildScores sums the best hit of every current member and orders by total,
// then guild id.
func guildScores(guilds []GuildSummary, results []d.Result) []guildScore {
	best := make(map[int64]int64, len(results))
	for _, entry := range results {
		if entry.Hurt > best[entry.PlayerID] {
			best[entry.PlayerID] = entry.Hurt
		}
	}
	scores := make([]guildScore, 0, len(guilds))
	for _, guild := range guilds {
		var total int64
		for _, member := range guild.Members {
			total += best[int64(member)]
		}
		scores = append(scores, guildScore{Guild: guild, Total: total})
	}
	slices.SortFunc(scores, func(left, right guildScore) int {
		switch {
		case left.Total != right.Total:
			if left.Total > right.Total {
				return -1
			}
			return 1
		case left.Guild.ID < right.Guild.ID:
			return -1
		case left.Guild.ID > right.Guild.ID:
			return 1
		default:
			return 0
		}
	})
	return scores
}

func rankListBody(subtype int64, mine map[string]any, rows []map[string]any) map[string]any {
	return map[string]any{"rank_list": []map[string]any{{"rank_type": subtype, "rank_info": map[string]any{"my_rank": mine, "rank_info": rows}}}}
}
