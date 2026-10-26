package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) MissionDefinitionsTx(ctx context.Context, q tx.Queryer, revision string) ([]objective.MissionDefinition, error) {
	if q == nil || len(revision) != 64 {
		return nil, errors.New("content store: mission revision/queryer required")
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(d)-'revision_id' ORDER BY objective_id),'[]'::jsonb)::text
FROM gxb_content_objective_definitions d WHERE revision_id=$1 AND definition_revision='I9_MISSIONS_V1'`, revision).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var definitions []objective.MissionDefinition
	if err := json.Unmarshal([]byte(raw), &definitions); err != nil {
		return nil, err
	}
	if len(definitions) != 476 {
		return nil, errors.New("content store: incomplete mission catalog")
	}
	for _, definition := range definitions {
		if err := definition.Validate(); err != nil {
			return nil, err
		}
	}
	return definitions, nil
}
