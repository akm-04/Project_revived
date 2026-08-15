local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = {}
local var_0_4 = var_0_2.tables.skill
local var_0_5 = math

function var_0_3.getTeam(arg_1_0)
	return arg_1_0.selfTeam_, arg_1_0.targetTeam_
end

function var_0_3.aliveTargets(arg_2_0)
	local var_2_0 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_0) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
			table.insert(var_2_0, iter_2_1)
		end
	end

	return var_2_0
end

function var_0_3.A1(arg_3_0, arg_3_1)
	local var_3_0, var_3_1 = arg_3_0:getPos()
	local var_3_2, var_3_3 = var_0_3.getTeam(arg_3_0)
	local var_3_4
	local var_3_5

	for iter_3_0, iter_3_1 in ipairs(var_3_2) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_0 then
			local var_3_6, var_3_7 = iter_3_1:getPos()
			local var_3_8 = var_0_5.abs(var_3_0 - var_3_6)

			if not var_3_4 or var_3_8 < var_3_4 then
				var_3_4 = var_3_8
				var_3_5 = iter_3_1
			end
		end
	end

	if not var_3_5 or var_3_4 > arg_3_0:getFrontSkillDistance() then
		return {}
	end

	return {
		var_3_5
	}
end

function var_0_3.A2(arg_4_0, arg_4_1)
	local var_4_0, var_4_1 = var_0_3.getTeam(arg_4_0)

	return var_0_3.aliveTargets(var_4_0)
end

