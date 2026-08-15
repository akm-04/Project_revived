local var_0_0 = class("StickBlessRankWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.stickBless = xyd.ModelManager.get():loadModel(xyd.ModelType.STICK_BLESS)
	arg_1_0.rank_list = arg_1_2.rank_list
	arg_1_0.my_rank = arg_1_2.my_rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	xyd.imgEvent(arg_4_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)

	local var_4_0 = arg_4_0:nodeByName("container")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:initListBoard()
end

function var_0_0.initListBoard(arg_6_0)
	arg_6_0:nodeByName("rank_num"):setString(arg_6_0.my_rank.rank + 1)
	arg_6_0:nodeByName("score_num"):setString(arg_6_0.my_rank.point)

	for iter_6_0 = 1, #arg_6_0.rank_list do
		local var_6_0 = arg_6_0.list:newItem()
		local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/stick_bless_word/ranklist/rank_item.csb")
		local var_6_2 = var_6_1:getChildByName("container")
		local var_6_3 = var_6_2:getContentSize()

		var_6_2:getChildByName("txt_score_num"):setString(arg_6_0.rank_list[iter_6_0].point)

		local var_6_4 = var_6_2:getChildByName("rank_num")
		local var_6_5 = var_6_2:getChildByName("txt_rank_num")

		var_6_5:setVisible(false)
		var_6_4:setVisible(false)

		if iter_6_0 <= 3 then
			local var_6_6 = cc.Director:getInstance():getTextureCache():addImage("windows/stick_bless_word/ranklist/" .. iter_6_0 .. ".png")

			var_6_4:setVisible(true)
			var_6_4:setTexture(var_6_6)
		else
			var_6_5:setVisible(true)
			var_6_5:setString(iter_6_0)
		end

		var_6_2:getChildByName("txt_score_num"):setString(arg_6_0.rank_list[iter_6_0].point)

		if arg_6_0.rank_list[iter_6_0].player_id.conquer_lev and arg_6_0.rank_list[iter_6_0].player_id.conquer_lev > 0 then
			xyd.setConquerLev(arg_6_0.rank_list[iter_6_0].player_id.conquer_lev, var_6_2:getChildByName("txt_level"), var_6_2:getChildByName("level_circle"), nil, nil, nil, nil, arg_6_0.rank_list[iter_6_0].player_id.conquer_loop_id)
		else
			local var_6_7 = xyd.AssetLoader.get():loadSprite("images/level_bg.png")

			var_6_7:addTo(var_6_2)

			local var_6_8 = cc.p(var_6_2:getChildByName("level_circle"):getPosition())

			var_6_8.x = var_6_8.x + 2
			var_6_8.y = var_6_8.y - 2

			var_6_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_7:setPosition(cc.p(var_6_8))
			var_6_2:getChildByName("level_circle"):setVisible(false)
			var_6_7:setLocalZOrder(9)
			var_6_2:getChildByName("txt_level"):setString(arg_6_0.rank_list[iter_6_0].player_id.lev)
			var_6_2:getChildByName("txt_level"):setLocalZOrder(10)
		end

		local var_6_9 = {
			avatar_id = arg_6_0.rank_list[iter_6_0].player_id.avatar_id,
			avatar_frame_id = arg_6_0.rank_list[iter_6_0].player_id.avatar_frame_id
		}

		xyd.setPlayerAvatar(var_6_2:getChildByName("player_head"), var_6_9)
		var_6_2:getChildByName("txt_name"):setString(arg_6_0.rank_list[iter_6_0].player_id.player_name)
		var_6_2:getChildByName("txt_server"):setString("S" .. math.floor(arg_6_0.rank_list[iter_6_0].player_id.player_id / 100000))
		var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_1:setPosition(0, 0)
		var_6_0:addContent(var_6_1)
		var_6_0:setItemSize(var_6_3.width, var_6_3.height)
		arg_6_0.list:addItem(var_6_0)
	end

	arg_6_0.list:reload()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
