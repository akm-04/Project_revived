package player

import (
	"errors"
	"strconv"
	"strings"
)

// ChatCosmetics is response metadata, never an entitlement or selection owner.
type ChatCosmetics struct{ TitleID, UniqueID, TitleEnd, BubbleID, BubbleEnd int64 }

func (v ChatCosmetics) Strings() (string, string, error) {
	for _, n := range []int64{v.TitleID, v.UniqueID, v.TitleEnd, v.BubbleID, v.BubbleEnd} {
		if n < 0 || n > 9007199254740991 {
			return "", "", errors.New("invalid chat cosmetics")
		}
	}
	if v.BubbleID < 1 || (v.TitleID == 0 && (v.UniqueID != 0 || v.TitleEnd != 0)) {
		return "", "", errors.New("invalid chat cosmetics")
	}
	title := "@@@@"
	if v.TitleID > 0 {
		title = strconv.FormatInt(v.TitleID, 10) + "@" + strconv.FormatInt(v.UniqueID, 10) + "@" + strconv.FormatInt(v.TitleEnd, 10)
	}
	return title, strconv.FormatInt(v.BubbleID, 10) + "@" + strconv.FormatInt(v.BubbleEnd, 10), nil
}

// ValidateChatCosmeticString admits only the recovered finite decimal grammar.
// It checks shape and exact numeric transport, not ownership (which is read by Player).
func ValidateChatCosmeticString(s string, title bool) bool {
	if title && s == "@@@@" {
		return true
	}
	fields := strings.Split(s, "@")
	size := 2
	if title {
		size = 3
	}
	if len(fields) != size {
		return false
	}
	for i, x := range fields {
		n, e := strconv.ParseInt(x, 10, 64)
		if e != nil || n < 0 || n > 9007199254740991 || strconv.FormatInt(n, 10) != x || (i == 0 && n == 0) {
			return false
		}
	}
	return true
}
