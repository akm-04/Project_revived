package stockruntime

import "errors"

// practiceAutoWireRequest is the exact CA6-4 AUTO request surface. It is
// intentionally decoded separately from practiceWireMID during CA6-4A so
// MIDs 127/132 cannot become production-owned merely by adding the decoder.
type practiceAutoWireRequest struct {
	Hero         bool
	ActorID      int64
	Locks        [3]int64
	PracticeType int64
	PracticeNum  int64
	SaveTypes    [4]int64
}

func decodePracticeSaveTypes(raw any) ([4]int64, error) {
	var out [4]int64
	values, ok := raw.([]any)
	if !ok || len(values) != len(out) {
		return out, errors.New("invalid Practice AUTO save_types vector")
	}
	selected := false
	for i, rawValue := range values {
		v, err := requiredInt64(map[string]any{"value": rawValue}, "value")
		if err != nil || (v != 0 && v != 1) {
			return [4]int64{}, errors.New("invalid Practice AUTO save_types bit")
		}
		out[i] = v
		selected = selected || v == 1
	}
	if !selected {
		return [4]int64{}, errors.New("Practice AUTO requires a save predicate")
	}
	return out, nil
}

func validPracticeAutoCount(n int64) bool {
	switch n {
	case 2, 4, 6, 8, 10:
		return true
	default:
		return false
	}
}

func practiceAutoMID(mid uint16) (hero bool, ok bool) {
	switch mid {
	case 127:
		return true, true
	case 132:
		return false, true
	default:
		return false, false
	}
}

func decodePracticeAutoWireRequest(mid uint16, params map[string]any) (practiceAutoWireRequest, error) {
	hero, ok := practiceAutoMID(mid)
	if !ok {
		return practiceAutoWireRequest{}, errors.New("not a CA6-4 AUTO Practice MID")
	}
	actorKey := "pet_id"
	if hero {
		actorKey = "partner_id"
	}
	if !onlyStockGameplayParams(params, actorKey, "locks", "practice_type", "practice_num", "save_types") {
		return practiceAutoWireRequest{}, errors.New("invalid Practice AUTO params")
	}
	actorID, err := requiredInt64(params, actorKey)
	if err != nil || actorID <= 0 {
		return practiceAutoWireRequest{}, errors.New("invalid Practice AUTO actor")
	}
	locks, err := decodePracticeLocks(params["locks"])
	if err != nil {
		return practiceAutoWireRequest{}, err
	}
	method, err := requiredInt64(params, "practice_type")
	if err != nil || method < 1 || method > 3 {
		return practiceAutoWireRequest{}, errors.New("invalid Practice AUTO method")
	}
	count, err := requiredInt64(params, "practice_num")
	if err != nil || !validPracticeAutoCount(count) {
		return practiceAutoWireRequest{}, errors.New("invalid Practice AUTO batch size")
	}
	save, err := decodePracticeSaveTypes(params["save_types"])
	if err != nil {
		return practiceAutoWireRequest{}, err
	}
	for axis := 0; axis < 3; axis++ {
		if locks[axis] == 1 && save[axis] != 1 {
			return practiceAutoWireRequest{}, errors.New("locked Practice AUTO axis must be selected")
		}
	}
	return practiceAutoWireRequest{Hero: hero, ActorID: actorID, Locks: locks, PracticeType: method, PracticeNum: count, SaveTypes: save}, nil
}
