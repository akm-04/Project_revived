local var_0_0 = class("DragonBoatResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.matchPlayers = arg_1_2.match_players or {}
	arg_1_0.awards_ = arg_1_2.awards
	arg_1_0.costTime_ = arg_1_2.cost_time
	arg_1_0.rank_ = arg_1_2.rank
	arg_1_0.preCostTime_ = arg_1_2.pre_cost_time
	arg_1_0.lastRank_ = arg_1_2.last_rank
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:playEffect()
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0:addItemsToBackpack()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")

	arg_3_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0:getWidth(), var_3_0:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list_:align(display.LEFT_BOTTOM, 0, 0)
	arg_3_0.list_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list_:reload()
	arg_3_0:setupText()
end

function var_0_0.setupText(arg_4_0)
	arg_4_0:nodeByName("text_tip_1"):setString(var_0_3:translation("DRAGONBOAT_RESULT_TIP1"))
	arg_4_0:nodeByName("text_tip_2"):setString(var_0_3:translation("DRAGONBOAT_RESULT_TIP2"))
	arg_4_0:nodeByName("text_tip_3"):setString(var_0_3:translation("DRAGONBOAT_RESULT_TIP3"))
	arg_4_0:nodeByName("text_tip_4"):setString(string.format(var_0_3:translation("DRAGONBOAT_RESULT_TIP4"), arg_4_0.rank_ - 1))
	arg_4_0:nodeByName("text_match_tip"):setString(var_0_3:translation("DRAGONBOAT_RESULT_TIP5"))
	arg_4_0:nodeByName("text_best_rank"):setString(var_0_3:translation("DRAGONBOAT_RESULT_TIP6"))
	arg_4_0:nodeByName("text_value1"):setString(arg_4_0:getClock(arg_4_0.costTime_))
	arg_4_0:nodeByName("text_value2"):setString(arg_4_0.rank_)
	arg_4_0:nodeByName("text_value3"):setString(string.format("%.2f", arg_4_0.costTime_ - arg_4_0.preCostTime_))

	if arg_4_0.rank_ == 1 then
		arg_4_0:nodeByName("text_tip_3"):hide()
		arg_4_0:nodeByName("text_tip_4"):hide()
		arg_4_0:nodeByName("text_value3"):hide()
	end

	if arg_4_0.rank_ < arg_4_0.lastRank_ then
		arg_4_0:nodeByName("text_best_rank"):hide()
		arg_4_0:nodeByName("text_up_rank"):setString(arg_4_0.lastRank_ - arg_4_0.rank_)
	else
		arg_4_0:nodeByName("text_record"):hide()
		arg_4_0:nodeByName("arrow_up"):hide()

		local var_4_0 = arg_4_0.lastRank_ > 0 and arg_4_0.lastRank_ or arg_4_0.rank_

		arg_4_0:nodeByName("text_up_rank"):setString(var_4_0)
	end

	if #arg_4_0.matchPlayers < 1 then
		arg_4_0:nodeByName("text_match_tip"):hide()
	end
end

function var_0_0.getClock(arg_5_0, arg_5_1)
	local var_5_0 = math.floor(arg_5_1)
	local var_5_1 = math.floor(var_5_0 / 60)
	local var_5_2 = var_5_0 % 60
	local var_5_3 = math.floor((arg_5_1 - var_5_0) * 100)

	return (string.format("%02d'%02d\"%02d", var_5_1, var_5_2, var_5_3))
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0.matchPlayers[arg_7_3]

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.matchPlayers
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1 = arg_7_0.list_:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.list_:newItem()
		else
			var_7_1:removeAllChildren()
		end

		local var_7_2 = arg_7_0:nodeByName("list")
		local var_7_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1060/result/avatar_item.csb")
		local var_7_4 = var_7_3:getChildByName("background")

		var_7_3:size(var_7_4:getWidth(), var_7_4:getHeight())
		xyd.setPlayerAvatar(var_7_3:getChildByName("avatar"), var_7_0)
		var_7_3:getChildByName("text_name"):setString(var_7_0.player_name)
		var_7_3:getChildByName("text_rank"):setString(var_7_0.rank)
		var_7_3:getChildByName("text_name_tip"):setString(var_0_3:translation("DRAGONBOAT_MATCH_PLAYER_RANK_TIP"))
		var_7_3:align(display.LEFT_BOTTOM, 0, 0)
		var_7_1:setItemSize(var_7_3:getWidth() + 10, var_7_3:getHeight())
		var_7_1:addContent(var_7_3)

		return var_7_1
	end
end

function var_0_0.playEffect(arg_8_0)
	if not arg_8_0.effect_ then
		local var_8_0 = "skeletons/ui_effect/common_effect_spin3/common_effect_spin3"
		local var_8_1 = var_8_0 .. ".json"
		local var_8_2 = var_8_0 .. ".atlas"

		arg_8_0.effect_ = var_0_1.new(var_8_1, var_8_2, 1)

		arg_8_0.effect_:addTo(arg_8_0:nodeByName("container_effect"))
		arg_8_0.effect_:align(display.CENTER, arg_8_0:nodeByName("container_effect"):getWidth() / 2, arg_8_0:nodeByName("container_effect"):getHeight() / 2)
	end

	arg_8_0.effect_:play(nil, true)
end

function var_0_0.addItemsToBackpack(arg_9_0)
	if arg_9_0.awards_ and next(arg_9_0.awards_.awards or {}) then
		arg_9_0.selfPlayer:handleRewards(arg_9_0.awards_.awards)
	end
end

function var_0_0.willClose(arg_10_0)
	if arg_10_0.effect_ then
		arg_10_0.effect_:stop()
	end

	xyd.WindowManager.get():closeWindow("dragon_boat_boating")
end

return var_0_0
