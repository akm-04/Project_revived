// Command gxb-virtual-client boots the stock client headless against a running gxb-api, plays one scenario and writes the run report.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/virtualclient/client"
	"gxb.local/backend/v2/virtualclient/provision"
)

const defaultTaps = "region_button,last_login_panel/server,640x500,640x360*20"

func main() {
	source := flag.String("source", "", "stock src_64 directory")
	assets := flag.String("assets", "", "APK assets directory (holds res/)")
	updateTree := flag.String("update-tree", "", "gxb-asset-tree output linked into the device as already-downloaded assets (empty: none)")
	device := flag.String("device", "", "device storage directory for this virtual install")
	origin := flag.String("origin", "", "gxb-api origin replacing the stock hard-coded servers")
	databaseURL := flag.String("database", "", "backend database URL for provisioning the SDK login")
	scenarioPath := flag.String("scenario", "", "scenario JSON played once the client is in MainScene (empty: boot only)")
	limit := flag.Duration("limit", 180*time.Second, "virtual time limit for reaching MainScene")
	reportPath := flag.String("report", "", "report JSON path (default stdout)")
	region := flag.Int("region", 1, "region the returning device remembers (0: fresh install)")
	taps := flag.String("taps", defaultTaps,
		"comma-separated boot taps, each a node name path or XxY design coordinates, *N repeats one; the default picks the remembered "+
			"server, logs in and taps through the first story; taps stop once the client is in MainScene")
	wait := flag.Duration("wait", 5*time.Second, "virtual time before each tap or step")
	flag.Parse()
	run := run{source: *source, assets: *assets, updateTree: *updateTree, device: *device, origin: *origin, databaseURL: *databaseURL,
		limit: *limit, reportPath: *reportPath, region: *region, taps: expandTaps(*taps), wait: *wait}
	if *scenarioPath != "" {
		content, err := os.ReadFile(*scenarioPath)
		if err == nil {
			err = json.Unmarshal(content, &run.scenario)
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, "gxb-virtual-client: scenario:", err)
			os.Exit(2)
		}
	}
	failures, err := run.play()
	if err != nil {
		fmt.Fprintln(os.Stderr, "gxb-virtual-client:", err)
		os.Exit(1)
	}
	if len(failures) > 0 {
		fmt.Fprintln(os.Stderr, "gxb-virtual-client: scenario failed:", strings.Join(failures, "; "))
		os.Exit(3)
	}
}

// scenario is one I8.5-5 scenario (D55): a provisioned player (D56), steps after MainScene and what the run must show.
type scenario struct {
	FriendFixture bool   `json:"friend_fixture"`
	Name          string `json:"name"`
	// Level and Heroes progress the player stock MID1 births; the stock client then summons each hero through MID59.
	Level  int64        `json:"level"`
	VIP    int64        `json:"vip"`
	Grants []grant.Line `json:"grants"`
	Heroes []int64      `json:"heroes"`
	// ChallengeFixture seeds declared prior clears through the Campaign store; it is not gameplay-origin proof.
	ChallengeFixture bool `json:"challenge_fixture"`
	// SignInBonusFixture is declared prior-month progress, not proof of earning login rewards.
	SignInBonusFixture bool `json:"signin_bonus_fixture"`
	// AwakeningFixture declares prior progression of the fresh birth companion; never mission completion.
	AwakeningFixture bool `json:"awakening_fixture"`
	// PetAwakeningFixture declares one prior hatched level-90 pet; never mission completion.
	PetAwakeningFixture bool `json:"pet_awakening_fixture"`
	// KeepFunctionNotice leaves the stock function_show popup that the provisioned summons earn for the scenario to handle itself.
	KeepFunctionNotice bool `json:"keep_function_notice"`
	// Steps: "tap:<node path or XxY>", "window:<stock window>[ <json params>]", "lua:<chunk>", "wait:<seconds>", "relogin" (same account/device, fresh Lua VM),
	// "relogin-after:<file>" (a relogin that first waits in wall time until <file> exists, so an operator can move the host clock).
	// "fixture:top_floor_task_rank" (moves the player to rank 150 of the normal ladder, which must already exist).
	// "fixture:one_on_one_cooling" (starts the cooldown of a player that already loaded 1on1).
	Steps []string `json:"steps"`
	// Settle is virtual seconds run after the last step (stock ErrorLogPoster uploads every 30 s).
	Settle float64 `json:"settle_seconds"`
	// ExpectOK: MIDs the stock client must have sent with HTTP 200 and stock error_code 0.
	ExpectOK []int `json:"expect_ok"`
	// ExpectInactive: MIDs the stock client must have sent and the shared inactive dispatcher answered 200 with error_code 1,
	// journalled INACTIVE_MODE (I9_MODE_FOUNDATION_V1 MF2).
	ExpectInactive []int `json:"expect_inactive"`
	// ExpectLuaErrors: each must match at least one Lua error, and every Lua error must match one of them (empty: none at all).
	ExpectLuaErrors []string `json:"expect_lua_errors"`
	// ExpectClientLog: text the backend must hold in this account's client log rows; ExpectClientLogAbsent: text it must not.
	ExpectClientLog       []string `json:"expect_client_log"`
	ExpectClientLogAbsent []string `json:"expect_client_log_absent"`
}

