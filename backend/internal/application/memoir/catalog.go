package memoir

import (
	"context"
	"log"

	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// catalog is the pinned revision under the operator overlay. An unreadable or
// rejected overlay is logged and the source catalog serves, so a bad operator
// edit never stops the mode.
func (mode Mode) catalog(ctx context.Context, query tx.Queryer, revision string) (memoir.Catalog, error) {
	catalog, err := mode.Content.MemoirCatalogTx(ctx, query, revision)
	if err != nil {
		return catalog, err
	}
	tuning, found, err := mode.Store.TuningTx(ctx, query)
	if err != nil || !found {
		return catalog, nil
	}
	tuned, err := catalog.Tune(tuning)
	if err != nil {
		log.Printf("memoir: operator tuning v%d rejected, source catalog serves: %v", tuning.Version, err)
		return catalog, nil
	}
	return tuned, nil
}
