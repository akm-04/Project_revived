local var_0_0 = class("SelectHeroCardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = 4
local var_0_4 = 6
local var_0_5 = 30
local var_0_6 = {
	PET = 2,
	HERO = 1
}
local var_0_7 = {
	btn_hero = var_0_1:translation("PERSON_SELECT_HERO"),
	btn_pet = var_0_1:translation("PERSON_SELECT_PET"),
	btn_all = var_0_1:translation("PERSON_SELECT_ALL"),
	btn_qianpai = var_0_1:translation("HERO_QIANPAI"),
	btn_zhongpai = var_0_1:translation("HERO_ZHONGPAI"),
	btn_houpai = var_0_1:translation("HERO_HOUPAI")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.personDisplay = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.index = arg_1_2.index
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalPet_ = {}
	arg_1_0.heroCells_ = {}
	arg_1_0.selectHeros = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_1:translation("SELECT_SHOW_HERO"))
	arg_2_0:nodeByName("txt_all"):setString(var_0_7.btn_all)
	arg_2_0:nodeByName("txt_qianpai"):setString(var_0_7.btn_qianpai)
	arg_2_0:nodeByName("txt_zhongpai"):setString(var_0_7.btn_zhongpai)
	arg_2_0:nodeByName("txt_houpai"):setString(var_0_7.btn_houpai)
	arg_2_0:nodeByName("txt_hero"):setString(var_0_7.btn_hero)
	arg_2_0:nodeByName("txt_pet"):setString(var_0_7.btn_pet)

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_2_0)

	arg_2_0.heroList_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:initPreSelect()
	arg_2_0:initHeros(arg_2_0.selfPlayer.heros_)
	arg_2_0:initPets(arg_2_0.selfPlayer.collectedPets)
	arg_2_0:initLeftMenu()
	arg_2_0:initRightMenu()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
	arg_3_0:refreshSelectedHeroClass()
end

