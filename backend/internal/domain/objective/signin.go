package objective

import (
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/modes"
	"time"
)

var ErrSignRefused = errors.New("sign-in refused")

// SignAward keeps the stock calendar wire fields, including its negative sentinels.
type SignAward struct {
	ItemID    int64 `json:"award_item_id"`
	ItemNum   int64 `json:"award_item_num"`
	Crystal   int64 `json:"award_crystal"`
	DoubleVIP int64 `json:"double_vip_lv"`
}
type SignMonth struct {
	SourceYear int64       `json:"source_year"`
	Month      int64       `json:"month"`
	PartnerID  int64       `json:"partner_id"`
	IsSkin     int64       `json:"is_skin"`
	Awards     []SignAward `json:"awards"`
}
type SignCatalog struct {
	Months []SignMonth `json:"months"`
}

func (c SignCatalog) Validate() error {
	if len(c.Months) != 12 {
		return errors.New("sign-in calendar requires twelve months")
	}
	for i, m := range c.Months {
		if m.Month != int64(i+1) || m.SourceYear < 2015 || m.PartnerID <= 0 || (m.IsSkin != 0 && m.IsSkin != 1) || len(m.Awards) < 28 || len(m.Awards) > 31 {
			return errors.New("invalid sign-in month")
		}
		for _, a := range m.Awards {
			if a.DoubleVIP < -1 || a.DoubleVIP > 15 || (a.ItemID > 0) == (a.Crystal > 0) || a.ItemID > 0 && a.ItemNum <= 0 {
				return errors.New("invalid sign-in reward")
			}
		}
	}
	return nil
}
func (c SignCatalog) Month(month int64) (SignMonth, error) {
	if err := c.Validate(); err != nil {
		return SignMonth{}, err
	}
	if month < 1 || month > 12 {
		return SignMonth{}, ErrSignRefused
	}
	return c.Months[month-1], nil
}

type SignRoot struct {
	Month           int64
	Day             int64
	Count           int64
	Signed          int64
	ContentRevision string
	StateVersion    int64
}

func SignMonthAt(at time.Time) int64 {
	// The calendar date belongs to the F7 day beginning at05:00 GMT+8.
	date := modes.DayBegins(modes.Day(at)).Add(8 * time.Hour)
	return int64(date.Year()*100 + int(date.Month()))
}
func (s SignRoot) Refresh(at time.Time, revision string) (SignRoot, error) {
	if at.IsZero() || len(revision) != 64 || s.Day > modes.Day(at) {
		return s, ErrSignRefused
	}
	if s.Month != SignMonthAt(at) {
		s.Month = SignMonthAt(at)
		s.Count = 0
		s.Signed = 0
		s.ContentRevision = revision
	}
	if s.Day != modes.Day(at) {
		s.Day = modes.Day(at)
		s.Signed = 0
	}
	return s, s.Validate()
}
func (s SignRoot) Validate() error {
	if s.Month < 197001 || s.Month%100 < 1 || s.Month%100 > 12 || s.Count < 0 || s.Count > 31 || s.Signed < 0 || s.Signed > 2 || s.Signed > 0 && s.Count == 0 || len(s.ContentRevision) != 64 || s.StateVersion < 1 {
		return errors.New("invalid sign-in root")
	}
	return nil
}
func (s SignRoot) Claim(m SignMonth, vip int64) (SignRoot, SignAward, string, error) {
	if s.Validate() != nil || m.Month != s.Month%100 || vip < 0 || vip > 15 {
		return s, SignAward{}, "", ErrSignRefused
	}
	next := s
	slot := "first"
	index := s.Count
	if s.Signed == 1 {
		slot = "bonus"
		index--
	} else if s.Signed != 0 {
		return s, SignAward{}, "", ErrSignRefused
	}
	if index < 0 || index >= int64(len(m.Awards)) {
		return s, SignAward{}, "", ErrSignRefused
	}
	a := m.Awards[index]
	if slot == "bonus" {
		if a.DoubleVIP < 0 || vip < a.DoubleVIP {
			return s, SignAward{}, "", ErrSignRefused
		}
		next.Signed = 2
	} else {
		next.Count++
		next.Signed = 1
		if a.DoubleVIP < 0 {
			next.Signed = 2
		}
	}
	next.StateVersion++
	return next, a, fmt.Sprintf("%d:%s", s.Day, slot), nil
}
