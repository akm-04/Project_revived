package topfloor

import (
	"gxb.local/backend/v2/internal/application/broadcast"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// PRIVATE_POLICY: the source names no Top Floor win-streak milestone. The
// tunable list is docs/i9/I9_BROADCAST_PRIVATE_POLICY_V1.json.
var winStreakMilestones = []int64{5, 10, 15, 20, 25, 30, 35, 40, 45, 50}

func nextWinStreak(previous int64, attack, won bool) int64 {
	if !attack {
		return previous
	}
	if won {
		return previous + 1
	}
	return 0
}

func announcesWinStreak(streak int64) bool {
	for _, milestone := range winStreakMilestones {
		if streak == milestone {
			return true
		}
	}
	return false
}

// topThreeRank reports the rank a settlement announces on SYSTEM_BROADCAST 3003.
// Only an attack win that strictly improves the challenger into the top three
// announces; a win that keeps the same rank does not.
func topThreeRank(outcome d.Outcome) (int64, bool) {
	if !outcome.Win || outcome.ChallengerAfter >= outcome.ChallengerBefore {
		return 0, false
	}
	if outcome.ChallengerAfter < 1 || outcome.ChallengerAfter > 3 {
		return 0, false
	}
	return outcome.ChallengerAfter, true
}

// settlementMessages shapes the lobby announcements one settled fight produces.
func settlementMessages(catalog d.Catalog, f d.Fight, outcome d.Outcome, challengerStreak int64) []broadcast.Message {
	messages := make([]broadcast.Message, 0, 2)
	if rank, ok := topThreeRank(outcome); ok {
		message := broadcast.Message{MID: broadcast.SystemMID, MsgType: broadcast.ArenaTop3, Server: f.Server, Player: f.Challenger, Fields: broadcast.Fields{Rank: rank}}
		if f.Defender.IsRobot() {
			message.Fields.EnemyName = catalog.RobotName(f.Defender.Robot)
		} else {
			message.Enemy = f.Defender.Player
		}
		messages = append(messages, message)
	}
	if outcome.Win && announcesWinStreak(challengerStreak) {
		messages = append(messages, broadcast.Message{MID: broadcast.SystemMID, MsgType: broadcast.ArenaWins, Server: f.Server, Player: f.Challenger,
			Fields: broadcast.Fields{KeepWinTimes: challengerStreak}})
	}
	return messages
}
