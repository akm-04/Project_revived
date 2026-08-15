local var_0_0 = class("ValentineGiftRankItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = xyd.tables.hero
local var_0_4 = {
	GIVE = 1,
	RECEIVE = 2
}

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1142/rank/rank_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.player_info.lev)

	if arg_4_1.player_info.conquer_lev and arg_4_1.player_info.conquer_lev > 0 then
		xyd.setConquerLev(arg_4_1.player_info.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), {
			x = -2,
			y = 3
		}, nil, nil, nil, arg_4_1.player_info.conquer_loop_id)
	end

	arg_4_0.contentView_:nodeByName("name"):setString(arg_4_1.player_info.player_name)

	local var_4_0 = {
		avatar_id = arg_4_1.player_info.avatar_id,
		avatar_frame_id = arg_4_1.player_info.avatar_frame_id,
		playerInfo = arg_4_1.player_info
	}

	arg_4_0.contentView_:nodeByName("avatar"):setContentSize(80, 80)
	arg_4_0.contentView_:nodeByName("avatar"):setAnchorPoint(0.5, 0.5)
	arg_4_0.contentView_:nodeByName("region"):setString("S" .. arg_4_1.player_info.region)
	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("avatar"), var_4_0)
	xyd.setRankLabel(arg_4_0.contentView_:nodeByName("rank"), arg_4_3, left)

	local var_4_1

	if arg_4_2 == var_0_4.GIVE then
		var_4_1 = string.format(var_0_1:translation("VALENTINE_TIPS_TXT11"), arg_4_1.num)
	elseif arg_4_2 == var_0_4.RECEIVE then
		var_4_1 = string.format(var_0_1:translation("VALENTINE_TIPS_TXT12"), arg_4_1.num)
	end

	arg_4_0.contentView_:nodeByName("desc"):setString(var_4_1)
end

local var_0_5 = class("ValentineGiftRankWindow", import("app.common.ui.BaseWindow"))
local var_0_6 = xyd.tables.twoYearsCampaign
local var_0_7 = xyd.tables.translation
local var_0_8 = {
	GIVE = 1,
	RECEIVE = 2
}

function var_0_5.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_5.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.giveRankData = arg_5_2[var_0_8.GIVE]
	arg_5_0.receiveRankData = arg_5_2[var_0_8.RECEIVE]
end

function var_0_5.willOpen(arg_6_0, arg_6_1)
	var_0_5.super.willOpen(arg_6_0, arg_6_1)
end

function var_0_5.didOpen(arg_7_0, arg_7_1)
	var_0_5.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
	arg_7_0:layout()
end

function var_0_5.layout(arg_8_0)
	arg_8_0:initGiveRankList()
	arg_8_0:initReceiveRankList()
end

function var_0_5.initReceiveRankList(arg_9_0)
	if not arg_9_0.receiveRankListView_ then
		arg_9_0.receiveRankListView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 420, 470),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_9_0:nodeByName("receive_rank_list"))
	else
		arg_9_0.receiveRankListView_:removeAllItems()
	end

	for iter_9_0, iter_9_1 in pairs(arg_9_0.receiveRankData) do
		local var_9_0 = arg_9_0.receiveRankListView_:newItem()
		local var_9_1 = var_0_0.new()

		var_9_1:setParams(iter_9_1, 2, iter_9_0)
		var_9_0:addContent(var_9_1)
		var_9_0:setItemSize(var_9_1:getContentSize().width, var_9_1:getContentSize().height)
		arg_9_0.receiveRankListView_:addItem(var_9_0)
	end

	arg_9_0.receiveRankListView_:reload()
end

function var_0_5.initGiveRankList(arg_10_0)
	if not arg_10_0.giveRankListView_ then
		arg_10_0.giveRankListView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 420, 470),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_10_0:nodeByName("give_rank_list"))
	else
		arg_10_0.giveRankListView_:removeAllItems()
	end

	for iter_10_0, iter_10_1 in pairs(arg_10_0.giveRankData) do
		local var_10_0 = arg_10_0.giveRankListView_:newItem()
		local var_10_1 = var_0_0.new()

		var_10_1:setParams(iter_10_1, 1, iter_10_0)
		var_10_0:addContent(var_10_1)
		var_10_0:setItemSize(var_10_1:getContentSize().width, var_10_1:getContentSize().height)
		arg_10_0.giveRankListView_:addItem(var_10_0)
	end

	arg_10_0.giveRankListView_:reload()
end

function var_0_5.willClose(arg_11_0)
	return
end

return var_0_5
