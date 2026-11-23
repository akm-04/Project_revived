package otarelease

import (
	"context"
	"math"
	"slices"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Status list bounds; the store asks for one more row so the fold can report
// a truncated list (I11A_OPERATOR_COMMANDS_V1 ruling 3, bounded reads).
const (
	StatusActiveLimit     = 64
	StatusBuiltLimit      = 200
	StatusActivationLimit = 20
	StatusServedLimit     = 50
	StatusMissesLimit     = 50
	// StatusVersionLimit bounds the release-number read behind next_version. The
	// rows come newest first, so a cut cannot hide the highest number.
	StatusVersionLimit = 512
)

// StatusStore is the ota.status read side.
type StatusStore interface {
	ReadStatusTx(context.Context, tx.Queryer) (StatusSnapshot, error)
}

// StatusSnapshot is the bounded raw read; Status folds the active lanes.
type StatusSnapshot struct {
	Revision    int64              `json:"revision"`
	Active      []ActiveRow        `json:"active"`
	Built       []BuiltRelease     `json:"built"`
	Activations []ActivationStatus `json:"activations"`
	Served      []ServedCounter    `json:"served"`
	Misses      []AssetMiss        `json:"misses"`
	// Versions is every release number of every lane and state, newest first, so
	// next_version counts one shared counter across lanes (G44).
	Versions []string `json:"versions"`
}

type ActiveRow struct {
	Version     string     `json:"version"`
	Lane        string     `json:"lane"`
	TotalSize   int64      `json:"total_size"`
	PublishedAt *time.Time `json:"published_at"`
}

// Status is the ota.status reply (I11A_OTA_RELEASE_V1 "Commands").
type Status struct {
	Revision    int64              `json:"revision"`
	Active      ActiveStatus       `json:"active"`
	Lanes       []LaneSummary      `json:"lanes"`
	Built       []BuiltRelease     `json:"built"`
	Activations []ActivationStatus `json:"activations"`
	Served      []ServedCounter    `json:"served"`
	Misses      []AssetMiss        `json:"misses"`
	Truncated   TruncatedLists     `json:"truncated"`
	// NextVersion is the highest release number of any lane and state plus one,
	// empty when there is no release (G44).
	NextVersion string `json:"next_version"`
	// Settings are the effective live values, including a field a client or an
	// operator sees without restarting the API (L4h).
	Settings domain.Settings `json:"settings"`
}

// LaneSummary is one OTA lane's overview (OPERATOR_GUI_V2 design item 5):
// the active version and the newest BUILT release that is not published yet.
type LaneSummary struct {
	Lane          string     `json:"lane"`
	ActiveVersion *string    `json:"active_version"`
	PublishedAt   *time.Time `json:"published_at,omitempty"`
	BuiltVersion  *string    `json:"built_not_published,omitempty"`
	BuiltAt       *time.Time `json:"built_at,omitempty"`
	Size          int64      `json:"size,omitempty"`
}

// TruncatedLists says which ota.status list hit its bound and was cut.
type TruncatedLists struct {
	Active      bool `json:"active"`
	Built       bool `json:"built"`
	Activations bool `json:"activations"`
	Served      bool `json:"served"`
	Misses      bool `json:"misses"`
}

type ActiveStatus struct {
	Code    *string  `json:"code"`
	Assets  *string  `json:"assets"`
	Catalog []string `json:"catalog"`
}

type BuiltRelease struct {
	Version   string    `json:"version"`
	Lane      string    `json:"lane"`
	TotalSize int64     `json:"total_size"`
	BuiltAt   time.Time `json:"built_at"`
}

type ActivationStatus struct {
	ID         int64     `json:"id"`
	Version    string    `json:"version"`
	Action     string    `json:"action"`
	CommandKey string    `json:"command_key"`
	At         time.Time `json:"at"`
}

type ServedCounter struct {
	Path string `json:"path"`
	Hits int64  `json:"hits"`
}

type AssetMiss struct {
	Path      string    `json:"path"`
	MD5       string    `json:"md5"`
	FirstSeen time.Time `json:"first_seen"`
	LastSeen  time.Time `json:"last_seen"`
	Hits      int64     `json:"hits"`
	FirstUID  *string   `json:"first_uid"`
}

// StatusService reads ota.status in one read-only transaction.
type StatusService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      StatusStore
	Live       *SettingsValue
}

func (s StatusService) Status(ctx context.Context) (Status, error) {
	if s.Store == nil || s.Runner.DB == nil {
		return Status{}, ErrUnavailable
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return Status{}, err
	}
	var snapshot StatusSnapshot
	_, err = s.Runner.Run(ctx, current, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Store.ReadStatusTx(ctx, scope.Tx)
		if readErr == nil {
			snapshot = loaded
		}
		return readErr
	})
	if err != nil {
		return Status{}, err
	}
	status, err := foldStatus(snapshot)
	if err != nil {
		return Status{}, err
	}
	status.Settings = s.Live.Get()
	return status, nil
}

