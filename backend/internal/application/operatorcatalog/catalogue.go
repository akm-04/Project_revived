// Package operatorcatalog is the shared operator item catalogue
// (I11A_OPERATOR_COMMANDS_V1 ruling 9): the generated backend resource
// catalogue joined with the compiled client item rows, for the export file and
// the bounded catalog.search read. Grantability is the backend's own settlement
// rule, never a list kept here.
package operatorcatalog

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"slices"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/grant"
)

const (
	GrantableEnabled    = "ENABLED"
	GrantableFailClosed = "FAIL_CLOSED"

	DefaultSearchLimit = 50
	MaxSearchLimit     = 200
	maxQueryRunes      = 200

	// consumableItemType is item.lua's type column for consumables and its
	// subtype column's value 8 is a skin (app/common/tables item data).
	consumableItemType = 4
	skinSubType        = 8
)

// Resource is one backend catalogue row the builder needs.
type Resource struct {
	DefinitionKey string
	Class         string
	Activation    string
	ItemID        int64
	// ItemType is item.lua's type column for an item-backed definition, zero
	// when the generated catalogue carries none.
	ItemType int64
	// StackCap is the generated per-stack ceiling, zero when it carries none.
	StackCap int64
	// ResourceKey names the scalar/temporal resource (mana, exp, energy, ...);
	// it is empty for item-backed definitions.
	ResourceKey string
	Reason      string
}

// ItemPresentation is one compiled client item row, joined by item id.
type ItemPresentation struct {
	ID   int64
	Name string
	Icon string
	// Quality is the item.lua quality column: 0 unset, 1..6 the star rarity.
	Quality int64
	// SubType is the item.lua consumable subtype; 8 marks a skin item.
	SubType int64
	// SkinHeroName is the girl a skin item unlocks, resolved from the compiled
	// appearance catalogue; empty for every non-skin row.
	SkinHeroName string
}

// Entry is one exported catalogue row. ID stays the backend definition key the
// grant command uses; ItemID is the numeric client item id when the definition
// has one. ItemType, Category and StackCap are the item-backed presentation the
// picker filters on; a scalar resource carries none of them.
type Entry struct {
	ID        string `json:"id"`
	Kind      string `json:"kind"`
	Grantable string `json:"grantable"`
	Reason    string `json:"reason,omitempty"`
	ItemID    *int64 `json:"item_id"`
	ItemType  *int64 `json:"item_type,omitempty"`
	SubType   *int64 `json:"sub_type,omitempty"`
	Category  string `json:"category,omitempty"`
	StackCap  *int64 `json:"stack_cap,omitempty"`
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	Rarity    int64  `json:"rarity,omitempty"`
}

// Category is one picker bucket: the client item type, its client-derived
// label and how many catalogue rows it holds. SubType is set on the type-4
// buckets so the Skin bucket and the remaining Consumables stay separable.
type Category struct {
	ItemType int64  `json:"item_type"`
	SubType  *int64 `json:"sub_type,omitempty"`
	Label    string `json:"label"`
	Count    int    `json:"count"`
}

// categoryLabels are the client's own item type constants
// (tmp/virtualclient/src_64/app/common/enums.lua:508-524), lowercased to plain
// English. HUNQI is the client's name for a horcrux. A type the client names
// nowhere is "Other (type N)".
var categoryLabels = map[int64]string{
	1:  "Equipment",
	2:  "Reel",
	3:  "Soul stone",
	4:  "Consumables",
	5:  "Equipment fragment",
	6:  "Reel fragment",
	7:  "Pet stone",
	8:  "Pet equipment",
	11: "Avatar",
	12: "Avatar frame",
	13: "Book",
	14: "Book fragment",
	16: "Inscription",
	18: "Furniture",
	21: "Element equipment",
	24: "Horcrux",
}

func categoryLabel(itemType, subType int64) string {
	if itemType == consumableItemType && subType == skinSubType {
		return "Skin"
	}
	if label, found := categoryLabels[itemType]; found {
		return label
	}
	return "Other (type " + strconv.FormatInt(itemType, 10) + ")"
}

// Document is the export file and the read source.
type Document struct {
	ContentRevision string    `json:"content_revision"`
	GeneratedAt     time.Time `json:"generated_at"`
	Entries         []Entry   `json:"entries"`
}

