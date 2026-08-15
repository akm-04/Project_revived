local var_0_0 = class("FourthAnniPaintingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.fourthAnniPaintingTable
local var_0_3 = xyd.tables.fourthAnniPaintingGiftTable
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.misc
local var_0_6 = 1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.basePos = {
		x = 352,
		y = 598
	}
	arg_1_0.color = {
		cc.c3b(255, 123, 119),
		cc.c3b(135, 217, 244),
		cc.c3b(80, 223, 157),
		cc.c3b(255, 224, 204),
		cc.c3b(255, 255, 255),
		cc.c3b(54, 47, 44)
	}
	arg_1_0.params = arg_1_2 or {}
	arg_1_0.painted = arg_1_2.map
	arg_1_0.stage = arg_1_2.stage
	arg_1_0.isAward = arg_1_2.is_award
	arg_1_0.voteNum = arg_1_2.vote_num
	arg_1_0.notShow = arg_1_2.not_show
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.colorItem = {}
	arg_2_0.colorItem[1] = var_0_5:getValue("activity_anni_4th_red")
	arg_2_0.colorItem[2] = var_0_5:getValue("activity_anni_4th_blue")
	arg_2_0.colorItem[3] = var_0_5:getValue("activity_anni_4th_green")
	arg_2_0.colorItem[4] = var_0_5:getValue("activity_anni_4th_yellow")
	arg_2_0.colorItem[5] = var_0_5:getValue("activity_anni_4th_white")
	arg_2_0.colorItem[6] = var_0_5:getValue("activity_anni_4th_black")

	arg_2_0:nodeByName("vote_num"):setString(arg_2_0.voteNum)

	for iter_2_0 = 1, 6 do
		arg_2_0:nodeByName("color_des" .. iter_2_0):setString(string.char(string.byte("A") - 1 + iter_2_0))
	end

	arg_2_0.giftEffect = xyd.createEffect("skeletons/ui_effect/activity_anniversary_4th/painting_chest")

	arg_2_0.giftEffect:addTo(arg_2_0:nodeByName("container"))
	arg_2_0.giftEffect:pos(arg_2_0:nodeByName("btn_gift"):getPosition())
	arg_2_0.giftEffect:play(nil, true)
	arg_2_0:nodeByName("rank_txt"):setString(var_0_4:translation("RANKING_LIST"))
	arg_2_0:nodeByName("visit_txt"):setString(var_0_4:translation("FOURTH_ANNI_PAINT_TXT6"))
	arg_2_0:nodeByName("random_visit_txt"):setString(var_0_4:translation("FOURTH_ANNI_PAINT_TXT7"))
	arg_2_0:nodeByName("title_txt"):setString(var_0_4:translation("FOURTH_ANNI_PAINT_TXT8"))
	arg_2_0:nodeByName("talk_content"):setString(var_0_4:translation("FOURTH_ANNI_PAINT_TIP5"))

	arg_2_0.colorMode = 1
	arg_2_0.currentDraw = arg_2_0.stage

	arg_2_0:initDatas()
	arg_2_0:initBlocks()
	arg_2_0:setZOrders()
	arg_2_0:setBtns()
	arg_2_0:updateColorBtns()
	arg_2_0:changeDraw()
	arg_2_0:updateColorItemNums()
	arg_2_0:updateHideBtn()
end

function var_0_0.initDatas(arg_3_0)
	arg_3_0.bitNum = {}
	arg_3_0.bitNum[48] = 1

	for iter_3_0 = 47, 1, -1 do
		arg_3_0.bitNum[iter_3_0] = arg_3_0.bitNum[iter_3_0 + 1] * 2
	end

	arg_3_0.map = {}
	arg_3_0.doneMap = {}
	arg_3_0.undoNum = 0

	if arg_3_0.stage == 7 then
		for iter_3_1 = 1, 48 do
			arg_3_0.map[iter_3_1] = {}

			local var_3_0

			if arg_3_0.painted[iter_3_1] and arg_3_0.painted[iter_3_1] ~= "" then
				var_3_0 = xyd.splitToNumber(arg_3_0.painted[iter_3_1], "|")
			else
				var_3_0 = {}
			end

			for iter_3_2 = 1, 30 do
				arg_3_0.map[iter_3_1][iter_3_2] = var_3_0[iter_3_2] or 0
			end
		end

		arg_3_0.oldMap = clone(arg_3_0.map)
	else
		for iter_3_3 = 1, 48 do
			arg_3_0.map[iter_3_3] = {}

			local var_3_1 = var_0_2:getData(arg_3_0.stage, iter_3_3)

			for iter_3_4 = 1, 30 do
				arg_3_0.map[iter_3_3][iter_3_4] = var_3_1[iter_3_4] or 0
			end

			arg_3_0.doneMap[iter_3_3] = {}

			local var_3_2 = arg_3_0.painted[iter_3_3] or 0

			for iter_3_5 = 30, 1, -1 do
				arg_3_0.doneMap[iter_3_3][iter_3_5] = var_3_2 % 2
				var_3_2 = math.floor(var_3_2 / 2)

				if arg_3_0.doneMap[iter_3_3][iter_3_5] == 0 and arg_3_0.map[iter_3_3][iter_3_5] ~= 0 then
					arg_3_0.undoNum = arg_3_0.undoNum + 1
				end
			end
		end
	end
end

function var_0_0.initBlocks(arg_4_0)
	for iter_4_0 = 1, 48 do
		for iter_4_1 = 1, 30 do
			local var_4_0 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/block.png")

			var_4_0:pos(arg_4_0.basePos.x + 15 * iter_4_0, arg_4_0.basePos.y - 15 * iter_4_1)
			var_4_0:addTo(arg_4_0:nodeByName("container"):getChildByName("blocks"))
			var_4_0:setAnchorPoint(0.5, 0.5)
			var_4_0:setName("block_" .. iter_4_0 .. "_" .. iter_4_1)

			local var_4_1 = arg_4_0.map[iter_4_0][iter_4_1]

			if var_4_1 > 0 then
				var_4_0:setColor(arg_4_0.color[var_4_1])
			else
				var_4_0:setVisible(false)
			end

			if arg_4_0.stage ~= 7 and arg_4_0.doneMap[iter_4_0][iter_4_1] == 0 then
				var_4_0:setVisible(false)
			end
		end
	end

	local var_4_2 = display.newNode()

	var_4_2:size(720, 450)
	var_4_2:setAnchorPoint(0, 1)
	var_4_2:pos(arg_4_0.basePos.x + 7, arg_4_0.basePos.y - 7)
	var_4_2:addTo(arg_4_0:nodeByName("container"))
	var_4_2:setTouchEnabled(true)
	var_4_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		local var_5_0 = var_4_2:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))

		if arg_5_0.name == "began" then
			arg_4_0.blockJ = 30 - math.floor(var_5_0.y / 15)
			arg_4_0.blockI = math.floor(var_5_0.x / 15) + 1

			return true
		elseif arg_5_0.name == "ended" then
			if arg_4_0.currentDraw < arg_4_0.stage then
				return
			end

			if arg_4_0.currentDraw > arg_4_0.stage then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("FOURTH_ANNI_PAINT_TXT23")
				})

				return
			end

			local var_5_1 = 30 - math.floor(var_5_0.y / 15)
			local var_5_2 = math.floor(var_5_0.x / 15) + 1

			if var_5_2 ~= arg_4_0.blockI or var_5_1 ~= arg_4_0.blockJ then
				return
			end

			arg_4_0:clickBlock(var_5_2, var_5_1)
		end
	end)
