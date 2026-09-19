package activity

import domainactivity "gxb.local/backend/v2/internal/domain/activity"

func Row(p domainactivity.Projection) map[string]any {
	return map[string]any{
		"table_id":   p.TableID,
		"is_open":    p.IsOpen,
		"start_time": p.StartTime,
		"end_time":   p.EndTime,
		"days":       p.Days,
		"details":    p.Details,
	}
}

func List(ps []domainactivity.Projection) map[string]any {
	rows := make([]any, 0, len(ps))
	for _, p := range ps {
		rows = append(rows, Row(p))
	}
	return map[string]any{"list": rows}
}
