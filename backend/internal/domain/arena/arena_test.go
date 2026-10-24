package arena

import (
	"encoding/json"
	"errors"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func catalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/arena_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var c Catalog
	if err = json.Unmarshal(raw, &c); err != nil {
		t.Fatal(err)
	}
	if err = c.Validate(); err != nil {
		t.Fatal(err)
	}
	return c
}

var gmt8 = time.FixedZone("GMT+8", 8*3600)

func TestSeasonCalendar(t *testing.T) {
	c := catalog(t)
	first := c.SeasonNumbered(1)
	if !first.OpensAt.Equal(time.Date(2022, 10, 28, 5, 0, 0, 0, gmt8)) || !first.ClosesAt.Equal(time.Date(2022, 12, 12, 0, 0, 0, 0, gmt8)) {
		t.Fatal("source season window", first)
	}
	now := c.SeasonAt(time.Date(2026, 10, 20, 12, 0, 0, 0, gmt8))
	if now.Number != 33 || !now.Open(time.Date(2026, 10, 20, 12, 0, 0, 0, gmt8)) {
		t.Fatal("repeating seasons", now)
	}
	gap := time.Date(2022, 12, 12, 3, 0, 0, 0, gmt8)
	if c.SeasonAt(gap).Number != 1 || c.SeasonAt(gap).Open(gap) || c.LatestClosed(gap) != 1 || c.SeasonAt(gap.Add(2*time.Hour)).Number != 2 {
		t.Fatal("closed gap before the next season")
	}
	if Day(time.Date(2026, 10, 20, 4, 59, 0, 0, gmt8)) == Day(time.Date(2026, 10, 20, 5, 0, 0, 0, gmt8)) {
		t.Fatal("day begins at 05:00")
	}
}

func TestLevelsStarsAndProtections(t *testing.T) {
	c := catalog(t)
	for star, level := range map[int64]int64{0: 1, 2: 1, 3: 2, 10: 5, 11: 6, 94: 26, 95: 26, 90: 25} {
		if c.LevelOf(star) != level {
			t.Fatal("level of", star, c.LevelOf(star))
		}
	}
	at := time.Unix(1700000000, 0)
	attack := func(star, keep int64, win bool) Player {
		return c.Attack(Player{Star: star, KeepWin: keep}, Player{}, win, false, at).Attacker
	}
	if attack(5, 0, true).Star != 6 || attack(5, 4, true).Star != 7 || attack(70, 4, true).Star != 71 || attack(94, 4, true).Star != 95 {
		t.Fatal("win gems and the LV20 streak bonus")
	}
	if attack(10, 0, false).Star != 10 || attack(11, 0, false).Star != 10 || attack(90, 0, false).Star != 90 || attack(91, 0, false).Star != 90 || attack(95, 0, false).Star != 95 {
		t.Fatal("loss protections")
	}
	won := attack(5, 2, true)
	if won.KeepWin != 3 || won.WinTimes != 1 || won.TotalFight != 1 || attack(5, 2, false).KeepWin != 0 {
		t.Fatal("streak and statistics")
	}
	challenger := c.Attack(Player{Star: 95, Point: 100}, Player{Point: 300}, true, false, at).Attacker
	if challenger.Point != 100+min(50, 10+20) || c.Attack(Player{Star: 95, Point: 5}, Player{Point: 0}, false, false, at).Attacker.Point != 0 {
		t.Fatal("Lord points", challenger.Point)
	}
	p := Player{Star: 20}
	coins := []int64{}
	for range 11 {
		r := c.Attack(p, Player{}, true, false, at)
		p, coins = r.Attacker, append(coins, r.Coins)
	}
	if coins[0] != 50 || coins[9] != 50 || coins[10] != 0 || c.Attack(Player{}, Player{}, false, false, at).Coins != 25 {
		t.Fatal("first 10 daily coins", coins)
	}
	if r := c.Attack(Player{}, Player{Star: 30, DefenseWins: 2}, false, true, at); r.Coins != 0 || r.Defender.Star != 30 {
		t.Fatal("forfeit has no coins and leaves the defender")
	}
}

func TestDefenseStreaks(t *testing.T) {
	c := catalog(t)
	at := time.Unix(1700000000, 0)
	held := Player{Star: 30}
	for range 3 {
		held = c.Attack(Player{}, held, false, false, at).Defender
	}
	lost := Player{Star: 30}
	for range 3 {
		lost = c.Attack(Player{}, lost, true, false, at).Defender
	}
	if held.Star != 31 || held.DefenseWins != 0 || lost.Star != 27 || lost.DefenseLosses != 0 {
		t.Fatal("third consecutive defense", held, lost)
	}
	floor := Player{Star: 12, DefenseLosses: 2}
	if c.Attack(Player{}, floor, true, false, at).Defender.Star != 10 {
		t.Fatal("defense loss floors at the protection")
	}
}

