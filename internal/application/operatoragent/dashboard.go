package operatoragent

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

const (
	// DashboardServerLimit bounds the per-server fan-out of the dashboard read.
	DashboardServerLimit = 64
	// DashboardEventLimit is the events.list page size per server.
	DashboardEventLimit = 50
	// CloudflareMetricsNotInV2 records the V2 scope: no Cloudflare token, so no
	// cache metrics (OPERATOR_GUI_V2 design item 7).
	CloudflareMetricsNotInV2 = "not_in_v2"
)

// DashboardModule is the agent's dashboard module: one read that folds the
// backend facts a home page shows (OPERATOR_GUI_V2 design item 7).
func DashboardModule() operator.Module {
	return operator.Module{
		ID:         "dashboard",
		Title:      "Dashboard",
		Role:       operator.RoleRoot,
		LogChannel: "dashboard",
		Screen:     operator.Screen{Tab: "Dashboard"},
		Reads: []operator.Read{
			{Name: "dashboard.summary", Help: "Backend, servers, events, OTA and asset-front overview."},
		},
	}
}

// VersionSource answers the backend version endpoint.
type VersionSource interface {
	Version(context.Context) (operator.VersionInfo, error)
}

// DashboardBackups is the backup module's list port: the snapshot age comes
// from a validated manifest, never from a file's mtime.
type DashboardBackups interface {
	List(context.Context) (BackupList, error)
}

// Dashboard composes the agent-side dashboard read. Each backend section is
// best effort: one failing read leaves its section empty and names the error,
// so the dashboard still answers while the backend is up but degraded.
type Dashboard struct {
	Backend    BackendControl
	Operator   OperatorClient
	Version    VersionSource
	PublicURLs []string
	Backups    DashboardBackups
	Now        func() time.Time
}

// DashboardBackendState is the process-control half.
type DashboardBackendState struct {
	Running bool   `json:"running"`
	PID     int    `json:"pid,omitempty"`
	State   string `json:"state,omitempty"`
}

// DashboardAPIState is the operator-API reachability and latency.
type DashboardAPIState struct {
	Reachable        bool   `json:"reachable"`
	PingMilliseconds *int64 `json:"ping_ms"`
}

// DashboardServer is one registered server with its live session count.
type DashboardServer struct {
	ServerID    int64  `json:"server_id"`
	Name        string `json:"name"`
	Open        bool   `json:"open"`
	OnlineCount int64  `json:"online_count"`
}

// DashboardEvent is one running or claim-window occurrence.
type DashboardEvent struct {
	ID              int64      `json:"id"`
	LogicalServerID int64      `json:"logical_server_id"`
	ActivityID      int64      `json:"activity_id"`
	State           string     `json:"state"`
	StartsAt        time.Time  `json:"starts_at"`
	EndsAt          *time.Time `json:"ends_at"`
}

// DashboardOTA is the active release set per lane.
type DashboardOTA struct {
	Code    *string  `json:"code"`
	Assets  *string  `json:"assets"`
	Catalog []string `json:"catalog"`
}

// DashboardAssets counts what the asset front served and could not serve; the
// counters come from ota.status (I11A_OTA_RELEASE_V1 ruling 7).
type DashboardAssets struct {
	ServedPaths  int   `json:"served_paths"`
	ServedHits   int64 `json:"served_hits"`
	MissingPaths int   `json:"missing_paths"`
	MissingHits  int64 `json:"missing_hits"`
}

// DashboardSnapshot is the age of the newest database snapshot, or null with
// the reason when the backup module is not built.
type DashboardSnapshot struct {
	AgeSeconds *int64 `json:"age_seconds"`
	Status     string `json:"status"`
}

// DashboardSummary is the dashboard.summary reply.
type DashboardSummary struct {
	Backend           DashboardBackendState `json:"backend"`
	API               DashboardAPIState     `json:"api"`
	Version           *operator.VersionInfo `json:"version"`
	PublicURLs        []string              `json:"public_urls"`
	Servers           []DashboardServer     `json:"servers"`
	Events            []DashboardEvent      `json:"events"`
	OTA               DashboardOTA          `json:"ota"`
	Assets            DashboardAssets       `json:"assets"`
	DBSnapshot        DashboardSnapshot     `json:"db_snapshot"`
	CloudflareMetrics string                `json:"cloudflare_metrics"`
	Errors            []string              `json:"errors,omitempty"`
}

// Summary folds the process, version, server, event, OTA and asset facts.
func (dashboard Dashboard) Summary(ctx context.Context) DashboardSummary {
	now := time.Now
	if dashboard.Now != nil {
		now = dashboard.Now
	}
	summary := DashboardSummary{
		PublicURLs:        orEmptyStrings(dashboard.PublicURLs),
		Servers:           []DashboardServer{},
		Events:            []DashboardEvent{},
		OTA:               DashboardOTA{Catalog: []string{}},
		CloudflareMetrics: CloudflareMetricsNotInV2,
	}
	if dashboard.Backend != nil {
		status := dashboard.Backend.Status()
		summary.Backend = DashboardBackendState{Running: status.Running, PID: status.PID, State: status.State}
	}
	if dashboard.Version != nil {
		started := now()
		version, versionErr := dashboard.Version.Version(ctx)
		elapsed := now().Sub(started).Milliseconds()
		if versionErr != nil {
			summary.Errors = append(summary.Errors, "version: "+versionErr.Error())
		} else {
			summary.API.Reachable = true
			summary.API.PingMilliseconds = &elapsed
			summary.Version = &version
		}
	}
	if dashboard.Operator != nil && summary.API.Reachable {
		summary.Servers = dashboard.servers(ctx, &summary)
		summary.Events = dashboard.events(ctx, summary.Servers)
		dashboard.otaAndAssets(ctx, &summary)
	}
	summary.DBSnapshot = snapshotAge(ctx, dashboard.Backups, now())
	return summary
}

