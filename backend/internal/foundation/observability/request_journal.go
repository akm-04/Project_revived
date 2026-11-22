package observability

import (
	"context"
	"sync"
	"time"
)

// RequestDisposition is how far the HTTP edge got with a request.
type RequestDisposition int

const (
	RequestDispatched RequestDisposition = iota
	RequestUnknownMID
	RequestUndecodable
	RequestRejectedAtEdge
	RequestInactiveMode
)

// RequestRecord is one stock HTTP request as seen by the edge
// (I85_REQUEST_JOURNAL_V1). Raw holds the unescaped request body for
// unknown or undecodable requests only; the journal redacts and caps it.
type RequestRecord struct {
	ReceivedAt    time.Time
	Disposition   RequestDisposition
	MID           int
	HasMID        bool
	HTTPStatus    int
	ErrorCode     int64
	Latency       time.Duration
	RequestBytes  int64
	ResponseBytes int64
	RequestSHA256 []byte
	Cause         error
	Raw           []byte
	Actor         RequestActor
	// Replay marks a request answered from an undelivered-reply mark instead of a dispatch.
	Replay bool
}

// RequestActor is the authenticated stock identity of a request, when known.
type RequestActor struct {
	AccountUID string
	PlayerID   int64
	SessionID  string
}

// RequestJournal receives edge records; implementations must not block.
type RequestJournal interface {
	Record(RequestRecord)
}

// RequestNote collects the actor of one request while dispatchers run.
type RequestNote struct {
	mutex             sync.Mutex
	actor             RequestActor
	paramsFingerprint [32]byte
	hasFingerprint    bool
	claim             int64
	hasClaim          bool
	replayed          bool
}

type requestNoteKey struct{}

// WithRequestNote attaches an empty note to a request context.
func WithRequestNote(ctx context.Context) (context.Context, *RequestNote) {
	note := &RequestNote{}
	return context.WithValue(ctx, requestNoteKey{}, note), note
}

// ActingActor is the actor noted on ctx so far, zero when the request attached no note or was not authenticated.
func ActingActor(ctx context.Context) RequestActor {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return RequestActor{}
	}
	return note.Actor()
}

// NoteActor records the authenticated actor on the request's note, if any.
func NoteActor(ctx context.Context, actor RequestActor) {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return
	}
	note.mutex.Lock()
	defer note.mutex.Unlock()
	note.actor = actor
}

// Actor returns the noted actor (zero when the request was never authenticated).
func (n *RequestNote) Actor() RequestActor {
	n.mutex.Lock()
	defer n.mutex.Unlock()
	return n.actor
}

// NoteParamsFingerprint records the canonical params fingerprint the replay
// guard computed for a state-changing request.
func NoteParamsFingerprint(ctx context.Context, fingerprint [32]byte) {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return
	}
	note.mutex.Lock()
	defer note.mutex.Unlock()
	note.paramsFingerprint = fingerprint
	note.hasFingerprint = true
}

// ParamsFingerprint returns the fingerprint noted for this request.
func (n *RequestNote) ParamsFingerprint() ([32]byte, bool) {
	n.mutex.Lock()
	defer n.mutex.Unlock()
	return n.paramsFingerprint, n.hasFingerprint
}

// NoteClaim records the claim the replay guard took for this state request
// before dispatch. A mark write is stored only while the claim still holds.
func NoteClaim(ctx context.Context, claim int64) {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return
	}
	note.mutex.Lock()
	defer note.mutex.Unlock()
	note.claim = claim
	note.hasClaim = true
}

// Claim returns the claim noted for this request.
func (n *RequestNote) Claim() (int64, bool) {
	n.mutex.Lock()
	defer n.mutex.Unlock()
	return n.claim, n.hasClaim
}

// NoteReplay records that the request was answered from an undelivered-reply mark.
func NoteReplay(ctx context.Context) {
	note, _ := ctx.Value(requestNoteKey{}).(*RequestNote)
	if note == nil {
		return
	}
	note.mutex.Lock()
	defer note.mutex.Unlock()
	note.replayed = true
}

// Replayed reports whether the request was answered from an undelivered-reply mark.
func (n *RequestNote) Replayed() bool {
	n.mutex.Lock()
	defer n.mutex.Unlock()
	return n.replayed
}
