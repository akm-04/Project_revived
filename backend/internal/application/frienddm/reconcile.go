package frienddm

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"time"
)

type RecipientDeliverer interface {
	DeliverRecipient(context.Context, identity.PlayerID) error
}

// Reconciler has independent bounded periodic/hint lanes (7+1 workers). Hints
// cannot consume the periodic queue. Shared slots prohibit overlapping delivery
// for one recipient. Neither queue is a durable payload or gameplay owner.
type Reconciler struct {
	Store           Store
	Queryer         tx.Queryer
	Deliverer       RecipientDeliverer
	OnDeliveryError func(error)
	mu              sync.Mutex
	hints           map[identity.PlayerID]bool
	active          map[identity.PlayerID]bool
	cursor, high    identity.PlayerID
}

func (r *Reconciler) ReloadAndDeliver(c context.Context, raw string) error {
	ref, e := DecodeReference(raw)
	if e != nil {
		return e
	}
	if r.Store == nil || r.Queryer == nil {
		return ErrUnavailable
	}
	bounded, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	ok, e := r.Store.ReferencePending(bounded, r.Queryer, ref)
	if e != nil {
		return e
	}
	if !ok {
		return nil
	}

	r.mu.Lock()
	defer r.mu.Unlock()
	if r.hints == nil {
		r.hints = map[identity.PlayerID]bool{}
	}
	if len(r.hints) < 64 {
		r.hints[ref.Recipient] = true
	}
	return nil
}
func (r *Reconciler) page(c context.Context) ([]identity.PlayerID, error) {
	if r.high == 0 {
		high, e := r.Store.PendingHighWater(c, r.Queryer)
		if e != nil {
			return nil, e
		}
		r.high = high
		r.cursor = 0
	}
	ids, e := r.Store.PendingRecipients(c, r.Queryer, r.cursor, r.high, 64)
	if e != nil {
		return nil, e
	}
	if len(ids) > 0 {
		r.cursor = ids[len(ids)-1]
	}
	if len(ids) < 64 || r.cursor >= r.high {
		r.cursor = 0
		r.high = 0
	}
	return ids, nil
}

// InitialReconcile is canonical discovery before TCP admission. Offline targets
// are advanced by normal workers; no connection or presentation is invented.
func (r *Reconciler) InitialReconcile(c context.Context) error {
	if r.Store == nil || r.Queryer == nil || r.Deliverer == nil {
		return ErrUnavailable
	}
	bounded, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	ids, e := r.page(bounded)
	if e != nil {
		return e
	}
	for _, id := range ids {
		if e = r.Deliverer.DeliverRecipient(bounded, id); e != nil {
			return e
		}
	}
	return nil
}
func (r *Reconciler) Run(c context.Context) error {
	if r.Store == nil || r.Queryer == nil || r.Deliverer == nil {
		return ErrUnavailable
	}
	c, stop := context.WithCancel(c)
	defer stop()
	periodic := make(chan identity.PlayerID, 56)
	hint := make(chan identity.PlayerID, 8)
	r.mu.Lock()
	r.active = map[identity.PlayerID]bool{}
	if r.hints == nil {
		r.hints = map[identity.PlayerID]bool{}
	}
	r.mu.Unlock()
	var wg sync.WaitGroup
	worker := func(jobs <-chan identity.PlayerID) {
		defer wg.Done()
		for {
			select {
			case <-c.Done():
				return
			case id := <-jobs:
				bounded, cancel := context.WithTimeout(c, 5*time.Second)
				e := r.Deliverer.DeliverRecipient(bounded, id)
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
	for i := 0; i < 7; i++ {
		wg.Add(1)
		go worker(periodic)
	}
	wg.Add(1)
	go worker(hint)
	// Child cancellation and join are structural even on canonical scan failure.
	defer func() { stop(); wg.Wait() }()
	enqueue := func(id identity.PlayerID, jobs chan identity.PlayerID) {
		r.mu.Lock()
		defer r.mu.Unlock()
		if r.active[id] || len(r.active) >= 64 {
			return
		}
		select {
		case jobs <- id:
			r.active[id] = true
		default:
		}
	}
	tick := time.NewTicker(time.Second)
	defer tick.Stop()
	for {
		select {
		case <-c.Done():
			return c.Err()
		case <-tick.C:
			bounded, cancel := context.WithTimeout(c, 2*time.Second)
			page, e := r.page(bounded)
			cancel()
			if e != nil {
				return e
			}
			for _, id := range page {
				enqueue(id, periodic)
			}
			r.mu.Lock()
			hints := []identity.PlayerID{}
			for id := range r.hints {
				hints = append(hints, id)
				delete(r.hints, id)
				if len(hints) == 8 {
					break
				}
			}
			r.mu.Unlock()
			for _, id := range hints {
				enqueue(id, hint)
			}
		}
	}
}
