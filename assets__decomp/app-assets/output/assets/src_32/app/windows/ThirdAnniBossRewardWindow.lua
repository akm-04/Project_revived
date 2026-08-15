local var_0_0 = class("ThirdAnniBossRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityAnniversaryBossDamage
local var_0_2 = xyd.tables.gift
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.bossInfo = arg_1_0.thirdAnniModel.bossInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")

	local var_2_0 = arg_2_0.scroll:getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.scroll)

	arg_2_0.scrollList:setBounceable(true)
	arg_2_0:updateRewards()
	arg_2_0:nodeByName("title_txt1"):setString(var_0_3:translation("THIRD_ANNI_WORD_REWARD10"))
	arg_2_0:nodeByName("get_award_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.thirdAnniModel:thirdAnniPersonAward({}, function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					arg_2_0.bossInfo.person_awarded = arg_4_1.person_awarded

					arg_2_0:updateBtnState()
				end
			end)
		end
	end)
	arg_2_0:updateBtnState()
end

function var_0_0.updateBtnState(arg_5_0, ...)
	local var_5_0, var_5_1 = arg_5_0:getAwardIndex()

	if var_5_0 > 0 then
		arg_5_0:scrollToIthItem(var_5_0)
	end

	if not var_5_1 then
		arg_5_0:nodeByName("get_award_btn"):setBright(false)
		arg_5_0:nodeByName("get_award_btn"):setTouchEnabled(false)
	end
end

function var_0_0.getAwardIndex(arg_6_0)
	local var_6_0 = -1
	local var_6_1 = false
	local var_6_2 = var_0_1:ids()

	for iter_6_0 = 1, #var_6_2 do
		local var_6_3 = var_6_2[iter_6_0]
		local var_6_4 = var_0_1:damage(var_6_3)

		if arg_6_0.bossInfo.person_awarded[var_6_3] == 0 and var_6_4 <= arg_6_0.bossInfo.person_damage then
			var_6_0 = var_6_3
			var_6_1 = true

			break
		elseif arg_6_0.bossInfo.person_awarded[var_6_3] == 0 then
			var_6_0 = var_6_3
			var_6_1 = false

			break
		end
	end

	return var_6_0, var_6_1
end

function var_0_0.scrollToIthItem(arg_7_0, arg_7_1)
	local var_7_0 = #var_0_1:ids()
	local var_7_1 = 4

	if arg_7_1 < 1 then
		arg_7_1 = 1
	elseif arg_7_1 >= var_7_0 - (var_7_1 - 1) then
		arg_7_1 = var_7_0 - (var_7_1 - 1)
	end

	arg_7_0.scrollList:scrollTo(0, arg_7_0.orgPosY + (arg_7_1 - 1) * 119)
end

function var_0_0.updateRewards(arg_8_0)
	local var_8_0 = var_0_1:ids()

	for iter_8_0 = 1, #var_8_0 do
		local var_8_1 = var_8_0[iter_8_0]
		local var_8_2 = var_0_1:item(var_8_1)
		local var_8_3 = var_0_1:num(var_8_1)
		local var_8_4 = var_0_1:damage(var_8_1)
		local var_8_5 = arg_8_0.scrollList:newItem()
		local var_8_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/third_anniversary_boss/award_item.csb")
		local var_8_7 = var_8_6:getChildByName("container")

		var_8_7:getChildByName("title_txt"):setString(string.format(var_0_3:translation("ACTIVITY_THIRD_BOSS_AWARD_TEXT1"), iter_8_0))
		var_8_7:getChildByName("desc_txt"):setString(string.format(var_0_3:translation("ACTIVITY_THIRD_BOSS_AWARD_TEXT2"), var_8_4))
		xyd.setItemAndAddTips(var_8_7:getChildByName("icon_container"), var_8_2, var_8_3)
		var_8_7:getChildByName("icon_available"):setVisible(false)
		var_8_7:getChildByName("icon_processing"):setVisible(false)
		var_8_7:getChildByName("icon_recieved"):setVisible(false)

		if arg_8_0.bossInfo.person_awarded[var_8_1] == 1 then
			var_8_7:getChildByName("icon_recieved"):setVisible(true)
		elseif var_8_4 <= arg_8_0.bossInfo.person_damage then
			var_8_7:getChildByName("icon_available"):setVisible(true)
		else
			var_8_7:getChildByName("icon_processing"):setVisible(true)
		end

		local var_8_8 = var_8_7:getContentSize()

		var_8_6:setAnchorPoint(cc.p(0, 0))
		var_8_6:setContentSize(var_8_8.width, var_8_8.height)
		var_8_5:setItemSize(var_8_8.width, var_8_8.height)
		var_8_5:addContent(var_8_6)
		arg_8_0.scrollList:addItem(var_8_5)
	end

	arg_8_0.scrollList:reload()

	arg_8_0.orgPosY = arg_8_0.scrollList.scrollNode:getPositionY()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

return var_0_0
