package operatoragent

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

type fakeOperator struct {
	reads    map[string]BackendResponse
	commands []OperatorRequest
}

func (*fakeOperator) Version(context.Context) (operator.VersionInfo, error) {
	return operator.VersionInfo{}, errors.New("no version expected")
}

func (operator *fakeOperator) Command(_ context.Context, request OperatorRequest) (BackendResponse, error) {
	operator.commands = append(operator.commands, request)
	return BackendResponse{Status: 200, Body: []byte(`{"state":"APPLIED"}`)}, nil
}

func (operator *fakeOperator) Read(_ context.Context, name, query string) (BackendResponse, error) {
	values, _ := url.ParseQuery(query)
	key := name
	if uid := values.Get("uid"); uid != "" {
		key += "?uid=" + uid
	}
	if player := values.Get("player_id"); player != "" {
		key += "?player_id=" + player
	}
	response, found := operator.reads[key]
	if !found {
		response, found = operator.reads[name]
	}
	if !found {
		return BackendResponse{Status: 404, Body: []byte(`{"error_code":"OPERATOR_UNKNOWN_READ"}`)}, nil
	}
	return response, nil
}

func TestResolvePlayerByIdAndByName(t *testing.T) {
	operator := &fakeOperator{reads: map[string]BackendResponse{
		"player.summary": {Status: 200, Body: []byte(`{"player_id":42,"account_uid":"acct-42"}`)},
		"player.find":    {Status: 200, Body: []byte(`{"players":[{"player_id":43,"account_uid":"acct-43"}]}`)},
	}}
	service := &LogService{Operator: operator, Now: func() time.Time { return time.Unix(0, 0) }}
	uid, playerID, err := service.ResolvePlayer(context.Background(), "42")
	if err != nil || uid != "acct-42" || playerID != 42 {
		t.Fatalf("id resolve = %q %d err=%v", uid, playerID, err)
	}
	uid, playerID, err = service.ResolvePlayer(context.Background(), "Alpha")
	if err != nil || uid != "acct-43" || playerID != 43 {
		t.Fatalf("name resolve = %q %d err=%v", uid, playerID, err)
	}
}

func TestResolvePlayerRefusesUnknownAndAmbiguousNames(t *testing.T) {
	operator := &fakeOperator{reads: map[string]BackendResponse{
		"player.find": {Status: 200, Body: []byte(`{"players":[]}`)},
	}}
	service := &LogService{Operator: operator}
	_, _, err := service.ResolvePlayer(context.Background(), "Nobody")
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeLogPlayerUnknown {
		t.Fatalf("unknown name err = %v", err)
	}
	operator.reads["player.find"] = BackendResponse{Status: 200, Body: []byte(`{"players":[{"player_id":1},{"player_id":2}]}`)}
	_, _, err = service.ResolvePlayer(context.Background(), "TooMany")
	if !errors.As(err, &refusal) || refusal.Code != CodeLogPlayerAmbiguous {
		t.Fatalf("ambiguous name err = %v", err)
	}
}

func TestClientTailAndSearchForwardToTheBackendJournal(t *testing.T) {
	operator := &fakeOperator{reads: map[string]BackendResponse{
		"logs.tail":      {Status: 200, Body: []byte(`{"entries":[{"received_at":"2026-11-22T10:00:00Z","outcome":"SERVER_ERROR","mid":1}],"next_cursor":"c1"}`)},
		"player.summary": {Status: 200, Body: []byte(`{"player_id":42,"account_uid":"acct-42"}`)},
		"logs.timeline":  {Status: 200, Body: []byte(`{"entries":[{"received_at":"2026-11-22T10:00:00Z","outcome":"OK","mid":2}]}`)},
	}}
	service := &LogService{Operator: operator}
	tail, err := service.Tail(context.Background(), LogSourceClient, "", "error", 10)
	if err != nil || len(tail.Lines) != 1 || tail.NextCursor != "c1" {
		t.Fatalf("client tail = %+v err=%v", tail, err)
	}
	if tail.Lines[0].Level != "error" {
		t.Fatalf("client level = %+v", tail.Lines[0])
	}
	search, err := service.Search(context.Background(), LogSourceClient, "42", "2026-11-22T00:00:00Z", "", "", 10)
	if err != nil || len(search.Entries) != 1 {
		t.Fatalf("client search = %+v err=%v", search, err)
	}
	encoded, _ := json.Marshal(search.Entries[0])
	if string(encoded) == "" {
		t.Fatal("the timeline entry was dropped")
	}
}

func TestLogSourceAndLevelRefusals(t *testing.T) {
	service := &LogService{Directory: t.TempDir()}
	if _, err := service.Tail(context.Background(), "nope", "", "", 10); err == nil {
		t.Fatal("an unknown source was accepted")
	}
	if _, err := service.Tail(context.Background(), LogSourceTool, "", "debug", 10); err == nil {
		t.Fatal("an unknown level was accepted")
	}
	if _, err := service.Tail(context.Background(), LogSourceTool, "not-a-cursor", "", 10); err == nil {
		t.Fatal("an unknown cursor was accepted")
	}
}
