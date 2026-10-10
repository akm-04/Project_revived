package publication

import (
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/publication"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"strings"
	"testing"
	"time"
)

func TestStockInactiveAndManualReadShape(t *testing.T) {
	m, e := Announcement(app.View{})
	if e != nil || m["contents"] != "{\"contents\":[]}" {
		t.Fatal(m, e)
	}
	b, e := Board(app.View{})
	if e != nil || len(b["contents"].([]map[string]any)) != 0 {
		t.Fatal(b, e)
	}
	p := Picture(app.View{})
	if p["has_read"] != 1 || len(p["contents"].([]pub.PictureItem)) != 0 {
		t.Fatal(p)
	}
	p = Picture(app.View{Visible: true, HasRead: true, Set: pub.Set{Items: []pub.Item{{Picture: &pub.PictureItem{Weight: 3}}, {Picture: &pub.PictureItem{Weight: 1}}}}})
	encoded, _ := json.Marshal(p)
	if !strings.Contains(string(encoded), `"has_read":1`) || len(p["contents"].([]pub.PictureItem)) != 2 || p["contents"].([]pub.PictureItem)[0].Weight != 1 {
		t.Fatal(string(encoded))
	}
}
func TestPublishedInputSourceConstraints(t *testing.T) {
	id, _ := ids.NewUUID()
	s := pub.Set{ID: id, Family: pub.Board, StartsAt: time.Now(), Items: []pub.Item{{Board: &pub.BoardItem{ID: 1}}}}
	if e := s.Validate(); e != nil {
		t.Fatal(e)
	}
	s.Items[0].Board.ID = pub.MaxWireID + 1
	if s.Validate() == nil {
		t.Fatal("non Lua-exact board ID accepted")
	}
	s.Items[0].Board.ID = 1
	s.Items[0].Board.ImageURL = "https://example.invalid/image.png"
	if s.Validate() == nil {
		t.Fatal("unsupported downloader prefix accepted")
	}
	s.Items[0] = pub.Item{Picture: &pub.PictureItem{}}
	if s.Validate() == nil {
		t.Fatal("mixed family accepted")
	}
}
