local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("avatar_container")

	var_3_0:getChildByName("avatars_words"):setString(var_0_1:translation("SX_CLICK_AVATAR_DESC"))

	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0:getChildByName("avatars_list"):getWidth(), var_3_0:getChildByName("avatars_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_3_0:getChildByName("avatars_list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView_:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	data = xyd.tables.misc.enHeroExchange

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > #data then
			return nil
		end

		local var_4_0 = arg_4_0.listView_:dequeueItem()

		if not var_4_0 then
			var_4_0 = arg_4_0.listView_:newItem()
		else
			var_4_0:removeAllChildren(true)
		end

		local var_4_1 = data[arg_4_3]
		local var_4_2 = display.newNode()

		arg_4_0:initCell(var_4_2, var_4_1)

		local var_4_3 = display.newNode()

		var_4_3:addChild(var_4_2)
		var_4_2:setPosition(0, 0)
		var_4_3:setContentSize(120, 150)
		var_4_0:setItemSize(120, 150)
		var_4_0:addContent(var_4_3)

		return var_4_0
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1087/avatar_item.csb")
	local var_5_1 = var_5_0:getChildByName("container")
	local var_5_2 = var_5_1:getChildByName("avatar")
	local var_5_3 = var_5_1:getContentSize()
	local var_5_4 = xyd.tables.hero:name(arg_5_2)

	var_5_1:getChildByName("name_text"):setString(var_5_4)
	var_5_1:getChildByName("book_words"):setString(var_0_1:translation("STONE"))
	var_5_0:setContentSize(var_5_3)
	arg_5_1:setContentSize(var_5_3)
	var_5_0:setName("layout")
	var_5_0:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_0)
	arg_5_1:setTouchSwallowEnabled(false)
	xyd.setAvatarBorder(arg_5_2, var_5_2, 1, 0)
	var_5_2:getChildByName("stone_mini"):setLocalZOrder(10)

	local var_5_5 = display.newNode()

	var_5_5:setContentSize(var_5_2:getWidth(), var_5_2:getHeight())
	var_5_5:setTouchEnabled(true)
	var_5_5:setTouchSwallowEnabled(false)
	var_5_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_5:setPosition(var_5_2:getPosition())
	var_5_1:addChild(var_5_5)
	var_5_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			var_5_2:setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			if arg_5_0.startClick_ == false then
				var_5_2:setScale(1)
			end

			return true
		elseif arg_6_0.name == "ended" then
			var_5_2:setScale(1)

			if arg_5_0.startClick_ == true then
				xyd.playButtonSound()

				if arg_5_0.activity.is_open == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_CLOSED")
					})

					return
				end

				local var_6_0 = false

				for iter_6_0, iter_6_1 in pairs(xyd.tables.misc.enHeroExchange) do
					if arg_5_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.hero:stoneID(iter_6_1)) >= xyd.tables.misc.enHeroExchangeRate and arg_5_0.selfPlayer:getHeroIgnoreAwaken(iter_6_1) and arg_5_0.selfPlayer:getHeroIgnoreAwaken(iter_6_1):getStar() >= 5 then
						var_6_0 = true

						break
					end
				end

				if var_6_0 then
					xyd.WindowManager.get():openWindow("activity_exchange_hero", {
						heroId = arg_5_2,
						tableId = arg_5_0.activity.table_id
					})
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("NO_EXCHANGE_HERO_STONE")
					})
				end
			end

			return true
		end
	end)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.startClick_ = true
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.startClick_ = false
	end
end

return var_0_0
