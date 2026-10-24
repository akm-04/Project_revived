// Package changes is the request change set of I9_MODE_FOUNDATION_V1 MF5 (F17, D93): owners record the state they wrote, each
// transaction attempt stages its records, and only a clean commit keeps them for the response decorator.
package changes

import (
	"context"
	"slices"
	"sync"
)

type contextKey struct{}

// Set holds absolute state written during one request, or during one transaction attempt when it has a parent.
type Set struct {
	mutex     sync.Mutex
	parent    *Set
	balances  map[string]int64
	functions map[int64]struct{}
}

// Track starts the change set of a request.
func Track(ctx context.Context) (context.Context, *Set) {
	set := &Set{}
	return context.WithValue(ctx, contextKey{}, set), set
}

// Stage opens the change set of one transaction attempt; nil when the request is not tracked.
func Stage(ctx context.Context) (context.Context, *Set) {
	parent, _ := ctx.Value(contextKey{}).(*Set)
	if parent == nil {
		return ctx, nil
	}
	stage := &Set{parent: parent}
	return context.WithValue(ctx, contextKey{}, stage), stage
}

// Keep hands a committed attempt's records to the enclosing set.
func (s *Set) Keep() {
	if s == nil || s.parent == nil {
		return
	}
	s.mutex.Lock()
	balances, functions := s.balances, s.functions
	s.mutex.Unlock()
	s.parent.mutex.Lock()
	defer s.parent.mutex.Unlock()
	for key, amount := range balances {
		s.parent.setBalance(key, amount)
	}
	for id := range functions {
		s.parent.addFunction(id)
	}
}

// Balance records a resource's amount after a write: a scalar resource key, or exp and lev of player progression.
func Balance(ctx context.Context, key string, amount int64) {
	set, _ := ctx.Value(contextKey{}).(*Set)
	if set == nil {
		return
	}
	set.mutex.Lock()
	defer set.mutex.Unlock()
	set.setBalance(key, amount)
}

// FunctionOpened records a function unlock written for the player.
func FunctionOpened(ctx context.Context, id int64) {
	set, _ := ctx.Value(contextKey{}).(*Set)
	if set == nil {
		return
	}
	set.mutex.Lock()
	defer set.mutex.Unlock()
	set.addFunction(id)
}

func (s *Set) setBalance(key string, amount int64) {
	if s.balances == nil {
		s.balances = map[string]int64{}
	}
	s.balances[key] = amount
}

func (s *Set) addFunction(id int64) {
	if s.functions == nil {
		s.functions = map[int64]struct{}{}
	}
	s.functions[id] = struct{}{}
}

// Balances is a copy of the recorded amounts.
func (s *Set) Balances() map[string]int64 {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	out := make(map[string]int64, len(s.balances))
	for key, amount := range s.balances {
		out[key] = amount
	}
	return out
}

// Functions are the recorded function ids in ascending order.
func (s *Set) Functions() []int64 {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	out := make([]int64, 0, len(s.functions))
	for id := range s.functions {
		out = append(out, id)
	}
	slices.Sort(out)
	return out
}
