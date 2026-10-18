package ranking

import "time"

type GirlsPeriod struct {
	Server     int64
	Policy     string
	Week       time.Time
	Generation int64
	SettledAt  *time.Time
}

func (p GirlsPeriod) Validate(s GirlsSnapshot) error {
	w, e := GirlsWeek(s.ObservedAt)
	if e != nil || s.Validate() != nil || p.Server != int64(s.Server) || p.Policy != s.Policy || !p.Week.Equal(w) || p.Generation != s.Generation || p.SettledAt != nil && p.SettledAt.Before(s.ObservedAt) {
		return ErrSnapshot
	}
	return nil
}

type GirlsAwardEvidence struct {
	Snapshot           GirlsSnapshot
	Award              GirlsAward
	Server, Generation int64
	SnapshotDigest     string
	SettledAt          time.Time
}

func (v GirlsAwardEvidence) Validate() error {
	if v.Server != int64(v.Snapshot.Server) || v.Generation != v.Snapshot.Generation || v.SnapshotDigest != v.Snapshot.Digest || v.SettledAt.Before(v.Snapshot.ObservedAt) {
		return ErrSnapshot
	}
	a, e := v.Snapshot.Awards()
	if e != nil {
		return e
	}
	for _, x := range a {
		y := v.Award
		if x.Player == y.Player && x.Rank == y.Rank && x.TitleID == y.TitleID && x.OriginKey == y.OriginKey && x.StartsAt.Equal(y.StartsAt) && x.EndTime == y.EndTime {
			return nil
		}
	}
	return ErrSnapshot
}
