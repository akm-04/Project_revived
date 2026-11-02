package workplace

import (
	"math"
	"testing"
)

func quoteFixture() (Location, Job, []Worker, Formula) {
	location := Location{ID: 1, Jobs: []int64{1001, 1002}, MaxMembers: 21, BaseTime: 36000, BaseIce: 10, ChestRate: 20, EnemyRate: 20}
	job := Job{ID: 1002, Product: 2}
	workers := []Worker{{PartnerID: 1, BaseID: 11001, Level: 14, Star: 1, Color: 1, Trait: 1}}
	formula := Formula{Base: 96000, PerGirl: 18000, Color: 1500, Star: 2800, Level: 130, Products: map[int64]Rate{1: {1, 1}, 2: {3, 25000}, 3: {1, 100000}}, TraitAmounts: map[int64]int64{1: 1, 2: 3, 3: 1800, 4: 5}}
	return location, job, workers, formula
}

func TestStockQuoteFloorsAndCrewTraits(t *testing.T) {
	location, job, workers, formula := quoteFixture()
	quote, err := Calculate(location, job, workers, Rate{3, 2}, formula)
	if err != nil || quote.BaseReward != 180180 || quote.Quantity != 21 || quote.SP != 9 || quote.Seconds != 36000 {
		t.Fatalf("single crew VIP preview %+v %v", quote, err)
	}
	for trait := int64(2); trait <= 4; trait++ {
		workers = append(workers, Worker{PartnerID: trait, BaseID: 11000 + trait, Level: 14, Star: 1, Color: 1, Trait: trait})
	}
	quote, err = Calculate(location, job, workers, Rate{1, 1}, formula)
	if err != nil || quote.BaseReward != 192480 || quote.Quantity != 23 || quote.SP != 9 || quote.Seconds != 34200 || quote.ChestPercent != 23 || quote.RivalPercent != 25 || quote.TotalLevel != 56 || quote.TotalStar != 4 || quote.TotalColor != 4 {
		t.Fatalf("crew traits %+v %v", quote, err)
	}
	location.ChestRate, location.EnemyRate = 0, 0
	quote, err = Calculate(location, job, workers, Rate{1, 1}, formula)
	if err != nil || quote.ChestPercent != 0 || quote.RivalPercent != 0 {
		t.Fatalf("factory zero event rates changed %+v %v", quote, err)
	}
}

func TestQuoteRejectsIdentityConfusionInvalidMathAndOverflow(t *testing.T) {
	for _, name := range []string{"duplicate owned ID", "duplicate base alias", "wrong district", "zero divisor", "overflow", "negative duration", "unsupported product"} {
		t.Run(name, func(t *testing.T) {
			location, job, workers, formula := quoteFixture()
			vip := Rate{1, 1}
			switch name {
			case "duplicate owned ID":
				workers = append(workers, Worker{PartnerID: 1, BaseID: 11002, Level: 14, Star: 1})
			case "duplicate base alias":
				workers = append(workers, Worker{PartnerID: 2, BaseID: 11001, Level: 14, Star: 1})
			case "wrong district":
				job.ID = 6001
			case "zero divisor":
				vip.Denominator = 0
			case "overflow":
				workers[0].Level = math.MaxInt64
			case "negative duration":
				workers[0].Trait = 3
				location.BaseTime = 1
			case "unsupported product":
				job.Product = 10
			}
			if _, err := Calculate(location, job, workers, vip, formula); err != ErrInvalid {
				t.Fatalf("invalid input accepted: %v", err)
			}
		})
	}
}
