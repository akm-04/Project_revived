package activitydirectory

import (
	"context"
	"errors"
	"fmt"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/identity"
)

type Directory struct{ Registry Registry }

func (d Directory) ListAt(ctx context.Context, actor identity.ActorContext, at time.Time) ([]activity.Projection, error) {
	if err := validateActor(actor); err != nil {
		return nil, err
	}
	if d.Registry.Len() == 0 {
		return []activity.Projection{}, nil
	}
	pc := ProjectionContext{Actor: actor, DecisionAt: at.UTC()}
	if err := pc.Validate(); err != nil {
		return nil, err
	}
	out := make([]activity.Projection, 0, d.Registry.Len())
	for _, r := range d.Registry.ordered {
		p, ok, err := r.Provider.Project(ctx, pc)
		if err != nil {
			return nil, fmt.Errorf("activity provider %s: %w", r.Name, err)
		}
		if !ok {
			continue
		}
		cp, err := validateClone(r, p)
		if err != nil {
			return nil, err
		}
		out = append(out, cp)
	}
	return out, nil
}

func (d Directory) LookupAt(ctx context.Context, actor identity.ActorContext, at time.Time, tableID int64) (activity.Projection, bool, error) {
	if err := validateActor(actor); err != nil {
		return activity.Projection{}, false, err
	}
	r, ok := d.Registry.registration(tableID)
	if !ok {
		return activity.Projection{}, false, nil
	}
	pc := ProjectionContext{Actor: actor, DecisionAt: at.UTC()}
	if err := pc.Validate(); err != nil {
		return activity.Projection{}, false, err
	}
	p, present, err := r.Provider.Project(ctx, pc)
	if err != nil {
		return activity.Projection{}, false, fmt.Errorf("activity provider %s: %w", r.Name, err)
	}
	if !present {
		return activity.Projection{}, false, nil
	}
	cp, err := validateClone(r, p)
	return cp, err == nil, err
}

func validateClone(r Registration, p activity.Projection) (activity.Projection, error) {
	if p.TableID != r.TableID {
		return activity.Projection{}, fmt.Errorf("%w: provider=%s registered=%d projected=%d", ErrProviderMismatch, r.Name, r.TableID, p.TableID)
	}
	if err := p.Validate(); err != nil {
		return activity.Projection{}, err
	}
	details, err := cloneDetails(p.Details)
	if err != nil {
		return activity.Projection{}, err
	}
	p.Details = details
	return p, nil
}

type Runtime struct {
	Directory Directory
	Time      appgeneration.TimeAuthority
}

func (s Runtime) List(ctx context.Context, actor identity.ActorContext) ([]activity.Projection, error) {
	if s.Directory.Registry.Len() == 0 {
		// No child provider is evaluated, so no authoritative gameplay instant is sampled.
		return s.Directory.ListAt(ctx, actor, time.Time{})
	}
	if s.Time == nil {
		return nil, errors.New("activity directory: nil time authority")
	}
	at, err := s.Time.Now(ctx)
	if err != nil {
		return nil, err
	}
	return s.Directory.ListAt(ctx, actor, at)
}

func (s Runtime) Lookup(ctx context.Context, actor identity.ActorContext, tableID int64) (activity.Projection, bool, error) {
	if err := validateActor(actor); err != nil {
		return activity.Projection{}, false, err
	}
	if _, ok := s.Directory.Registry.registration(tableID); !ok {
		return activity.Projection{}, false, nil
	}
	if s.Time == nil {
		return activity.Projection{}, false, errors.New("activity directory: nil time authority")
	}
	at, err := s.Time.Now(ctx)
	if err != nil {
		return activity.Projection{}, false, err
	}
	return s.Directory.LookupAt(ctx, actor, at, tableID)
}
