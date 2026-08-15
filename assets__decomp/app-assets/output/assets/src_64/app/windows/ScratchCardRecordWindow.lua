local var_0_0 = class("ScratchCardRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.randCardGroup = arg_1_2.rand_card_group
	arg_1_0.scratchStatus = arg_1_2.scratch_status
	arg_1_0.cardGroup = arg_1_2.card_group
	arg_1_0.isShareJoy = arg_1_2.isShareJoy
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.cardIDToOrgPosTable = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:creatCardIDToOrgPosTable()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0.randCardGroup
	local var_5_1 = arg_5_0.scratchStatus

	for iter_5_0 = 1, #var_5_0 do
		local var_5_2 = var_5_0[iter_5_0]
		local var_5_3 = arg_5_0:nodeByName("card_" .. iter_5_0)

		var_5_3:getChildByName("have_get_txt"):setVisible(false)
		var_5_3:getChildByName("step_txt"):setVisible(false)
		arg_5_0:setCardInObverseSideAndAddTips(var_5_3, var_5_2)

		local var_5_4 = arg_5_0.cardIDToOrgPosTable[var_5_2]

		if var_5_4 > var_0_2 then
			local var_5_5 = math.floor(var_5_4 / var_0_2)

			var_5_4 = arg_5_0.cardIDToOrgPosTable[var_5_2] - var_5_5 * var_0_2
			arg_5_0.cardIDToOrgPosTable[var_5_2] = var_5_5
		end

		if var_5_1[var_5_4] and var_5_1[var_5_4] ~= 0 then
			var_5_3:getChildByName("step_txt"):setString(string.format(var_0_1:translation("SCRATCH_NSETP"), var_5_1[var_5_4]))
			var_5_3:getChildByName("have_get_txt"):setVisible(true)
			var_5_3:getChildByName("step_txt"):setVisible(true)
			var_5_3:getChildByName("have_get_txt"):zorder(100)
			var_5_3:getChildByName("have_get_txt"):setPosition(cc.p(60, 20))
		end
	end

	arg_5_0:nodeByName("share_joy_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0.isShareJoy and arg_5_0.isShareJoy == true then
				arg_5_0:goToShareJoy()
			else
				arg_5_0:goToTakeChance()
			end
		end
	end)

	if arg_5_0.isShareJoy and arg_5_0.isShareJoy == true then
		arg_5_0:nodeByName("share_joy_txt"):setVisible(true)
		arg_5_0:nodeByName("take_chance_txt"):setVisible(false)
	else
		arg_5_0:nodeByName("share_joy_txt"):setVisible(false)
		arg_5_0:nodeByName("take_chance_txt"):setVisible(false)
		arg_5_0:nodeByName("share_joy_btn"):setTouchEnabled(false)
		arg_5_0:nodeByName("share_joy_btn"):setVisible(false)
	end
end

function var_0_0.goToShareJoy(arg_7_0)
	local var_7_0 = {
		player_id = arg_7_0.selfPlayer.playerID,
		player_name = arg_7_0.selfPlayer.playerName
	}

	var_7_0.share_gua = 1
	var_7_0.rand_card_group = arg_7_0.randCardGroup
	var_7_0.card_group = arg_7_0.cardGroup
	var_7_0.scratch_status = arg_7_0.scratchStatus

	local var_7_1 = json.encode(var_7_0)

	xyd.WindowManager.get():openWindow("record_share_menu", {
		type_ = 2,
		message = var_7_1
	})
end

function var_0_0.goToTakeChance(arg_8_0)
	if arg_8_0.activitiesModel:isScratchCardShow() then
		local var_8_0 = arg_8_0.activitiesModel:isScratchCardShow()

		if xyd.WindowManager.get():isWindowOpen("chat") then
			xyd.WindowManager.get():closeWindow("chat")
		end

		if xyd.WindowManager.get():isWindowOpen("activities") then
			xyd.WindowManager.get():closeWindow("activities")
		end

		xyd.WindowManager.get():openWindow("activities")

		local var_8_1 = xyd.WindowManager.get():getWindow("activities")

		if var_8_1 then
			for iter_8_0, iter_8_1 in pairs(var_8_1.openedActivities) do
				if iter_8_0 ~= xyd.Activities.ScratchCard and iter_8_1 then
					iter_8_1:release()
				end
			end

			if not var_8_1.lastClickActivity or var_8_1.lastClickActivity ~= var_8_0 then
				var_8_1:leftLayout(var_8_0)

				var_8_1.lastClickActivity = var_8_0
			end
		end

		xyd.WindowManager.get():closeWindow(arg_8_0)
	else
		local var_8_2 = var_0_1:translation("ACTIVITY_HAS_FAILED")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_8_2
		})
	end
