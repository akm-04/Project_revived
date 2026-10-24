package characterasset

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// RosterMetricRow exposes identity and progression facts only. It deliberately
// carries no equipment, skin entitlement, cached force or display eligibility.
type RosterMetricRow struct {
	InstanceID, OriginTableID, TableID, Star, Version int64
	BeforeAwaken                                      int64
}
type RosterMetricPopulation struct {
	PlayerID    identity.PlayerID
	Family      string
	Revision    string
	ObservedAt  time.Time
	RootVersion int64
	Rows        []RosterMetricRow
}
type RosterMetricReader interface {
	ReadRosterMetricsTx(context.Context, CoherentReadScope, identity.PlayerID, string) (RosterMetricPopulation, error)
}

// Digest includes records as well as the root: evolving a girl need not change
// the root allocator version. Sorting makes the witness independent of SQL order.
func (p RosterMetricPopulation) Digest() string {
	rows := append([]RosterMetricRow{}, p.Rows...)
	sort.Slice(rows, func(i, j int) bool { return rows[i].InstanceID < rows[j].InstanceID })
	b, _ := json.Marshal(struct {
		Player           identity.PlayerID
		Family, Revision string
		Root             int64
		Rows             []RosterMetricRow
	}{p.PlayerID, p.Family, p.Revision, p.RootVersion, rows})
	d := sha256.Sum256(b)
	return hex.EncodeToString(d[:])
}
