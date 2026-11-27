package publication

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

func pictureSet(pic, smallPic string) Set {
	return Set{
		ID:       ids.UUID{1},
		Family:   Picture,
		ServerID: 1,
		StartsAt: time.Unix(0, 0).UTC(),
		Items:    []Item{{Picture: &PictureItem{Weight: 1, Pic: pic, SmallPic: smallPic}}},
	}
}

// TestImageAcceptsBothClientSchemes proves G40: the client patch leaves http and
// https alone, so publication accepts both and still refuses non-URLs.
func TestImageAcceptsBothClientSchemes(t *testing.T) {
	accepted := []string{
		"",
		"http://example.test/p.png",
		"https://example.test/p.png",
		"https://example.test/media/0123456789abcdef.png",
		"http://example.test:8080/p.png",
	}
	for _, value := range accepted {
		if err := pictureSet(value, "").Validate(); err != nil {
			t.Fatalf("%q was refused: %v", value, err)
		}
	}
	refused := []string{
		"https://",
		"http://",
		"ftp://example.test/p.png",
		"javascript:alert(1)",
		"//example.test/p.png",
		"https:// example.test/p.png",
		"http:///no-host",
		"example.test/p.png",
	}
	for _, value := range refused {
		if err := pictureSet(value, "").Validate(); err == nil {
			t.Fatalf("%q was accepted", value)
		}
	}
}
