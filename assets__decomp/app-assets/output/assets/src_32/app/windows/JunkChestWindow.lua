local var_0_0 = class("JunkChestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.cabinetSkillTable
local var_0_5 = xyd.tables.cabinetSkillCostTable
local var_0_6 = xyd.tables.cabinetBookTable
local var_0_7 = 5
local var_0_8 = 30
local var_0_9 = 30
local var_0_10 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()

	local var_1_0 = {}

	for iter_1_0, iter_1_1 in pairs(var_0_6:getIds()) do
		local var_1_1 = {
			index = iter_1_0,
			title = var_0_6:name(iter_1_1),
			star = var_0_6:star(iter_1_1),
			skills = var_0_6:skillId(iter_1_1),
			author = var_0_6:author(iter_1_1),
			desc = var_0_6:desc(iter_1_1)
		}

		table.insert(var_1_0, var_1_1)
	end

	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.cabinetLev = arg_1_0.eventCentre.cabinetLev
	arg_1_0.index_ = 1

	if arg_1_2 then
		arg_1_0.startBook = arg_1_2.id
		arg_1_0.startBookType = arg_1_2.bookType
	end
end

function var_0_0.getAllHeros(arg_2_0)
	arg_2_0.heros = {}

	for iter_2_0, iter_2_1 in pairs(var_0_6:getHeros()) do
		local var_2_0 = arg_2_0.selfPlayer:getHeroIgnoreAwaken(iter_2_1)
		local var_2_1 = 0

		if var_2_0 then
			var_2_1 = var_2_0:getZhandouli()
		end

		arg_2_0.heros[iter_2_0] = {}
		arg_2_0.heros[iter_2_0].power = var_2_1
		arg_2_0.heros[iter_2_0].id = iter_2_1
	end

	table.sort(arg_2_0.heros, function(arg_3_0, arg_3_1)
		if arg_3_0.power == arg_3_1.power then
			return arg_3_0.id < arg_3_1.id
		else
			return arg_3_0.power > arg_3_1.power
		end
	end)
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	arg_4_0.originalY = arg_4_0.leftList_.scrollNode:getPositionY()

	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 10 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLeftContainer(arg_5_0, arg_5_1)
	arg_5_0.leftList_:removeAllItems()

	for iter_5_0, iter_5_1 in pairs(arg_5_0.bookData) do
		arg_5_0:addLeftCategory(iter_5_1, iter_5_0, arg_5_1)
	end

	arg_5_0.leftList_:reload()

	if arg_5_0.originalY and arg_5_1 then
		arg_5_0.playMoveHandle = var_0_1.performWithDelayGlobal(function()
			if not arg_5_0 or tolua.isnull(arg_5_0) then
				return
			elseif arg_5_0.leftList_ then
				arg_5_0.leftList_:scrollTo(0, arg_5_0.originalY)
			end
		end, 0.01)
	end
end

function var_0_0.addLeftCategory(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0.leftList_:newItem()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/big_label.csb")
	local var_7_2 = var_7_1:getChildByName("container")

	if arg_7_0.book_type == arg_7_1.type and arg_7_0.has_click_left == false then
		var_7_2:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_7_2:getChildByName("btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	local var_7_3 = var_7_2:getContentSize()

	var_7_1:setPosition(cc.p(0, 0))
	var_7_1:setContentSize(var_7_3)
	var_7_1:setTouchEnabled(true)
	var_7_1:setTouchSwallowEnabled(false)
	var_7_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			if not arg_7_0.scrollViewMoved_ then
				arg_7_0.originalY = arg_7_0.leftList_.scrollNode:getPositionY()

				if arg_7_0.book_type == arg_7_1.type then
					if arg_7_0.has_click_left == false then
						arg_7_0.has_click_left = true
					else
						arg_7_0.has_click_left = false
					end

					arg_7_0.click_same_left = true
				else
					arg_7_0.has_click_left = false
					arg_7_0.click_same_left = false
				end

				arg_7_0.book_type = arg_7_1.type

				arg_7_0:updateLeftContainer()

				if arg_7_0.click_same_left == false then
					arg_7_0.leftList_:scrollTo(0, arg_7_0.leftList_.scrollNode:getPositionY() + (arg_7_2 - 1) * 99)
				end

				return true
			else
				return true
			end
		end
	end)
	var_7_0:addContent(var_7_1)
	var_7_0:setItemSize(var_7_3.width, var_7_3.height)
	arg_7_0.leftList_:addItem(var_7_0)

	for iter_7_0 = 0, 4 do
		var_7_2:getChildByName("bookClass" .. iter_7_0):setVisible(false)
	end

	var_7_2:getChildByName("bookClass" .. arg_7_1.type):setVisible(true)

	local var_7_4 = #arg_7_1.subList or 0

	var_7_2:getChildByName("book_num_text"):setString("(" .. var_7_4 .. ")")

	if arg_7_1.type == arg_7_0.book_type then
		local var_7_5 = arg_7_1.subList

		if var_7_5 and next(var_7_5) then
			local var_7_6 = {}

			local function var_7_7(arg_9_0, arg_9_1)
				for iter_9_0, iter_9_1 in pairs(var_7_6) do
					if iter_9_0 == arg_9_0 then
						iter_9_1:getChildByName("bg1"):setVisible(false)
						iter_9_1:getChildByName("bg2"):setVisible(true)
						iter_9_1:getChildByName("left_click_not"):setVisible(false)
						iter_9_1:getChildByName("left_click_on"):setVisible(true)

						if arg_9_1 == nil or arg_9_1 == 2 then
							if arg_7_0:nodeByName("icons"):getChildByName("effect") then
								arg_7_0:nodeByName("icons"):removeChildByName("effect")
							end

							if arg_7_0.has_click_left == false then
								if arg_7_0.selfPlayer:getBackpack():getItemNumByID(var_7_5[arg_9_0].id) > 0 then
									arg_7_0:nodeByName("book_des_container"):setVisible(true)
									arg_7_0:nodeByName("piece_container"):setVisible(false)
								elseif arg_7_0.selfPlayer:getBackpack():getItemNumByID(var_7_5[arg_9_0].id) <= 0 and arg_7_1.type == 0 then
									arg_7_0:nodeByName("book_des_container"):setVisible(true)
									arg_7_0:nodeByName("piece_container"):setVisible(false)
								else
									arg_7_0:nodeByName("book_des_container"):setVisible(false)
									arg_7_0:nodeByName("piece_container"):setVisible(true)
								end

								arg_7_0:nodeByName("working_container"):setVisible(false)
							end

							if var_7_5[arg_9_0] then
								if var_7_5[arg_9_0].author then
									arg_7_0:nodeByName("writer_text"):setString(var_0_3:name(var_7_5[arg_9_0].author))
								end

								if var_7_5[arg_9_0].desc then
									arg_7_0:nodeByName("book_des_text"):setString(var_7_5[arg_9_0].desc)
								end

								if var_7_5[arg_9_0].skills then
									arg_7_0:updateMainContainer(var_7_5[arg_9_0].skills, var_7_5[arg_9_0].star, var_7_5[arg_9_0].id)

									arg_7_0.book = var_7_5[arg_9_0]
									arg_7_0.bookId = var_7_5[arg_9_0].id
								end

								if arg_7_1.type ~= 0 then
									local var_9_0 = arg_7_0.selfPlayer:getBackpack():getItemNumByID(var_0_6:piece(var_7_5[arg_9_0].id))
									local var_9_1 = xyd.tables.item:itemNum(var_0_6:piece(var_7_5[arg_9_0].id))

									if var_9_1 < var_9_0 then
										arg_7_0:nodeByName("piece_bar"):setPercent(100)
									else
										arg_7_0:nodeByName("piece_bar"):setPercent(var_9_0 / var_9_1 * 100)
									end

									arg_7_0:nodeByName("num_text"):setString(var_9_0 .. "/" .. var_9_1)
									arg_7_0:nodeByName("piece_icon"):removeAllChildren()
									xyd.setItemBorder(arg_7_0:nodeByName("piece_icon"), var_0_6:piece(var_7_5[arg_9_0].id))
								end
							end
						elseif arg_9_1 == 3 and var_7_5[arg_9_0] and var_7_5[arg_9_0].skills then
							arg_7_0:updateMainContainer(var_7_5[arg_9_0].skills, var_7_5[arg_9_0].star, var_7_5[arg_9_0].id)
						end
					else
						iter_9_1:getChildByName("bg1"):setVisible(true)
						iter_9_1:getChildByName("bg2"):setVisible(false)
						iter_9_1:getChildByName("left_click_not"):setVisible(true)
						iter_9_1:getChildByName("left_click_on"):setVisible(false)
					end

					if arg_7_0.selfPlayer:getBackpack():getItemNumByID(var_7_5[iter_9_0].id) <= 0 then
						-- block empty
					end
				end
			end

			local var_7_8 = 0

			for iter_7_1, iter_7_2 in pairs(var_7_5) do
				var_7_8 = var_7_8 - 1

				local var_7_9 = arg_7_0.leftList_:newItem()
				local var_7_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/little_label.csb")
				local var_7_11 = var_7_10:getChildByName("container")
				local var_7_12 = var_7_11:getContentSize()

				var_7_11:setPosition(cc.p(0, 0))
				var_7_10:setContentSize(var_7_12)
				var_7_9:setLocalZOrder(-100 - var_7_8)
				var_7_11:getChildByName("name_text"):setString(iter_7_2.title)

				local var_7_13 = var_7_11:getChildByName("stars")

				var_7_13:setPosition(var_7_13:getPositionX() + (6 - iter_7_2.star) * 8, var_7_13:getPositionY())

				for iter_7_3 = 1, 6 do
					if iter_7_3 > iter_7_2.star then
						var_7_13:getChildByName("star" .. iter_7_3):setVisible(false)
					end

					var_7_13:getChildByName("star_gray" .. iter_7_3):setVisible(false)
				end

				table.insert(var_7_6, var_7_11)
				var_7_10:setTouchEnabled(true)
				var_7_10:setTouchSwallowEnabled(false)
				var_7_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(iter_7_1, function(arg_10_0, arg_10_1)
					if arg_10_1.name == "began" then
						return true
					elseif arg_10_1.name == "ended" and not arg_7_0.scrollViewMoved_ then
						var_7_7(arg_10_0)

						arg_7_0.index_ = arg_10_0

						return true
					end
				end))
				var_7_9:addContent(var_7_10)
				var_7_9:setItemSize(var_7_12.width, var_7_12.height + 10)

				if arg_7_0.has_click_left == false then
					arg_7_0.leftList_:addItem(var_7_9)
				end

				if arg_7_0.startBook == iter_7_2.id then
					arg_7_0.index_ = iter_7_1
				end
			end

			if arg_7_0.startBook then
				arg_7_0.startBook = nil
			else
				local var_7_14 = arg_7_0.index_

				if arg_7_0.click_same_left == false and arg_7_3 == nil then
					arg_7_0.index_ = 1
				end
			end

			var_7_7(arg_7_0.index_, arg_7_3)
		end
	end
end

function var_0_0.willOpen(arg_11_0, arg_11_1)
	var_0_0.super:willOpen(arg_11_1)
	arg_11_0:updateBookList()

	arg_11_0.left_container = arg_11_0:nodeByName("left_list")

	local var_11_0 = arg_11_0.left_container:getContentSize()

	arg_11_0.leftList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_11_0.width, var_11_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_11_0.left_container):onScroll(handler(arg_11_0, arg_11_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_11_0.has_click_left = false
	arg_11_0.click_same_left = false

	arg_11_0:updateLeftContainer()
	arg_11_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.LEARN_CABINET_SKILL, function(arg_12_0)
		local var_12_0 = xyd.tables.cabinetSkillTable:skillbook(arg_12_0.params)

		for iter_12_0, iter_12_1 in pairs(arg_11_0.eventCentre.workingBook) do
			if iter_12_1.id == var_12_0 then
				arg_11_0.book = iter_12_1
				arg_11_0.book_type = 1
				arg_11_0.index_ = iter_12_0

				break
			end
		end

		for iter_12_2, iter_12_3 in pairs(arg_11_0.eventCentre.creatsBook) do
			if iter_12_3.id == var_12_0 then
				arg_11_0.book = iter_12_3
				arg_11_0.book_type = 0
				arg_11_0.index_ = iter_12_2

				break
			end
		end

		for iter_12_4, iter_12_5 in pairs(arg_11_0.eventCentre.overBook) do
			if iter_12_5.id == var_12_0 then
				arg_11_0.book = iter_12_5
				arg_11_0.book_type = 3
				arg_11_0.index_ = iter_12_4

				break
			end
		end

		if arg_11_0.book then
			arg_11_0:updateMainContainer(arg_11_0.book.skills, arg_11_0.book.star, arg_11_0.book.id)
		end

		arg_11_0:updateLeftContainer(3)
		arg_11_0:refreshBottomContainer()
		arg_11_0:checkSkillTime()

		for iter_12_6, iter_12_7 in pairs(arg_11_0.eventCentre.workingBook) do
			if iter_12_7.id == var_12_0 then
				arg_11_0.skills[arg_12_0.params].lev = iter_12_7.skills[arg_12_0.params].lev
			end
		end

		for iter_12_8, iter_12_9 in pairs(arg_11_0.eventCentre.creatsBook) do
			if iter_12_9.id == var_12_0 then
				arg_11_0.skills[arg_12_0.params].lev = iter_12_9.skills[arg_12_0.params].lev
			end
		end
	end)
end

function var_0_0.avatarUpdateLeft(arg_13_0, arg_13_1)
	arg_13_0.originalY = nil

	local var_13_0 = {}
	local var_13_1 = {}
	local var_13_2 = {}
	local var_13_3 = {}
	local var_13_4 = {}

	for iter_13_0, iter_13_1 in pairs(var_0_6:getHeroBook(arg_13_1)) do
		if arg_13_0.eventCentre.allBooks[iter_13_1] then
			if arg_13_0.eventCentre.allBooks[iter_13_1].type == xyd.BookType.CREATS then
				table.insert(var_13_0, arg_13_0.eventCentre.allBooks[iter_13_1])
			elseif arg_13_0.eventCentre.allBooks[iter_13_1].type == xyd.BookType.WORKING then
				table.insert(var_13_2, arg_13_0.eventCentre.allBooks[iter_13_1])
			elseif arg_13_0.eventCentre.allBooks[iter_13_1].type == xyd.BookType.PIECE then
				table.insert(var_13_1, arg_13_0.eventCentre.allBooks[iter_13_1])
			elseif arg_13_0.eventCentre.allBooks[iter_13_1].type == xyd.BookType.UNCOLLECTED then
				table.insert(var_13_4, arg_13_0.eventCentre.allBooks[iter_13_1])
			else
				table.insert(var_13_3, arg_13_0.eventCentre.allBooks[iter_13_1])
			end
		end
	end

	arg_13_0.bookData = {}

	if #var_13_0 > 0 then
		arg_13_0.book_type = 0

		local var_13_5 = {
			type = 0,
			subList = var_13_0
		}

		table.insert(arg_13_0.bookData, var_13_5)
	end

	if #var_13_2 > 0 then
		if #var_13_0 <= 0 then
			arg_13_0.book_type = 1
		end

		local var_13_6 = {
			type = 1,
			subList = var_13_2
		}

		table.insert(arg_13_0.bookData, var_13_6)
	end

	if #var_13_1 > 0 then
		if #var_13_2 <= 0 then
			arg_13_0.book_type = 2
		end

		local var_13_7 = {
			type = 2,
			subList = var_13_1
		}

		table.insert(arg_13_0.bookData, var_13_7)
	end

	if #var_13_4 > 0 then
		if #var_13_2 <= 0 then
			arg_13_0.book_type = 4
		end

		local var_13_8 = {
			type = 4,
			subList = var_13_4
		}

		table.insert(arg_13_0.bookData, var_13_8)
	end

	if #var_13_3 > 0 then
		if #var_13_2 <= 0 and #var_13_1 <= 0 then
			arg_13_0.book_type = 3
		end

		local var_13_9 = {
			type = 3,
			subList = var_13_3
		}

		table.insert(arg_13_0.bookData, var_13_9)
	end
end

function var_0_0.clickAvatar(arg_14_0, arg_14_1)
	arg_14_0.isSelectHero = true
	arg_14_0.selectHeroId = arg_14_1

	arg_14_0:avatarUpdateLeft(arg_14_1)
	arg_14_0:updateLeftContainer()
end

function var_0_0.layout(arg_15_0)
	arg_15_0:nodeByName("txt_cancel"):setString(var_0_2:translation("CANCEL"))
	arg_15_0:nodeByName("txt_accelerate1"):setString(var_0_2:translation("EVENT_CENTRE_TIP2"))
	arg_15_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.CABINET))
	arg_15_0:nodeByName("txt_working"):setString(var_0_2:translation("EVENT_CENTRE_TIP6"))
	arg_15_0:nodeByName("txt_working2"):setString(var_0_2:translation("EVENT_CENTRE_TIP8"))
	arg_15_0:nodeByName("txt_compose"):setString(var_0_2:translation("FRAGMENT_COMPOSE"))
	arg_15_0:nodeByName("txt_detail"):setString(var_0_2:translation("BACKPACK_TEXT_1"))
	arg_15_0:nodeByName("txt_accelerate2"):setString(var_0_2:translation("EVENT_CENTRE_TIP2"))
	arg_15_0:nodeByName("txt_cancel_select"):setString(var_0_2:translation("EVENT_CENTRE_TIP7"))
	arg_15_0:nodeByName("txt_lev_up"):setString(var_0_2:translation("HERO_MAIN_TEXT_13"))
	arg_15_0:nodeByName("txt_search"):setString(var_0_2:translation("HERO_LIST_BTN_FILTER"))
	arg_15_0:nodeByName("icon_words"):setString(var_0_2:translation("EFFECT_HERO"))
	arg_15_0:nodeByName("working_container"):setVisible(false)
	arg_15_0:nodeByName("time_container"):setVisible(false)
	arg_15_0:nodeByName("btn_working2"):setVisible(false)
	arg_15_0:nodeByName("cancel_select_btn"):setVisible(false)
	arg_15_0:nodeByName("writer_words"):setString(var_0_2:translation("AUTHOR"))
	arg_15_0:nodeByName("des_words"):setString(var_0_2:translation("FIRST_RECHARGE_DESC"))
	arg_15_0:nodeByName("txt_num"):setString(arg_15_0.eventCentre.cabinetLev)
	arg_15_0:nodeByName("bar_time_progress"):setPercent(0)
	arg_15_0:nodeByName("btn_lev_up"):setTouchEnabled(true)
	arg_15_0:nodeByName("btn_lev_up"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_15_0:nodeByName("btn_lev_up"), arg_16_1)

		if arg_16_1 == ccui.TouchEventType.began then
			return true
		elseif arg_16_1 == ccui.TouchEventType.ended then
			if arg_15_0.eventCentre.cabinetLev == var_0_10 then
				local var_16_0 = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.CABINET)
				local var_16_1 = string.format(var_0_2:translation("HIGHEST_LEV"), var_16_0)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_16_1
				})

				return
			end

			if arg_15_0.eventCentre.skillNeedTime ~= 0 then
				local var_16_2 = var_0_2:translation("ON_LEARNING_CANNOT_UPGRADE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_16_2
				})

				return
			end

			if arg_15_0.eventCentre.cabinetNeedTime > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_2:translation("BUILDING_LEVING_UP"), xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.CABINET))
				})
			else
				local var_16_3 = {
					type = xyd.EventCentreBuildingType.CABINET,
					lev = arg_15_0.eventCentre.cabinetLev
				}

				xyd.WindowManager.get():openWindow("event_centre_upgrade", var_16_3)
			end

			return true
		end
	end)
	arg_15_0:nodeByName("btn_search"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_15_0:nodeByName("btn_search"), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_17_0(arg_18_0)
				arg_15_0:clickAvatar(arg_18_0)
				arg_15_0:nodeByName("cancel_select_btn"):setVisible(true)
			end

			if not arg_15_0.isInitAvatar then
				arg_15_0:getAllHeros()

				arg_15_0.isInitAvatar = true
			end

			xyd.WindowManager.get():openWindow("junk_chest_select_hero", {
				heros = arg_15_0.heros,
				callback = var_17_0
			})
		end

		return true
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("cancel_select_btn"), nil, function(arg_19_0)
		xyd.playButtonSound()

		arg_15_0.isSelectHero = false
		arg_15_0.clickAvatarId = nil

		if arg_15_0.clickCell and not tolua.isnull(arg_15_0.clickCell) then
			arg_15_0.clickCell:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(false)
			arg_15_0.clickCell:getChildByName("layout"):getChildByName("chosen"):setVisible(false)

			arg_15_0.clickCell.isAnimated_ = false

			arg_15_0:nodeByName("select_avatar"):removeAllChildren()
		end

		arg_15_0:updateBookList()
		arg_15_0:updateLeftContainer()
		arg_15_0:nodeByName("cancel_select_btn"):setVisible(false)
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("plus"), nil, function(arg_20_0)
		xyd.playButtonSound()
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("GIVE_UP_SKILL_ALERT"), function()
			local var_21_0 = {
				skill_id = arg_15_0.eventCentre.curLearnSkill
			}

			arg_15_0.eventCentre:giveUpLearnSkill(var_21_0, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					arg_15_0.eventCentre.recentCompleteSkill = arg_15_0.theId

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.REFRESH_MAGIC_RES
					})

					if arg_22_1.return_skillpage then
						arg_15_0.backpack:addItemsByID(arg_15_0.currentlearnskillpageid, arg_22_1.return_skillpage)
					end

					for iter_22_0, iter_22_1 in pairs(arg_15_0.eventCentre.workingBook) do
						if iter_22_1.id == arg_15_0.bookId then
							arg_15_0.book = iter_22_1
							arg_15_0.book_type = 1
							arg_15_0.index_ = iter_22_0

							break
						end
					end

					for iter_22_2, iter_22_3 in pairs(arg_15_0.eventCentre.creatsBook) do
						if iter_22_3.id == arg_15_0.bookId then
							arg_15_0.book = iter_22_3
							arg_15_0.book_type = 0
							arg_15_0.index_ = iter_22_2

							break
						end
					end

					for iter_22_4, iter_22_5 in pairs(arg_15_0.eventCentre.overBook) do
						if iter_22_5.id == arg_15_0.bookId then
							arg_15_0.book = iter_22_5
							arg_15_0.book_type = 3
							arg_15_0.index_ = iter_22_4

							break
						end
					end

					if arg_15_0.book then
						arg_15_0:updateMainContainer(arg_15_0.book.skills, arg_15_0.book.star, arg_15_0.book.id)
					end

					arg_15_0.startBookType = arg_15_0.book_type

					arg_15_0:checkSkillTime()
					arg_15_0:updateLeftContainer(3)
					arg_15_0:refreshBottomContainer()

					return true
				end
			end)
		end, nil, nil, xyd.ColorMode.GREEN)
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("clear_btn"), nil, function(arg_23_0)
		xyd.playButtonSound()

		local var_23_0 = string.format(var_0_2:translation("FINISH_SKILL_INMMEDIATELY"), arg_15_0.cost)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_23_0, function()
			if arg_15_0.cost > arg_15_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_25_0 = {}

					var_25_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_25_0)
				end, nil, nil, xyd.ColorMode.GREEN)
			else
				local var_24_0 = {
					skill_id = arg_15_0.eventCentre.curLearnSkill
				}

				arg_15_0.eventCentre:speedUpSkill(var_24_0, function(arg_26_0, arg_26_1)
					if arg_26_0 == xyd.error.OK then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})

						for iter_26_0, iter_26_1 in pairs(arg_15_0.eventCentre.workingBook) do
							if iter_26_1.id == arg_15_0.bookId then
								arg_15_0.book = iter_26_1
								arg_15_0.book_type = 1
								arg_15_0.index_ = iter_26_0

								break
							end
						end

						for iter_26_2, iter_26_3 in pairs(arg_15_0.eventCentre.creatsBook) do
							if iter_26_3.id == arg_15_0.bookId then
								arg_15_0.book = iter_26_3
								arg_15_0.book_type = 0
								arg_15_0.index_ = iter_26_2

								break
							end
						end

						for iter_26_4, iter_26_5 in pairs(arg_15_0.eventCentre.overBook) do
							if iter_26_5.id == arg_15_0.bookId then
								arg_15_0.book = iter_26_5
								arg_15_0.book_type = 3
								arg_15_0.index_ = iter_26_4

								break
							end
						end

						arg_15_0.startBookType = arg_15_0.book_type

						if arg_15_0.book then
							arg_15_0:updateMainContainer(arg_15_0.book.skills, arg_15_0.book.star, arg_15_0.book.id)
						end

						arg_15_0:checkSkillTime()
						arg_15_0:updateLeftContainer(3)
						arg_15_0:refreshBottomContainer()
						arg_15_0:nodeByName("btn_working"):setTouchEnabled(true)

						return true
					end
				end)
			end
		end, nil, 0, xyd.ColorMode.GREEN)
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("detail_btn"), nil, function(arg_27_0)
		xyd.playButtonSound()

		local var_27_0 = {
			bookId = arg_15_0.bookId
		}

		xyd.WindowManager.get():openWindow("junk_chest_piece_detail", var_27_0)
	end)
	arg_15_0:nodeByName("chest_time_btn"):addTouchEventListener(function(arg_28_0, arg_28_1)
		xyd.buttonScaleAnim(arg_15_0:nodeByName("chest_time_btn"), arg_28_1)

		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_28_0 = arg_15_0.eventCentre.cabinetNeedTime - (xyd.ServerTime.get():getServerTime() - arg_15_0.eventCentre.cabinetStartTime)
			local var_28_1 = arg_15_0.eventCentre:getUpgradeCost(var_28_0)
			local var_28_2 = string.format(var_0_2:translation("COST_TO_UPGRADE"), var_28_1, arg_15_0.cabinetLev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_28_2, function()
				if var_28_1 > arg_15_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
						local var_30_0 = {}

						var_30_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_30_0)
					end, nil, nil, xyd.ColorMode.GREEN)
				else
					local var_29_0 = {
						type = xyd.EventCentreBuildingType.CABINET
					}

					arg_15_0.eventCentre:speedUpBuilding(var_29_0, function(arg_31_0, arg_31_1)
						if arg_31_0 == xyd.error.OK then
							arg_15_0.eventCentre.cabinetStartTime = 0
							arg_15_0.eventCentre.cabinetNeedTime = 0
							arg_15_0.eventCentre.cabinetLev = arg_31_1.lev
							arg_15_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.CABINET].lev = arg_15_0.eventCentre.cabinetLev

							arg_15_0:updateUpgradeTime()
							arg_15_0:openBuildingLevupWindow()
						end
					end)
				end
			end, nil, 0, xyd.ColorMode.GREEN)
		end

		return true
	end)
	arg_15_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		xyd.buttonScaleAnim(arg_15_0:nodeByName("cancel_btn"), arg_32_1)

		if arg_32_1 == ccui.TouchEventType.ended then
			local var_32_0 = var_0_2:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_32_0, function()
				local var_33_0 = {
					type = xyd.EventCentreBuildingType.CABINET
				}

				arg_15_0.eventCentre:cancelEvolveBuilding(var_33_0, function(arg_34_0, arg_34_1)
					if arg_34_0 == xyd.error.OK then
						arg_15_0.eventCentre.cabinetStartTime = arg_34_1.building_info.start_time
						arg_15_0.eventCentre.cabinetNeedTime = arg_34_1.building_info.need_time
						arg_15_0.eventCentre.cabinetLev = arg_34_1.building_info.lev
						arg_15_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.CABINET].lev = arg_15_0.eventCentre.cabinetLev

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
						arg_15_0:updateUpgradeTime()

						local var_34_0 = {
							resolve_types = arg_34_1.return_res_id,
							resolve_nums = arg_34_1.return_res_num,
							resolve_crits = {}
						}

						xyd.WindowManager.get():openWindow("recycle_award", var_34_0)
					end
				end)
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("compose_btn"), nil, function(arg_35_0)
		xyd.playButtonSound()

		if var_0_6:star(arg_15_0.bookId) > arg_15_0.eventCentre.cabinetLev then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("JUNK_CHEST_LEV_LOW")
			})
		else
			xyd.WindowManager.get():openWindow("fragment_make", {
				itemID = var_0_6:piece(arg_15_0.bookId)
			})
		end
	end)

	if arg_15_0.eventCentre.cabinetNewEvolve and arg_15_0.eventCentre.cabinetNewEvolve == 1 then
		arg_15_0:openBuildingLevupWindow()
	end

	arg_15_0:checkSkillTime()
	arg_15_0:updateUpgradeTime()

	if arg_15_0.eventCentre.recentCompleteSkill and arg_15_0.eventCentre.recentCompleteSkill ~= 0 then
		arg_15_0.eventCentre:confirmSkillUpgrade({}, function(arg_36_0, arg_36_1)
			if arg_36_0 == xyd.error.OK then
				return true
			end
		end)
	end
