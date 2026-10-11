package builtin

import "errors"

type PublicShowcasePolicy struct {
	SchemaVersion        int    `json:"schema_version"`
	PolicyID             string `json:"policy_id"`
	Slots                int    `json:"slots"`
	VisibleSlots         int    `json:"visible_slots"`
	SignRule             string `json:"sign_rule"`
	DuplicateRule        string `json:"duplicate_rule"`
	IndexRule            string `json:"index_rule"`
	EmptyRecord          string `json:"empty_record"`
	WireRule             string `json:"wire_rule"`
	ModelSourceSHA256    string `json:"model_source_sha256"`
	SelectorSourceSHA256 string `json:"selector_source_sha256"`
}

func (p PublicShowcasePolicy) Validate() error {
	if p.SchemaVersion != 1 || p.PolicyID != "I7B_SHOWCASE_SELECTION_V1" || p.Slots != 6 || p.VisibleSlots != 5 || p.SignRule != "POSITIVE_OWNED_HERO_NEGATIVE_OWNED_PET_ZERO_EMPTY" || p.DuplicateRule != "FAMILY_CURRENT_TEMPLATE" || p.IndexRule != "CURRENT_CALLER_SNAPSHOT_ONE_BASED" || p.EmptyRecord != "OBJECT" || p.WireRule != "REQUIRED_PROVIDERS_BEFORE_WRITE_I7B6" || p.ModelSourceSHA256 != "022fcbf39167ac9197ce5034b32fd5833016742744ad3de118ceacf6f808cfb8" || p.SelectorSourceSHA256 != "e1db1b02194652043b289b2670501c0fc8226ccaba17c8e5eca1a915e715440e" {
		return errors.New("unqualified showcase selection policy")
	}
	return nil
}
