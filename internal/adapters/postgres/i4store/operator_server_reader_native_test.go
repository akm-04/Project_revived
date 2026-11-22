//go:build postgres

package i4store_test

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
)

const serverListServer = 9011

func TestOperatorServerAndPlayerNameReadsNative(t *testing.T) {
	pool := o2DirectoryPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Second)
	firstPlayer := int64(serverListServer*100000 + 1)
	secondPlayer := int64(serverListServer*100000 + 2)
	account := o2UUID(t)
	secondAccount := o2UUID(t)
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'List Open',true,true,true,$2,$3,$4) ON CONFLICT DO NOTHING`, []any{serverListServer, serverListServer*100000 + 25001, (serverListServer+1)*100000 - 1, now}},
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'List Closed',true,false,false,$2,$3,$4) ON CONFLICT DO NOTHING`, []any{serverListServer + 1, (serverListServer+1)*100000 + 25001, (serverListServer+2)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "list-" + account, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{secondAccount, "list-" + secondAccount, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'list') ON CONFLICT DO NOTHING`, []any{firstPlayer, account, serverListServer, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'list') ON CONFLICT DO NOTHING`, []any{secondPlayer, secondAccount, serverListServer, now}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,'List Alpha',1,$2,$2) ON CONFLICT DO NOTHING`, []any{firstPlayer, now}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,'List Beta',1,$2,$2) ON CONFLICT DO NOTHING`, []any{secondPlayer, now}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	reader := i4store.ServerDirectoryReader{}
	servers, err := reader.OperatorServersTx(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	byID := map[int64]bool{}
	for _, server := range servers {
		byID[server.ServerID] = server.Open
	}
	open, found := byID[serverListServer]
	if !found || !open {
		t.Fatalf("open server = %+v", servers)
	}
	if closed, found := byID[serverListServer+1]; !found || closed {
		t.Fatalf("closed server = %+v", servers)
	}
	names, err := i4store.PlayerDirectoryReader{}.PlayerNamesTx(ctx, pool, []int64{firstPlayer, secondPlayer})
	if err != nil {
		t.Fatal(err)
	}
	if names[firstPlayer] != "List Alpha" || names[secondPlayer] != "List Beta" {
		t.Fatalf("names = %v", names)
	}
}
