// Package socialexchange owns the pure friendship-coin exchange plan:
// product qualification, deterministic weighted dropbox rolls and checked
// aggregation. It performs no I/O, balance debit or inventory grant.
package socialexchange

import (
	"cmp"
	"encoding/binary"
	"errors"
	"fmt"
	"math"
	"slices"

	"gxb.local/backend/v2/internal/foundation/operation"
)

var (
	ErrUnqualified    = errors.New("social exchange: unqualified input")
	ErrCount          = errors.New("social exchange: count outside source limit")
	ErrUnknownProduct = errors.New("social exchange: unknown product")
	ErrOverflow       = errors.New("social exchange: arithmetic overflow")
)

const (
	PriceCurrency = "friendship_coin"
	weightTotal   = 10000
)

type Product struct {
	ID        int64
	GiftID    int64
	SellPrice int64
}

type Drop struct {
	ID      int64
	ItemID  int64
	ItemNum int64
	Rate    int64
}

type Dropbox struct {
	ID    int64
	Rolls []Drop
}

type ExchangeGift struct {
	ID        int64
	DropboxID int64
}

type Catalog struct {
	ExchangeLimit int64
	Products      []Product
	Dropboxes     []Dropbox
	Gifts         []ExchangeGift
}

func (c Catalog) Validate() error {
	if c.ExchangeLimit <= 0 || len(c.Products) == 0 || len(c.Gifts) == 0 || len(c.Dropboxes) == 0 {
		return ErrUnqualified
	}
	products := make(map[int64]struct{}, len(c.Products))
	for _, product := range c.Products {
		if product.ID <= 0 || product.GiftID <= 0 || product.SellPrice <= 0 {
			return ErrUnqualified
		}
		if _, duplicate := products[product.ID]; duplicate {
			return ErrUnqualified
		}
		products[product.ID] = struct{}{}
	}
	gifts := make(map[int64]ExchangeGift, len(c.Gifts))
	for _, gift := range c.Gifts {
		if gift.ID <= 0 || gift.DropboxID <= 0 {
			return ErrUnqualified
		}
		if _, duplicate := gifts[gift.ID]; duplicate {
			return ErrUnqualified
		}
		gifts[gift.ID] = gift
	}
	dropboxes := make(map[int64]Dropbox, len(c.Dropboxes))
	for _, dropbox := range c.Dropboxes {
		if dropbox.ID <= 0 {
			return ErrUnqualified
		}
		if _, duplicate := dropboxes[dropbox.ID]; duplicate {
			return ErrUnqualified
		}
		if err := dropbox.validate(); err != nil {
			return err
		}
		dropboxes[dropbox.ID] = dropbox
	}
	for _, product := range c.Products {
		gift, found := gifts[product.GiftID]
		if !found {
			return ErrUnqualified
		}
		if _, found := dropboxes[gift.DropboxID]; !found {
			return ErrUnqualified
		}
	}
	return nil
}

func (d Dropbox) validate() error {
	if len(d.Rolls) == 0 {
		return ErrUnqualified
	}
	items := make(map[int64]struct{}, len(d.Rolls))
	rollIdentifiers := make(map[int64]struct{}, len(d.Rolls))
	total := int64(0)
	for _, roll := range d.Rolls {
		if roll.ID <= 0 || roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.Rate < 0 || roll.Rate > weightTotal {
			return ErrUnqualified
		}
		if _, duplicate := rollIdentifiers[roll.ID]; duplicate {
			return ErrUnqualified
		}
		rollIdentifiers[roll.ID] = struct{}{}
		if _, duplicate := items[roll.ItemID]; duplicate {
			return ErrUnqualified
		}
		items[roll.ItemID] = struct{}{}
		total += roll.Rate
	}
	if total != weightTotal {
		return ErrUnqualified
	}
	return nil
}

type ItemQuantity struct {
	ItemID  int64
	ItemNum int64
}

type Plan struct {
	ProductID     int64
	DropboxID     int64
	Count         int64
	PriceCurrency string
	UnitPrice     int64
	TotalCost     int64
	Items         []ItemQuantity
}

