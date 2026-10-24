package dormhouse

import (
	"math"
	"sort"
	"strconv"
	"strings"
)

type Placement struct {
	Key, Parent                                                           string
	ItemID, X, Y, Flip, Panel, Layer, AbsoluteX, AbsoluteY, Length, Width int64
}
type LayoutResult struct {
	Placements []Placement
	Comfort    int64
	Used       map[int64]int64
	// InventoryMinimum excludes one source-built-in dresser per purchased room.
	InventoryMinimum  map[int64]int64
	FreeResidentCells int64
}

func ParsePlacementKey(key string) (Placement, error) {
	var out Placement
	parts := strings.Split(key, "|")
	if len(parts) == 0 || len(parts) > 5 {
		return out, ErrInvalidLayout
	}
	out.Key = key
	if len(parts) > 1 {
		out.Parent = strings.Join(parts[:len(parts)-1], "|")
	}
	for _, part := range parts {
		values := strings.Split(part, "#")
		if len(values) != 4 {
			return Placement{}, ErrInvalidLayout
		}
		var n [4]int64
		for i, v := range values {
			parsed, e := strconv.ParseInt(v, 10, 64)
			if e != nil || strconv.FormatInt(parsed, 10) != v {
				return Placement{}, ErrInvalidLayout
			}
			n[i] = parsed
		}
		if n[0] <= 0 || n[1] < 1 || n[2] < 1 || (n[3] != 0 && n[3] != 1) {
			return Placement{}, ErrInvalidLayout
		}
		out.ItemID = n[0]
		out.X = n[1] - 1
		out.Y = n[2] - 1
		out.Flip = n[3]
	}
	return out, nil
}
func furniturePanel(f FurnitureRule, flip int64) (int64, error) {
	if len(f.Panels) == 0 {
		return 0, ErrUnqualified
	}
	panel := f.Panels[0]
	if panel != 1 {
		panel = 2
		if flip == 1 {
			for _, p := range f.Panels {
				if p == 3 {
					panel = 3
				}
			}
		}
	}
	if panel < 1 || panel > 3 {
		return 0, ErrUnqualified
	}
	return panel, nil
}

