local var_0_0 = class("HireHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = xyd.tables.translation
local var_0_5 = 4
local var_0_6 = 10
local var_0_7 = 1
local var_0_8 = {
	RENT_HERO = 1,
	RENT_PET = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.treasure = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.maxSentNum = xyd.tables.vip:employee(arg_1_0.selfPlayer.vip)
	arg_1_0.sentHeros = arg_1_0.guild:getSentHeros()
	arg_1_0.rentPets = arg_1_0.guild:getRentPets()
	arg_1_0.allTeamHeros = {}
	arg_1_0.allTeamPets = {}
end

function var_0_0.scrollListener2(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super:willOpen(arg_4_1)

	arg_4_0.sentList = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 849, 495),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))
	arg_4_0.allList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 787, 504),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("all_list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener2))
	arg_4_0.handlers = {}
	arg_4_0.girlType = 1

	arg_4_0:layout()
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_1)

	if arg_5_0.handlers and next(arg_5_0.handlers) ~= nil then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.handlers) do
			var_0_1.unscheduleGlobal(iter_5_1)
		end
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("send_hero_txt"):setString(var_0_4:translation("SEND_HERO_NUM"))
	arg_6_0:nodeByName("rent_pet_txt"):setString(var_0_4:translation("RENT_PET_NUM"))
	arg_6_0:nodeByName("title"):setString(var_0_4:translation("SHE_TUAN_TEXT_33"))
	arg_6_0:nodeByName("my_hero_txt"):setString(var_0_4:translation("SHE_TUAN_TEXT_34"))
	arg_6_0:nodeByName("all_hero_txt"):setString(var_0_4:translation("SHE_TUAN_TEXT_35"))
	arg_6_0:nodeByName("all_pet_txt"):setString(var_0_4:translation("SHE_TUAN_TEXT_36"))
	arg_6_0:updateGirlBtnType(arg_6_0.girlType)
	arg_6_0:nodeByName("my_scene"):setVisible(true)
	arg_6_0:nodeByName("all_scene"):setVisible(false)
	arg_6_0:nodeByName("my_hero_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0.girlType = 1

			arg_6_0:updateGirlBtnType(arg_6_0.girlType)
			arg_6_0:nodeByName("my_scene"):setVisible(true)
			arg_6_0:nodeByName("all_scene"):setVisible(false)
			arg_6_0:updateSentList()
		end
	end)
	arg_6_0:nodeByName("all_hero_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {}

			var_8_0.load_place = 1

			arg_6_0.guild:loadAllTeamHeros(var_8_0, function(arg_9_0)
				if arg_9_0 == xyd.error.OK then
					arg_6_0.girlType = 2

					arg_6_0:updateGirlBtnType(arg_6_0.girlType)
					arg_6_0:nodeByName("my_scene"):setVisible(false)
					arg_6_0:nodeByName("all_scene"):setVisible(true)
					arg_6_0:updateAllHeroList()
				end
			end)
		end
	end)
	arg_6_0:nodeByName("all_pet_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = {}

			var_10_0.load_place = 1

			arg_6_0.guild:loadAllTeamPets(var_10_0, function(arg_11_0)
				if arg_11_0 == xyd.error.OK then
					arg_6_0.girlType = 3

					arg_6_0:updateGirlBtnType(arg_6_0.girlType)
					arg_6_0:nodeByName("my_scene"):setVisible(false)
					arg_6_0:nodeByName("all_scene"):setVisible(true)
					arg_6_0:updateAllPetList()
				end
			end)
		end
	end)
	arg_6_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("rule_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = {
				title_name = "HIRE_HERO_RULE_TITLE",
				rule = "borrow_rule"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
		end
	end)
	arg_6_0.allList:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0:updateSentList()
end

