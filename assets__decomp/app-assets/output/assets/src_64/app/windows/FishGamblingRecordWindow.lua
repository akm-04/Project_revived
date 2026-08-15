local var_0_0 = class("FishGamblingRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFish
local var_0_3 = xyd.tables.misc
local var_0_4 = {
	ITEM = 2,
	TITLE = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.responseInfo = arg_1_2.response1
	arg_1_0.responseRank = arg_1_2.response2
	arg_1_0.baseInfo = arg_1_0.responseInfo.fish_fight_info.base_info
	arg_1_0.gameInfo = arg_1_0.responseInfo.fish_fight_info.game_info
	arg_1_0.playerInfo = arg_1_0.responseInfo.fish_fight_info.player_info
	arg_1_0.myRank = arg_1_0.responseRank.my_rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.initData(arg_3_0)
	local var_3_0 = {}

	for iter_3_0 = 1, #arg_3_0.baseInfo do
		local var_3_1 = arg_3_0.baseInfo[iter_3_0]
		local var_3_2 = arg_3_0.gameInfo[iter_3_0]
		local var_3_3 = arg_3_0.playerInfo[iter_3_0]
		local var_3_4 = false

		for iter_3_1 = 1, #var_3_1 do
			local var_3_5 = var_3_1[iter_3_1]
			local var_3_6 = var_3_2[iter_3_1]
			local var_3_7 = var_3_3[iter_3_1]

			if var_3_6 ~= 0 then
				if not var_3_4 then
					var_3_4 = true

					local var_3_8 = {
						itemType = var_0_4.TITLE,
						round = iter_3_0
					}

					table.insert(var_3_0, var_3_8)
				end

				local var_3_9 = {}
				local var_3_10
				local var_3_11
				local var_3_12 = var_0_3:getValue("activity_fish_gambling_initial_gold")
				local var_3_13 = var_0_3:getValue("activity_fish_gambling_commision")
				local var_3_14 = var_0_2:score(var_3_5[1].fish_id)
				local var_3_15 = var_0_2:score(var_3_5[2].fish_id)
				local var_3_16 = var_3_14 / var_3_15
				local var_3_17 = var_3_15 / var_3_14
				local var_3_18 = var_3_5[1].bet
				local var_3_19 = var_3_5[2].bet

				if var_3_18 == var_3_12 and var_3_19 == var_3_12 then
					var_3_10 = 1 + 1 / (var_3_16 * var_3_16 * var_3_16 * var_3_16 * var_3_16 * var_3_16)
					var_3_11 = 1 + 1 / (var_3_17 * var_3_17 * var_3_17 * var_3_17 * var_3_17 * var_3_17)
				else
					var_3_10 = 1 + var_3_19 * (1 - var_3_13) / var_3_18
					var_3_11 = 1 + var_3_18 * (1 - var_3_13) / var_3_19
				end

				var_3_9.itemType = var_0_4.ITEM
				var_3_9.round = iter_3_0
				var_3_9.stage = iter_3_1
				var_3_9.odd1 = string.format("%.2f", var_3_10)
				var_3_9.odd2 = string.format("%.2f", var_3_11)
				var_3_9.bet1 = var_3_7[1]
				var_3_9.bet2 = var_3_7[2]
				var_3_9.fish1 = var_3_5[1].fish_id
				var_3_9.fish2 = var_3_5[2].fish_id
				var_3_9.winner = var_3_6

				table.insert(var_3_0, var_3_9)
			end
		end
	end

	arg_3_0.data = var_3_0
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("FIGHT_FISH_TEXT_2"))
	arg_4_0:nodeByName("text_total_bet"):setString(var_0_1:translation("FIGHT_FISH_TEXT_3"))
	arg_4_0:nodeByName("text_total_earning"):setString(var_0_1:translation("FIGHT_FISH_TEXT_4"))
	arg_4_0:nodeByName("bet_num"):setString(arg_4_0.myRank.total.score)
	arg_4_0:nodeByName("earning_num"):setString(arg_4_0.myRank.win.score - arg_4_0.myRank.lose.score)

	local var_4_0 = arg_4_0:nodeByName("list")

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0:getWidth(), var_4_0:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0)

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_1:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_1:newItem()
		else
			var_5_1:removeAllChildren(false)
		end

		local var_5_2 = arg_5_0.data[arg_5_3]
		local var_5_3 = arg_5_0:initCell(var_5_2, arg_5_3)
		local var_5_4 = var_5_3:getWidth()
		local var_5_5 = var_5_3:getHeight()

		var_5_1:setItemSize(var_5_4, var_5_5)
		var_5_1:addContent(var_5_3)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	if arg_6_1.itemType == var_0_4.TITLE then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/fish_gambling/record_title.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("title"):setString(string.format(var_0_1:translation("NUM_LUN"), var_0_1:translation("NUM_" .. arg_6_1.round)))
	else
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/fish_gambling/record_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("text_game"):setString(xyd.tables.activityFishGamblingOddSche:name(arg_6_1.stage))
		var_6_1:getChildByName("text_game"):enableOutline(cc.c4b(147, 48, 48, 255), 2)
		var_6_1:getChildByName("text_bet_rate_1"):setString(var_0_1:translation("FIGHT_FISH_TEXT_5"))
		var_6_1:getChildByName("text_bet_rate_2"):setString(var_0_1:translation("FIGHT_FISH_TEXT_5"))
		var_6_1:getChildByName("bet_rate_1"):setString(arg_6_1.odd1)
		var_6_1:getChildByName("bet_rate_2"):setString(arg_6_1.odd2)
		var_6_1:getChildByName("bet_num_1"):setString(arg_6_1.bet1)
		var_6_1:getChildByName("bet_num_2"):setString(arg_6_1.bet2)

		if arg_6_1.winner == 1 then
			var_6_1:getChildByName("text_result_1"):setString(var_0_1:translation("LVBU_WIN_TEXT"))
			var_6_1:getChildByName("text_result_2"):setString(var_0_1:translation("LVBU_LOSE_TEXT"))
			var_6_1:getChildByName("text_result_1"):setColor(cc.c3b(204, 78, 78))
			var_6_1:getChildByName("text_result_2"):setColor(cc.c3b(56, 56, 56))

			local var_6_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. arg_6_1.fish1 .. ".png")

			var_6_2:setScale(0.7)

			local var_6_3 = xyd.getItemBg(var_0_2:rarity(arg_6_1.fish1))

			xyd.displaySpriteOnContainer(var_6_3, var_6_1:getChildByName("icon_1"))
			xyd.displaySpriteOnContainer(var_6_2, var_6_1:getChildByName("icon_1"), false)

			local var_6_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. arg_6_1.fish2 .. ".png")

			var_6_4:setScale(0.7)

			local var_6_5 = xyd.getItemBg(var_0_2:rarity(arg_6_1.fish2))

			xyd.displaySpriteOnContainer(var_6_5, var_6_1:getChildByName("icon_2"))
			xyd.displaySpriteOnContainer(var_6_4, var_6_1:getChildByName("icon_2"), false)
			xyd.GrayNode(var_6_1:getChildByName("icon_2"))
		else
			var_6_1:getChildByName("text_result_1"):setString(var_0_1:translation("LVBU_LOSE_TEXT"))
			var_6_1:getChildByName("text_result_2"):setString(var_0_1:translation("LVBU_WIN_TEXT"))
			var_6_1:getChildByName("text_result_1"):setColor(cc.c3b(56, 56, 56))
			var_6_1:getChildByName("text_result_2"):setColor(cc.c3b(204, 78, 78))

			local var_6_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. arg_6_1.fish1 .. ".png")

			var_6_6:setScale(0.7)

			local var_6_7 = xyd.getItemBg(var_0_2:rarity(arg_6_1.fish1))

			xyd.displaySpriteOnContainer(var_6_7, var_6_1:getChildByName("icon_1"))
			xyd.displaySpriteOnContainer(var_6_6, var_6_1:getChildByName("icon_1"), false)
			xyd.GrayNode(var_6_1:getChildByName("icon_1"))

			local var_6_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. arg_6_1.fish2 .. ".png")

			var_6_8:setScale(0.7)

			local var_6_9 = xyd.getItemBg(var_0_2:rarity(arg_6_1.fish2))

			xyd.displaySpriteOnContainer(var_6_9, var_6_1:getChildByName("icon_2"))
			xyd.displaySpriteOnContainer(var_6_8, var_6_1:getChildByName("icon_2"), false)
		end

		var_6_1:getChildByName("btn_replay"):addTouchEventListener(function(arg_7_0, arg_7_1)
			xyd.buttonScaleAnim(arg_7_0, arg_7_1)

			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_7_0 = {
					round = arg_6_1.round,
					stage = arg_6_1.stage
				}

				xyd.Backend.get():request(3014, var_7_0, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0:playReport(arg_8_1)
					end
				end)
			end
		end)
	end

	var_6_0:setContentSize(var_6_1:getContentSize())

	return var_6_0
end

function var_0_0.playReport(arg_9_0, arg_9_1)
	local var_9_0 = json.decode(arg_9_1[1].content)
	local var_9_1 = import("app.scenes.FishBattleCreate")
	local var_9_2 = {
		reportData = var_9_0,
		battleType = xyd.BattleType.ReplayReport
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "fish_gambling_main"
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(var_9_1.new(var_9_2))
end

function var_0_0.didOpen(arg_10_0)
	var_0_0.super.didOpen(arg_10_0)
	arg_10_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