end

function var_0_0.clickBlock(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_0.stage == 7 then
		arg_6_0:selfDraw(arg_6_1, arg_6_2)
	else
		arg_6_0:normalPaint(arg_6_1, arg_6_2)
	end
end

function var_0_0.setZOrders(arg_7_0)
	for iter_7_0 = 1, 6 do
		arg_7_0:nodeByName("color" .. iter_7_0):setLocalZOrder(5)
	end

	arg_7_0:nodeByName("bg7"):setLocalZOrder(2)
	arg_7_0:nodeByName("blocks"):setLocalZOrder(5)
end

function var_0_0.setBtns(arg_8_0)
	local var_8_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_8_0:addTo(arg_8_0:nodeByName("title"))
	var_8_0:setAnchorPoint(0.5, 0.5)
	var_8_0:setPosition(43, -23)
	var_8_0:setName("return_btn")

	arg_8_0.returnBtn = var_8_0

	arg_8_0.returnBtn:addTouchEvent(function(arg_9_0)
		if arg_9_0.name == "ended" then
			xyd.playCloseSound()

			local var_9_0 = 0

			if arg_8_0.oldMap then
				for iter_9_0 = 1, 48 do
					for iter_9_1 = 1, 30 do
						if arg_8_0.map[iter_9_0][iter_9_1] ~= arg_8_0.oldMap[iter_9_0][iter_9_1] then
							var_9_0 = 1

							break
						end
					end

					if var_9_0 == 1 then
						break
					end
				end
			end

			if arg_8_0.stage == 7 and var_9_0 == 1 then
				local var_9_1 = {
					txt = var_0_4:translation("FOURTH_ANNI_PAINT_TIP4"),
					rcallback = function()
						local var_10_0 = {}

						for iter_10_0 = 1, 48 do
							var_10_0[iter_10_0] = tostring(arg_8_0.map[iter_10_0][1])

							for iter_10_1 = 2, 30 do
								var_10_0[iter_10_0] = var_10_0[iter_10_0] .. "|" .. arg_8_0.map[iter_10_0][iter_10_1]
							end
						end

						xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_SAVE, {
							map = var_10_0
						}, function()
							xyd.WindowManager.get():closeWindow(arg_8_0)
						end)
					end,
					lcallback = function()
						xyd.WindowManager.get():closeWindow(arg_8_0)
					end
				}

				xyd.WindowManager.get():openWindow("common_alert", var_9_1)
			else
				xyd.WindowManager.get():closeWindow(arg_8_0)
			end
		end
	end)

	for iter_8_0 = 1, 6 do
		xyd.nodeEventSample(arg_8_0:nodeByName("color" .. iter_8_0), {
			scale = 1
		}, function()
			arg_8_0.colorMode = iter_8_0

			arg_8_0:updateColorBtns()
		end)
	end

	xyd.nodeEventSample(arg_8_0:nodeByName("btn_erase"), {
		scale = 1
	}, function()
		arg_8_0.colorMode = 0

		arg_8_0:updateColorBtns()
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_clear"), {
		scale = 1
	}, function()
		local var_15_0 = {
			txt = var_0_4:translation("FOURTH_ANNI_PAINT_TXT18"),
			rcallback = function()
				arg_8_0:clearDraw()
			end
		}

		xyd.WindowManager.get():openWindow("common_alert", var_15_0)
	end)

	for iter_8_1 = 1, 6 do
		xyd.nodeEventSample(arg_8_0:nodeByName("draw" .. iter_8_1), {
			scale = 1
		}, function()
			arg_8_0.currentDraw = iter_8_1

			arg_8_0:changeDraw()
		end)
	end

	xyd.nodeEventSample(arg_8_0:nodeByName("self_draw"), {
		scale = 1
	}, function()
		if arg_8_0.stage == 7 then
			arg_8_0.currentDraw = 7

			arg_8_0:changeDraw()
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("FOURTH_ANNI_PAINT_TXT19")
			})
		end
	end)
	arg_8_0:nodeByName("btn_gift"):setTouchEnabled(true)
	arg_8_0:nodeByName("btn_gift"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			if arg_8_0.stage <= arg_8_0.currentDraw then
				local var_19_0 = var_0_3:getGift(arg_8_0.currentDraw)
				local var_19_1 = xyd.tables.gift:items(var_19_0)
				local var_19_2 = xyd.tables.gift:itemNum(var_19_0)

				dump(var_19_0)
				dump(var_19_1)

				local var_19_3 = {}

				for iter_19_0 = 1, #var_19_1 do
					var_19_3[iter_19_0] = {}
					var_19_3[iter_19_0].item_id = var_19_1[iter_19_0]
					var_19_3[iter_19_0].item_num = var_19_2[iter_19_0]
				end

				xyd.WindowManager.get():openWindow("fourth_anni_award_items", {
					items = var_19_3
				})
			end

			return true
		elseif arg_19_0.name == "ended" and arg_8_0.isAward[arg_8_0.currentDraw] == 0 and arg_8_0.stage > arg_8_0.currentDraw then
			xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_AWARD, {
				award_id = arg_8_0.currentDraw
			}, function(arg_20_0, arg_20_1)
				if arg_20_0 == xyd.error.OK then
					arg_8_0:nodeByName("btn_gift"):setVisible(false)
					arg_8_0.giftEffect:setVisible(false)

					arg_8_0.isAward[arg_8_0.currentDraw] = 1

					arg_8_0:nodeByName("gift_open"):setVisible(true)
					arg_8_0.selfPlayer:handleRewards(arg_20_1.awards)
				end
			end)
		end
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_rank"), nil, function()
		xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_RANK_LIST, nil, function(arg_22_0, arg_22_1)
			if arg_22_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fourth_anni_paint_rank", arg_22_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_vote"), nil, function()
		local var_23_0 = {
			player_info = {},
			vote_num = arg_8_0.voteNum,
			player_id = arg_8_0.selfPlayer.playerID
		}

		var_23_0.player_info.player_name = arg_8_0.selfPlayer.playerName
		var_23_0.player_info.lev = arg_8_0.selfPlayer.lev
		var_23_0.player_info.avatar_id = arg_8_0.selfPlayer.avatarId or 110001001
		var_23_0.player_info.avatar_frame_id = arg_8_0.selfPlayer.avatarFrame
		var_23_0.player_info.conquer_lev = arg_8_0.selfPlayer.conquerLev
		var_23_0.player_info.conquer_loop_id = arg_8_0.selfPlayer.conquerLoopID

		xyd.WindowManager.get():openWindow("fourth_anni_paint_vote", var_23_0)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_random_visit"), nil, function()
		xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_VISIT_LIST, nil, function(arg_25_0, arg_25_1)
			if arg_25_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fourth_anni_paint_random_visit", arg_25_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_visit"), nil, function()
		xyd.WindowManager.get():openWindow("fourth_anni_paint_search")
	end)
	arg_8_0:nodeByName("btn_hide"):addTouchEventListener(function(arg_27_0, arg_27_1)
		arg_8_0:updateHideBtn()

		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_SET_SHOW, {
				not_show = 1 - arg_8_0.notShow
			}, function(arg_28_0, arg_28_1)
				if arg_28_0 == xyd.error.OK then
					arg_8_0.notShow = 1 - arg_8_0.notShow

					if arg_8_0.notShow == 1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("FOURTH_ANNI_PAINT_TXT21")
						})
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("FOURTH_ANNI_PAINT_TXT22")
						})
					end

					arg_8_0:updateHideBtn()
				end
			end)
		end
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("rule_btn"), nil, function()
		local var_29_0 = {
			hasOtherItem = true,
			title_name = "FOURTH_ANNI_PAINT_RULE_TITLE",
			rule = "FOURTH_ANNI_PAINT_RULE_TEXT",
			otherItemType = xyd.TextRuleItemType.Award,
			award = xyd.tables.fourthAnniPaintingRankTable
		}

		xyd.WindowManager.get():openWindow("fourth_anni_paint_rule", var_29_0)
	end)
