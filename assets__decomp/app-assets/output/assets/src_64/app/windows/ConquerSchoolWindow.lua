local var_0_0 = class("ConquerSchoolWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.conquerSchoolCampaign
local var_0_4 = import("app.model.Hero")
local var_0_5 = {
	88241005,
	88242005,
	88243005
}
local var_0_6 = {
	10001033,
	10001017,
	10001058
}
local var_0_7 = {
	LEFT = 1,
	RIGHT = -1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.conquerSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teamID = 1
	arg_1_0.maxTeamNum = arg_1_0.conquerSchool:getMaxTeamNum()
	arg_1_0.teamItems = {}
	arg_1_0.pointItems = {}
	arg_1_0.isShowAwards = false
	arg_1_0.startScrollNodeID = 1
	arg_1_0.buyConquerTimes = arg_1_0.conquerSchool:getBuyConquerTimes()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = {
		show_rule = true
	}

	arg_2_0:addTopSidebar(var_2_0)

	local var_2_1 = arg_2_0:nodeByName("hero_list"):getContentSize()

	arg_2_0.teamWidth = var_2_1.width

	local var_2_2 = display.newClippingRegionNode()

	var_2_2:setClippingRegion(cc.rect(0, 0, var_2_1.width, var_2_1.height))
	arg_2_0:nodeByName("hero_list"):addChild(var_2_2)

	arg_2_0.teamList_ = display.newNode()

	arg_2_0.teamList_:setContentSize(var_2_1)
	arg_2_0.teamList_:addTo(var_2_2)
	arg_2_0:initTeamID()
	arg_2_0:layout()
	arg_2_0:checkCanGetAwards()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:playStory()
end

function var_0_0.initTeamID(arg_4_0)
	arg_4_0.teamID = arg_4_0.conquerSchool:getLastTeamID()

	if arg_4_0.teamID > 0 then
		arg_4_0.startScrollNodeID = arg_4_0.teamID

		return
	end

	local var_4_0 = arg_4_0.conquerSchool:getTeamStatus()

	for iter_4_0 = 1, arg_4_0.maxTeamNum do
		if var_4_0[iter_4_0] and var_4_0[iter_4_0] == 0 then
			arg_4_0.teamID = iter_4_0
			arg_4_0.startScrollNodeID = arg_4_0.teamID

			return
		end
	end
end

function var_0_0.checkCanGetAwards(arg_5_0)
	local var_5_0 = arg_5_0.conquerSchool:getPromote()
	local var_5_1 = arg_5_0.conquerSchool:getAwards()

	if var_5_0 and var_5_1 and next(var_5_1) then
		if not arg_5_0.conquerSchool:checkEnd() then
			arg_5_0.isShowAwards = true
		end

		arg_5_0:nodeByName("btn_foot"):setVisible(false)
		arg_5_0:nodeByName("awards_bg"):setVisible(false)
		arg_5_0:nodeByName("special_buff"):setVisible(false)
		arg_5_0:nodeByName("left"):setVisible(false)
		arg_5_0:nodeByName("right"):setVisible(false)
		arg_5_0:nodeByName("point_bg"):setVisible(false)
		arg_5_0.selfPlayer:handleRewards(var_5_1, function()
			arg_5_0.conquerSchool:clear()
			arg_5_0:showAnimationToNext()
		end)
	elseif arg_5_0.conquerSchool:checkEnd() then
		arg_5_0:nodeByName("btn_foot"):setVisible(true)
		arg_5_0:nodeByName("awards_bg"):setVisible(false)
		arg_5_0:nodeByName("special_buff"):setVisible(false)
		arg_5_0:nodeByName("left"):setVisible(false)
		arg_5_0:nodeByName("right"):setVisible(false)
		arg_5_0:nodeByName("point_bg"):setVisible(false)
		arg_5_0:nodeByName("hero_list"):setVisible(false)
	else
		arg_5_0.isShowAwards = false

		arg_5_0:nodeByName("btn_foot"):setVisible(false)
	end
end

function var_0_0.widgetSet(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in ipairs(arg_7_1:getChildren()) do
		if iter_7_1 ~= nil then
			iter_7_1:setCascadeOpacityEnabled(true)
			arg_7_0:widgetSet(iter_7_1)
		end
	end
end

function var_0_0.showAnimationToNext(arg_8_0)
	arg_8_0:widgetSet(arg_8_0.teamItems[arg_8_0.teamID])
	arg_8_0.teamItems[arg_8_0.teamID]:setCascadeOpacityEnabled(true)
	arg_8_0.teamItems[arg_8_0.teamID]:runActionOnce(cc.FadeOut:create(1), false, function()
		arg_8_0.teamList_:setVisible(false)
		arg_8_0:nodeByName("btn_foot"):setVisible(true)
		arg_8_0:nodeByName("btn_foot"):setCascadeOpacityEnabled(true)
		arg_8_0:nodeByName("btn_foot"):setOpacity(0)
		arg_8_0:nodeByName("btn_foot"):runActionOnce(cc.FadeIn:create(1), false)
	end)
end

function var_0_0.layout(arg_10_0)
	arg_10_0:initButtonEvent()
	arg_10_0:updateLeftRightBtn()
	arg_10_0:initReward()
	arg_10_0:updateShowInfo()
	arg_10_0:initLeftTimes()
	arg_10_0:initSpecialBuff()
	arg_10_0:initMap()
end

function var_0_0.updateNextCampaign(arg_11_0)
	arg_11_0.teamItems = {}
	arg_11_0.isShowAwards = false

	arg_11_0:nodeByName("btn_foot"):setVisible(false)

	local var_11_0 = {}
	local var_11_1 = 0

	arg_11_0:showCloudAnimation(function(arg_12_0, arg_12_1)
		if arg_12_1 then
			var_11_1 = var_11_1 + 1
			arg_11_0.isCreateTeam = true

			arg_11_0.teamList_:setVisible(true)
			arg_11_0:nodeByName("point_bg"):setVisible(true)
			arg_11_0:nodeByName("awards_bg"):setVisible(true)
			arg_11_0:nodeByName("special_buff"):setVisible(true)
			arg_11_0:initTeamID()
			arg_11_0:updateLeftRightBtn()
			arg_11_0:initReward()
			arg_11_0:updateShowInfo()
			arg_11_0:initLeftTimes()
			arg_11_0:initSpecialBuff()
			arg_11_0:initMap()
			arg_11_0:initTeam()
		end

		if arg_12_0 then
			arg_12_0()
		end
	end)
end

function var_0_0.showCloudAnimation(arg_13_0, arg_13_1)
	local var_13_0 = xyd.AssetLoader.get():loadSprite("windows/conquer_school/yun.png")
	local var_13_1 = xyd.AssetLoader.get():loadSprite("windows/conquer_school/yun.png")

	var_13_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_0:setPosition(cc.p(560, -420))
	var_13_0:addTo(arg_13_0:background())
	var_13_0:setOpacity(0)
	var_13_0:setScale(8)
	var_13_0:setRotation(168)
	var_13_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_1:setPosition(cc.p(820, 1240))
	var_13_1:addTo(arg_13_0:background())
	var_13_1:setOpacity(0)
	var_13_1:setScale(8)
	var_13_1:setRotation(-8)

	local var_13_2 = 1
	local var_13_3 = cc.Spawn:create({
		cc.MoveTo:create(var_13_2, cc.p(900, 30)),
		cc.FadeIn:create(var_13_2)
	})
	local var_13_4 = cc.Spawn:create({
		cc.MoveTo:create(var_13_2, cc.p(400, 600)),
		cc.FadeIn:create(var_13_2)
	})
	local var_13_5 = cc.DelayTime:create(0.3)

	var_13_0:runActionOnce(var_13_3, false, function()
		if arg_13_1 then
			arg_13_1(function()
				local var_15_0 = cc.Spawn:create({
					cc.MoveTo:create(var_13_2, cc.p(560, -420)),
					cc.FadeOut:create(var_13_2)
				})

				var_13_0:runActionOnce(var_15_0, true)

				arg_13_0.isCreateTeam = false
				arg_13_0.isAnimation = false
			end, true)
		end
	end)
	var_13_1:runActionOnce(var_13_4, false, function()
		if arg_13_1 then
			arg_13_1(function()
				local var_17_0 = cc.Spawn:create({
					cc.MoveTo:create(var_13_2, cc.p(820, 1240)),
					cc.FadeOut:create(var_13_2)
				})

				var_13_1:runActionOnce(var_17_0, true)

				arg_13_0.isCreateTeam = false
				arg_13_0.isAnimation = false
			end)
		end
	end)
end

function var_0_0.initTeam(arg_18_0, arg_18_1)
	if arg_18_0.teamItems[arg_18_0.teamID] then
		return
	end

	local var_18_0 = arg_18_0.conquerSchool:getCurrentID()
	local var_18_1 = display.newNode()

	arg_18_0:initTeamCell(var_18_1, arg_18_0.teamID)
	var_18_1:addTo(arg_18_0.teamList_)

	if not arg_18_1 then
		var_18_1:setPosition(cc.p(0, 0))
		arg_18_0.teamList_:setPosition(cc.p(0, 0))
	elseif arg_18_1 == var_0_7.LEFT then
		local var_18_2 = cc.p(arg_18_0.teamItems[arg_18_0.teamID + 1]:getPosition())

		var_18_1:setPosition(cc.p(var_18_2.x - arg_18_0.teamWidth, var_18_2.y))
	elseif arg_18_1 == var_0_7.RIGHT then
		local var_18_3 = cc.p(arg_18_0.teamItems[arg_18_0.teamID - 1]:getPosition())

		var_18_1:setPosition(cc.p(var_18_3.x + arg_18_0.teamWidth, var_18_3.y))
	end
end

function var_0_0.initTeamCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0:nodeByName("hero_list"):getContentSize()
	local var_19_1 = arg_19_0.conquerSchool:getCurrentID()
	local var_19_2 = var_0_3:teams(var_19_1)[arg_19_2]

	arg_19_1:setContentSize(var_19_0)

	local var_19_3 = var_19_0.width / (#var_19_2 + 1)
	local var_19_4 = 40

	for iter_19_0 = 1, #var_19_2 do
		local var_19_5 = var_19_2[iter_19_0]
		local var_19_6 = var_0_4.new()

		var_19_6:populateWithTableID(var_19_5)

		local var_19_7 = var_19_6:getHeroModel()

		var_19_7:setScale(0.75)

		local var_19_8 = display.newNode()

		var_19_8:setAnchorPoint(0, 0)
		var_19_8:addChild(var_19_7)
		arg_19_1:addChild(var_19_8)
		var_19_8:setPosition(var_19_3, var_19_4)

		var_19_3 = var_19_3 + 180
	end

	arg_19_0.teamItems[arg_19_2] = arg_19_1
end

function var_0_0.moveToNextTeam(arg_20_0, arg_20_1)
	if arg_20_0.isAnimation then
		return
	end

	arg_20_0.isAnimation = true

	if not arg_20_0.teamItems[arg_20_0.teamID] then
		arg_20_0:initTeam(arg_20_1)
	end

	local var_20_0 = cc.p((arg_20_0.startScrollNodeID - arg_20_0.teamID) * arg_20_0.teamWidth, 0)

	arg_20_0.teamList_:runActionOnce(cc.MoveTo:create(1.5, var_20_0), false, function()
		arg_20_0.isAnimation = false
	end)
	arg_20_0:updatePointStyle()
end

function var_0_0.initButtonEvent(arg_22_0)
	arg_22_0:nodeByName("top_sidebar")
	arg_22_0:nodeByName("top_sidebar"):nodeByName("rule")
	xyd.nodeEventSample(arg_22_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_23_0)
		local var_23_0 = {}

		var_23_0.title_name = "CONQUER_SCHOOL_RULE_TITLE"
		var_23_0.rule = "CONQUER_SCHOOL_RULE_TEXT"
		var_23_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_23_0)
	end)
	arg_22_0:nodeByName("text_reset"):setString(var_0_2:translation("CONQUER_SCHOOL_TEXT_2"))
	arg_22_0:nodeByName("btn_reset"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_24_0, arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended and arg_22_0:checkCanTouch() and not arg_22_0.conquerSchool:checkEnd() then
			local var_24_0 = var_0_2:translation("MAKE_SUER_RESET_LEV")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_24_0, function()
				arg_22_0.conquerSchool:reset({}, function(arg_26_0, arg_26_1)
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("CONQUER_SCHOOL_RESET_LEV")
					})

					arg_22_0.isAnimation = true

					arg_22_0.teamList_:removeAllChildren()
					arg_22_0:updateNextCampaign()
				end)
			end, nil, nil, arg_22_0.colorMode)
		end
	end)
	arg_22_0:nodeByName("text_field"):setString(var_0_2:translation("CONQUER_SCHOOL_TEXT_3"))
	arg_22_0:nodeByName("btn_field"):addTouchEventListener(function(arg_27_0, arg_27_1)
		xyd.buttonScaleAnim(arg_27_0, arg_27_1)

		if arg_27_1 == ccui.TouchEventType.ended and arg_22_0:checkCanTouch() then
			xyd.WindowManager.get():openWindow("conquer_school_field")
		end
	end)
	arg_22_0:nodeByName("btn_fight"):addTouchEventListener(function(arg_28_0, arg_28_1)
		xyd.buttonScaleAnim(arg_28_0, arg_28_1)

		if arg_28_1 == ccui.TouchEventType.ended and arg_22_0:checkCanTouch() then
			if not arg_22_0.conquerSchool:checkTeamCanFight(arg_22_0.teamID) or arg_22_0.conquerSchool:checkEnd() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("CONQUER_FIGHT_TIPS_1")
				})

				return
			elseif arg_22_0.conquerSchool:getLeftTimes() <= 0 then
				if arg_22_0.selfPlayer.privilegeLeftCardDay <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("CONQUER_CANNOT_BUY_TIMES")
					})

					return
				end

				if arg_22_0.conquerSchool:getBuyConquerTimes() < 10 then
					local var_28_0 = {}
					local var_28_1 = xyd.tables.refreshCost:buyConquerCost(arg_22_0.conquerSchool:getBuyConquerTimes() + 1)
					local var_28_2 = string.format(var_0_2:translation("CONQUER_SCHOOL_BUY"), var_28_1)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_28_2, function()
						arg_22_0.conquerSchool:buyConquer(var_28_0, function(arg_30_0, arg_30_1)
							if arg_30_0 == xyd.error.OK then
								arg_22_0.buyConquerTimes = arg_22_0.conquerSchool:getBuyConquerTimes()

								arg_22_0:initLeftTimes()

								local var_30_0 = 10 - arg_22_0.buyConquerTimes
								local var_30_1 = string.format(var_0_2:translation("CONQUER_BUY_TIMES"), var_30_0)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_30_1
								})
							end
						end)
					end, nil, nil, arg_22_0.colorMode)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("CONQUER_BUY_TIMES_ALL")
					})
				end

				return
			end

			local var_28_3 = xyd.SelectTeamType.CONQUER_SCHOOL
			local var_28_4 = arg_22_0.conquerSchool:getCurrentID()
			local var_28_5 = var_0_3:fightIDs(var_28_4)[arg_22_0.teamID]
			local var_28_6 = {
				heroIDs = arg_22_0.conquerSchool:getUsedHeros(),
				petIDs = arg_22_0.conquerSchool:getUsedPets()
			}

			arg_22_0.conquerSchool:setLastTeamID(arg_22_0.teamID)

			local var_28_7 = {
				type = var_28_3,
				battleID = var_28_5,
				campaignID = var_28_4,
				conquerSchoolTeamID = arg_22_0.teamID,
				conquerUsedTeam = var_28_6,
				campaignType = xyd.CampaignType.CONQUER_SCHOOL
			}
			local var_28_8 = var_0_3:buffID(var_28_4)

			if var_28_8 == xyd.ConquerSchoolBuff.ASSIST then
				var_28_7.selectSpType = xyd.SelectSpType.ASSIST
				var_28_7.assistID = var_0_5[arg_22_0.teamID]
				var_28_7.assistHeroID = var_0_6[arg_22_0.teamID]
				var_28_7.noPreset = true
			elseif var_28_8 == xyd.ConquerSchoolBuff.WEI then
				var_28_7.selectSpType = xyd.SelectSpType.WEI
				var_28_7.banPet = true
			elseif var_28_8 == xyd.ConquerSchoolBuff.SHU then
				var_28_7.selectSpType = xyd.SelectSpType.SHU
				var_28_7.banPet = true
			elseif var_28_8 == xyd.ConquerSchoolBuff.WU then
				var_28_7.selectSpType = xyd.SelectSpType.WU
				var_28_7.banPet = true
			elseif var_28_8 == xyd.ConquerSchoolBuff.QUN then
				var_28_7.selectSpType = xyd.SelectSpType.QUN
				var_28_7.banPet = true
			elseif var_28_8 == xyd.ConquerSchoolBuff.KOF then
				var_28_7.banPet = true
			end

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_28_7)
		end
	end)
	arg_22_0:nodeByName("text_report"):setString(var_0_2:translation("CONQUER_SCHOOL_TEXT_1"))
	arg_22_0:nodeByName("btn_report"):addTouchEventListener(function(arg_31_0, arg_31_1)
		xyd.buttonScaleAnim(arg_31_0, arg_31_1)

		if arg_31_1 == ccui.TouchEventType.ended and arg_22_0:checkCanTouch() then
			local var_31_0 = {
				conquer_loop_id = arg_22_0.conquerSchool:getLoopID(),
				campaign_id = arg_22_0.conquerSchool:getCurrentID(),
				team_id = arg_22_0.teamID
			}

			arg_22_0.conquerSchool:getReportList(var_31_0, function(arg_32_0, arg_32_1)
				if arg_32_0 == xyd.error.OK then
					var_31_0.reports = arg_32_1.reports

					xyd.WindowManager.get():openWindow("conquer_school_report", var_31_0)
				end
			end)
		end
	end)
	arg_22_0:nodeByName("btn_foot"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended then
			if arg_22_0.conquerSchool:checkEnd() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("CONQUER_END")
				})
			else
				arg_22_0:updateNextCampaign()
			end
		end
	end)
	arg_22_0:nodeByName("left"):setTouchEnabled(true)
	arg_22_0:nodeByName("left"):setTouchSwallowEnabled(false)
	arg_22_0:nodeByName("left"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			arg_22_0:nodeByName("left"):setScale(0.9)

			return true
		elseif arg_34_0.name == "ended" and not arg_22_0.isAnimation then
			arg_22_0:nodeByName("left"):setScale(1)

			if arg_22_0.teamID == xyd.ConquerSchoolBattle.FIRST_TEAM then
				return false
			else
				arg_22_0.teamID = arg_22_0.teamID - 1

				arg_22_0:moveToNextTeam(var_0_7.LEFT)
				arg_22_0:updateLeftRightBtn()
			end
		end
	end)
	arg_22_0:nodeByName("right"):setTouchEnabled(true)
	arg_22_0:nodeByName("right"):setTouchSwallowEnabled(false)
	arg_22_0:nodeByName("right"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
		if arg_35_0.name == "began" then
			arg_22_0:nodeByName("right"):setScale(0.9)

			return true
		elseif arg_35_0.name == "ended" and not arg_22_0.isAnimation then
			arg_22_0:nodeByName("right"):setScale(0.9)

			if arg_22_0.teamID == arg_22_0.maxTeamNum then
				return false
			else
				arg_22_0.teamID = arg_22_0.teamID + 1

				arg_22_0:moveToNextTeam(var_0_7.RIGHT)
				arg_22_0:updateLeftRightBtn()
			end
		end
	end)
