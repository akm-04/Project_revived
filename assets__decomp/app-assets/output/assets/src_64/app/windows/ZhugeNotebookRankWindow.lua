local var_0_0 = class("ZhugeNotebookRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rankData = arg_1_2.rank_data or {}
	arg_1_0.rankList = arg_1_0.rankData.list
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.initList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.list_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_7"))
	arg_4_0:nodeByName("text_fight_enemy"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_8"))
	arg_4_0:nodeByName("fight_enemy_num"):setString(arg_4_0.rankData.self_score)

	if arg_4_0.rankData.self_rank > 0 then
		local var_4_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_4_0:setString(arg_4_0.rankData.self_rank)
		var_4_0:setScale(1.5)
		var_4_0:addTo(arg_4_0:nodeByName("container"))

		local var_4_1 = cc.p(arg_4_0:nodeByName("my_rank_pos"):getPosition())

		var_4_0:setPosition(cc.p(var_4_1))
	end
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.rankList

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.list_:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.list_:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initCell(var_5_6, arg_5_3)
		var_5_5:addChild(var_5_6)
		var_5_5:setContentSize(cc.size(arg_5_0.list_.viewRect_.width, var_5_6:getContentSize().height))
		var_5_4:setItemSize(arg_5_0.list_.viewRect_.width, var_5_6:getContentSize().height)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.rankList[arg_6_2]
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/small_house/rank_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = var_6_2:getContentSize()

	var_6_1:addTo(arg_6_1)
	arg_6_1:setContentSize(var_6_3)

	var_6_0.playerInfo = var_6_0

	xyd.setPlayerAvatar(var_6_2:getChildByName("avatar"), var_6_0)

	if var_6_0.conquer_lev and var_6_0.conquer_lev > 0 then
		xyd.setConquerLev(var_6_0.conquer_lev, var_6_2:getChildByName("text_lev"), var_6_2:getChildByName("level_bg"), nil, nil, nil, nil, var_6_0.conquer_loop_id)
	else
		var_6_2:getChildByName("text_lev"):setString(var_6_0.lev)
	end

	var_6_2:getChildByName("text_name"):setString(var_6_0.player_name)
	var_6_2:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_6_0.player_id))
	var_6_2:getChildByName("fight_enemy_num"):setString(var_6_0.score)
	var_6_2:getChildByName("text_fight_enemy"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_8"))
	arg_6_0:initRankNum(var_6_2, arg_6_2)
end

function var_0_0.initRankNum(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0

	if arg_7_2 > 3 then
		var_7_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_7_0:setString(arg_7_2)
		var_7_0:setScale(1.5)
	else
		var_7_0 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/rank0" .. arg_7_2 .. ".png")
	end

	var_7_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_0:addTo(arg_7_1)

	local var_7_1 = cc.p(arg_7_1:getChildByName("rank_num"):getPosition())

	var_7_0:setPosition(var_7_1)
end

return var_0_0