end

function var_0_0.updateHideBtn(arg_30_0)
	if arg_30_0.notShow == 1 then
		arg_30_0:nodeByName("btn_hide"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_30_0:nodeByName("btn_hide"):setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.changeDraw(arg_31_0)
	arg_31_0:nodeByName("container"):getChildByName("blocks"):setVisible(arg_31_0.currentDraw == arg_31_0.stage)

	for iter_31_0 = 1, 7 do
		if arg_31_0:nodeByName("container"):getChildByName("bg" .. iter_31_0) then
			arg_31_0:nodeByName("container"):getChildByName("bg" .. iter_31_0):setVisible(false)
		end
	end

	if arg_31_0:nodeByName("container"):getChildByName("bg" .. arg_31_0.currentDraw) then
		arg_31_0:nodeByName("container"):getChildByName("bg" .. arg_31_0.currentDraw):setVisible(true)
	else
		local var_31_0

		if arg_31_0.currentDraw < arg_31_0.stage then
			var_31_0 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/bg" .. arg_31_0.currentDraw .. "_2.png")
		else
			var_31_0 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/bg" .. arg_31_0.currentDraw .. "_1.png")
		end

		var_31_0:addTo(arg_31_0:nodeByName("container"))

		local var_31_1, var_31_2 = arg_31_0:nodeByName("bg7"):getPosition()

		var_31_0:setPosition(var_31_1, var_31_2)
		var_31_0:setAnchorPoint(0.5, 0.5)
		var_31_0:setLocalZOrder(2)
		var_31_0:setName("bg" .. arg_31_0.currentDraw)
	end

	for iter_31_1 = 1, 6 do
		arg_31_0:nodeByName("draw" .. iter_31_1):setLocalZOrder(arg_31_0.currentDraw == iter_31_1 and 3 or 1)
	end

	arg_31_0:nodeByName("self_draw"):setLocalZOrder(arg_31_0.currentDraw == 7 and 3 or 1)
	arg_31_0:nodeByName("btn_erase"):setVisible(arg_31_0.currentDraw == 7)
	arg_31_0:nodeByName("btn_clear"):setVisible(arg_31_0.currentDraw == 7)
	arg_31_0:nodeByName("btn_gift"):setVisible(arg_31_0.currentDraw ~= 7 and arg_31_0.isAward[arg_31_0.currentDraw] == 0)

	if arg_31_0.stage > arg_31_0.currentDraw then
		arg_31_0:nodeByName("btn_gift"):setOpacity(0)
	else
		arg_31_0:nodeByName("btn_gift"):setOpacity(255)
	end

	arg_31_0.giftEffect:setVisible(arg_31_0.stage > arg_31_0.currentDraw and arg_31_0.isAward[arg_31_0.currentDraw] == 0)
	arg_31_0:nodeByName("gift_open"):setVisible(arg_31_0.currentDraw ~= 7 and arg_31_0.isAward[arg_31_0.currentDraw] == 1)
	arg_31_0:nodeByName("btn_vote"):setVisible(arg_31_0.currentDraw == 7)
	arg_31_0:nodeByName("btn_hide"):setVisible(arg_31_0.currentDraw == 7)
end

function var_0_0.updateColorBtns(arg_32_0)
	for iter_32_0 = 1, 6 do
		local var_32_0 = arg_32_0:nodeByName("color" .. iter_32_0)

		if iter_32_0 == arg_32_0.colorMode then
			var_32_0:setScale(1)
			var_32_0:setPositionX(1200)
		else
			var_32_0:setScale(0.75)
			var_32_0:setPositionX(1222)
		end
	end

	if arg_32_0.colorMode == 0 then
		arg_32_0:nodeByName("btn_erase"):setScale(1.25)
	else
		arg_32_0:nodeByName("btn_erase"):setScale(1)
	end
end

function var_0_0.updateColorItemNums(arg_33_0)
	arg_33_0.colorNums = {}

	for iter_33_0 = 1, 6 do
		arg_33_0.colorNums[iter_33_0] = arg_33_0.backpack:getItemNumByID(arg_33_0.colorItem[iter_33_0])

		arg_33_0:nodeByName("color_num" .. iter_33_0):setString("x" .. arg_33_0.colorNums[iter_33_0])
	end
end

function var_0_0.normalPaint(arg_34_0, arg_34_1, arg_34_2)
	if arg_34_0.doneMap and arg_34_0.doneMap[arg_34_1][arg_34_2] == 1 then
		return
	end

	if arg_34_0.map[arg_34_1][arg_34_2] ~= arg_34_0.colorMode then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("FOURTH_ANNI_PAINT_TIP1")
		})

		return
	end

	local var_34_0 = arg_34_0.backpack:getItemNumByID(arg_34_0.colorItem[arg_34_0.colorMode])

	if var_34_0 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("FOURTH_ANNI_PAINT_TIP3")
		})

		return
	end

	local var_34_1 = arg_34_0:findPaintBlocks(arg_34_1, arg_34_2, var_34_0)

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_BLOCKS, {
		block_ids = var_34_1
	}, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			local var_35_0 = arg_34_0.map[var_34_1[1].i][var_34_1[1].j]

			for iter_35_0 = 1, #var_34_1 do
				local var_35_1 = var_34_1[iter_35_0]
				local var_35_2 = arg_34_0:nodeByName("blocks"):getChildByName("block_" .. var_35_1.i .. "_" .. var_35_1.j)

				var_35_2:setVisible(true)
				var_35_2:setColor(arg_34_0.color[var_35_0])
			end

			arg_34_0.backpack:removeItem({
				itemID = arg_34_0.colorItem[var_35_0],
				itemNum = #var_34_1
			})
			arg_34_0:nodeByName("color_num" .. var_35_0):setString("x" .. arg_34_0.backpack:getItemNumByID(arg_34_0.colorItem[var_35_0]))

			arg_34_0.undoNum = arg_34_0.undoNum - #var_34_1

			arg_34_0:checkComplite()
		else
			arg_34_0:revertBlocks(var_34_1)
		end
	end)
