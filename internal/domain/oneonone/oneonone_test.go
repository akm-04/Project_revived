package oneonone

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func catalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/one_on_one_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var c Catalog
	if err = json.Unmarshal(raw, &c); err != nil || c.Validate() != nil {
		t.Fatal(err, c.Validate())
	}
	return c
}

// 2026-10-21 is a Wednesday; local is GMT+8.
func local(day, hour, minute int) time.Time {
	return time.Date(2026, 10, day, hour, minute, 0, 0, time.FixedZone("GMT+8", 8*3600)).UTC()
}

func TestCalendar(t *testing.T) {
	c := catalog(t)
	if Weekday(LocalDay(local(21, 12, 0))) != 3 || Weekday(LocalDay(local(25, 12, 0))) != 7 {
		t.Fatal("weekday")
	}
	if c.Open(local(21, 7, 59)) || !c.Open(local(21, 8, 0)) || !c.Open(local(21, 21, 59)) || c.Open(local(21, 22, 0)) {
		t.Fatal("opening hours 08:00-22:00")
	}
	if TriesDay(local(22, 4, 59)) != TriesDay(local(21, 12, 0)) || TriesDay(local(22, 5, 0)) == TriesDay(local(21, 12, 0)) {
		t.Fatal("tries reset 05:00")
	}
	if c.LatestSettlement(local(21, 21, 59)) != LocalDay(local(18, 12, 0)) || c.LatestSettlement(local(21, 22, 0)) != LocalDay(local(21, 12, 0)) {
		t.Fatal("Wednesday/Sunday 22:00 settlements")
	}
	r := c.NewCompetition("x", local(20, 12, 0))
	var kinds []string
	at := local(26, 23, 0)
	for {
		next, ok := c.NextDue(r, at)
		if !ok {
			break
		}
		kinds = append(kinds, next.Kind)
		switch next.Kind {
		case TransitionSettle:
			r.SettledThrough = next.Key
		case TransitionOpen:
			r.OpenedThrough = next.Key
		default:
			r.ClosedThrough = next.Key
		}
	}
	want := []string{TransitionSettle, TransitionOpen, TransitionClose, TransitionSettle}
	if len(kinds) != len(want) {
		t.Fatal(kinds)
	}
	for i := range want {
		if kinds[i] != want[i] {
			t.Fatal(kinds)
		}
	}
}

func TestEloAndDecide(t *testing.T) {
	c := catalog(t)
	if c.Gain(4300, 4300) != 10 || c.Gain(4300, 4700) <= 10 || c.Gain(4700, 4300) >= 10 || c.Gain(3000, 6000) > 20 {
		t.Fatal("Elo K 20 around 10 per even win", c.Gain(4300, 4700), c.Gain(4700, 4300))
	}
	at := local(21, 12, 0)
	a := c.NewPlayer(100001, 1, "r", at)
	b := c.NewPlayer(200001, 2, "r", at)
	b.Points = 4640
	m := Match{Mode: ModeNormal}
	a2, b2, o := c.Decide(m, a, b, []int64{1, 1}, true, at)
	if a2.Points <= 4300 || b2.Points >= 4640 || a2.Points-4300 != 4640-b2.Points || a2.WinStreak != 1 || o.AttackerBefore.Points != 4300 {
		t.Fatal("junior points move", a2.Points, b2.Points)
	}
	b.Points = 3005
	low := a
	low.Points = 3005
	_, b3, _ := c.Decide(m, low, b, []int64{1, 1}, true, at)
	if b3.Points != 3000 {
		t.Fatal("points floor 3000")
	}
	a.Points = 4840
	strong := c.NewPlayer(200002, 2, "r", at)
	strong.Points, strong.Level = 4950, LevelJunior1
	a4, _, _ := c.Decide(m, a, strong, []int64{1, 1}, true, at)
	if a4.Points < 4850 || a4.Level != LevelJunior1 {
		t.Fatal("level follows points")
	}
	s1 := Player{Position: Position{Level: LevelSenior, Slot: 520}}
	s2 := Player{Position: Position{Level: LevelSenior, Slot: 510}}
	x, y, _ := c.Decide(m, s1, s2, []int64{1, 0, 1}, true, at)
	if x.Slot != 510 || y.Slot != 520 {
		t.Fatal("senior swap on win against a better slot")
	}
	x, y, _ = c.Decide(m, s2, s1, []int64{1, 1, 1}, true, at)
	if x.Slot != 510 || y.Slot != 520 {
		t.Fatal("no swap against a worse slot")
	}
	j := c.NewPlayer(100002, 1, "r", at)
	j.Points, j.Level = 4900, LevelJunior1
	j.Mode, j.Candidates = ModePromotion, []identity.PlayerID{200003}
	senior := c.NewPlayer(200003, 2, "r", at)
	senior.Position = Position{Level: LevelSenior, Slot: 5000, Points: 4200, PointsAt: at}
	pm := Match{Mode: ModePromotion}
	j, senior, _ = c.Decide(pm, j, senior, []int64{1, 1, 1}, true, at)
	if j.Mode != ModePromotion || j.PromotionWins != 1 || j.Level != LevelJunior1 {
		t.Fatal("first promotion win", j)
	}
	j, senior, o = c.Decide(pm, j, senior, []int64{1, 1, 1}, true, at)
	if !o.Promoted || j.Level != LevelSenior || j.Slot != 5000 || j.Points != 4200 || senior.Slot != 0 || senior.Points != 4900 || senior.Level != LevelJunior1 || j.Mode != ModeNormal {
		t.Fatal("promotion swaps slot and points", j.Position, senior.Position)
	}
}

