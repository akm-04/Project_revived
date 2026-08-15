local var_0_0 = class("PetTuJianWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation

var_0_0.LEFT = "left_btn"
var_0_0.RIGHT = "right_btn"
LISTTOTAL = 12

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.left = arg_2_0:nodeByName(var_0_0.LEFT)
	arg_2_0.right = arg_2_0:nodeByName(var_0_0.RIGHT)

	arg_2_0:initPetTables()
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.pageText_ = arg_3_0:nodeByName("page_text")

	arg_3_0.pageText_:enableShadow(cc.c4b(69, 46, 18, 20))

	local var_3_0 = #arg_3_0.selfPlayer.collectedPets
	local var_3_1 = #arg_3_0.totalHero_
	local var_3_2 = 0
	local var_3_3 = var_3_0 / var_3_1 * 100

	if var_3_3 <= 99 then
		var_3_2 = math.ceil(var_3_3)
	else
		var_3_2 = math.floor(var_3_3)
	end

	arg_3_0:nodeByName("txt_now"):setString(var_3_0)
	arg_3_0:nodeByName("txt_all"):setString(var_3_1)
	arg_3_0:nodeByName("txt_percentage"):setString(var_3_2 .. "%")
	arg_3_0:switchHeroGroup()
	arg_3_0:setFlipButtonListener()
end

function var_0_0.initPetTables(arg_4_0)
	arg_4_0.totalHero_ = {}
	arg_4_0.totalIDs_ = {}

	if arg_4_0.selfPlayer.collectedPets == nil then
		arg_4_0.selfPlayer.collectedPets = {}
	end

	for iter_4_0, iter_4_1 in pairs(arg_4_0.selfPlayer.collectedPets) do
		table.insert(arg_4_0.totalHero_, iter_4_1)

		arg_4_0.totalIDs_[iter_4_1:getTableID()] = iter_4_1
	end

	for iter_4_2, iter_4_3 in pairs(xyd.tables.hero:getPetsIgnoreShow()) do
		if arg_4_0.totalIDs_[iter_4_3] == nil and xyd.tables.hero:beforeAwaken(iter_4_3) == 0 and xyd.tables.hero:isLibraryShow(iter_4_3) and arg_4_0.totalIDs_[xyd.tables.hero:afterAwaken(iter_4_3)] == nil then
			local var_4_0 = var_0_2.new()

			var_4_0:initUnCollected(iter_4_3)

			arg_4_0.totalIDs_[iter_4_3] = var_4_0

			table.insert(arg_4_0.totalHero_, var_4_0)
		end
	end

	arg_4_0:sortTables()
end

function var_0_0.sortTables(arg_5_0)
	table.sort(arg_5_0.totalHero_, function(arg_6_0, arg_6_1)
		if arg_6_0:isCollected() == arg_6_1:isCollected() then
			return arg_6_0:getTableID() < arg_6_1:getTableID()
		else
			return arg_6_0:isCollected()
		end
	end)
end

function var_0_0.loadHero(arg_7_0)
	if arg_7_0.currentIdx <= 1 then
		arg_7_0:nodeByName(var_0_0.LEFT):setTouchEnabled(false)
		arg_7_0:nodeByName(var_0_0.LEFT):setVisible(false)
	else
		arg_7_0:nodeByName(var_0_0.LEFT):setTouchEnabled(true)
		arg_7_0:nodeByName(var_0_0.LEFT):setVisible(true)
	end

	if #arg_7_0.totalHero_ - arg_7_0.currentIdx < LISTTOTAL then
		arg_7_0:nodeByName(var_0_0.RIGHT):setTouchEnabled(false)
		arg_7_0:nodeByName(var_0_0.RIGHT):setVisible(false)
	else
		arg_7_0:nodeByName(var_0_0.RIGHT):setTouchEnabled(true)
		arg_7_0:nodeByName(var_0_0.RIGHT):setVisible(true)
	end

	if #arg_7_0.totalHero_ - arg_7_0.currentIdx >= LISTTOTAL then
		arg_7_0:showNhero(LISTTOTAL)
	else
		local var_7_0 = #arg_7_0.totalHero_ - arg_7_0.currentIdx + 1

		arg_7_0:showNhero(var_7_0)
	end
end

function var_0_0.showNhero(arg_8_0, arg_8_1)
	for iter_8_0 = 1, arg_8_1 do
		local var_8_0 = arg_8_0:nodeByName("list_" .. iter_8_0)
		local var_8_1 = import("app.windows.TuJianCellPet").new()
		local var_8_2 = {
			hero = arg_8_0.totalHero_[arg_8_0.currentIdx]
		}

		var_8_1:setParams(var_8_2)
		var_8_1:setPosition(0, 13)
		var_8_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_0:addChild(var_8_1)

		local var_8_3 = arg_8_0.currentIdx

		var_8_1:setTouchEnabled(true)
		var_8_1:setTouchSwallowEnabled(true)
		var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				var_8_1.contentView_:nodeByName("container"):setScale(0.9)

				return true
			elseif arg_9_0.name == "ended" then
				var_8_1.contentView_:nodeByName("container"):setScale(1)
				xyd.playButtonSound()

				local var_9_0 = {
					hero = arg_8_0.totalHero_[var_8_3]
				}

				var_8_1:onClick(var_9_0)
			end
		end)

		arg_8_0.currentIdx = arg_8_0.currentIdx + 1
	end

	if arg_8_0.currentIdx > #arg_8_0.totalHero_ then
		if #arg_8_0.totalHero_ % LISTTOTAL == 0 then
			arg_8_0.currentIdx = #arg_8_0.totalHero_ + 1
		else
			arg_8_0.currentIdx = #arg_8_0.totalHero_ - #arg_8_0.totalHero_ % LISTTOTAL + LISTTOTAL + 1
		end
	end