end

function var_0_0.selfDraw(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_0:nodeByName("container"):getChildByName("blocks"):getChildByName("block_" .. arg_36_1 .. "_" .. arg_36_2)

	arg_36_0.map[arg_36_1][arg_36_2] = arg_36_0.colorMode

	if arg_36_0.colorMode == 0 then
		var_36_0:setVisible(false)
	else
		var_36_0:setColor(arg_36_0.color[arg_36_0.colorMode])
		var_36_0:setVisible(true)
	end
end

function var_0_0.findPaintBlocks(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	local var_37_0 = {}

	table.insert(var_37_0, {
		i = arg_37_1,
		j = arg_37_2
	})

	arg_37_0.doneMap[arg_37_1][arg_37_2] = 1

	local var_37_1 = 1

	while var_37_1 <= #var_37_0 and arg_37_3 > #var_37_0 do
		local var_37_2 = var_37_0[var_37_1].i
		local var_37_3 = var_37_0[var_37_1].j

		for iter_37_0 = -1, 1 do
			for iter_37_1 = -1, 1 do
				if arg_37_0.doneMap[var_37_2 + iter_37_0] and arg_37_0.doneMap[var_37_2 + iter_37_0][var_37_3 + iter_37_1] and arg_37_0.doneMap[var_37_2 + iter_37_0][var_37_3 + iter_37_1] == 0 and arg_37_0.map[var_37_2 + iter_37_0][var_37_3 + iter_37_1] == arg_37_0.colorMode then
					table.insert(var_37_0, {
						i = var_37_2 + iter_37_0,
						j = var_37_3 + iter_37_1
					})

					arg_37_0.doneMap[var_37_2 + iter_37_0][var_37_3 + iter_37_1] = 1

					if #var_37_0 == arg_37_3 then
						break
					end
				end
			end

			if #var_37_0 == arg_37_3 then
				break
			end
		end

		var_37_1 = var_37_1 + 1
	end

	return var_37_0
end

function var_0_0.revertBlocks(arg_38_0, arg_38_1)
	for iter_38_0 = 1, #arg_38_1 do
		local var_38_0 = arg_38_1[iter_38_0]

		arg_38_0.doneMap[var_38_0.i][var_38_0.j] = 0
	end
end

function var_0_0.checkComplite(arg_39_0)
	if arg_39_0.undoNum == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("FOURTH_ANNI_PAINT_TIP2")
		})
		arg_39_0:nodeByName("blocks"):removeAllChildren()
		arg_39_0:nodeByName("container"):getChildByName("bg" .. arg_39_0.stage):removeSelf()

		arg_39_0.stage = arg_39_0.stage + 1

		for iter_39_0 = 1, 48 do
			if arg_39_0.stage == 7 then
				arg_39_0.painted[iter_39_0] = ""
			else
				arg_39_0.painted[iter_39_0] = 0
			end
		end

		arg_39_0:initDatas()
		arg_39_0:initBlocks()
		arg_39_0:changeDraw()
	end
end

function var_0_0.clearDraw(arg_40_0)
	for iter_40_0 = 1, 48 do
		for iter_40_1 = 1, 30 do
			arg_40_0.map[iter_40_0][iter_40_1] = 0

			arg_40_0:nodeByName("container"):getChildByName("blocks"):getChildByName("block_" .. iter_40_0 .. "_" .. iter_40_1):setVisible(false)
		end
	end
end

return var_0_0