func attempt(t *testing.T) ids.UUID {
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func TestWinsMajorityAndForfeit(t *testing.T) {
	won := func(star int64) Round { return Round{AttemptID: attempt(t), Star: star, Resolved: true} }
	wins, win, done := Wins([]Round{won(3), won(0), won(1)})
	if !done || !win || len(wins) != 3 {
		t.Fatal("best of three", wins)
	}
	wins, win, done = Wins([]Round{won(0), won(0), won(3), won(3), won(3)})
	if !done || !win || len(wins) != 5 {
		t.Fatal("best of five", wins)
	}
	wins, win, done = Wins([]Round{won(1), won(1), {}})
	if !done || !win || len(wins) != 2 {
		t.Fatal("stop at majority", wins)
	}
	_, _, done = Wins([]Round{won(1), {AttemptID: attempt(t)}, won(1)})
	if done {
		t.Fatal("an unresolved round leaves the match open")
	}
	wins, win, _ = Wins([]Round{won(0), {}, {}})
	if !win || len(wins) != 3 {
		t.Fatal("missing defender teams are forfeited", wins)
	}
}

func TestRankOfferAndPromotion(t *testing.T) {
	c := catalog(t)
	at := local(21, 12, 0)
	all := []Standing{
		{Player: 100001, Server: 1, HasDefense: true, Position: Position{Level: LevelMaster, Slot: 1}},
		{Player: 200001, Server: 2, HasDefense: true, Position: Position{Level: LevelSenior, Slot: 501}},
	}
	for i := int64(0); i < 10; i++ {
		all = append(all, Standing{Player: identity.PlayerID(100010 + i), Server: 1, HasDefense: i != 3, Position: Position{Level: LevelJunior3, Points: 4300 + 10*i, PointsAt: at}})
	}
	all[11].Level, all[11].Points = LevelJunior1, 4900
	ranked := c.Rank(all)
	if ranked[0].Global != 1 || ranked[1].Global != 501 || ranked[2].Global != 5001 || ranked[2].Player != 100019 || ranked[2].ServerRank != 2 || ranked[1].ServerRank != 1 {
		t.Fatal("global and server ranks", ranked[:3])
	}
	if len(c.Offer(ranked, 100019, 1, 0)) != 0 {
		t.Fatal("the top of a group has no opponent")
	}
	offer := c.Offer(ranked, 100010, 1, 0)
	if len(offer) == 0 || len(offer) > 3 {
		t.Fatal("offers", offer)
	}
	for _, p := range offer {
		r, _ := Find(ranked, p)
		if Group(r.Level) != LevelJunior1 || r.Points <= 4300 || !r.HasDefense {
			t.Fatal("offers are better members of the same group with a defense", r)
		}
	}
	o := c.OpenPromotion(ranked, LocalDay(at))
	if o.Moves[200001].Level != LevelMaster || o.Moves[200001].Slot != 2 || o.Moves[100019].Level != LevelSenior || o.Moves[100019].Slot != 501 || len(o.Entrants) != 0 {
		t.Fatal("vacancies fill with the best eligible players", o)
	}
}

func TestTeamsAndAdmission(t *testing.T) {
	c := catalog(t)
	if !ValidTeams([]Team{{Heroes: []int64{1, 2}, Pet: 9}, {Heroes: []int64{3}}, {Heroes: []int64{4}}}, 3) || ValidTeams([]Team{{Heroes: []int64{1}}, {Heroes: []int64{1}}, {Heroes: []int64{4}}}, 3) ||
		ValidTeams([]Team{{Heroes: []int64{1}, Pet: 9}, {Heroes: []int64{2}, Pet: 9}, {Heroes: []int64{4}}}, 3) || ValidTeams([]Team{{Heroes: []int64{1}}}, 3) {
		t.Fatal("team shape")
	}
	at := local(21, 12, 0)
	p := c.NewPlayer(100001, 1, "r", at)
	if _, err := c.Admit(p, local(21, 23, 0)); err != ErrClosedHours {
		t.Fatal("closed hours")
	}
	p, err := c.Admit(p, at)
	if err != nil || p.TriesLeft != 9 {
		t.Fatal("try consumed")
	}
	if _, err = c.Admit(p, at.Add(59*time.Second)); err != ErrRefused {
		t.Fatal("junior cooldown 60 s")
	}
	if _, _, err = c.ResetTimer(p, c.Privilege(2), false, at); err != ErrRefused {
		t.Fatal("reset needs VIP top_reset or a monthly card")
	}
	if p2, cost, err := c.ResetTimer(p, c.Privilege(3), false, at); err != nil || cost != 50 || p2.LastFightAt != nil {
		t.Fatal("paid reset")
	}
	p.TriesLeft = 0
	if p2, cost, err := c.Buy(p, c.Privilege(3), at); err != nil || cost != 50 || p2.TriesLeft != 10 {
		t.Fatal("buy restores 10")
	}
}
