local var_0_0 = class("GuildWarPersonalStateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.guildBattleTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	if arg_3_0.guild.rankData[xyd.RankType.BATTLE] and arg_3_0.guild.rankData[xyd.RankType.BATTLE].subList then
		var_3_0 = arg_3_0.guild.rankData[xyd.RankType.BATTLE].subList[1].rankList
	end

	if cc.ui.UIListView.COUNT_TAG == arg_3_2 then
		return #var_3_0
	elseif cc.ui.UIListView.CELL_TAG == arg_3_2 then
		if arg_3_3 > #var_3_0 then
			return nil
		end

		local var_3_1 = arg_3_0.listView:dequeueItem()

		if not var_3_1 then
			var_3_1 = arg_3_0.listView:newItem()
		else
			var_3_1:removeAllChildren(true)
		end

		local var_3_2 = var_3_0[arg_3_3]
		local var_3_3 = display.newNode()

		arg_3_0:initCell(var_3_3, var_3_2, arg_3_3)

		local var_3_4 = display.newNode()

		var_3_4:addChild(var_3_3)
		var_3_4:setContentSize(var_3_3:getContentSize())
		var_3_1:setItemSize(var_3_3:getContentSize().width, var_3_3:getContentSize().height)
		var_3_1:addContent(var_3_4)

		return var_3_1
	end
end

function var_0_0.initCell(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/personal_fight_state/personal_item.csb")
	local var_4_1 = var_4_0:getChildByName("container")

	var_4_1:getChildByName("name_text"):setString(arg_4_2.player_name)
	var_4_1:getChildByName("kill_text"):setString(arg_4_2.kill_num)
	var_4_1:getChildByName("live_text"):setString(arg_4_2.alive_num)

	local var_4_2 = 0
	local var_4_3 = var_4_1:getChildByName("reward_container")

	if arg_4_2.guild_war_coin then
		var_4_2 = var_4_2 + 1

		xyd.setItemBorder(var_4_3:getChildByName("item_" .. var_4_2), -6, nil, nil, arg_4_2.guild_war_coin)
	end

	for iter_4_0, iter_4_1 in pairs(xyd.tables.guildBattleGiftTable:giftItem(arg_4_3)) do
		var_4_2 = var_4_2 + 1

		xyd.setItemBorder(var_4_3:getChildByName("item_" .. var_4_2), iter_4_1, nil, nil, xyd.tables.guildBattleGiftTable:giftNum(arg_4_3)[iter_4_0])
	end

	for iter_4_2 = 1, var_4_2 do
		var_4_3:getChildByName("item_" .. iter_4_2):setPositionX(var_4_3:getChildByName("item_" .. iter_4_2):getPositionX() + (5 - var_4_2) * 30)
	end

	if tonumber(arg_4_2.guild_id) == arg_4_0.guild.guild_id then
		if arg_4_0.guild.warSide == 1 then
			var_4_1:getChildByName("red_bg"):setVisible(false)
		else
			var_4_1:getChildByName("blue_bg"):setVisible(false)
		end
	elseif arg_4_0.guild.warSide == 1 then
		var_4_1:getChildByName("blue_bg"):setVisible(false)
	else
		var_4_1:getChildByName("red_bg"):setVisible(false)
	end

	xyd.setAvatarClip(var_4_1:getChildByName("icon"), arg_4_2.avatar_id, 1)

	local var_4_4 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_4_2.avatar_frame_id and arg_4_2.avatar_frame_id ~= 0 then
		var_4_4 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_4_2.avatar_frame_id] .. ".png"
	end

	local var_4_5 = xyd.AssetLoader.get():loadSprite(var_4_4)

	var_4_5:setPosition(35, 35)
	var_4_1:getChildByName("icon_border"):addChild(var_4_5)

	local var_4_6 = var_4_1:getContentSize()

	var_4_0:setContentSize(var_4_6)
	arg_4_1:setContentSize(var_4_6)
	var_4_0:setName("layout")
	var_4_0:setPosition(cc.p(0, 0))
	arg_4_1:addChild(var_4_0)
	arg_4_1:setTouchSwallowEnabled(false)
	arg_4_1:setTouchEnabled(true)
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super:willOpen(arg_5_1)

	arg_5_0.scrollViewMoved_ = false
	arg_5_0.listView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("list"):getWidth(), arg_5_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listView:setBounceable(true)
	arg_5_0.listView:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.listView:reload()
	arg_5_0:layout()
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
end

function var_0_0.layout(arg_7_0)
	arg_7_0:addBlockLayer()
	arg_7_0:nodeByName("name"):setString(var_0_1:translation("NAME"))
	arg_7_0:nodeByName("kill"):setString(var_0_1:translation("KILL"))
	arg_7_0:nodeByName("live"):setString(var_0_1:translation("ALIVE"))
	arg_7_0:nodeByName("reward"):setString(var_0_1:translation("MAYBE_REWARD"))
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super:willClose(arg_8_1)
end

return var_0_0
