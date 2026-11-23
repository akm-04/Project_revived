package operator

import (
	"context"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeServerRenamer struct {
	result   ServerRename
	err      error
	serverID int64
	name     string
}

func (fake *fakeServerRenamer) RenameServerTx(_ context.Context, _ tx.Tx, serverID int64, name string) (ServerRename, error) {
	fake.serverID = serverID
	fake.name = name
	return fake.result, fake.err
}

func callServerRename(t *testing.T, renamer ServerRenamer, payload string) (any, error) {
	t.Helper()
	return ServerRenameHandler(renamer)(context.Background(), tx.Scope{Tx: inventoryTx{}}, Command{Payload: []byte(payload)})
}

func TestServerRenameHandlerRenamesInsideTheTransaction(t *testing.T) {
	renamer := &fakeServerRenamer{result: ServerRename{ServerID: 2, OldName: "Server 2", NewName: "Sakura"}}
	result, err := callServerRename(t, renamer, `{"server_id":2,"name":" Sakura "}`)
	if err != nil {
		t.Fatal(err)
	}
	if renamer.serverID != 2 || renamer.name != "Sakura" {
		t.Fatalf("owner saw %d/%q", renamer.serverID, renamer.name)
	}
	rename, ok := result.(ServerRename)
	if !ok || rename.OldName != "Server 2" || rename.NewName != "Sakura" {
		t.Fatalf("result = %+v", result)
	}
}

func TestServerRenameHandlerRefusesBadPayloads(t *testing.T) {
	cases := map[string]string{
		"missing name":  `{"server_id":1}`,
		"blank name":    `{"server_id":1,"name":"   "}`,
		"control char":  `{"server_id":1,"name":"a\nb"}`,
		"too long":      `{"server_id":1,"name":"abcdefghijklmnopq"}`,
		"wide too long": `{"server_id":1,"name":"一二三四五六七八九"}`,
		"zero id":       `{"server_id":0,"name":"Alpha"}`,
		"unknown field": `{"server_id":1,"name":"Alpha","extra":1}`,
		"not an object": `[]`,
	}
	for name, payload := range cases {
		t.Run(name, func(t *testing.T) {
			renamer := &fakeServerRenamer{}
			_, err := callServerRename(t, renamer, payload)
			var refusal *Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodePayloadInvalid {
				t.Fatalf("payload %s: err = %v", payload, err)
			}
			if renamer.serverID != 0 {
				t.Fatal("the owner was called for a refused payload")
			}
		})
	}
}

func TestServerRenameHandlerMapsAMissingServer(t *testing.T) {
	_, err := callServerRename(t, &fakeServerRenamer{err: ErrServerNotFound}, `{"server_id":9,"name":"Alpha"}`)
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeServerNotFound {
		t.Fatalf("err = %v", err)
	}
}

func TestServerModuleDeclaresRename(t *testing.T) {
	module := ServerModule()
	index := commandIndex(module.Commands, "server.rename")
	if index < 0 {
		t.Fatalf("server.rename is not declared: %+v", module.Commands)
	}
	command := module.Commands[index]
	if command.Class != ClassLive || len(command.Fields) != 2 {
		t.Fatalf("server.rename = %+v", command)
	}
	if command.Fields[0].Name != "server_id" || !command.Fields[0].Required || command.Fields[1].Name != "name" || !command.Fields[1].Required {
		t.Fatalf("server.rename fields = %+v", command.Fields)
	}
}

func TestNormalizeServerNameUsesTheClientLabelBudget(t *testing.T) {
	accepted := map[string]string{
		"ascii":   "Server One",
		"sixteen": "abcdefghijklmnop",
		"wide":    "一二三四五六七八",
		"padded":  "  Alpha  ",
	}
	for name, value := range accepted {
		t.Run(name, func(t *testing.T) {
			got, err := NormalizeServerName(value)
			if err != nil {
				t.Fatalf("%q: %v", value, err)
			}
			if strings.TrimSpace(got) != got || got == "" {
				t.Fatalf("normalized %q", got)
			}
		})
	}
	for name, value := range map[string]string{
		"seventeen": "abcdefghijklmnopq",
		"nine wide": "一二三四五六七八九",
		"empty":     " ",
		"newline":   "a\nb",
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := NormalizeServerName(value); err == nil {
				t.Fatalf("%q was accepted", value)
			}
		})
	}
}
