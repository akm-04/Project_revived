local var_0_0 = class("SingleDayBattlePreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activitySingleMission
local var_0_4 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battleInfo = arg_1_2
	arg_1_0.missionID = arg_1_2.missionID
	arg_1_0.battleID = arg_1_2.battleID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_boss_name"):setString(var_0_3:bossName(arg_4_0.missionID))
	arg_4_0:nodeByName("text_boss_name"):enableOutline(cc.c4b(30, 77, 148, 255), 1)
	arg_4_0:nodeByName("text_skill_1"):setString(var_0_3:skillTitle1(arg_4_0.missionID))
	arg_4_0:nodeByName("text_skill_desc_1"):setString(var_0_3:skillTranslation1(arg_4_0.missionID))
	arg_4_0:nodeByName("text_skill_2"):setString(var_0_3:skillTitle2(arg_4_0.missionID))
	arg_4_0:nodeByName("text_skill_desc_2"):setString(var_0_3:skillTranslation2(arg_4_0.missionID))
	arg_4_0:nodeByName("btn_go"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:startBattle()
		end
	end)
	arg_4_0:initBoss()
	arg_4_0:initRecommendHero()
end

function var_0_0.initBoss(arg_6_0)
	local var_6_0 = var_0_2.new()
	local var_6_1 = xyd.tables.battle:fight1(arg_6_0.battleID)[1]

	var_6_0:populateWithTableID(var_6_1)

	local var_6_2 = var_6_0:getHeroModel()

	arg_6_0:nodeByName("container"):addChild(var_6_2)
	var_6_2:setScale(0.75)

	local var_6_3 = cc.p(arg_6_0:nodeByName("container"):getChildByName("boss_node"):getPosition())

	var_6_2:setAnchorPoint(cc.p(0, 0.5))
	var_6_2:setPosition(cc.p(var_6_3))
end

function var_0_0.initRecommendHero(arg_7_0)
	local var_7_0 = var_0_3:heroRecommend(arg_7_0.missionID)
	local var_7_1 = arg_7_0:nodeByName("hero_container")
	local var_7_2 = 50

	for iter_7_0, iter_7_1 in pairs(var_7_0) do
		local var_7_3 = display.newNode()

		var_7_3:setContentSize(var_0_4, var_0_4)
		var_7_3:setAnchorPoint(cc.p(0.5, 0.5))

		local var_7_4 = var_0_2.new()

		var_7_4:initUnCollected(iter_7_1)
		xyd.setAvatarBorder(var_7_4, var_7_3)
		var_7_3:addTo(var_7_1)
		var_7_3:setPosition(cc.p(var_7_2, var_0_4 / 2 + 10))

		var_7_2 = var_7_2 + var_0_4 + 10

		local var_7_5 = "new_item_tips"
		local var_7_6
		local var_7_7 = {
			name = xyd.tables.hero:name(iter_7_1),
			desc = xyd.tables.hero:getDes(iter_7_1),
			id = iter_7_1
		}

		var_7_7.isHero = true

		var_7_3:setTouchEnabled(true)
		var_7_3:setTouchSwallowEnabled(false)
		var_7_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				var_7_6 = arg_8_0.y

				if not xyd.WindowManager.get():getWindow(var_7_5) then
					local var_8_0 = xyd.WindowManager.get():openWindow(var_7_5, var_7_7)
					local var_8_1, var_8_2 = var_7_3:getPosition()
					local var_8_3 = var_7_3:getHeight()
					local var_8_4 = var_8_0:getTipHeight()
					local var_8_5 = var_7_3:getParent():convertToWorldSpace(cc.p(var_8_1 - 20, var_8_2 + var_8_4 / 2 - 30))

					var_8_0:setPosition(var_8_5.x, var_8_5.y)
				end

				return true
			elseif arg_8_0.name == "moved" then
				local var_8_6 = arg_8_0.y

				if math.abs(var_8_6 - var_7_6) > 30 then
					xyd.WindowManager.get():closeWindow(var_7_5)
				end
			elseif arg_8_0.name == "ended" and xyd.WindowManager.get():getWindow(var_7_5) then
				xyd.WindowManager.get():closeWindow(var_7_5)
			end
		end)
	end
end

function var_0_0.startBattle(arg_9_0)
	local var_9_0 = arg_9_0.missionID
	local var_9_1 = arg_9_0.battleID
	local var_9_2 = xyd.tables.battle:campaignType(var_9_1)
	local var_9_3 = {
		type = xyd.SelectTeamType.SINGLE_DAY,
		battleID = var_9_1,
		campaignType = xyd.CampaignType.SINGLE_DAY,
		missionID = var_9_0
	}

	xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_9_3)
end

return var_0_0