function var_0_0.initRightMenu(arg_4_0)
	arg_4_0.rightMenuButtons_ = {}

	table.insert(arg_4_0.rightMenuButtons_, arg_4_0:nodeByName("btn_all"))
	table.insert(arg_4_0.rightMenuButtons_, arg_4_0:nodeByName("btn_qianpai"))
	table.insert(arg_4_0.rightMenuButtons_, arg_4_0:nodeByName("btn_zhongpai"))
	table.insert(arg_4_0.rightMenuButtons_, arg_4_0:nodeByName("btn_houpai"))

	for iter_4_0 = 1, #arg_4_0.rightMenuButtons_ do
		arg_4_0.rightMenuButtons_[iter_4_0]:setZoomScale(0.3)
		arg_4_0.rightMenuButtons_[iter_4_0]:addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_4_0.selectedHeroClass_ == iter_4_0 then
					for iter_5_0 = 1, #arg_4_0.rightMenuButtons_ do
						if iter_5_0 == arg_4_0.selectedHeroClass_ then
							arg_4_0.rightMenuButtons_[iter_5_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_4_0.rightMenuButtons_[iter_5_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_4_0.selectedHeroClass_ = iter_4_0

				arg_4_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initLeftMenu(arg_6_0)
	arg_6_0:nodeByName("btn_hero"):hide()

	arg_6_0:nodeByName("btn_hero").menu_type = var_0_6.HERO

	arg_6_0:nodeByName("btn_pet"):hide()

	arg_6_0:nodeByName("btn_pet").menu_type = var_0_6.PET
	arg_6_0.leftMenuType_ = var_0_6.HERO
	arg_6_0.leftMenuButtons_, arg_6_0.leftMenuText_ = {}, {}

	table.insert(arg_6_0.leftMenuButtons_, arg_6_0:nodeByName("btn_hero"))

	if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		table.insert(arg_6_0.leftMenuButtons_, arg_6_0:nodeByName("btn_pet"))
	end

	if #arg_6_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_6_0 = 1, #arg_6_0.leftMenuButtons_ do
		arg_6_0.leftMenuButtons_[iter_6_0]:show()
		arg_6_0.leftMenuButtons_[iter_6_0]:setZoomScale(0.3)
		arg_6_0.leftMenuButtons_[iter_6_0]:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_7_0, iter_7_1 in ipairs(arg_6_0.leftMenuButtons_) do
					iter_7_1:setBrightStyle(arg_7_0 == iter_7_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_6_0.leftMenuType_ = arg_7_0.menu_type

				arg_6_0:refreshSelectedHeroClass()

				if iter_6_0 == 1 then
					arg_6_0:nodeByName("txt_title"):setString(var_0_1:translation("SELECT_SHOW_HERO"))
				else
					arg_6_0:nodeByName("txt_title"):setString(var_0_1:translation("SELECT_SHOW_PET"))
				end
			end
		end)
	end

	arg_6_0.leftMenuButtons_[1]:setBrightStyle(ccui.BrightStyle.highlight)
end

function var_0_0.refreshSelectedHeroClass(arg_8_0)
	for iter_8_0 = 1, #arg_8_0.rightMenuButtons_ do
		if iter_8_0 == arg_8_0.selectedHeroClass_ then
			arg_8_0.rightMenuButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_8_0.rightMenuButtons_[iter_8_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_8_0.heroList_:removeAllItems()
	arg_8_0.heroList_:reload()
end

function var_0_0.getSelectIds(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0 = 1, var_0_4 do
		local var_9_1 = 0
		local var_9_2 = arg_9_0.selectHeros[iter_9_0]

		if var_9_2 and next(var_9_2) then
			if var_9_2:getTableID() == arg_9_1:getTableID() then
				var_9_1 = 0
			elseif arg_9_0.index == iter_9_0 then
				if arg_9_1.isPet_ then
					var_9_1 = -arg_9_1:getPetID()
				else
					var_9_1 = arg_9_1:getHeroID()
				end
			elseif var_9_2.isPet_ then
				var_9_1 = -var_9_2:getPetID()
			else
				var_9_1 = var_9_2:getHeroID()
			end
		elseif arg_9_0.index == iter_9_0 then
			if arg_9_1.isPet_ then
				var_9_1 = -arg_9_1:getPetID()
			else
				var_9_1 = arg_9_1:getHeroID()
			end
		end

		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

function var_0_0.initPreSelect(arg_10_0)
	local var_10_0 = arg_10_0.personDisplay:getShowCase()

	for iter_10_0 = 1, var_0_4 do
		local var_10_1 = var_10_0[iter_10_0]

		if var_10_1 and next(var_10_1) then
			local var_10_2

			if var_10_1.partner_id then
				var_10_2 = arg_10_0.selfPlayer:getHeroByID(var_10_1.partner_id)
			elseif var_10_1.pet_id then
				var_10_2 = arg_10_0.selfPlayer:getPetByID(var_10_1.pet_id)
			end

			if var_10_2 then
				arg_10_0:addToSelectHero(var_10_2)
			end

			if var_10_2 and arg_10_0.index == iter_10_0 then
				arg_10_0.currentHero = var_10_2
			end
		else
			arg_10_0:addToSelectHero({})
		end
	end
end

function var_0_0.initHeros(arg_11_0, arg_11_1)
	for iter_11_0, iter_11_1 in pairs(arg_11_1) do
		if not arg_11_0:checkHeroIsSelect(iter_11_1) then
			if iter_11_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_11_0.totalHero_[xyd.DistanceType.QIANPAI], iter_11_1)
			elseif iter_11_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_11_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_11_1)
			elseif iter_11_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_11_0.totalHero_[xyd.DistanceType.HOUPAI], iter_11_1)
			end

			table.insert(arg_11_0.totalHero_[xyd.DistanceType.ALL], iter_11_1)
		end
	end

	arg_11_0:sortTables(arg_11_0.totalHero_)

	arg_11_0.selectedHeroClass_ = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_12_0, arg_12_1)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		if iter_12_1.is_show_ == 1 and not arg_12_0:checkHeroIsSelect(iter_12_1) then
			table.insert(var_12_0, iter_12_1)
		end
	end

	table.sort(var_12_0, function(arg_13_0, arg_13_1)
		local var_13_0 = arg_12_0:checkHeroIsCurrent(arg_13_0)
		local var_13_1 = arg_12_0:checkHeroIsCurrent(arg_13_1)

		if (var_13_0 or var_13_1) and (not var_13_0 or not var_13_1) then
			return var_13_0
		end

		return xyd.petNormalSort(arg_13_0, arg_13_1) or false
	end)

	arg_12_0.totalPet_ = var_12_0
