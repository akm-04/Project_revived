package librarylocal

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestDialogOpenedAndActUnlock(t *testing.T) {
	catalog := Catalog{
		Stages: []StageRule{{ID: 1, Favor: 100, ActIDs: []int64{1}}, {ID: 2, Favor: 300, ActIDs: []int64{1, 2}}},
		Acts: map[int64]ActRule{
			1: {ID: 1, Dialog: 12, Amour: 5},
			2: {ID: 2, Dialog: 13, Amour: 5},
			3: {ID: 3, Dialog: 14, Amour: 5},
			4: {ID: 4, Dialog: 0, Amour: 5},
		},
		DialogConfigs: map[int64]DialogConfigRule{
			1:  {ID: 1, Type: 1},
			2:  {ID: 2, Type: 2, OpenCondition: 100},
			3:  {ID: 3, Type: 3},
			12: {ID: 12, Type: 5},
			15: {ID: 15, Type: 5},
			17: {ID: 17, Type: 7},
		},
	}
	for _, tc := range []struct {
		id      int64
		favor   int64
		married bool
		want    bool
	}{
		{1, 0, false, true},
		{2, 99, false, false},
		{2, 100, false, true},
		{3, 0, false, false},
		{3, 0, true, true},
		{12, 99, false, false},
		{12, 100, false, true},
		{15, 2000, true, false},
		{17, 2000, true, false},
		{99, 2000, true, false},
	} {
		if got := catalog.DialogOpened(tc.id, tc.favor, tc.married); got != tc.want {
			t.Fatalf("DialogOpened(%d,%d,%v)=%v want %v", tc.id, tc.favor, tc.married, got, tc.want)
		}
	}
	ids := catalog.OpenDialogIDs(100, false)
	if len(ids) != 3 || ids[0] != 1 || ids[1] != 2 || ids[2] != 12 {
		t.Fatalf("OpenDialogIDs %v", ids)
	}
	if catalog.ActUnlocked(1, 99) || !catalog.ActUnlocked(1, 100) || catalog.ActUnlocked(2, 299) || !catalog.ActUnlocked(2, 300) || catalog.ActUnlocked(4, 2000) {
		t.Fatal("act unlock boundary")
	}
}

func TestAwardActClampsAndVersions(t *testing.T) {
	now := time.Unix(1000, 0).UTC()
	f := HeroFacts{Ref: character.HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 1}, StateVersion: 1, Favor: 1998, SeedPolicy: SeedPolicyV1, CreatedAt: now, UpdatedAt: now}
	next, changed, e := f.AwardAct(ActRule{ID: 1, Amour: 5}, now.Add(time.Second))
	if e != nil || !changed || next.Favor != FavorLimit || next.StateVersion != 2 {
		t.Fatalf("clamped award %+v changed=%v err=%v", next, changed, e)
	}
	next, changed, e = next.AwardAct(ActRule{ID: 2, Amour: 5}, now.Add(2*time.Second))
	if e != nil || changed || next.Favor != FavorLimit {
		t.Fatalf("capped award %+v changed=%v err=%v", next, changed, e)
	}
}