end

function var_0_0.checkCanTouch(arg_36_0)
	if arg_36_0.isShowAwards then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("CONQUER_SCHOOL_TIPS_2")
		})

		return false
	end

	return true
end

function var_0_0.updateLeftRightBtn(arg_37_0)
	arg_37_0.maxTeamNum = arg_37_0.conquerSchool:getMaxTeamNum()

	if arg_37_0.teamID == 1 then
		arg_37_0:nodeByName("left"):setVisible(false)
	else
		arg_37_0:nodeByName("left"):setVisible(true)
	end

	if arg_37_0.teamID == arg_37_0.maxTeamNum then
		arg_37_0:nodeByName("right"):setVisible(false)
	else
		arg_37_0:nodeByName("right"):setVisible(true)
	end
end

function var_0_0.updateShowInfo(arg_38_0)
	local var_38_0 = var_0_3:lev(arg_38_0.conquerSchool:getCurrentID())
	local var_38_1 = string.format(var_0_2:translation("CONQUER_SCHOOL_BATTLE_LEV"), var_38_0, var_0_3:maxLev())

	arg_38_0:nodeByName("current_lev"):setString(var_38_1)

	local var_38_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_38_3 = math.min(xyd.tables.misc.conquerSchoolMaxLoop, var_38_2.conquerLoopID)
	local var_38_4 = arg_38_0:nodeByName("loop_container")

	for iter_38_0, iter_38_1 in ipairs(var_38_4:getChildren()) do
		iter_38_1:setVisible(false)
	end

	if var_38_3 > 0 then
		var_38_4:getChildByName("loop" .. var_38_3):setVisible(true)
	end

	local var_38_5 = var_0_3:region(arg_38_0.conquerSchool:getCurrentID())
	local var_38_6 = cc.p(arg_38_0:nodeByName("title_pos"):getPosition())

	if arg_38_0.titleSprite then
		arg_38_0.titleSprite:removeSelf()
	end

	arg_38_0.titleSprite = xyd.AssetLoader.get():loadSprite("windows/conquer_school/conquer_main/region_title_" .. var_38_5 .. ".png")

	arg_38_0.titleSprite:addTo(arg_38_0:nodeByName("title_bg"))
	arg_38_0.titleSprite:setAnchorPoint(cc.p(0.5, 0.5))
	arg_38_0.titleSprite:setPosition(var_38_6)

	local var_38_7 = arg_38_0:nodeByName("point_container")

	if arg_38_0.maxTeamNum == 1 then
		arg_38_0:nodeByName("point_bg"):setVisible(false)
	else
		var_38_7:removeAllChildren()

		arg_38_0.pointItems = {}

		local var_38_8 = var_38_7:getContentSize()
		local var_38_9 = var_38_8.width / (arg_38_0.maxTeamNum + 1)
		local var_38_10 = var_38_9

		for iter_38_2 = 1, arg_38_0.maxTeamNum do
			local var_38_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/conquer_school/point.csb")
			local var_38_12 = var_38_11:getChildByName("container")

			table.insert(arg_38_0.pointItems, var_38_12)

			if arg_38_0.conquerSchool:checkTeamCanFight(iter_38_2) then
				var_38_12:getChildByName("green_point"):setVisible(false)
				var_38_12:getChildByName("gray_point"):setVisible(true)
			else
				var_38_12:getChildByName("green_point"):setVisible(true)
				var_38_12:getChildByName("gray_point"):setVisible(false)
			end

			var_38_7:addChild(var_38_11)
			var_38_11:setPosition(var_38_10, var_38_8.height / 2)

			var_38_10 = var_38_10 + var_38_9
		end
	end

	arg_38_0:updatePointStyle()
