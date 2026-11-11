//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
)

// i9Process is the exact candidate API binary serving one fixture player.
type i9Process struct {
	t       *testing.T
	command *osexec.Cmd
	log     *os.File
	origin  string
	bearer  string
	running bool
}

func startI9Process(t *testing.T, p *pg.Pool, actor identity.ActorContext) *i9Process {
	t.Helper()
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	bearer := displayToken(t, p, actor)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	address := listener.Addr().String()
	listener.Close()
	origin := "http://" + address
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, e := blobstore.NewLocal(assets); e != nil {
		t.Fatal(e)
	}
	command := osexec.Command(binary)
	command.Env = append(os.Environ(),
		"GXB_POSTGRES_DSN="+os.Getenv("GXB_I7B6A_DSN"),
		"GXB_HTTP_ADDR="+address,
		"GXB_PUBLIC_ENGINE_URL="+origin+"/engine",
		"GXB_REALTIME_PUBLIC_HOST=127.0.0.1",
		"GXB_REALTIME_PUBLIC_PORT=19001",
		"GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001",
		"GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001",
		"GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001",
		"GXB_DERIVATION_KEY_ID=i7b2b-native",
		"GXB_PROFILE_MEDIA_ROOT="+assets,
		"GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin,
	)
	log, e := os.CreateTemp(t.TempDir(), "api-log")
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { log.Close() })
	command.Stdout = log
	command.Stderr = log
	if e = command.Start(); e != nil {
		t.Fatal(e)
	}
	for end := time.Now().Add(15 * time.Second); time.Now().Before(end); {
		resp, e := http.Get(origin + "/profile-media/missing")
		if e == nil {
			resp.Body.Close()
			process := &i9Process{t: t, command: command, log: log, origin: origin, bearer: bearer, running: true}
			t.Cleanup(process.stop)
			return process
		}
		time.Sleep(30 * time.Millisecond)
	}
	command.Process.Kill()
	command.Wait()
	raw, _ := os.ReadFile(log.Name())
	t.Fatal("startup", string(raw))
	return nil
}

func (process *i9Process) post(mid uint16, fields map[string]any) (int, map[string]any) {
	process.t.Helper()
	fields["mid"] = mid
	fields["token"] = process.bearer
	fields["region"] = 1
	// Backend.lua:576-585 adds these to every stock request.
	fields["v_"] = "1.631.0"
	fields["app_v"] = "1.631.0"
	fields["platform"] = int64(3)
	raw, _ := json.Marshal(fields)
	resp, e := http.Post(process.origin+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {string(raw)}}.Encode()))
	if e != nil {
		process.t.Fatal(e)
	}
	defer resp.Body.Close()
	var body map[string]any
	if e = json.NewDecoder(resp.Body).Decode(&body); e != nil {
		process.t.Fatal(e)
	}
	return resp.StatusCode, body
}

func (process *i9Process) stop() {
	if !process.running {
		return
	}
	process.running = false
	process.command.Process.Signal(os.Interrupt)
	process.command.Wait()
	if process.t.Failed() {
		if raw, err := os.ReadFile(process.log.Name()); err == nil {
			process.t.Logf("API process log: %s", raw)
		}
	}
}

func i9Number(t *testing.T, value any) int64 {
	t.Helper()
	switch number := value.(type) {
	case float64:
		return int64(number)
	case int64:
		return number
	}
	t.Fatalf("not a number: %T %+v", value, value)
	return 0
}

// i9IntimacyFacts counts the durable objective receipts one favor move writes.
func i9IntimacyFacts(t *testing.T, p *pg.Pool, actor identity.ActorContext) int64 {
	t.Helper()
	var count int64
	query := `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='objective' AND operation='mission-source-fact'`
	if e := p.Raw().QueryRow(ctx, query, strconv.FormatInt(int64(actor.PlayerID), 10)).Scan(&count); e != nil {
		t.Fatal(e)
	}
	return count
}

func i9MissionProgress(t *testing.T, p *pg.Pool, actor identity.ActorContext, objectiveID int64) int64 {
	t.Helper()
	var progress int64
	query := `SELECT COALESCE((SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=$2 AND definition_revision='I9_MISSIONS_V1' ORDER BY generation_id LIMIT 1),0)`
	if e := p.Raw().QueryRow(ctx, query, int64(actor.PlayerID), objectiveID).Scan(&progress); e != nil {
		t.Fatal(e)
	}
	return progress
}