end

function var_0_0.sortTables(arg_14_0, arg_14_1)
	for iter_14_0 = 1, #arg_14_1 do
		table.sort(arg_14_1[iter_14_0], function(arg_15_0, arg_15_1)
			local var_15_0 = arg_14_0:checkHeroIsCurrent(arg_15_0)
			local var_15_1 = arg_14_0:checkHeroIsCurrent(arg_15_1)

			if (var_15_0 or var_15_1) and (not var_15_0 or not var_15_1) then
				return var_15_0
			end

			return xyd.heroNormalSort(arg_15_0, arg_15_1) or false
		end)
	end
end

function var_0_0.delegate(arg_16_0, ...)
	if arg_16_0.leftMenuType_ == var_0_6.PET then
		return arg_16_0:petDelegate(...)
	end

	return arg_16_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = math.ceil(#arg_17_0.totalHero_[arg_17_0.selectedHeroClass_] / var_0_3)

	if cc.ui.UIListView.COUNT_TAG == arg_17_2 then
		return var_17_0
	elseif cc.ui.UIListView.CELL_TAG == arg_17_2 then
		local var_17_1
		local var_17_2
		local var_17_3
		local var_17_4 = arg_17_0.heroList_:dequeueItem()

		if not var_17_4 then
			var_17_4 = arg_17_0.heroList_:newItem()
		else
			var_17_4:removeAllChildren()
		end

		local var_17_5 = display.newNode()

		var_17_5:setTouchSwallowEnabled(false)

		for iter_17_0 = 1, var_0_3 do
			local var_17_6 = (arg_17_3 - 1) * var_0_3 + iter_17_0

			if var_17_6 > #arg_17_0.totalHero_[arg_17_0.selectedHeroClass_] then
				break
			end

			var_17_3 = display.newNode()

			arg_17_0:initHeroCell(var_17_3, var_17_6)

			local var_17_7 = var_17_3:getContentSize().width
			local var_17_8 = var_17_3:getContentSize().height
			local var_17_9 = (arg_17_0.heroList_.viewRect_.width - var_17_7 * var_0_3) / (var_0_3 + 1)

			var_17_3:pos(var_17_9 * iter_17_0 + (iter_17_0 - 1) * var_17_7 + var_17_7 / 2, var_0_5 + var_17_8 / 2 - 2)
			var_17_5:addChild(var_17_3)

			arg_17_0.heroCells_[var_17_6] = var_17_3
		end

		var_17_5:setContentSize(cc.size(arg_17_0.heroList_.viewRect_.width, var_17_3:getContentSize().height + var_0_5))
		var_17_4:setItemSize(arg_17_0.heroList_.viewRect_.width, var_17_3:getContentSize().height + var_0_5)
		var_17_4:addContent(var_17_5)

		return var_17_4
	end
end

function var_0_0.petDelegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = math.ceil(#arg_18_0.totalPet_ / var_0_2)

	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		return var_18_0
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_1
		local var_18_2
		local var_18_3
		local var_18_4 = arg_18_0.heroList_:dequeueItem()

		if not var_18_4 then
			var_18_4 = arg_18_0.heroList_:newItem()
		else
			var_18_4:removeAllChildren()
		end

		local var_18_5 = display.newNode()

		var_18_5:setTouchSwallowEnabled(false)

		for iter_18_0 = 1, var_0_2 do
			local var_18_6 = (arg_18_3 - 1) * var_0_2 + iter_18_0

			if var_18_6 > #arg_18_0.totalPet_ then
				break
			end

			var_18_3 = display.newNode()

			arg_18_0:initPetCell(var_18_3, var_18_6)

			local var_18_7 = var_18_3:getContentSize().width
			local var_18_8 = var_18_3:getContentSize().height
			local var_18_9 = (arg_18_0.heroList_.viewRect_.width - var_18_7 * var_0_2) / (var_0_2 + 1)

			var_18_3:align(display.CENTER, var_18_9 * iter_18_0 + (iter_18_0 - 1) * var_18_7 + var_18_7 / 2, var_18_8 / 2)
			var_18_5:addChild(var_18_3)
		end

		var_18_5:setContentSize(cc.size(arg_18_0.heroList_.viewRect_.width, var_18_3:getContentSize().height))
		var_18_4:setItemSize(arg_18_0.heroList_.viewRect_.width, var_18_3:getContentSize().height)
		var_18_4:addContent(var_18_5)

		return var_18_4
	end
end

function var_0_0.initHeroCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0.totalHero_[arg_19_0.selectedHeroClass_][arg_19_2]
	local var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_19_1:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_19_2 = var_19_1:getChildByName("background"):getContentSize()

	var_19_1:setContentSize(var_19_2)
	arg_19_1:setContentSize(var_19_2)
	xyd.setAvatarBorderNewUI(var_19_0, var_19_1:getChildByName("avatar"))

	local var_19_3 = var_19_1:getChildByName("chosen")

	var_19_3:setLocalZOrder(100)
	var_19_3:setVisible(false)

	local var_19_4 = var_19_1:getChildByName("avatar_mask")

	var_19_4:setLocalZOrder(2)
	var_19_4:setVisible(false)

	arg_19_1.type = var_0_6.SELF_HERO

	var_19_1:getChildByName("is_can_rent"):setVisible(false)

	for iter_19_0 = 1, 3 do
		var_19_1:getChildByName("team" .. iter_19_0):setVisible(false)
	end

	var_19_1:getChildByName("lv_txt"):setString(var_19_0:getLevel())

	local var_19_5 = var_19_1:getChildByName("name_text")

	var_19_5:setString(var_19_0:getName())
	var_19_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_19_0:getColor()] ~= "" then
		local var_19_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_19_5:getX() + var_19_5:getWidth() / 2 - 10,
			y = var_19_5:getY(),
			color = xyd.color.HERO_QUALITY[var_19_0:getColor()],
			text = xyd.Color2Level[var_19_0:getColor()]
		}
		local var_19_7 = xyd.AssetLoader.get():loadLabel(var_19_6)

		var_19_7:addTo(var_19_1)
		var_19_7:align(display.CENTER_LEFT)
		var_19_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_19_5:x(var_19_5:getX() - 15)
	end

	var_19_1:getChildByName("hp_bar"):hide()
	var_19_1:getChildByName("mp_bar"):hide()
	var_19_1:getChildByName("dead_text"):hide()
	var_19_1:getChildByName("hp_di"):hide()
	var_19_1:getChildByName("mp_di"):hide()
	var_19_1:setName("layout")
	var_19_1:setPosition(cc.p(0, 0))

	arg_19_1.data = var_19_0

	arg_19_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_19_1:addChild(var_19_1)
	arg_19_1:setTouchSwallowEnabled(false)
	arg_19_1:setTouchEnabled(true)
	arg_19_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		arg_19_0:buttonHandler(nil, arg_19_1, arg_20_0)

		if arg_20_0.name == "began" then
			arg_19_0.startClick_ = true
			arg_19_0.prevX_ = arg_20_0.x
			arg_19_0.prevY_ = arg_20_0.y
		elseif arg_20_0.name == "moved" then
			if math.abs(arg_20_0.y - arg_19_0.prevY_) > 5 or math.abs(arg_20_0.x - arg_19_0.prevX_) > 5 then
				arg_19_0.startClick_ = false
			end
		elseif arg_20_0.name == "ended" and arg_19_0.startClick_ then
			arg_19_0:clickAvatar(arg_19_1)
		end

		return true
	end)

	if arg_19_0:checkHeroIsCurrent(var_19_0) then
		var_19_4:setVisible(true)
		var_19_3:setVisible(true)
	end
