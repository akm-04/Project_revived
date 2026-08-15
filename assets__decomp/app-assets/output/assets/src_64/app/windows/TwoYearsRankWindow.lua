local var_0_0 = class("TwoYearsRankItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/two_years/two_years_rank_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.contentView_:nodeByName("name"):setString(arg_4_1.player_info.player_name)
	arg_4_0.contentView_:nodeByName("region"):setString("S" .. arg_4_1.player_info.region)
	arg_4_0.contentView_:nodeByName("bonus_stars"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT8"), arg_4_1.star))
	arg_4_0.contentView_:nodeByName("time"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT23"), xyd.date("%x %X", arg_4_1.time)))
	arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.player_info.lev)

	if arg_4_1.player_info.conquer_lev and arg_4_1.player_info.conquer_lev > 0 then
		xyd.setConquerLev(arg_4_1.player_info.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), {
			x = -2,
			y = 3
		})
	end

	arg_4_0.contentView_:nodeByName("avatar_node"):setAnchorPoint(0.5, 0.5)
	arg_4_0.contentView_:nodeByName("avatar_node"):setContentSize(80, 80)

	local var_4_0 = {
		avatar_id = arg_4_1.player_info.avatar_id,
		avatar_frame_id = arg_4_1.player_info.avatar_frame_id,
		player_info = arg_4_1.player_info
	}

	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("avatar_node"), var_4_0)
	arg_4_0:initRankNum(arg_4_0.contentView_:nodeByName("rank_node"), arg_4_1.rank)
end

function var_0_0.initRankNum(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0

	if arg_5_2 > 3 then
		var_5_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_5_0:setString(arg_5_2)
		var_5_0:setScale(1.2)
	else
		var_5_0 = xyd.AssetLoader.get():loadSprite("windows/two_years/concentrate/rank0" .. arg_5_2 .. ".png")

		var_5_0:setScale(0.8)
	end

	var_5_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_0:addTo(arg_5_1)

	local var_5_1 = cc.p(arg_5_1:getPosition())

	var_5_0:setPosition(var_5_1)
end

local var_0_4 = class("TwoYearsRankWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = xyd.tables.translation

function var_0_4.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_4.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.rank_list = arg_6_2.rank_list
	arg_6_0.self_rank = arg_6_2.self_rank
end

function var_0_4.willOpen(arg_7_0, arg_7_1)
	var_0_4.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_4.didOpen(arg_8_0, arg_8_1)
	var_0_4.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:initListView()
	arg_8_0:updateSelfRank()
end

function var_0_4.initListView(arg_9_0)
	if not arg_9_0.listView_ then
		arg_9_0.listView_ = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, arg_9_0:nodeByName("rank_list"):getWidth(), arg_9_0:nodeByName("rank_list"):getHeight()),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_9_0:nodeByName("rank_list"))
	else
		arg_9_0.listView_:removeAllItems()
	end

	for iter_9_0, iter_9_1 in pairs(arg_9_0.rank_list) do
		local var_9_0 = iter_9_1
		local var_9_1 = arg_9_0.listView_:newItem()
		local var_9_2 = var_0_0.new()

		var_9_0.rank = iter_9_0

		var_9_2:setParams(var_9_0)
		var_9_1:addContent(var_9_2)
		var_9_1:setItemSize(var_9_2:getContentSize().width, var_9_2:getContentSize().height)
		arg_9_0.listView_:addItem(var_9_1)
	end

	arg_9_0.listView_:reload()
end

function var_0_4.updateSelfRank(arg_10_0)
	arg_10_0:nodeByName("my_rank_txt"):setString(var_0_5:translation("MYRANK_TEXT"))

	local var_10_0
	local var_10_1 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

	var_10_1:setString(arg_10_0.self_rank.rank)
	var_10_1:setScale(1.2)
	var_10_1:setAnchorPoint(cc.p(0, 0.5))
	var_10_1:addTo(arg_10_0:nodeByName("my_rank"))
	var_10_1:setPosition(0, 0)
end

function var_0_4.scrollListener(arg_11_0, arg_11_1)
	return
end

function var_0_4.willClose(arg_12_0)
	return
end

return var_0_4
