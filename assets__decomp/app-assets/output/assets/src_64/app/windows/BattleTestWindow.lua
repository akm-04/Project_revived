local var_0_0 = class("BattleTestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "images/input_box.png"
local var_0_2 = {
	"10001053",
	"5",
	"40002053",
	"10001213",
	"5",
	"",
	"11004",
	"5",
	"",
	"11005",
	"5",
	"",
	"11007",
	"5",
	"",
	"10001053",
	"5",
	"40002053",
	"10001213",
	"5",
	"",
	"11004",
	"5",
	"",
	"11005",
	"5",
	"",
	"",
	"5",
	""
}
local var_0_3 = {
	"",
	"",
	"",
	"",
	"",
	""
}

function var_0_0.willOpen(arg_1_0, arg_1_1)
	var_0_0.super.willOpen(arg_1_0, arg_1_1)
	arg_1_0:layout()

	arg_1_0.reports = {}
	arg_1_0.replays = {}
end

function var_0_0.layout(arg_2_0)
	arg_2_0.editBox = {}
	arg_2_0.petBox = {}

	for iter_2_0 = 1, 2 do
		local var_2_0 = arg_2_0:nodeByName("node_team_" .. iter_2_0)

		for iter_2_1 = 1, 5 do
			local var_2_1 = var_2_0:getChildByName("node_partner_" .. iter_2_1)
			local var_2_2 = var_2_1:getChildByName("partner_id")
			local var_2_3 = var_2_1:getChildByName("star")
			local var_2_4 = var_2_1:getChildByName("skin_id")
			local var_2_5 = (iter_2_0 - 1) * 15 + (iter_2_1 - 1) * 3

			arg_2_0.editBox[var_2_5 + 1] = arg_2_0:createEditBox(var_2_2)
			arg_2_0.editBox[var_2_5 + 2] = arg_2_0:createEditBox(var_2_3)
			arg_2_0.editBox[var_2_5 + 3] = arg_2_0:createEditBox(var_2_4)

			arg_2_0.editBox[var_2_5 + 1]:setText(var_0_2[var_2_5 + 1])
			arg_2_0.editBox[var_2_5 + 2]:setText(var_0_2[var_2_5 + 2])
			arg_2_0.editBox[var_2_5 + 3]:setText(var_0_2[var_2_5 + 3])
		end

		local var_2_6 = var_2_0:getChildByName("node_pet")
		local var_2_7 = var_2_6:getChildByName("partner_id")
		local var_2_8 = var_2_6:getChildByName("star")
		local var_2_9 = var_2_6:getChildByName("skin_id")
		local var_2_10 = (iter_2_0 - 1) * 3

		arg_2_0.petBox[var_2_10 + 1] = arg_2_0:createEditBox(var_2_7)
		arg_2_0.petBox[var_2_10 + 2] = arg_2_0:createEditBox(var_2_8)
		arg_2_0.petBox[var_2_10 + 3] = arg_2_0:createEditBox(var_2_9)

		arg_2_0.petBox[var_2_10 + 1]:setText(var_0_3[var_2_10 + 1])
		arg_2_0.petBox[var_2_10 + 2]:setText(var_0_3[var_2_10 + 2])
		arg_2_0.petBox[var_2_10 + 3]:setText(var_0_3[var_2_10 + 3])
	end

	arg_2_0.timesBox = arg_2_0:createEditBox(arg_2_0:nodeByName("times"))

	arg_2_0.timesBox:setText("1")
	arg_2_0:nodeByName("btn_start"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("btn_start"), arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_2_0.params = arg_2_0:sortParams()
			arg_2_0.times = tonumber(arg_2_0.timesBox:getText())

			arg_2_0:webRequest()
			arg_2_0:nodeByName("btn_start"):setTouchEnabled(false)
			arg_2_0:nodeByName("btn_start"):setBright(false)
		end
	end)
	arg_2_0:nodeByName("btn_record"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("btn_record"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = {
				reports = arg_2_0.reports,
				replays = arg_2_0.replays
			}

			xyd.WindowManager.get():openWindow("battle_test_output", var_4_0)
		end
	end)
	arg_2_0:nodeByName("btn_clear"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("btn_clear"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_2_0.reports = {}

			xyd.WindowManager.get():openWindow("toast", {
				message = "已清空"
			})
		end
	end)
end

function var_0_0.createEditBox(arg_6_0, arg_6_1)
	local var_6_0 = ccui.EditBox:create(arg_6_1:getContentSize(), var_0_1)

	var_6_0:setAnchorPoint(0, 0)
	var_6_0:setOpacity(0)
	var_6_0:pos(0, 0):addTo(arg_6_1)
	var_6_0:setFontColor(cc.c3b(0, 0, 0))

	return var_6_0
end

function var_0_0.webRequest(arg_7_0)
	if arg_7_0.times > 0 then
		xyd.Backend.get():request(xyd.mid.GET_TEST_REPORT, arg_7_0.params, function(arg_8_0, arg_8_1)
			if arg_8_0 == xyd.error.OK then
				arg_7_0:dealWithResponse(arg_8_1.report)
				arg_7_0:webRequest()
			end
		end)
	else
		arg_7_0:nodeByName("btn_start"):setTouchEnabled(true)
		arg_7_0:nodeByName("btn_start"):setBright(true)
		print("拉戰報finish=========================")
		xyd.WindowManager.get():openWindow("toast", {
			message = "拉戰報finish"
		})
	end

	arg_7_0.times = arg_7_0.times - 1
end

function var_0_0.sortParams(arg_9_0)
	local var_9_0 = {
		formationA = {
			formation = {}
		},
		formationB = {
			formation = {}
		}
	}

	for iter_9_0 = 1, 5 do
		local var_9_1 = (iter_9_0 - 1) * 3

		if arg_9_0.editBox[var_9_1 + 1]:getText() == "" then
			break
		end

		local var_9_2 = {
			table_id = tonumber(arg_9_0.editBox[var_9_1 + 1]:getText()),
			star = tonumber(arg_9_0.editBox[var_9_1 + 2]:getText()) or 5,
			skin_id = tonumber(arg_9_0.editBox[var_9_1 + 3]:getText()) or 0,
			skill_ids = {
				50050144,
				20050144,
				30050144,
				40050144,
				60050144,
				0
			}
		}

		table.insert(var_9_0.formationA.formation, var_9_2)
	end

	for iter_9_1 = 1, 5 do
		local var_9_3 = (iter_9_1 - 1) * 3 + 15

		if arg_9_0.editBox[var_9_3 + 1]:getText() == "" then
			break
		end

		local var_9_4 = {
			table_id = tonumber(arg_9_0.editBox[var_9_3 + 1]:getText()),
			star = tonumber(arg_9_0.editBox[var_9_3 + 2]:getText()) or 5,
			skin_id = tonumber(arg_9_0.editBox[var_9_3 + 3]:getText()) or 0,
			skill_ids = {
				50050144,
				20050144,
				30050144,
				40050144,
				60050144,
				0
			}
		}

		table.insert(var_9_0.formationB.formation, var_9_4)
	end

	local var_9_5
	local var_9_6 = (arg_9_0.petBox[1]:getText() ~= "" or nil) and {
		table_id = tonumber(arg_9_0.petBox[1]:getText()),
		star = tonumber(arg_9_0.petBox[2]:getText()) or 5,
		skin_id = tonumber(arg_9_0.petBox[3]:getText()) or 0
	}

	var_9_0.formationA.pet = var_9_6

	local var_9_7
	local var_9_8 = (arg_9_0.petBox[4]:getText() ~= "" or nil) and {
		table_id = tonumber(arg_9_0.petBox[4]:getText()),
		star = tonumber(arg_9_0.petBox[5]:getText()) or 5,
		skin_id = tonumber(arg_9_0.petBox[6]:getText()) or 0
	}

	var_9_0.formationB.pet = var_9_8

	return var_9_0
end

function var_0_0.dealWithResponse(arg_10_0, arg_10_1)
	local var_10_0 = true
	local var_10_1 = import("app.model.Hero")
	local var_10_2 = import("app.model.Pet")

	if arg_10_1 == nil or next(arg_10_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = stringLocalizer:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_10_3 = {}
	local var_10_4 = json.decode(arg_10_1.battle_report)

	var_10_3.herosA = {}
	var_10_3.herosB = {}
	var_10_3.summonMonsters = {}
	var_10_3.campaignType = xyd.CampaignType.ARENA
	var_10_3.battleID = xyd.MapBattleID.ARENA
	var_10_3.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_10_4

	local var_10_5 = {}
	local var_10_6 = {}

	for iter_10_0, iter_10_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_10_7 = string.sub(iter_10_0, 1, 1)
		local var_10_8 = tonumber(string.sub(iter_10_0, 3, 3))

		if var_10_7 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_9 = var_10_1.new()

			var_10_9:populate(iter_10_1.hero)
			var_10_9:setReportData(iter_10_1)

			if var_10_0 then
				var_10_9.harms = iter_10_1.harms
				var_10_9.willDie = (iter_10_1.die_count or 0) ~= -1
			end

			var_10_3.herosA[var_10_8] = var_10_9
		elseif var_10_7 == "A" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_10 = var_10_2.new()

			var_10_10:populate(iter_10_1.hero)
			var_10_10:setReportData(iter_10_1)

			if var_10_0 then
				var_10_10.harms = iter_10_1.harms
				var_10_10.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.petA = {
					var_10_10
				}
			else
				var_10_3.petsA = {
					var_10_10
				}
			end
		elseif var_10_7 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.None then
			local var_10_11 = var_10_1.new()

			var_10_11:populate(iter_10_1.hero)
			var_10_11:setReportData(iter_10_1)

			if var_10_0 then
				var_10_11.harms = iter_10_1.harms
				var_10_11.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.herosB[var_10_8] = var_10_11
			else
				var_10_5[var_10_8] = var_10_11
			end
		elseif var_10_7 == "B" and tonumber(iter_10_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_10_12 = var_10_2.new()

			var_10_12:populate(iter_10_1.hero)
			var_10_12:setReportData(iter_10_1)

			if var_10_0 then
				var_10_12.harms = iter_10_1.harms
				var_10_12.willDie = (iter_10_1.die_count or 0) ~= -1
				var_10_3.petB = {
					var_10_12
				}
			else
				var_10_3.petsB = {
					var_10_12
				}
			end
		elseif tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_10_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_10_13 = var_10_1.new()

			var_10_13:populate(iter_10_1.hero)
			var_10_13:setReportData(iter_10_1)

			var_10_6[iter_10_0] = var_10_13
		end
	end

	table.insert(arg_10_0.replays, arg_10_1)

	local var_10_14 = {
		cost_time = arg_10_1.cost_time
	}
	local var_10_15 = {}
	local var_10_16 = {}
	local var_10_17 = 0
	local var_10_18 = 0
	local var_10_19 = 0
	local var_10_20 = 0

	for iter_10_2, iter_10_3 in ipairs(var_10_3.herosA) do
		local var_10_21 = iter_10_3:getReportData()

		if var_10_21.die_count == -1 then
			var_10_17 = var_10_17 + 1
		end

		var_10_19 = var_10_19 + var_10_21.harms

		local var_10_22 = {
			table_id = iter_10_3:getTableID(),
			harms = var_10_21.harms,
			bearHarms = var_10_21.bear_harms,
			die_count = var_10_21.die_count
		}

		table.insert(var_10_15, var_10_22)
	end

	var_10_14.teamA = var_10_15

	for iter_10_4, iter_10_5 in ipairs(var_10_3.herosB) do
		local var_10_23 = iter_10_5:getReportData()

		if var_10_23.die_count == -1 then
			var_10_18 = var_10_18 + 1
		end

		var_10_20 = var_10_20 + var_10_23.harms

		local var_10_24 = {
			table_id = iter_10_5:getTableID(),
			harms = var_10_23.harms,
			bearHarms = var_10_23.bear_harms,
			die_count = var_10_23.die_count
		}

		table.insert(var_10_16, var_10_24)
	end

	var_10_14.teamB = var_10_16
	var_10_14.aliveNumA = var_10_17
	var_10_14.aliveNumB = var_10_18

	local var_10_25

	var_10_14.winner = var_10_18 < var_10_17 and "A" or var_10_17 < var_10_18 and "B" or var_10_20 <= var_10_19 and "A" or "B"

	table.insert(arg_10_0.reports, var_10_14)
	print("===========================================", #arg_10_0.reports)
end

return var_0_0
