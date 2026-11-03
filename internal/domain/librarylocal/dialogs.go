package librarylocal

import "slices"

// DialogOpened reports whether a config row is open from facts the server owns.
// Types 1, 2, 3 and 5 have recovered triggers. Types 4 (event), 6 (choice) and
// 7 (gift) open only after their own row exists: no trigger fact is recovered.
func (c Catalog) DialogOpened(id, favor int64, married bool) bool {
	rule, ok := c.DialogConfigs[id]
	if !ok {
		return false
	}
	switch rule.Type {
	case 1:
		return true
	case 2:
		return favor >= rule.OpenCondition
	case 3:
		return married
	case 5:
		return c.actDialogUnlocked(id, favor)
	default:
		return false
	}
}

// Contextual dialogs open from a trigger the client attests (event push, a
// choice inside another dialog, or a gift reaction), not from a favor stage.
func (r DialogConfigRule) Contextual() bool {
	return r.Type == 4 || r.Type == 6 || r.Type == 7
}

func (c Catalog) actDialogUnlocked(dialogID, favor int64) bool {
	for _, act := range c.Acts {
		if act.Dialog == dialogID {
			return c.ActUnlocked(act.ID, favor)
		}
	}
	return false
}

// OpenDialogIDs returns statically opened dialog ids in ascending order.
func (c Catalog) OpenDialogIDs(favor int64, married bool) []int64 {
	ids := make([]int64, 0, len(c.DialogConfigs))
	for id := range c.DialogConfigs {
		if c.DialogOpened(id, favor, married) {
			ids = append(ids, id)
		}
	}
	slices.Sort(ids)
	return ids
}