end

function var_0_0.openBuildingLevupWindow(arg_37_0)
	local var_37_0 = {
		type = xyd.EventCentreBuildingType.CABINET
	}

	arg_37_0.eventCentre:confirmBuildingUpgrade(var_37_0, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			local var_38_0 = {
				type = xyd.EventCentreBuildingType.CABINET,
				lev = arg_37_0.eventCentre.cabinetLev
			}

			xyd.WindowManager.get():openWindow("building_levelup", var_38_0)

			arg_37_0.eventCentre.cabinetNewEvolve = 0
		end
	end)
end

function var_0_0.updateUpgradeTime(arg_39_0)
	if arg_39_0.handle1 then
		var_0_1.unscheduleGlobal(arg_39_0.handle1)

		arg_39_0.handle1 = nil
	end

	local var_39_0

	if arg_39_0.eventCentre.cabinetStartTime > 0 then
		var_39_0 = arg_39_0.eventCentre.cabinetNeedTime - (xyd.ServerTime.get():getServerTime() - arg_39_0.eventCentre.cabinetStartTime)

		arg_39_0:nodeByName("top_container"):setVisible(true)
		arg_39_0:nodeByName("chest_time_text"):setString(xyd.secondsToString1(var_39_0))
		arg_39_0:nodeByName("btn_lev_up"):setVisible(false)
	else
		var_39_0 = 0

		arg_39_0:nodeByName("top_container"):setVisible(false)
		arg_39_0:nodeByName("btn_lev_up"):setVisible(true)
	end

	if var_39_0 > 0 then
		arg_39_0:nodeByName("top_container"):setVisible(true)

		arg_39_0.handle1 = var_0_1.scheduleGlobal(function()
			var_39_0 = var_39_0 - 1

			if not tolua.isnull(arg_39_0) then
				arg_39_0:nodeByName("chest_time_text"):setString(xyd.secondsToString1(var_39_0))
				arg_39_0:nodeByName("btn_lev_up"):setVisible(false)

				local var_40_0 = (1 - var_39_0 / arg_39_0.eventCentre.cabinetNeedTime) * 100

				arg_39_0:nodeByName("bar_time_progress"):setPercent(math.min(100, var_40_0))
			end

			if var_39_0 <= 0 and arg_39_0.handle1 then
				arg_39_0.eventCentre.cabinetLev = arg_39_0.eventCentre.cabinetLev + 1
				arg_39_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.CABINET].lev = arg_39_0.eventCentre.cabinetLev
				arg_39_0.eventCentre.cabinetNeedTime = 0
				arg_39_0.eventCentre.cabinetStartTime = 0

				var_0_1.unscheduleGlobal(arg_39_0.handle1)

				arg_39_0.handle1 = nil

				if not tolua.isnull(arg_39_0) then
					arg_39_0:nodeByName("btn_lev_up"):setVisible(true)
					arg_39_0:nodeByName("top_container"):setVisible(false)
					arg_39_0:nodeByName("bar_time_progress"):setPercent(0)
				end
			end
		end, 1)
	else
		arg_39_0:nodeByName("top_container"):setVisible(false)
		arg_39_0:nodeByName("btn_lev_up"):setVisible(true)

		if arg_39_0.handle1 then
			var_0_1.unscheduleGlobal(arg_39_0.handle1)

			arg_39_0.handle1 = nil
		end
	end

	if arg_39_0.eventCentre.cabinetLev ~= arg_39_0.cabinetLev then
		arg_39_0.cabinetLev = arg_39_0.eventCentre.cabinetLev

		arg_39_0:nodeByName("txt_num"):setString(arg_39_0.eventCentre.cabinetLev)
	end
