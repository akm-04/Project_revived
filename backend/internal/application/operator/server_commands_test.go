package operator

import (
	"context"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeServerRenamer struct {
	result  []ServerRename
	err     error
	changes []ServerNameChange
	calls   int
}

func (fake *fakeServerRenamer) RenameServersTx(_ context.Context, _ tx.Tx, changes []ServerNameChange) ([]ServerRename, error) {
	fake.calls++
	fake.changes = changes
	return fake.result, fake.err
}

func callServerRename(t *testing.T, renamer ServerRenamer, payload string) (any, error) {
	t.Helper()
	return ServerRenameHandler(renamer)(context.Background(), tx.Scope{Tx: inventoryTx{}}, Command{Payload: []byte(payload)})
}

func TestServerRenameHandlerRenamesInsideTheTransaction(t *testing.T) {
	renamer := &fakeServerRenamer{result: []ServerRename{{ServerID: 2, OldName: "Server 2", NewName: "Sakura"}}}
	result, err := callServerRename(t, renamer, `{"server_id":2,"name":" Sakura "}`)
	if err != nil {
		t.Fatal(err)
	}
	if len(renamer.changes) != 1 || renamer.changes[0].ServerID != 2 || renamer.changes[0].Name != "Sakura" {
		t.Fatalf("owner saw %+v", renamer.changes)
	}
	rename, ok := result.(ServerRename)
	if !ok || rename.OldName != "Server 2" || rename.NewName != "Sakura" {
		t.Fatalf("result = %+v", result)
	}
}

func TestServerRenameHandlerRenamesABatch(t *testing.T) {
	renamer := &fakeServerRenamer{result: []ServerRename{
		{ServerID: 2, OldName: "Two", NewName: "Sakura"},
		{ServerID: 5, OldName: "Five", NewName: "Maple"},
	}}
	result, err := callServerRename(t, renamer, `{"names":[{"server_id":5,"name":" Maple "},{"server_id":2,"name":"Sakura"}]}`)
	if err != nil {
		t.Fatal(err)
	}
	want := []ServerNameChange{{ServerID: 5, Name: "Maple"}, {ServerID: 2, Name: "Sakura"}}
	if len(renamer.changes) != len(want) || renamer.changes[0] != want[0] || renamer.changes[1] != want[1] {
		t.Fatalf("owner saw %+v", renamer.changes)
	}
	batch, ok := result.(ServerRenameBatch)
	if !ok || len(batch.Renames) != 2 || batch.Renames[0].NewName != "Sakura" {
		t.Fatalf("result = %+v", result)
	}
}

func TestServerRenameHandlerRefusesBadBatches(t *testing.T) {
	cases := map[string]string{
		"empty names":   `{"names":[]}`,
		"zero id":       `{"names":[{"server_id":0,"name":"Alpha"}]}`,
		"bad name":      `{"names":[{"server_id":2,"name":"   "}]}`,
		"duplicate":     `{"names":[{"server_id":2,"name":"Alpha"},{"server_id":2,"name":"Beta"}]}`,
		"mixed forms":   `{"server_id":2,"name":"Alpha","names":[{"server_id":2,"name":"Beta"}]}`,
		"unknown entry": `{"names":[{"server_id":2,"name":"Alpha","extra":1}]}`,
	}
	for name, payload := range cases {
		t.Run(name, func(t *testing.T) {
			renamer := &fakeServerRenamer{}
			_, err := callServerRename(t, renamer, payload)
			var refusal *Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodePayloadInvalid {
				t.Fatalf("payload %s: err = %v", payload, err)
			}
			if renamer.calls != 0 {
				t.Fatal("the owner was called for a refused batch")
			}
		})
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
			if renamer.calls != 0 {
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

func TestServerRenameHandlerNamesTheMissingServerInABatch(t *testing.T) {
	_, err := callServerRename(t, &fakeServerRenamer{err: &ServerNotFoundError{ServerID: 7}}, `{"names":[{"server_id":2,"name":"Alpha"},{"server_id":7,"name":"Beta"}]}`)
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeServerNotFound {
		t.Fatalf("err = %v", err)
	}
	if !strings.Contains(refusal.Message, "server_id 7") {
		t.Fatalf("refusal does not name the server: %q", refusal.Message)
	}
}

func TestServerModuleDeclaresRename(t *testing.T) {
	module := ServerModule()
	index := commandIndex(module.Commands, "server.rename")
	if index < 0 {
		t.Fatalf("server.rename is not declared: %+v", module.Commands)
	}
	command := module.Commands[index]
	if command.Class != ClassLive || len(command.Fields) != 3 {
		t.Fatalf("server.rename = %+v", command)
	}
	if command.Fields[0].Name != "server_id" || command.Fields[1].Name != "name" {
		t.Fatalf("server.rename fields = %+v", command.Fields)
	}
	if command.Fields[2].Name != "names" || command.Fields[2].Type != FieldArray || command.Fields[2].Required {
		t.Fatalf("server.rename names field = %+v", command.Fields[2])
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
