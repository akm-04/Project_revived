local var_0_0 = class("CloudPetTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 60
local var_0_3 = 80
local var_0_4 = 5
local var_0_5 = 10
local var_0_6 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.collectedPets = clone(arg_1_0.selfPlayer.collectedPets)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initPets()
	arg_2_0:initPetList()
	arg_2_0:layout()
end

function var_0_0.initPetList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("pet_container")
	local var_3_1 = var_3_0:getContentSize().width
	local var_3_2 = var_3_0:getContentSize().height

	arg_3_0.petList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1, var_3_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.petList:getViewRect().width

	for iter_4_0, iter_4_1 in pairs(arg_4_0.totalPets) do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.petList:newItem()
		local var_4_3 = xyd.tables.petHolyAttr:name(iter_4_0)
		local var_4_4 = {
			y = 0,
			size = 24,
			x = 0,
			text = string.format(var_0_1:translation("PET_ATTR_TIPS_3"), var_4_3),
			color = cc.c3b(243, 196, 7)
		}
		local var_4_5 = xyd.AssetLoader.get():loadLabel(var_4_4)

		var_4_5:setAnchorPoint(cc.p(0, 0.5))
		var_4_5:setPosition(cc.p(0, var_0_2 / 2))
		var_4_5:addTo(var_4_1)
		var_4_1:setContentSize(var_4_0, var_0_2)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(var_4_0, var_0_2)
		arg_4_0.petList:addItem(var_4_2)

		local var_4_6 = arg_4_0.petList:newItem()
		local var_4_7 = display.newNode()
		local var_4_8 = math.ceil(#iter_4_1 / var_0_4)
		local var_4_9 = var_4_8 * (var_0_3 + var_0_5)
		local var_4_10 = var_4_9

		for iter_4_2 = 1, var_4_8 do
			local var_4_11 = 0

			var_4_10 = var_4_10 - var_0_3 - var_0_5

			for iter_4_3 = 1, var_0_4 do
				if (iter_4_2 - 1) * var_0_4 + iter_4_3 > #iter_4_1 then
					break
				end

				local var_4_12 = iter_4_1[(iter_4_2 - 1) * var_0_4 + iter_4_3]
				local var_4_13 = display.newNode()

				var_4_13:setContentSize(var_0_3, var_0_3)
				xyd.setAvatarBorder(var_4_12, var_4_13, var_4_12:getColor(), var_4_12:getStar())
				var_4_13:setPosition(var_4_11, var_4_10)

				var_4_11 = var_4_11 + var_0_3 + var_0_5

				var_4_13:addTo(var_4_7)
			end
		end

		var_4_7:setContentSize(var_4_0, var_4_9)
		var_4_6:addContent(var_4_7)
		var_4_6:setItemSize(var_4_0, var_4_9)
		arg_4_0.petList:addItem(var_4_6)
	end
end

function var_0_0.initPets(arg_5_0)
	local var_5_0 = xyd.tables.hero:getPetsIgnoreShow() or {}

	arg_5_0.totalPets = {}

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if xyd.tables.hero:beforeAwaken(iter_5_1) == 0 then
			local var_5_1 = var_0_6.new()

			var_5_1:initUnCollected(iter_5_1)

			local var_5_2 = xyd.tables.hero:getHolyAttr(iter_5_1)

			for iter_5_2 = 1, #var_5_2 do
				if not arg_5_0.totalPets[var_5_2[iter_5_2]] then
					arg_5_0.totalPets[var_5_2[iter_5_2]] = {}
				end

				table.insert(arg_5_0.totalPets[var_5_2[iter_5_2]], var_5_1)
			end
		end
	end
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
	arg_6_0.petList:reload()
end

return var_0_0
