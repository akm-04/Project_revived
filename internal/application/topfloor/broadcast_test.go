package topfloor

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

func TestNextWinStreak(t *testing.T) {
	cases := []struct {
		name     string
		previous int64
		attack   bool
		won      bool
		want     int64
	}{
		{"attack win increments", 4, true, true, 5},
		{"attack loss resets", 6, true, false, 0},
		{"defence win leaves unchanged", 3, false, true, 3},
		{"defence loss leaves unchanged", 3, false, false, 3},
	}
	for _, tc := range cases {
		if got := nextWinStreak(tc.previous, tc.attack, tc.won); got != tc.want {
			t.Fatalf("%s: got %d want %d", tc.name, got, tc.want)
		}
	}
}

func TestAnnouncesWinStreak(t *testing.T) {
	for streak := int64(0); streak <= 16; streak++ {
		want := streak == 5 || streak == 10 || streak == 15
		if got := announcesWinStreak(streak); got != want {
			t.Fatalf("streak %d announced=%v want %v", streak, got, want)
		}
	}
}

func TestTopThreeRank(t *testing.T) {
	cases := []struct {
		name    string
		outcome d.Outcome
		want    int64
		ok      bool
	}{
		{"improves into rank 3", d.Outcome{Win: true, ChallengerBefore: 5, ChallengerAfter: 3}, 3, true},
		{"improves into rank 1", d.Outcome{Win: true, ChallengerBefore: 2, ChallengerAfter: 1}, 1, true},
		{"win keeps same rank in top three", d.Outcome{Win: true, ChallengerBefore: 3, ChallengerAfter: 3}, 0, false},
		{"win improves to rank 4", d.Outcome{Win: true, ChallengerBefore: 6, ChallengerAfter: 4}, 0, false},
		{"loss does not announce", d.Outcome{Win: false, ChallengerBefore: 5, ChallengerAfter: 5}, 0, false},
	}
	for _, tc := range cases {
		rank, ok := topThreeRank(tc.outcome)
		if rank != tc.want || ok != tc.ok {
			t.Fatalf("%s: got (%d,%v) want (%d,%v)", tc.name, rank, ok, tc.want, tc.ok)
		}
	}
}

func TestSettlementMessages(t *testing.T) {
	catalog := d.Catalog{FirstNames: []string{"Robot"}, LastNames: []string{"Name"}}
	robot := d.Fight{Server: 7, Challenger: identity.PlayerID(700001), Defender: d.Occupant{Robot: 7}}
	messages := settlementMessages(catalog, robot, d.Outcome{Win: true, ChallengerBefore: 5, ChallengerAfter: 3, BestAfter: 3}, 3)
	if len(messages) != 1 {
		t.Fatalf("robot top three messages=%+v", messages)
	}
	topThree := messages[0]
	if topThree.MsgType != app.ArenaTop3 || topThree.Fields.Rank != 3 || topThree.Fields.EnemyName != catalog.RobotName(7) || topThree.Enemy.Valid() {
		t.Fatalf("robot top three message=%+v", topThree)
	}
	if err := topThree.Validate(); err != nil {
		t.Fatal(err)
	}

	human := d.Fight{Server: 7, Challenger: identity.PlayerID(700001), Defender: d.Occupant{Player: identity.PlayerID(700002)}}
	messages = settlementMessages(catalog, human, d.Outcome{Win: true, ChallengerBefore: 5, ChallengerAfter: 2, BestAfter: 2}, 2)
	if len(messages) != 1 || messages[0].Enemy != identity.PlayerID(700002) || messages[0].Fields.EnemyName != "" {
		t.Fatalf("human top three messages=%+v", messages)
	}
	if err := messages[0].Validate(); err != nil {
		t.Fatal(err)
	}

	messages = settlementMessages(catalog, robot, d.Outcome{Win: true, ChallengerBefore: 3, ChallengerAfter: 3}, 3)
	if len(messages) != 0 {
		t.Fatalf("same-rank win announced: %+v", messages)
	}
	for _, streak := range []int64{4, 5, 6} {
		messages = settlementMessages(catalog, robot, d.Outcome{Win: true, ChallengerBefore: 8, ChallengerAfter: 8}, streak)
		if streak == 5 {
			if len(messages) != 1 || messages[0].MsgType != app.ArenaWins || messages[0].Fields.KeepWinTimes != 5 {
				t.Fatalf("streak 5 messages=%+v", messages)
			}
			if err := messages[0].Validate(); err != nil {
				t.Fatal(err)
			}
			continue
		}
		if len(messages) != 0 {
			t.Fatalf("streak %d announced: %+v", streak, messages)
		}
	}
	messages = settlementMessages(catalog, robot, d.Outcome{Win: false, ChallengerBefore: 8, ChallengerAfter: 8}, 0)
	if len(messages) != 0 {
		t.Fatalf("loss announced: %+v", messages)
	}
}
