local var_0_0 = class("DreamWorldCollectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.dreamWorldDiaryTable
local var_0_3 = xyd.tables.item
local var_0_4 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.items_ = xyd.tables.misc:getValue("dreamworld_collection_item_id")
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.listViewCollect_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listViewCollect_:setBounceable(true)
	arg_2_0.listViewCollect_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("info_container"):setVisible(false)

	local var_3_0 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.items_) do
		if arg_3_0.backpack:getItemNumByID(iter_3_1) > 0 then
			var_3_0 = var_3_0 + 1

			if var_3_0 == 1 then
				arg_3_0:showItem(iter_3_1)
			end
		end
	end

	arg_3_0:nodeByName("text_percent"):setString(var_0_1:translation("DREAM_WORLD_TEXT_17"))
	arg_3_0:nodeByName("percent"):setString(math.floor(var_3_0 / #arg_3_0.items_ * 100) .. "%")
	arg_3_0:nodeByName("progress"):setPercent(var_3_0 / #arg_3_0.items_ * 100)
	arg_3_0:nodeByName("text_have_1"):setString(var_0_1:translation("ITEM_OWN"))
	arg_3_0:nodeByName("text_have_2"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_3_0.listViewCollect_:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = math.ceil(#arg_4_0.items_ / var_0_4)

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_4_0
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if var_4_0 < arg_4_3 then
			return nil
		end

		local var_4_1 = arg_4_0.listViewCollect_:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.listViewCollect_:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = display.newNode()

		arg_4_0:initCell(var_4_2, arg_4_3)

		local var_4_3 = display.newNode()

		var_4_3:addChild(var_4_2)
		var_4_3:setContentSize(var_4_2:getContentSize())
		var_4_1:setItemSize(var_4_2:getContentSize().width, var_4_2:getContentSize().height)
		var_4_1:addContent(var_4_3)

		return var_4_1
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0

	for iter_5_0 = 1, var_0_4 do
		local var_5_1 = (arg_5_2 - 1) * var_0_4 + iter_5_0

		if var_5_1 > #arg_5_0.items_ then
			break
		end

		local var_5_2 = arg_5_0.items_[var_5_1]
		local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/dream_world/explore/collect_item.csb")
		local var_5_4 = var_5_3:getChildByName("container")

		var_5_0 = var_5_4:getContentSize()

		var_5_4:getChildByName("name"):setString(var_0_3:name(var_5_2))

		local var_5_5 = "windows/dream_world/explore/" .. var_5_2 .. ".png"

		xyd.AssetLoader:get():loadSprite(var_5_5):addTo(var_5_4:getChildByName("node"))

		if arg_5_0.backpack:getItemNumByID(var_5_2) > 0 then
			var_5_4:getChildByName("shadow"):setVisible(false)
			var_5_4:getChildByName("text_lock"):setVisible(false)
			var_5_3:setTouchEnabled(true)
			var_5_3:setTouchSwallowEnabled(false)
			var_5_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					var_5_4:setScale(0.9)

					arg_5_0.click = true
					arg_5_0.touchBeganX = arg_6_0.x
					arg_5_0.touchBeganY = arg_6_0.y

					return true
				elseif arg_6_0.name == "moved" then
					if math.abs(arg_5_0.touchBeganX - arg_6_0.x) + math.abs(arg_5_0.touchBeganY - arg_6_0.y) < 20 then
						return true
					else
						arg_5_0.click = false

						var_5_4:setScale(1)
					end
				elseif arg_6_0.name == "ended" and arg_5_0.click then
					xyd.playButtonSound()
					var_5_4:setScale(1)
					arg_5_0:showItem(var_5_2)

					return true
				end
			end)
		else
			var_5_4:getChildByName("shadow"):setVisible(true)
			var_5_4:getChildByName("text_lock"):setVisible(true)
			var_5_4:getChildByName("text_lock"):setString(var_0_1:translation("UNLOCK"))
		end

		var_5_3:addTo(arg_5_1)
		var_5_3:setPosition((iter_5_0 - 1) * 256, 0)
	end

	arg_5_1:setContentSize(arg_5_0:nodeByName("list"):getWidth(), var_5_0.height + 10)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.startClick_ = true
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.startClick_ = false
	end
end

function var_0_0.showItem(arg_8_0, arg_8_1)
	arg_8_0:nodeByName("info_container"):setVisible(true)
	xyd.setItemBorder(arg_8_0:nodeByName("pic"), arg_8_1)
	arg_8_0:nodeByName("text_name"):setString(var_0_3:name(arg_8_1))
	arg_8_0:nodeByName("text_item"):setString(var_0_3:desc1(arg_8_1))
	arg_8_0:nodeByName("num"):setVisible(false)
	arg_8_0:nodeByName("text_have_1"):setVisible(false)
	arg_8_0:nodeByName("text_have_2"):setVisible(false)
end

function var_0_0.hide(arg_9_0)
	arg_9_0:setVisible(false)
end

function var_0_0.show(arg_10_0)
	arg_10_0:setVisible(true)
	arg_10_0:layout()
end

return var_0_0
