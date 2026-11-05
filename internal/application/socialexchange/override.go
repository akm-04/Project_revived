package socialexchange

import (
	"bytes"
	"encoding/json"
	"io"
	"strings"

	domain "gxb.local/backend/v2/internal/domain/socialexchange"
)

type productOverride struct {
	ID    int64          `json:"id"`
	Off   bool           `json:"off"`
	Price *int64         `json:"price,omitempty"`
	Limit *int64         `json:"limit,omitempty"`
	Items []overrideItem `json:"items,omitempty"`
}
type overrideItem struct {
	ItemID  int64 `json:"item_id"`
	ItemNum int64 `json:"item_num"`
}
type tuning struct {
	Version  int               `json:"version"`
	Revision string            `json:"revision"`
	Products []productOverride `json:"products"`
}

func decodeStrict(raw []byte, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	decoder.UseNumber()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return ErrProof
	}
	return nil
}

// Invalid operator data leaves the immutable source policy intact; SQL errors
// are handled by the caller and never converted into this fallback.
func effectiveCatalog(source domain.Catalog, productID int64, raw json.RawMessage) (domain.Catalog, bool, string) {
	var settings tuning
	if len(raw) == 0 || decodeStrict(raw, &settings) != nil || settings.Version != 1 || strings.TrimSpace(settings.Revision) == "" || len(settings.Revision) > 128 || len(settings.Products) == 0 {
		return source, false, "source"
	}
	var selected *productOverride
	seen := map[int64]bool{}
	for index := range settings.Products {
		setting := &settings.Products[index]
		if seen[setting.ID] {
			return source, false, "source"
		}
		seen[setting.ID] = true
		var product *domain.Product
		for productIndex := range source.Products {
			if source.Products[productIndex].ID == setting.ID {
				product = &source.Products[productIndex]
				break
			}
		}
		if product == nil || (setting.Price != nil && *setting.Price <= 0) || (setting.Limit != nil && (*setting.Limit < 1 || *setting.Limit > source.ExchangeLimit)) {
			return source, false, "source"
		}
		dropboxID := int64(0)
		for _, gift := range source.Gifts {
			if gift.ID == product.GiftID {
				dropboxID = gift.DropboxID
			}
		}
		allowed := map[int64]bool{}
		for _, dropbox := range source.Dropboxes {
			if dropbox.ID == dropboxID {
				for _, drop := range dropbox.Rolls {
					allowed[drop.ItemID] = true
				}
			}
		}
		itemsSeen := map[int64]bool{}
		for _, item := range setting.Items {
			if !allowed[item.ItemID] || itemsSeen[item.ItemID] || item.ItemNum <= 0 {
				return source, false, "source"
			}
			itemsSeen[item.ItemID] = true
		}
		if setting.ID == productID {
			selected = setting
		}
	}
	if selected == nil {
		return source, false, "source"
	}
	if selected.Off {
		return source, true, settings.Revision
	}
	output := source
	output.Products = append([]domain.Product(nil), source.Products...)
	output.Dropboxes = append([]domain.Dropbox(nil), source.Dropboxes...)
	dropboxID := int64(0)
	for index := range output.Products {
		if output.Products[index].ID == productID {
			if selected.Price != nil {
				output.Products[index].SellPrice = *selected.Price
			}
			for _, gift := range source.Gifts {
				if gift.ID == output.Products[index].GiftID {
					dropboxID = gift.DropboxID
				}
			}
		}
	}
	if selected.Limit != nil {
		output.ExchangeLimit = *selected.Limit
	}
	for index := range output.Dropboxes {
		if output.Dropboxes[index].ID == dropboxID {
			output.Dropboxes[index].Rolls = append([]domain.Drop(nil), source.Dropboxes[index].Rolls...)
			for dropIndex := range output.Dropboxes[index].Rolls {
				for _, item := range selected.Items {
					if output.Dropboxes[index].Rolls[dropIndex].ItemID == item.ItemID {
						output.Dropboxes[index].Rolls[dropIndex].ItemNum = item.ItemNum
					}
				}
			}
		}
	}
	if output.Validate() != nil {
		return source, false, "source"
	}
	return output, false, settings.Revision
}
