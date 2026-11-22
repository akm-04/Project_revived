// Package otarelease owns the OTA release value, its database-row validation
// and the MID 2 update scheduler rules (I11A_OTA_RELEASE_V1).
package otarelease

import (
	"cmp"
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// Version is one release number on the client's single version line.
type Version struct {
	Major int64
	Minor int64
	Patch int64
}

var versionPattern = regexp.MustCompile(`^[0-9]+\.[0-9]+\.[0-9]+$`)

// ParseVersion accepts only a strictly numeric x.y.z release number.
func ParseVersion(text string) (Version, error) {
	if !versionPattern.MatchString(text) {
		return Version{}, fmt.Errorf("otarelease: version %q is not x.y.z", text)
	}
	parts := strings.Split(text, ".")
	numbers := make([]int64, len(parts))
	for index, part := range parts {
		number, err := strconv.ParseInt(part, 10, 64)
		if err != nil {
			return Version{}, fmt.Errorf("otarelease: version %q: %w", text, err)
		}
		numbers[index] = number
	}
	return Version{Major: numbers[0], Minor: numbers[1], Patch: numbers[2]}, nil
}

func (v Version) String() string {
	return fmt.Sprintf("%d.%d.%d", v.Major, v.Minor, v.Patch)
}

// Compare orders versions numerically like the client's compareVersion
// (UpdateScene_64.lua:184-201), so 1.631.10 sorts above 1.631.9.
func (v Version) Compare(other Version) int {
	if order := cmp.Compare(v.Major, other.Major); order != 0 {
		return order
	}
	if order := cmp.Compare(v.Minor, other.Minor); order != 0 {
		return order
	}
	return cmp.Compare(v.Patch, other.Patch)
}