end

function var_0_0.switchHeroGroup(arg_10_0)
	arg_10_0.totalPage = math.ceil(#arg_10_0.totalHero_ / LISTTOTAL)

	if #arg_10_0.totalHero_ == 0 then
		arg_10_0.pageIndex_ = 0
	else
		arg_10_0.pageIndex_ = 1
	end

	arg_10_0.currentIdx = 1

	arg_10_0:refresh()
	arg_10_0:loadHero()
end

function var_0_0.refresh(arg_11_0)
	arg_11_0.pageText_:setString(arg_11_0.pageIndex_ .. "/" .. arg_11_0.totalPage)

	for iter_11_0 = 1, LISTTOTAL do
		arg_11_0:nodeByName("list_" .. iter_11_0):removeAllChildren()
	end
end

function var_0_0.setFlipButtonListener(arg_12_0)
	arg_12_0.left:addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.began then
			arg_12_0:nodeByName(var_0_0.LEFT):setScale(0.9)
		elseif arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_12_0:nodeByName(var_0_0.LEFT):setScale(1)

			arg_12_0.pageIndex_ = arg_12_0.pageIndex_ - 1

			if arg_12_0.pageIndex_ <= 0 then
				arg_12_0.pageIndex_ = 1

				return
			end

			arg_12_0.currentIdx = arg_12_0.currentIdx - LISTTOTAL * 2

			arg_12_0:updateItems()
		end
	end)
	arg_12_0.right:addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_12_0:nodeByName(var_0_0.RIGHT):setScale(0.9)
		elseif arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_12_0:nodeByName(var_0_0.RIGHT):setScale(1)

			arg_12_0.pageIndex_ = arg_12_0.pageIndex_ + 1

			if arg_12_0.pageIndex_ > arg_12_0.totalPage then
				arg_12_0.pageIndex_ = arg_12_0.totalPage

				return
			end

			arg_12_0:updateItems()
		end
	end)
end

function var_0_0.updataHeroShow(arg_15_0)
	arg_15_0.currentIdx = arg_15_0.currentIdx - LISTTOTAL

	arg_15_0:updateItems()
end

function var_0_0.updateItems(arg_16_0)
	arg_16_0:refresh()
	arg_16_0:loadHero()
end

return var_0_0