end

function var_0_0.initPetCell(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_0.totalPet_[arg_21_2]

	arg_21_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatar(arg_21_1, var_21_0, 100)

	arg_21_1.data = var_21_0

	arg_21_1:setTouchEnabled(true)
	arg_21_1:setTouchSwallowEnabled(false)
	arg_21_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		arg_21_0:buttonHandler(nil, arg_21_1, arg_22_0)

		if arg_22_0.name == "began" then
			arg_21_0.startClick_ = true
			arg_21_0.prevX_ = arg_22_0.x
			arg_21_0.prevY_ = arg_22_0.y
		elseif arg_22_0.name == "moved" then
			if math.abs(arg_22_0.y - arg_21_0.prevY_) > 5 or math.abs(arg_22_0.x - arg_21_0.prevX_) > 5 then
				arg_21_0.startClick_ = false
			end
		elseif arg_22_0.name == "ended" and arg_21_0.startClick_ then
			arg_21_0:clickAvatar(arg_21_1)
		end

		return true
	end)

	if arg_21_0:checkHeroIsCurrent(var_21_0) then
		local var_21_1 = arg_21_1:getChildByName("layout")
		local var_21_2 = var_21_1:getChildByName("avatar_mask")
		local var_21_3 = var_21_1:getChildByName("chosen")

		var_21_2:setVisible(true)
		var_21_3:setVisible(true)
	end
