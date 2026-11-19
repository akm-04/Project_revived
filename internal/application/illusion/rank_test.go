package illusion

import (
	"context"
	"math"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankOnlyStore leaves every other Store method to the embedded interface; the
// board read only calls RankOfTx on this path.
type rankOnlyStore struct {
	Store
	rank int64
}

func (s rankOnlyStore) RankOfTx(context.Context, tx.Queryer, int64, int64, identity.PlayerID) (int64, error) {
	return s.rank, nil
}

func TestPlayerBoardUsesStoreRankBeyondReadWindow(t *testing.T) {
	mode := Mode{Store: rankOnlyStore{rank: 1001}}
	body, err := mode.playerBoard(context.Background(), identity.ActorContext{PlayerID: 100001}, d.RankPersonal, nil, 1, 1)
	if err != nil {
		t.Fatal(err)
	}
	info := body["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	entry, ok := info["my_rank"].(map[string]any)
	if !ok || entry["rank"] != int64(1001) {
		t.Fatalf("my_rank = %#v, want rank 1001 from the store", info["my_rank"])
	}
}

// decodeStockRankSeconds is the stock inverse in NewRankWindow.lua:797-824.
func decodeStockRankSeconds(hurt float64) int64 {
	fraction := hurt - math.Floor(hurt)
	if fraction == 0 {
		return 0
	}
	seconds := 0.03333333333333333 / fraction
	if seconds-math.Floor(seconds) >= 0.5 {
		return int64(math.Ceil(seconds))
	}
	return int64(math.Floor(seconds))
}

func personalBoard(t *testing.T, playerID int64, results []d.Result) (map[string]any, []map[string]any) {
	t.Helper()
	body, err := Mode{Directory: teamDirectory{}, Store: rankOnlyStore{}}.playerBoard(context.Background(),
		identity.ActorContext{PlayerID: identity.PlayerID(playerID)}, d.RankPersonal, results, 0, 0)
	if err != nil {
		t.Fatal(err)
	}
	info := body["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	return info["my_rank"].(map[string]any), info["rank_info"].([]map[string]any)
}

// A-177: a killed run with a known time carries the clear seconds in the
// fractional hurt, the inverse of the stock decoder; the integer text is the
// canonical damage.
func TestPlayerBoardEncodesKilledClearSecondsInHurt(t *testing.T) {
	results := []d.Result{
		{PlayerID: 100001, Hurt: d.DamageCap, CostTime: 30, Killed: true},
		{PlayerID: 100002, Hurt: d.DamageCap, CostTime: 1110, Killed: true},
		{PlayerID: 100003, Hurt: d.DamageCap, CostTime: 18000, Killed: true},
	}
	for player, wantSeconds := range map[int64]int64{100001: 1, 100002: 37, 100003: 600} {
		mine, rows := personalBoard(t, player, results)
		row := findBoardRow(t, rows, player)
		for _, value := range []any{mine["hurt"], row["hurt"]} {
			hurt, ok := value.(float64)
			if !ok {
				t.Fatalf("player %d hurt %T %v is not fractional", player, value, value)
			}
			if int64(hurt) != d.DamageCap || decodeStockRankSeconds(hurt) != wantSeconds {
				t.Fatalf("player %d hurt %v decodes to %d, want %d s and integer %d", player, hurt, decodeStockRankSeconds(hurt), wantSeconds, d.DamageCap)
			}
		}
	}
}

func TestPlayerBoardKeepsLossAndZeroTimeInteger(t *testing.T) {
	for _, item := range []struct {
		player int64
		want   int64
	}{
		{100004, 900},
		{100005, 800},
	} {
		mine, rows := personalBoard(t, item.player, []d.Result{
			{PlayerID: 100004, Hurt: 900, CostTime: 60},
			{PlayerID: 100005, Hurt: 800, CostTime: 0, Killed: true},
		})
		row := findBoardRow(t, rows, item.player)
		for _, value := range []any{mine["hurt"], row["hurt"]} {
			if value != item.want {
				t.Fatalf("player %d hurt %T %v, want integer %d", item.player, value, value, item.want)
			}
		}
	}
}

func TestGuildBoardKeepsIntegerHurt(t *testing.T) {
	guilds := fixedGuilds{{ID: 9001, Name: "guild", Members: []identity.PlayerID{11}}}
	body, err := Mode{Guilds: guilds}.guildBoard(context.Background(), identity.ActorContext{LogicalServerID: 1, PlayerID: 11}, d.RankGuild,
		[]d.Result{{PlayerID: 11, Hurt: 100, CostTime: 30, Killed: true}})
	if err != nil {
		t.Fatal(err)
	}
	info := body["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	row := info["rank_info"].([]map[string]any)[0]
	mine := info["my_rank"].(map[string]any)
	if row["hurt"] != int64(100) || mine["hurt"] != int64(100) {
		t.Fatalf("guild hurt row %T %v mine %T %v", row["hurt"], row["hurt"], mine["hurt"], mine["hurt"])
	}
}

type fixedGuilds []GuildSummary

func (g fixedGuilds) GuildSummaries(context.Context, identity.LogicalServerID) ([]GuildSummary, error) {
	return g, nil
}

func findBoardRow(t *testing.T, rows []map[string]any, player int64) map[string]any {
	t.Helper()
	for _, row := range rows {
		if row["player_id"] == player {
			return row
		}
	}
	t.Fatalf("player %d missing from %#v", player, rows)
	return nil
}
