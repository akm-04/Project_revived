package builtin

import (
	"errors"
	"sort"
	"unicode/utf8"
)

type PublicProfilePolicy struct {
	SchemaVersion      int      `json:"schema_version"`
	PolicyID           string   `json:"policy_id"`
	ModerationPolicyID string   `json:"moderation_policy_id"`
	NameSourceSHA256   string   `json:"name_source_sha256"`
	FilterSourceSHA256 string   `json:"filter_source_sha256"`
	ShowSourceSHA256   string   `json:"show_source_sha256"`
	Words              []string `json:"words"`
	ShowTypeIDs        []int64  `json:"show_type_ids"`
	HideSubtypes       []int16  `json:"hide_subtypes"`
	IntroCodepoints    int      `json:"intro_codepoints"`
	SelectedLimit      int      `json:"selected_limit"`
}

func (p PublicProfilePolicy) Validate() error {
	if p.SchemaVersion != 1 || p.PolicyID != "I7B_PUBLIC_V1" || p.ModerationPolicyID != "PROFILE_SCALAR_CASE_SENSITIVE_SPACE_MASK_V1" || p.NameSourceSHA256 != "2254bb1bb4283199a112cb94a7e14e82ac28cd29e3a19e281d11faf23d9ec316" || p.FilterSourceSHA256 != "e961a9a0029c90cce75d8deee23d066ba4d74bc133e733625dae5b43e0c34783" || p.ShowSourceSHA256 != "ca342990ff24d8c5a4c12b270401c276b3e29597d43555f30978a2c5162afeb6" || p.IntroCodepoints != 40 || p.SelectedLimit != 4 || len(p.Words) != 55 || !sort.StringsAreSorted(p.Words) || len(p.ShowTypeIDs) != 11 || len(p.HideSubtypes) != 2 || p.HideSubtypes[0] != 2 || p.HideSubtypes[1] != 4 {
		return errors.New("unqualified PublicProfile content policy")
	}
	for i, w := range p.Words {
		if w == "" || !utf8.ValidString(w) || (i > 0 && p.Words[i-1] == w) {
			return errors.New("invalid moderation corpus")
		}
	}
	for i, id := range p.ShowTypeIDs {
		if id != int64(1001+i) {
			return errors.New("invalid show metadata")
		}
	}
	return nil
}
