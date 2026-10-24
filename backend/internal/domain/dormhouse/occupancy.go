package dormhouse

import (
	"sort"
	"time"
)

const ResidentCooldown = 24 * time.Hour

type ResidentPlan struct {
	Rooms        map[int64]Room
	Assignments  map[int64]int64
	ChangedRooms []int64
}

// PlanResidents is an atomic desired-membership plan. Application must settle
// old Lounge EXP and validate every changed Character ref under its preplanned
// locks before applying it. Room.Residents is a view of owned membership rows.
func (c Catalog) PlanResidents(rooms map[int64]Room, target int64, desired []int64, now time.Time) (ResidentPlan, error) {
	desired = append([]int64(nil), desired...)
	sort.Slice(desired, func(i, j int) bool { return desired[i] < desired[j] })
	out := ResidentPlan{Rooms: map[int64]Room{}, Assignments: map[int64]int64{}}
	r, ok := rooms[target]
	if !ok || now.IsZero() {
		return out, ErrInvalidFacts
	}
	rule, ok := c.Rooms[r.TableID]
	if !ok {
		return out, ErrUnqualified
	}
	typ, ok := c.Types[rule.MainType]
	if !ok {
		return out, ErrUnqualified
	}
	if int64(len(desired)) > typ.Residents {
		return out, ErrInvalidFacts
	}
	want := map[int64]bool{}
	for _, id := range desired {
		if id <= 0 || want[id] {
			return out, ErrInvalidFacts
		}
		want[id] = true
	}
	owner := map[int64]int64{}
	for id, r := range rooms {
		if r.ID != id || r.ID <= 0 || now.Before(r.UpdatedAt) {
			return out, ErrStaleTime
		}
		copy := r
		copy.Residents = append([]int64(nil), r.Residents...)
		out.Rooms[id] = copy
		for _, hero := range r.Residents {
			if hero <= 0 || owner[hero] != 0 {
				return out, ErrInvalidFacts
			}
			owner[hero] = id
		}
	}
	same := len(r.Residents) == len(desired)
	for i := range r.Residents {
		if !same || r.Residents[i] != desired[i] {
			same = false
			break
		}
	}
	if same {
		return out, nil
	}
	changed := map[int64]bool{target: true}
	for _, hero := range desired {
		if old := owner[hero]; old != 0 && old != target {
			changed[old] = true
		}
	}
	// Include source rooms: pulling a resident out is a membership change too.
	for id := range changed {
		old := rooms[id]
		rule, ok := c.Rooms[old.TableID]
		if !ok {
			return out, ErrUnqualified
		}
		if rule.MainType != LoungeType && !old.LastEnterAt.IsZero() && now.Before(old.LastEnterAt.Add(ResidentCooldown)) {
			return out, ErrCooldown
		}
	}
	for id := range changed {
		next := out.Rooms[id]
		if id == target {
			next.Residents = append([]int64(nil), desired...)
		} else {
			next.Residents = nil
			for _, hero := range rooms[id].Residents {
				if !want[hero] {
					next.Residents = append(next.Residents, hero)
				}
			}
		}
		next.LastEnterAt = now.UTC()
		next.UpdatedAt = now.UTC()
		next.StateVersion++
		out.Rooms[id] = next
		out.ChangedRooms = append(out.ChangedRooms, id)
	}
	for _, hero := range r.Residents {
		if !want[hero] {
			out.Assignments[hero] = 0
		}
	}
	for _, hero := range desired {
		if owner[hero] != target {
			out.Assignments[hero] = target
		}
	}
	sort.Slice(out.ChangedRooms, func(i, j int) bool { return out.ChangedRooms[i] < out.ChangedRooms[j] })
	return out, nil
}
