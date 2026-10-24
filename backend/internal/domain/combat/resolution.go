package combat

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
)

const ReportEncoding = "application/json;source=BattleCreateReport.writeReport"

// Outcome is what BattleCreateReport itself decides; modes interpret star
// (source is_win is star > 0) under their own rules.
type Outcome struct {
	Star        int64 `json:"star"`
	TimedOut    bool  `json:"timed_out"`
	Frames      int64 `json:"frames"`
	ReportError bool  `json:"report_error"`
}

// Resolution is persisted once per attempt; its hash binds the report bytes.
type Resolution struct {
	AttemptID      string  `json:"attempt_id"`
	SnapshotHash   string  `json:"snapshot_hash"`
	RulesCorpusID  string  `json:"rules_corpus_id"`
	Outcome        Outcome `json:"outcome"`
	ReportSHA256   string  `json:"report_sha256"`
	ReportBytes    int64   `json:"report_bytes"`
	ReportEncoding string  `json:"report_encoding"`
	EntropyDraws   uint64  `json:"entropy_draws"`
	EntropyReseeds uint64  `json:"entropy_reseeds"`
}

func ReportHash(report []byte) string {
	sum := sha256.Sum256(report)
	return hex.EncodeToString(sum[:])
}

func (r Resolution) Validate(a Attempt, report []byte) error {
	if r.AttemptID != a.ID.String() || r.SnapshotHash != a.SnapshotHash || r.RulesCorpusID != a.RulesCorpusID || r.ReportEncoding != ReportEncoding || r.ReportBytes != int64(len(report)) || r.ReportSHA256 != ReportHash(report) || len(report) == 0 || r.Outcome.Frames < 0 {
		return ErrIntegrity
	}
	return nil
}

func (r Resolution) Hash() (string, []byte, error) {
	raw, err := json.Marshal(r)
	if err != nil {
		return "", nil, err
	}
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:]), raw, nil
}
