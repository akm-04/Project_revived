package librarylocal

import "time"

// RaiseFavor applies one settled intimacy reward with the live clamp. A hero at
// the cap keeps its favor and the caller records no improvement.
func (f HeroFacts) RaiseFavor(amount int64, now time.Time) (HeroFacts, bool, error) {
	return f.addFavor(amount, now, true)
}

// AwardAmour applies a mission's amour when the command already advanced the
// state version, so the merged facts are saved once.
func (f HeroFacts) AwardAmour(amount int64, now time.Time) (HeroFacts, bool, error) {
	return f.addFavor(amount, now, false)
}

func (f HeroFacts) addFavor(amount int64, now time.Time, advanceState bool) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if amount < 0 {
		return HeroFacts{}, false, ErrUnqualified
	}
	if amount == 0 || f.Favor >= FavorLimit {
		return f, false, nil
	}
	next := f
	next.Favor = min(f.Favor+amount, FavorLimit)
	if advanceState {
		next.StateVersion++
	}
	next.UpdatedAt = now
	return next, true, next.Validate()
}

// RecordTalk applies one 843 request to a dialog row. A reward claim is once
// per dialog; a non-reward choice only records select_id.
func (f DialogFact) RecordTalk(isReward bool, selectID int64, now time.Time) (DialogFact, bool, error) {
	if err := f.Validate(); err != nil {
		return DialogFact{}, false, err
	}
	if selectID < 0 {
		return DialogFact{}, false, ErrUnqualified
	}
	if f.IsAwarded {
		return f, false, nil
	}
	if !isReward {
		if selectID == 0 || f.SelectID == selectID {
			return f, false, nil
		}
		f.SelectID, f.UpdatedAt = selectID, now
		return f, true, f.Validate()
	}
	f.IsAwarded = true
	if selectID > 0 {
		f.SelectID = selectID
	}
	f.UpdatedAt = now
	return f, true, f.Validate()
}

// TalkChoice validates a select against the relationship source graph and
// reports whether its source flag is positive.
func (c Catalog) TalkChoice(relationshipSourceID, dialogID, selectID, rawReward int64) (bool, error) {
	nodes, entry, err := c.dialogRelationshipGraph(relationshipSourceID, dialogID)
	if err != nil {
		return false, err
	}
	current := entry
	visited := map[int64]bool{entry: true}
	for {
		node, ok := nodes[current]
		if !ok {
			return false, ErrUnqualified
		}
		if len(node.TurnIDs) > 1 {
			for _, option := range node.TurnIDs {
				if option != selectID {
					continue
				}
				target, ok := nodes[option]
				if !ok || visited[option] || target.IsReward == nil || *target.IsReward != rawReward {
					return false, ErrUnqualified
				}
				return *target.IsReward > 0, nil
			}
			return false, ErrUnqualified
		}
		target := node.TurnIDs[0]
		if target == -1 || visited[target] {
			return false, ErrUnqualified
		}
		if _, ok := nodes[target]; !ok {
			return false, ErrUnqualified
		}
		visited[target] = true
		current = target
	}
}

// TalkEnd reports whether the entry and retained choice reach a positive
// terminal. A missing retained choice or a nonpositive ending does not grant.
func (c Catalog) TalkEnd(relationshipSourceID, dialogID, retainedSelectID int64) (bool, error) {
	nodes, entry, err := c.dialogRelationshipGraph(relationshipSourceID, dialogID)
	if err != nil {
		return false, err
	}
	current := entry
	visited := map[int64]bool{entry: true}
	usedRetainedChoice := false
	for {
		node, ok := nodes[current]
		if !ok {
			return false, ErrUnqualified
		}
		if len(node.TurnIDs) > 1 {
			if usedRetainedChoice {
				return false, ErrUnqualified
			}
			if retainedSelectID <= 0 {
				return false, nil
			}
			selected := false
			for _, option := range node.TurnIDs {
				if option == retainedSelectID {
					selected = true
					break
				}
			}
			if !selected || visited[retainedSelectID] {
				return false, ErrUnqualified
			}
			if _, ok := nodes[retainedSelectID]; !ok {
				return false, ErrUnqualified
			}
			visited[retainedSelectID] = true
			current = retainedSelectID
			usedRetainedChoice = true
			continue
		}
		target := node.TurnIDs[0]
		if target == -1 {
			if node.IsReward == nil {
				return false, ErrUnqualified
			}
			return *node.IsReward > 0, nil
		}
		if visited[target] {
			return false, ErrUnqualified
		}
		if _, ok := nodes[target]; !ok {
			return false, ErrUnqualified
		}
		visited[target] = true
		current = target
	}
}

func (c Catalog) dialogRelationshipGraph(relationshipSourceID, dialogID int64) (map[int64]DialogNode, int64, error) {
	groupNodes, ok := c.DialogNodes[DialogGroupKey{RelationshipSourceID: relationshipSourceID, DialogGroup: dialogID}]
	if !ok || len(groupNodes) == 0 {
		return nil, 0, ErrUnqualified
	}
	entry := int64(0)
	for nodeID := range groupNodes {
		if nodeID <= 0 {
			return nil, 0, ErrUnqualified
		}
		if entry == 0 || nodeID < entry {
			entry = nodeID
		}
	}
	nodes := make(map[int64]DialogNode)
	for key, rows := range c.DialogNodes {
		if key.RelationshipSourceID != relationshipSourceID {
			continue
		}
		for nodeID, node := range rows {
			if _, duplicate := nodes[nodeID]; duplicate {
				return nil, 0, ErrUnqualified
			}
			nodes[nodeID] = node
		}
	}
	return nodes, entry, nil
}
