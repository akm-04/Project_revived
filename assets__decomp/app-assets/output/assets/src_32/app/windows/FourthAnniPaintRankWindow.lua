local var_0_0 = class("FourthAnniPaintRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_2.rank_list
	arg_1_0.selfRank = arg_1_2.self_rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:pos(-640, -360)
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("vote_num"):setString(arg_3_0.selfRank.vote_num or 0)
	arg_3_0:nodeByName("myrank_text"):setString(var_0_1:translation("MYRANK_TEXT"))
	arg_3_0:nodeByName("vote_txt"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT1"))
	arg_3_0:nodeByName("message"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT24"))

	if arg_3_0.selfRank.rank and arg_3_0.selfRank.rank > 0 then
		arg_3_0:nodeByName("rank_txt"):setString(arg_3_0.selfRank.rank)
	else
		arg_3_0:nodeByName("rank_txt"):setString(var_0_1:translation("NO_RANK_TEXT"))
	end

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(true)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
	arg_3_0:nodeByName("bg_hero"):setVisible(#(arg_3_0.rankInfo or {}) == 0)
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #(arg_4_0.rankInfo or {})
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.rankInfo[arg_5_1]
	local var_5_1 = display.newNode()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/painting/rank_item.csb")
	local var_5_3 = var_5_2:getChildByName("container")
	local var_5_4 = var_5_0.player_info

	xyd.setPlayerAvatar(var_5_3:getChildByName("icon_container"), var_5_4)

	if var_5_4.conquer_lev and var_5_4.conquer_lev > 0 then
		var_5_3:getChildByName("lev_txt"):setString(var_5_4.conquer_lev)
		var_5_3:getChildByName("lv_bg"):setVisible(false)

		local var_5_5 = xyd.getLoopBy(var_5_4.conquer_lev, var_5_4.conquer_loop_id)

		if var_5_5 < 2 then
			var_5_5 = ""
		end

		var_5_3:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_5_5 .. ".png")
	else
		var_5_3:getChildByName("lev_txt"):setString(var_5_4.lev)
		var_5_3:getChildByName("conquer_lev_bg"):setVisible(false)
	end

	var_5_3:getChildByName("name_txt"):setString(var_5_4.player_name)
	var_5_3:getChildByName("vote_num"):setString(var_5_0.vote_num)
	var_5_3:getChildByName("vote_text"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT2"))

	local var_5_6

	var_5_3:getChildByName("bg1"):setVisible(false)
	var_5_3:getChildByName("bg2"):setVisible(false)
	var_5_3:getChildByName("bg3"):setVisible(false)
	var_5_3:getChildByName("bg4"):setVisible(false)

	if arg_5_1 <= 3 then
		var_5_3:getChildByName("bg" .. arg_5_1):setVisible(true)

		var_5_6 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/rank" .. arg_5_1 .. ".png")
	else
		var_5_3:getChildByName("bg4"):setVisible(true)

		local var_5_7 = {
			size = 48,
			text = arg_5_1,
			color = cc.c3b(222, 243, 253)
		}

		var_5_6 = xyd.AssetLoader.get():loadLabel(var_5_7)

		var_5_6:setString(arg_5_1)
		var_5_6:enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end

	var_5_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_6:addTo(var_5_3:getChildByName("rank_pos"))
	var_5_3:getChildByName("btn_visit"):getChildByName("visit_txt"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT3"))
	xyd.nodeEventSample(var_5_3:getChildByName("btn_visit"), nil, function()
		if var_5_0.not_show == 1 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT14")
			})
		else
			xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_VISIT, {
				visited_player = var_5_0.player_id
			}, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					local var_7_0 = {
						map = arg_7_1.map,
						info = var_5_0
					}

					xyd.WindowManager.get():openWindow("fourth_anni_paint_visit", var_7_0)
					xyd.WindowManager.get():closeWindow(arg_5_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT14")
					})
				end
			end)
		end
	end)
	var_5_2:addTo(var_5_1)
	var_5_2:setAnchorPoint(cc.p(0, 0))
	var_5_1:setContentSize(var_5_3:getContentSize())

	return var_5_1
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 5 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
