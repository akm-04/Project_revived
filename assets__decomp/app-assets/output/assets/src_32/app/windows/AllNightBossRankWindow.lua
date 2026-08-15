local var_0_0 = class("AllNightBossRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.rankList = arg_1_2.rank_list
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:initList()
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("RANKING_LIST"))
	arg_4_0:nodeByName("text_my_rank"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_4"))
	arg_4_0:nodeByName("text_my_dmg"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_5"))
	arg_4_0:nodeByName("rank"):setString(arg_4_0.allNight.bossInfo.rank)
	arg_4_0:nodeByName("dmg"):setString(arg_4_0.allNight.bossInfo.self_damage)
end

function var_0_0.initList(arg_5_0)
	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("list"):getWidth(), arg_5_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setBounceable(true)
	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.list:reload()
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.rankList

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		if var_6_0 < arg_6_3 then
			return nil
		end

		local var_6_1 = arg_6_0.list:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.list:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = display.newNode()

		arg_6_0:initCell(var_6_2, arg_6_3)

		local var_6_3 = display.newNode()

		var_6_3:addChild(var_6_2)
		var_6_3:setContentSize(var_6_2:getContentSize())
		var_6_1:setItemSize(var_6_2:getContentSize().width, var_6_2:getContentSize().height)
		var_6_1:addContent(var_6_3)

		return var_6_1
	end
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/boss/rank_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = arg_7_0.rankList[arg_7_2]
	local var_7_4 = var_7_3.player_info

	if arg_7_2 < 4 then
		var_7_2:getChildByName("bg_rank_" .. arg_7_2):setVisible(true)
		var_7_2:getChildByName("rank_" .. arg_7_2):setVisible(true)
		var_7_2:getChildByName("rank"):setVisible(false)
	else
		var_7_2:getChildByName("rank"):setString(arg_7_2)
		var_7_2:getChildByName("rank"):enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end

	xyd.setPlayerAvatar(var_7_2:getChildByName("avatar"), {
		avatar_id = var_7_4.avatar_id,
		avatar_frame_id = var_7_4.avatar_frame_id
	})

	if var_7_4.conquer_lev and var_7_4.conquer_lev > 0 then
		local var_7_5 = {
			x = -1,
			y = 2
		}

		xyd.setConquerLev(var_7_4.conquer_lev, var_7_2:getChildByName("lev"), var_7_2:getChildByName("level_bg"), var_7_5, nil, nil, nil, var_7_4.conquer_loop_id)
	else
		var_7_2:getChildByName("lev"):setString(var_7_4.lev)
	end

	var_7_2:getChildByName("name"):setString(var_7_4.player_name)
	var_7_2:getChildByName("region"):setString("S" .. var_7_4.region)
	var_7_2:getChildByName("text_total_dmg"):setString(string.format(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_6"), var_7_3.damage))

	local var_7_6 = var_7_2:getContentSize()

	var_7_1:addTo(arg_7_1)
	arg_7_1:setContentSize(arg_7_0:nodeByName("list"):getWidth(), var_7_6.height + 5)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.startClick_ = true
		arg_8_0.prevX_ = arg_8_1.x
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
		arg_8_0.startClick_ = false
	end
end

function var_0_0.didOpen(arg_9_0)
	arg_9_0:addBlockLayer()
end

return var_0_0
