package otarelease

import (
	"context"
	"slices"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
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
}

type ActiveRow struct {
	Version string `json:"version"`
	Lane    string `json:"lane"`
}

// Status is the ota.status reply (I11A_OTA_RELEASE_V1 "Commands").
type Status struct {
	Revision    int64              `json:"revision"`
	Active      ActiveStatus       `json:"active"`
	Built       []BuiltRelease     `json:"built"`
	Activations []ActivationStatus `json:"activations"`
	Served      []ServedCounter    `json:"served"`
	Misses      []AssetMiss        `json:"misses"`
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
	return foldStatus(snapshot)
}

func foldStatus(snapshot StatusSnapshot) (Status, error) {
	status := Status{
		Revision:    snapshot.Revision,
		Built:       orEmpty(snapshot.Built),
		Activations: orEmpty(snapshot.Activations),
		Served:      orEmpty(snapshot.Served),
		Misses:      orEmpty(snapshot.Misses),
		Active:      ActiveStatus{Catalog: []string{}},
	}
	catalog := make([]domain.Version, 0, len(snapshot.Active))
	for _, row := range snapshot.Active {
		version, err := domain.ParseVersion(row.Version)
		if err != nil {
			return Status{}, err
		}
		lane, err := domain.ParseLane(row.Lane)
		if err != nil {
			return Status{}, err
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
	return status, nil
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
