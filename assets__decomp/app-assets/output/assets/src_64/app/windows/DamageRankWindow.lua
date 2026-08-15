local var_0_0 = class("DamageRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.chapterID = arg_1_2.chapter_id
	arg_1_0.rankList = arg_1_2.rankList
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevX_ = arg_2_1.x
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" then
		local var_2_0 = 20

		if var_2_0 <= math.abs(arg_2_1.x - arg_2_0.prevX_) or var_2_0 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
			arg_2_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 737, 521),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list"))

	arg_3_0:nodeByName("title"):setString(var_0_1:translation("DAMAGE_HIGHEST_ONE_TIME"))
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	var_0_0.super:willClose(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.list:removeAllItems()
	arg_5_0:sortTable(arg_5_0.rankList)

	for iter_5_0 = 1, #arg_5_0.rankList do
		local var_5_0 = arg_5_0.rankList[iter_5_0]

		if var_5_0.rank == 1 then
			arg_5_0.maxDamage = var_5_0.damage
		end

		local var_5_1 = var_5_0.damage / arg_5_0.maxDamage
		local var_5_2 = display.newNode()
		local var_5_3 = arg_5_0.list:newItem()
		local var_5_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/damage_rank_new/damage_item_new.csb")
		local var_5_5 = var_5_4:getChildByName("container")

		var_5_5:getChildByName("progress_bg"):getChildByName("damage_progress"):setPercent(var_5_1 * 100)

		local var_5_6 = arg_5_0:createShowNumbers(var_5_0.damage)

		var_5_5:getChildByName("damage_txt"):setString(var_5_6)
		var_5_5:getChildByName("damage_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_5_7, var_5_8 = var_5_5:getChildByName("rank_pos"):getPosition()
		local var_5_9 = 0

		for iter_5_1 = #xyd.tables.misc.teamDungeonRank, 1, -1 do
			if var_5_0.rank <= xyd.tables.misc.teamDungeonRank[iter_5_1] then
				var_5_9 = xyd.tables.misc.teamDungeonRankReward[iter_5_1]
			end
		end

		var_5_5:getChildByName("rank_bonus"):setString(var_0_1:translation("TEAM_RANK_TIP") .. var_5_9 .. "%")

		if var_5_0.rank <= 3 then
			local var_5_10 = xyd.AssetLoader.get():loadSprite("windows/corporation_window/damage_rank/" .. var_5_0.rank .. ".png")

			var_5_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_10:addTo(var_5_5)
			var_5_10:setPosition(var_5_7, var_5_8)
		else
			local var_5_11 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

			var_5_11:setString(var_5_0.rank)
			var_5_11:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_11:addTo(var_5_5)
			var_5_11:setPosition(var_5_7, var_5_8)
		end

		var_5_5:getChildByName("player_name"):setString(var_5_0.player_name)

		local var_5_12 = {
			avatar_id = var_5_0.avatar_id,
			avatar_frame_id = var_5_0.avatar_frame_id
		}

		var_5_12.showLevel = true

		xyd.setPlayerAvatar(var_5_5:getChildByName("avatar"), var_5_12)

		if var_5_0.conquer_lev and var_5_0.conquer_lev > 0 then
			local var_5_13 = {
				x = -1.5,
				y = 2.5
			}

			xyd.setConquerLev(var_5_0.conquer_lev, var_5_5:getChildByName("lev_txt"), var_5_5:getChildByName("level_bg"), var_5_13, false, 1, nil, var_5_0.conquer_loop_id)
		else
			var_5_5:getChildByName("lev_txt"):setString(var_5_0.lev)
		end

		var_5_4:setContentSize(720, 132)
		var_5_2:addChild(var_5_4)
		var_5_2:setContentSize(720, 132)
		var_5_3:addContent(var_5_2)
		var_5_3:setItemSize(720, 140)
		arg_5_0.list:addItem(var_5_3)
	end

	arg_5_0.list:reload()
end

function var_0_0.sortTable(arg_6_0, arg_6_1)
	table.sort(arg_6_1, function(arg_7_0, arg_7_1)
		if arg_7_0.rank ~= arg_7_1.rank then
			return arg_7_0.rank < arg_7_1.rank
		end
	end)
end

function var_0_0.createShowNumbers(arg_8_0, arg_8_1)
	local var_8_0 = tostring(arg_8_1)
	local var_8_1 = string.len(var_8_0)
	local var_8_2 = ""

	for iter_8_0 = 1, var_8_1 do
		var_8_2 = var_8_2 .. string.sub(var_8_0, iter_8_0, iter_8_0)

		if var_8_1 - iter_8_0 > 0 and (var_8_1 - iter_8_0) % 3 == 0 then
			var_8_2 = var_8_2 .. "."
		end
	end

	return var_8_2
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

return var_0_0