// Build joins the two compiled sources and fixes the content revision over the
// entries alone, so a later export of unchanged content keeps the revision the
// operator's file comparison relies on.
func Build(resources []Resource, items []ItemPresentation, generatedAt time.Time) (Document, error) {
	if len(resources) == 0 {
		return Document{}, errors.New("operator catalogue: no backend resources")
	}
	presentations := make(map[int64]ItemPresentation, len(items))
	for _, item := range items {
		if item.ID <= 0 {
			return Document{}, errors.New("operator catalogue: invalid client item id")
		}
		presentations[item.ID] = item
	}
	entries := make([]Entry, 0, len(resources))
	seen := make(map[string]struct{}, len(resources))
	for _, resource := range resources {
		if strings.TrimSpace(resource.DefinitionKey) == "" || strings.TrimSpace(resource.Class) == "" {
			return Document{}, errors.New("operator catalogue: incomplete backend resource")
		}
		if _, duplicate := seen[resource.DefinitionKey]; duplicate {
			return Document{}, errors.New("operator catalogue: duplicate resource id " + resource.DefinitionKey)
		}
		seen[resource.DefinitionKey] = struct{}{}
		grantable, reason := grant.ResourceGrantable(resource.Class, resource.Activation)
		entry := Entry{ID: resource.DefinitionKey, Kind: resource.Class, Grantable: GrantableFailClosed, Reason: reason}
		if resource.Reason != "" {
			entry.Reason = resource.Reason
		}
		if grantable {
			entry.Grantable, entry.Reason = GrantableEnabled, ""
		}
		if resource.ItemID > 0 {
			itemID, itemType := resource.ItemID, resource.ItemType
			entry.ItemID, entry.ItemType = &itemID, &itemType
		}
		if resource.StackCap > 0 {
			stackCap := resource.StackCap
			entry.StackCap = &stackCap
		}
		if presentation, found := presentations[resource.ItemID]; found && resource.ItemID > 0 {
			entry.Name, entry.Icon, entry.Rarity = presentation.Name, presentation.Icon, presentation.Quality
			if presentation.SubType > 0 {
				subType := presentation.SubType
				entry.SubType = &subType
			}
			if presentation.SubType == skinSubType && presentation.SkinHeroName != "" {
				entry.Name = presentation.Name + " (" + presentation.SkinHeroName + " skin)"
			}
		} else if presentation, found := ScalarPresentations[resource.ResourceKey]; found {
			entry.Name, entry.Icon = presentation.Name, presentation.Icon
		}
		if resource.ItemID > 0 {
			subType := int64(0)
			if entry.SubType != nil {
				subType = *entry.SubType
			}
			entry.Category = categoryLabel(resource.ItemType, subType)
		}
		entries = append(entries, entry)
	}
	sort.Slice(entries, func(i, j int) bool { return entries[i].ID < entries[j].ID })
	revision, err := entriesRevision(entries)
	if err != nil {
		return Document{}, err
	}
	return Document{ContentRevision: revision, GeneratedAt: generatedAt.UTC(), Entries: entries}, nil
}

func entriesRevision(entries []Entry) (string, error) {
	encoded, err := json.Marshal(entries)
	if err != nil {
		return "", err
	}
	digest := sha256.Sum256(encoded)
	return hex.EncodeToString(digest[:]), nil
}

// matches reports whether the lowercased query names this entry. An all-digit
// query also matches the numeric client item id exactly.
func (entry Entry) matches(needle string) bool {
	if strings.Contains(strings.ToLower(entry.Name), needle) || strings.Contains(strings.ToLower(entry.ID), needle) {
		return true
	}
	if strings.Contains(strings.ToLower(entry.Category), needle) {
		return true
	}
	numeric, ok := parseNumeric(needle)
	return ok && entry.ItemID != nil && *entry.ItemID == numeric
}

func parseNumeric(text string) (int64, bool) {
	if text == "" {
		return 0, false
	}
	for _, digit := range text {
		if digit < '0' || digit > '9' {
			return 0, false
		}
	}
	value, err := strconv.ParseInt(text, 10, 64)
	if err != nil {
		return 0, false
	}
	return value, true
}

// Lookup returns one entry by its backend definition key.
func (d Document) Lookup(id string) (Entry, bool) {
	for _, entry := range d.Entries {
		if entry.ID == id {
			return entry, true
		}
	}
	return Entry{}, false
}

// GrantLine turns a catalogue id into the grant line the owner validates. The
// id is refused when the catalogue does not carry it or the backend cannot
// grant it.
func (d Document) GrantLine(id string, amount int64) (grant.Line, *Entry, bool) {
	entry, found := d.Lookup(id)
	if !found || entry.Grantable != GrantableEnabled {
		return grant.Line{}, nil, false
	}
	switch entry.Kind {
	case string(grant.StackItem):
		itemID, ok := parseItemID(entry.ID, "stack_item:")
		if !ok {
			return grant.Line{}, nil, false
		}
		return grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: amount}, &entry, true
	case string(grant.ScalarCurrency):
		key, ok := strings.CutPrefix(entry.ID, "scalar_currency:")
		if !ok || key == "" {
			return grant.Line{}, nil, false
		}
		return grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: amount}, &entry, true
	case string(grant.PlayerExp):
		if entry.ID != "player_exp:exp" {
			return grant.Line{}, nil, false
		}
		return grant.Line{Kind: grant.PlayerExp, Amount: amount}, &entry, true
	case string(grant.Temporal):
		key, ok := strings.CutPrefix(entry.ID, "temporal:")
		if !ok || key == "" {
			return grant.Line{}, nil, false
		}
		return grant.Line{Kind: grant.Temporal, ResourceKey: key, Amount: amount}, &entry, true
	}
	return grant.Line{}, nil, false
}

