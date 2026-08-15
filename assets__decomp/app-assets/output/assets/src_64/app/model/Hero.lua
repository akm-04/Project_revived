local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hero")

function var_0_3.initUnCollected(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	local var_1_0 = var_0_2.getPartnerTypeByTableID(arg_1_1)

	if var_1_0 then
		if var_1_0 == var_0_2.PartnerType.NORMAL then
			setmetatable(arg_1_0, {
				__index = var_0_0.import("app.model.NormalHero").new()
			})
		elseif var_1_0 == var_0_2.PartnerType.SUPER then
			setmetatable(arg_1_0, {
				__index = var_0_0.import("app.model.SuperHero").new()
			})
		end

		return arg_1_0:initUnCollected_(arg_1_1, arg_1_2, arg_1_3)
	else
		setmetatable(arg_1_0, {
			__index = var_0_0.import("app.model.NormalHero").new()
		})

		return arg_1_0:initUnCollected_(arg_1_1, arg_1_2, arg_1_3)
	end
end

function var_0_3.populate(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.table_id)
	local var_2_1 = tonumber(arg_2_1.partner_id)
	local var_2_2 = var_0_2.getPartnerTypeByTableID(var_2_0) or var_0_2.getPartnerTypeByPartnerID(var_2_1)

	if not var_2_2 then
		setmetatable(arg_2_0, {
			__index = var_0_0.import("app.model.NormalHero").new()
		})

		return arg_2_0:populate_(arg_2_1)
	end

	if var_2_2 == var_0_2.PartnerType.NORMAL then
		setmetatable(arg_2_0, {
			__index = var_0_0.import("app.model.NormalHero").new()
		})
	elseif var_2_2 == var_0_2.PartnerType.SUPER then
		setmetatable(arg_2_0, {
			__index = var_0_0.import("app.model.SuperHero").new()
		})
	end

	return arg_2_0:populate_(arg_2_1)
end

function var_0_3.populateWithTableID(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_2.getPartnerTypeByTableID(arg_3_1)

	if var_3_0 then
		if var_3_0 == var_0_2.PartnerType.NORMAL then
			setmetatable(arg_3_0, {
				__index = var_0_0.import("app.model.NormalHero").new()
			})
		elseif var_3_0 == var_0_2.PartnerType.SUPER then
			setmetatable(arg_3_0, {
				__index = var_0_0.import("app.model.SuperHero").new()
			})
		end

		return arg_3_0:populateWithTableID_(arg_3_1, arg_3_2)
	else
		setmetatable(arg_3_0, {
			__index = var_0_0.import("app.model.NormalHero").new()
		})

		return arg_3_0:populateWithTableID_(arg_3_1, arg_3_2)
	end
end

return var_0_3