end

function var_0_0.updatePointStyle(arg_39_0)
	for iter_39_0 = 1, #arg_39_0.pointItems do
		local var_39_0 = arg_39_0.pointItems[iter_39_0]

		if iter_39_0 == arg_39_0.teamID then
			if arg_39_0.conquerSchool:checkTeamCanFight(iter_39_0) then
				var_39_0:getChildByName("green_point_2"):setVisible(false)
				var_39_0:getChildByName("gray_point_2"):setVisible(true)
			else
				var_39_0:getChildByName("green_point_2"):setVisible(true)
				var_39_0:getChildByName("gray_point_2"):setVisible(false)
			end
		else
			var_39_0:getChildByName("green_point_2"):setVisible(false)
			var_39_0:getChildByName("gray_point_2"):setVisible(false)
		end
	end
end

function var_0_0.initLeftTimes(arg_40_0)
	local var_40_0

	if arg_40_0.isShowAwards then
		var_40_0 = arg_40_0.conquerSchool:getLastLeftTimes()
	else
		var_40_0 = arg_40_0.conquerSchool:getLeftTimes()
	end

	local var_40_1 = xyd.tables.misc.conquerSchoolChallengeNum

	if var_40_0 == 0 then
		arg_40_0:nodeByName("text_fight"):setString(var_0_2:translation("ARENA_BUY_TIME"))
	else
		arg_40_0:nodeByName("text_fight"):setString(string.format(var_0_2:translation("CONQUER_SCHOOL_TEXT_4"), var_40_0, var_40_1))
	end
