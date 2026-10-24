package combatresolver

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"runtime/debug"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

const (
	MaxRequestBytes  = 8 << 20
	MaxResponseBytes = 32 << 20
	StatusResolved   = "RESOLVED"
	StatusPermanent  = "PERMANENT_FAILURE"
)

// Request is the only input a worker process receives: the canonical frozen
// snapshot and its attempt entropy root. It never carries keys or credentials.
type Request struct {
	Snapshot     json.RawMessage `json:"snapshot"`
	SnapshotHash string          `json:"snapshot_hash"`
	EntropyRoot  string          `json:"entropy_root"`
}

type Response struct {
	Status         string         `json:"status"`
	Failure        string         `json:"failure,omitempty"`
	CorpusID       string         `json:"corpus_id"`
	Outcome        combat.Outcome `json:"outcome"`
	Report         string         `json:"report,omitempty"`
	EntropyDraws   uint64         `json:"entropy_draws"`
	EntropyReseeds uint64         `json:"entropy_reseeds"`
}

// Serve prepares the attempt-independent machine before it reads stdin, then
// answers exactly one request. Only deterministic failures produce a response;
// I/O failures return an error so the launcher classifies them as retryable.
func Serve(in io.Reader, out io.Writer) error {
	corpus, prepareErr := combatcorpus.Load()
	var m *machine
	if prepareErr == nil {
		m, prepareErr = prepare(corpus)
	}
	// A prepared worker idles until the launcher hands it an attempt.
	debug.FreeOSMemory()
	raw, err := io.ReadAll(io.LimitReader(in, MaxRequestBytes+1))
	if err != nil {
		return err
	}
	response := answer(corpus, m, prepareErr, raw)
	return json.NewEncoder(out).Encode(response)
}

func answer(corpus *combatcorpus.Corpus, m *machine, prepareErr error, raw []byte) Response {
	if corpus == nil {
		return Response{Status: StatusPermanent, Failure: prepareErr.Error()}
	}
	failed := func(err error) Response {
		return Response{Status: StatusPermanent, Failure: err.Error(), CorpusID: corpus.ID()}
	}
	if prepareErr != nil {
		return failed(prepareErr)
	}
	defer m.state.Close()
	if len(raw) > MaxRequestBytes {
		return failed(errors.New("request exceeds bound"))
	}
	var request Request
	if err := json.Unmarshal(raw, &request); err != nil {
		return failed(err)
	}
	snapshot, err := combat.DecodeSnapshot(request.Snapshot, request.SnapshotHash)
	if err != nil {
		return failed(err)
	}
	rootBytes, err := hex.DecodeString(request.EntropyRoot)
	if err != nil || len(rootBytes) != 32 {
		return failed(errors.New("entropy root shape"))
	}
	if err = m.bind(snapshot, [32]byte(rootBytes)); err != nil {
		return failed(err)
	}
	result, err := m.resolve()
	if err != nil {
		return failed(err)
	}
	return Response{Status: StatusResolved, CorpusID: corpus.ID(), Outcome: result.Outcome, Report: string(result.Report), EntropyDraws: result.EntropyDraws, EntropyReseeds: result.EntropyReseeds}
}
