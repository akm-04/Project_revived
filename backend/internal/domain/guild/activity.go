package guild

// Stock caps the client displays (misc.lua guild_vitality_limit1, guild_vitality_limit2).
const (
	ActivityDailyCap int64 = 1000
	ActivityGuildCap int64 = 280000
)

// ActivityBalance is a guild's spendable activity: the folded balance plus what
// has not been folded yet, clamped to the stock cap (I9_GUILD_ACTIVITY_V1 C4).
func ActivityBalance(vitality, unfolded int64) int64 {
	return min(ActivityGuildCap, vitality+unfolded)
}

// LifetimeAfterLeaving applies guild_vitality_quite 0.5 to a leaver's lifetime
// contribution (I9_GUILD_ACTIVITY_V1 C7, D402).
func LifetimeAfterLeaving(lifetime int64) int64 {
	return lifetime / 2
}

// PlayerActivity is one member's own activity as the stock client reads it:
// today_huoyue, the lifetime huoyue_num net of forfeits, and the seven-day
// activity shown on a roster row (I9_GUILD_ACTIVITY_V1 C3, C10).
type PlayerActivity struct {
	Today    int64
	Lifetime int64
	SevenDay int64
}

// ActivityBoardRow is one guild's row on LOAD_RANK_LIST type 4
// (I9_GUILD_ACTIVITY_V1 C12). ThreeDay is the 3-day active points the client
// displays and orders by (rank.lua:120-137).
type ActivityBoardRow struct {
	GuildID       int64
	Name          string
	Icon          int64
	Description   string
	MinAllowLevel int64
	MemberNum     int64
	ThreeDay      int64
}