// assertI9Journal waits for the asynchronous request journal and rejects the
// two anomaly outcomes for every MID this fixture sent.
func assertI9Journal(t *testing.T, p *pg.Pool, actor identity.ActorContext, expected []int) {
	t.Helper()
	deadline := time.Now().Add(15 * time.Second)
	for {
		seen := map[int]string{}
		rows, e := p.Raw().Query(ctx, `SELECT mid,outcome FROM request_journal WHERE account_uid=$1 AND mid IS NOT NULL`, string(actor.AccountUID))
		if e != nil {
			t.Fatal(e)
		}
		for rows.Next() {
			var mid int
			var outcome string
			if e = rows.Scan(&mid, &outcome); e != nil {
				rows.Close()
				t.Fatal(e)
			}
			seen[mid] = outcome
		}
		rows.Close()
		complete := true
		for _, mid := range expected {
			if _, ok := seen[mid]; !ok {
				complete = false
				break
			}
		}
		if !complete && time.Now().Before(deadline) {
			time.Sleep(50 * time.Millisecond)
			continue
		}
		for mid, outcome := range seen {
			if outcome == "UNKNOWN_MID" || outcome == "SERVER_ERROR" {
				t.Fatalf("journal MID%d outcome %s", mid, outcome)
			}
		}
		for _, mid := range expected {
			if _, ok := seen[mid]; !ok {
				t.Fatalf("journal missing MID%d", mid)
			}
		}
		return
	}
}

