package agentapi

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type fakeModuleLister struct {
	list operatoragent.AgentModules
}

func (lister fakeModuleLister) List(context.Context) operatoragent.AgentModules { return lister.list }

func TestModulesRouteNeedsTheSessionAndServesTheMergedList(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	handler.Modules = fakeModuleLister{list: operatoragent.AgentModules{Modules: []operator.Module{
		{ID: "ota", Title: "OTA", Commands: []operator.CommandSpec{{Name: "ota.build", Class: operator.ClassLive, Route: operator.RouteAgent}}},
		{ID: "server", Title: "Server", Commands: []operator.CommandSpec{{Name: "server.status", Class: operator.ClassLive, Route: operator.RouteAgent}}},
	}}}
	if recorder := serveAgent(handler, http.MethodGet, "/agent/v1/modules", "", ""); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized modules: %d %s", recorder.Code, recorder.Body)
	}
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/modules", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("modules: %d %s", recorder.Code, recorder.Body)
	}
	var reply operatoragent.AgentModules
	if err := json.Unmarshal(recorder.Body.Bytes(), &reply); err != nil {
		t.Fatal(err)
	}
	if len(reply.Modules) != 2 || reply.Modules[0].ID != "ota" || reply.Modules[1].ID != "server" {
		t.Fatalf("modules = %+v", reply.Modules)
	}
	if reply.Modules[0].Commands[0].Route != operator.RouteAgent {
		t.Fatalf("the agent route was lost: %+v", reply.Modules[0].Commands[0])
	}
}