end

function var_0_0.updateBookList(arg_41_0)
	arg_41_0.bookData = {}

	if #arg_41_0.eventCentre.creatsBook > 0 then
		arg_41_0.book_type = 0

		local var_41_0 = {
			type = 0,
			subList = arg_41_0.eventCentre.creatsBook
		}

		table.insert(arg_41_0.bookData, var_41_0)
	end

	if #arg_41_0.eventCentre.workingBook > 0 then
		if #arg_41_0.eventCentre.creatsBook <= 0 then
			arg_41_0.book_type = 1
		end

		local var_41_1 = {
			type = 1,
			subList = arg_41_0.eventCentre.workingBook
		}

		table.insert(arg_41_0.bookData, var_41_1)
	end

	if #arg_41_0.eventCentre.pieceBook > 0 then
		if #arg_41_0.eventCentre.workingBook <= 0 then
			arg_41_0.book_type = 2
		end

		local var_41_2 = {
			type = 2,
			subList = arg_41_0.eventCentre.pieceBook
		}

		table.insert(arg_41_0.bookData, var_41_2)
	end

	if #arg_41_0.eventCentre.overBook > 0 then
		if #arg_41_0.eventCentre.workingBook <= 0 and #arg_41_0.eventCentre.pieceBook <= 0 then
			arg_41_0.book_type = 3
		end

		local var_41_3 = {
			type = 3,
			subList = arg_41_0.eventCentre.overBook
		}

		table.insert(arg_41_0.bookData, var_41_3)
	end

	if #arg_41_0.eventCentre.uncollectedBook > 0 then
		if #arg_41_0.eventCentre.workingBook <= 0 and #arg_41_0.eventCentre.pieceBook <= 0 and #arg_41_0.eventCentre.overBook <= 0 then
			arg_41_0.book_type = 4
		end

		local var_41_4 = {
			type = 4,
			subList = arg_41_0.eventCentre.uncollectedBook
		}

		table.insert(arg_41_0.bookData, var_41_4)
	end

	if arg_41_0.startBookType then
		arg_41_0.book_type = arg_41_0.startBookType
		arg_41_0.startBookType = nil
	end

	if arg_41_0.book_type == nil then
		for iter_41_0 = 1, 3 do
			for iter_41_1 = 1, 3 do
				if arg_41_0:nodeByName("line_d_" .. iter_41_0 .. "_" .. iter_41_1) then
					arg_41_0:nodeByName("line_d_" .. iter_41_0 .. "_" .. iter_41_1):setVisible(false)
				end

				if arg_41_0:nodeByName("line" .. iter_41_0 .. "_" .. iter_41_1) then
					arg_41_0:nodeByName("line" .. iter_41_0 .. "_" .. iter_41_1):setVisible(false)
				end

				arg_41_0:nodeByName("line" .. iter_41_0 .. "_" .. iter_41_1 .. "_a"):setVisible(false)
				arg_41_0:nodeByName("line" .. iter_41_0 .. "_" .. iter_41_1 .. "_b"):setVisible(false)
				arg_41_0:nodeByName("line" .. iter_41_0 .. "_" .. iter_41_1 .. "_c"):setVisible(false)
			end
		end

		arg_41_0:nodeByName("piece_container"):setVisible(false)
		arg_41_0:nodeByName("book_des_container"):setVisible(false)
		arg_41_0:nodeByName("working_container"):setVisible(false)
	end
