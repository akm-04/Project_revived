local var_0_0 = {}
local var_0_1 = xyd.tables.skill

function var_0_0.aliveTargets(arg_1_0)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_0) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() then
			table.insert(var_1_0, iter_1_1)
		end
	end

	return var_1_0
end

function var_0_0.A1(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0, var_2_1 = arg_2_0.fighterModel:getPosition()
	local var_2_2
	local var_2_3

	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1 ~= arg_2_0 then
			local var_2_4, var_2_5 = iter_2_1.fighterModel:getPosition()
			local var_2_6 = math.abs(var_2_0 - var_2_4)
			local var_2_7 = var_2_4 < var_2_0 == iter_2_1:getFighterModel():getFlipX()

			if (not var_2_2 or var_2_6 < var_2_2) and var_2_7 then
				var_2_2 = var_2_6
				var_2_3 = iter_2_1
			end
		end
	end

	if not var_2_3 then
		return {}
	end

	if var_2_2 and arg_2_0:getDistance() > 0 and var_2_2 > arg_2_0:getDistance() then
		return {}
	end

	return var_2_3 and {
		var_2_3
	} or {}
end

function var_0_0.A2(arg_3_0, arg_3_1, arg_3_2)
	return var_0_0.aliveTargets(arg_3_1)
end

function var_0_0.A3(arg_4_0, arg_4_1, arg_4_2)
	if not var_0_0.timeSeed_ then
		var_0_0.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_0.timeSeed_):reverse():sub(1, 6)))

	local var_4_0 = math.random(tonumber(os.time()))

	var_0_0.timeSeed_ = var_4_0

	local var_4_1 = var_0_0.A2(arg_4_0, arg_4_1, arg_4_2)

	if not var_4_1 or next(var_4_1) == nil then
		return {}
	end

	math.randomseed(var_4_0)

	return {
		var_4_1[math.random(#var_4_1)]
	}
end

function var_0_0.A4(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = var_0_0.A2(arg_5_0, arg_5_1, arg_5_2)
	local var_5_1
	local var_5_2

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if not var_5_1 or var_5_2 > iter_5_1:getHp() / iter_5_1:getHpLimit() or var_5_2 == iter_5_1:getHp() / iter_5_1:getHpLimit() and var_5_1:getHp() > iter_5_1:getHp() then
			var_5_1 = iter_5_1
			var_5_2 = var_5_1:getHp() / var_5_1:getHpLimit()
		end
	end

	if var_5_1 then
		return {
			var_5_1
		}
	else
		return {}
	end
end

function var_0_0.A5(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0:getFighterModel():getFlipX()
	local var_6_1 = var_0_0.A2(arg_6_0, arg_6_1, arg_6_2)
	local var_6_2, var_6_3 = arg_6_0.fighterModel:getPosition()
	local var_6_4 = {}

	for iter_6_0, iter_6_1 in pairs(var_6_1) do
		local var_6_5, var_6_6 = iter_6_1.fighterModel:getPosition()

		if var_6_0 then
			if var_6_5 < var_6_2 and var_6_2 - var_6_5 <= arg_6_0:getScope() then
				table.insert(var_6_4, iter_6_1)
			end
		elseif var_6_2 < var_6_5 and var_6_5 - var_6_2 <= arg_6_0:getScope() then
			table.insert(var_6_4, iter_6_1)
		end
	end

	return var_6_4
end

function var_0_0.A6(arg_7_0, arg_7_1, arg_7_2)
	return
end

function var_0_0.A7(arg_8_0, arg_8_1, arg_8_2)
	return {}
end

function var_0_0.A8(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}
	local var_9_1 = arg_9_3 == nil and arg_9_0:getScope() or xyd.tables.skill:scope(arg_9_3)

	x1, y1 = arg_9_0.fighterModel:getPosition()

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_2, var_9_3 = iter_9_1.fighterModel:getPosition()

		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_1 >= math.abs(var_9_2 - x1) then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_0.A9(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if not arg_10_3 or type(arg_10_3) == "number" then
		return var_0_0.A1(arg_10_0, arg_10_1, arg_10_2)
	end

	if not arg_10_3.targets_ or not next(arg_10_3.targets_) then
		return
	end

	local var_10_0, var_10_1 = arg_10_3.targets_[1].fighterModel:getPosition()
	local var_10_2
	local var_10_3

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1 ~= arg_10_0 then
			local var_10_4, var_10_5 = iter_10_1.fighterModel:getPosition()
			local var_10_6 = math.abs(var_10_0 - var_10_4)

			if (not var_10_2 or var_10_6 < var_10_2) and not arg_10_3.recordTargets_[iter_10_1.fighterIndex] then
				var_10_2 = var_10_6
				var_10_3 = iter_10_1
			end
		end
	end

	local var_10_7 = {}

	if var_10_3 then
		var_10_7 = {
			var_10_3
		}
	end

	return var_10_7
end

function var_0_0.A13(arg_11_0, arg_11_1, arg_11_2)
	return {
		arg_11_0
	}
end

function var_0_0.A14(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = var_0_0.A2(arg_12_0, arg_12_1, arg_12_2)
	local var_12_1
	local var_12_2

	for iter_12_0, iter_12_1 in pairs(var_12_0) do
		if not var_12_1 or var_12_2 < iter_12_1:getHp() / iter_12_1:getHpLimit() or var_12_2 == iter_12_1:getHp() / iter_12_1:getHpLimit() and var_12_1:getHp() < iter_12_1:getHp() then
			var_12_1 = iter_12_1
			var_12_2 = var_12_1:getHp() / var_12_1:getHpLimit()
		end
	end

	if var_12_1 then
		return {
			var_12_1
		}
	else
		return {}
	end
end

function var_0_0.A16(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}
	local var_13_1 = arg_13_0:getX()
	local var_13_2 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() then
			table.insert(var_13_2, iter_13_1)
		end
	end

	if not next(var_13_2) then
		return {}
	end

	table.sort(var_13_2, function(arg_14_0, arg_14_1)
		return math.abs(arg_14_0:getX() - var_13_1) < math.abs(arg_14_1:getX() - var_13_1)
	end)

	for iter_13_2, iter_13_3 in ipairs(var_13_2) do
		if iter_13_2 < 6 then
			table.insert(var_13_0, iter_13_3)
		end
	end

	return var_13_0
end

function var_0_0.A17(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0:getX()
	local var_15_1
	local var_15_2

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and (not var_15_1 or var_15_1 < math.abs(iter_15_1:getX() - var_15_0)) then
			var_15_2 = iter_15_1
			var_15_1 = math.abs(iter_15_1:getX() - var_15_0)
		end
	end

	if not var_15_2 then
		return {}
	end

	return {
		var_15_2
	}
end

function var_0_0.A18(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = {}
	local var_16_1 = arg_16_0:getScope()
	local var_16_2 = unpack(var_0_0.A17(arg_16_0, arg_16_1, arg_16_2))

	if not var_16_2 then
		return {}
	end

	x1, y1 = var_16_2.fighterModel:getPosition()

	table.insert(var_16_0, var_16_2)

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_3, var_16_4 = iter_16_1.fighterModel:getPosition()

		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and math.abs(x1 - var_16_3) <= var_16_1 / 2 and iter_16_1 ~= var_16_2 then
			table.insert(var_16_0, iter_16_1)
		end
	end

	return var_16_0
end

function var_0_0.A19(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_0.specialSkills[1]

	if not var_17_0 then
		return {}
	end

	local var_17_1 = var_17_0.skillID
	local var_17_2 = {}
	local var_17_3 = xyd.tables.skill:scope(var_17_1)
	local var_17_4 = var_17_0.buffTarget

	if not var_17_4 then
		return {}
	end

	x1, y1 = var_17_4.fighterModel:getPosition()

	if not var_17_4:isDeath() and not var_17_4:isAffected() then
		table.insert(var_17_2, var_17_4)
	end

	for iter_17_0, iter_17_1 in ipairs(arg_17_1) do
		local var_17_5, var_17_6 = iter_17_1.fighterModel:getPosition()

		if not iter_17_1:isDeath() and not iter_17_1:isAffected() and math.abs(x1 - var_17_5) <= var_17_3 / 2 and iter_17_1 ~= var_17_4 then
			table.insert(var_17_2, iter_17_1)
		end
	end

	return var_17_2
end

function var_0_0.A23(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_0.specialSkills[1]

	if not var_18_0 then
		return {}
	end

	local var_18_1 = var_18_0.skillID
	local var_18_2 = var_18_0.buffTarget

	if not var_18_2 then
		return {}
	end

	return {
		var_18_2
	}
end

function var_0_0.A25(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = {}
	local var_19_1

	for iter_19_0, iter_19_1 in ipairs(arg_19_1) do
		if not iter_19_1:isDeath() and not iter_19_1:isAffected() and iter_19_1.energy < xyd.ENERGY_DECIMAL_BASE and iter_19_1.summonType_ == xyd.summonMonsterType.None and (var_19_1 == nil or var_19_1.energy < iter_19_1.energy) then
			var_19_1 = iter_19_1
		end
	end

	if var_19_1 then
		table.insert(var_19_0, var_19_1)
	end

	return var_19_0
end

function var_0_0.A28(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = var_0_0.A2(arg_20_0, arg_20_1, arg_20_2)
	local var_20_1
	local var_20_2

	if arg_20_0:getTeamType() == xyd.TeamType.A then
		for iter_20_0, iter_20_1 in pairs(var_20_0) do
			if not var_20_1 or var_20_2 > iter_20_1:getHp() / iter_20_1:getHpLimit() or var_20_2 == iter_20_1:getHp() / iter_20_1:getHpLimit() and var_20_1:getX() < iter_20_1:getX() then
				var_20_1 = iter_20_1
				var_20_2 = var_20_1:getHp() / var_20_1:getHpLimit()
			end
		end
	else
		for iter_20_2, iter_20_3 in pairs(var_20_0) do
			if not var_20_1 or var_20_2 > iter_20_3:getHp() / iter_20_3:getHpLimit() or var_20_2 == iter_20_3:getHp() / iter_20_3:getHpLimit() and var_20_1:getX() > iter_20_3:getX() then
				var_20_1 = iter_20_3
				var_20_2 = var_20_1:getHp() / var_20_1:getHpLimit()
			end
		end
	end

	if var_20_1 then
		return {
			var_20_1
		}
	else
		return {}
	end
end

function var_0_0.B1(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0, var_21_1 = arg_21_0.fighterModel:getPosition()
	local var_21_2
	local var_21_3
	local var_21_4 = arg_21_3 == nil and arg_21_0:getDistance() or var_0_1:distance(arg_21_3)

	for iter_21_0, iter_21_1 in ipairs(arg_21_2) do
		if not iter_21_1:isDeath() and not iter_21_1:isAffected() and iter_21_1 ~= arg_21_0 then
			local var_21_5, var_21_6 = iter_21_1.fighterModel:getPosition()
			local var_21_7 = math.abs(var_21_0 - var_21_5)
			local var_21_8 = var_21_5 < var_21_0 == arg_21_0:getFighterModel():getFlipX()

			if (not var_21_2 or var_21_7 < var_21_2) and var_21_8 then
				var_21_2 = var_21_7
				var_21_3 = iter_21_1
			end
		end
	end

	if not var_21_3 then
		return {}
	end

	if var_21_2 and var_21_4 > 0 and var_21_4 < var_21_2 then
		return {}
	end

	return {
		var_21_3
	}
end

function var_0_0.B2(arg_22_0, arg_22_1, arg_22_2)
	return var_0_0.aliveTargets(arg_22_2)
end

function var_0_0.B3(arg_23_0, arg_23_1, arg_23_2)
	if not var_0_0.timeSeed_ then
		var_0_0.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_0.timeSeed_):reverse():sub(1, 6)))

	local var_23_0 = math.random(tonumber(os.time()))

	var_0_0.timeSeed_ = var_23_0

	local var_23_1 = var_0_0.B2(arg_23_0, arg_23_1, arg_23_2)

	if not var_23_1 or next(var_23_1) == nil then
		return {}
	end

	math.randomseed(var_23_0)

	return {
		var_23_1[math.random(#var_23_1)]
	}
end

function var_0_0.B4(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = var_0_0.B2(arg_24_0, arg_24_1, arg_24_2)
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

function var_0_0.B5(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = arg_25_0:getFighterModel():getFlipX()
	local var_25_1 = var_0_0.B2(arg_25_0, arg_25_1, arg_25_2)
	local var_25_2, var_25_3 = arg_25_0.fighterModel:getPosition()
	local var_25_4 = arg_25_3 == nil and arg_25_0:getScope() or xyd.tables.skill:scope(arg_25_3)
	local var_25_5 = {}

	for iter_25_0, iter_25_1 in pairs(var_25_1) do
		local var_25_6, var_25_7 = iter_25_1.fighterModel:getPosition()

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

function var_0_0.B6(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = {}
	local var_26_1, var_26_2 = arg_26_0.fighterModel:getPosition()
	local var_26_3 = arg_26_3 == nil and arg_26_0:getScope() or xyd.tables.skill:scope(arg_26_3)
	local var_26_4 = unpack(var_0_0.B1(arg_26_0, arg_26_1, arg_26_2, arg_26_3))
	local var_26_5 = arg_26_0:getFighterModel():getFlipX()

	if not var_26_4 then
		return {}
	end

	x2, y2 = var_26_4.fighterModel:getPosition()

	if var_26_5 then
		for iter_26_0, iter_26_1 in ipairs(arg_26_2) do
			local var_26_6, var_26_7 = iter_26_1.fighterModel:getPosition()

			if not iter_26_1:isDeath() and not iter_26_1:isAffected() and var_26_6 <= x2 and var_26_3 >= x2 - var_26_6 then
				table.insert(var_26_0, iter_26_1)
			end
		end
	else
		for iter_26_2, iter_26_3 in ipairs(arg_26_2) do
			local var_26_8, var_26_9 = iter_26_3.fighterModel:getPosition()

			if not iter_26_3:isDeath() and not iter_26_3:isAffected() and var_26_8 >= x2 and var_26_3 >= var_26_8 - x2 then
				table.insert(var_26_0, iter_26_3)
			end
		end
	end

	return var_26_0
end

function var_0_0.B7(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = {}
	local var_27_1 = arg_27_3 == nil and arg_27_0:getScope() / 2 or var_0_1:scope(arg_27_3) / 2
	local var_27_2 = unpack(var_0_0.B1(arg_27_0, arg_27_1, arg_27_2))

	if not var_27_2 then
		return {}
	end

	x1, y1 = var_27_2.fighterModel:getPosition()

	table.insert(var_27_0, var_27_2)

	for iter_27_0, iter_27_1 in ipairs(arg_27_2) do
		local var_27_3, var_27_4 = iter_27_1.fighterModel:getPosition()

		if not iter_27_1:isDeath() and not iter_27_1:isAffected() and var_27_1 >= math.abs(x1 - var_27_3) and iter_27_1 ~= var_27_2 then
			table.insert(var_27_0, iter_27_1)
		end
	end

	return var_27_0
end

function var_0_0.B8(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = {}
	local var_28_1 = arg_28_3 == nil and arg_28_0:getScope() or xyd.tables.skill:scope(arg_28_3)

	x1, y1 = arg_28_0.fighterModel:getPosition()

	for iter_28_0, iter_28_1 in ipairs(arg_28_2) do
		local var_28_2, var_28_3 = iter_28_1.fighterModel:getPosition()

		if not iter_28_1:isDeath() and not iter_28_1:isAffected() and var_28_1 >= math.abs(var_28_2 - x1) then
			table.insert(var_28_0, iter_28_1)
		end
	end

	return var_28_0
end

function var_0_0.B9(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if not arg_29_3 or type(arg_29_3) == "number" then
		return var_0_0.B1(arg_29_0, arg_29_1, arg_29_2)
	end

	if not arg_29_3.targets_ or not next(arg_29_3.targets_) then
		return
	end

	local var_29_0 = arg_29_3.targets_
	local var_29_1, var_29_2 = var_29_0[#var_29_0].fighterModel:getPosition()
	local var_29_3
	local var_29_4

	for iter_29_0, iter_29_1 in ipairs(arg_29_2) do
		if not iter_29_1:isDeath() and not iter_29_1:isAffected() and iter_29_1 ~= arg_29_0 then
			local var_29_5, var_29_6 = iter_29_1.fighterModel:getPosition()
			local var_29_7 = math.abs(var_29_1 - var_29_5)

			if (not var_29_3 or var_29_7 < var_29_3) and not arg_29_3.recordTargets_[iter_29_1.fighterIndex] then
				var_29_3 = var_29_7
				var_29_4 = iter_29_1
			end
		end
	end

	local var_29_8 = {}

	if var_29_4 then
		var_29_8 = {
			var_29_4
		}
	end

	return var_29_8
end

function var_0_0.B10(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	if not arg_30_3 or type(arg_30_3) == "number" then
		return var_0_0.B1(arg_30_0, arg_30_1, arg_30_2)
	end

	if not arg_30_3.targets_ or not next(arg_30_3.targets_) then
		return {}
	end

	local var_30_0 = arg_30_3.target
	local var_30_1, var_30_2 = var_30_0.fighterModel:getPosition()
	local var_30_3
	local var_30_4

	for iter_30_0, iter_30_1 in ipairs(arg_30_2) do
		if not iter_30_1:isDeath() and not iter_30_1:isAffected() and iter_30_1 ~= arg_30_0 and iter_30_1 ~= var_30_0 then
			local var_30_5, var_30_6 = iter_30_1.fighterModel:getPosition()
			local var_30_7 = math.abs(var_30_1 - var_30_5)

			if not var_30_3 or var_30_7 < var_30_3 then
				var_30_3 = var_30_7
				var_30_4 = iter_30_1
			end
		end
	end

	local var_30_8 = {}

	if var_30_4 then
		var_30_8 = {
			var_30_4
		}
	end

	return var_30_8
end

function var_0_0.B13(arg_31_0, arg_31_1, arg_31_2)
	return {
		arg_31_0
	}
end

function var_0_0.B14(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = var_0_0.B2(arg_32_0, arg_32_1, arg_32_2)
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

function var_0_0.B15(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = unpack(var_0_0.B1(arg_33_0, arg_33_1, arg_33_2))

	if not var_33_0 then
		return {}
	end

	x1, y1 = var_33_0.fighterModel:getPosition()

	local var_33_1

	for iter_33_0, iter_33_1 in ipairs(arg_33_2) do
		local var_33_2, var_33_3 = iter_33_1.fighterModel:getPosition()

		if not iter_33_1:isDeath() and not iter_33_1:isAffected() and iter_33_1 ~= var_33_0 and (not var_33_1 or math.abs(var_33_2 - x1) < math.abs(var_33_1:getX() - x1)) then
			var_33_1 = iter_33_1
		end
	end

	if not var_33_1 then
		return {
			var_33_0
		}
	end

	return {
		var_33_0,
		var_33_1
	}
end

function var_0_0.B16(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {}
	local var_34_1 = arg_34_0:getX()
	local var_34_2 = {}

	for iter_34_0, iter_34_1 in ipairs(arg_34_2) do
		if not iter_34_1:isDeath() and not iter_34_1:isAffected() then
			table.insert(var_34_2, iter_34_1)
		end
	end

	if not next(var_34_2) then
		return {}
	end

	table.sort(var_34_2, function(arg_35_0, arg_35_1)
		return math.abs(arg_35_0:getX() - var_34_1) < math.abs(arg_35_1:getX() - var_34_1)
	end)

	for iter_34_2, iter_34_3 in ipairs(var_34_2) do
		if iter_34_2 < 6 then
			table.insert(var_34_0, iter_34_3)
		end
	end

	return var_34_0
end

function var_0_0.B17(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_0:getX()
	local var_36_1
	local var_36_2

	for iter_36_0, iter_36_1 in ipairs(arg_36_2) do
		if not iter_36_1:isDeath() and not iter_36_1:isAffected() and (not var_36_1 or var_36_1 < math.abs(iter_36_1:getX() - var_36_0)) then
			var_36_2 = iter_36_1
			var_36_1 = math.abs(iter_36_1:getX() - var_36_0)
		end
	end

	if not var_36_2 then
		return {}
	end

	return {
		var_36_2
	}
end

function var_0_0.B18(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = {}
	local var_37_1 = arg_37_0:getScope()
	local var_37_2 = unpack(var_0_0.B17(arg_37_0, arg_37_1, arg_37_2))

	if not var_37_2 then
		return {}
	end

	x1, y1 = var_37_2.fighterModel:getPosition()

	table.insert(var_37_0, var_37_2)

	for iter_37_0, iter_37_1 in ipairs(arg_37_2) do
		local var_37_3, var_37_4 = iter_37_1.fighterModel:getPosition()

		if not iter_37_1:isDeath() and not iter_37_1:isAffected() and math.abs(x1 - var_37_3) <= var_37_1 / 2 and iter_37_1 ~= var_37_2 then
			table.insert(var_37_0, iter_37_1)
		end
	end

	return var_37_0
end

function var_0_0.B19(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_0.specialSkills[1]

	if not var_38_0 then
		return {}
	end

	local var_38_1 = var_38_0.skillID
	local var_38_2 = {}
	local var_38_3 = xyd.tables.skill:scope(var_38_1)
	local var_38_4 = var_38_0.buffTarget

	if not var_38_4 then
		return {}
	end

	x1, y1 = var_38_4.fighterModel:getPosition()

	if not var_38_4:isDeath() and not var_38_4:isAffected() then
		table.insert(var_38_2, var_38_4)
	end

	for iter_38_0, iter_38_1 in ipairs(arg_38_2) do
		local var_38_5, var_38_6 = iter_38_1.fighterModel:getPosition()

		if not iter_38_1:isDeath() and not iter_38_1:isAffected() and math.abs(x1 - var_38_5) <= var_38_3 / 2 and iter_38_1 ~= var_38_4 then
			table.insert(var_38_2, iter_38_1)
		end
	end

	return var_38_2
end

function var_0_0.B23(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_0.specialSkills[1]

	if not var_39_0 then
		return {}
	end

	local var_39_1 = var_39_0.skillID
	local var_39_2 = var_39_0.buffTarget

	if not var_39_2 then
		return {}
	end

	return {
		var_39_2
	}
end

function var_0_0.B24(arg_40_0, arg_40_1, arg_40_2, arg_40_3)
	local var_40_0 = {}

	arg_40_0.B24 = arg_40_0.B24 or {}
	arg_40_0.B24[arg_40_3] = arg_40_0.B24[arg_40_3] or {}

	local var_40_1 = arg_40_3 == nil and arg_40_0:getScope() or xyd.tables.skill:scope(arg_40_3)

	x1, y1 = arg_40_0.fighterModel:getPosition()

	for iter_40_0, iter_40_1 in ipairs(arg_40_2) do
		local var_40_2, var_40_3 = iter_40_1.fighterModel:getPosition()

		if not iter_40_1:isDeath() and not iter_40_1:isAffected() and var_40_1 >= math.abs(var_40_2 - x1) and not table.keyof(arg_40_0.B24[arg_40_3], iter_40_1) then
			table.insert(var_40_0, iter_40_1)
			table.insert(arg_40_0.B24[arg_40_3], iter_40_1)
		end
	end

	return var_40_0
end

function var_0_0.B25(arg_41_0, arg_41_1, arg_41_2, arg_41_3)
	local var_41_0 = {}
	local var_41_1

	for iter_41_0, iter_41_1 in ipairs(arg_41_2) do
		if not iter_41_1:isDeath() and not iter_41_1:isAffected() and iter_41_1.summonType_ == xyd.summonMonsterType.None and (var_41_1 == nil or var_41_1.energy < iter_41_1.energy) then
			var_41_1 = iter_41_1
		end
	end

	if var_41_1 then
		table.insert(var_41_0, var_41_1)
	end

	return var_41_0
end

function var_0_0.B26(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	local var_42_0 = {}
	local var_42_1 = {}

	for iter_42_0, iter_42_1 in ipairs(arg_42_2) do
		if not iter_42_1:isDeath() and not iter_42_1:isAffected() and not iter_42_1:isHasBuffByID(xyd.MOON_LIGHT_BUFF) then
			table.insert(var_42_1, iter_42_1)
		end
	end

	if next(var_42_1) then
		return var_0_0.B3(arg_42_0, arg_42_1, var_42_1, arg_42_3)
	else
		var_42_0 = var_0_0.B3(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	end

	return var_42_0
end

function var_0_0.B27(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	local var_43_0 = {}
	local var_43_1
	local var_43_2

	if arg_43_0.manualTargetsMoon_ then
		return arg_43_0.manualTargetsMoon_
	end

	for iter_43_0, iter_43_1 in ipairs(arg_43_2) do
		if not iter_43_1:isDeath() and not iter_43_1:isAffected() and iter_43_1:isHasBuffByID(xyd.MOON_LIGHT_BUFF) and (not var_43_1 or var_43_1 < math.abs(iter_43_1:getX() - arg_43_0:getX())) then
			var_43_1 = math.abs(iter_43_1:getX() - arg_43_0:getX())
			var_43_2 = iter_43_1
		end
	end

	if var_43_2 then
		return {
			var_43_2
		}
	else
		var_43_0 = var_0_0.B1(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	end

	return var_43_0
end

function var_0_0.AB1(arg_44_0, arg_44_1, arg_44_2)
	return var_0_0.A1(arg_44_0, arg_44_1, arg_44_2), var_0_0.B1(arg_44_0, arg_44_1, arg_44_2)
end

function var_0_0.AB2(arg_45_0, arg_45_1, arg_45_2)
	return var_0_0.A4(arg_45_0, arg_45_1, arg_45_2), var_0_0.B2(arg_45_0, arg_45_1, arg_45_2)
end

function var_0_0.AB3(arg_46_0, arg_46_1, arg_46_2)
	return var_0_0.A3(arg_46_0, arg_46_1, arg_46_2), var_0_0.B3(arg_46_0, arg_46_1, arg_46_2)
end

function var_0_0.AB4(arg_47_0, arg_47_1, arg_47_2)
	return var_0_0.A4(arg_47_0, arg_47_1, arg_47_2), var_0_0.B4(arg_47_0, arg_47_1, arg_47_2)
end

function var_0_0.AB5(arg_48_0, arg_48_1, arg_48_2)
	return var_0_0.A5(arg_48_0, arg_48_1, arg_48_2), var_0_0.B5(arg_48_0, arg_48_1, arg_48_2)
end

function var_0_0.AB6(arg_49_0, arg_49_1, arg_49_2)
	return var_0_0.A6(arg_49_0, arg_49_1, arg_49_2), var_0_0.B6(arg_49_0, arg_49_1, arg_49_2)
end

function var_0_0.AB7(arg_50_0, arg_50_1, arg_50_2)
	return var_0_0.A7(arg_50_0, arg_50_1, arg_50_2), var_0_0.B7(arg_50_0, arg_50_1, arg_50_2)
end

function var_0_0.AB8(arg_51_0, arg_51_1, arg_51_2)
	return var_0_0.A8(arg_51_0, arg_51_1, arg_51_2), var_0_0.B8(arg_51_0, arg_51_1, arg_51_2)
end

function var_0_0.C3(arg_52_0, arg_52_1, arg_52_2, arg_52_3)
	local var_52_0 = {}

	if arg_52_3 and arg_52_3.manualTargets then
		var_52_0 = arg_52_3.manualTargets
	else
		var_52_0 = var_0_0.B3(arg_52_0, arg_52_1, arg_52_2, arg_52_3.skillID)
	end

	return var_52_0
end

function var_0_0.C5(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local var_53_0 = {}

	if arg_53_3 and arg_53_3.manualTargets then
		var_53_0 = arg_53_3.manualTargets
	else
		var_53_0 = var_0_0.B5(arg_53_0, arg_53_1, arg_53_2, arg_53_3.skillID)
	end

	return var_53_0
end

function var_0_0.C8(arg_54_0, arg_54_1, arg_54_2, arg_54_3)
	if arg_54_3 and arg_54_3.manualTargets then
		return arg_54_3.manualTargets
	end

	local var_54_0 = arg_54_3.skillID

	if xyd.tables.skill:type(var_54_0) == xyd.AttackType.CURE then
		return var_0_0.A8(arg_54_0, arg_54_1, arg_54_2, var_54_0)
	else
		return var_0_0.B8(arg_54_0, arg_54_1, arg_54_2, var_54_0)
	end
end

function var_0_0.C11(arg_55_0, arg_55_1, arg_55_2, arg_55_3)
	local var_55_0 = {}

	for iter_55_0, iter_55_1 in ipairs(var_0_0.aliveTargets(arg_55_2)) do
		if (arg_55_3.iniX_ < iter_55_1:getX() and iter_55_1:getX() <= arg_55_3:getX() or arg_55_3.iniX_ > iter_55_1:getX() and iter_55_1:getX() >= arg_55_3:getX()) and not arg_55_3.targets[iter_55_1.fighterIndex] then
			arg_55_3.targets[iter_55_1.fighterIndex] = iter_55_1

			table.insert(var_55_0, iter_55_1)
		end
	end

	return var_55_0
end

function var_0_0.C12(arg_56_0, arg_56_1, arg_56_2, arg_56_3)
	if arg_56_3 and arg_56_3.manualTargets then
		return arg_56_3.manualTargets
	end

	return var_0_0.B7(arg_56_0, arg_56_1, arg_56_2, arg_56_3.skillID)
end

function var_0_0.C18(arg_57_0, arg_57_1, arg_57_2, arg_57_3)
	if arg_57_3 and arg_57_3.manualTargets then
		return arg_57_3.manualTargets
	end

	return var_0_0.B18(arg_57_0, arg_57_1, arg_57_2)
end

function var_0_0.C20(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	local var_58_0 = var_0_0.C12(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	local var_58_1 = {}

	for iter_58_0, iter_58_1 in pairs(var_58_0) do
		if iter_58_1.hero:getHeroType() ~= xyd.HeroType.WISE then
			table.insert(var_58_1, iter_58_1)
		end
	end

	return var_58_1
end

function var_0_0.C21(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
	local var_59_0 = {}

	for iter_59_0, iter_59_1 in ipairs(var_0_0.aliveTargets(arg_59_2)) do
		if arg_59_3:getX() - arg_59_3:getSkillScope() / 2 < iter_59_1:getX() and iter_59_1:getX() <= arg_59_3:getX() + arg_59_3:getSkillScope() / 2 then
			table.insert(var_59_0, iter_59_1)
		end
	end

	return var_59_0
end

function var_0_0.C22(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	local var_60_0 = {}

	if arg_60_3 and arg_60_3.manualTargets then
		var_60_0 = arg_60_3.manualTargets
	else
		var_60_0 = var_0_0.B6(arg_60_0, arg_60_1, arg_60_2, arg_60_3.skillID)
	end

	return var_60_0
end

function var_0_0.D4(arg_61_0, arg_61_1, arg_61_2)
	local var_61_0 = var_0_0.A2(arg_61_0, arg_61_1, arg_61_2)
	local var_61_1 = var_0_0.B2(arg_61_0, arg_61_1, arg_61_2)
	local var_61_2
	local var_61_3

	for iter_61_0, iter_61_1 in pairs(var_61_0) do
		if not var_61_2 or var_61_3 > iter_61_1:getHp() / iter_61_1:getHpLimit() or var_61_3 == iter_61_1:getHp() / iter_61_1:getHpLimit() and var_61_2:getHp() > iter_61_1:getHp() then
			var_61_2 = iter_61_1
			var_61_3 = var_61_2:getHp() / var_61_2:getHpLimit()
		end
	end

	for iter_61_2, iter_61_3 in pairs(var_61_1) do
		if not var_61_2 or var_61_3 > iter_61_3:getHp() / iter_61_3:getHpLimit() or var_61_3 == iter_61_3:getHp() / iter_61_3:getHpLimit() and var_61_2:getHp() > iter_61_3:getHp() then
			var_61_2 = iter_61_3
			var_61_3 = var_61_2:getHp() / var_61_2:getHpLimit()
		end
	end

	if var_61_2 then
		return {
			var_61_2
		}
	else
		return {}
	end
end

return var_0_0
