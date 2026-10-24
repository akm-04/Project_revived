package topfloor

// Display is the public face of a ladder occupant in source populate shapes.
type Display struct {
	Occupant     Occupant
	Rank         int64
	Name         string
	Level        int64
	AvatarID     int64
	FrameID      int64
	ConquerLevel int64
	ConquerLoop  int64
	GuildID      int64
	GuildName    string
	Wins         int64
	Force        int64
	Heroes       []map[string]any
	Pet          map[string]any
}
