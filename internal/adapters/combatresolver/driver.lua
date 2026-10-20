-- Transport-detached BattleCreateReport run over the frozen snapshot. The
-- original server wrapper's sendBattleResult is replaced by report capture.
local MaxFrames = 1000000
local input = combat_input
local waves = {}
for i, wave in ipairs(input.waves_b) do
	waves[i] = combat_models(wave)
end
local herosA = combat_models(input.team_a)
local herosB = waves
-- SUPER_ARENA BattleCreateReport takes team groups; one round is team1.
if input.campaign_type == xyd.CampaignType.SUPER_ARENA then
	herosA, herosB = { team1 = herosA }, { team1 = waves[1] }
end
local Report = require("app.scenes.BattleCreateReport")
local battle = Report.new({
	battleType = xyd.BattleType.CreateReport,
	campaignType = input.campaign_type,
	battleID = input.battle_id,
	herosA = herosA,
	herosB = herosB,
	petsA = combat_models(input.pets_a),
	petsB = combat_models(input.pets_b),
	fighterInfo = {},
})
function battle:sendBattleResult()
	self:writeReport()
	local collect, books = combat_report_context()
	-- Server-wrapper keys read back by NormalHero/SuperHero on ReplayReport.
	self.report_.hero_collect_attr = collect
	self.report_.zhuge_book_skill_num = books
	combat_output = {
		report = combat_json_encode(self.report_),
		star = self:getBattleStar(),
		frames = ngx.ctx.battle.count,
		timed_out = self.timeOut_ and true or false,
		report_error = self:checkBattleReport() == 1,
	}
end
battle:run()
local frames = 0
while not ngx.ctx.battle.isEnd do
	frames = frames + 1
	if frames > MaxFrames then
		error("COMBAT_DRIVER_FRAME_BOUND")
	end
	combat_next_frame()
end
assert(combat_output, "COMBAT_DRIVER_NO_REPORT")
