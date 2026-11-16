package publicprofile

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type ownerFailureMetricReader struct{ err error }

func (r ownerFailureMetricReader) ReadMetricsTx(context.Context, tx.Queryer, MetricRequest) ([]MetricObservation, error) {
	return nil, r.err
}

type unknownBasisMetricReader struct{ unknown map[int64]bool }

func (r unknownBasisMetricReader) ReadMetricsTx(_ context.Context, _ tx.Queryer, req MetricRequest) ([]MetricObservation, error) {
	out := make([]MetricObservation, 0, len(req.IDs))
	for _, id := range req.IDs {
		if r.unknown[id] {
			return nil, character.ErrRawAwakeningUnavailable
		}
		out = append(out, MetricObservation{Owner: "I5.Player", PlayerID: req.PlayerID, FieldID: id, Value: 5, Semantics: CreationMetricSemantics, SourceVersion: 1, ContentRevision: req.ContentRevision, ObservedAt: req.ObservedAt.UTC()})
	}
	return out, nil
}

func TestAllShowTypesPropagatesOwnerFailure(t *testing.T) {
	s := ReadService{Metrics: ownerFailureMetricReader{err: ErrContent}}
	if _, e := s.allShowTypes(context.Background(), tx.Scope{}, 1, "rev", time.Unix(100, 0)); !errors.Is(e, ErrContent) {
		t.Fatalf("owner failure masked: %v", e)
	}
}

func TestAllShowTypesOmitsOnlyExplicitUnknownBasis(t *testing.T) {
	unknown := map[int64]bool{}
	for id := int64(1001); id <= 1010; id++ {
		unknown[id] = true
	}
	got, e := (ReadService{Metrics: unknownBasisMetricReader{unknown: unknown}}).allShowTypes(context.Background(), tx.Scope{}, 1, "rev", time.Unix(100, 0))
	if e != nil || len(got) != 1 || got["1011"] != 5 {
		t.Fatalf("unknown basis handling %v %v", got, e)
	}
}
