package objective

import (
	"strings"
	"testing"
	"time"
)

func TestSignCalendarDailyBonusAndMonth(t *testing.T) {
	at := time.Date(2026, 10, 31, 20, 59, 59, 0, time.UTC)
	rev := strings.Repeat("a", 64)
	root := SignRoot{StateVersion: 1}
	root, err := root.Refresh(at, rev)
	if err != nil {
		t.Fatal(err)
	}
	m := SignMonth{Month: 10, Awards: []SignAward{{ItemID: 50001003, ItemNum: 1, DoubleVIP: 2}}}
	first, a, key, err := root.Claim(m, 0)
	if err != nil || first.Count != 1 || first.Signed != 1 || a.ItemNum != 1 || key == "" {
		t.Fatal(first, err)
	}
	if _, _, _, err = first.Claim(m, 1); err != ErrSignRefused {
		t.Fatal("low VIP", err)
	}
	bonus, _, key2, err := first.Claim(m, 2)
	if err != nil || bonus.Count != 1 || bonus.Signed != 2 || key == key2 {
		t.Fatal(bonus, err)
	}
	if _, _, _, err = bonus.Claim(m, 15); err != ErrSignRefused {
		t.Fatal("third claim", err)
	}
	same, err := bonus.Refresh(at, strings.Repeat("b", 64))
	if err != nil || same.ContentRevision != rev {
		t.Fatal("month pin", same, err)
	}
	next, err := bonus.Refresh(at.Add(time.Second), strings.Repeat("b", 64))
	if err != nil || next.Month != 202611 || next.Count != 0 || next.Signed != 0 {
		t.Fatal("F7 month reset", next, err)
	}
	if _, err = next.Refresh(at, rev); err != ErrSignRefused {
		t.Fatal("clock rollback", err)
	}
}
func TestSignNoBonusAndFiniteCalendar(t *testing.T) {
	root := SignRoot{Month: 202602, Day: 1, ContentRevision: strings.Repeat("a", 64), StateVersion: 1}
	m := SignMonth{Month: 2, Awards: []SignAward{{Crystal: 40, DoubleVIP: -1}}}
	next, _, _, err := root.Claim(m, 15)
	if err != nil || next.Signed != 2 {
		t.Fatal(next, err)
	}
	next.Day++
	next.Signed = 0
	if _, _, _, err = next.Claim(m, 15); err != ErrSignRefused {
		t.Fatal("catalog exhausted", err)
	}
}
