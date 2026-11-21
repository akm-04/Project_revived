//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"testing"
	"time"
)

// BUGS #84/#85: the stock Cabinet and Recycle windows update only from the
// success reply they receive (JunkChestWindow.lua:1036-1081,
// EventCentre.lua:332-346; RecycleWindow.lua:992-1004, EventCentre.lua:456-468).
// The client's exact requests are {skill_id:<number>} and {type:3}; a paid
// success must carry cabinet_info and trash_info or the refresh is skipped.
func TestI912WorkshopMIDsAnswerTheStockLiveRefresh(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	database := pool(t)
	recycleActor, _, recycleBooks := bookFixture(t, database)
	finishBuilding(t, recycleBooks, recycleActor, 1)
	learnActor, _, _ := bookFixture(t, database)
	recycleBearer := displayToken(t, database, recycleActor)
	learnBearer := displayToken(t, database, learnActor)

	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	address := listener.Addr().String()
	listener.Close()
	origin := "http://" + address
	targetDSN := os.Getenv("GXB_I7B6A_DSN")
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, err = blobstore.NewLocal(assets); err != nil {
		t.Fatal(err)
	}
	command := osexec.Command(binary)
	command.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+targetDSN, "GXB_HTTP_ADDR="+address, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+assets, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
	log, err := os.CreateTemp(t.TempDir(), "api-log")
	if err != nil {
		t.Fatal(err)
	}
	command.Stdout = log
	command.Stderr = log
	if err = command.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		command.Process.Kill()
		command.Wait()
		log.Close()
	})
	for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
		response, err := http.Get(origin + "/profile-media/missing")
		if err == nil {
			response.Body.Close()
			break
		}
		time.Sleep(30 * time.Millisecond)
	}

	post := func(bearer string, mid int, fields map[string]any) (int, map[string]any) {
		fields["mid"] = mid
		fields["token"] = bearer
		fields["region"] = 1
		raw, _ := json.Marshal(fields)
		body := url.Values{"payload": {string(raw)}}.Encode()
		response, err := http.Post(origin+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(body))
		if err != nil {
			t.Fatal(err)
		}
		defer response.Body.Close()
		var out map[string]any
		if err = json.NewDecoder(response.Body).Decode(&out); err != nil {
			t.Fatal(err)
		}
		return response.StatusCode, out
	}

	code, out := post(recycleBearer, 1057, map[string]any{"type": 3})
	if code != 200 {
		t.Fatalf("upgrade recycle bin: %d %#v", code, out)
	}
	code, out = post(recycleBearer, 1077, map[string]any{"type": 3})
	if code != 200 || number(t, out["lev"]) != 2 || number(t, out["start_time"]) != 0 || number(t, out["need_time"]) != 0 || number(t, out["new_evolve"]) != 1 {
		t.Fatalf("accelerate recycle bin: %d %#v", code, out)
	}
	trash, ok := out["trash_info"].(map[string]any)
	if !ok {
		t.Fatalf("accelerate reply lacks trash_info: %#v", out)
	}
	for _, field := range []string{"energy", "energy_time"} {
		if _, present := trash[field]; !present {
			t.Fatalf("trash_info lacks %s: %#v", field, trash)
		}
	}

	code, out = post(learnBearer, 83, map[string]any{"item_id": 130001001, "item_num": 1})
	if code != 200 {
		t.Fatalf("compose book: %d %#v", code, out)
	}
	code, out = post(learnBearer, 1060, map[string]any{"skill_id": 10010001})
	cabinet, ok := out["cabinet_info"].(map[string]any)
	if code != 200 || !ok || number(t, cabinet["cur_learn_skill"]) != 10010001 || number(t, cabinet["need_time"]) <= 0 || number(t, cabinet["start_time"]) <= 0 {
		t.Fatalf("learn skill: %d %#v", code, out)
	}

	code, out = post(learnBearer, 1060, map[string]any{"skill_id": 10010004})
	if _, untagged := out["error"]; untagged || code != http.StatusConflict || out["error_code"] != float64(35028) || out["error_msg"] != "" {
		t.Fatalf("second skill while researching: %d %#v", code, out)
	}

	code, out = post(learnBearer, 1060, map[string]any{"skill_id": "not-a-number"})
	if code != http.StatusBadRequest {
		t.Fatalf("malformed skill id must stay 400: %d %#v", code, out)
	}
}
