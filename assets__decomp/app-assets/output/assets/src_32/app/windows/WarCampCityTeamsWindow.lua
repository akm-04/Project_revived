local var_0_0 = class("WarCampCityTeamsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.warCamp

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.playerInfos = arg_1_2.player_infos
	arg_1_0.totalNum = arg_1_2.total_num
	arg_1_0.cityID = arg_1_2.cityID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()

	arg_2_0.myCamp = arg_2_0.warCamp_:getCampType()

	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.initList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.leftList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.leftList_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.leftList_:reload()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("text_name"):setString(var_0_2:name(arg_4_0.cityID))

	local var_4_0 = string.format(var_0_1:translation("WAR_CAMP_TEAMS_TIPS_1"), arg_4_0.totalNum)

	arg_4_0:nodeByName("text_team_num"):setString(var_4_0)
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.playerInfos

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.leftList_:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.leftList_:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initCell(var_5_6, arg_5_3)
		var_5_5:addChild(var_5_6)
		var_5_5:setContentSize(cc.size(arg_5_0.leftList_.viewRect_.width, var_5_6:getContentSize().height))
		var_5_4:setItemSize(arg_5_0.leftList_.viewRect_.width, var_5_6:getContentSize().height)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.playerInfos[arg_6_2].info
	local var_6_1 = arg_6_0.playerInfos[arg_6_2].team_num
	local var_6_2 = arg_6_0.playerInfos[arg_6_2].partner_num
	local var_6_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_map/city_team_item.csb")
	local var_6_4 = var_6_3:getChildByName("container")
	local var_6_5 = var_6_4:getContentSize()

	var_6_3:addTo(arg_6_1)
	arg_6_1:setContentSize(var_6_5)

	var_6_0.playerInfo = var_6_0

	xyd.setPlayerAvatar(var_6_4:getChildByName("avatar"), var_6_0)

	if var_6_0.conquer_lev and var_6_0.conquer_lev > 0 then
		xyd.setConquerLev(var_6_0.conquer_lev, var_6_4:getChildByName("text_lev"), var_6_4:getChildByName("level_bg"), nil, nil, nil, nil, var_6_0.conquer_loop_id)
	else
		var_6_4:getChildByName("text_lev"):setString(var_6_0.lev)
	end

	var_6_4:getChildByName("text_name"):setString(var_6_0.player_name)
	var_6_4:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_6_0.player_id))
	var_6_4:getChildByName("text_desc"):setString(string.format(var_0_1:translation("WAR_CAMP_TEAMS_TIPS_2"), var_6_1, var_6_2))
end

return var_0_0
