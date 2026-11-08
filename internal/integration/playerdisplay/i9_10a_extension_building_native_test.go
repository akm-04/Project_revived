//go:build postgres

package playerdisplay_test

import (
	"strings"
	"testing"

	app "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
)

func finishBuilding(t *testing.T, service app.Service, actor identity.ActorContext, buildingType int64) {
	t.Helper()
	bookCmd(t, service, actor, app.Command{Family: app.Start, Type: buildingType})
	bookCmd(t, service, actor, app.Command{Family: app.Speed, Type: buildingType})
	bookCmd(t, service, actor, app.Command{Family: app.Confirm, Type: buildingType})
}

func TestI910AExtensionBuildingLazyLevelOneNative(t *testing.T) {
	database := pool(t)
	actor, revision, service := bookFixture(t, database)

	finishBuilding(t, service, actor, 1)

	root := bookRoot(t, database, actor)
	if _, exists := root.Facts.Buildings[2]; exists {
		t.Fatal("type 2 existed before its first start")
	}

	beforeVersion := root.Version
	failedOperation := op()
	failedOperation.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if _, err := service.Command(ctx, actor, app.Command{Family: app.Start, Type: 7}, failedOperation); err == nil {
		t.Fatal("type 7 started while its type 2 dependency was level 1")
	}
	root = bookRoot(t, database, actor)
	if _, exists := root.Facts.Buildings[7]; exists || root.Version != beforeVersion {
		t.Fatal("failed validated start persisted a level one row")
	}

	started := bookCmd(t, service, actor, app.Command{Family: app.Start, Type: 2})
	if started.Body["type"] != int64(2) || started.Body["lev"] != int64(1) || started.Body["need_time"] != int64(43200) {
		t.Fatalf("type 2 start wire: %+v", started.Body)
	}
	root = bookRoot(t, database, actor)
	building := root.Facts.Buildings[2]
	if building.Level != 1 || building.CatalogRevision != revision || building.Job == nil || building.Job.Target != 2 || building.Job.Revision != revision {
		t.Fatalf("persisted type 2 row: %+v", building)
	}

	list, err := service.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	buildings := list["building_list"].(map[string]any)
	if buildings["2"].(map[string]any)["lev"] != int64(1) {
		t.Fatalf("1056 building list: %+v", buildings["2"])
	}

	bookCmd(t, service, actor, app.Command{Family: app.Cancel, Type: 2})
	root = bookRoot(t, database, actor)
	building = root.Facts.Buildings[2]
	if building.Level != 1 || building.Job != nil || building.CatalogRevision != revision {
		t.Fatalf("cancel changed the level one pin: %+v", building)
	}

	for _, buildingType := range []int64{5, 6} {
		started = bookCmd(t, service, actor, app.Command{Family: app.Start, Type: buildingType})
		if started.Body["lev"] != int64(1) || started.Body["type"] != buildingType {
			t.Fatalf("type %d start wire: %+v", buildingType, started.Body)
		}
	}
	root = bookRoot(t, database, actor)
	for _, buildingType := range []int64{5, 6} {
		if root.Facts.Buildings[buildingType].Level != 1 || root.Facts.Buildings[buildingType].CatalogRevision != revision {
			t.Fatalf("persisted type %d row: %+v", buildingType, root.Facts.Buildings[buildingType])
		}
	}

	finishBuilding(t, service, actor, 2)
	started = bookCmd(t, service, actor, app.Command{Family: app.Start, Type: 7})
	if started.Body["lev"] != int64(1) || started.Body["type"] != int64(7) {
		t.Fatalf("type 7 start wire: %+v", started.Body)
	}
	root = bookRoot(t, database, actor)
	if root.Facts.Buildings[7].Level != 1 || root.Facts.Buildings[7].CatalogRevision != revision || len(root.Facts.Buildings) != 7 {
		t.Fatalf("persisted type 7 row or building count: %+v", root.Facts)
	}
}

func TestI910AExtensionBuildingStartRejectsMissingContentRevisionNative(t *testing.T) {
	database := pool(t)
	actor, _, service := bookFixture(t, database)
	finishBuilding(t, service, actor, 1)
	invalid := op()
	invalid.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("f", 64)})
	if _, err := service.Command(ctx, actor, app.Command{Family: app.Start, Type: 2}, invalid); err == nil {
		t.Fatal("start used an unregistered content revision")
	}
	root := bookRoot(t, database, actor)
	if _, exists := root.Facts.Buildings[2]; exists {
		t.Fatal("unregistered revision persisted a level one row")
	}
}