function var_0_3.A3(arg_5_0, arg_5_1)
	if not var_0_3.timeSeed_ then
		var_0_3.timeSeed_ = 1
	end

	var_0_5.randomseed(tonumber(tostring(os.time() + var_0_3.timeSeed_):reverse():sub(1, 6)))

	local var_5_0 = var_0_5.random(tonumber(os.time()))

	var_0_3.timeSeed_ = var_5_0

	local var_5_1 = var_0_3.A2(arg_5_0, arg_5_1)

	if not var_5_1 or next(var_5_1) == nil then
		return {}
	end

	var_0_5.randomseed(var_5_0)

	return {
		var_5_1[var_0_5.random(#var_5_1)]
	}
end

function var_0_3.A4(arg_6_0, arg_6_1)
	local var_6_0 = var_0_3.A2(arg_6_0, arg_6_1)
	local var_6_1
	local var_6_2

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		if not var_6_1 or var_6_2 > iter_6_1:getHp() / iter_6_1:getHpLimit() or var_6_2 == iter_6_1:getHp() / iter_6_1:getHpLimit() and var_6_1:getHp() > iter_6_1:getHp() then
			var_6_1 = iter_6_1
			var_6_2 = var_6_1:getHp() / var_6_1:getHpLimit()
		end
	end

	if var_6_1 then
		return {
			var_6_1
		}
	else
		return {}
	end
end

function var_0_3.A5(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0:getFighterModel():getFlipX()
	local var_7_1 = var_0_3.A2(arg_7_0, arg_7_1)
	local var_7_2, var_7_3 = arg_7_0:getPos()
	local var_7_4 = var_0_4:scope(arg_7_1)
	local var_7_5 = {}

	for iter_7_0, iter_7_1 in pairs(var_7_1) do
		local var_7_6, var_7_7 = iter_7_1:getPos()

		if var_7_0 then
			if var_7_6 < var_7_2 and var_7_4 >= var_7_2 - var_7_6 then
				table.insert(var_7_5, iter_7_1)
			end
		elseif var_7_2 < var_7_6 and var_7_4 >= var_7_6 - var_7_2 then
			table.insert(var_7_5, iter_7_1)
		end
	end

	return var_7_5
end

function var_0_3.A6(arg_8_0, arg_8_1)
	return {}
end

function var_0_3.A7(arg_9_0, arg_9_1)
	return {}
end

function var_0_3.A8(arg_10_0, arg_10_1)
	local var_10_0 = {}
	local var_10_1 = arg_10_1 == nil and arg_10_0:getScope() or var_0_4:scope(arg_10_1)
	local var_10_2, var_10_3 = arg_10_0:getPos()
	local var_10_4, var_10_5 = var_0_3.getTeam(arg_10_0)

	for iter_10_0, iter_10_1 in ipairs(var_10_4) do
		local var_10_6, var_10_7 = iter_10_1:getPos()

		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and var_10_1 >= var_0_5.abs(var_10_6 - var_10_2) then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.A9(arg_11_0, arg_11_1, arg_11_2)
	if not arg_11_2 then
		return var_0_3.A1(arg_11_0)
	end

	if not arg_11_2.targets_ or not next(arg_11_2.targets_) then
		return {}
	end

	local var_11_0, var_11_1 = var_0_3.getTeam(arg_11_0)
	local var_11_2, var_11_3 = arg_11_2.targets_[1]:getPos()
	local var_11_4
	local var_11_5

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_6, var_11_7 = iter_11_1:getPos()
			local var_11_8 = var_0_5.abs(var_11_2 - var_11_6)

			if (not var_11_4 or var_11_8 < var_11_4) and not arg_11_2.recordTargets_[iter_11_1.fighterIndex] then
				var_11_4 = var_11_8
				var_11_5 = iter_11_1
			end
		end
	end

	local var_11_9 = {}

	if var_11_5 then
		var_11_9 = {
			var_11_5
		}
	end

	return var_11_9
end

function var_0_3.A13(arg_12_0, arg_12_1)
	return {
		arg_12_0
	}
end

function var_0_3.A14(arg_13_0, arg_13_1)
	local var_13_0 = var_0_3.A2(arg_13_0)
	local var_13_1
	local var_13_2

	for iter_13_0, iter_13_1 in pairs(var_13_0) do
		if not var_13_1 or var_13_2 < iter_13_1:getHp() / iter_13_1:getHpLimit() or var_13_2 == iter_13_1:getHp() / iter_13_1:getHpLimit() and var_13_1:getHp() < iter_13_1:getHp() then
			var_13_1 = iter_13_1
			var_13_2 = var_13_1:getHp() / var_13_1:getHpLimit()
		end
	end

	if var_13_1 then
		return {
			var_13_1
		}
	else
		return {}
	end
end

function var_0_3.A16(arg_14_0, arg_14_1)
	local var_14_0 = {}
	local var_14_1 = arg_14_0:getX()
	local var_14_2 = {}
	local var_14_3, var_14_4 = var_0_3.getTeam(arg_14_0)

	for iter_14_0, iter_14_1 in ipairs(var_14_3) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			table.insert(var_14_2, iter_14_1)
		end
	end

	if not next(var_14_2) then
		return {}
	end

	table.sort(var_14_2, function(arg_15_0, arg_15_1)
		return var_0_5.abs(arg_15_0:getX() - var_14_1) < var_0_5.abs(arg_15_1:getX() - var_14_1)
	end)

	for iter_14_2, iter_14_3 in ipairs(var_14_2) do
		if iter_14_2 < 6 then
			table.insert(var_14_0, iter_14_3)
		end
	end

	return var_14_0
end

function var_0_3.A17(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:getX()
	local var_16_1
	local var_16_2
	local var_16_3, var_16_4 = var_0_3.getTeam(arg_16_0)

	for iter_16_0, iter_16_1 in ipairs(var_16_3) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and (not var_16_1 or var_16_1 < var_0_5.abs(iter_16_1:getX() - var_16_0)) then
			var_16_2 = iter_16_1
			var_16_1 = var_0_5.abs(iter_16_1:getX() - var_16_0)
		end
	end

	if not var_16_2 then
		return {}
	end

	return {
		var_16_2
	}
end

function var_0_3.A18(arg_17_0, arg_17_1)
	local var_17_0 = {}
	local var_17_1 = var_0_4:scope(arg_17_1)
	local var_17_2 = unpack(var_0_3.A17(arg_17_0, arg_17_1))
	local var_17_3, var_17_4 = var_0_3.getTeam(arg_17_0)

	if not var_17_2 then
		return {}
	end

	local var_17_5, var_17_6 = var_17_2:getPos()

	table.insert(var_17_0, var_17_2)

	for iter_17_0, iter_17_1 in ipairs(var_17_3) do
		local var_17_7, var_17_8 = iter_17_1:getPos()

		if not iter_17_1:isDeath() and not iter_17_1:isAffected() and var_0_5.abs(var_17_5 - var_17_7) <= var_17_1 / 2 and iter_17_1 ~= var_17_2 then
			table.insert(var_17_0, iter_17_1)
		end
	end

	return var_17_0
end

function var_0_3.A25(arg_18_0, arg_18_1)
	local var_18_0 = {}
	local var_18_1
	local var_18_2, var_18_3 = var_0_3.getTeam(arg_18_0)

	for iter_18_0, iter_18_1 in ipairs(var_18_2) do
		if not iter_18_1:isDeath() and not iter_18_1:isAffected() and iter_18_1:getEnergy() < var_0_2.ENERGY_DECIMAL_BASE and iter_18_1.summonType_ == var_0_2.summonMonsterType.None and (var_18_1 == nil or var_18_1:getEnergy() < iter_18_1:getEnergy()) then
			var_18_1 = iter_18_1
		end
	end

	if var_18_1 then
		table.insert(var_18_0, var_18_1)
	end

	return var_18_0
end

function var_0_3.A28(arg_19_0, arg_19_1)
	local var_19_0 = var_0_3.A2(arg_19_0, arg_19_1)
	local var_19_1

	if arg_19_0:getTeamType() == var_0_2.TeamType.A then
		for iter_19_0, iter_19_1 in pairs(var_19_0) do
			if not var_19_1 or var_19_1:getX() < iter_19_1:getX() then
				var_19_1 = iter_19_1
			end
		end
	else
		for iter_19_2, iter_19_3 in pairs(var_19_0) do
			if not var_19_1 or var_19_1:getX() > iter_19_3:getX() then
				var_19_1 = iter_19_3
			end
		end
	end

	if var_19_1 then
		return {
			var_19_1
		}
	else
		return {}
	end
end

function var_0_3.A31(arg_20_0, arg_20_1)
	local var_20_0
	local var_20_1
	local var_20_2, var_20_3 = var_0_3.getTeam(arg_20_0)

	for iter_20_0, iter_20_1 in ipairs(var_20_2) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() and iter_20_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_20_1 or var_20_1 < iter_20_1.harms) then
			var_20_0 = iter_20_1
			var_20_1 = iter_20_1.harms
		end
	end

	return {
		var_20_0
	}
end

function var_0_3.B1(arg_21_0, arg_21_1)
	local var_21_0, var_21_1 = arg_21_0:getPos()
	local var_21_2
	local var_21_3 = arg_21_0:getNearestTarget()
	local var_21_4 = var_0_4:distance(arg_21_1)

	if not var_21_3 or var_21_4 > 0 and var_21_4 < var_0_5.abs(var_21_3:getX() - arg_21_0:getX()) then
		return {}
	end

	return {
		var_21_3
	}
end

function var_0_3.B2(arg_22_0, arg_22_1)
	local var_22_0, var_22_1 = var_0_3.getTeam(arg_22_0)

	return var_0_3.aliveTargets(var_22_1)
end

function var_0_3.B3(arg_23_0, arg_23_1)
	if not var_0_3.timeSeed_ then
		var_0_3.timeSeed_ = 1
	end

	var_0_5.randomseed(tonumber(tostring(os.time() + var_0_3.timeSeed_):reverse():sub(1, 6)))

	local var_23_0 = var_0_5.random(tonumber(os.time()))

	var_0_3.timeSeed_ = var_23_0

	local var_23_1 = var_0_3.B2(arg_23_0, arg_23_1)

	if not var_23_1 or next(var_23_1) == nil then
		return {}
	end

	var_0_5.randomseed(var_23_0)

	return {
		var_23_1[var_0_5.random(#var_23_1)]
	}
end

function var_0_3.B4(arg_24_0, arg_24_1)
	local var_24_0 = var_0_3.B2(arg_24_0, arg_24_1)
	local var_24_1
	local var_24_2

	for iter_24_0, iter_24_1 in pairs(var_24_0) do
		if not var_24_1 or var_24_2 > iter_24_1:getHp() / iter_24_1:getHpLimit() or var_24_2 == iter_24_1:getHp() / iter_24_1:getHpLimit() and var_24_1:getHp() > iter_24_1:getHp() then
			var_24_1 = iter_24_1
			var_24_2 = var_24_1:getHp() / var_24_1:getHpLimit()
		end
	end

	if var_24_1 then
		return {
			var_24_1
		}
	else
		return {}
	end
end

function var_0_3.B5(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0:getFighterModel():getFlipX()
	local var_25_1 = var_0_3.B2(arg_25_0, arg_25_1)
	local var_25_2, var_25_3 = arg_25_0:getPos()
	local var_25_4 = var_0_4:scope(arg_25_1)
	local var_25_5 = {}

	for iter_25_0, iter_25_1 in pairs(var_25_1) do
		local var_25_6, var_25_7 = iter_25_1:getPos()

		if var_25_0 then
			if var_25_6 < var_25_2 and var_25_4 >= var_25_2 - var_25_6 then
				table.insert(var_25_5, iter_25_1)
			end
		elseif var_25_2 < var_25_6 and var_25_4 >= var_25_6 - var_25_2 then
			table.insert(var_25_5, iter_25_1)
		end
	end

	return var_25_5
end

function var_0_3.B6(arg_26_0, arg_26_1)
	local var_26_0 = {}
	local var_26_1, var_26_2 = arg_26_0:getPos()
	local var_26_3 = var_0_4:scope(arg_26_1)
	local var_26_4 = unpack(var_0_3.B1(arg_26_0, arg_26_1))
	local var_26_5 = arg_26_0:getFighterModel():getFlipX()
	local var_26_6, var_26_7 = var_0_3.getTeam(arg_26_0)

	if not var_26_4 then
		return {}
	end

	local var_26_8, var_26_9 = var_26_4:getPos()

	if var_26_5 then
		for iter_26_0, iter_26_1 in ipairs(var_26_7) do
			local var_26_10, var_26_11 = iter_26_1:getPos()

			if not iter_26_1:isDeath() and not iter_26_1:isAffected() and var_26_10 <= var_26_8 and var_26_3 >= var_26_8 - var_26_10 then
				table.insert(var_26_0, iter_26_1)
			end
		end
	else
		for iter_26_2, iter_26_3 in ipairs(var_26_7) do
			local var_26_12, var_26_13 = iter_26_3:getPos()

			if not iter_26_3:isDeath() and not iter_26_3:isAffected() and var_26_8 <= var_26_12 and var_26_3 >= var_26_12 - var_26_8 then
				table.insert(var_26_0, iter_26_3)
			end
		end
	end

	return var_26_0
end

function var_0_3.B7(arg_27_0, arg_27_1)
	local var_27_0 = {}
	local var_27_1 = var_0_4:scope(arg_27_1) / 2
	local var_27_2 = unpack(var_0_3.B1(arg_27_0, arg_27_1))

	if not var_27_2 then
		return {}
	end

	local var_27_3, var_27_4 = var_27_2:getPos()
	local var_27_5, var_27_6 = var_0_3.getTeam(arg_27_0)

	table.insert(var_27_0, var_27_2)

	for iter_27_0, iter_27_1 in ipairs(var_27_6) do
		local var_27_7, var_27_8 = iter_27_1:getPos()

		if not iter_27_1:isDeath() and not iter_27_1:isAffected() and var_27_1 >= var_0_5.abs(var_27_3 - var_27_7) and iter_27_1 ~= var_27_2 then
			table.insert(var_27_0, iter_27_1)
		end
	end

	return var_27_0
end

function var_0_3.B8(arg_28_0, arg_28_1)
	local var_28_0 = {}
	local var_28_1 = var_0_4:scope(arg_28_1)
	local var_28_2, var_28_3 = arg_28_0:getPos()
	local var_28_4, var_28_5 = var_0_3.getTeam(arg_28_0)

	for iter_28_0, iter_28_1 in ipairs(var_28_5) do
		local var_28_6, var_28_7 = iter_28_1:getPos()

		if not iter_28_1:isDeath() and not iter_28_1:isAffected() and var_28_1 >= var_0_5.abs(var_28_6 - var_28_2) then
			table.insert(var_28_0, iter_28_1)
		end
	end

	return var_28_0
end

function var_0_3.B9(arg_29_0, arg_29_1, arg_29_2)
	if not arg_29_2 then
		return var_0_3.B1(arg_29_0, arg_29_1)
	end

	if not arg_29_2.targets_ or not next(arg_29_2.targets_) then
		return
	end

	local var_29_0 = arg_29_2.targets_
	local var_29_1, var_29_2 = var_0_3.getTeam(arg_29_0)
	local var_29_3, var_29_4 = var_29_0[#var_29_0]:getPos()
	local var_29_5
	local var_29_6

	for iter_29_0, iter_29_1 in ipairs(var_29_2) do
		if not iter_29_1:isDeath() and not iter_29_1:isAffected() and iter_29_1 ~= arg_29_0 then
			local var_29_7, var_29_8 = iter_29_1:getPos()
			local var_29_9 = var_0_5.abs(var_29_3 - var_29_7)

			if (not var_29_5 or var_29_9 < var_29_5) and not arg_29_2.recordTargets_[iter_29_1.fighterIndex] then
				var_29_5 = var_29_9
				var_29_6 = iter_29_1
			end
		end
	end

	local var_29_10 = {}

	if var_29_6 then
		var_29_10 = {
			var_29_6
		}
	end

	return var_29_10
end

function var_0_3.B10(arg_30_0, arg_30_1, arg_30_2)
	if not arg_30_2 then
		return var_0_3.B1(arg_30_0, arg_30_1)
	end

	if not arg_30_2.targets_ or not next(arg_30_2.targets_) then
		return {}
	end

	local var_30_0 = arg_30_2.target
	local var_30_1, var_30_2 = var_30_0:getPos()
	local var_30_3, var_30_4 = var_0_3.getTeam(arg_30_0)
	local var_30_5
	local var_30_6

	for iter_30_0, iter_30_1 in ipairs(var_30_4) do
		if not iter_30_1:isDeath() and not iter_30_1:isAffected() and iter_30_1 ~= arg_30_0 and iter_30_1 ~= var_30_0 then
			local var_30_7, var_30_8 = iter_30_1:getPos()
			local var_30_9 = var_0_5.abs(var_30_1 - var_30_7)

			if not var_30_5 or var_30_9 < var_30_5 then
				var_30_5 = var_30_9
				var_30_6 = iter_30_1
			end
		end
	end

	local var_30_10 = {}

	if var_30_6 then
		var_30_10 = {
			var_30_6
		}
	end

	return var_30_10
end

function var_0_3.B13(arg_31_0, arg_31_1)
	return {
		arg_31_0
	}
end

function var_0_3.B14(arg_32_0, arg_32_1)
	local var_32_0 = var_0_3.B2(arg_32_0, arg_32_1)
	local var_32_1
	local var_32_2

	for iter_32_0, iter_32_1 in pairs(var_32_0) do
		if not var_32_1 or var_32_2 < iter_32_1:getHp() / iter_32_1:getHpLimit() or var_32_2 == iter_32_1:getHp() / iter_32_1:getHpLimit() and var_32_1:getHp() < iter_32_1:getHp() then
			var_32_1 = iter_32_1
			var_32_2 = var_32_1:getHp() / var_32_1:getHpLimit()
		end
	end

	if var_32_1 then
		return {
			var_32_1
		}
	else
		return {}
	end
end

function var_0_3.B15(arg_33_0, arg_33_1)
	local var_33_0 = unpack(var_0_3.B1(arg_33_0, arg_33_1))

	if not var_33_0 then
		return {}
	end

	local var_33_1, var_33_2 = var_33_0:getPos()
	local var_33_3
	local var_33_4, var_33_5 = var_0_3.getTeam(arg_33_0)

	for iter_33_0, iter_33_1 in ipairs(var_33_5) do
		local var_33_6, var_33_7 = iter_33_1:getPos()

		if not iter_33_1:isDeath() and not iter_33_1:isAffected() and iter_33_1 ~= var_33_0 and (not var_33_3 or var_0_5.abs(var_33_6 - var_33_1) < var_0_5.abs(var_33_3:getX() - var_33_1)) then
			var_33_3 = iter_33_1
		end
	end

	if not var_33_3 then
		return {
			var_33_0
		}
	end

	return {
		var_33_0,
		var_33_3
	}
end

function var_0_3.B16(arg_34_0, arg_34_1)
	local var_34_0 = {}
	local var_34_1 = arg_34_0:getX()
	local var_34_2 = {}
	local var_34_3, var_34_4 = var_0_3.getTeam(arg_34_0)

	for iter_34_0, iter_34_1 in ipairs(var_34_4) do
		if not iter_34_1:isDeath() and not iter_34_1:isAffected() then
			table.insert(var_34_2, iter_34_1)
		end
	end

	if not next(var_34_2) then
		return {}
	end

	table.sort(var_34_2, function(arg_35_0, arg_35_1)
		return var_0_5.abs(arg_35_0:getX() - var_34_1) < var_0_5.abs(arg_35_1:getX() - var_34_1)
	end)

	for iter_34_2, iter_34_3 in ipairs(var_34_2) do
		if iter_34_2 < 6 then
			table.insert(var_34_0, iter_34_3)
		end
	end

	return var_34_0
end

function var_0_3.B17(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_0:getX()
	local var_36_1
	local var_36_2
	local var_36_3, var_36_4 = var_0_3.getTeam(arg_36_0)

	for iter_36_0, iter_36_1 in ipairs(var_36_4) do
		if not iter_36_1:isDeath() and not iter_36_1:isAffected() and (not var_36_1 or var_36_1 < var_0_5.abs(iter_36_1:getX() - var_36_0)) then
			var_36_2 = iter_36_1
			var_36_1 = var_0_5.abs(iter_36_1:getX() - var_36_0)
		end
	end

	if not var_36_2 then
		return {}
	end

	return {
		var_36_2
	}
end

function var_0_3.B18(arg_37_0, arg_37_1)
	local var_37_0 = {}
	local var_37_1 = var_0_4:scope(arg_37_1)
	local var_37_2 = unpack(var_0_3.B17(arg_37_0, arg_37_1))
	local var_37_3, var_37_4 = var_0_3.getTeam(arg_37_0)

	if not var_37_2 then
		return {}
	end

	local var_37_5, var_37_6 = var_37_2:getPos()

	table.insert(var_37_0, var_37_2)

	for iter_37_0, iter_37_1 in ipairs(var_37_4) do
		local var_37_7, var_37_8 = iter_37_1:getPos()

		if not iter_37_1:isDeath() and not iter_37_1:isAffected() and var_0_5.abs(var_37_5 - var_37_7) <= var_37_1 / 2 and iter_37_1 ~= var_37_2 then
			table.insert(var_37_0, iter_37_1)
		end
	end

	return var_37_0
end

function var_0_3.B25(arg_38_0, arg_38_1)
	local var_38_0 = {}
	local var_38_1
	local var_38_2, var_38_3 = var_0_3.getTeam(arg_38_0)

	for iter_38_0, iter_38_1 in ipairs(var_38_3) do
		if not iter_38_1:isDeath() and not iter_38_1:isAffected() and iter_38_1.summonType_ == var_0_2.summonMonsterType.None and (var_38_1 == nil or var_38_1:getEnergy() < iter_38_1:getEnergy()) then
			var_38_1 = iter_38_1
		end
	end

	if var_38_1 then
		table.insert(var_38_0, var_38_1)
	end

	return var_38_0
end

function var_0_3.B26(arg_39_0, arg_39_1)
	local var_39_0 = {}
	local var_39_1 = var_0_3.B3(arg_39_0, arg_39_1)

	if next(var_39_1) == nil then
		return {}
	end

	local var_39_2 = var_0_4:scope(arg_39_1)
	local var_39_3 = var_39_1[1]
	local var_39_4, var_39_5 = var_0_3.getTeam(arg_39_0)

	for iter_39_0, iter_39_1 in ipairs(var_39_5) do
		if not iter_39_1:isDeath() and not iter_39_1:isAffected() and iter_39_1 ~= var_39_3 and var_0_5.abs(var_39_3:getX() - iter_39_1:getX()) <= var_39_2 / 2 then
			table.insert(var_39_1, iter_39_1)
		end
	end

	return var_39_1
end

function var_0_3.B30(arg_40_0, arg_40_1)
	local function var_40_0(arg_41_0, arg_41_1)
		local var_41_0, var_41_1 = var_0_3.getTeam(arg_41_0)
		local var_41_2 = {}

		table.insert(var_41_2, arg_41_0)

		for iter_41_0, iter_41_1 in ipairs(var_41_0) do
			if not iter_41_1:isDeath() and not iter_41_1:isAffected() and iter_41_1 ~= arg_41_0 and arg_41_1 >= var_0_5.abs(iter_41_1:getX() - arg_41_0:getX()) then
				table.insert(var_41_2, iter_41_1)
			end
		end

		return var_41_2
	end

	local var_40_1 = {}
	local var_40_2 = 0
	local var_40_3 = var_0_4:scope(arg_40_1) * 0.5
	local var_40_4, var_40_5 = var_0_3.getTeam(arg_40_0)

	for iter_40_0, iter_40_1 in ipairs(var_40_5) do
		if not iter_40_1:isDeath() and not iter_40_1:isAffected() then
			local var_40_6 = var_40_0(iter_40_1, var_40_3)

			if var_40_2 < #var_40_6 then
				var_40_1 = var_40_6
				var_40_2 = #var_40_6
			end
		end
	end

	return var_40_1
end

function var_0_3.B31(arg_42_0, arg_42_1)
	local var_42_0
	local var_42_1
	local var_42_2, var_42_3 = var_0_3.getTeam(arg_42_0)

	for iter_42_0, iter_42_1 in ipairs(var_42_3) do
		if not iter_42_1:isDeath() and not iter_42_1:isAffected() and iter_42_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_42_1 or var_42_1 < iter_42_1.harms) then
			var_42_0 = iter_42_1
			var_42_1 = iter_42_1.harms
		end
	end

	return {
		var_42_0
	}
end

function var_0_3.B32(arg_43_0, arg_43_1)
	local var_43_0 = var_0_3.B4(arg_43_0, arg_43_1)

	if not next(var_43_0) then
		return {}
	end

	local var_43_1 = var_43_0[1]
	local var_43_2 = {}
	local var_43_3 = var_0_4:scope(arg_43_1) / 2
	local var_43_4, var_43_5 = var_43_1:getPos()
	local var_43_6, var_43_7 = var_0_3.getTeam(arg_43_0)

	table.insert(var_43_2, var_43_1)

	for iter_43_0, iter_43_1 in ipairs(var_43_7) do
		local var_43_8, var_43_9 = iter_43_1:getPos()

		if not iter_43_1:isDeath() and not iter_43_1:isAffected() and var_43_3 >= var_0_5.abs(var_43_4 - var_43_8) and iter_43_1 ~= var_43_1 then
			table.insert(var_43_2, iter_43_1)
		end
	end

	return var_43_2
end

function var_0_3.B33(arg_44_0, arg_44_1)
	local var_44_0 = {}
	local var_44_1, var_44_2 = arg_44_0:getPos()
	local var_44_3 = var_0_4:scope(arg_44_1)
	local var_44_4 = unpack(var_0_3.B1(arg_44_0, arg_44_1))
	local var_44_5 = arg_44_0:getFighterModel():getFlipX()
	local var_44_6, var_44_7 = var_0_3.getTeam(arg_44_0)

	if not var_44_4 then
		return {}
	end

	local var_44_8, var_44_9 = var_44_4:getPos()

	if var_44_5 then
		for iter_44_0, iter_44_1 in ipairs(var_44_7) do
			local var_44_10, var_44_11 = iter_44_1:getPos()

			if not iter_44_1:isDeath() and not iter_44_1:isAffected() and iter_44_1 ~= var_44_4 and var_44_10 <= var_44_8 and var_44_3 >= var_44_8 - var_44_10 then
				table.insert(var_44_0, iter_44_1)
			end
		end
	else
		for iter_44_2, iter_44_3 in ipairs(var_44_7) do
			local var_44_12, var_44_13 = iter_44_3:getPos()

			if not iter_44_3:isDeath() and not iter_44_3:isAffected() and iter_44_3 ~= var_44_4 and var_44_8 <= var_44_12 and var_44_3 >= var_44_12 - var_44_8 then
				table.insert(var_44_0, iter_44_3)
			end
		end
	end

	return var_44_0
end

function var_0_3.C3(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = {}

	if arg_45_2 and arg_45_2.manualTargets_ then
		var_45_0 = arg_45_2.manualTargets_
	else
		var_45_0 = var_0_3.B3(arg_45_0, arg_45_1)
	end

	return var_45_0
end

function var_0_3.C5(arg_46_0, arg_46_1, arg_46_2)
	local var_46_0 = {}

	if arg_46_2 and arg_46_2.manualTargets_ then
		var_46_0 = arg_46_2.manualTargets_
	else
		var_46_0 = var_0_3.B5(arg_46_0, arg_46_1)
	end

	return var_46_0
end

function var_0_3.C6(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_2 and arg_47_2.manualTargets_ then
		return arg_47_2.manualTargets_
	end

	return var_0_3.B6(arg_47_0, arg_47_1)
end

function var_0_3.C7(arg_48_0, arg_48_1, arg_48_2)
	if arg_48_2 and arg_48_2.manualTargets_ then
		return arg_48_2.manualTargets_
	end

	return var_0_3.B7(arg_48_0, arg_48_1)
end

function var_0_3.C8(arg_49_0, arg_49_1, arg_49_2)
	if arg_49_2 and arg_49_2.manualTargets_ then
		return arg_49_2.manualTargets_
	end

	if var_0_2.tables.skill:type(arg_49_1) == var_0_2.AttackType.CURE then
		return var_0_3.A8(arg_49_0, arg_49_1)
	else
		return var_0_3.B8(arg_49_0, arg_49_1)
	end
end

function var_0_3.C11(arg_50_0, arg_50_1, arg_50_2)
	if not arg_50_2 then
		return {}
	end

	local var_50_0 = {}
	local var_50_1, var_50_2 = var_0_3.getTeam(arg_50_0)

	for iter_50_0, iter_50_1 in ipairs(var_0_3.aliveTargets(var_50_2)) do
		if (arg_50_2.iniX_ < iter_50_1:getX() and iter_50_1:getX() <= arg_50_2:getX() or arg_50_2.iniX_ > iter_50_1:getX() and iter_50_1:getX() >= arg_50_2:getX()) and not arg_50_2.targets[iter_50_1.fighterIndex] then
			arg_50_2.targets[iter_50_1.fighterIndex] = iter_50_1

			table.insert(var_50_0, iter_50_1)
		end
	end

	return var_50_0
end

function var_0_3.C12(arg_51_0, arg_51_1, arg_51_2)
	if arg_51_2 and arg_51_2.manualTargets_ then
		return arg_51_2.manualTargets_
	end

	return var_0_3.B7(arg_51_0, arg_51_1)
end

function var_0_3.C13(arg_52_0, arg_52_1, arg_52_2)
	if arg_52_2 and arg_52_2.manualTargets_ then
		return arg_52_2.manualTargets_
	end

	return var_0_3.A13(arg_52_0, arg_52_1)
end

function var_0_3.C18(arg_53_0, arg_53_1, arg_53_2)
	if arg_53_2 and arg_53_2.manualTargets_ then
		return arg_53_2.manualTargets_
	end

	return var_0_3.B18(arg_53_0, arg_53_1)
end

function var_0_3.C20(arg_54_0, arg_54_1, arg_54_2)
	local var_54_0 = var_0_3.C12(arg_54_0, arg_54_1, arg_54_2)
	local var_54_1 = {}

	for iter_54_0, iter_54_1 in pairs(var_54_0) do
		if iter_54_1.hero_:getHeroType() ~= var_0_2.HeroType.WISE then
			table.insert(var_54_1, iter_54_1)
		end
	end

	return var_54_1
end

function var_0_3.C21(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = {}
	local var_55_1, var_55_2 = var_0_3.getTeam(arg_55_0)

	for iter_55_0, iter_55_1 in ipairs(var_0_3.aliveTargets(var_55_2)) do
		if arg_55_2:getX() - arg_55_2:getSkillScope() / 2 < iter_55_1:getX() and iter_55_1:getX() <= arg_55_2:getX() + arg_55_2:getSkillScope() / 2 then
			table.insert(var_55_0, iter_55_1)
		end
	end

	return var_55_0
end

function var_0_3.C22(arg_56_0, arg_56_1, arg_56_2)
	local var_56_0 = {}

	if arg_56_2 and arg_56_2.manualTargets_ then
		var_56_0 = arg_56_2.manualTargets_
	else
		var_56_0 = var_0_3.B6(arg_56_0, arg_56_1)
	end

	return var_56_0
end

function var_0_3.C26(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0 = {}

	if arg_57_2 and arg_57_2.manualTargets_ then
		var_57_0 = arg_57_2.manualTargets_
	else
		var_57_0 = var_0_3.B26(arg_57_0, arg_57_1)
	end

	return var_57_0
end

function var_0_3.C29(arg_58_0, arg_58_1, arg_58_2)
	return {}
end

function var_0_3.C30(arg_59_0, arg_59_1, arg_59_2)
	local var_59_0 = {}

	if arg_59_2 and arg_59_2.manualTargets_ then
		var_59_0 = arg_59_2.manualTargets_
	else
		var_59_0 = var_0_3.B30(arg_59_0, arg_59_1)
	end

	return var_59_0
end

return var_0_3