end

function var_0_0.setCardInObverseSideAndAddTips(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = display.newNode()

	var_9_0:setContentSize(arg_9_1:getHeight(), arg_9_1:getHeight())

	local var_9_1 = xyd.tables.activityScratchCard:getGiftID(arg_9_2)

	if xyd.tables.activityScratchCard:isMultiplierCard(arg_9_2) then
		local var_9_2 = xyd.tables.activityScratchCard:getIcon(arg_9_2)

		xyd.setSpriteBorder(var_9_0, var_9_2, 1)

		local var_9_3 = {}

		var_9_3.id = -11
		var_9_3.tipsType = 1

		arg_9_0:addTips(var_9_0, var_9_3)
	elseif xyd.tables.gift:crystal(var_9_1) and xyd.tables.gift:crystal(var_9_1) > 0 then
		xyd.setItemBorder(var_9_0, -1, false, false, xyd.tables.gift:crystal(var_9_1))

		local var_9_4 = {}

		var_9_4.id = -1
		var_9_4.tipsType = 1

		arg_9_0:addTips(var_9_0, var_9_4)
	elseif xyd.tables.gift:mana(var_9_1) and xyd.tables.gift:mana(var_9_1) > 0 then
		xyd.setItemBorder(var_9_0, -2, false, false, xyd.tables.gift:mana(var_9_1))

		local var_9_5 = {}

		var_9_5.id = -2
		var_9_5.tipsType = 1

		arg_9_0:addTips(var_9_0, var_9_5)
	elseif xyd.tables.gift:luckyCoin(var_9_1) and xyd.tables.gift:luckyCoin(var_9_1) > 0 then
		xyd.setItemBorder(var_9_0, -5, false, false, xyd.tables.gift:luckyCoin(var_9_1))

		local var_9_6 = {}

		var_9_6.id = -10
		var_9_6.tipsType = 1

		arg_9_0:addTips(var_9_0, var_9_6)
	else
		local var_9_7 = xyd.tables.gift:items(var_9_1)[1]
		local var_9_8 = xyd.tables.gift:itemNum(var_9_1)[1]

		xyd.setItemBorder(var_9_0, var_9_7, false, false, var_9_8)

		local var_9_9 = {
			id = var_9_7,
			lev = xyd.tables.item:level(var_9_7)
		}

		if xyd.tables.item:type(var_9_7) == -1 then
			var_9_9.tipsType = 0
			var_9_9.desc1 = xyd.tables.hero:getDes(var_9_7)
		elseif specialItem then
			var_9_9.tipsType = 1
			var_9_9.id = -3
		else
			var_9_9.tipsType = 1
			var_9_9.desc1 = xyd.tables.item:desc1(var_9_7)
			var_9_9.desc2 = xyd.tables.item:desc2(var_9_7)
		end

		var_9_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_7)
		var_9_9.name = xyd.tables.item:name(var_9_7)

		arg_9_0:addTips(var_9_0, var_9_9)
	end

	var_9_0:addTo(arg_9_1)
	var_9_0:setPosition(0, 0)
	var_9_0:setAnchorPoint(cc.p(0, 0))
end

function var_0_0.creatCardIDToOrgPosTable(arg_10_0)
	arg_10_0.cardIDToCardPosTable = {}

	local var_10_0 = arg_10_0.cardGroup

	for iter_10_0 = 1, #var_10_0 do
		if not arg_10_0.cardIDToOrgPosTable[var_10_0[iter_10_0]] then
			arg_10_0.cardIDToOrgPosTable[var_10_0[iter_10_0]] = 0
		end

		arg_10_0.cardIDToOrgPosTable[var_10_0[iter_10_0]] = arg_10_0.cardIDToOrgPosTable[var_10_0[iter_10_0]] * var_0_2 + iter_10_0
	end
end

return var_0_0