const closeFunctionNotice = "lua:local m=xyd.WindowManager.get() if m:getWindow('function_show') then m:closeWindow('function_show') end"

type run struct {
	source, assets, updateTree, device, origin, databaseURL, reportPath string
	limit, wait                                                         time.Duration
	region                                                              int
	taps                                                                []string
	scenario                                                            scenario
	account                                                             string
}

// expandTaps reads the -taps list, where "target*N" stands for N taps on target.
func expandTaps(list string) []string {
	var taps []string
	for _, entry := range strings.Split(list, ",") {
		target, count := entry, 1
		if index := strings.LastIndex(entry, "*"); index >= 0 {
			if parsed, err := strconv.Atoi(entry[index+1:]); err == nil {
				target, count = entry[:index], parsed
			}
		}
		for range count {
			taps = append(taps, target)
		}
	}
	return taps
}

// tap is one player input: a design coordinate "XxY" or a node name path.
func tap(virtual *client.Client, target string) error {
	var x, y float64
	if _, err := fmt.Sscanf(target, "%gx%g", &x, &y); err == nil {
		return virtual.Tap(x, y)
	}
	return virtual.TapNode(target)
}

func inMainScene(current *client.Client) bool { return current.InScene("MainScene") }

func (run run) play() ([]string, error) {
	secret := os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET")
	if secret == "" {
		return nil, fmt.Errorf("GXB_CREDENTIAL_DIGEST_SECRET must match the backend's")
	}
	ctx := context.Background()
	session, err := provision.Account(ctx, run.databaseURL, []byte(secret))
	if err != nil {
		return nil, fmt.Errorf("provision: %w", err)
	}
	run.account = session.AccountID
	output := struct {
		Account  string             `json:"account_id"`
		Scenario string             `json:"scenario,omitempty"`
		Sessions []client.Report    `json:"sessions,omitempty"`
		Birth    *client.Report     `json:"birth,omitempty"`
		Summons  []provision.Summon `json:"summons,omitempty"`
		Reached  bool               `json:"reached"`
		Report   client.Report      `json:"report"`
		Failures []string           `json:"failures"`
	}{Account: session.AccountID, Scenario: run.scenario.Name, Failures: []string{}}
	progressed := run.scenario.FriendFixture || run.scenario.AwakeningFixture || run.scenario.PetAwakeningFixture || run.scenario.SignInBonusFixture || run.scenario.ChallengeFixture || run.scenario.Level > 0 || len(run.scenario.Heroes) > 0 || run.scenario.VIP > 0 || len(run.scenario.Grants) > 0
	if progressed {
		// A returning player: the first boot lets stock MID1 birth the player, the harness progresses it, the second boot loads it.
		birth, err := run.boot(session)
		if err != nil {
			return nil, err
		}
		reached := birth.InScene("MainScene")
		// A progressed fixture declares completed tutorials through the stock MID26 owner; fresh level-0 walks do not.
		if reached && run.scenario.Level > 0 {
			if err := birth.Call("local s=xyd.StoryData.get() s:setGuideID(100503,true) s:persist()"); err != nil {
				birth.Close()
				return nil, fmt.Errorf("progressed tutorial fixture: %w", err)
			}
			if err := birth.Run(run.wait, nil); err != nil {
				birth.Close()
				return nil, err
			}
		}
		report := birth.Report()
		if run.scenario.Level > 0 && !answeredOK(report, 26) {
			birth.Close()
			return nil, fmt.Errorf("progressed fixture MID26 was not acknowledged")
		}
		output.Birth = &report
		birth.Close()
		if !reached {
			return nil, fmt.Errorf("birth boot never reached MainScene")
		}
		if output.Summons, err = provision.Progress(ctx, run.databaseURL, session.AccountID, run.scenario.Level, run.scenario.Heroes, run.scenario.ChallengeFixture); err != nil {
			return nil, fmt.Errorf("progress: %w", err)
		}
	}
	if progressed {
		if err := provision.Configure(ctx, run.databaseURL, session.AccountID, run.scenario.VIP, run.scenario.Grants); err != nil {
			return nil, err
		}
	}
	if run.scenario.SignInBonusFixture {
		if err := provision.SignInBonusFixture(ctx, run.databaseURL, session.AccountID); err != nil {
			return nil, err
		}
	}
	if run.scenario.AwakeningFixture {
		if err := provision.AwakeningFixture(ctx, run.databaseURL, session.AccountID); err != nil {
			return nil, err
		}
	}
	if run.scenario.PetAwakeningFixture {
		if err := provision.PetAwakeningFixture(ctx, run.databaseURL, session.AccountID); err != nil {
			return nil, err
		}
	}
	if run.scenario.FriendFixture {
		peer, err := run.bornPeer(ctx, secret)
		if err != nil {
			return nil, fmt.Errorf("friend peer: %w", err)
		}
		if err := provision.FriendFixture(ctx, run.databaseURL, session.AccountID, peer); err != nil {
			return nil, err
		}
	}
	groups, resumeFiles := [][]string{{}}, []string{""}
	for _, step := range run.scenario.Steps {
		resumeFile, delayed := strings.CutPrefix(step, "relogin-after:")
		if !delayed {
			resumeFile = ""
		}
		if step == "relogin" || delayed {
			groups, resumeFiles = append(groups, []string{}), append(resumeFiles, resumeFile)
		} else {
			groups[len(groups)-1] = append(groups[len(groups)-1], step)
		}
	}
	for i, group := range groups {
		if err = awaitFile(resumeFiles[i]); err != nil {
			break
		}
		virtual, bootErr := run.boot(session)
		if bootErr != nil {
			err = bootErr
			break
		}
		output.Reached = virtual.InScene("MainScene")
		segment := run
		segment.scenario.Steps = group
		summons := output.Summons
		if i > 0 {
			summons = nil
		}
		if i < len(groups)-1 {
			segment.scenario.Settle = 0
		}
		if output.Reached {
			err = segment.steps(virtual, summons)
		}
		output.Sessions = append(output.Sessions, virtual.Report())
		virtual.Close()
		if err != nil || !output.Reached {
			break
		}
	}
	output.Report = mergeReports(output.Sessions)
	if err == nil {
		output.Failures, err = run.check(ctx, session.AccountID, output.Reached, output.Report)
	}
	if err != nil {
		output.Failures = append(output.Failures, err.Error())
	}
	encoded, marshalErr := json.MarshalIndent(output, "", " ")
	if marshalErr != nil {
		return nil, marshalErr
	}
	if run.reportPath == "" {
		fmt.Println(string(encoded))
		return output.Failures, nil
	}
	return output.Failures, os.WriteFile(run.reportPath, append(encoded, '\n'), 0o644)
}

