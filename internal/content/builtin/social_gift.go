package builtin

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
)

type SocialGiftMapping struct {
	Level  int64 `json:"level"`
	GiftID int64 `json:"gift_id"`
}
type SocialGiftCatalog struct {
	SchemaVersion     int                 `json:"schema_version"`
	ResourceKey       string              `json:"resource_key"`
	Amount            int64               `json:"amount"`
	SendCap           int64               `json:"send_cap"`
	ClaimCap          int64               `json:"claim_cap"`
	Policy            string              `json:"policy"`
	Selector          string              `json:"selector"`
	VectorFingerprint string              `json:"vector_fingerprint"`
	RewardVector      map[string]string   `json:"reward_vector"`
	Mapping           []SocialGiftMapping `json:"mapping"`
}

func (c SocialGiftCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ResourceKey != "friendship_coin" || c.Amount != 5 || c.SendCap != 10 || c.ClaimCap != 10 || c.Policy != "SOCIAL_GIFT_DAY_V1" || c.Selector != "UNKNOWN_UNIFORM_ONLY" || len(c.Mapping) != 100 {
		return errors.New("unqualified SocialGift content")
	}
	seen := map[int64]bool{}
	for i, r := range c.Mapping {
		if seen[r.GiftID] {
			return errors.New("SocialGift duplicate gift mapping")
		}
		seen[r.GiftID] = true
		if r.Level != int64(i+1) || r.GiftID < 1 {
			return errors.New("SocialGift mapping drift")
		}
	}
	expected := map[string]string{"arena_coin": "0", "badge": "0", "crystal": "0", "drops": "0", "energy": "0", "equip": "0", "ex_badge": "0", "exp": "0", "friendship_coin": "5", "item_nums": "0", "items": "0", "lucky_coin": "0", "mana": "0", "march_coin": "0", "skin_coin": "0", "skin_fragment": "0", "soul": "0", "spirit_energy": "", "summon_id": "0", "summon_init_time": "", "tutor_coin": "", "vip": "0", "vip_exp": "0"}
	if len(c.RewardVector) != len(expected) {
		return errors.New("SocialGift incomplete vector")
	}
	for k, v := range expected {
		if c.RewardVector[k] != v {
			return errors.New("SocialGift vector drift")
		}
	}
	if c.RewardVector["friendship_coin"] != "5" {
		return errors.New("SocialGift amount drift")
	}
	for k, v := range c.RewardVector {
		if k != "friendship_coin" && v != "" && v != "0" {
			return errors.New("unqualified SocialGift vector")
		}
	}
	raw, e := json.Marshal(c.RewardVector)
	if e != nil {
		return e
	}
	d := sha256.Sum256(append(raw, byte(10)))
	if hex.EncodeToString(d[:]) != c.VectorFingerprint {
		return errors.New("SocialGift vector digest drift")
	}
	return nil
}
