package memoir

import (
	"errors"
	"strconv"
)

// Tuning is the D476 operator overlay (memoir_tuning, written by the I11
// operator tool): a listed (box, item) pair replaces that drop row's rate in
// the same scale as campaign.DropRows, where 10000 is one guaranteed copy.
type Tuning struct {
	Version  int64                       `json:"version"`
	BoxRates map[string]map[string]int64 `json:"box_rates"`
}

const tuningRateScale = 10000

// maxTuningRate keeps a typo from flooding backpacks; 10 x the scale is ten
// guaranteed copies of one row.
const maxTuningRate = 10 * tuningRateScale

var errTuning = errors.New("memoir: operator tuning")

// Tune returns the catalog with the overlay applied. Any rejected entry leaves
// the source catalog in force for the caller to report.
func (catalog Catalog) Tune(tuning Tuning) (Catalog, error) {
	if len(tuning.BoxRates) == 0 {
		return catalog, nil
	}
	boxes := make([]Box, len(catalog.Boxes))
	copy(boxes, catalog.Boxes)
	copied := make([]bool, len(boxes))
	for rawBox, rates := range tuning.BoxRates {
		box, found := indexBox(boxes, rawBox)
		if !found {
			return catalog, errTuning
		}
		for rawItem, rate := range rates {
			index, found := indexDrop(boxes[box].Rows, rawItem)
			if !found || rate < 0 || rate > maxTuningRate {
				return catalog, errTuning
			}
			if !copied[box] {
				boxes[box].Rows = append([]Drop(nil), boxes[box].Rows...)
				copied[box] = true
			}
			boxes[box].Rows[index].Rate = rate
		}
	}
	applied := catalog
	applied.Boxes = boxes
	return applied, nil
}

func indexBox(boxes []Box, raw string) (int, bool) {
	identifier, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || identifier <= 0 {
		return 0, false
	}
	for index, box := range boxes {
		if box.ID == identifier {
			return index, true
		}
	}
	return 0, false
}

func indexDrop(rows []Drop, raw string) (int, bool) {
	identifier, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || identifier <= 0 {
		return 0, false
	}
	for index, row := range rows {
		if row.Item == identifier {
			return index, true
		}
	}
	return 0, false
}
