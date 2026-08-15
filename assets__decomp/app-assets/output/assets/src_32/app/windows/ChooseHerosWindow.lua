local var_0_0 = class("ChooseHerosWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("socket")
local var_0_2 = xyd.tables.translation
local var_0_3 = 4
local var_0_4 = 30
local var_0_5 = 1
local var_0_6 = {
	SELF_PET = 2,
	SELF_HERO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.busyHeros = arg_1_2.busyHeros
	arg_1_0.sentHeros = arg_1_2.sentHeros
	arg_1_0.heros = clone(arg_1_0.selfPlayer.heros_)
	arg_1_0.pets = clone(arg_1_0.selfPlayer.collectedPets)
end

function var_0_0.filtCanSentHeros(arg_2_0)
	for iter_2_0 = 1, #arg_2_0.busyHeros do
		for iter_2_1, iter_2_2 in ipairs(arg_2_0.heros) do
			if iter_2_2:getHeroID() == arg_2_0.busyHeros[iter_2_0] then
				table.remove(arg_2_0.heros, iter_2_1)

				break
			end
		end
	end

	arg_2_0:sortHeros(arg_2_0.heros)
	arg_2_0:layout()
end

function var_0_0.filtCanRentPets(arg_3_0)
	arg_3_0.rentPets = arg_3_0.guild:getRentPets()

	for iter_3_0, iter_3_1 in pairs(arg_3_0.rentPets) do
		for iter_3_2 = #arg_3_0.pets, 1, -1 do
			if iter_3_1.pet_id == arg_3_0.pets[iter_3_2]:getPetID() then
				table.remove(arg_3_0.pets, iter_3_2)
			end
		end
	end

	for iter_3_3 = #arg_3_0.pets, 1, -1 do
		if arg_3_0.pets[iter_3_3]:isBorn() == 0 then
			table.remove(arg_3_0.pets, iter_3_3)
		end
	end
end

function var_0_0.sortHeros(arg_4_0, arg_4_1)
	table.sort(arg_4_1, function(arg_5_0, arg_5_1)
		return xyd.heroNormalSort(arg_5_0, arg_5_1) or false
	end)
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 10 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super:willOpen(arg_7_1)

	arg_7_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 606, 529),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_7_0:nodeByName("list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0:filtCanRentPets()
	arg_7_0:filtCanSentHeros()
end

function var_0_0.heroDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = math.ceil(#arg_8_0.heros / 4)

	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return var_8_0
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_1
		local var_8_2
		local var_8_3
		local var_8_4 = arg_8_0.list:dequeueItem()

		if not var_8_4 then
			var_8_4 = arg_8_0.list:newItem()
		else
			var_8_4:removeAllChildren()
		end

		local var_8_5 = display.newNode()

		var_8_5:setTouchSwallowEnabled(false)

		for iter_8_0 = 1, 4 do
			local var_8_6 = (arg_8_3 - 1) * 4 + iter_8_0

			if var_8_6 > #arg_8_0.heros then
				break
			end

			local var_8_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/hero_item.csb")

			var_8_7:setTouchSwallowEnabled(false)

			local var_8_8 = var_8_7:getChildByName("container")

			var_8_7:addTo(var_8_5)
			var_8_7:setPosition((iter_8_0 - 1) * (var_8_8:getWidth() + 36), 0)
			xyd.setAvatarBorderNewUI(arg_8_0.heros[var_8_6], var_8_8:getChildByName("hero"))
			var_8_8:getChildByName("lv_txt"):setString(arg_8_0.heros[var_8_6]:getLevel())
			var_8_8:getChildByName("name"):setString(arg_8_0.heros[var_8_6]:getName())
			var_8_7:setTouchEnabled(true)
			var_8_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					return true
				elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
					if xyd.tables.vip:employee(arg_8_0.selfPlayer.vip) <= #arg_8_0.sentHeros then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("SEND_HERO_TIP")
						})
					else
						if not xyd.isSuperHero(arg_8_0.heros[var_8_6]) or not xyd.color.SUPER_HERO then
							local var_9_0 = xyd.color.HERO_QUALITY[arg_8_0.heros[var_8_6]:getColor()]
						end

						local var_9_1 = "343434"
						local var_9_2 = var_0_2:translation("SHE_TUAN_TEXT_49") .. "#" .. var_9_1 .. "#" .. arg_8_0.heros[var_8_6]:getName() .. xyd.Color2Level[arg_8_0.heros[var_8_6]:getColor()] .. var_0_2:translation("SHE_TUAN_TEXT_50")
						local var_9_3 = xyd.createMultiColorTxt(var_9_2, xyd.color.BLACK, 24)

						var_9_3:retain()
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, nil, function()
							arg_8_0:rentHeroOK(arg_8_0.heros[var_8_6]:getHeroID())
						end, nil, 0, xyd.ColorMode.YELLOW, var_9_3)
					end
				end

				return true
			end)
		end

		var_8_5:setContentSize(606, 150)
		var_8_5:setAnchorPoint(cc.p(0, 0))
		var_8_5:setPosition(0, 0)
		var_8_4:addContent(var_8_5)
		var_8_4:setItemSize(606, 170)

		return var_8_4
	end
end

