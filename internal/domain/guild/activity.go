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