func TestI9_10BLibraryProcessStockMIDs(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	resetForumBoards(t, p)
	actor := bornActor(t, p)
	hero := bornHero(t, p, actor, revision, 10001013, 1)
	setLibraryFavor(t, p, actor, 1, 100)
	seedStack(t, p, actor, revision, 50005011, 1)
	seedStack(t, p, actor, revision, lib.BackgroundUnlockItemID, 1)
	api := startI9Process(t, p, actor)

	code, body := api.post(836, map[string]any{})
	if code != 200 || body["library_infos"] == nil || body["library_talk_infos"] == nil || body["library_cg_infos"] == nil || body["library_bg_infos"] == nil {
		t.Fatalf("836 status %d body %+v", code, body)
	}
	code, body = api.post(838, map[string]any{"partner_id": int64(1)})
	if code != 200 || len(body["partner_dialogs"].([]any)) != 3 {
		t.Fatalf("838 status %d body %+v", code, body)
	}
	code, body = api.post(837, map[string]any{"partner_id": int64(1), "dialog_id": int64(1)})
	if code != 200 || body["dialog"].(map[string]any)["is_read"] != float64(1) {
		t.Fatalf("837 status %d body %+v", code, body)
	}
	code, body = api.post(841, map[string]any{"partner_id": int64(1)})
	if code != 200 || len(body["mission_list"].([]any)) != 3 {
		t.Fatalf("841 status %d body %+v", code, body)
	}
	code, body = api.post(842, map[string]any{"partner_id": int64(1)})
	// Favor 100 is the [0,100] band: only act 1 is addressable.
	if code != 200 || len(body["partner_acts"].([]any)) != 1 {
		t.Fatalf("842 status %d body %+v", code, body)
	}

	code, body = api.post(834, map[string]any{"id": int64(1), "comment": "vc library comment"})
	if code != 200 {
		t.Fatalf("834 status %d body %+v", code, body)
	}
	code, body = api.post(832, map[string]any{"start_pos": int64(1), "end_pos": int64(50), "table_id": hero.TableID})
	if code != 200 || len(body["comments"].([]any)) != 1 {
		t.Fatalf("832 status %d body %+v", code, body)
	}
	comment := body["comments"].([]any)[0].(map[string]any)
	if i9Number(t, comment["player_id"]) != int64(actor.PlayerID) || comment["comment"] != "vc library comment" || i9Number(t, comment["table_id"]) != hero.TableID {
		t.Fatalf("832 row %+v", comment)
	}
	code, body = api.post(833, map[string]any{"player_id": int64(actor.PlayerID), "table_id": hero.TableID})
	if code != 200 || i9Number(t, body["comments"].([]any)[0].(map[string]any)["like"]) != 1 || i9Number(t, body["comments"].([]any)[0].(map[string]any)["is_commented"]) != 1 {
		t.Fatalf("833 status %d body %+v", code, body)
	}
	// 10001013 is partner.lua modelid for the fixture hero (source: data/tables/partner.lua).
	code, body = api.post(835, map[string]any{"partner_id": int64(1), "card_status": int64(1), "board_model_id": int64(10001013)})
	if code != 200 || i9Number(t, body["board_partner"]) != 1 || i9Number(t, body["board_card"]) != 1 || i9Number(t, body["board_model_id"]) != 10001013 {
		t.Fatalf("835 status %d body %+v", code, body)
	}

	code, body = api.post(839, map[string]any{"gift_id": int64(50005011), "gift_num": int64(1)})
	if code != 200 || i9Number(t, body["gift_id"]) != 50005011 || i9Number(t, body["gift_num"]) != 2 {
		t.Fatalf("839 status %d body %+v", code, body)
	}
	code, body = api.post(840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)})
	if code != 200 || i9Number(t, body["favor_degree"]) != 113 {
		t.Fatalf("840 status %d body %+v", code, body)
	}
	dialogs, ok := body["partner_dialogs"].([]any)
	if !ok || len(dialogs) != 4 {
		t.Fatalf("840 partner_dialogs %T %+v", body["partner_dialogs"], body["partner_dialogs"])
	}
	for index, wantID := range []int64{1, 2, 12, 13} {
		if got := i9Number(t, dialogs[index].(map[string]any)["dialog_id"]); got != wantID {
			t.Fatalf("840 dialog %d id %d want %d", index, got, wantID)
		}
	}
	// Favor 113 is the (100,300] band: acts 1 and 2.
	if acts, ok := body["partner_acts"].([]any); !ok || len(acts) != 2 {
		t.Fatalf("840 partner_acts %T %+v", body["partner_acts"], body["partner_acts"])
	}
	if facts := i9IntimacyFacts(t, p, actor); facts != 1 {
		t.Fatalf("gift intimacy facts %d want 1", facts)
	}
	if progress := i9MissionProgress(t, p, actor, 10029); progress != 1 {
		t.Fatalf("gift mission 10029 progress %d want 1", progress)
	}
	// 203001 is a type-2 choice row with is_reward=1 in data/tables/10001013.lua.
	code, body = api.post(843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "1|203001"})
	if code != 200 || i9Number(t, body["dialog_info"].(map[string]any)["is_awarded"]) != 1 || i9Number(t, body["dialog_info"].(map[string]any)["select_id"]) != 203001 || i9Number(t, body["favor_degree"]) != 115 {
		t.Fatalf("843 status %d body %+v", code, body)
	}
	if facts := i9IntimacyFacts(t, p, actor); facts != 2 {
		t.Fatalf("talk intimacy facts %d want 2", facts)
	}
	if progress := i9MissionProgress(t, p, actor, 10029); progress != 2 {
		t.Fatalf("talk mission 10029 progress %d want 2", progress)
	}
	code, body = api.post(844, map[string]any{"partner_id": int64(1), "act_id": int64(1)})
	if code != 200 || i9Number(t, body["favor_degree"]) != 120 {
		t.Fatalf("844 status %d body %+v", code, body)
	}
	if facts := i9IntimacyFacts(t, p, actor); facts != 3 {
		t.Fatalf("act intimacy facts %d want 3", facts)
	}
	if progress := i9MissionProgress(t, p, actor, 10029); progress != 3 {
		t.Fatalf("act mission 10029 progress %d want 3", progress)
	}
	code, body = api.post(851, map[string]any{"talk_id": int64(1001)})
	if code != 200 || len(body["awards"].([]any)) != 1 {
		t.Fatalf("851 status %d body %+v", code, body)
	}
	code, body = api.post(855, map[string]any{"index": int64(1)})
	if code != 200 || len(body["awards"].([]any)) != 1 {
		t.Fatalf("855 status %d body %+v", code, body)
	}
	code, body = api.post(856, map[string]any{"bg_id": int64(3)})
	if code != 200 {
		t.Fatalf("856 status %d body %+v", code, body)
	}
	code, body = api.post(857, map[string]any{"_type": int64(1), "bg_id": int64(3)})
	if code != 200 {
		t.Fatalf("857 status %d body %+v", code, body)
	}
	for _, mid := range []uint16{845, 846, 847} {
		code, body = api.post(mid, map[string]any{"partner_id": int64(1), "mission_id": int64(1001)})
		if code != 409 || body["error_code"] != float64(35028) {
			t.Fatalf("%d status %d body %+v", mid, code, body)
		}
	}
	code, body = api.post(836, map[string]any{"partner_id": int64(1)})
	if code != 400 {
		t.Fatalf("836 extra param status %d body %+v", code, body)
	}
	// Representative D426 business refusals on existing live routes.
	code, body = api.post(837, map[string]any{"partner_id": int64(1), "dialog_id": int64(9)})
	if code != 409 || body["error_code"] != float64(35028) {
		t.Fatalf("837 closed dialog status %d body %+v", code, body)
	}
	code, body = api.post(851, map[string]any{"talk_id": int64(1001)})
	if code != 409 || body["error_code"] != float64(35028) {
		t.Fatalf("851 replay status %d body %+v", code, body)
	}
	code, body = api.post(839, map[string]any{"gift_id": int64(50001112), "gift_num": int64(1)})
	if code != 409 || body["error_code"] != float64(35028) {
		t.Fatalf("839 insufficient crystal status %d body %+v", code, body)
	}
	// Malformed requests stay 400.
	code, body = api.post(838, map[string]any{})
	if code != 400 {
		t.Fatalf("838 missing partner status %d body %+v", code, body)
	}
	code, body = api.post(843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "bad"})
	if code != 400 {
		t.Fatalf("843 malformed select status %d body %+v", code, body)
	}

	api.stop()
	assertI9Journal(t, p, actor, []int{836, 838, 837, 841, 842, 834, 832, 833, 835, 839, 840, 843, 844, 851, 855, 856, 857, 845, 846, 847})
}