func TestMissionsAndExchange(t *testing.T) {
	c := catalog(t)
	at := time.Unix(1700000000, 0)
	p := NewPlayer(c, 100001, 1, at)
	if len(p.Missions) != 3 || p.Missions[0].MissionID == p.Missions[1].MissionID {
		t.Fatal("three distinct missions", p.Missions)
	}
	p.Missions = []MissionSlot{{MissionID: 1004}, {MissionID: 1010}, {MissionID: 1001}}
	p.KeepWin = 2
	p = c.Progress(p, 12, 0, true)
	if !p.Missions[0].Complete || p.Missions[1].Current != 1 || !p.Missions[2].Complete {
		t.Fatal("mission progress", p.Missions)
	}
	p, coin, err := c.Claim(p, 1004, at)
	if err != nil || coin != 120 || len(p.Missions) != 2 {
		t.Fatal("claim", err, coin)
	}
	if _, err = c.GiveUp(p, 1001, at); !errors.Is(err, ErrRefused) {
		t.Fatal("a completed mission is claimed, not given up")
	}
	if c.Rolled(p, at.Add(71999*time.Second)).Missions[1].MissionID == 0 || len(c.Rolled(p, at.Add(71999*time.Second)).Missions) != 2 || len(c.Rolled(p, at.Add(72000*time.Second)).Missions) != 3 {
		t.Fatal("refill after 72000 s")
	}
	girl := Girl{Known: true, Owned: true, Star: 4, CanAwaken: true}
	p, award, cost, err := c.Exchange(p, ExchangeStar, 11001, girl)
	if err != nil || award.AddStar != 1 || cost != 270 || p.ExchangeTimes[0] != 1 {
		t.Fatal("star exchange", err, award, cost)
	}
	if _, _, _, err = c.Exchange(p, ExchangeStar, 11001, girl); !errors.Is(err, ErrRefused) {
		t.Fatal("full star refused")
	}
	if _, _, _, err = c.Exchange(p, ExchangeSummon, 11001, girl); !errors.Is(err, ErrRefused) {
		t.Fatal("owned girl cannot be summoned")
	}
	p, award, cost, err = c.Exchange(p, ExchangeSummon, 12001, Girl{Known: true, InitialStar: 3})
	if err != nil || !award.Summon || cost != 900 {
		t.Fatal("summon", err, award, cost)
	}
	if _, award, _, err = c.Exchange(p, ExchangeAwaken, 12001, Girl{Known: true, InitialStar: 3, CanAwaken: true}); err != nil || !award.Awake {
		t.Fatal("awaken a summoned girl", err)
	}
	if rolled := c.Rolled(p, c.SeasonAt(at).ClosesAt.Add(6*time.Hour)); len(rolled.Awards) != 0 || rolled.ExchangeTimes != [3]int64{} || len(rolled.Missions) == 0 {
		t.Fatal("full season reset keeps missions")
	}
}

func TestPickWidensAndSettle(t *testing.T) {
	c := catalog(t)
	self := Player{PlayerID: 1, Star: 50, Season: 33}
	standings := []Standing{{PlayerID: 1, Star: 50, Defended: true}, {PlayerID: 2, Star: 80, Defended: true}, {PlayerID: 3, Star: 45, Defended: false}}
	if id, ok := c.Pick(self, standings, false); !ok || id != 2 {
		t.Fatal("widen to the only defended opponent", id)
	}
	if _, ok := c.Pick(Player{PlayerID: 1}, standings[:1], true); ok {
		t.Fatal("no opponent")
	}
	if id, ok := c.Pick(Player{PlayerID: 9}, []Standing{{PlayerID: 4, Star: 0, Defended: true}}, false); !ok || id != 4 {
		t.Fatal("zero-star players match")
	}
	at := time.Unix(1700000000, 0)
	lines := c.Settle([]Standing{
		{PlayerID: 5, Star: 95, Point: 10, TotalFight: 3, StarAt: at},
		{PlayerID: 6, Star: 95, Point: 40, TotalFight: 3, StarAt: at},
		{PlayerID: 7, Star: 20, TotalFight: 1},
		{PlayerID: 8, Star: 60},
	})
	if len(lines) != 3 || lines[0].Standing.PlayerID != 6 || !lines[0].Champion || lines[1].Champion || lines[0].Reward.FrameID != 120001216 || lines[2].Level != 9 || lines[2].Reward.SkinID != 0 {
		t.Fatal("settlement lines", lines)
	}
	if Rank(Order([]Standing{{PlayerID: 1, Star: 3}, {PlayerID: identity.PlayerID(2), Star: 9}}), 1) != 2 {
		t.Fatal("rank")
	}
}

func TestFormation(t *testing.T) {
	base := func(id int64) int64 { return id % 1000 }
	if !ValidFormation([]int64{1, 2, 3}, base, false) || ValidFormation([]int64{1, 1001}, base, false) || ValidFormation([]int64{1, 2, 3}, base, true) || ValidFormation(nil, base, false) {
		t.Fatal("formation rules")
	}
	m := Match{Status: StatusStarted, StartedAt: time.Unix(1700000000, 0)}
	if m.Abandoned(m.StartedAt.Add(599*time.Second)) || !m.Abandoned(m.StartedAt.Add(600*time.Second)) {
		t.Fatal("abandon window")
	}
}