end

function var_0_0.initReward(arg_41_0)
	local var_41_0 = arg_41_0.conquerSchool:getCurrentID()
	local var_41_1 = var_0_3:rewardItem(var_41_0)
	local var_41_2 = var_0_3:rewardItemNum(var_41_0)
	local var_41_3 = display.newNode()
	local var_41_4 = arg_41_0:nodeByName("reward"):getContentSize()

	var_41_3:setContentSize(var_41_4)
	arg_41_0:nodeByName("reward"):removeAllChildren()
	var_41_3:addTo(arg_41_0:nodeByName("reward"))
	xyd.setItemBorder(var_41_3, var_41_1, false, false, var_41_2)

	local var_41_5 = {
		id = var_41_1,
		hasNum = arg_41_0.selfPlayer:getBackpack():getItemNumByID(var_41_1)
	}
	local var_41_6 = var_41_3

	xyd.addTips(var_41_6, var_41_5)
end

function var_0_0.initSpecialBuff(arg_42_0)
	local var_42_0 = arg_42_0:nodeByName("special_buff")

	var_42_0:removeAllChildren()

	local var_42_1 = var_42_0:getContentSize()
	local var_42_2 = var_42_1.width / 2

	local function var_42_3(arg_43_0, arg_43_1)
		local var_43_0 = xyd.tables.conquerSchoolBuff:buffIcon(arg_43_0)

		if var_43_0 == "" then
			return
		end

		local var_43_1 = xyd.SpriteLoader.new(var_43_0, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_42_0)

		if var_43_1 then
			local var_43_2 = var_43_1:getContentSize()

			var_43_1:setScale(var_42_1.width / var_43_2.width)
			var_43_1:setAnchorPoint(cc.p(0.5, 0.5))
			var_43_1:addTo(var_42_0)
			var_43_1:setPosition(cc.p(var_42_2, var_42_1.height / 2))
			var_43_1:setTouchEnabled(true)
			var_43_1:setTouchSwallowEnabled(false)
			var_43_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
				if arg_44_0.name == "began" then
					local var_44_0 = xyd.tables.conquerSchoolBuff:buffDesc(arg_43_0)

					if arg_43_0 == 1 then
						local var_44_1 = xyd.tables.misc.conquerSchoolHurtParam * arg_42_0.conquerSchool:getIsBuffOn() * 100

						var_44_0 = string.format(var_44_0, var_44_1, var_44_1)
					end

					local var_44_2 = {
						txtSize = 24,
						isAutoClose = 0,
						message = var_44_0,
						pos = cc.p(800, 575)
					}

					xyd.WindowManager.get():openWindow("toast", var_44_2)

					return true
				elseif arg_44_0.name == "ended" and xyd.WindowManager.get():isWindowOpen("toast") then
					xyd.WindowManager.get():closeWindow("toast")
				end
			end)

			if arg_43_1 and arg_43_1 > 1 then
				local var_43_3 = xyd.AssetLoader:get():loadSprite("images/digit_bg.png")

				var_42_0:addChild(var_43_3)
				var_43_3:setAnchorPoint(cc.p(0.5, 0))
				var_43_3:setPosition(var_42_2 + 1, 4)

				local var_43_4 = {
					size = 20,
					y = 1,
					text = arg_43_1,
					color = cc.c3b(255, 255, 255),
					align = cc.ui.TEXT_ALIGN_CENTER,
					valign = cc.ui.TEXT_VALIGN_TOP,
					x = var_42_2 + var_42_1.width / 4
				}
				local var_43_5 = xyd.AssetLoader.get():loadLabel(var_43_4)

				var_43_5:addTo(var_42_0)
				var_43_5:setAnchorPoint(0.5, 0)
			end

			var_42_2 = var_42_2 + var_42_1.width + 5
		end
	end

	local var_42_4 = var_0_3:buffID(arg_42_0.conquerSchool:getCurrentID())

	if var_42_4 ~= 0 then
		var_42_3(var_42_4)
	end

	if arg_42_0.conquerSchool:getIsBuffOn() > 0 then
		var_42_3(1, arg_42_0.conquerSchool:getIsBuffOn())
	end
