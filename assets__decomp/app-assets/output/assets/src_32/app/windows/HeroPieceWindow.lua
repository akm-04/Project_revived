local var_0_0 = class("HeroPieceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "hero_piece"
local var_0_2 = import("app.model.Scroll")
local var_0_3 = 98
local var_0_4 = 128

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:refresh()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("background"):setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))

	local var_4_0 = xyd.tables.translation

	arg_4_0:nodeByName("title"):setString(var_4_0:translation("HERO_PIECES"))

	arg_4_0.pieceListContainer_ = arg_4_0:nodeByName("piece_list_container")

	arg_4_0:initNoPieceLabel()
end

function var_0_0.initNoPieceLabel(arg_5_0)
	arg_5_0.pieceListContainer_:removeAllChildren()

	local var_5_0 = arg_5_0.pieceListContainer_:getContentSize().width
	local var_5_1 = arg_5_0.pieceListContainer_:getContentSize().height
	local var_5_2 = xyd.tables.translation
	local var_5_3 = xyd.AssetLoader.get():loadLabel({
		size = 24,
		text = var_5_2:translation("NO_HERO_PIECES")
	})

	var_5_3:enableShadow()
	var_5_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_3:setPosition(cc.p(var_5_0 / 2, var_5_1 / 2))
	arg_5_0.pieceListContainer_:addChild(var_5_3)
end

function var_0_0.initPieceList(arg_6_0)
	arg_6_0.pieceListContainer_:removeAllChildren()

	local var_6_0 = arg_6_0.pieceListContainer_:getContentSize().width
	local var_6_1 = arg_6_0.pieceListContainer_:getContentSize().height

	arg_6_0.pieceList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0, var_6_1),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):onTouch(handler(arg_6_0, arg_6_0.touchListener)):addTo(arg_6_0.pieceListContainer_)

	arg_6_0.pieceList_:setDelegate(handler(arg_6_0, arg_6_0.sourceDelegate))

	arg_6_0.pieceListColNum_ = math.floor(var_6_0 / var_0_3)
end

function var_0_0.initCellAtIdx(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_piece_cell.json")
	local var_7_1 = var_7_0:getChildByName("background")

	arg_7_1.heroIconContainer_ = var_7_1:getChildByName("hero_icon_container")

	arg_7_1.heroIconContainer_:removeAllChildren()

	arg_7_1.pieceNumLabel_ = var_7_1:getChildByName("Label_num")
	arg_7_1.pieceButtonContainer_ = var_7_1:getChildByName("piece_button_container")

	arg_7_1.pieceButtonContainer_:removeAllChildren()

	arg_7_1.pieceButton_ = xyd.AssetLoader.get():loadButton("#piece_button", cc.ui.UIPushButton, nil)

	xyd.displaySpriteOnContainer(arg_7_1.pieceButton_, arg_7_1.pieceButtonContainer_, true)
	arg_7_1.pieceButton_:setTouchSwallowEnabled(false)

	local var_7_2 = arg_7_1:getCascadeBoundingBox()

	var_7_0:setContentSize(var_7_2.width, var_7_2.height)
	arg_7_1:setContentSize(var_7_2.width, var_7_2.height)

	if arg_7_2 > #arg_7_0.pieces_ then
		return
	end

	var_7_0:setPosition(cc.p(0, 0))
	arg_7_1:addChild(var_7_0)

	local var_7_3 = arg_7_0.pieces_[arg_7_2]
	local var_7_4 = xyd.AssetLoader.get():loadSprite(var_7_3:getIcon())

	xyd.displaySpriteOnContainer(var_7_4, arg_7_1.heroIconContainer_, true)
	arg_7_1.pieceNumLabel_:setString(string.format("%d/%d", var_7_3:getScrollNum(), var_7_3:getHeroPiece()))
	arg_7_1.pieceButton_:onButtonClicked(function(arg_8_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow("hero_info", {
			partner_table_id = var_7_3:getHeroID()
		})
	end)
end

function var_0_0.sourceDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = math.ceil(#arg_9_0.pieces_ / arg_9_0.pieceListColNum_)

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_1 = arg_9_0.pieceList_:dequeueItem()
		local var_9_2

		if not var_9_1 then
			var_9_1 = arg_9_0.pieceList_:newItem()
		else
			var_9_1:removeAllChildren()
		end

		local var_9_3 = display.newNode()

		for iter_9_0 = 1, arg_9_0.pieceListColNum_ do
			local var_9_4 = (arg_9_3 - 1) * arg_9_0.pieceListColNum_ + iter_9_0
			local var_9_5 = display.newNode()

			arg_9_0:initCellAtIdx(var_9_5, var_9_4)
			var_9_5:setAnchorPoint(cc.p(0, 0))
			var_9_5:setPosition(cc.p(var_0_3 * (iter_9_0 - 1), 0))
			var_9_3:addChild(var_9_5)
		end

		var_9_1:addContent(var_9_3)

		local var_9_6 = var_9_1:getCascadeBoundingBox()

		var_9_1:setItemSize(var_9_6.width, var_9_6.height)
		var_9_3:setContentSize(var_9_6.width, var_9_6.height)

		return var_9_1
	end
end

function var_0_0.touchListener(arg_10_0, arg_10_1)
	return
end

function var_0_0.refresh(arg_11_0)
	arg_11_0.pieces_ = {}

	arg_11_0:loadHeroPieces()
end

function var_0_0.loadHeroPieces(arg_12_0)
	local var_12_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_12_0:loadHeroPieces(xyd.backendCallbackWrapper(var_0_1, function(arg_13_0)
		if arg_13_0 == xyd.error.OK then
			if var_12_0:getHeroPieceNum() > 0 then
				for iter_13_0, iter_13_1 in pairs(var_12_0.heroPieces_) do
					local var_13_0 = tonumber(iter_13_0)
					local var_13_1 = iter_13_1

					table.insert(arg_12_0.pieces_, var_0_2.new({
						scroll_id = xyd.ScrollID.HERO_PIECE,
						hero_id = var_13_0,
						num = var_13_1
					}))
				end

				arg_12_0:initPieceList()
				arg_12_0.pieceList_:reload()
			else
				arg_12_0:initNoPieceLabel()
			end
		end
	end))
end

return var_0_0
