package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appsavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type savedPresetFakeService struct {
	cmd appsavedpreset.Command
	got identity.ActorContext
	out appsavedpreset.MutationResult
	err error
}

func (s *savedPresetFakeService) Replace(_ context.Context, actor identity.ActorContext, cmd appsavedpreset.Command, _ operation.Context) (appsavedpreset.MutationResult, error) {
	s.got = actor
	s.cmd = cmd
	return s.out, s.err
}

func savedPresetRequest(t *testing.T, params map[string]any) httpedge.DispatchRequest {
	t.Helper()
	now := time.Unix(100, 0).UTC()
	if params == nil {
		params = map[string]any{}
	}
	params["token"] = "bearer"
	params["region"] = int64(1)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID: 1793, ReceivedAt: now, Params: params,
		Claims:    wire.CredentialClaims{Token: "bearer", Region: 1},
		Operation: operation.Context{StartedAt: now},
	}}
}

func TestSavedPresetDispatcherPreservesPetPresenceAndReturnsCanonicalTriple(t *testing.T) {
	actor := actorForHTTP(t)
	svc := &savedPresetFakeService{out: appsavedpreset.MutationResult{Wire: appsavedpreset.WireProjection{SaveTeam: "1", SaveTeamName: "A", SavePet: "0"}}}
	d := SavedPresetDispatcher{Authority: httpAuthority{actor}, Service: svc}
	got := d.Dispatch(context.Background(), savedPresetRequest(t, map[string]any{"team_str": "1", "team_name_str": "A", "pet_str": ""}))
	if got.HTTPStatus != http.StatusOK || got.Body["save_team"] != "1" || got.Body["save_team_name"] != "A" || got.Body["save_pet"] != "0" {
		t.Fatalf("response=%+v", got)
	}
	if !svc.cmd.PetPresent || svc.cmd.PetString != "" || svc.cmd.TeamString != "1" || svc.got.PlayerID != actor.PlayerID {
		t.Fatalf("cmd=%+v actor=%+v", svc.cmd, svc.got)
	}

	svc.cmd = appsavedpreset.Command{}
	got = d.Dispatch(context.Background(), savedPresetRequest(t, map[string]any{"team_str": "", "team_name_str": ""}))
	if got.HTTPStatus != http.StatusOK || svc.cmd.PetPresent {
		t.Fatalf("legacy response=%+v cmd=%+v", got, svc.cmd)
	}
}

func TestSavedPresetDispatcherRejectsUnknownOrWrongTypedGameplayFields(t *testing.T) {
	d := SavedPresetDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &savedPresetFakeService{}}
	for _, params := range []map[string]any{
		{"team_name_str": "A", "pet_str": "0"},
		{"team_str": "1", "pet_str": "0"},
		{"team_str": int64(1), "team_name_str": "A", "pet_str": "0"},
		{"team_str": "1", "team_name_str": "A", "pet_str": nil},
		{"team_str": "1", "team_name_str": "A", "pet_str": "0", "invented": true},
	} {
		got := d.Dispatch(context.Background(), savedPresetRequest(t, params))
		if got.HTTPStatus != http.StatusBadRequest {
			t.Fatalf("params=%v got=%+v", params, got)
		}
	}
}

func TestSavedPresetDispatcherUsesLocalFailuresWithoutInventedStockErrorCode(t *testing.T) {
	cases := []struct {
		err  error
		want int
	}{
		{appsavedpreset.ErrInvalidCommand, http.StatusBadRequest},
		{characterasset.ErrReferenceNotFound, http.StatusBadRequest},
		{appsavedpreset.ErrAmbiguousLegacyDelete, http.StatusConflict},
		{appsavedpreset.ErrStaleLegacyDelete, http.StatusConflict},
		{&tx.UnknownCommitError{Cause: errors.New("ambiguous commit")}, http.StatusServiceUnavailable},
		{errors.New("infra"), http.StatusServiceUnavailable},
	}
	for _, tc := range cases {
		svc := &savedPresetFakeService{err: tc.err}
		d := SavedPresetDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
		got := d.Dispatch(context.Background(), savedPresetRequest(t, map[string]any{"team_str": "1", "team_name_str": "A", "pet_str": "0"}))
		if got.HTTPStatus != tc.want {
			t.Fatalf("err=%v got=%+v", tc.err, got)
		}
		if _, invented := got.Body["error_code"]; invented {
			t.Fatalf("invented stock error code for %v: %+v", tc.err, got.Body)
		}
	}
}
