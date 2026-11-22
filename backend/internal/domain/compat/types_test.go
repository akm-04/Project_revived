package compat

import (
	"errors"
	"slices"
	"testing"
)

func TestPreferencesTogglesAreSortedAndIdempotent(t *testing.T) {
	preferences := Preferences{StateVersion: 1}
	if !preferences.AddMessagePush(7) || !preferences.AddMessagePush(2) {
		t.Fatal("first add must change the set")
	}
	if preferences.AddMessagePush(7) {
		t.Fatal("repeat add must not change the set")
	}
	if !slices.Equal(preferences.Enabled(), []int64{2, 7}) {
		t.Fatalf("enabled = %v, want [2 7]", preferences.Enabled())
	}
	if !preferences.RemoveMessagePush(2) || preferences.RemoveMessagePush(2) {
		t.Fatal("remove must be idempotent")
	}
	if !slices.Equal(preferences.Enabled(), []int64{7}) {
		t.Fatalf("enabled = %v, want [7]", preferences.Enabled())
	}
}

func TestFirstMainTouchIsOneShot(t *testing.T) {
	preferences := Preferences{StateVersion: 1}
	if !preferences.MarkFirstMainTouch() || preferences.FirstMainTouch != 1 {
		t.Fatal("first touch must set the marker")
	}
	if preferences.MarkFirstMainTouch() {
		t.Fatal("second first touch must be a no-op")
	}
}

func TestPreferencesValidateRejectsWireBreakingRows(t *testing.T) {
	for _, preferences := range []Preferences{
		{FirstMainTouch: 2, StateVersion: 1},
		{FirstMainTouch: 0, StateVersion: 0},
		{FirstMainTouch: 0, StateVersion: 1, MessagePushIDs: []int64{3, 2}},
		{FirstMainTouch: 0, StateVersion: 1, MessagePushIDs: []int64{0}},
	} {
		if !errors.Is(preferences.Validate(), ErrUnavailable) {
			t.Fatalf("preferences %+v must be rejected", preferences)
		}
	}
}

func TestPreferencesNormalizeOrdersAndDeduplicatesRestoredRows(t *testing.T) {
	preferences := Preferences{StateVersion: 1, MessagePushIDs: []int64{9, 1, 9}}
	preferences.Normalize()
	if !slices.Equal(preferences.MessagePushIDs, []int64{1, 9}) {
		t.Fatalf("normalized ids = %v, want [1 9]", preferences.MessagePushIDs)
	}
	if err := preferences.Validate(); err != nil {
		t.Fatalf("normalized row rejected: %v", err)
	}
}

func TestCompatLockRank(t *testing.T) {
	if LockRank != 470 {
		t.Fatalf("compat lock rank = %d, want 470", LockRank)
	}
}

func TestEnabledIsNeverNil(t *testing.T) {
	if got := (Preferences{}).Enabled(); got == nil || len(got) != 0 {
		t.Fatalf("empty enabled = %#v, want []int64{}", got)
	}
}
