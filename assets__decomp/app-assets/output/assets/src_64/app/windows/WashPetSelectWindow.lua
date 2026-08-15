local var_0_0 = class("WashPetSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5
local var_0_3 = 1
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.pets_ = clone(arg_1_0.player_.collectedPets)

	table.sort(arg_1_0.pets_, function(arg_2_0, arg_2_1)
		local var_2_0 = arg_2_0.tableID_ < arg_2_1.tableID_ and 1 or 0
		local var_2_1 = arg_2_0.tableID_ > arg_2_1.tableID_ and 1 or 0
		local var_2_2 = arg_2_0.color_ > arg_2_1.color_ and 2 or 0
		local var_2_3 = arg_2_0.color_ < arg_2_1.color_ and 2 or 0
		local var_2_4 = arg_2_0.star_ > arg_2_1.star_ and 4 or 0
		local var_2_5 = arg_2_0.star_ < arg_2_1.star_ and 4 or 0
		local var_2_6 = arg_2_0.level_ > arg_2_1.level_ and 8 or 0
		local var_2_7 = arg_2_0.level_ < arg_2_1.level_ and 8 or 0
		local var_2_8 = 0
		local var_2_9 = 0

		if arg_2_0:isAwaken() and arg_2_1:isAwaken() then
			var_2_8 = arg_1_0:getPracticeNum(arg_2_0) > arg_1_0:getPracticeNum(arg_2_1) and 16 or 0
			var_2_9 = arg_1_0:getPracticeNum(arg_2_0) < arg_1_0:getPracticeNum(arg_2_1) and 16 or 0
		end

		local var_2_10 = arg_2_0:isAwaken() and 32 or 0
		local var_2_11 = arg_2_1:isAwaken() and 32 or 0
		local var_2_12 = arg_2_0:canSummon() and 64 or 0
		local var_2_13 = arg_2_1:canSummon() and 64 or 0

		return var_2_0 + var_2_2 + var_2_4 + var_2_6 + var_2_8 + var_2_10 + var_2_12 > var_2_1 + var_2_3 + var_2_5 + var_2_7 + var_2_9 + var_2_11 + var_2_13
	end)
end

function var_0_0.getPracticeNum(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1:getPractice()
	local var_3_1 = 0

	return tonumber(var_3_0[1]) >= xyd.WaskAttrUpLimit and tonumber(var_3_0[2]) >= xyd.WaskAttrUpLimit and tonumber(var_3_0[3]) >= xyd.WaskAttrUpLimit and -10000 or var_3_0[1] + var_3_0[2] + var_3_0[3]
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.layout(arg_5_0)
	arg_5_0.container = arg_5_0:nodeByName("container")

	local var_5_0 = arg_5_0.container:getChildByName("list")

	arg_5_0.petListWidth = var_5_0:getContentSize().width
	arg_5_0.petListHeight = var_5_0:getContentSize().height
	arg_5_0.petList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0.petListWidth, arg_5_0.petListHeight),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.container:getChildByName("title_txt"):setString(var_0_1:translation("WASH_PET_SELECT_TITLE"))
	arg_5_0.container:getChildByName("title_txt_0"):setString(var_0_1:translation("CLOUD_CITY_GUIDE_2"))
	arg_5_0.petList_:setDelegate(handler(arg_5_0, arg_5_0.petDelegate))
end

function var_0_0.sortTables(arg_6_0, arg_6_1)
	for iter_6_0 = 1, #arg_6_1 do
		table.sort(arg_6_1[iter_6_0], function(arg_7_0, arg_7_1)
			if (arg_7_0.can_rent or arg_7_1.can_rent) and (not arg_7_0.can_rent or not arg_7_1.can_rent) then
				return arg_7_0.can_rent and not arg_7_1.can_rent
			end

			return xyd.petNormalSort(arg_7_0, arg_7_1) or false
		end)
	end
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 0.5 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

function var_0_0.petDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return (math.ceil(#arg_9_0.pets_ / var_0_2))
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.petList_:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.petList_:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = 710
		local var_9_2 = 130

		var_9_0:setItemSize(var_9_1, 130)

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(var_9_1, 130)

		for iter_9_0 = 1, var_0_2 do
			local var_9_4 = (arg_9_3 - 1) * var_0_2 + iter_9_0

			if var_9_4 > #arg_9_0.pets_ then
				break
			end

			local var_9_5 = display.newNode()

			var_9_5:setContentSize(108, 108)
			var_9_5:setPosition(142 * iter_9_0 - 142 + 65 + 30, 64)
			var_9_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_9_3:addChild(var_9_5)
			var_9_5:setTouchEnabled(true)
			var_9_5:setTouchSwallowEnabled(false)

			local var_9_6 = arg_9_0.pets_[var_9_4]

			xyd.setPetAvatarNewUI(var_9_5, var_9_6, 0)

			local var_9_7 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")

			var_9_7:setScale(0.8)

			if var_9_6:isAwaken() == false then
				xyd.GrayNode(var_9_5)
			else
				local var_9_8 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")
				local var_9_9 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")
				local var_9_10 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/white.png")

				var_9_8:setPosition(42, 0)
				var_9_5:addChild(var_9_8)
				var_9_9:setPosition(57, 0)
				var_9_5:addChild(var_9_9)
				var_9_10:setPosition(72, 0)
				var_9_5:addChild(var_9_10)

				local var_9_11 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")
				local var_9_12 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")
				local var_9_13 = xyd.AssetLoader.get():loadSprite("windows/wasg_select_hero/green.png")

				var_9_11:setPosition(42, 0)
				var_9_5:addChild(var_9_11)
				var_9_12:setPosition(57, 0)
				var_9_5:addChild(var_9_12)
				var_9_13:setPosition(72, 0)
				var_9_5:addChild(var_9_13)

				local var_9_14 = var_9_6:getPractice()
				local var_9_15 = var_0_4:getPracticeNeeds(var_9_6:getTableID())

				if tonumber(var_9_14[1]) < var_9_15[1] then
					var_9_8:setVisible(true)
					var_9_11:setVisible(false)
				end

				if tonumber(var_9_14[2]) < var_9_15[2] then
					var_9_9:setVisible(true)
					var_9_12:setVisible(false)
				end

				if tonumber(var_9_14[3]) < var_9_15[3] then
					var_9_10:setVisible(true)
					var_9_13:setVisible(false)
				end
			end

			local var_9_16 = var_9_7:getWidth()
			local var_9_17 = var_9_5:getWidth()
			local var_9_18 = var_9_5:getHeight()

			var_9_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_9_7:addTo(var_9_5)
			var_9_7:setPosition(var_9_16 / 2 + 5, var_9_18 / 3)

			local var_9_19 = {
				size = 16,
				color = cc.c3b(255, 255, 255)
			}
			local var_9_20 = xyd.AssetLoader.get():loadLabel(var_9_19)

			var_9_20:setString(var_9_6:getLevel())
			var_9_20:addTo(var_9_5)
			var_9_20:setAnchorPoint(cc.p(0.5, 0.5))
			var_9_20:setPosition(var_9_7:getPositionX() + 4, var_9_7:getPositionY() - 0.5)
			var_9_20:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
			var_9_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
				if arg_10_0.name == "began" then
					var_9_5:setScale(0.9)

					return true
				elseif arg_10_0.name == "ended" then
					var_9_5:setScale(1)

					if not arg_9_0.scrollViewMoved_ then
						if var_9_6:isAwaken() == true then
							local var_10_0 = xyd.WindowManager.get():getWindow("wash_hero")

							if var_10_0 then
								local var_10_1 = arg_9_0.player_:getPetByID(var_9_6:getPetID())

								var_10_0:setHero(var_10_1, false, true)
							end

							xyd.WindowManager.get():closeWindow("wash_select_pet")
						else
							local var_10_2 = var_0_1:translation("PET_NOT_AWAKEN")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_10_2
							})
						end
					end
				end
			end)
		end

		var_9_0:addContent(var_9_3)
		var_9_0:setItemSize(720, 150)

		return var_9_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.didOpen(arg_11_0)
	arg_11_0:addBlockLayer()
	arg_11_0.petList_:reload()
end

return var_0_0
