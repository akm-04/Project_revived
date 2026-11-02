package dodgeball

import (
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
)

type HitRecord struct {
	Throw                 int64 `json:"rate_id"`
	Occurrence            int64 `json:"id"`
	ProbabilityBuff       bool  `json:"is_buff1"`
	FriendProbabilityBuff bool  `json:"is_buff2"`
	Hits                  int64 `json:"ball_num"`
}

type Evaluation struct {
	Derivation   combat.Derivation
	ActorAwards  []grant.Line
	FriendAwards []grant.Line
}

func (catalog Catalog) Evaluate(board Board, marked int64, records []HitRecord, draws combat.DrawPackage, friendEnabled bool) (Evaluation, error) {
	rejected := Evaluation{}
	if catalog.Validate() != nil || !catalog.DrawPolicy().Issued(draws) {
		return rejected, ErrUnavailable
	}
	selected := false
	for _, identifier := range board.Marked {
		if identifier == marked {
			selected = true
		}
	}
	if !selected || len(board.Monsters) != 25 || len(records) > len(board.Monsters) {
		return rejected, ErrRefused
	}
	buffs := map[int64]bool{}
	availableBalls := catalog.InitialBalls
	for _, buff := range board.Buffs {
		buffs[buff.ID] = true
		if buff.ID == AdditionalBallsBuff {
			availableBalls += catalog.BuffEffect(AdditionalBallsBuff)
		}
	}
	evaluation := Evaluation{Derivation: combat.Derivation{Claims: []combat.DrawClaim{}}, ActorAwards: []grant.Line{}, FriendAwards: []grant.Line{}}
	occurrences := map[int64]bool{}
	hitsByThrow := map[int64]int64{}
	friendFired := map[int64]bool{}
	friendBuffByThrow := map[int64]bool{}
	seenThrows := map[int64]bool{}
	highestThrow := int64(0)
	for _, record := range records {
		if record.Throw < 1 || record.Throw > int64(len(draws.Streams["self"])) || record.Throw > int64(len(draws.Streams["friend"])) || record.Occurrence < 1 || record.Occurrence > int64(len(board.Monsters)) || occurrences[record.Occurrence] || record.Hits < 1 {
			return rejected, ErrRefused
		}
		if record.ProbabilityBuff && !buffs[ProbabilityBuff] {
			return rejected, ErrRefused
		}
		if record.FriendProbabilityBuff && (!friendEnabled || !buffs[FriendProbabilityBuff]) {
			return rejected, ErrRefused
		}
		if seenThrows[record.Throw] && friendBuffByThrow[record.Throw] != record.FriendProbabilityBuff {
			return rejected, ErrRefused
		}
		seenThrows[record.Throw] = true
		friendBuffByThrow[record.Throw] = record.FriendProbabilityBuff
		chance := catalog.FriendProbability
		if record.FriendProbabilityBuff {
			chance += catalog.BuffEffect(FriendProbabilityBuff)
		}
		qualifies := friendEnabled && draws.Streams["friend"][record.Throw-1] <= chance
		maximumHits := int64(MaximumSelfBalls)
		if qualifies {
			maximumHits += catalog.FriendBalls
		}
		if record.Hits > maximumHits || hitsByThrow[record.Throw] > maximumHits-record.Hits {
			return rejected, ErrRefused
		}
		hitsByThrow[record.Throw] += record.Hits
		if record.Throw > highestThrow {
			highestThrow = record.Throw
		}
		target, found := catalog.Target(board.Monsters[record.Occurrence-1])
		if !found || target.Group == 5 {
			return rejected, ErrUnavailable
		}
		probability := target.Probability
		if record.ProbabilityBuff {
			probability += catalog.BuffEffect(ProbabilityBuff)
		}
		probability *= record.Hits
		if probability > combat.PermilleScale {
			probability = combat.PermilleScale
		}
		evaluation.Derivation.Claims = append(evaluation.Derivation.Claims, combat.DrawClaim{Stream: "self", Index: int(record.Throw), Target: int(record.Occurrence), Permille: probability})
		amount := target.Amount
		if target.ID == marked {
			amount *= catalog.MarkedMultiplier
		}
		award := grant.Line{Kind: grant.StackItem, ItemID: target.ItemID, Amount: amount}
		evaluation.ActorAwards = append(evaluation.ActorAwards, award)
		if qualifies {
			evaluation.FriendAwards = append(evaluation.FriendAwards, award)
			if !friendFired[record.Throw] {
				evaluation.Derivation.Claims = append(evaluation.Derivation.Claims, combat.DrawClaim{Stream: "friend", Index: int(record.Throw), Permille: chance})
				friendFired[record.Throw] = true
			}
		}
		occurrences[record.Occurrence] = true
	}
	minimumSpent := highestThrow
	for throw, hits := range hitsByThrow {
		if friendFired[throw] {
			hits -= catalog.FriendBalls
		}
		if hits > 1 {
			minimumSpent += hits - 1
		}
	}
	if minimumSpent > availableBalls {
		return rejected, ErrRefused
	}
	return evaluation, nil
}
