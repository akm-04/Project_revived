local var_0_0 = class("PetOtherAttrWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 2
local var_0_3 = 80
local var_0_4 = 5
local var_0_5 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.pet = arg_1_2.pet
	arg_1_0.id = arg_1_2.id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.collectedPets = clone(arg_1_0.selfPlayer.collectedPets)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initSimilarPets()
	arg_2_0:layout()
	arg_2_0:initPetList()
end

function var_0_0.initPetList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("other_pet_container")
	local var_3_1 = var_3_0:getContentSize().width
	local var_3_2 = var_3_0:getContentSize().height

	if math.ceil(#arg_3_0.similarPets / var_0_4) <= 1 then
		var_3_2 = var_3_2 / 2

		arg_3_0:nodeByName("other_pet_container"):setContentSize(var_3_1, var_3_2)
		arg_3_0:nodeByName("other_pet_container"):setPositionY(arg_3_0:nodeByName("other_pet_container"):getPositionY() + 50)

		local var_3_3 = arg_3_0:nodeByName("bg"):getContentSize().width
		local var_3_4 = arg_3_0:nodeByName("bg"):getContentSize().height

		arg_3_0:nodeByName("bg"):setContentSize(var_3_3, var_3_4 - 100)

		local var_3_5 = arg_3_0:nodeByName("self_pet_container"):getPositionY()

		arg_3_0:nodeByName("self_pet_container"):setPositionY(var_3_5 - 50)
	end

	arg_3_0.petList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1, var_3_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.petList:setDelegate(handler(arg_3_0, arg_3_0.delegate))
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.tables.petHolyAttr:icon(arg_4_0.id)
	local var_4_1 = xyd.tables.petHolyAttr:name(arg_4_0.id)
	local var_4_2 = xyd.tables.petHolyAttr:desc(arg_4_0.id)
	local var_4_3 = string.gsub(var_0_1:translation("PET_ATTR_TIPS_2"), "@", "       ")

	arg_4_0:nodeByName("text_top_desc"):setString(string.format(var_0_1:translation("PET_ATTR_TIPS_1"), arg_4_0.pet:getName(), var_4_1))
	arg_4_0:nodeByName("text_mid"):setString(string.format(var_4_3, var_4_1, var_4_2))
	arg_4_0:nodeByName("text_bottom"):setString(string.format(var_0_1:translation("PET_ATTR_TIPS_3"), var_4_1))
	arg_4_0:nodeByName("text_top_name"):setString(var_4_1)

	for iter_4_0 = 1, var_0_2 do
		local var_4_4 = xyd.AssetLoader.get():loadSprite(var_4_0)
		local var_4_5, var_4_6 = arg_4_0:nodeByName("node_" .. iter_4_0):getPosition()

		var_4_4:addTo(arg_4_0:nodeByName("self_pet_container"))
		var_4_4:setPosition(cc.p(var_4_5, var_4_6))

		if iter_4_0 == 2 then
			var_4_4:setScale(0.7)
		end
	end
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = math.ceil(#arg_5_0.similarPets / var_0_4)

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.petList:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.petList:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		for iter_5_0 = 1, var_0_4 do
			local var_5_6 = (arg_5_3 - 1) * var_0_4 + iter_5_0

			if var_5_6 > #arg_5_0.similarPets then
				break
			end

			var_5_3 = display.newNode()

			arg_5_0:initPetCell(var_5_3, var_5_6)

			local var_5_7 = var_5_3:getContentSize().width
			local var_5_8 = var_5_3:getContentSize().height
			local var_5_9 = (arg_5_0.petList.viewRect_.width - var_5_7 * var_0_4) / (var_0_4 + 1)

			var_5_3:align(display.CENTER, var_5_9 * iter_5_0 + (iter_5_0 - 1) * var_5_7 + var_5_7 / 2, var_5_8 / 2)
			var_5_5:addChild(var_5_3)
		end

		var_5_5:setContentSize(cc.size(arg_5_0.petList.viewRect_.width, var_5_3:getContentSize().height + var_0_5))
		var_5_4:setItemSize(arg_5_0.petList.viewRect_.width, var_5_3:getContentSize().height + var_0_5)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.initSimilarPets(arg_6_0)
	local var_6_0 = xyd.tables.hero:getPetsIgnoreShow() or {}

	arg_6_0.similarPets = {}

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		if iter_6_1 ~= arg_6_0.pet:getTableID() and xyd.tables.hero:beforeAwaken(iter_6_1) == 0 and iter_6_1 ~= xyd.tables.hero:beforeAwaken(arg_6_0.pet:getTableID()) then
			local var_6_1 = xyd.tables.hero:getHolyAttr(iter_6_1)

			for iter_6_2 = 1, #var_6_1 do
				if var_6_1[iter_6_2] == arg_6_0.id then
					table.insert(arg_6_0.similarPets, iter_6_1)

					break
				end
			end
		end
	end
end

function var_0_0.initPetCell(arg_7_0, arg_7_1, arg_7_2)
	arg_7_1:setContentSize(var_0_3, var_0_3)
	arg_7_1:setAnchorPoint(cc.p(0.5, 0.5))

	local var_7_0 = arg_7_0.similarPets[arg_7_2]
	local var_7_1 = false

	for iter_7_0, iter_7_1 in pairs(arg_7_0.collectedPets) do
		if var_7_0 == iter_7_1:getTableID() or var_7_0 == xyd.tables.hero:beforeAwaken(iter_7_1:getTableID()) then
			xyd.setPetAvatarNewUI(arg_7_1, iter_7_1, nil, true, nil, 0.7, nil)

			var_7_1 = true

			break
		end
	end

	if not var_7_1 then
		local var_7_2 = xyd.AssetLoader.get():loadSprite("windows/pet/petMainWindow/black_bg.png")

		if var_7_2 then
			var_7_2:setAnchorPoint(cc.p(0, 0))

			local var_7_3 = var_7_2:getContentSize().width
			local var_7_4 = var_7_2:getContentSize().height

			var_7_2:setScale(var_0_3 / var_7_3, var_0_3 / var_7_4)
			var_7_2:addTo(arg_7_1)
		end
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0.petList:reload()
end

return var_0_0