function var_0_0.petDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = math.ceil(#arg_11_0.pets / var_0_3)

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return var_11_0
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = arg_11_0.list:dequeueItem()

		if not var_11_4 then
			var_11_4 = arg_11_0.list:newItem()
		else
			var_11_4:removeAllChildren()
		end

		local var_11_5 = display.newNode()

		var_11_5:setTouchSwallowEnabled(false)

		for iter_11_0 = 1, var_0_3 do
			local var_11_6 = (arg_11_3 - 1) * var_0_3 + iter_11_0

			if var_11_6 > #arg_11_0.pets then
				break
			end

			var_11_3 = display.newNode()

			arg_11_0:initPetCell(var_11_3, var_11_6)

			local var_11_7 = var_11_3:getContentSize().width
			local var_11_8 = var_11_3:getContentSize().height
			local var_11_9 = (arg_11_0.list.viewRect_.width - var_11_7 * var_0_3) / (var_0_3 + 1)

			var_11_3:align(display.CENTER, var_11_9 * iter_11_0 + (iter_11_0 - 1) * var_11_7 + var_11_7 / 2, var_11_8 / 2)
			var_11_5:addChild(var_11_3)
		end

		var_11_5:setContentSize(cc.size(arg_11_0.list.viewRect_.width, var_11_3:getContentSize().height + var_0_4))
		var_11_4:setItemSize(arg_11_0.list.viewRect_.width, var_11_3:getContentSize().height + var_0_4)
		var_11_4:addContent(var_11_5)

		return var_11_4
	end
end

function var_0_0.initPetCell(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.pets[arg_12_2]

	arg_12_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatar(arg_12_1, var_12_0, 100)
	arg_12_1:setTouchEnabled(true)
	arg_12_1:setTouchSwallowEnabled(false)
	arg_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			arg_12_1:setScale(0.9)

			arg_12_0.startClick_ = true
			arg_12_0.prevX_ = arg_13_0.x
			arg_12_0.prevY_ = arg_13_0.y
		elseif arg_13_0.name == "moved" then
			arg_12_1:setScale(1)

			if math.abs(arg_13_0.y - arg_12_0.prevY_) > 5 or math.abs(arg_13_0.x - arg_12_0.prevX_) > 5 then
				arg_12_0.startClick_ = false
			end
		elseif arg_13_0.name == "ended" and arg_12_0.startClick_ then
			arg_12_1:setScale(1)

			if #arg_12_0.rentPets >= var_0_5 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("RENT_PET_MAX")
				})
			else
				local var_13_0 = xyd.color.HERO_QUALITY[var_12_0:getColor()]
				local var_13_1 = "343434"
				local var_13_2 = var_0_2:translation("SHE_TUAN_TEXT_49") .. "#" .. var_13_1 .. "#" .. var_12_0:getName() .. xyd.Color2Level[var_12_0:getColor()] .. var_0_2:translation("SHE_TUAN_TEXT_50")
				local var_13_3 = xyd.createMultiColorTxt(var_13_2, xyd.color.BLACK, 24)

				var_13_3:retain()
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_0_2:translation("TEAM_DISSOLUTION_ALERT")
				}, function(arg_14_0)
					arg_12_0:rentPetOK(var_12_0:getPetID())
				end, nil, 0, xyd.ColorMode.YELLOW, var_13_3)
			end
		end

		return true
	end)
end

function var_0_0.rentHeroOK(arg_15_0, arg_15_1)
	local var_15_0 = {
		partner_id = arg_15_1
	}

	arg_15_0.guild:rentHero(var_15_0, function(arg_16_0)
		if arg_16_0 == xyd.error.OK then
			local var_16_0 = xyd.WindowManager.get():getWindow("hire_hero")

			if var_16_0 and var_16_0.girlType == 1 then
				var_16_0.sentHeros = arg_15_0.guild:getSentHeros()

				var_16_0:updateSentList()
				xyd.WindowManager.get():closeWindow(arg_15_0.name)
			else
				xyd.WindowManager.get():closeWindow(arg_15_0.name)
			end
		end
	end)
end

function var_0_0.rentPetOK(arg_17_0, arg_17_1)
	local var_17_0 = {
		pet_id = arg_17_1
	}

	arg_17_0.guild:rentPet(var_17_0, function(arg_18_0)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = xyd.WindowManager.get():getWindow("hire_hero")

			if var_18_0 and var_18_0.girlType == 1 then
				var_18_0.rentPets = arg_17_0.guild:getRentPets()

				var_18_0:updateSentList()
				xyd.WindowManager.get():closeWindow(arg_17_0.name)
			else
				xyd.WindowManager.get():closeWindow(arg_17_0.name)
			end
		end
	end)
end

function var_0_0.layout(arg_19_0)
	arg_19_0:nodeByName("btn_hero"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			arg_19_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_19_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.normal)

			arg_19_0.leftMenuType = var_0_6.SELF_HERO

			arg_19_0.list:reload()
		end
	end)
	arg_19_0:nodeByName("btn_pet"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			arg_19_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_19_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.normal)

			arg_19_0.leftMenuType = var_0_6.SELF_PET

			arg_19_0.list:reload()
		end
	end)
	arg_19_0:nodeByName("btn_hero"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_19_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.normal)

	arg_19_0.leftMenuType = var_0_6.SELF_HERO

	arg_19_0.list:setDelegate(handler(arg_19_0, arg_19_0.delegate))
	arg_19_0.list:reload()
end

function var_0_0.delegate(arg_22_0, ...)
	if var_0_6.SELF_PET == arg_22_0.leftMenuType then
		return arg_22_0:petDelegate(...)
	end

	return arg_22_0:heroDelegate(...)
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	var_0_0.super:didOpen(arg_23_1)
	arg_23_0:addBlockLayer()
end

return var_0_0