// awaitFile blocks in wall time until path exists (empty path: no wait), for a host clock moved between two sessions.
func awaitFile(path string) error {
	if path == "" {
		return nil
	}
	fmt.Fprintln(os.Stderr, "gxb-virtual-client: waiting for", path)
	for deadline := time.Now().Add(24 * time.Hour); time.Now().Before(deadline); time.Sleep(10 * time.Second) {
		if _, err := os.Stat(path); err == nil {
			return nil
		}
	}
	return fmt.Errorf("relogin-after: %s never appeared", path)
}

// boot starts one client process on the account's device and plays the boot taps until MainScene or the limit.
func (run run) boot(session provision.Session) (*client.Client, error) {
	virtual, err := client.New(client.Options{SourceRoot: run.source, AssetRoot: run.assets, DeviceRoot: run.device, BackendOrigin: run.origin,
		UpdateTree: run.updateTree, SID: session.SID, LoginToken: session.LoginToken, Log: os.Stderr,
		RememberedRegion: client.Region{ID: run.region, Name: fmt.Sprintf("Server %d", run.region)}})
	if err != nil {
		return nil, err
	}
	if err := virtual.Boot(); err != nil {
		virtual.Close()
		return nil, fmt.Errorf("boot: %w", err)
	}
	for _, target := range run.taps {
		if err := virtual.Run(run.wait, inMainScene); err != nil || inMainScene(virtual) {
			return virtual, err
		}
		if err := tap(virtual, target); err != nil {
			virtual.Close()
			return nil, fmt.Errorf("tap %s: %w", target, err)
		}
	}
	return virtual, virtual.Run(run.limit-time.Duration(len(run.taps))*run.wait, inMainScene)
}

