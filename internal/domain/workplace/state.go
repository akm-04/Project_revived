package workplace

import "gxb.local/backend/v2/internal/domain/grant"

type Occurrence struct {
	ID           string
	Team         int64
	Job          int64
	Revision     string
	PolicySHA    string
	Start        int64
	Quote        Quote
	Workers      []Worker
	Fingerprint  string
	Award        map[string]any
	Lines        []grant.Line
	RivalReward  [2]int64
	Attempt      string
	PartnersInfo []map[string]any
}
type State struct {
	Sequence      int64
	Day           int64
	Initialized   bool
	BonusLocation int64
	BonusBase     int64
	BonusUsed     bool
	Slots         map[int64]*Occurrence
	Selections    map[int64][]int64
	Last          map[int64]map[string]any
	Diary         []map[string]any
}

func (s *State) Init() {
	if s.Slots == nil {
		s.Slots = map[int64]*Occurrence{}
	}
	if s.Selections == nil {
		s.Selections = map[int64][]int64{}
	}
	if s.Last == nil {
		s.Last = map[int64]map[string]any{}
	}
	if s.Diary == nil {
		s.Diary = []map[string]any{}
	}
}
func (o Occurrence) Ready(now int64) bool { return now > o.Start+o.Quote.Seconds }
func (s State) Busy(partner int64) bool {
	for _, o := range s.Slots {
		if o != nil {
			for _, w := range o.Workers {
				if w.PartnerID == partner {
					return true
				}
			}
		}
	}
	return false
}
