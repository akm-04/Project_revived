package compat

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	i5 "gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type overlayStore struct {
	preferences d.Preferences
	found       bool
}

func (s overlayStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Preferences, bool, error) {
	return s.preferences, s.found, nil
}

func (overlayStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Preferences, error) {
	return d.Preferences{}, nil
}

func (overlayStore) SaveTx(context.Context, tx.Tx, identity.PlayerID, d.Preferences, int64, time.Time) error {
	return nil
}

func TestBootstrapClaimsDoNotCollideWithI5(t *testing.T) {
	contributors := []appboot.MID1DetailContributor{
		BootstrapProjection{Store: overlayStore{}},
		i5.MissionBootstrap{},
		i5store.BootstrapProjection{},
	}
	if err := appboot.ValidateDetailContributors(contributors); err != nil {
		t.Fatal(err)
	}
}

func TestBootstrapProjectsTheStoredArrayAndMarker(t *testing.T) {
	detail := map[string]any{"17": map[string]any{"first_main_touch": int64(0), "message_pushes": map[string]any{}}}
	projection := BootstrapProjection{Store: overlayStore{preferences: d.Preferences{FirstMainTouch: 1, MessagePushIDs: []int64{2, 9}}}}
	if err := projection.OverlayMID1(context.Background(), nil, identity.ActorContext{PlayerID: 100001}, false, time.Unix(1, 0), detail); err != nil {
		t.Fatal(err)
	}
	record := detail["17"].(map[string]any)
	want := map[string]any{"first_main_touch": int64(1), "message_pushes": []int64{2, 9}}
	if !reflect.DeepEqual(record, want) {
		t.Fatalf("MID 1 record = %#v, want %#v", record, want)
	}
}

func TestBootstrapProjectsEmptyArrayWithoutARow(t *testing.T) {
	detail := map[string]any{"17": map[string]any{}}
	if err := (BootstrapProjection{Store: overlayStore{}}).OverlayMID1(context.Background(), nil, identity.ActorContext{PlayerID: 100001}, false, time.Unix(1, 0), detail); err != nil {
		t.Fatal(err)
	}
	record := detail["17"].(map[string]any)
	if record["first_main_touch"] != int64(0) {
		t.Fatalf("first_main_touch = %#v", record["first_main_touch"])
	}
	if pushes, ok := record["message_pushes"].([]int64); !ok || pushes == nil || len(pushes) != 0 {
		t.Fatalf("message_pushes = %#v, want a non-nil empty []int64", record["message_pushes"])
	}
}
