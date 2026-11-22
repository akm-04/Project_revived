package otarelease

import (
	"context"
	"log"
	"sort"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// maxLedgerKeys bounds the in-memory maps; events for a key already present
// keep counting, a new key past the cap is dropped and reported once per flush.
const maxLedgerKeys = 10_000

// maxMissLogPaths bounds the one-line-per-new-miss-path log map.
const maxMissLogPaths = 4_096

// maxLedgerPathBytes is migration 00184's path length bound.
const maxLedgerPathBytes = 512

// ServedCount is one ota_asset_served_daily increment.
type ServedCount struct {
	Path string
	Day  string
	Hits int64
}

// MissRecord is one ota_asset_misses increment.
type MissRecord struct {
	Path      string
	MD5       string
	FirstSeen time.Time
	LastSeen  time.Time
	Hits      int64
}

// LedgerStore writes one flush batch in the caller's transaction.
type LedgerStore interface {
	FlushTx(context.Context, tx.Tx, []ServedCount, []MissRecord) error
}

// Ledger accumulates OTA serving counters and asset misses in bounded memory
// (OTA ruling 7: one path counter per day, one row per missing path+md5).
type Ledger struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      LedgerStore
	Now        func() time.Time

	mu              sync.Mutex
	served          map[servedKey]int64
	misses          map[missKey]*MissRecord
	loggedMissPaths map[string]struct{}
	dropped         int64
}

type servedKey struct {
	path string
	day  string
}

type missKey struct {
	path string
	md5  string
}

func NewLedger(runner tx.Runner, operations operation.Factory, store LedgerStore) *Ledger {
	return &Ledger{
		Runner: runner, Operations: operations, Store: store, Now: time.Now,
		served:          map[servedKey]int64{},
		misses:          map[missKey]*MissRecord{},
		loggedMissPaths: map[string]struct{}{},
	}
}

// RecordServed adds one served lazy asset hit for its UTC day.
func (l *Ledger) RecordServed(path string, at time.Time) {
	if l == nil || path == "" || len(path) > maxLedgerPathBytes {
		return
	}
	key := servedKey{path: path, day: at.UTC().Format("2006-01-02")}
	l.mu.Lock()
	defer l.mu.Unlock()
	if _, present := l.served[key]; !present && l.full() {
		l.dropped++
		return
	}
	l.served[key]++
}

// RecordMiss adds one unservable lazy asset. The first new path in this process
// writes the only log line; the client retries a 404 forever.
func (l *Ledger) RecordMiss(path, md5 string, at time.Time) {
	if l == nil || path == "" || len(path) > maxLedgerPathBytes {
		return
	}
	if md5 != "" && !validMD5(md5) {
		md5 = ""
	}
	key := missKey{path: path, md5: md5}
	l.mu.Lock()
	defer l.mu.Unlock()
	if record, present := l.misses[key]; present {
		record.Hits++
		record.LastSeen = at
	} else if l.full() {
		l.dropped++
	} else {
		l.misses[key] = &MissRecord{Path: path, MD5: md5, FirstSeen: at, LastSeen: at, Hits: 1}
	}
	if _, logged := l.loggedMissPaths[path]; !logged && len(l.loggedMissPaths) < maxMissLogPaths {
		l.loggedMissPaths[path] = struct{}{}
		log.Printf("ota asset miss: path=%q md5=%q", path, md5)
	}
}

func (l *Ledger) full() bool {
	return len(l.served)+len(l.misses) >= maxLedgerKeys
}

// Flush writes the accumulated batch in one transaction and swaps in empty
// maps, so requests during the flush go to the next batch. Losing one batch on
// a database fault is the plan's accepted observability loss.
func (l *Ledger) Flush(ctx context.Context) error {
	if l == nil || l.Store == nil {
		return nil
	}
	l.mu.Lock()
	served := make([]ServedCount, 0, len(l.served))
	for key, hits := range l.served {
		served = append(served, ServedCount{Path: key.path, Day: key.day, Hits: hits})
	}
	misses := make([]MissRecord, 0, len(l.misses))
	for _, record := range l.misses {
		misses = append(misses, *record)
	}
	dropped := l.dropped
	l.served = map[servedKey]int64{}
	l.misses = map[missKey]*MissRecord{}
	l.dropped = 0
	l.mu.Unlock()
	if dropped > 0 {
		log.Printf("ota ledger overflow: %d events dropped (more than %d distinct keys in one flush)", dropped, maxLedgerKeys)
	}
	if len(served) == 0 && len(misses) == 0 {
		return nil
	}
	sort.Slice(served, func(left, right int) bool {
		if served[left].Path != served[right].Path {
			return served[left].Path < served[right].Path
		}
		return served[left].Day < served[right].Day
	})
	sort.Slice(misses, func(left, right int) bool {
		if misses[left].Path != misses[right].Path {
			return misses[left].Path < misses[right].Path
		}
		return misses[left].MD5 < misses[right].MD5
	})
	op, err := l.Operations.New(policy.Set{})
	if err != nil {
		return err
	}
	profile := tx.Profile{Name: "ota-ledger-flush", AcquireTimeout: 2 * time.Second, LockTimeout: time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 20 * time.Second}
	_, err = l.Runner.Run(ctx, op, profile, tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 2}, nil, func(ctx context.Context, scope tx.Scope) error {
		return l.Store.FlushTx(ctx, scope.Tx, served, misses)
	})
	return err
}

// Run flushes every interval and once more at shutdown.
func (l *Ledger) Run(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			if err := l.Flush(shutdown); err != nil {
				log.Printf("ota ledger shutdown flush: %v", err)
			}
			cancel()
			return
		case <-ticker.C:
			if err := l.Flush(ctx); err != nil && ctx.Err() == nil {
				log.Printf("ota ledger flush: %v", err)
			}
		}
	}
}
