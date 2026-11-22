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
)

// Resource is one backend catalogue row the builder needs.
type Resource struct {
	DefinitionKey string
	Class         string
	Activation    string
	ItemID        int64
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
}

// Entry is one exported catalogue row. ID stays the backend definition key the
// grant command uses; ItemID is the numeric client item id when the definition
// has one.
type Entry struct {
	ID        string `json:"id"`
	Kind      string `json:"kind"`
	Grantable string `json:"grantable"`
	Reason    string `json:"reason,omitempty"`
	ItemID    *int64 `json:"item_id"`
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	Rarity    int64  `json:"rarity,omitempty"`
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
			itemID := resource.ItemID
			entry.ItemID = &itemID
		}
		if presentation, found := presentations[resource.ItemID]; found && resource.ItemID > 0 {
			entry.Name, entry.Icon, entry.Rarity = presentation.Name, presentation.Icon, presentation.Quality
		} else if presentation, found := ScalarPresentations[resource.ResourceKey]; found {
			entry.Name, entry.Icon = presentation.Name, presentation.Icon
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

// SearchFilter is the bounded catalog.search query.
type SearchFilter struct {
	Kind   string
	Query  string
	Rarity *int64
	Limit  int
	After  string
}

// SearchPage is one catalog.search reply.
type SearchPage struct {
	Entries         []Entry `json:"entries"`
	NextAfter       string  `json:"next_after,omitempty"`
	ContentRevision string  `json:"content_revision"`
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
		if needle != "" && !entry.matches(needle) {
			continue
		}
		matches = append(matches, entry)
		if len(matches) > filter.Limit {
			break
		}
	}
	page := SearchPage{Entries: matches, ContentRevision: d.ContentRevision}
	if len(matches) > filter.Limit {
		page.Entries = matches[:filter.Limit]
		page.NextAfter = page.Entries[len(page.Entries)-1].ID
	}
	if page.Entries == nil {
		page.Entries = []Entry{}
	}
	return page, nil
}
