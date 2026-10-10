package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

const CreationMetricSemantics = "I7B_METRIC_CANONICAL_PLAYER_CREATED_AT_UNIX_SECONDS_V1"

type MetricRequest struct {
	PlayerID        identity.PlayerID
	IDs             []int64
	ContentRevision string
	ObservedAt      time.Time
}
type MetricObservation struct {
	Owner           string            `json:"owner"`
	PlayerID        identity.PlayerID `json:"player_id"`
	FieldID         int64             `json:"field_id"`
	Value           int64             `json:"value"`
	Semantics       string            `json:"semantics"`
	SourceVersion   int64             `json:"source_version"`
	ContentRevision string            `json:"content_revision"`
	ObservedAt      time.Time         `json:"observed_at"`
}
type MetricReader interface {
	ReadMetricsTx(context.Context, tx.Queryer, MetricRequest) ([]MetricObservation, error)
}
type CanonicalCreationMetricProvider struct{ Players i5.PublicPlayerBasisReader }

func (p CanonicalCreationMetricProvider) ReadMetricsTx(c context.Context, t tx.Queryer, r MetricRequest) ([]MetricObservation, error) {
	if t == nil || p.Players == nil || !r.PlayerID.Valid() || r.ObservedAt.IsZero() {
		return nil, ErrContent
	}
	out := []MetricObservation{}
	if len(r.IDs) == 0 {
		return out, nil
	}
	for _, id := range r.IDs {
		if id != 1011 {
			return nil, ErrContent
		}
	}
	basis, e := p.Players.ReadPublicPlayerBasisTx(c, t, r.PlayerID)
	if e != nil || basis.Validate() != nil || basis.Profile.PlayerID != r.PlayerID {
		return nil, ErrContent
	}
	v := basis.Profile.CreatedAt.Unix()
	if v < -9007199254740991 || v > 9007199254740991 {
		return nil, ErrContent
	}
	for _, id := range r.IDs {
		out = append(out, MetricObservation{Owner: "I5.Player", PlayerID: r.PlayerID, FieldID: id, Value: v, Semantics: CreationMetricSemantics, SourceVersion: basis.Profile.StateVersion, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()})
	}
	return out, nil
}
func metricValues(r MetricRequest, obs []MetricObservation) (map[string]int64, error) {
	if len(obs) != len(r.IDs) {
		return nil, ErrContent
	}
	wanted := map[int64]bool{}
	for _, id := range r.IDs {
		if wanted[id] {
			return nil, ErrContent
		}
		wanted[id] = true
	}
	out := map[string]int64{}
	for _, v := range obs {
		if !wanted[v.FieldID] || v.PlayerID != r.PlayerID || v.ContentRevision != r.ContentRevision || !v.ObservedAt.Equal(r.ObservedAt) || v.SourceVersion <= 0 || v.FieldID != 1011 || v.Owner != "I5.Player" || v.Semantics != CreationMetricSemantics || v.Value < -9007199254740991 || v.Value > 9007199254740991 {
			return nil, ErrContent
		}
		delete(wanted, v.FieldID)
		out[strconv.FormatInt(v.FieldID, 10)] = v.Value
	}
	return out, nil
}
