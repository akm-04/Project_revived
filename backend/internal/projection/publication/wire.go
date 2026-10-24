package publication

import (
	"encoding/json"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"sort"
)

func Announcement(v pub.View) (map[string]any, error) {
	rows := []pub.Section{}
	if v.Visible {
		for _, i := range v.Set.Items {
			rows = append(rows, *i.Announcement)
		}
	}
	b, e := json.Marshal(map[string]any{"contents": rows})
	return map[string]any{"contents": string(b)}, e
}
func Board(v pub.View) (map[string]any, error) {
	rows := []map[string]any{}
	if v.Visible {
		for _, i := range v.Set.Items {
			x := i.Board
			b, e := json.Marshal(map[string]any{"content": x.Content, "img_url": x.ImageURL})
			if e != nil {
				return nil, e
			}
			rows = append(rows, map[string]any{"notice_id": x.ID, "table_id": x.ID, "title": x.Title, "start_date": x.StartDate, "content": string(b)})
		}
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i]["notice_id"].(int64) > rows[j]["notice_id"].(int64) })
	return map[string]any{"contents": rows}, nil
}
func Picture(v pub.View) map[string]any {
	rows := []pub.PictureItem{}
	if v.Visible {
		for _, i := range v.Set.Items {
			rows = append(rows, *i.Picture)
		}
	}
	sort.SliceStable(rows, func(i, j int) bool { return rows[i].Weight < rows[j].Weight })
	read := 1
	if v.Visible && !v.HasRead {
		read = 0
	}
	return map[string]any{"contents": rows, "has_read": read}
}