// BuildPlan resolves one weighted dropbox row per purchased unit. Entropy
// derives from the semantic operation and the draw ordinal, so a retried
// transaction draws the same award and each unit draws a distinct ordinal.
func BuildPlan(catalog Catalog, productID, count int64, op operation.Context) (Plan, error) {
	if err := catalog.Validate(); err != nil {
		return Plan{}, err
	}
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return Plan{}, ErrUnqualified
	}
	if count < 1 || count > catalog.ExchangeLimit {
		return Plan{}, ErrCount
	}
	product, dropbox, found := catalog.resolve(productID)
	if !found {
		return Plan{}, ErrUnknownProduct
	}
	totalCost, ok := checkedMultiply(product.SellPrice, count)
	if !ok {
		return Plan{}, ErrOverflow
	}
	items := make(map[int64]int64, len(dropbox.Rolls))
	for ordinal := range count {
		label := fmt.Sprintf("social.exchange.v1/product=%d/dropbox=%d/draw=%d", product.ID, dropbox.ID, ordinal)
		pick, err := draw(op, label, weightTotal)
		if err != nil {
			return Plan{}, err
		}
		roll, found := selectRoll(dropbox, pick)
		if !found {
			return Plan{}, ErrUnqualified
		}
		aggregated, ok := checkedAdd(items[roll.ItemID], roll.ItemNum)
		if !ok {
			return Plan{}, ErrOverflow
		}
		items[roll.ItemID] = aggregated
	}
	return Plan{
		ProductID:     product.ID,
		DropboxID:     dropbox.ID,
		Count:         count,
		PriceCurrency: PriceCurrency,
		UnitPrice:     product.SellPrice,
		TotalCost:     totalCost,
		Items:         sortedItems(items),
	}, nil
}

func (c Catalog) resolve(productID int64) (Product, Dropbox, bool) {
	for _, product := range c.Products {
		if product.ID != productID {
			continue
		}
		for _, gift := range c.Gifts {
			if gift.ID != product.GiftID {
				continue
			}
			for _, dropbox := range c.Dropboxes {
				if dropbox.ID == gift.DropboxID {
					return product, dropbox, true
				}
			}
		}
	}
	return Product{}, Dropbox{}, false
}

func selectRoll(dropbox Dropbox, pick uint64) (Drop, bool) {
	cumulative := uint64(0)
	for _, roll := range dropbox.Rolls {
		cumulative += uint64(roll.Rate)
		if pick < cumulative {
			return roll, true
		}
	}
	return Drop{}, false
}

func sortedItems(items map[int64]int64) []ItemQuantity {
	out := make([]ItemQuantity, 0, len(items))
	for itemID, itemNum := range items {
		out = append(out, ItemQuantity{ItemID: itemID, ItemNum: itemNum})
	}
	slices.SortFunc(out, func(left, right ItemQuantity) int {
		return cmp.Compare(left.ItemID, right.ItemID)
	})
	return out
}

// draw keeps the rejection-sampling shape already qualified for Course gift
// boxes. Original-server Social entropy is UNKNOWN; D495 makes this private
// policy.
func draw(op operation.Context, label string, bound uint64) (uint64, error) {
	const space = uint64(1) << 32
	if bound == 0 || bound > space {
		return 0, ErrUnqualified
	}
	limit := space - space%bound
	for round := uint64(0); ; round++ {
		block := op.Derive(fmt.Sprintf("%s/round=%d", label, round), 0)
		for index := 0; index+4 <= len(block); index += 4 {
			value := uint64(binary.BigEndian.Uint32(block[index : index+4]))
			if value < limit {
				return value % bound, nil
			}
		}
	}
}

func checkedMultiply(left, right int64) (int64, bool) {
	if left <= 0 || right <= 0 {
		return 0, false
	}
	if left > math.MaxInt64/right {
		return 0, false
	}
	return left * right, true
}

func checkedAdd(left, right int64) (int64, bool) {
	if right > math.MaxInt64-left {
		return 0, false
	}
	return left + right, true
}