func parseItemID(id, prefix string) (int64, bool) {
	text, found := strings.CutPrefix(id, prefix)
	if !found || text == "" {
		return 0, false
	}
	var value int64
	for _, digit := range text {
		if digit < '0' || digit > '9' {
			return 0, false
		}
		value = value*10 + int64(digit-'0')
	}
	return value, value > 0
}

// SearchFilter is the bounded catalog.search query. Category narrows the page
// to one client item type; SubType 8 selects skins and SubType 0 the remaining
// consumables.
type SearchFilter struct {
	Kind     string
	Query    string
	Rarity   *int64
	Category *int64
	SubType  *int64
	Limit    int
	After    string
}

// SearchPage is one catalog.search reply. Categories carries the whole
// document's item type buckets and counts, so the picker fills its select from
// the same round trip.
type SearchPage struct {
	Entries         []Entry    `json:"entries"`
	Categories      []Category `json:"categories"`
	NextAfter       string     `json:"next_after,omitempty"`
	ContentRevision string     `json:"content_revision"`
}

// categories lists the document's item-backed buckets by item type, whatever
// the page filter is; a scalar resource has no item type and no bucket.
type categoryKey struct {
	itemType int64
	subType  int64
}

func (entry Entry) categoryBucket() (int64, int64) {
	subType := int64(0)
	if entry.SubType != nil {
		subType = *entry.SubType
	}
	if *entry.ItemType != consumableItemType || subType != skinSubType {
		subType = 0
	}
	return *entry.ItemType, subType
}

func (d Document) categories() []Category {
	counts := map[categoryKey]int{}
	for _, entry := range d.Entries {
		if entry.ItemType == nil {
			continue
		}
		itemType, subType := entry.categoryBucket()
		counts[categoryKey{itemType: itemType, subType: subType}]++
	}
	keys := make([]categoryKey, 0, len(counts))
	for key := range counts {
		keys = append(keys, key)
	}
	slices.SortFunc(keys, func(left, right categoryKey) int {
		if left.itemType != right.itemType {
			return int(left.itemType - right.itemType)
		}
		return int(left.subType - right.subType)
	})
	categories := make([]Category, 0, len(keys))
	for _, key := range keys {
		category := Category{ItemType: key.itemType, Label: categoryLabel(key.itemType, key.subType), Count: counts[key]}
		if key.itemType == consumableItemType {
			subType := key.subType
			category.SubType = &subType
		}
		categories = append(categories, category)
	}
	return categories
}

// Search pages the document by id, after the last id of the previous page.
func (d Document) Search(filter SearchFilter) (SearchPage, error) {
	if filter.Limit == 0 {
		filter.Limit = DefaultSearchLimit
	}
	if filter.Limit < 1 || filter.Limit > MaxSearchLimit {
		return SearchPage{}, errors.New("catalog.search limit must be between 1 and 200")
	}
	if utf8.RuneCountInString(filter.Query) > maxQueryRunes {
		return SearchPage{}, errors.New("catalog.search query is too long")
	}
	needle := strings.ToLower(strings.TrimSpace(filter.Query))
	matches := make([]Entry, 0, filter.Limit+1)
	for _, entry := range d.Entries {
		if filter.After != "" && entry.ID <= filter.After {
			continue
		}
		if filter.Kind != "" && entry.Kind != filter.Kind {
			continue
		}
		if filter.Rarity != nil && (entry.Rarity < 1 || entry.Rarity != *filter.Rarity) {
			continue
		}
		if filter.Category != nil && (entry.ItemType == nil || *entry.ItemType != *filter.Category) {
			continue
		}
		if filter.SubType != nil {
			subType := int64(0)
			if entry.SubType != nil {
				subType = *entry.SubType
			}
			// A zero sub_type filter is the remaining consumables, i.e.
			// everything that is not a skin.
			if *filter.SubType == 0 {
				if subType == skinSubType {
					continue
				}
			} else if subType != *filter.SubType {
				continue
			}
		}
		if needle != "" && !entry.matches(needle) {
			continue
		}
		matches = append(matches, entry)
		if len(matches) > filter.Limit {
			break
		}
	}
	page := SearchPage{Entries: matches, Categories: d.categories(), ContentRevision: d.ContentRevision}
	if len(matches) > filter.Limit {
		page.Entries = matches[:filter.Limit]
		page.NextAfter = page.Entries[len(page.Entries)-1].ID
	}
	if page.Entries == nil {
		page.Entries = []Entry{}
	}
	return page, nil
}