func foldStatus(snapshot StatusSnapshot) (Status, error) {
	nextVersion, err := nextReleaseVersion(snapshot.Versions)
	if err != nil {
		return Status{}, err
	}
	active, activeTruncated := bounded(snapshot.Active, StatusActiveLimit)
	built, builtTruncated := bounded(snapshot.Built, StatusBuiltLimit)
	activations, activationsTruncated := bounded(snapshot.Activations, StatusActivationLimit)
	served, servedTruncated := bounded(snapshot.Served, StatusServedLimit)
	misses, missesTruncated := bounded(snapshot.Misses, StatusMissesLimit)
	status := Status{
		Revision:    snapshot.Revision,
		Built:       orEmpty(built),
		Activations: orEmpty(activations),
		Served:      orEmpty(served),
		Misses:      orEmpty(misses),
		Active:      ActiveStatus{Catalog: []string{}},
		NextVersion: nextVersion,
		Truncated: TruncatedLists{
			Active:      activeTruncated,
			Built:       builtTruncated,
			Activations: activationsTruncated,
			Served:      servedTruncated,
			Misses:      missesTruncated,
		},
	}
	catalog := make([]domain.Version, 0, len(active))
	highestActive := make(map[string]domain.Version, len(active))
	activeRows := make(map[string]ActiveRow, len(active))
	for _, row := range active {
		version, err := domain.ParseVersion(row.Version)
		if err != nil {
			return Status{}, err
		}
		lane, err := domain.ParseLane(row.Lane)
		if err != nil {
			return Status{}, err
		}
		current, seen := highestActive[string(lane)]
		if !seen || version.Compare(current) > 0 {
			highestActive[string(lane)] = version
			activeRows[string(lane)] = row
		}
		switch lane {
		case domain.LaneCode:
			status.Active.Code = keepNewer(status.Active.Code, version)
		case domain.LaneAssets:
			status.Active.Assets = keepNewer(status.Active.Assets, version)
		case domain.LaneCatalog:
			catalog = append(catalog, version)
		}
	}
	slices.SortFunc(catalog, domain.Version.Compare)
	for _, version := range catalog {
		status.Active.Catalog = append(status.Active.Catalog, version.String())
	}
	highestBuilt := make(map[string]domain.Version, len(snapshot.Built))
	builtRows := make(map[string]BuiltRelease, len(snapshot.Built))
	for _, release := range snapshot.Built {
		version, err := domain.ParseVersion(release.Version)
		if err != nil {
			return Status{}, err
		}
		if _, err := domain.ParseLane(release.Lane); err != nil {
			return Status{}, err
		}
		current, seen := highestBuilt[release.Lane]
		if !seen || version.Compare(current) > 0 {
			highestBuilt[release.Lane] = version
			builtRows[release.Lane] = release
		}
	}
	for _, lane := range []domain.Lane{domain.LaneCode, domain.LaneAssets, domain.LaneCatalog} {
		summary := LaneSummary{Lane: string(lane)}
		if version, seen := highestActive[string(lane)]; seen {
			text := version.String()
			summary.ActiveVersion = &text
			summary.PublishedAt = activeRows[string(lane)].PublishedAt
		}
		if version, seen := highestBuilt[string(lane)]; seen {
			text := version.String()
			summary.BuiltVersion = &text
			release := builtRows[string(lane)]
			summary.Size = release.TotalSize
			builtAt := release.BuiltAt.UTC()
			summary.BuiltAt = &builtAt
		}
		status.Lanes = append(status.Lanes, summary)
	}
	return status, nil
}

// nextReleaseVersion is the one shared counter: the highest number of any lane
// and state, plus one on its last component. Parsing and comparison happen here
// in Go so 1.631.10 sorts above 1.631.9 (G44).
func nextReleaseVersion(versions []string) (string, error) {
	var highest *domain.Version
	for _, text := range versions {
		version, err := domain.ParseVersion(text)
		if err != nil {
			return "", err
		}
		if highest == nil || version.Compare(*highest) > 0 {
			candidate := version
			highest = &candidate
		}
	}
	if highest == nil || highest.Patch == math.MaxInt64 {
		return "", nil
	}
	return domain.Version{Major: highest.Major, Minor: highest.Minor, Patch: highest.Patch + 1}.String(), nil
}

func keepNewer(current *string, candidate domain.Version) *string {
	if current == nil {
		text := candidate.String()
		return &text
	}
	parsed, err := domain.ParseVersion(*current)
	if err != nil || candidate.Compare(parsed) > 0 {
		text := candidate.String()
		return &text
	}
	return current
}

func orEmpty[T any](values []T) []T {
	if values == nil {
		return []T{}
	}
	return values
}

func bounded[T any](values []T, bound int) ([]T, bool) {
	if len(values) <= bound {
		return values, false
	}
	return values[:bound], true
}
