package operatorcatalog

// ScalarPresentations is the client-evidenced name and icon of the scalar
// resources (currencies, player exp and the temporal counters). The item
// presentation table does not cover them, so each entry cites the client source
// that draws or names it. A key the client does not name or draw stays out of
// this map, so its name and icon remain empty (UNKNOWN, never invented).
//
// Icons are res-relative paths, like the item icons. Names come from the
// translation table only where the client translates the currency.
var ScalarPresentations = map[string]ItemPresentation{
	// translation.lua:2059-2061 "COIN" (" Coin(s)"); ListItem.lua:26-27.
	"mana": {Name: "Coin(s)", Icon: "images/icon/eco/jinbi.png"},
	// translation.lua:2063-2065 "CRYSTAL" (" Diamond(s)"); ListItem.lua:28-29.
	"crystal": {Name: "Diamond(s)", Icon: "images/icon/eco/yuanbao.png"},
	// ListItem.lua:30-31.
	"arena_coin": {Icon: "images/icon/eco/shell.png"},
	// ListItem.lua:32-33.
	"top_coin": {Icon: "images/icon/eco/top_coin.png"},
	// ListItem.lua:34-35.
	"guild_coin": {Icon: "images/icon/eco/guild_coin.png"},
	// ListItem.lua:36-37.
	"region_coin": {Icon: "images/icon/eco/region_coin.png"},
	// ListItem.lua:40-41.
	"march_coin": {Icon: "images/icon/eco/march_coin.png"},
	// ListItem.lua:46-57.
	"spirit_stone":      {Icon: "images/icon/eco/spirit_stone.png"},
	"magic_liquid":      {Icon: "images/icon/eco/magic_liquid.png"},
	"magic_dust":        {Icon: "images/icon/eco/magic_dust.png"},
	"magic_energy":      {Icon: "images/icon/eco/magic_energy.png"},
	"friend_medal":      {Icon: "images/icon/eco/gay_coin.png"},
	"team_dungeon_coin": {Icon: "images/icon/eco/team_dungeon_coin.png"},
	// utils.lua:2506-2507 draws the war coin at the item border; utils.lua:2504-2505
	// the lucky coin.
	"war_coin":   {Icon: "images/icon/war_coin.png"},
	"lucky_coin": {Icon: "images/icon/lucky_coin.png"},
	// utils.lua:2516-2517 (the temporal energy counter).
	"energy": {Icon: "images/icon/energy.png"},
	// GiftAwardWindow.lua:98-99, :104-105, :110-111.
	"exp":             {Icon: "images/icon/eco/exp.png"},
	"friendship_coin": {Icon: "images/icon/eco/friendship_coin.png"},
	"king_coin":       {Icon: "images/icon/eco/king_coin.png"},
	// EventCentreUpgradeWindow.lua:183.
	"magic_exp": {Icon: "images/icon/eco/magic_exp.png"},
}
