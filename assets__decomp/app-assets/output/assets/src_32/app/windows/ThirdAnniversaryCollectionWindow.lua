local var_0_0 = class("ThirdAnniversaryCollectionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ThirdAnniversaryWord
local var_0_3 = xyd.tables.ThirdAnniversaryWordReward
local var_0_4 = xyd.tables.misc
local var_0_5 = {
	16,
	8,
	4,
	2,
	1
}
local var_0_6 = {}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.getTimes = arg_1_0.thirdAnniModel.collectInfo.get_times
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.container = arg_2_0:nodeByName("container")
	arg_2_0.state = 0
	arg_2_0.count = 0
	arg_2_0.isRemoving = {
		false,
		false,
		false,
		false,
		false
	}

	arg_2_0:nodeByName("red_point"):setVisible(false)
	arg_2_0.thirdAnniModel:getDiaryInfo(function(arg_3_0)
		if arg_3_0.get_list and next(arg_3_0.get_list) and arg_2_0.getTimes < var_0_4:getValue("activity_anniversary_word_get_limit") then
			arg_2_0:nodeByName("red_point"):setVisible(true)
		end
	end)
	arg_2_0:prepare()
	arg_2_0:updateLeftBtns()
	arg_2_0:updateItems()
	arg_2_0:updateItemNum()
	arg_2_0:nodeByName("word_rule"):setString(var_0_1:translation("THIRD_ANNI_WORD_LEFT_TXT1"))
	arg_2_0:nodeByName("word_mercy"):setString(var_0_1:translation("THIRD_ANNI_WORD_LEFT_TXT2"))
	arg_2_0:nodeByName("word_beg"):setString(var_0_1:translation("THIRD_ANNI_WORD_LEFT_TXT3"))
	arg_2_0:nodeByName("word_award"):setString(var_0_1:translation("THIRD_ANNI_WORD_LEFT_TXT4"))
	arg_2_0:nodeByName("word_rank"):setString(var_0_1:translation("THIRD_ANNI_WORD_LEFT_TXT5"))
	arg_2_0:nodeByName("word_mix"):setString(var_0_1:translation("THIRD_ANNI_WORD_MIDDLE_TXT1"))
end

function var_0_0.prepare(arg_4_0)
	arg_4_0:nodeByName("tip"):setString(var_0_1:translation("ACTIVITY_WORD_TIP_1"))
	arg_4_0:nodeByName("tip"):enableOutline(cc.c4b(214, 86, 95, 188), 2)

	local var_4_0 = var_0_3:ids()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = var_0_3:wordTypes(var_4_0[iter_4_0])
		local var_4_2 = 0

		for iter_4_1 = 1, #var_4_1 do
			var_4_2 = var_4_2 + var_0_5[var_4_1[iter_4_1]]
		end

		var_0_6[var_4_2] = var_4_0[iter_4_0]
	end

	arg_4_0:nodeByName("mix_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("mix_btn"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if var_0_6[arg_4_0.state] and arg_4_0:checkItems() then
				xyd.Backend.get():request(xyd.mid.THIRD_ANNI_WORD_REWARD, {
					idx = var_0_6[arg_4_0.state]
				}, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_4_0.selfPlayer:handleRewards(arg_6_1.awards)

						local var_6_0 = arg_4_0.container:getChildByName("item_container1")

						for iter_6_0 = 1, 5 do
							if math.floor(arg_4_0.state / var_0_5[iter_6_0]) % 2 == 1 then
								local var_6_1 = var_6_0:getChildByName("item" .. iter_6_0)
								local var_6_2 = {}

								var_6_2.itemNum = 1
								var_6_2.itemID = var_0_2:itemId(iter_6_0)

								arg_4_0.backpack:removeItem(var_6_2)
								var_6_1:getChildByName("num_txt"):setString(arg_4_0.backpack:getItemNumByID(var_0_2:itemId(iter_6_0)) or 0)
							end
						end
					end
				end)
			elseif var_0_6[arg_4_0.state] then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ZHUGE_FOREST_TIPS_15")
				})
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_WORD_TIP_3")
				})
			end
		end
	end)
	arg_4_0:nodeByName("diary_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("diary_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0.thirdAnniModel:getDiaryInfo(function(arg_8_0)
				arg_4_0:nodeByName("red_point"):setVisible(false)
				xyd.WindowManager.get():openWindow("third_anni_word_diary", arg_8_0)
			end)
		end
	end)
end

function var_0_0.checkItems(arg_9_0)
	for iter_9_0 = 1, 5 do
		if math.floor(arg_9_0.state / var_0_5[iter_9_0]) % 2 == 1 then
			local var_9_0 = arg_9_0.backpack:getItemNumByID(var_0_2:itemId(iter_9_0))

			if not var_9_0 or not (var_9_0 > 0) then
				return false
			end
		end
	end

	return true
end