end

function var_0_0.checkSkillTime(arg_42_0)
	if arg_42_0.eventCentre.curLearnSkill == 0 then
		arg_42_0:nodeByName("time_container"):setVisible(false)
		arg_42_0:nodeByName("btn_working"):setVisible(arg_42_0.btnWorkingVisible)
		arg_42_0:nodeByName("btn_working2"):setVisible(false)
	else
		local var_42_0 = xyd.ServerTime.get():getServerTime()

		if arg_42_0.handle_ == nil then
			arg_42_0.handle_ = var_0_1.scheduleGlobal(function(arg_43_0)
				var_42_0 = xyd.ServerTime.get():getServerTime()

				if var_42_0 - arg_42_0.eventCentre.skillStartTime < arg_42_0.eventCentre.skillNeedTime then
					arg_42_0:checkSkillTime()
				else
					arg_42_0:nodeByName("time_container"):setVisible(false)
					arg_42_0:nodeByName("btn_working"):setVisible(arg_42_0.btnWorkingVisible)
					arg_42_0:nodeByName("btn_working"):setTouchEnabled(true)
					arg_42_0:nodeByName("btn_working2"):setVisible(false)

					if arg_42_0.isSelectHero then
						arg_42_0:avatarUpdateLeft(arg_42_0.selectHeroId)
					else
						arg_42_0:updateBookList()
					end

					arg_42_0.eventCentre:levUp(arg_42_0.eventCentre.curLearnSkill)
					arg_42_0:updateLeftContainer(3)
					arg_42_0:refreshBottomContainer()

					if arg_42_0.handle_ then
						var_0_1.unscheduleGlobal(arg_42_0.handle_)

						arg_42_0.handle_ = nil
						arg_42_0.eventCentre.curLearnSkill = 0
						arg_42_0.eventCentre.skillNeedTime = 0
						arg_42_0.eventCentre.skillStartTime = 0

						if arg_42_0.eventCentre.recentCompleteSkill and arg_42_0.eventCentre.recentCompleteSkill ~= 0 then
							arg_42_0.eventCentre:confirmSkillUpgrade({}, function(arg_44_0, arg_44_1)
								if arg_44_0 == xyd.error.OK then
									return true
								end
							end)
						end
					end
				end
			end, 1)
		end

		if arg_42_0.clickSkill and arg_42_0.clickSkill.id == arg_42_0.eventCentre.curLearnSkill then
			arg_42_0:nodeByName("time_container"):setVisible(true)
			arg_42_0:nodeByName("btn_working"):setVisible(false)
			arg_42_0:nodeByName("btn_working2"):setVisible(false)
		end

		arg_42_0:setSkillTime(arg_42_0.eventCentre.skillStartTime + arg_42_0.eventCentre.skillNeedTime - var_42_0)

		if var_42_0 > arg_42_0.eventCentre.skillStartTime + arg_42_0.eventCentre.skillNeedTime then
			arg_42_0:nodeByName("skill_bar"):setPercent(100)
		else
			arg_42_0:nodeByName("skill_bar"):setPercent((var_42_0 - arg_42_0.eventCentre.skillStartTime) / arg_42_0.eventCentre.skillNeedTime * 100)
		end
	end
