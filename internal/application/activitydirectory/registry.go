package activitydirectory

import (
	"fmt"
	"math"
	"sort"
	"strings"
)

type Registry struct {
	ordered []Registration
	byTable map[int64]Registration
}

func NewRegistry(regs []Registration, content ContentCapabilities) (Registry, error) {
	out := Registry{byTable: make(map[int64]Registration, len(regs))}
	names := map[string]struct{}{}
	caps := map[string]struct{}{}
	for _, raw := range regs {
		r := raw
		r.Name = strings.TrimSpace(raw.Name)
		r.RuntimeCapability = strings.TrimSpace(raw.RuntimeCapability)
		r.ContentCapability = strings.TrimSpace(raw.ContentCapability)
		if r.Name != raw.Name || r.RuntimeCapability != raw.RuntimeCapability || (raw.ContentCapability != "" && r.ContentCapability != raw.ContentCapability) ||
			r.Name == "" || r.RuntimeCapability == "" || r.TableID <= 0 || r.TableID > math.MaxInt32 || nilProvider(r.Provider) {
			return Registry{}, ErrInvalidRegistration
		}
		if _, ok := names[r.Name]; ok {
			return Registry{}, fmt.Errorf("%w: duplicate provider name %q", ErrInvalidRegistration, r.Name)
		}
		if _, ok := caps[r.RuntimeCapability]; ok {
			return Registry{}, fmt.Errorf("%w: duplicate runtime capability %q", ErrInvalidRegistration, r.RuntimeCapability)
		}
		if _, ok := out.byTable[r.TableID]; ok {
			return Registry{}, fmt.Errorf("%w: duplicate table_id %d", ErrInvalidRegistration, r.TableID)
		}
		if r.ContentCapability != "" && (content == nil || !content.SupportsContentCapability(r.ContentCapability)) {
			return Registry{}, fmt.Errorf("%w: unavailable content capability %q", ErrInvalidRegistration, r.ContentCapability)
		}
		names[r.Name] = struct{}{}
		caps[r.RuntimeCapability] = struct{}{}
		out.byTable[r.TableID] = r
		out.ordered = append(out.ordered, r)
	}
	sort.Slice(out.ordered, func(i, j int) bool { return out.ordered[i].TableID < out.ordered[j].TableID })
	return out, nil
}

func (r Registry) Len() int { return len(r.ordered) }
func (r Registry) registration(tableID int64) (Registration, bool) {
	v, ok := r.byTable[tableID]
	return v, ok
}
