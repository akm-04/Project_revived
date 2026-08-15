local var_0_0 = class("BoardTaskBonusItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.award = arg_2_1
	arg_2_0.useCrystal = false
	arg_2_0.container = arg_2_0:contentView():nodeByName("container")

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:contentView():nodeByName("task_name"):setString(xyd.tables.eventCentreMissionTable:name(arg_3_0.award.mission_id))

	if arg_3_0.award.wish_crystal == 0 then
		-- block empty
	elseif arg_3_0.award.wish_crystal == 1 then
		local var_3_0 = {
			color = xyd.color.GREEN,
			text = var_0_1:translation("BOARD_DOUBLE_BONUS")
		}
		local var_3_1 = cc.Node:create()
		local var_3_2 = xyd.AssetLoader:get():loadLabel(var_3_0)

		var_3_1:addChild(var_3_2)
		var_3_2:setPosition(arg_3_0:contentView():nodeByName("task_name"):getContentSize().width + 5, 0)
		var_3_2:setAnchorPoint(cc.p(0, 0))
		var_3_2:enableOutline(cc.c4b(255, 255, 255, 255), 1)

		local var_3_3 = arg_3_0:contentView():nodeByName("task_name"):getContentSize().width - arg_3_0:contentView():nodeByName("task_name"):getContentSize().width - var_3_2:getContentSize().width - 5

		var_3_1:setPosition(0, 0)
		var_3_1:setAnchorPoint(cc.p(0, 0))
		arg_3_0:contentView():nodeByName("task_name"):addChild(var_3_1)

		local var_3_4, var_3_5 = arg_3_0:contentView():nodeByName("task_name"):getPosition()

		arg_3_0:contentView():nodeByName("task_name"):setPosition(var_3_4 - var_3_2:getContentSize().width / 2, var_3_5)

		arg_3_0.useCrystal = true
	end

	arg_3_0:registerTouchEvent()
	arg_3_0:setMissionAward()
end

function var_0_0.registerTouchEvent(arg_4_0)
	local var_4_0 = arg_4_0.container

	arg_4_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0.prevX_ = arg_5_0.x
			arg_4_0.prevY_ = arg_5_0.y
			arg_4_0.startClick_ = true
		elseif arg_5_0.name == "moved" then
			if math.abs(arg_5_0.y - arg_4_0.prevY_) > 10 or math.abs(arg_5_0.x - arg_4_0.prevX_) > 20 then
				arg_4_0.startClick_ = false
			end
		elseif arg_5_0.name == "ended" and arg_4_0.startClick_ then
			local var_5_0 = var_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))
		end

		return true
	end)
end

function var_0_0.contentView(arg_6_0)
	if arg_6_0.contentView_ == nil then
		arg_6_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_6_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/board/board/board_bonus_item.csb"))
		arg_6_0.contentView_:addTo(arg_6_0)
		arg_6_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_6_0.contentView_
end

function var_0_0.showAward(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0 = 0

	if arg_7_1 == "jinbi" then
		var_7_0 = xyd.tables.eventCentreMissionTable:deposit(arg_7_0.award.mission_id)
	end

	local var_7_1 = arg_7_0:contentView():nodeByName(arg_7_1)

	var_7_1:setVisible(true)

	if arg_7_5 ~= 0 then
		local var_7_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		xyd.setItemBorder(var_7_1, tonumber(arg_7_5))

		if not arg_7_0.useCrystal then
			var_7_2:getBackpack():addItemsByID(tonumber(arg_7_5), tonumber(arg_7_3))
		elseif arg_7_0.useCrystal then
			var_7_2:getBackpack():addItemsByID(tonumber(arg_7_5), tonumber(arg_7_3 * 2))
		end
	end

	local var_7_3 = arg_7_0:contentView():nodeByName(arg_7_2)

	var_7_3:setVisible(true)

	if arg_7_0.useCrystal then
		var_7_3:setString("x" .. arg_7_3 * 2 + var_7_0)
	else
		var_7_3:setString("x" .. arg_7_3 + var_7_0)
	end

	if arg_7_4 > 0 then
		local var_7_4, var_7_5 = var_7_1:getPosition()
		local var_7_6, var_7_7 = var_7_3:getPosition()

		var_7_1:setPosition(cc.p(var_7_4 + arg_7_4, var_7_5))
		var_7_3:setPosition(cc.p(var_7_6 + arg_7_4, var_7_7))
	end

	var_7_1:setScale(0.8)

	if arg_7_0.useCrystal then
		var_7_3:setTextColor(cc.c4b(252, 213, 0, 255))
	else
		var_7_3:setTextColor(cc.c4b(255, 255, 255, 255))
	end
end

function var_0_0.setMissionAward(arg_8_0)
	if arg_8_0.award.type == 1 then
		arg_8_0.missionAwardItem = xyd.tables.eventCentreMissionAwardTable:itemId(arg_8_0.award.award_id)
		arg_8_0.missionAwardItemNumber = xyd.tables.eventCentreMissionAwardTable:itemNumber(arg_8_0.award.award_id)
		arg_8_0.missionAwardRewardId = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardId(arg_8_0.award.award_id), "|")
		arg_8_0.missionAwardRewardResource = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardResource(arg_8_0.award.award_id), "|")

		local var_8_0 = 0

		if arg_8_0.missionAwardItem ~= "0" then
			arg_8_0:showAward("item", "item_num", arg_8_0.missionAwardItemNumber, var_8_0, arg_8_0.missionAwardItem)

			var_8_0 = var_8_0 + 140
		end

		for iter_8_0 = 1, #arg_8_0.missionAwardRewardId do
			if arg_8_0.missionAwardRewardId[iter_8_0] == "11" then
				arg_8_0:showAward("dust", "dust_num", arg_8_0.missionAwardRewardResource[iter_8_0], var_8_0, 0)
			elseif arg_8_0.missionAwardRewardId[iter_8_0] == "12" then
				arg_8_0:showAward("liquid", "liquid_num", arg_8_0.missionAwardRewardResource[iter_8_0], var_8_0, 0)
			elseif arg_8_0.missionAwardRewardId[iter_8_0] == "13" then
				arg_8_0:showAward("energy", "energy_num", arg_8_0.missionAwardRewardResource[iter_8_0], var_8_0, 0)
			elseif arg_8_0.missionAwardRewardId[iter_8_0] == "14" then
				arg_8_0:showAward("jinbi", "jinbi_num", arg_8_0.missionAwardRewardResource[iter_8_0], var_8_0, 0)
			end

			var_8_0 = var_8_0 + 170
		end
	elseif arg_8_0.award.type == 2 then
		local var_8_1 = xyd.tables.eventCentreMissionAwardTable:rewardGold(arg_8_0.award.award_id)

		arg_8_0:showAward("jinbi", "jinbi_num", var_8_1, 0, 0)
	end
end

return var_0_0
