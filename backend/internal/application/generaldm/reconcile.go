package generaldm

import (
	"context"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"time"
)

type IntentDeliverer interface {
	DeliverIntent(context.Context, string) error
}
type Reconciler struct {
	Store           Store
	Queryer         tx.Queryer
	Deliverer       IntentDeliverer
	OnDeliveryError func(error)
	mu              sync.Mutex
	hints           map[string]bool
	active          map[string]bool
	cursor, high    string
}

func (r *Reconciler) ReloadAndDeliver(c context.Context, raw string) error {
	ref, e := DecodeReference(raw)
	if e != nil {
		return e
	}
	if r.Store == nil || r.Queryer == nil {
		return ErrUnavailable
	}
	bounded, cancel := context.WithTimeout(c, time.Second)
	defer cancel()
	i, ok, e := r.Store.Find(bounded, r.Queryer, ref.ID)
	if e != nil {
		return e
	}
	if !ok || i.Status.Terminal() || i.StateVersion != ref.Version {
		return nil
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.hints == nil {
		r.hints = map[string]bool{}
	}
	if len(r.hints) < 32 {
		r.hints[ref.ID] = true
	}
	return nil
}
func (r *Reconciler) page(c context.Context) ([]string, error) {
	if r.high == "" {
		high, e := r.Store.HighWater(c, r.Queryer)
		if e != nil {
			return nil, e
		}
		r.high = high
		r.cursor = ""
		if high == "" {
			return nil, nil
		}
	}
	ids, e := r.Store.Page(c, r.Queryer, r.cursor, r.high, 64)
	if e != nil {
		return nil, e
	}
	if len(ids) > 0 {
		last, ok, e := r.Store.Find(c, r.Queryer, ids[len(ids)-1])
		if e != nil || !ok {
			return nil, ErrUnavailable
		}
		r.cursor = last.AcceptedAt.UTC().Format("20060102150405.000000")
		r.cursor = r.cursor[:14] + r.cursor[15:] + ":" + last.ID
	}
	if len(ids) < 64 || r.cursor >= r.high {
		r.cursor = ""
		r.high = ""
	}
	return ids, nil
}
func (r *Reconciler) InitialReconcile(c context.Context) error {
	if r.Store == nil || r.Queryer == nil || r.Deliverer == nil {
		return ErrUnavailable
	}
	bounded, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	// Readiness requires a successful canonical scan. Work is handled by bounded
	// workers; TCP admission does not wait serially on 64 network deadlines.
	_, e := r.page(bounded)
	r.cursor = ""
	r.high = ""
	return e
}
func (r *Reconciler) Run(c context.Context) error {
	if r.Store == nil || r.Queryer == nil || r.Deliverer == nil {
		return ErrUnavailable
	}
	c, stop := context.WithCancel(c)
	defer stop()
	periodic := make(chan string, 24)
	hint := make(chan string, 8)
	r.mu.Lock()
	r.active = map[string]bool{}
	if r.hints == nil {
		r.hints = map[string]bool{}
	}
	r.mu.Unlock()
	var wg sync.WaitGroup
	worker := func(jobs <-chan string) {
		defer wg.Done()
		for {
			select {
			case <-c.Done():
				return
			case id := <-jobs:
				bounded, cancel := context.WithTimeout(c, 5*time.Second)
				e := r.Deliverer.DeliverIntent(bounded, id)
				cancel()
				r.mu.Lock()
				delete(r.active, id)
				r.mu.Unlock()
				if e != nil && r.OnDeliveryError != nil {
					r.OnDeliveryError(e)
				}
			}
		}
	}
	for n := 0; n < 4; n++ {
		wg.Add(1)
		go worker(periodic)
	}
	wg.Add(1)
	go worker(hint)
	defer func() { stop(); wg.Wait() }()
	enqueue := func(id string, q chan string) bool {
		r.mu.Lock()
		defer r.mu.Unlock()
		if r.active[id] {
			return true
		}
		if len(r.active) >= 32 {
			return false
		}
		select {
		case q <- id:
			r.active[id] = true
			return true
		default:
			return false
		}
	}
	var backlog []string
	tick := time.NewTicker(time.Second)
	defer tick.Stop()
	for {
		select {
		case <-c.Done():
			return c.Err()
		case <-tick.C:
			if len(backlog) == 0 {
				bounded, cancel := context.WithTimeout(c, time.Second)
				page, e := r.page(bounded)
				cancel()
				if e != nil {
					return e
				}
				backlog = page
			}
			kept := backlog[:0]
			for _, id := range backlog {
				if !enqueue(id, periodic) {
					kept = append(kept, id)
				}
			}
			backlog = kept
			r.mu.Lock()
			h := []string{}
			for id := range r.hints {
				h = append(h, id)
				delete(r.hints, id)
				if len(h) == 8 {
					break
				}
			}
			r.mu.Unlock()
			for _, id := range h {
				enqueue(id, hint)
			}
		}
	}
}