// bornPeer births a second player through stock MID1 at the scenario level and returns its account.
func (run run) bornPeer(ctx context.Context, secret string) (string, error) {
	peer, err := provision.Account(ctx, run.databaseURL, []byte(secret))
	if err != nil {
		return "", err
	}
	birth, err := run.boot(peer)
	if err != nil {
		return "", err
	}
	reached := birth.InScene("MainScene")
	birth.Close()
	if !reached {
		return "", fmt.Errorf("birth boot never reached MainScene")
	}
	if _, err := provision.Progress(ctx, run.databaseURL, peer.AccountID, run.scenario.Level, nil, false); err != nil {
		return "", err
	}
	return peer.AccountID, nil
}

// steps plays the hero summons provisioning granted, then the scenario steps, then the settle time.
func (run run) steps(virtual *client.Client, summons []provision.Summon) error {
	var steps []string
	for _, summon := range summons {
		steps = append(steps, fmt.Sprintf("lua:xyd.selfPlayer:stoneSummonHero({table_id=%d, stone=%d, stone_num=%d})", summon.TableID, summon.Stone, summon.StoneNum))
	}
	if run.scenario.Level > 0 && !run.scenario.KeepFunctionNotice {
		steps = append(steps, closeFunctionNotice)
	}
	for _, step := range append(steps, run.scenario.Steps...) {
		if err := virtual.Run(run.wait, nil); err != nil {
			return err
		}
		if err := run.step(virtual, step); err != nil {
			return fmt.Errorf("step %q: %w", step, err)
		}
	}
	return virtual.Run(time.Duration(run.scenario.Settle*float64(time.Second))+run.wait, nil)
}

func (run run) step(virtual *client.Client, step string) error {
	kind, argument, _ := strings.Cut(step, ":")
	switch kind {
	case "tap":
		return tap(virtual, argument)
	case "lua":
		return virtual.Call(argument)
	case "window":
		name, parameters, _ := strings.Cut(argument, " ")
		if parameters == "" {
			parameters = "{}"
		}
		return virtual.Call(fmt.Sprintf("xyd.WindowManager.get():openWindow(%q, json.decode(%q))", name, parameters))
	case "fixture":
		switch argument {
		case "top_floor_task_rank":
			return provision.TopFloorTaskRankFixture(context.Background(), run.databaseURL, run.account)
		case "one_on_one_cooling":
			return provision.OneOnOneCoolingFixture(context.Background(), run.databaseURL, run.account)
		}
		return fmt.Errorf("unknown fixture %q", argument)
	case "wait":
		seconds, err := strconv.ParseFloat(argument, 64)
		if err != nil {
			return err
		}
		return virtual.Run(time.Duration(seconds*float64(time.Second)), nil)
	}
	return fmt.Errorf("unknown step kind %q", kind)
}

// check compares the run with the scenario's expectations.
func (run run) check(ctx context.Context, accountID string, reached bool, report client.Report) ([]string, error) {
	failures := []string{}
	if !reached {
		return append(failures, "never reached MainScene"), nil
	}
	for _, mid := range run.scenario.ExpectOK {
		if !answeredOK(report, mid) {
			failures = append(failures, fmt.Sprintf("MID%d not sent or not answered 200 with error_code 0", mid))
		}
	}
	inactive, err := inactiveFailures(ctx, run.databaseURL, accountID, report, run.scenario.ExpectInactive)
	if err != nil {
		return failures, err
	}
	failures = append(failures, inactive...)
	for _, exchange := range report.Requests {
		if exchange.MID > 0 && len(exchange.NullFields) > 0 {
			failures = append(failures, fmt.Sprintf("MID%d answers JSON null at %s", int(exchange.MID), strings.Join(exchange.NullFields, ", ")))
		}
	}
	failures = append(failures, luaErrorFailures(report.LuaErrors, run.scenario.ExpectLuaErrors)...)
	if len(run.scenario.ExpectClientLog)+len(run.scenario.ExpectClientLogAbsent) == 0 {
		return failures, nil
	}
	logged, err := clientLog(ctx, run.databaseURL, accountID)
	if err != nil {
		return failures, err
	}
	for _, text := range run.scenario.ExpectClientLog {
		if !strings.Contains(logged, text) {
			failures = append(failures, fmt.Sprintf("client log of %s lacks %q", accountID, text))
		}
	}
	for _, text := range run.scenario.ExpectClientLogAbsent {
		if strings.Contains(logged, text) {
			failures = append(failures, fmt.Sprintf("client log of %s holds %q", accountID, text))
		}
	}
	return failures, nil
}

