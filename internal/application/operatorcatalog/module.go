package operatorcatalog

import "gxb.local/backend/v2/internal/application/operator"

// Module is the catalog module (I11A_OPERATOR_COMMANDS_V1 ruling 9): the
// bounded catalogue search the GUI and CLI use. The catalogue itself is the
// exported content revision, not a tool-side list.
func Module() operator.Module {
	return operator.Module{
		ID:         "catalog",
		Title:      "Item catalogue",
		Role:       operator.RoleRoot,
		LogChannel: "catalog",
		Screen:     operator.Screen{Tab: "Catalogue", Columns: []string{"id", "kind", "grantable", "name", "icon"}},
		Reads: []operator.Read{
			{Name: "catalog.search", Help: "Search the operator catalogue by kind, text, item rarity and item type category.", Fields: []operator.Field{
				operator.NewField("kind", operator.FieldString, false, "kind filter"),
				operator.NewField("category", operator.FieldInt, false, "client item type category from the categories reply"),
				operator.NewField("sub_type", operator.FieldInt, false, "client item subtype within category; 8 is Skin and 0 the remaining consumables"),
				operator.NewField("query", operator.FieldString, false, "id or name text"),
				operator.NewField("rarity", operator.FieldInt, false, "item quality 1..6").Bounded(1, 6),
				operator.NewField("after", operator.FieldString, false, "last id of the previous page"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, MaxSearchLimit),
			}},
		},
	}
}
