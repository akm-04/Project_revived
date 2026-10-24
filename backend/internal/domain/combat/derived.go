package combat

import "encoding/json"

// PermilleScale is the stock comparison scale of a client-derived draw: a
// success needs probability >= draw/1000 (ThrowSandbagWindow self_rd/friend_rd).
const PermilleScale = 1000

// maxDrawLength bounds one package stream; the stock throw count is about 40.
const maxDrawLength = 4096

// Challenge is the frozen layout of a battle-less SERVER_ENTROPY_CLIENT_DERIVED
// START (Dodgeball ENTER monsters); RESULT claims name targets by 1-based index.
type Challenge struct {
	Targets []int64 `json:"targets"`
}

func (c Challenge) valid() bool {
	for _, target := range c.Targets {
		if target <= 0 {
			return false
		}
	}
	return len(c.Targets) > 0
}

// DrawStream is one named per-mille entropy array of a START package.
type DrawStream struct {
	Name   string
	Length int
	Low    int64
	High   int64
}

// DrawPolicy is a family's versioned SERVER_ENTROPY_CLIENT_DERIVED package.
// Lengths and ranges are private policy (D20): the original arrays are
// UNKNOWN. A changed stream is a new version, never an edit.
type DrawPolicy struct {
	ID      string
	Version int
	Streams []DrawStream
}

func (p DrawPolicy) Valid() bool {
	names := map[string]bool{}
	for _, s := range p.Streams {
		if s.Name == "" || names[s.Name] || s.Length <= 0 || s.Length > maxDrawLength || s.Low < 0 || s.High < s.Low || s.High > PermilleScale {
			return false
		}
		names[s.Name] = true
	}
	return versionedID.MatchString(p.ID) && p.Version > 0 && len(p.Streams) > 0
}

// DrawPackage is the stored START package of a client-derived attempt: the
// draws and the policy version that issued them (PASS420: lost START returns
// the same entropy and rules version).
type DrawPackage struct {
	Policy  string             `json:"policy"`
	Version int                `json:"version"`
	Streams map[string][]int64 `json:"streams"`
}

// Build draws the policy's streams from the attempt's START package stream;
// it is the StartRequest.Package of the family.
func (p DrawPolicy) Build(stream *Stream) (any, error) {
	if !p.Valid() {
		return nil, ErrInvalid
	}
	pack := DrawPackage{Policy: p.ID, Version: p.Version, Streams: map[string][]int64{}}
	for _, s := range p.Streams {
		draws := make([]int64, s.Length)
		for i := range draws {
			draw, err := stream.Between(float64(s.Low), float64(s.High))
			if err != nil {
				return nil, err
			}
			draws[i] = draw
		}
		pack.Streams[s.Name] = draws
	}
	return pack, nil
}

// Issued reports whether this policy version issued the package; a RESULT is
// judged only under the policy its START drew.
func (p DrawPolicy) Issued(pack DrawPackage) bool {
	return pack.Policy == p.ID && pack.Version == p.Version
}

func DecodeDrawPackage(pack StartPackage) (DrawPackage, error) {
	var draws DrawPackage
	if err := json.Unmarshal(pack.Canonical, &draws); err != nil || draws.Policy == "" {
		return DrawPackage{}, ErrIntegrity
	}
	return draws, nil
}

// DrawClaim is one client-derived outcome as the mode decoded it from the
// stock RESULT: the draw it consumed (1-based, as the stock rate_id), the
// challenge target it won (1-based; 0 is a gate draw such as the friend
// throw) and the success probability the mode computed from content.
type DrawClaim struct {
	Stream   string `json:"stream"`
	Index    int    `json:"index"`
	Target   int    `json:"target"`
	Permille int64  `json:"permille"`
}

// Derivation is CLIENT_ATTESTED evidence: the claimed successes only.
type Derivation struct {
	Claims []DrawClaim `json:"claims"`
}

// Judge checks every claim against the stored draws and the frozen challenge
// and returns the verdict with a stable reason code for a rejection.
func (p DrawPackage) Judge(snapshot Snapshot, derivation Derivation) (Verdict, string) {
	targets := 0
	if snapshot.Challenge != nil {
		targets = len(snapshot.Challenge.Targets)
	}
	wonTargets := map[int]bool{}
	gates := map[DrawClaim]bool{}
	for _, claim := range derivation.Claims {
		draws, known := p.Streams[claim.Stream]
		gate := DrawClaim{Stream: claim.Stream, Index: claim.Index}
		switch {
		case !known:
			return VerdictRejected, "STREAM_UNKNOWN"
		case claim.Index < 1 || claim.Index > len(draws):
			return VerdictRejected, "INDEX_OUT_OF_RANGE"
		case claim.Target < 0 || claim.Target > targets:
			return VerdictRejected, "TARGET_UNKNOWN"
		case claim.Target > 0 && wonTargets[claim.Target]:
			return VerdictRejected, "TARGET_DUPLICATE"
		case claim.Target == 0 && gates[gate]:
			return VerdictRejected, "GATE_DUPLICATE"
		case claim.Permille < 0 || claim.Permille > PermilleScale:
			return VerdictRejected, "PERMILLE_OUT_OF_RANGE"
		case draws[claim.Index-1] > claim.Permille:
			return VerdictRejected, "DRAW_ABOVE_CLAIM"
		}
		if claim.Target > 0 {
			wonTargets[claim.Target] = true
			continue
		}
		gates[gate] = true
	}
	return VerdictAccepted, ""
}
