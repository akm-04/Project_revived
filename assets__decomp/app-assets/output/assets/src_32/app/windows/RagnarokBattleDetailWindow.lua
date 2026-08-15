local var_0_0 = class("RagnarokBattleDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ragnarokBoss
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.skill

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.pos = arg_1_2.pos
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_hp"):setString(var_0_1:translation("RAGNAROK_BOSS_18"))
	arg_4_0:nodeByName("title_intro"):setString(var_0_1:translation("RAGNAROK_BOSS_19"))
	arg_4_0:nodeByName("title_skill"):setString(var_0_1:translation("RAGNAROK_BOSS_20"))
	arg_4_0:nodeByName("txt_fight"):setString(var_0_1:translation("RAGNAROK_BOSS_21"))

	local var_4_0 = var_0_2:monsterId(arg_4_0.ragnarok:getType(), arg_4_0.pos)
	local var_4_1 = var_0_3:getDes(var_4_0)
	local var_4_2 = xyd.createLabel(20, cc.c3b(52, 54, 55))

	var_4_2:setAnchorPoint(0, 1)
	var_4_2:setWidth(380)
	var_4_2:setLineHeight(30)
	var_4_2:setString(var_4_1)
	var_4_2:addTo(arg_4_0:nodeByName("pos_txt_intro"))

	local var_4_3 = var_0_3:modelID(var_4_0)
	local var_4_4 = xyd.HeroAnimation.new(nil, var_4_3, 0.5, {})

	var_4_4:addTo(arg_4_0:nodeByName("pos_boss"))
	var_4_4:idle(true)

	if arg_4_0.pos > 1 then
		var_4_4:setPosition(-40, 0)
	end

	local var_4_5 = var_0_3:name(var_4_0)

	arg_4_0:nodeByName("txt_boss_name"):setString(var_4_5)

	local var_4_6 = arg_4_0.ragnarok:getMonsterStatus()
	local var_4_7 = arg_4_0.ragnarok.monster_total_hp[arg_4_0.pos]
	local var_4_8 = var_4_6[arg_4_0.pos].damage

	arg_4_0:nodeByName("bar_hp"):setPercent(100 * ((var_4_7 - var_4_8) / var_4_7))

	local var_4_9 = 0
	local var_4_10 = var_0_3:getSkill(var_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_10) do
		if iter_4_1 ~= 0 then
			local var_4_11 = display.newNode()

			var_4_11:setContentSize(70, 70)
			xyd.setSkillBorder(var_4_11, iter_4_1, 1, true)
			var_4_11:addTo(arg_4_0:nodeByName("skill_container"))
			var_4_11:pos(var_4_9, 0)

			var_4_9 = var_4_9 + 86

			local var_4_12 = {
				has_jiantou = false,
				id = iter_4_1
			}

			var_4_11:setTouchEnabled(true)
			var_4_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
				if arg_5_0.name == "began" then
					if not xyd.WindowManager.get():getWindow("skill_tips") then
						local var_5_0 = xyd.WindowManager.get():openWindow("skill_tips", var_4_12)
						local var_5_1 = var_5_0:getTipHeight()
						local var_5_2, var_5_3 = var_4_11:getPosition()
						local var_5_4 = arg_4_0:nodeByName("skill_container"):convertToWorldSpace(cc.p(var_5_2, var_5_3))

						var_5_0:setPosition(var_5_4.x - 80, var_5_4.y + var_5_1 - 90)
					end

					return true
				elseif arg_5_0.name == "ended" then
					xyd.WindowManager.get():closeWindow("skill_tips")
				end
			end)
		end
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("btn_fight"), nil, function()
		local var_6_0 = {
			type = xyd.SelectTeamType.RAGNAROK,
			campaignType = xyd.CampaignType.RAGNAROK,
			battleID = var_0_2:battleId(arg_4_0.ragnarok:getType(), arg_4_0.pos)
		}

		xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_0)
		arg_4_0:close()
	end)
end

return var_0_0
