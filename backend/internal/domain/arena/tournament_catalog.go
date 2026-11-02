package arena

import "time"

type TournamentReward struct {
	Rank    int64 `json:"rank"`
	Crystal int64 `json:"crystal"`
	Mana    int64 `json:"mana"`
}

type TournamentStage struct {
	Identifier int `json:"identifier"`
	Stage      int `json:"stage"`
	Substage   int `json:"substage"`
}

type TournamentCatalog struct {
	ContractIdentifier string             `json:"contract_id"`
	PolicyIdentifier   string             `json:"policy_id"`
	Rules              TournamentRules    `json:"rules"`
	SourceDates        []string           `json:"source_dates"`
	Stages             []TournamentStage  `json:"stages"`
	Rewards            []TournamentReward `json:"rewards"`
	CasualRewards      []TournamentReward `json:"casual_rewards"`
	CasualOpenSeconds  int64              `json:"casual_open_seconds"`
	CasualCloseSeconds int64              `json:"casual_close_seconds"`
}

func (catalog TournamentCatalog) Validate() error {
	if catalog.ContractIdentifier != TournamentContractIdentifier || catalog.PolicyIdentifier != TournamentPolicyIdentifier || catalog.Rules.Validate() != nil || len(catalog.SourceDates) != 8 || len(catalog.Stages) != 10 || len(catalog.Rewards) != TournamentEntrantLimit || len(catalog.CasualRewards) != 12 || catalog.CasualOpenSeconds != 64800 || catalog.CasualCloseSeconds != 72000 {
		return ErrUnavailable
	}
	var registration time.Time
	for index, raw := range catalog.SourceDates {
		date, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			return ErrUnavailable
		}
		if index == 0 {
			registration = date
		}
		if date.Sub(registration) != time.Duration(catalog.Rules.StageOffsetsSeconds[index])*time.Second {
			return ErrUnavailable
		}
	}
	for index, reward := range catalog.Rewards {
		if reward.Rank != int64(index+1) || reward.Crystal < 0 || reward.Mana < 0 {
			return ErrUnavailable
		}
	}
	var previous int64
	for _, reward := range catalog.CasualRewards {
		if reward.Rank <= previous || reward.Crystal < 0 || reward.Mana < 0 {
			return ErrUnavailable
		}
		previous = reward.Rank
	}
	expected := [10][2]int{{1, 0}, {3, 1}, {3, 2}, {3, 3}, {4, 0}, {5, 0}, {6, 1}, {7, 1}, {7, 2}, {7, 3}}
	for index, stage := range catalog.Stages {
		if stage.Identifier != index+1 || stage.Stage != expected[index][0] || stage.Substage != expected[index][1] {
			return ErrUnavailable
		}
	}
	return nil
}

func (catalog TournamentCatalog) RewardFor(rank int64, casual bool) (TournamentReward, bool) {
	if rank <= 0 {
		return TournamentReward{}, false
	}
	rewards := catalog.Rewards
	if casual {
		rewards = catalog.CasualRewards
	}
	for _, reward := range rewards {
		if rank <= reward.Rank {
			return reward, true
		}
	}
	return TournamentReward{}, false
}