end

function var_0_0.initMap(arg_45_0)
	if arg_45_0.mapSprite then
		arg_45_0.mapSprite:removeSelf()
	end

	local var_45_0 = var_0_3:campaignMap(arg_45_0.conquerSchool:getCurrentID())

	if var_45_0 == "" then
		return
	end

	local var_45_1 = xyd.SpriteLoader.new(var_45_0, nil, nil, xyd.DefaultImageType.MAP)

	var_45_1:addTo(arg_45_0:background())
	var_45_1:setAnchorPoint(cc.p(0, 0))
	var_45_1:setPosition(cc.p(0, 0))

	local var_45_2 = var_45_1:getContentSize()
	local var_45_3 = arg_45_0:background():getContentSize()

	var_45_1:setScale(var_45_3.width / var_45_2.width, var_45_3.height / var_45_2.height)
	var_45_1:setLocalZOrder(-1)

	arg_45_0.mapSprite = var_45_1
end

function var_0_0.playStory(arg_46_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CONQUER_SCHOOL_START then
		arg_46_0:background():setVisible(false)

		local var_46_0 = xyd.WindowManager.get():openWindow("story", {
			story_id = 1001,
			story_state = 1,
			is_guide_story = true
		})

		cc.EventProxy.new(var_46_0, var_46_0):addEventListener(xyd.event.STORY_COMPLETE, function(arg_47_0)
			if arg_47_0.state == 1 then
				arg_46_0:background():setVisible(true)
				arg_46_0:initTeam()
			end
		end)
	else
		arg_46_0:initTeam()
	end
end

return var_0_0