function var_0_0.updateLeftBtns(arg_10_0)
	local var_10_0 = arg_10_0.container:getChildByName("left_container")

	var_10_0:getChildByName("rule_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("rule_btn"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = {
				title_name = "ACTIVITY_WORD_RULE_TITLE",
				rule = "ACTIVITY_WORD_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("third_anni_word_rule", var_11_0)
		end
	end)
	var_10_0:getChildByName("mercy_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("mercy_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_word_beg", {
				_type = "mercy"
			})
		end
	end)
	var_10_0:getChildByName("beg_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("beg_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_word_beg", {
				_type = "beg"
			})
		end
	end)
	var_10_0:getChildByName("award_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("award_btn"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_anni_word_reward")
		end
	end)
	var_10_0:getChildByName("rank_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("rank_btn"), arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0.thirdAnniModel:getCollectRank(function(arg_16_0)
				xyd.WindowManager.get():openWindow("third_diglett_rank", {
					_type = 2,
					data = arg_16_0
				})
			end)
		end
	end)
end

function var_0_0.updateItems(arg_17_0)
	local var_17_0 = arg_17_0.container:getChildByName("item_container1")

	for iter_17_0 = 1, 5 do
		local var_17_1 = var_17_0:getChildByName("item" .. iter_17_0)

		var_17_1:getChildByName("num_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
		var_17_1:setTouchEnabled(true)
		var_17_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "began" then
				var_17_1:setScale(0.9)
			elseif arg_18_0.name == "moved" then
				var_17_1:setScale(1)
			elseif arg_18_0.name == "ended" then
				var_17_1:setScale(1)
				xyd.playButtonSound()

				if math.floor(arg_17_0.state / var_0_5[iter_17_0]) % 2 == 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_WORD_TIP_2")
					})
				elseif arg_17_0.backpack:getItemNumByID(var_0_2:itemId(iter_17_0)) > 0 then
					arg_17_0.state = arg_17_0.state + var_0_5[iter_17_0]

					arg_17_0:createAddItem(iter_17_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("THIRD_ANNIVERSARY_WORD_TIP_1")
					})
				end
			end

			return true
		end)
	end
end

function var_0_0.updateItemNum(arg_19_0)
	local var_19_0 = arg_19_0.container:getChildByName("item_container1")

	for iter_19_0 = 1, 5 do
		local var_19_1 = var_19_0:getChildByName("item" .. iter_19_0)
		local var_19_2 = arg_19_0.backpack:getItemNumByID(var_0_2:itemId(iter_19_0)) or 0

		var_19_1:getChildByName("num_txt"):setString(var_19_2)
	end
end

function var_0_0.createAddItem(arg_20_0, arg_20_1)
	local var_20_0 = 154
	local var_20_1 = math.floor(arg_20_0:nodeByName("item_container1"):getPositionY() - arg_20_0:nodeByName("item_container2"):getPositionY())
	local var_20_2 = xyd.AssetLoader.get():loadSprite("windows/anniversary3rd/word_collection/icon" .. arg_20_1 .. ".png")
	local var_20_3 = arg_20_0:nodeByName("item_container2")
	local var_20_4, var_20_5 = var_20_3:getChildByName("item" .. arg_20_1):getPosition()

	var_20_2:setName("addItem" .. arg_20_1)
	var_20_2:addTo(var_20_3)
	var_20_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_20_2:setPosition(var_20_4, var_20_5 + var_20_1)
	var_20_2:setTouchEnabled(true)

	arg_20_0.count = arg_20_0.count + 1

	local var_20_6
	local var_20_7
	local var_20_8 = 0

	for iter_20_0 = 5, arg_20_1 + 1, -1 do
		if var_20_3:getChildByName("addItem" .. iter_20_0) and not arg_20_0.isRemoving[iter_20_0] then
			local var_20_9, var_20_10 = var_20_3:getChildByName("item" .. arg_20_0.count - var_20_8):getPosition()

			var_20_3:getChildByName("addItem" .. iter_20_0):stopAllActions()
			var_20_3:getChildByName("addItem" .. iter_20_0):runAction(cc.MoveTo:create(0.15, cc.p(var_20_9, var_20_10)))

			var_20_8 = var_20_8 + 1
		end
	end

	local var_20_11, var_20_12 = var_20_3:getChildByName("item" .. arg_20_0.count - var_20_8):getPosition()

	var_20_2:runAction(cc.MoveTo:create(0.3, cc.p(var_20_11, var_20_12)))
	var_20_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "ended" then
			var_20_2:setTouchEnabled(false)

			arg_20_0.isRemoving[arg_20_1] = true

			var_20_2:runAction(cc.Sequence:create({
				cc.MoveTo:create(0.3, cc.p(var_20_4, var_20_5 + var_20_1)),
				cc.CallFunc:create(function()
					var_20_2:removeSelf()

					var_20_2 = nil
					arg_20_0.isRemoving[arg_20_1] = false
				end)
			}))

			arg_20_0.state = arg_20_0.state - var_0_5[arg_20_1]
			arg_20_0.count = arg_20_0.count - 1

			local var_21_0 = 0

			for iter_21_0 = 5, arg_20_1 + 1, -1 do
				if var_20_3:getChildByName("addItem" .. iter_21_0) and not arg_20_0.isRemoving[iter_21_0] then
					var_20_11, var_20_12 = var_20_3:getChildByName("item" .. arg_20_0.count - var_21_0):getPosition()

					var_20_3:getChildByName("addItem" .. iter_21_0):runAction(cc.Sequence:create({
						cc.DelayTime:create(0.15),
						cc.MoveTo:create(0.15, cc.p(var_20_11, var_20_12))
					}))

					var_21_0 = var_21_0 + 1
				end
			end
		end

		return true
	end)
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	arg_23_0:addBlockLayer()
end

return var_0_0
