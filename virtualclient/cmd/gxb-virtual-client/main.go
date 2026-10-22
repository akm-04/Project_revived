// Command gxb-virtual-client boots the stock client headless against a running gxb-api and writes the run report.
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

	"gxb.local/backend/v2/virtualclient/client"
	"gxb.local/backend/v2/virtualclient/provision"
)

func main() {
	source := flag.String("source", "", "stock src_64 directory")
	assets := flag.String("assets", "", "APK assets directory (holds res/)")
	updateTree := flag.String("update-tree", "", "gxb-asset-tree output linked into the device as already-downloaded assets (empty: none)")
	device := flag.String("device", "", "device storage directory for this virtual install")
	origin := flag.String("origin", "", "gxb-api origin replacing the stock hard-coded servers")
	databaseURL := flag.String("database", "", "backend database URL for provisioning the SDK login")
	until := flag.String("until", "MainScene", "stop once the client enters this scene")
	limit := flag.Duration("limit", 180*time.Second, "virtual time limit")
	reportPath := flag.String("report", "", "report JSON path (default stdout)")
	region := flag.Int("region", 1, "region the returning device remembers (0: fresh install)")
	taps := flag.String("taps", "region_button,last_login_panel/server,640x500,640x360*20",
		"comma-separated taps, each a node name path or XxY design coordinates, *N repeats one; the default picks the remembered "+
			"server, logs in and taps through the first story")
	wait := flag.Duration("wait", 5*time.Second, "virtual time before each tap")
	flag.Parse()
	scenario := scenario{source: *source, assets: *assets, updateTree: *updateTree, device: *device, origin: *origin, databaseURL: *databaseURL, until: *until,
		limit: *limit, reportPath: *reportPath, region: *region, taps: expandTaps(*taps), wait: *wait}
	if err := scenario.run(); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-virtual-client:", err)
		os.Exit(1)
	}
}

type scenario struct {
	source, assets, updateTree, device, origin, databaseURL, until, reportPath string
	limit, wait                                                                time.Duration
	region                                                                     int
	taps                                                                       []string
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

func (scenario scenario) run() error {
	source, assets, device, origin, databaseURL, until, limit, reportPath := scenario.source, scenario.assets, scenario.device,
		scenario.origin, scenario.databaseURL, scenario.until, scenario.limit, scenario.reportPath
	secret := os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET")
	if secret == "" {
		return fmt.Errorf("GXB_CREDENTIAL_DIGEST_SECRET must match the backend's")
	}
	session, err := provision.Account(context.Background(), databaseURL, []byte(secret))
	if err != nil {
		return fmt.Errorf("provision: %w", err)
	}
	virtual, err := client.New(client.Options{SourceRoot: source, AssetRoot: assets, DeviceRoot: device, BackendOrigin: origin,
		UpdateTree: scenario.updateTree, SID: session.SID, LoginToken: session.LoginToken, Log: os.Stderr, RememberedRegion: client.Region{ID: scenario.region, Name: fmt.Sprintf("Server %d", scenario.region)}})
	if err != nil {
		return err
	}
	defer virtual.Close()
	if err := virtual.Boot(); err != nil {
		return fmt.Errorf("boot: %w", err)
	}
	reached := func(current *client.Client) bool { return current.InScene(until) }
	runErr := scenario.play(virtual, reached)
	if runErr == nil && !reached(virtual) {
		runErr = virtual.Run(limit-time.Duration(len(scenario.taps))*scenario.wait, reached)
	}
	report, err := json.MarshalIndent(struct {
		Account string        `json:"account_id"`
		Reached bool          `json:"reached"`
		Until   string        `json:"until"`
		Report  client.Report `json:"report"`
	}{session.AccountID, virtual.InScene(until), until, virtual.Report()}, "", " ")
	if err != nil {
		return err
	}
	if reportPath == "" {
		fmt.Println(string(report))
		return runErr
	}
	if err := os.WriteFile(reportPath, append(report, '\n'), 0o644); err != nil {
		return err
	}
	return runErr
}

func (scenario scenario) play(virtual *client.Client, reached func(*client.Client) bool) error {
	for _, target := range scenario.taps {
		if err := virtual.Run(scenario.wait, reached); err != nil || reached(virtual) {
			return err
		}
		if err := tap(virtual, target); err != nil {
			return fmt.Errorf("tap %s: %w", target, err)
		}
	}
	return nil
}