end

function var_0_0.setSkillTime(arg_45_0, arg_45_1)
	local var_45_0 = math.floor(arg_45_1 / 60) % 60
	local var_45_1 = math.floor(arg_45_1 / 3600)

	if arg_45_1 <= 60 then
		var_45_0 = 1
	end

	arg_45_0:nodeByName("time_txt"):setString(string.format(var_0_2:translation("CABINET_SKILL_TIME"), var_45_1, var_45_0))

	arg_45_0.cost = 0

	if arg_45_1 < 14400 then
		arg_45_0.cost = math.floor(arg_45_1 / 72)
	elseif arg_45_1 <= 43200 then
		arg_45_0.cost = math.floor((arg_45_1 - 14400) / 144 + 200)
	elseif arg_45_1 > 43200 then
		arg_45_0.cost = math.floor((arg_45_1 - 43200) / 432 + 400)
	end

	arg_45_0.cost = math.max(math.ceil(arg_45_0.cost), 1)

	arg_45_0:nodeByName("crystal_num"):setString(arg_45_0.cost)
end

function var_0_0.updateMainContainer(arg_46_0, arg_46_1, arg_46_2, arg_46_3)
	local var_46_0 = {
		{
			0,
			0,
			0
		},
		{
			0,
			0,
			0
		},
		{
			0,
			0,
			0
		},
		{
			0,
			0,
			0
		}
	}

	for iter_46_0 = 1, 3 do
		for iter_46_1 = 1, 3 do
			if arg_46_0:nodeByName("line_d_" .. iter_46_0 .. "_" .. iter_46_1) then
				arg_46_0:nodeByName("line_d_" .. iter_46_0 .. "_" .. iter_46_1):setVisible(false)
			end

			if arg_46_0:nodeByName("line" .. iter_46_0 .. "_" .. iter_46_1) then
				arg_46_0:nodeByName("line" .. iter_46_0 .. "_" .. iter_46_1):setVisible(false)
			end

			arg_46_0:nodeByName("line" .. iter_46_0 .. "_" .. iter_46_1 .. "_a"):setVisible(false)
			arg_46_0:nodeByName("line" .. iter_46_0 .. "_" .. iter_46_1 .. "_b"):setVisible(false)
			arg_46_0:nodeByName("line" .. iter_46_0 .. "_" .. iter_46_1 .. "_c"):setVisible(false)
		end
	end

	for iter_46_2 = 1, 3 do
		for iter_46_3 = 1, 4 do
			arg_46_0:nodeByName("icon" .. iter_46_2 .. "_" .. iter_46_3):removeAllChildren()

			arg_46_0:nodeByName("icon" .. iter_46_2 .. "_" .. iter_46_3).id = 0
		end
	end

	arg_46_0.skills = arg_46_1

	for iter_46_4, iter_46_5 in pairs(arg_46_0.skills) do
		local var_46_1 = var_0_4:posX(iter_46_5.id)
		local var_46_2 = var_0_4:posY(iter_46_5.id)

		var_46_0[var_46_1][var_46_2] = iter_46_5.id

		local var_46_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/skill_item.csb")
		local var_46_4 = cc.p(73, 73)

		var_46_3:setContentSize(var_46_4)

		local var_46_5 = var_46_3:getChildByName("icon")
		local var_46_6 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

		var_46_6:setPosition(var_46_5:getWidth() / 2, var_46_5:getHeight() / 2)
		var_46_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_46_6:scale(var_46_5:getWidth() / var_46_6:getWidth())

		local var_46_7 = cc.ClippingNode:create()

		var_46_7:setStencil(var_46_6)
		var_46_7:setInverted(true)
		var_46_7:setAlphaThreshold(0)
		var_46_5:addChild(var_46_7)

		local var_46_8

		var_46_3:getChildByName("lev_text"):enableOutline(xyd.color.BLACK, 1)

		if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] > 0 then
			var_46_8 = xyd.SpriteLoader.new(var_0_4:icon(iter_46_5.id), nil, nil, xyd.DefaultImageType.SKILL_ICON)

			if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] == arg_46_2 then
				var_46_3:getChildByName("lev_text"):setString(var_0_2:translation("MAX_EN"))
			else
				var_46_3:getChildByName("lev_text"):setString("Lv. " .. arg_46_0.eventCentre.allSkillsLev[iter_46_5.id])
			end

			var_46_3:getChildByName("lev_bg"):setVisible(true)
		else
			local var_46_9 = {
				filter = {}
			}

			var_46_9.filter.name = "GRAY"
			var_46_9.filter.value = {
				0.2,
				0.3,
				0.5,
				0.1
			}
			var_46_8 = xyd.SpriteLoader.new(var_0_4:icon(iter_46_5.id), nil, var_46_9, xyd.DefaultImageType.SKILL_ICON)
		end

		var_46_7:addChild(var_46_8)
		var_46_8:align(display.LEFT_BOTTOM, 0, 0)
		var_46_8:scale((var_46_5:getWidth() - 3) / var_46_8:getWidth())
		var_46_3:scale(0.65, 0.65)
		arg_46_0:nodeByName("icon" .. var_46_2 .. "_" .. var_46_1):addChild(var_46_3)

		arg_46_0:nodeByName("icon" .. var_46_2 .. "_" .. var_46_1).id = iter_46_5.id

		var_46_3:setTouchEnabled(true)
		var_46_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_47_0)
			if arg_47_0.name == "began" then
				var_46_3:setScale(0.5850000000000001)

				return true
			elseif arg_47_0.name == "ended" then
				var_46_3:setScale(0.65)

				arg_46_0.clickSkill = iter_46_5

				if not tolua.isnull(arg_46_0.effect) and arg_46_0.effect then
					transition.stopTarget(arg_46_0.effect)
					arg_46_0.effect:removeSelf()

					arg_46_0.effect = nil
				end

				arg_46_0.effect = xyd.AssetLoader:get():loadSprite("windows/event_centre/bg_select.png")

				arg_46_0.effect:setAnchorPoint(cc.p(0.5, 0.5))

				local var_47_0 = var_46_3:getContentSize()

				arg_46_0.effect:setPosition(var_47_0.width / 2, var_47_0.height / 2)
				arg_46_0.effect:addTo(var_46_3)

				local var_47_1 = transition.sequence({
					cc.ScaleTo:create(0.3, 1.04),
					cc.ScaleTo:create(0.3, 1)
				})
				local var_47_2 = cc.RepeatForever:create(var_47_1)

				arg_46_0.effect:runAction(var_47_2)
				arg_46_0:nodeByName("working_container"):setVisible(true)
				arg_46_0:nodeByName("book_des_container"):setVisible(false)
				arg_46_0:nodeByName("piece_container"):setVisible(false)

				local var_47_3 = arg_46_0:nodeByName("hero_icon")

				var_47_3:removeAllChildren()

				local var_47_4 = var_0_4:partner(iter_46_5.id)
				local var_47_5 = arg_46_0.selfPlayer:getHeroIgnoreAwaken(var_47_4)

				if var_47_5 then
					xyd.setAvatarBorderNewUI(var_47_5, var_47_3, var_47_5:getColor(), var_47_5:getStar())
				else
					xyd.setAvatarBorderNewUI(var_47_4, var_47_3, 1, 0)
				end

				local var_47_6 = var_47_3:getContentSize()
				local var_47_7 = display.newNode()

				var_47_7:addTo(var_47_3)
				var_47_7:setContentSize(var_47_6.width, var_47_6.height)
				xyd.addTips(var_47_7, {
					id = var_47_4
				})
				arg_46_0:nodeByName("hero_name"):setString(var_0_3:name(var_47_4))
				arg_46_0:nodeByName("intel_words"):setString(var_0_4:name(iter_46_5.id))
				arg_46_0:nodeByName("lv_text"):setString(arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] .. "/" .. arg_46_2)

				if arg_46_0.selfPlayer:getBackpack():getItemNumByID(arg_46_3) > 0 then
					if arg_46_2 == arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] then
						arg_46_0.btnWorkingVisible = false
					else
						arg_46_0.btnWorkingVisible = true
					end
				else
					arg_46_0.btnWorkingVisible = false
				end

				if arg_46_0.eventCentre.curLearnSkill ~= 0 then
					if arg_46_0.clickSkill.id == arg_46_0.eventCentre.curLearnSkill then
						arg_46_0:nodeByName("time_container"):setVisible(true)
						arg_46_0:nodeByName("btn_working"):setVisible(false)
						arg_46_0:nodeByName("btn_working2"):setVisible(false)
					else
						arg_46_0:nodeByName("time_container"):setVisible(false)
						arg_46_0:nodeByName("btn_working"):setVisible(arg_46_0.btnWorkingVisible)
						arg_46_0:nodeByName("btn_working2"):setVisible(true)
					end
				else
					arg_46_0:nodeByName("btn_working"):setVisible(arg_46_0.btnWorkingVisible)
					arg_46_0:nodeByName("btn_working2"):setVisible(false)
				end

				arg_46_0:nodeByName("btn_working"):addTouchEventListener(function(arg_48_0, arg_48_1)
					xyd.buttonScaleAnim(arg_46_0:nodeByName("btn_working"), arg_48_1)

					if arg_48_1 == ccui.TouchEventType.began then
						xyd.playButtonSound()

						if arg_46_0.eventCentre.skillNeedTime <= 0 and arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] < arg_46_2 then
							local var_48_0 = true
							local var_48_1 = {
								1,
								1,
								1,
								1,
								1
							}
							local var_48_2 = {}

							for iter_48_0, iter_48_1 in pairs(var_0_4:lastSkill(iter_46_5.id)) do
								if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] >= arg_46_0.eventCentre.allSkillsLev[iter_48_1] then
									var_48_0 = false
									var_48_2[iter_48_0] = 1
								else
									var_48_2[iter_48_0] = 0
								end
							end

							for iter_48_2, iter_48_3 in pairs(var_0_5:getResType(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)) do
								if iter_48_3 == xyd.currencyType.MAGIC_DUST and arg_46_0.selfPlayer.magicDust < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_2] then
									var_48_0 = false
									var_48_1[iter_48_2] = 0
								elseif iter_48_3 == xyd.currencyType.MAGIC_LIQUID and arg_46_0.selfPlayer.magicLiquid < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_2] then
									var_48_0 = false
									var_48_1[iter_48_2] = 0
								elseif iter_48_3 == xyd.currencyType.MAGIC_ENERGY and arg_46_0.selfPlayer.magicEnergy < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_2] then
									var_48_0 = false
									var_48_1[iter_48_2] = 0
								elseif iter_48_3 == xyd.currencyType.MANA and arg_46_0.selfPlayer.mana < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_2] then
									var_48_0 = false
									var_48_1[iter_48_2] = 0
								elseif iter_48_3 == -1 and arg_46_0.selfPlayer:getBackpack():getItemNumByID(var_0_6:skillPage(var_0_4:skillbook(iter_46_5.id))) < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_2] then
									var_48_0 = false
									var_48_1[iter_48_2] = 0
								end
							end

							local var_48_3 = {
								iconType = var_48_2,
								redArr = var_48_1,
								resType = var_0_5:getResType(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1),
								resNum = var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1),
								lastId = var_0_4:lastSkill(iter_46_5.id),
								lev = arg_46_0.eventCentre.allSkillsLev[iter_46_5.id],
								skillPageId = var_0_6:skillPage(var_0_4:skillbook(iter_46_5.id))
							}

							if var_48_0 == false then
								xyd.WindowManager.get():openWindow("junk_chest_skill_alert", var_48_3):setPosition(695, 145)
							end
						end
					elseif arg_48_1 == 3 then
						xyd.WindowManager.get():closeWindow("junk_chest_skill_alert")
					elseif arg_48_1 == ccui.TouchEventType.ended then
						xyd.WindowManager.get():closeWindow("junk_chest_skill_alert")

						if arg_46_0.eventCentre.skillNeedTime <= 0 then
							if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] < arg_46_2 then
								local var_48_4 = true

								if #var_0_4:lastSkill(iter_46_5.id) ~= 0 then
									for iter_48_4, iter_48_5 in pairs(var_0_4:lastSkill(iter_46_5.id)) do
										if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] >= arg_46_0.eventCentre.allSkillsLev[iter_48_5] then
											var_48_4 = false

											break
										end
									end
								end

								if var_48_4 == true then
									for iter_48_6, iter_48_7 in pairs(var_0_5:getResType(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)) do
										if iter_48_7 == xyd.currencyType.MAGIC_DUST and arg_46_0.selfPlayer.magicDust < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_6] then
											var_48_4 = false

											break
										elseif iter_48_7 == xyd.currencyType.MAGIC_LIQUID and arg_46_0.selfPlayer.magicLiquid < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_6] then
											var_48_4 = false

											break
										elseif iter_48_7 == xyd.currencyType.MAGIC_ENERGY and arg_46_0.selfPlayer.magicEnergy < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_6] then
											var_48_4 = false

											break
										elseif iter_48_7 == xyd.currencyType.MANA and arg_46_0.selfPlayer.mana < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_6] then
											var_48_4 = false

											break
										elseif iter_48_7 == -1 and arg_46_0.selfPlayer:getBackpack():getItemNumByID(var_0_6:skillPage(var_0_4:skillbook(iter_46_5.id))) < var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1)[iter_48_6] then
											var_48_4 = false

											break
										end
									end
								end

								if var_48_4 == true then
									if arg_46_0.eventCentre.cabinetNeedTime == 0 then
										if arg_46_0.eventCentre.cabinetLev < arg_46_2 then
											xyd.WindowManager.get():openWindow("toast", {
												message = var_0_2:translation("JUNK_CHEST_LEV_LOW2")
											})
										else
											local var_48_5 = {
												resType = var_0_5:getResType(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1),
												resNum = var_0_5:getResNum(var_0_4:costResType(iter_46_5.id), arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] + 1),
												theId = iter_46_5.id,
												lev = arg_46_0.eventCentre.allSkillsLev[iter_46_5.id],
												skillPageId = var_0_6:skillPage(var_0_4:skillbook(iter_46_5.id))
											}

											arg_46_0.currentlearnskillpageid = var_48_5.skillPageId

											xyd.WindowManager.get():openWindow("junk_chest_skill_up", var_48_5)
										end
									else
										xyd.WindowManager.get():openWindow("toast", {
											message = var_0_2:translation("ON_UPGRADE_CANNOT_LEARN")
										})
									end
								end
							end
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("BOOK_IS_WORKING")
							})
						end
					end
				end)

				if arg_46_0.eventCentre.allSkillsLev[iter_46_5.id] > 0 then
					arg_46_0:nodeByName("des_text"):setString(string.format(var_0_4:desc2(iter_46_5.id), var_0_4:attrValues(iter_46_5.id) * arg_46_0.clickSkill.lev))
				else
					arg_46_0:nodeByName("des_text"):setString(var_0_4:desc(iter_46_5.id))
				end

				if arg_46_0.eventCentre.skillNeedTime <= 0 then
					arg_46_0:nodeByName("btn_working"):setTouchEnabled(true)
				else
					arg_46_0:nodeByName("btn_working"):setTouchEnabled(false)
				end

				return true
			end
		end)

		for iter_46_6, iter_46_7 in ipairs(var_0_4:afterSkill(iter_46_5.id)) do
			if iter_46_7 ~= 0 then
				local var_46_10 = var_0_4:posX(iter_46_7)
				local var_46_11 = var_0_4:posY(iter_46_7)

				arg_46_0:nodeByName("line" .. var_46_1 .. "_" .. var_46_2 .. "_a"):setVisible(true)

				local var_46_12 = var_46_1

				while var_46_12 < var_46_10 do
					if var_46_12 + 1 == var_46_10 then
						arg_46_0:nodeByName("line" .. var_46_12 .. "_" .. var_46_11 .. "_c"):setVisible(true)
					else
						arg_46_0:nodeByName("line" .. var_46_12 .. "_" .. var_46_11 .. "_b"):setVisible(true)
						arg_46_0:nodeByName("line" .. var_46_12 + 1 .. "_" .. var_46_11 .. "_a"):setVisible(true)
						arg_46_0:nodeByName("line" .. var_46_12 + 1 .. "_" .. var_46_11):setVisible(true)
					end

					var_46_12 = var_46_12 + 1
				end

				local var_46_13 = var_46_2

				while var_46_13 ~= var_46_11 do
					if var_46_13 < var_46_11 then
						arg_46_0:nodeByName("line_d_" .. var_46_1 .. "_" .. var_46_11 - 1):setVisible(true)

						var_46_13 = var_46_13 + 1
					elseif var_46_11 < var_46_13 then
						arg_46_0:nodeByName("line_d_" .. var_46_1 .. "_" .. var_46_13 - 1):setVisible(true)

						var_46_13 = var_46_13 - 1
					end
				end
			end
		end
	end