// ValidateLayout follows the client packed parent graph and floor-mask layers.
// It does not consume inventory or infer inventory from placement. The caller
// checks InventoryMinimum against I5 total stock under the common economy lock.
func (c Catalog) ValidateLayout(tableID, appliedLevel int64, record map[string]string) (LayoutResult, error) {
	var out LayoutResult
	room, ok := c.Rooms[tableID]
	if !ok {
		return out, ErrUnqualified
	}
	typ, ok := c.Types[room.MainType]
	if !ok {
		return out, ErrUnqualified
	}
	length, width, height, e := c.RoomSize(tableID, appliedLevel)
	if e != nil {
		return out, e
	}
	keys := make([]string, 0, len(record))
	for k := range record {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool {
		a, b := strings.Count(keys[i], "|"), strings.Count(keys[j], "|")
		if a != b {
			return a < b
		}
		return keys[i] < keys[j]
	})
	placements := map[string]Placement{}
	children := map[string]map[string]bool{}
	for _, key := range keys {
		p, e := ParsePlacementKey(key)
		if e != nil {
			return out, e
		}
		f, ok := c.Furniture[p.ItemID]
		if !ok || f.Length <= 0 || f.Width <= 0 || f.Height < 0 || f.Floor < 0 {
			return out, ErrUnqualified
		}
		p.Panel, e = furniturePanel(f, p.Flip)
		if e != nil {
			return out, e
		}
		p.Length, p.Width = f.Length, f.Width
		if p.Panel == 1 && p.Flip == 1 {
			if !f.CanRotate {
				return out, &PlacementError{Key: key}
			}
			p.Length, p.Width = p.Width, p.Length
		}
		panelLength, panelWidth := length, width
		if p.Panel == 2 {
			panelWidth = height
		}
		if p.Panel == 3 {
			panelLength, panelWidth = width, height
		}
		if f.SpecialType == 2 {
			if p.Parent != "" || p.X != 0 || p.Y != 0 {
				return out, &PlacementError{Key: key}
			}
			p.Length, p.Width = panelLength, panelWidth
		}
		p.AbsoluteX, p.AbsoluteY = p.X, p.Y
		p.Layer = f.Floor
		if f.Floor >= 2 {
			p.Layer = int64(strings.Count(key, "|")) + 2
		}
		if p.Layer > 6 {
			return out, &PlacementError{Key: key}
		}
		if p.Parent != "" {
			parent, ok := placements[p.Parent]
			if !ok {
				return out, &PlacementError{Key: key}
			}
			pf := c.Furniture[parent.ItemID]
			if p.Panel != 1 || parent.Panel != 1 || !pf.CanBePile || f.Floor <= pf.Floor {
				return out, &PlacementError{Key: key}
			}
			// The support mask uses parent-local coordinates shifted by cover_height.
			sx, sy, ex, ey := int64(0), int64(0), parent.Length, parent.Width
			if pf.PileLimit {
				if len(pf.PileStart) != 2 || len(pf.PileEnd) != 2 {
					return out, ErrUnqualified
				}
				sx, sy, ex, ey = pf.PileStart[0], pf.PileStart[1], pf.PileEnd[0], pf.PileEnd[1]
				if parent.Flip == 1 {
					sx, sy, ex, ey = sy, sx, ey, ex
				}
			}
			if p.X < sx || p.Y < sy || p.Length > ex-p.X || p.Width > ey-p.Y {
				return out, &PlacementError{Key: key}
			}
			if parent.AbsoluteX > math.MaxInt64-pf.Height-p.X || parent.AbsoluteY > math.MaxInt64-pf.Height-p.Y {
				return out, &PlacementError{Key: key}
			}
			p.AbsoluteX = parent.AbsoluteX + pf.Height + p.X
			p.AbsoluteY = parent.AbsoluteY + pf.Height + p.Y
			if children[p.Parent] == nil {
				children[p.Parent] = map[string]bool{}
			}
			children[p.Parent][key] = true
		} else if p.X > panelLength || p.Y > panelWidth || p.Length > panelLength-p.X || p.Width > panelWidth-p.Y {
			return out, &PlacementError{Key: key}
		}
		placements[key] = p
	}
	// A missing/extra/repeated child string is an invalid graph, never a reason
	// to drop an orphan quietly and manufacture a different saved layout.
	for _, key := range keys {
		expected := children[key]
		seen := map[string]bool{}
		if record[key] != "" {
			for _, child := range strings.Split(record[key], "@") {
				if seen[child] || !expected[child] {
					return out, &PlacementError{Key: key}
				}
				seen[child] = true
			}
		}
		if len(seen) != len(expected) {
			return out, &PlacementError{Key: key}
		}
	}
	out.Used = map[int64]int64{}
	out.InventoryMinimum = map[int64]int64{}
	// Separate layers permit wallpaper, rugs and physical furniture to overlap;
	// siblings at the same physical/support layer may not overlap.
	type cell struct{ panel, layer, x, y int64 }
	occupied := map[cell]bool{}
	auto := map[int64]bool{}
	floorBlocked := map[[2]int64]bool{}
	dresserCount := int64(0)
	for _, key := range keys {
		p := placements[key]
		f := c.Furniture[p.ItemID]
		if f.SpecialType == 2 {
			if auto[p.Panel] {
				return LayoutResult{}, &PlacementError{Key: key}
			}
			auto[p.Panel] = true
		}
		if f.Comfort < 0 || out.Comfort > math.MaxInt64-f.Comfort {
			return LayoutResult{}, &PlacementError{Key: key}
		}
		out.Comfort += f.Comfort
		out.Used[p.ItemID]++
		out.InventoryMinimum[p.ItemID]++
		if p.ItemID == room.Dresser {
			if p.Parent != "" {
				return LayoutResult{}, &PlacementError{Key: key}
			}
			dresserCount++
		}
		for x := int64(0); x < p.Length; x++ {
			for y := int64(0); y < p.Width; y++ {
				cellKey := cell{p.Panel, p.Layer, p.AbsoluteX + x, p.AbsoluteY + y}
				if occupied[cellKey] {
					return LayoutResult{}, &PlacementError{Key: key}
				}
				occupied[cellKey] = true
				if p.Panel == 1 && p.Layer == 2 {
					floorBlocked[[2]int64{p.AbsoluteX + x, p.AbsoluteY + y}] = true
				}
			}
		}
		out.Placements = append(out.Placements, p)
	}
	if room.Dresser > 0 {
		if dresserCount != 1 {
			return LayoutResult{}, ErrInvalidLayout
		}
		out.InventoryMinimum[room.Dresser]--
		if out.InventoryMinimum[room.Dresser] == 0 {
			delete(out.InventoryMinimum, room.Dresser)
		}
	}
	out.FreeResidentCells = length*width - int64(len(floorBlocked))
	if out.FreeResidentCells < typ.Residents {
		return LayoutResult{}, ErrInvalidLayout
	}
	return out, nil
}
func strconvKey(item, x, y, flip int64) string {
	return strconv.FormatInt(item, 10) + "#" + strconv.FormatInt(x+1, 10) + "#" + strconv.FormatInt(y+1, 10) + "#" + strconv.FormatInt(flip, 10)
}

// PlacementError identifies a source-packed key only when validation locates
// an offending entry. Aggregate failures (e.g. missing dresser) have no key.
type PlacementError struct{ Key string }

func (e *PlacementError) Error() string { return ErrInvalidLayout.Error() }
func (e *PlacementError) Unwrap() error { return ErrInvalidLayout }