func answeredOK(report client.Report, mid int) bool {
	return answered(report, mid, 0)
}

func answered(report client.Report, mid int, errorCode int) bool {
	for _, exchange := range report.Requests {
		if int(exchange.MID) == mid && exchange.Status == 200 && int(exchange.ErrorCode) == errorCode {
			return true
		}
	}
	return false
}

func inactiveFailures(ctx context.Context, databaseURL, accountUID string, report client.Report, mids []int) ([]string, error) {
	failures := []string{}
	if len(mids) == 0 {
		return failures, nil
	}
	// The API journal flushes in batches every 250 ms (D46), so rows for the last replies may not be written yet.
	time.Sleep(time.Second)
	connection, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		return failures, err
	}
	defer connection.Close(ctx)
	for _, mid := range mids {
		if !answered(report, mid, 1) {
			failures = append(failures, fmt.Sprintf("MID%d not sent or not answered 200 with error_code 1", mid))
		}
		var journalled int
		if err := connection.QueryRow(ctx, `SELECT count(*) FROM request_journal WHERE account_uid=$1 AND mid=$2 AND outcome='INACTIVE_MODE'`, accountUID, mid).Scan(&journalled); err != nil {
			return failures, err
		}
		if journalled == 0 {
			failures = append(failures, fmt.Sprintf("MID%d has no INACTIVE_MODE journal row", mid))
		}
	}
	return failures, nil
}

func luaErrorFailures(errors, expected []string) []string {
	var failures []string
	for _, want := range expected {
		if !anyContains(errors, want) {
			failures = append(failures, fmt.Sprintf("expected Lua error %q did not occur", want))
		}
	}
	for _, got := range errors {
		if !anyContainedIn(got, expected) {
			failures = append(failures, "unexpected Lua error: "+errorLine(got))
		}
	}
	return failures
}

func anyContains(texts []string, part string) bool {
	for _, text := range texts {
		if strings.Contains(text, part) {
			return true
		}
	}
	return false
}

func anyContainedIn(text string, parts []string) bool {
	for _, part := range parts {
		if strings.Contains(text, part) {
			return true
		}
	}
	return false
}

// errorLine is the stock "LUA ERROR: <message>" line of a traceback (stock prints the platform line after it), else the first line.
func errorLine(text string) string {
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		if _, message, found := strings.Cut(line, "LUA ERROR: "); found {
			return message
		}
	}
	return lines[0]
}

// clientLog is everything the backend ingested for the account: the per-uid view an operator gets from gxb-client-log.
func clientLog(ctx context.Context, databaseURL, accountUID string) (string, error) {
	connection, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		return "", err
	}
	defer connection.Close(ctx)
	var logged string
	err = connection.QueryRow(ctx, `SELECT coalesce(string_agg(log || E'\n' || dump, E'\n'), '') FROM client_log_rows WHERE account_uid=$1`, accountUID).Scan(&logged)
	return logged, err
}

// mergeReports keeps errors and requests from every login subject to the same assertions.
func mergeReports(sessions []client.Report) client.Report {
	out := client.Report{Missing: map[string]float64{}}
	for _, r := range sessions {
		out.SourceDigest = r.SourceDigest
		out.VirtualTime += r.VirtualTime
		out.Proxies += r.Proxies
		out.Scenes = append(out.Scenes, r.Scenes...)
		out.Requests = append(out.Requests, r.Requests...)
		out.LuaErrors = append(out.LuaErrors, r.LuaErrors...)
		out.Unreadable = append(out.Unreadable, r.Unreadable...)
		out.SDKCalls = append(out.SDKCalls, r.SDKCalls...)
		out.Exited = out.Exited || r.Exited
		for name, count := range r.Missing {
			out.Missing[name] += count
		}
	}
	return out
}
