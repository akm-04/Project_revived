package observe

import (
	"sync"
	"time"

	"gxb.local/backend/v2/internal/protocol/wire"
)

// Observation is intentionally metadata-only. Raw bearer tokens, private chat
// bodies, files and decoded player data are not retained by this protocol-edge
// backlog.
type Observation struct {
	MID        uint16
	Transport  wire.Transport
	Direction  wire.Direction
	RawBytes   int64
	HashPrefix string
	FirstSeen  time.Time
	LastSeen   time.Time
	Count      uint64
}

type Sink interface{ Record(Observation) }

type MemorySink struct {
	mu sync.Mutex
	m  map[string]Observation
}

func NewMemorySink() *MemorySink { return &MemorySink{m: make(map[string]Observation)} }
func key(o Observation) string {
	return string(o.Transport) + ":" + string(o.Direction) + ":" + o.HashPrefix + ":" + itoa(o.MID)
}
func (s *MemorySink) Record(o Observation) {
	s.mu.Lock()
	defer s.mu.Unlock()
	k := key(o)
	if prev, ok := s.m[k]; ok {
		prev.LastSeen = o.LastSeen
		prev.Count++
		s.m[k] = prev
		return
	}
	if o.Count == 0 {
		o.Count = 1
	}
	s.m[k] = o
}
func (s *MemorySink) Snapshot() []Observation {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Observation, 0, len(s.m))
	for _, o := range s.m {
		out = append(out, o)
	}
	return out
}
func itoa(v uint16) string {
	if v == 0 {
		return "0"
	}
	var b [5]byte
	i := len(b)
	for v > 0 {
		i--
		b[i] = byte('0' + v%10)
		v /= 10
	}
	return string(b[i:])
}
