package mentor

import (
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var ErrRelationship = errors.New("mentor: invalid relationship proof")
var ErrRelationshipConflict = errors.New("mentor: relationship changed")

type Relationship struct {
	ID                 ids.UUID
	Mentor             identity.PlayerID
	Student            identity.PlayerID
	Server             identity.LogicalServerID
	ContentRevision    string
	PolicyVersion      string
	AcceptedAt         time.Time
	EndedAt            *time.Time
	Intimacy           int64
	LastIntimacyDay    string
	BackgroundBaseline int64
	Version            int64
}

func (record Relationship) Validate() error {
	if record.ID.IsZero() || !record.Mentor.Valid() || !record.Student.Valid() || record.Mentor == record.Student || !record.Server.Valid() || logicalserver.PlayerRegion(record.Mentor) != record.Server || logicalserver.PlayerRegion(record.Student) != record.Server {
		return ErrRelationship
	}
	if len(record.ContentRevision) != 64 || strings.ToLower(record.ContentRevision) != record.ContentRevision || record.PolicyVersion != MinimumLevelGapPolicy || record.Version < 1 || record.AcceptedAt.IsZero() || record.AcceptedAt.Location() != time.UTC {
		return ErrRelationship
	}
	if record.Intimacy < 0 || record.BackgroundBaseline < 0 {
		return ErrRelationship
	}
	if _, err := hex.DecodeString(record.ContentRevision); err != nil {
		return ErrRelationship
	}
	if record.EndedAt == nil {
		return nil
	}
	if record.Version < 2 || record.EndedAt.IsZero() || record.EndedAt.Location() != time.UTC || record.EndedAt.Before(record.AcceptedAt) {
		return ErrRelationship
	}
	return nil
}