func (dashboard Dashboard) servers(ctx context.Context, summary *DashboardSummary) []DashboardServer {
	page, err := readPage[operator.ServerListPage](dashboard.Operator, ctx, "server.list", "")
	if err != nil {
		summary.Errors = append(summary.Errors, "server.list: "+err.Error())
		return []DashboardServer{}
	}
	servers := make([]DashboardServer, 0, len(page.Servers))
	for index, server := range page.Servers {
		if index >= DashboardServerLimit {
			summary.Errors = append(summary.Errors, "server.list: truncated at "+strconv.Itoa(DashboardServerLimit)+" servers")
			break
		}
		servers = append(servers, DashboardServer{ServerID: server.ServerID, Name: server.Name, Open: server.Open, OnlineCount: server.OnlineCount})
	}
	return servers
}

type occurrencePage struct {
	Occurrences []struct {
		ID              int64      `json:"id"`
		LogicalServerID int64      `json:"logical_server_id"`
		ActivityID      int64      `json:"activity_id"`
		State           string     `json:"state"`
		StartsAt        time.Time  `json:"starts_at"`
		EndsAt          *time.Time `json:"ends_at"`
	} `json:"occurrences"`
}

func (dashboard Dashboard) events(ctx context.Context, servers []DashboardServer) []DashboardEvent {
	events := []DashboardEvent{}
	for _, server := range servers {
		query := url.Values{}
		query.Set("server", strconv.FormatInt(server.ServerID, 10))
		query.Set("limit", strconv.Itoa(DashboardEventLimit))
		page, err := readPage[occurrencePage](dashboard.Operator, ctx, "events.list", query.Encode())
		if err != nil {
			// A server without occurrences is the common case; report only a real refusal.
			continue
		}
		for _, occurrence := range page.Occurrences {
			if occurrence.State != "RUNNING" && occurrence.State != "CLAIM_WINDOW" {
				continue
			}
			events = append(events, DashboardEvent{ID: occurrence.ID, LogicalServerID: occurrence.LogicalServerID, ActivityID: occurrence.ActivityID, State: occurrence.State, StartsAt: occurrence.StartsAt.UTC(), EndsAt: utcTime(occurrence.EndsAt)})
		}
	}
	return events
}

func (dashboard Dashboard) otaAndAssets(ctx context.Context, summary *DashboardSummary) {
	status, err := readPage[otaStatusView](dashboard.Operator, ctx, "ota.status", "")
	if err != nil {
		summary.Errors = append(summary.Errors, "ota.status: "+err.Error())
		return
	}
	summary.OTA = DashboardOTA{Code: status.Active.Code, Assets: status.Active.Assets, Catalog: orEmptyStrings(status.Active.Catalog)}
	for _, served := range status.Served {
		summary.Assets.ServedPaths++
		summary.Assets.ServedHits += served.Hits
	}
	for _, miss := range status.Misses {
		summary.Assets.MissingPaths++
		summary.Assets.MissingHits += miss.Hits
	}
}

type otaStatusView struct {
	Active struct {
		Code    *string  `json:"code"`
		Assets  *string  `json:"assets"`
		Catalog []string `json:"catalog"`
	} `json:"active"`
	Served []struct {
		Hits int64 `json:"hits"`
	} `json:"served"`
	Misses []struct {
		Hits int64 `json:"hits"`
	} `json:"misses"`
}

// readPage runs one operator read and decodes a 200 reply. The caller decides
// whether a failed section fails the whole answer.
func readPage[T any](client OperatorClient, ctx context.Context, name, query string) (T, error) {
	var page T
	response, err := client.Read(ctx, name, query)
	if err != nil {
		return page, err
	}
	if response.Status != 200 {
		return page, errors.New("backend read " + name + " answered HTTP " + strconv.Itoa(response.Status))
	}
	if err := json.Unmarshal(response.Body, &page); err != nil {
		return page, err
	}
	return page, nil
}

// snapshotAge reads the backup list and takes the newest entry whose manifest
// and dump both verify, so a damaged or partial file never counts.
func snapshotAge(ctx context.Context, backups DashboardBackups, now time.Time) DashboardSnapshot {
	if backups == nil {
		return DashboardSnapshot{Status: "backup module not built"}
	}
	list, err := backups.List(ctx)
	if err != nil {
		return DashboardSnapshot{Status: "backup list unavailable"}
	}
	if len(list.Backups) == 0 {
		return DashboardSnapshot{Status: "no snapshots"}
	}
	for _, entry := range list.Backups {
		if entry.Damaged || entry.CreatedAt.IsZero() {
			continue
		}
		age := int64(now.Sub(entry.CreatedAt).Seconds())
		if age < 0 {
			age = 0
		}
		return DashboardSnapshot{AgeSeconds: &age, Status: "ok"}
	}
	return DashboardSnapshot{Status: "no valid snapshots"}
}

func utcTime(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	at := value.UTC()
	return &at
}

func orEmptyStrings(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}
