package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	backpackproj "gxb.local/backend/v2/internal/projection/backpack"
)

type SpiritBackpackSnapshotPort interface {
	BackpackSnapshot(context.Context, identity.ActorContext, operation.Context) (app.BackpackSnapshot, error)
}
type SpiritBackpackProjection struct{ Service SpiritBackpackSnapshotPort }

func (s SpiritBackpackProjection) Backpack(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	v, e := s.Service.BackpackSnapshot(c, a, op)
	if e != nil {
		return nil, e
	}
	body, e := backpackproj.Build(v.Stacks)
	if e != nil {
		return nil, e
	}
	body["spirit_list"] = v.Spirits
	return body, nil
}