function var_0_0.updateGirlBtnType(arg_13_0, arg_13_1)
	if arg_13_1 == 1 then
		arg_13_0:nodeByName("my_hero_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("all_hero_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("all_pet_btn"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_1 == 2 then
		arg_13_0:nodeByName("my_hero_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("all_hero_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("all_pet_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("sub_title"):setString(var_0_4:translation("GUILD_ALL_HERO"))
	else
		arg_13_0:nodeByName("my_hero_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("all_hero_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("all_pet_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("sub_title"):setString(var_0_4:translation("GUILD_ALL_PET"))
	end
end

function var_0_0.updateSentList(arg_14_0)
	if arg_14_0.handlers and next(arg_14_0.handlers) ~= nil then
		for iter_14_0, iter_14_1 in ipairs(arg_14_0.handlers) do
			var_0_1.unscheduleGlobal(iter_14_1)
		end
	end

	arg_14_0.sentList:removeAllItems()

	local var_14_0 = #arg_14_0.sentHeros
	local var_14_1 = xyd.tables.vip:employee(arg_14_0.selfPlayer.vip)

	arg_14_0:nodeByName("send_hero_num"):setString(#arg_14_0.sentHeros .. "/" .. var_14_1)
	arg_14_0:nodeByName("rent_pet_num"):setString(#arg_14_0.rentPets .. "/" .. var_0_7)

	for iter_14_2 = 1, var_14_0 do
		arg_14_0:initSentItem(arg_14_0.sentHeros[iter_14_2], var_0_8.RENT_HERO, iter_14_2)
	end

	for iter_14_3 = 1, #arg_14_0.rentPets do
		arg_14_0:initSentItem(arg_14_0.rentPets[iter_14_3], var_0_8.RENT_PET, iter_14_3 + var_14_0)
	end

	if var_14_0 < var_14_1 or #arg_14_0.rentPets < var_0_7 then
		local var_14_2 = display.newNode()
		local var_14_3 = arg_14_0.sentList:newItem()
		local var_14_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/hire_item.csb")
		local var_14_5 = var_14_4:getChildByName("container")

		var_14_5:getChildByName("hero_container"):getChildByName("gain_money_txt"):setString(var_0_4:translation("ALREADY_INCOME"))
		var_14_5:getChildByName("hero_container"):getChildByName("send_time_txt"):setString(var_0_4:translation("GUILD_SEND_PROTECT_TIME"))
		var_14_5:getChildByName("add_hero_txt"):setString(var_0_4:translation("SEND_HERO"))
		var_14_5:getChildByName("add_hero_txt"):enableOutline(cc.c4b(123, 55, 0, 255), 1)
		var_14_5:getChildByName("add_hero_desc"):setString(var_0_4:translation("SEND_HERO_DES"))
		var_14_5:getChildByName("hero_container"):setVisible(false)
		var_14_5:getChildByName("hero_frame"):setTouchEnabled(true)
		var_14_5:getChildByName("hero_frame"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				var_14_5:getChildByName("hero_frame"):getChildByName("add_hero"):scale(0.9)

				arg_14_0.startframeClick_ = true
				arg_14_0.prevX_ = arg_15_0.x
				arg_14_0.prevY_ = arg_15_0.y

				return true
			elseif arg_15_0.name == "moved" then
				var_14_5:getChildByName("hero_frame"):getChildByName("add_hero"):scale(1)

				if math.abs(arg_15_0.y - arg_14_0.prevY_) > 5 or math.abs(arg_15_0.x - arg_14_0.prevX_) > 5 then
					arg_14_0.startframeClick_ = false
				end

				return true
			elseif arg_15_0.name == "ended" and arg_14_0.startframeClick_ then
				var_14_5:getChildByName("hero_frame"):getChildByName("add_hero"):scale(1)

				local var_15_0 = {
					treasurePartners = {},
					sentHeros = arg_14_0.sentHeros
				}

				arg_14_0.selfPlayer:loadUsedPartners(function(arg_16_0)
					local var_16_0 = {
						busyHeros = arg_16_0,
						sentHeros = arg_14_0.sentHeros
					}

					xyd.WindowManager.get():openWindow("choose_heros", var_16_0)
				end)

				return true
			end
		end)
		var_14_4:addTo(var_14_2)
		var_14_2:setContentSize(843, 172)
		var_14_2:setAnchorPoint(cc.p(0, 0))
		var_14_2:setPosition(0, 0)
		var_14_3:addContent(var_14_2)
		var_14_3:setItemSize(843, 180)
		arg_14_0.sentList:addItem(var_14_3)
	end

	arg_14_0.sentList:reload()
end

function var_0_0.initSentItem(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = display.newNode()
	local var_17_1 = arg_17_0.sentList:newItem()
	local var_17_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/hire_item.csb")
	local var_17_3 = var_17_2:getChildByName("container")
	local var_17_4 = var_17_3:getChildByName("hero_container")

	var_17_3:getChildByName("hero_container"):getChildByName("gain_money_txt"):setString(var_0_4:translation("ALREADY_INCOME"))
	var_17_3:getChildByName("hero_container"):getChildByName("send_time_txt"):setString(var_0_4:translation("GUILD_SEND_PROTECT_TIME"))
	var_17_3:getChildByName("add_hero_txt"):setString(var_0_4:translation("SEND_HERO"))
	var_17_3:getChildByName("add_hero_desc"):setString(var_0_4:translation("SEND_HERO_DES"))
	var_17_3:getChildByName("hero_frame"):setVisible(false)
	var_17_3:getChildByName("add_hero_txt"):setVisible(false)
	var_17_3:getChildByName("add_hero_desc"):setVisible(false)

	if arg_17_2 == var_0_8.RENT_HERO then
		local var_17_5 = arg_17_0.selfPlayer:getHeroByID(arg_17_1.partner_id)

		xyd.setAvatarBorderNewUI(var_17_5, var_17_4, var_17_5:getColor(), var_17_5:getStar())
	else
		local var_17_6 = arg_17_0.selfPlayer:getPetByID(arg_17_1.pet_id)

		xyd.setPetAvatar(var_17_4, var_17_6, 100, true)
	end

	local var_17_7 = arg_17_0:createTimeLabel(arg_17_1.rent_time, xyd.ServerTime.get():getServerTime())

	var_17_4:getChildByName("send_time_num"):setString(var_17_7)
	var_17_4:getChildByName("gain_money_num"):setString(math.floor(arg_17_1.award + arg_17_1.rent_award))
	var_17_4:getChildByName("send_time_txt"):setString(var_0_4:translation("SEND_TIME_DESC"))

	arg_17_0.handlers[arg_17_3] = var_0_1.scheduleGlobal(function()
		local var_18_0 = arg_17_0:createTimeLabel(arg_17_1.rent_time, xyd.ServerTime.get():getServerTime())

		var_17_4:getChildByName("send_time_num"):setString(var_18_0)
	end, 60)

	local var_17_8 = var_17_4:getChildByName("back_hero_btn")

	var_17_8:getChildByName("back_txt"):setString(var_0_4:translation("SHE_TUAN_TEXT_37"))
	var_17_8:addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(var_17_8, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = arg_17_1.rent_time

			if xyd.ServerTime.get():getServerTime() - var_19_0 < 1800 then
				local var_19_1 = var_0_4:translation("HIRE_HERO_BACK_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_1
				})
			else
				local var_19_2 = {}

				if arg_17_2 == var_0_8.RENT_HERO then
					var_19_2.partner_id = arg_17_1.partner_id

					arg_17_0.guild:getRentBack(var_19_2, function(arg_20_0)
						if arg_20_0 == xyd.error.OK then
							local var_20_0 = {
								jiewanAward = arg_17_1.rent_award,
								shouyingAward = arg_17_1.award
							}

							xyd.WindowManager.get():openWindow("hire_hero_award", var_20_0)
						end
					end)
				else
					var_19_2.pet_id = arg_17_1.pet_id

					arg_17_0.guild:getRentPetBack(var_19_2, function(arg_21_0)
						if arg_21_0 == xyd.error.OK then
							local var_21_0 = {
								jiewanAward = arg_17_1.rent_award,
								shouyingAward = arg_17_1.award
							}

							xyd.WindowManager.get():openWindow("hire_hero_award", var_21_0)
						end
					end)
				end
			end
		end
	end)
	var_17_2:addTo(var_17_0)
	var_17_0:setContentSize(843, 172)
	var_17_0:setAnchorPoint(cc.p(0, 0))
	var_17_0:setPosition(0, 0)
	var_17_1:addContent(var_17_0)
	var_17_1:setItemSize(843, 180)
	arg_17_0.sentList:addItem(var_17_1)
end

function var_0_0.sortHeros(arg_22_0, arg_22_1)
	table.sort(arg_22_1, function(arg_23_0, arg_23_1)
		if arg_23_0:canSummon() and not arg_23_1:canSummon() then
			return true
		elseif arg_23_1:canSummon() and not arg_23_0:canSummon() then
			return false
		end

		return xyd.heroNormalSort(arg_23_0, arg_23_1) or false
	end)
end

function var_0_0.delegate(arg_24_0, ...)
	if arg_24_0.girlType == 3 then
		return arg_24_0:petDelegate(...)
	end

	return arg_24_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = {}
	local var_25_1 = math.ceil(#arg_25_0.allTeamHeros / 4)

	if cc.ui.UIListView.COUNT_TAG == arg_25_2 then
		return var_25_1
	elseif cc.ui.UIListView.CELL_TAG == arg_25_2 then
		local var_25_2
		local var_25_3
		local var_25_4
		local var_25_5 = arg_25_0.allList:dequeueItem()

		if not var_25_5 then
			var_25_5 = arg_25_0.allList:newItem()
		else
			var_25_5:removeAllChildren()
		end

		local var_25_6 = display.newNode()

		var_25_6:setTouchSwallowEnabled(false)

		for iter_25_0 = 1, 4 do
			local var_25_7 = (arg_25_3 - 1) * 4 + iter_25_0

			if var_25_7 > #arg_25_0.allTeamHeros then
				break
			end

			local var_25_8 = arg_25_0.allTeamHeros[var_25_7]

			table.insert(var_25_0, var_25_8)

			local var_25_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/all_hero_item.csb")
			local var_25_10 = var_25_9:getChildByName("container")

			var_25_10:getChildByName("owner_name"):setString(var_25_8.player_name)

			local var_25_11 = var_25_10:getChildByName("avatar_container")

			xyd.setAvatarBorderNewUI(var_25_8, var_25_11)

			local var_25_12 = var_25_10:getChildByName("lv_txt")

			var_25_12:setString(var_25_8:getLevel())
			var_25_12:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_25_10:getChildByName("name"):setString(var_25_8:getName())
			var_25_9:addTo(var_25_6)
			var_25_9:setPosition((iter_25_0 - 1) * 200, 0)

			local var_25_13 = display.newNode()

			var_25_13:setContentSize(var_25_10:getWidth(), var_25_10:getHeight())
			var_25_13:setTouchEnabled(true)
			var_25_13:setTouchSwallowEnabled(false)
			var_25_13:setAnchorPoint(cc.p(0, 0))
			var_25_13:setPosition(0, 0)
			var_25_10:addChild(var_25_13)
			var_25_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
				local var_26_0 = var_25_10:getPositionX()
				local var_26_1 = var_25_10:getPositionY()
				local var_26_2 = true
				local var_26_3 = var_25_13:convertToWorldSpace(cc.p(var_25_13:getPositionX(), var_25_13:getPositionY()))

				if arg_26_0.name == "began" then
					arg_25_0.prevX_ = arg_26_0.x
					arg_25_0.prevY_ = arg_26_0.y

					var_25_10:setAnchorPoint(cc.p(0.5, 0.5))
					var_25_10:setPosition(87, 102)
					var_25_10:setScale(0.9)

					arg_25_0.MoveX_ = nil

					return true
				elseif arg_26_0.name == "moved" then
					arg_25_0.MoveX_ = arg_26_0.x
					arg_25_0.MoveY_ = arg_26_0.y
				elseif arg_26_0.name == "ended" then
					var_25_10:setScale(1)
					var_25_10:setPosition(var_26_0, var_26_1)

					if arg_25_0.MoveX_ then
						if math.abs(var_26_3.x - arg_25_0.MoveX_) > var_25_13:getWidth() or arg_25_0.MoveX_ > var_26_3.x + var_25_13:getWidth() or arg_25_0.MoveX_ < var_26_3.x then
							var_26_2 = false
						end

						if math.abs(var_26_3.y - arg_25_0.MoveY_) > var_25_13:getHeight() or arg_25_0.MoveY_ > var_26_3.y + var_25_13:getHeight() or arg_25_0.MoveY_ < var_26_3.y then
							var_26_2 = false
						end

						if arg_25_0.scrollViewMoved_ == true then
							var_26_2 = false
						end
					end

					if var_26_2 then
						xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_25_8)
					end
				end

				return true
			end)
		end

		var_25_6:setContentSize(699, 210)
		var_25_6:setAnchorPoint(cc.p(0, 0))
		var_25_6:setPosition(0, 0)
		var_25_5:addContent(var_25_6)
		var_25_5:setItemSize(699, 210)

		return var_25_5
	end
end

function var_0_0.petDelegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = math.ceil(#arg_27_0.allTeamPets / var_0_5)

	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		return var_27_0
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		local var_27_1
		local var_27_2
		local var_27_3 = arg_27_0.allList:dequeueItem()

		if not var_27_3 then
			var_27_3 = arg_27_0.allList:newItem()
		else
			var_27_3:removeAllChildren()
		end

		local var_27_4 = display.newNode()

		var_27_4:setTouchSwallowEnabled(false)

		for iter_27_0 = 1, var_0_5 do
			local var_27_5 = (arg_27_3 - 1) * var_0_5 + iter_27_0

			if var_27_5 > #arg_27_0.allTeamPets then
				break
			end

			local var_27_6 = display.newNode()
			local var_27_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/all_hero_item.csb")

			var_27_6:addChild(var_27_7)

			local var_27_8 = var_27_7:getChildByName("container")
			local var_27_9 = var_27_8:getChildByName("avatar_container")
			local var_27_10 = arg_27_0.allTeamPets[var_27_5]

			xyd.setPetAvatar(var_27_9, var_27_10, 100, true)
			var_27_8:getChildByName("owner_name"):setString(var_27_10.player_name)
			var_27_8:getChildByName("name"):setString(var_27_10:getName())
			var_27_8:getChildByName("lv_di"):setVisible(false)
			var_27_8:getChildByName("lv_txt"):setVisible(false)

			local var_27_11 = var_27_8:getContentSize().width
			local var_27_12 = var_27_8:getContentSize().height
			local var_27_13 = (arg_27_0.allList.viewRect_.width - var_27_11 * var_0_5) / (var_0_5 + 1)

			var_27_8:setAnchorPoint(cc.p(0.5, 0.5))
			var_27_6:align(display.CENTER, 200 * (iter_27_0 - 1) + var_27_11 / 2, var_27_12 / 2)
			var_27_6:setTouchEnabled(true)
			var_27_6:setTouchSwallowEnabled(false)
			var_27_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
				if arg_28_0.name == "began" then
					arg_27_0.startClick_ = true
					arg_27_0.prevX_ = arg_28_0.x
					arg_27_0.prevY_ = arg_28_0.y

					var_27_6:setScale(0.9)
				elseif arg_28_0.name == "moved" then
					var_27_6:setScale(1)

					if math.abs(arg_28_0.y - arg_27_0.prevY_) > 5 or math.abs(arg_28_0.x - arg_27_0.prevX_) > 5 then
						arg_27_0.startClick_ = false
					end
				elseif arg_28_0.name == "ended" and arg_27_0.startClick_ then
					var_27_6:setScale(1)
					xyd.WindowManager.get():openWindow("pet_attribute", var_27_10)
				end

				return true
			end)
			var_27_4:addChild(var_27_6)
		end

		var_27_4:setContentSize(cc.size(arg_27_0.allList.viewRect_.width, 200 + var_0_6))
		var_27_3:setItemSize(arg_27_0.allList.viewRect_.width, 200 + var_0_6)
		var_27_3:addContent(var_27_4)

		return var_27_3
	end
end

function var_0_0.updateAllHeroList(arg_29_0)
	arg_29_0.allTeamHeros = {}

	for iter_29_0, iter_29_1 in ipairs(arg_29_0.guild:getAllTeamHeros()) do
		local var_29_0 = var_0_2.new()

		var_29_0:populate(iter_29_1)

		var_29_0.player_name = iter_29_1.player_name
		var_29_0.player_lev = iter_29_1.player_lev
		var_29_0.player_avatar = iter_29_1.player_avatar_id
		var_29_0.player_avatar_frame = iter_29_1.player_avatar_frame_id

		if iter_29_1.conquer_lev and iter_29_1.conquer_lev > 0 then
			var_29_0:setConquerSchoolLev(iter_29_1.conquer_lev, iter_29_1.conquer_loop_id)
		end

		table.insert(arg_29_0.allTeamHeros, var_29_0)
	end

	arg_29_0:sortHeros(arg_29_0.allTeamHeros)
	arg_29_0.allList:reload()
end

function var_0_0.updateAllPetList(arg_30_0)
	arg_30_0.allTeamPets = {}

	for iter_30_0, iter_30_1 in ipairs(arg_30_0.guild:getAllTeamPets()) do
		local var_30_0 = var_0_3.new()

		var_30_0:populate(iter_30_1)

		var_30_0.player_name = iter_30_1.player_name
		var_30_0.player_lev = iter_30_1.player_lev
		var_30_0.player_avatar = iter_30_1.player_avatar_id
		var_30_0.player_avatar_frame = iter_30_1.player_avatar_frame_id

		if iter_30_1.conquer_lev and iter_30_1.conquer_lev > 0 then
			var_30_0.conquer_lev = iter_30_1.conquer_lev
		end

		table.insert(arg_30_0.allTeamPets, var_30_0)
	end

	arg_30_0:sortHeros(arg_30_0.allTeamPets)
	arg_30_0.allList:reload()
end

function var_0_0.createTimeLabel(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0
	local var_31_1
	local var_31_2

	if arg_31_2 - arg_31_1 <= 0 then
		var_31_0 = 0
		var_31_2 = 0
	else
		var_31_0 = math.floor((arg_31_2 - arg_31_1) / 3600)
		var_31_2 = math.floor((arg_31_2 - arg_31_1) % 3600 / 60)
	end

	if var_31_0 < 10 then
		var_31_0 = "0" .. var_31_0
	end

	if var_31_2 < 10 then
		var_31_2 = "0" .. var_31_2
	end

	return var_31_0 .. var_0_4:translation("UNIT_HOUR") .. var_31_2 .. var_0_4:translation("UNIT_MINUTE")
end

function var_0_0.didOpen(arg_32_0, arg_32_1)
	var_0_0.super:didOpen(arg_32_1)
	arg_32_0:addBlockLayer()
end

return var_0_0