end

function var_0_0.refreshBottomContainer(arg_49_0)
	for iter_49_0, iter_49_1 in pairs(arg_49_0.book.skills) do
		if arg_49_0.clickSkill and iter_49_1.id == arg_49_0.clickSkill.id then
			arg_49_0.clickSkill = iter_49_1

			break
		end
	end

	if arg_49_0.clickSkill then
		if arg_49_0.book and arg_49_0.selfPlayer:getBackpack():getItemNumByID(arg_49_0.book.id) > 0 then
			if arg_49_0.book.star == arg_49_0.clickSkill.lev then
				arg_49_0.btnWorkingVisible = false
			else
				arg_49_0.btnWorkingVisible = true
			end
		else
			arg_49_0.btnWorkingVisible = false
		end

		arg_49_0:nodeByName("btn_working"):setVisible(arg_49_0.btnWorkingVisible)
		arg_49_0:nodeByName("lv_text"):setString(arg_49_0.clickSkill.lev .. "/" .. arg_49_0.book.star)

		if arg_49_0.clickSkill.lev > 0 then
			arg_49_0:nodeByName("des_text"):setString(string.format(var_0_4:desc2(arg_49_0.clickSkill.id), var_0_4:attrValues(arg_49_0.clickSkill.id) * arg_49_0.clickSkill.lev))
		else
			arg_49_0:nodeByName("des_text"):setString(var_0_4:desc(arg_49_0.clickSkill.id))
		end
	end
end

function var_0_0.didOpen(arg_50_0, arg_50_1)
	var_0_0.super:didOpen(arg_50_1)
	arg_50_0:nodeByName("close"):addTouchEventListener(function(arg_51_0, arg_51_1)
		if arg_51_1 == ccui.TouchEventType.ended then
			local var_51_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_51_0, false)
			xyd.WindowManager.get():closeWindow(arg_50_0)
		end
	end)
	arg_50_0:addBlockLayer()
end

function var_0_0.willClose(arg_52_0, arg_52_1)
	var_0_0.super:willClose(arg_52_1)
	xyd.WindowManager.get():closeWindow("junk_chest_skill_alert")

	if arg_52_0.handle_ then
		var_0_1.unscheduleGlobal(arg_52_0.handle_)
	end

	if arg_52_0.handle1 then
		var_0_1.unscheduleGlobal(arg_52_0.handle1)

		arg_52_0.handle1 = nil
	end

	if arg_52_0.playMoveHandle then
		var_0_1.unscheduleGlobal(arg_52_0.playMoveHandle)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.UPDATE_HERO_BOOK
	})
end

return var_0_0
