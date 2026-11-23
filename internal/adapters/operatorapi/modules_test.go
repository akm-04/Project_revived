package operatorapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"testing"

	appevents "gxb.local/backend/v2/internal/application/events"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	apppublication "gxb.local/backend/v2/internal/application/publication"
)

func TestModulesRouteServesTheRegistry(t *testing.T) {
	handler := Handler{Token: "secret", Modules: []operator.Module{
		{ID: "ota", Title: "OTA", Commands: []operator.CommandSpec{{Name: "ota.publish", Class: operator.ClassMaintenance}}},
		{ID: "mail", Title: "Mail", Planned: "O3"},
	}}
	if recorder := get(t, handler, "", "/operator/v1/modules"); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized modules: %d", recorder.Code)
	}
	recorder := get(t, handler, "secret", "/operator/v1/modules")
	if recorder.Code != http.StatusOK {
		t.Fatalf("modules: %d %s", recorder.Code, recorder.Body)
	}
	var reply struct {
		Modules []operator.Module `json:"modules"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &reply); err != nil {
		t.Fatal(err)
	}
	if len(reply.Modules) != 2 || reply.Modules[0].Commands[0].Handler != nil || reply.Modules[1].Planned != "O3" {
		t.Fatalf("modules = %+v", reply.Modules)
	}
}

func TestEveryReadWithARequirementRefusesEmptyQuery(t *testing.T) {
	modules := []operator.Module{
		bindReads(t, appota.Commands{}.Module(), map[string]operator.ReadHandler{
			"ota.status":  OTAStatus(fakeStatusService{}),
			"ota.release": OTARelease(fakeReleaseService{}),
		}),
		bindReads(t, appevents.Commands{}.Module(), map[string]operator.ReadHandler{
			"events.list": EventsList(fakeEventsList{}),
		}),
		bindReads(t, operatorcatalog.Module(), map[string]operator.ReadHandler{
			"catalog.search": CatalogSearch(operatorcatalog.Document{}),
		}),
		bindReads(t, operator.PlayerModule(), map[string]operator.ReadHandler{
			"player.find":    PlayerFind(fakePlayerReads{}),
			"player.summary": PlayerSummary(fakePlayerReads{}),
		}),
		bindReads(t, operator.OperatorModule(), map[string]operator.ReadHandler{
			"operator.audit.list": AuditList(&fakeAuditService{}),
			"operator.bulk.show":  BulkShow(fakeBulkShow{}),
		}),
		bindReads(t, operator.ServerModule(), map[string]operator.ReadHandler{
			"server.list": ServerList(fakeServerList{}),
		}),
		bindReads(t, appidentity.LogoutCommands{}.Module(), map[string]operator.ReadHandler{
			"session.online": SessionOnline(fakeSessionOnline{}),
		}),
		bindReads(t, apppublication.OperatorCommands{}.Module(), map[string]operator.ReadHandler{
			"publication.show": PublicationShow(fakePublicationShow{}),
		}),
	}
	// The adapter itself refuses these when the declared required input is
	// missing. player.find validates in the application service; its test
	// lives with PlayerReadService.
	enforced := map[string]bool{"ota.release": true, "player.summary": true, "operator.bulk.show": true}
	for _, module := range modules {
		for _, read := range module.Reads {
			_, err := read.Handler(context.Background(), url.Values{})
			if !enforced[read.Name] {
				if err != nil {
					t.Fatalf("%s with no required input refused an empty query: %v", read.Name, err)
				}
				continue
			}
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) {
				t.Fatalf("%s did not refuse an empty query: %v", read.Name, err)
			}
		}
	}
}

func TestEventsListAcceptsTheGlobalViewAndRefusesABadServer(t *testing.T) {
	handler := EventsList(fakeEventsList{})
	if _, err := handler(context.Background(), url.Values{}); err != nil {
		t.Fatalf("an empty query asks for the global view (EA-15 item 5): %v", err)
	}
	for _, server := range []string{"0", "-1", "abc"} {
		if _, err := handler(context.Background(), url.Values{"server": []string{server}}); err == nil {
			t.Fatalf("server %q must be refused", server)
		}
	}
}

func bindReads(t *testing.T, module operator.Module, handlers map[string]operator.ReadHandler) operator.Module {
	t.Helper()
	bound, err := module.BindReads(handlers)
	if err != nil {
		t.Fatal(err)
	}
	return bound
}

type fakeReleaseService struct{}

func (fakeReleaseService) Exists(context.Context, string) (appota.ReleaseExistence, error) {
	return appota.ReleaseExistence{}, nil
}

type fakeBulkShow struct{}

func (fakeBulkShow) Show(context.Context, string) (operatorgrant.BulkProgress, error) {
	return operatorgrant.BulkProgress{}, nil
}

type fakePlayerReads struct{}

func (fakePlayerReads) Find(context.Context, playerdirectory.OperatorFind) (operator.PlayerFindPage, error) {
	return operator.PlayerFindPage{}, nil
}

func (fakePlayerReads) Summary(context.Context, int64) (operator.PlayerSummary, error) {
	return operator.PlayerSummary{}, nil
}

type fakeEventsList struct{}

func (fakeEventsList) List(context.Context, appevents.OccurrenceFilter) (appevents.OccurrencePage, error) {
	return appevents.OccurrencePage{}, nil
}

type fakeServerList struct{}

func (fakeServerList) List(context.Context) (operator.ServerListPage, error) {
	return operator.ServerListPage{}, nil
}

type fakeSessionOnline struct{}

func (fakeSessionOnline) Online(context.Context, operator.OnlineSessionFilter) (operator.OnlineSessionPage, error) {
	return operator.OnlineSessionPage{}, nil
}

type fakePublicationShow struct{}

func (fakePublicationShow) Show(context.Context, string, int64) (apppublication.ShowReply, error) {
	return apppublication.ShowReply{}, nil
}
