package policy

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"sort"
	"strings"
)

var ErrInvalidReference = errors.New("invalid policy reference")

type Ref struct {
	Name    string
	Version string
}

type Set struct{ refs []Ref }

func NewSet(in ...Ref) (Set, error) {
	refs := append([]Ref(nil), in...)
	sort.Slice(refs, func(i, j int) bool { return refs[i].Name < refs[j].Name })
	for i, r := range refs {
		if strings.TrimSpace(r.Name) == "" || strings.TrimSpace(r.Version) == "" {
			return Set{}, ErrInvalidReference
		}
		if i > 0 && refs[i-1].Name == r.Name {
			return Set{}, ErrInvalidReference
		}
	}
	return Set{refs: refs}, nil
}
func (s Set) Get(name string) (string, bool) {
	i := sort.Search(len(s.refs), func(i int) bool { return s.refs[i].Name >= name })
	if i < len(s.refs) && s.refs[i].Name == name {
		return s.refs[i].Version, true
	}
	return "", false
}
func (s Set) Refs() []Ref { return append([]Ref(nil), s.refs...) }
func (s Set) Equal(other Set) bool {
	if len(s.refs) != len(other.refs) {
		return false
	}
	for i := range s.refs {
		if s.refs[i] != other.refs[i] {
			return false
		}
	}
	return true
}

type durableRef struct {
	Name    string `json:"name"`
	Version string `json:"version"`
}

// MarshalJSON is the durable evidence encoding used by operation receipts.
// The zero set is [] (never null) and references remain name-sorted.
func (s Set) MarshalJSON() ([]byte, error) {
	wire := make([]durableRef, len(s.refs))
	for i, r := range s.refs {
		if strings.TrimSpace(r.Name) == "" || strings.TrimSpace(r.Version) == "" {
			return nil, ErrInvalidReference
		}
		if i > 0 && s.refs[i-1].Name >= r.Name {
			return nil, ErrInvalidReference
		}
		wire[i] = durableRef{Name: r.Name, Version: r.Version}
	}
	return json.Marshal(wire)
}

// UnmarshalJSON accepts only the canonical durable array shape. Array ordering
// is evidence: persisted unsorted/duplicate references fail closed rather than
// being silently normalized on read.
func (s *Set) UnmarshalJSON(data []byte) error {
	if s == nil {
		return ErrInvalidReference
	}
	trimmed := bytes.TrimSpace(data)
	if bytes.Equal(trimmed, []byte("null")) || len(trimmed) == 0 {
		return ErrInvalidReference
	}
	dec := json.NewDecoder(bytes.NewReader(trimmed))
	dec.DisallowUnknownFields()
	var wire []durableRef
	if err := dec.Decode(&wire); err != nil {
		return errors.Join(ErrInvalidReference, err)
	}
	var extra any
	if err := dec.Decode(&extra); err != io.EOF {
		if err == nil {
			return ErrInvalidReference
		}
		return errors.Join(ErrInvalidReference, err)
	}
	refs := make([]Ref, len(wire))
	for i, r := range wire {
		if strings.TrimSpace(r.Name) == "" || strings.TrimSpace(r.Version) == "" {
			return ErrInvalidReference
		}
		if i > 0 && wire[i-1].Name >= r.Name {
			return ErrInvalidReference
		}
		refs[i] = Ref{Name: r.Name, Version: r.Version}
	}
	*s = Set{refs: refs}
	return nil
}

func MarshalCanonicalJSON(s Set) ([]byte, error) { return s.MarshalJSON() }

func ParseCanonicalJSON(data []byte) (Set, error) {
	var s Set
	if err := s.UnmarshalJSON(data); err != nil {
		return Set{}, err
	}
	return s, nil
}
