package operator

import (
	"context"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OperatorAPIRevision is the operator API contract revision (I11A_OPERATOR_COMMANDS_V1).
const OperatorAPIRevision = "1"

// VersionReader reads the highest applied migration.
type VersionReader interface {
	GooseVersionTx(context.Context, tx.Queryer) (int64, error)
}

// VersionInfo is GET /operator/v1/version (ruling 8). A value with no producer
// in this phase is null, never invented.
type VersionInfo struct {
	BackendVersion      *string `json:"backend_version"`
	GitCommit           *string `json:"git_commit"`
	Migration           int64   `json:"migration"`
	ContentRevision     *string `json:"content_revision"`
	OperatorAPIRevision string  `json:"operator_api_revision"`
}

// VersionService answers the version endpoint from the running binary's build
// info and the database's applied migration.
type VersionService struct {
	Runner          tx.Runner
	Operations      operation.Factory
	Reader          VersionReader
	BackendVersion  *string
	GitCommit       *string
	ContentRevision *string
}

func (s VersionService) Version(ctx context.Context) (VersionInfo, error) {
	if s.Reader == nil || s.Runner.DB == nil {
		return VersionInfo{}, ErrUnavailable
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return VersionInfo{}, err
	}
	var migration int64
	_, err = s.Runner.Run(ctx, current, readProfile("operator-version-read-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Reader.GooseVersionTx(ctx, scope.Tx)
		if readErr == nil {
			migration = loaded
		}
		return readErr
	})
	if err != nil {
		return VersionInfo{}, err
	}
	return VersionInfo{
		BackendVersion:      s.BackendVersion,
		GitCommit:           s.GitCommit,
		Migration:           migration,
		ContentRevision:     s.ContentRevision,
		OperatorAPIRevision: OperatorAPIRevision,
	}, nil
}
