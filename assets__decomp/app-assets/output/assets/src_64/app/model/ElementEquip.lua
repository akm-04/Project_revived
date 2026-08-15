local var_0_0 = class("ElementEquip", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.equipElementItem(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local var_2_0 = {
		partner_id = arg_2_1:getHeroID(),
		equip_id = arg_2_2,
		equip_pos = arg_2_3
	}

	xyd.Backend.get():request(xyd.mid.ELEMENT_EQUIP, var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:refreshElementEquip(arg_2_1, arg_3_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_ELEMENT_EQUIP_CHANGED
			})

			if arg_2_4 then
				arg_2_4(arg_3_0, arg_3_1)
			end
		end
	end)
end

function var_0_0.strengthenElementItem(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {
		partner_id = arg_4_1:getHeroID(),
		equip_id = arg_4_2
	}

	xyd.Backend.get():request(xyd.mid.ELEMENT_LEV_UP, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0:refreshElementEquip(arg_4_1, arg_5_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_ELEMENT_EQUIP_CHANGED
			})

			if arg_4_3 then
				arg_4_3(arg_5_0, arg_5_1)
			end
		end
	end)
end

function var_0_0.takeOffElementItem(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {
		partner_id = arg_6_1:getHeroID(),
		equip_pos = arg_6_2
	}

	xyd.Backend.get():request(xyd.mid.ELEMENT_UNLOAD, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			arg_6_0:refreshElementEquip(arg_6_1, arg_7_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_ELEMENT_EQUIP_CHANGED
			})

			if arg_6_3 then
				arg_6_3(arg_7_0, arg_7_1)
			end
		end
	end)
end

function var_0_0.decomposeHeroElementItem(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {
		partner_id = arg_8_1:getHeroID(),
		equip_id = arg_8_2
	}

	xyd.Backend.get():request(xyd.mid.ELEMENT_DESTORY_ON_PARTNER, var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0:refreshElementEquip(arg_8_1, arg_9_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_ELEMENT_EQUIP_CHANGED
			})

			if arg_8_3 then
				arg_8_3(arg_9_0, arg_9_1)
			end
		end
	end)
end

function var_0_0.decomposeBackpackElementItem(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {
		equip_id = arg_10_1
	}

	xyd.Backend.get():request(xyd.mid.ELEMENT_DESTORY_IN_BACKPACK, var_10_0, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			if arg_10_2 then
				arg_10_2(arg_11_0, arg_11_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_ELEMENT_EQUIP_CHANGED
			})
		end
	end)
end

function var_0_0.refreshElementEquip(arg_12_0, arg_12_1, arg_12_2)
	arg_12_1.totalAttrs_ = nil

	if arg_12_2.element_equips then
		arg_12_1.elementEquips_ = xyd.splitToNumber(arg_12_2.element_equips, "|")
	end

	if arg_12_2.element_levels then
		arg_12_1.elementEquipsLevel_ = xyd.splitToNumber(arg_12_2.element_levels, "|")
	end

	if arg_12_2.element_bak_equips then
		arg_12_1.elementBindingEquips_ = xyd.splitToNumber(arg_12_2.element_bak_equips, "|")
	end

	if arg_12_2.element_bak_levels then
		arg_12_1.elementBindingEquipsLevel_ = xyd.splitToNumber(arg_12_2.element_bak_levels, "|")
	end
end

return var_0_0
