package profile

import (
	"errors"
	"slices"
	"sort"
	"strings"
	"unicode/utf8"
)

const PolicyVersion = "I7B_PUBLIC_V1"

var ErrInvalidPreferences = errors.New("invalid PublicProfile preferences")

type Preferences struct {
	Intro                    string
	ShowTypeIDs              []int64
	HideSubtypes             []int16
	ShareSwitch, IsFirstTime int16
	PolicyVersion            string
}

// Change assigns only source-qualified preference fields. Flags have no command here.
type Change struct {
	Intro        *string
	ShowTypeIDs  *[]int64
	HideSubtypes *[]int16
}

func Defaults() Preferences {
	return Preferences{ShowTypeIDs: []int64{}, HideSubtypes: []int16{}, PolicyVersion: PolicyVersion}
}
func (p Preferences) Clone() Preferences {
	p.ShowTypeIDs = append([]int64{}, p.ShowTypeIDs...)
	p.HideSubtypes = append([]int16{}, p.HideSubtypes...)
	return p
}
func (p Preferences) Validate() error {
	if p.PolicyVersion != PolicyVersion || !utf8.ValidString(p.Intro) || strings.ContainsRune(p.Intro, 0) || utf8.RuneCountInString(p.Intro) > 40 || len(p.ShowTypeIDs) > 4 || len(p.HideSubtypes) > 2 || (p.ShareSwitch != 0 && p.ShareSwitch != 1) || (p.IsFirstTime != 0 && p.IsFirstTime != 1) {
		return ErrInvalidPreferences
	}
	seen := map[int64]bool{}
	for _, id := range p.ShowTypeIDs {
		if id < 1001 || id > 1011 || seen[id] {
			return ErrInvalidPreferences
		}
		seen[id] = true
	}
	for i, id := range p.HideSubtypes {
		if (id != 2 && id != 4) || (i > 0 && p.HideSubtypes[i-1] >= id) {
			return ErrInvalidPreferences
		}
	}
	return nil
}
func (p Preferences) Apply(c Change) (Preferences, error) {
	p = p.Clone()
	if c.Intro != nil {
		p.Intro = *c.Intro
	}
	if c.ShowTypeIDs != nil {
		p.ShowTypeIDs = append([]int64{}, (*c.ShowTypeIDs)...)
	}
	if c.HideSubtypes != nil {
		p.HideSubtypes = append([]int16{}, (*c.HideSubtypes)...)
		sort.Slice(p.HideSubtypes, func(i, j int) bool { return p.HideSubtypes[i] < p.HideSubtypes[j] })
	}
	return p, p.Validate()
}
func (p Preferences) Equal(q Preferences) bool {
	return p.Intro == q.Intro && slices.Equal(p.ShowTypeIDs, q.ShowTypeIDs) && slices.Equal(p.HideSubtypes, q.HideSubtypes) && p.ShareSwitch == q.ShareSwitch && p.IsFirstTime == q.IsFirstTime && p.PolicyVersion == q.PolicyVersion
}