end

function var_0_0.clickAvatar(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_1.data
	local var_23_1 = arg_23_0:getSelectIds(var_23_0)

	arg_23_0.personDisplay:modifyShowCase(var_23_1, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			if arg_23_0.callback then
				arg_23_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_23_0)
		end
	end)
end

function var_0_0.addToSelectHero(arg_25_0, arg_25_1)
	table.insert(arg_25_0.selectHeros, arg_25_1)
end

function var_0_0.removeSelectHero(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.selectHeros) do
		if iter_26_1 and next(iter_26_1) and arg_26_1:getTableID() == iter_26_1:getTableID() then
			arg_26_0.selectHeros[iter_26_0] = {}

			break
		end
	end
end

function var_0_0.checkHeroIsSelect(arg_27_0, arg_27_1)
	for iter_27_0 = 1, #arg_27_0.selectHeros do
		local var_27_0 = arg_27_0.selectHeros[iter_27_0]

		if arg_27_0.index ~= iter_27_0 and var_27_0 and next(var_27_0) and arg_27_1:getTableID() == var_27_0:getTableID() then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsCurrent(arg_28_0, arg_28_1)
	if arg_28_0.currentHero and arg_28_0.currentHero:getTableID() == arg_28_1:getTableID() then
		return true
	end

	return false
end

function var_0_0.buttonHandler(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if not arg_29_2 or not arg_29_2:getParent() then
		return
	end

	if arg_29_3.name == "ended" then
		transition.stopTarget(arg_29_2)
		arg_29_2:setScale(1)

		if arg_29_1 then
			arg_29_1(arg_29_2, eventType)
		end
	elseif arg_29_3.name == "began" then
		local var_29_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_29_2:runAction(var_29_0)

		return true
	elseif arg_29_3.name == "cancled" then
		transition.stopTarget(arg_29_2)
		arg_29_2:setScale(1)
	end
end

return var_0_0
