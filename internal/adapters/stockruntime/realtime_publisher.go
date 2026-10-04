package stockruntime

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

var ErrInvalidRealtimePublicationHandle = errors.New("invalid realtime publication handle")

// RealtimePublisher is the protocol/adapter-edge publisher. It validates wire
// schema and physical role before using the existing per-socket writer handle.
// It owns no gameplay truth and contains no durable retry queue.
type RealtimePublisher struct {
	Registry wireRT.EventRegistry
	Limits   limits.Config
}

func (p RealtimePublisher) config() (limits.Config, error) {
	cfg := p.Limits
	if cfg.RealtimeBufferedBytes == 0 {
		cfg = limits.Default()
	}
	if err := cfg.Validate(); err != nil {
		return limits.Config{}, err
	}
	return cfg, nil
}

func (p RealtimePublisher) PublishDirect(ctx context.Context, h SessionHandle, mid uint16, params any) error {
	meta, ok := h.Metadata()
	if !ok {
		return ErrInvalidRealtimePublicationHandle
	}
	role := protocolRole(meta.PhysicalRole)
	if err := p.Registry.ValidateDirect(mid, role, params); err != nil {
		return err
	}
	cfg, err := p.config()
	if err != nil {
		return err
	}
	return h.Send(ctx, wireRT.Frame{MID: mid, Sequence: 0, Params: params}, cfg)
}

func (p RealtimePublisher) PublishNotice(ctx context.Context, h SessionHandle, parent uint16, namespace wireRT.NoticeNamespace, params any) error {
	meta, ok := h.Metadata()
	if !ok {
		return ErrInvalidRealtimePublicationHandle
	}
	role := protocolRole(meta.PhysicalRole)
	if err := p.Registry.ValidateNotice(parent, namespace, role, params); err != nil {
		return err
	}
	cfg, err := p.config()
	if err != nil {
		return err
	}
	return h.Send(ctx, wireRT.Frame{MID: parent, Sequence: 0, Params: params}, cfg)
}
