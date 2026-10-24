-- Constructs the source tables the server-branch battle builds on first use, so
-- a prepared worker holds them before any attempt data arrives (I8-2B). A table
-- missing from this list still constructs lazily; only latency changes.
for _, name in ipairs({ "hero", "item", "skill", "dbuff", "battle", "model", "misc", "modelPoints", "cabinetSkillTable",
	"skinSkill", "stoneEvolution", "sound", "libraryAmour", "inscriptionSuit", "dormHouse", "battleConfig" }) do
	local _ = xyd.tables[name].__combat_prepare
end
