local var_0_0 = class("DormEquipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.houseId = arg_1_2.house_id
	arg_1_0.equipItems = xyd.tables.hero:dormItem(arg_1_0.hero:getFirstTableID())
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	for iter_3_0 = 1, var_0_2 do
		local var_3_0 = arg_3_0.equipItems[iter_3_0]
		local var_3_1 = arg_3_0:createEquipContent(var_3_0)

		arg_3_0:nodeByName("pos" .. tostring(iter_3_0)):removeAllChildren()
		var_3_1:addTo(arg_3_0:nodeByName("pos" .. tostring(iter_3_0)))
		var_3_1:setTouchEnabled(true)
		var_3_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				return true
			elseif arg_4_0.name == "moved" then
				return true
			elseif arg_4_0.name == "ended" then
				local var_4_0 = {
					house_id = arg_3_0.houseId,
					index = iter_3_0,
					hero = arg_3_0.hero,
					item_id = var_3_0,
					callback = function()
						arg_3_0:layout()
					end
				}

				xyd.WindowManager.get():openWindow("dorm_equip_confirm", var_4_0)
			end
		end)

		local var_3_2 = var_3_1:getContentSize()

		var_3_1:setPosition(cc.p(-var_3_2.width / 2, -var_3_2.height / 2))

		if not xyd.isInTable(arg_3_0.hero:getHouseEquips(), var_3_0) and arg_3_0.backpack:getItemNumByID(var_3_0) > 0 and iter_3_0 <= arg_3_0.hero:getStar() then
			local var_3_3 = xyd.AssetLoader.get():loadSprite("windows/dorm/room_equip/green_plus.png")

			var_3_3:addTo(var_3_1)
			var_3_3:setPosition(cc.p(var_3_2.width / 2, var_3_2.height / 2))
		elseif not xyd.isInTable(arg_3_0.hero:getHouseEquips(), var_3_0) then
			local var_3_4 = xyd.AssetLoader.get():loadSprite("windows/dorm/room_equip/white_plus.png")

			var_3_4:addTo(var_3_1)
			var_3_4:setPosition(cc.p(var_3_2.width / 2, var_3_2.height / 2))
		end
	end
end

function var_0_0.createEquipContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()

	var_6_0:setContentSize(70, 70)

	local var_6_1 = xyd.tables.item:transparentIcon(arg_6_1)
	local var_6_2

	if xyd.isInTable(arg_6_0.hero:getHouseEquips(), arg_6_1) then
		var_6_2 = xyd.AssetLoader:get():loadSprite(var_6_1)
	else
		var_6_2 = display.newFilteredSprite(var_6_1, "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})
	end

	xyd.displaySpriteOnContainer(var_6_2, var_6_0, false)

	return var_6_0
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	var_0_0.super.willClose(arg_7_0, arg_7_1)
	arg_7_0.callback()
end

return var_0_0
