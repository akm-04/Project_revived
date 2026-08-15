local var_0_0 = class("NewTermRankItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = 80
local var_0_4 = xyd.tables.hero
local var_0_5 = 1
local var_0_6 = 2

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/new_term/rank_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0.contentView_:nodeByName("region"):setString("S" .. xyd.getPlayerRegion(arg_4_1.player_id))
	arg_4_0.contentView_:nodeByName("player_name"):setString(arg_4_1.player_name)

	if arg_4_3 == var_0_5 then
		arg_4_0.contentView_:nodeByName("desc"):setString(var_0_1:translation("LIANYI_TEXT12"))
		arg_4_0.contentView_:nodeByName("desc_num"):setString(arg_4_1.score)
	else
		arg_4_0.contentView_:nodeByName("desc"):setString(var_0_1:translation("LIANYI_TEXT13"))
		arg_4_0.contentView_:nodeByName("desc_num"):setString(arg_4_1.score)
	end

	if arg_4_1.conquer_lev and arg_4_1.conquer_lev ~= 0 then
		xyd.setConquerLev(arg_4_1.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), nil, nil, nil, nil, arg_4_1.conquer_loop_id)
	else
		arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.lev)
	end

	arg_4_0.contentView_:nodeByName("player_icon"):setContentSize(var_0_3, var_0_3)
	arg_4_0.contentView_:nodeByName("player_icon"):setAnchorPoint(0.5, 0.5)

	local var_4_0 = arg_4_1

	var_4_0.playerInfo = {
		player_id = arg_4_1.player_id
	}

	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("player_icon"), var_4_0)

	if arg_4_2 == 1 then
		arg_4_0.contentView_:nodeByName("1"):setVisible(true)
		arg_4_0.contentView_:nodeByName("2"):setVisible(false)
		arg_4_0.contentView_:nodeByName("3"):setVisible(false)
		arg_4_0.contentView_:nodeByName("rank_txt"):setVisible(false)
	elseif arg_4_2 == 2 then
		arg_4_0.contentView_:nodeByName("1"):setVisible(false)
		arg_4_0.contentView_:nodeByName("2"):setVisible(true)
		arg_4_0.contentView_:nodeByName("3"):setVisible(false)
		arg_4_0.contentView_:nodeByName("rank_txt"):setVisible(false)
	elseif arg_4_2 == 3 then
		arg_4_0.contentView_:nodeByName("1"):setVisible(false)
		arg_4_0.contentView_:nodeByName("2"):setVisible(false)
		arg_4_0.contentView_:nodeByName("3"):setVisible(true)
		arg_4_0.contentView_:nodeByName("rank_txt"):setVisible(false)
	else
		arg_4_0.contentView_:nodeByName("1"):setVisible(false)
		arg_4_0.contentView_:nodeByName("2"):setVisible(false)
		arg_4_0.contentView_:nodeByName("3"):setVisible(false)
		arg_4_0.contentView_:nodeByName("rank_txt"):setVisible(true)
		arg_4_0.contentView_:nodeByName("rank_txt"):setString(arg_4_2)
		arg_4_0.contentView_:nodeByName("rank_txt"):enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end
end

local var_0_7 = class("NewTermRankWindow", import("app.common.ui.BaseWindow"))
local var_0_8 = import("app.common.ui.SpineEffect")
local var_0_9 = xyd.tables.translation
local var_0_10 = import("framework.scheduler")
local var_0_11 = "windows/new_term/rank/charm_rank.png"
local var_0_12 = "windows/new_term/rank/connection_rank.png"

function var_0_7.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_7.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.rankList = arg_5_2.list or {}
	arg_5_0.selfRank = arg_5_2.self_rank
	arg_5_0.selfScore = arg_5_2.self_score
	arg_5_0.mode = arg_5_2.mode or var_0_5
end

function var_0_7.willOpen(arg_6_0, arg_6_1)
	var_0_7.super.willOpen(arg_6_0, arg_6_1)
end

function var_0_7.didOpen(arg_7_0, arg_7_1)
	var_0_7.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
	arg_7_0:layout()
end

function var_0_7.layout(arg_8_0)
	arg_8_0:nodeByName("my_rank_num"):enableOutline(cc.c4b(121, 52, 52, 255), 3)

	if arg_8_0.selfRank then
		arg_8_0:nodeByName("my_rank"):setString(string.format(var_0_9:translation("LIANYI_TEXT9"), ""))
		arg_8_0:nodeByName("my_rank_num"):setString(arg_8_0.selfRank)
	else
		arg_8_0:nodeByName("my_rank"):setVisible(false)
		arg_8_0:nodeByName("my_rank_num"):setVisible(false)
	end

	if arg_8_0.mode == var_0_5 then
		arg_8_0:nodeByName("title"):setString(var_0_9:translation("LIANYI_TIP5"))

		if arg_8_0.selfScore then
			arg_8_0:nodeByName("my_score"):setString(string.format(var_0_9:translation("LIANYI_TEXT10"), ""))
			arg_8_0:nodeByName("my_score_num"):setString(arg_8_0.selfScore)
		else
			arg_8_0:nodeByName("my_score"):setVisible(false)
			arg_8_0:nodeByName("my_score_num"):setVisible(false)
		end
	else
		arg_8_0:nodeByName("title"):setString(var_0_9:translation("LIANYI_TIP4"))

		if arg_8_0.selfScore then
			arg_8_0:nodeByName("my_score"):setString(string.format(var_0_9:translation("LIANYI_TEXT11"), ""))
			arg_8_0:nodeByName("my_score_num"):setString(arg_8_0.selfScore)
		else
			arg_8_0:nodeByName("my_score"):setVisible(false)
			arg_8_0:nodeByName("my_score_num"):setVisible(false)
		end
	end

	arg_8_0:initListView()
	arg_8_0:updateListView()
end

function var_0_7.initListView(arg_9_0)
	if not arg_9_0.listView_ then
		arg_9_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 780, 416),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_9_0:nodeByName("rank_container"))
	else
		arg_9_0.listView_:removeAllItems()
	end
end

function var_0_7.updateListView(arg_10_0)
	for iter_10_0 = 1, #arg_10_0.rankList do
		local var_10_0 = arg_10_0.listView_:newItem()
		local var_10_1 = var_0_0.new()

		var_10_1:setParams(arg_10_0.rankList[iter_10_0], iter_10_0, arg_10_0.mode)
		var_10_0:addContent(var_10_1)
		var_10_0:setItemSize(759, 138)
		arg_10_0.listView_:addItem(var_10_0)
	end

	arg_10_0.listView_:reload()
end

function var_0_7.willClose(arg_11_0)
	if arg_11_0.handle then
		var_0_10.unscheduleGlobal(arg_11_0.handle)

		arg_11_0.handle = nil
	end
end

return var_0_7
