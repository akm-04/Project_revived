// Package operatorcatalog is the compiled-content source of the operator item
// catalogue: it reads the embedded generated resource catalogue and the
// generated client item presentation rows and hands the application its plain
// document.
package operatorcatalog

import (
	"errors"
	"time"

	appcatalog "gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/content/builtin"
)

// Load builds the catalogue from the content this binary was compiled with.
func Load(generatedAt time.Time) (appcatalog.Document, error) {
	catalog, err := builtin.Load()
	if err != nil {
		return appcatalog.Document{}, err
	}
	resources := make([]appcatalog.Resource, 0, len(catalog.Resources.Resources))
	for _, definition := range catalog.Resources.Resources {
		resources = append(resources, appcatalog.Resource{
			DefinitionKey: definition.DefinitionKey,
			Class:         definition.Class,
			Activation:    definition.SettlementActivation,
			ItemID:        definition.ItemID,
			ItemType:      definition.ItemType,
			StackCap:      definition.StackCap,
			ResourceKey:   definition.ResourceKey,
			Reason:        definition.Reason,
		})
	}
	items := make([]appcatalog.ItemPresentation, 0, len(catalog.ItemPresentation.Items))
	for _, item := range catalog.ItemPresentation.Items {
		items = append(items, appcatalog.ItemPresentation{ID: item.ID, Name: item.Name, Icon: item.Icon, Quality: item.Quality})
	}
	if len(items) == 0 {
		return appcatalog.Document{}, errors.New("operator catalogue: compiled client item rows are missing")
	}
	return appcatalog.Build(resources, items, generatedAt)
}
