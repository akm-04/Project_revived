local var_0_0 = class("ForceExporter")
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Item")
local var_0_3 = import("app.model.Pet")
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.skill

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

local var_0_6 = {
	10001001,
	10001002,
	10001003,
	10001004,
	10001005,
	10001006,
	10001007,
	10001008,
	10001009,
	10001010,
	10001011,
	10001012,
	10001013,
	10001014,
	10001015,
	10001016,
	10001017,
	10001018,
	10001019,
	10001020,
	10001021,
	10001022,
	10001023,
	10001024,
	10001025,
	10001026,
	10001027,
	10001028,
	10001029,
	10001030,
	10001031,
	10001032,
	10001033,
	10001034,
	10001035,
	10001036,
	10001037,
	10001038,
	10001039,
	10001040,
	10001041,
	10001042,
	10001043,
	10001044,
	10001045,
	10001046,
	10001047,
	10001048,
	10001049,
	10001050,
	10001051,
	10001052,
	10001053,
	10001054,
	10001055,
	10001056,
	10001057,
	10001058,
	10001059,
	10001060,
	10001061,
	10001062,
	10001063,
	10001064,
	10001065,
	10001066,
	10001067,
	10001068,
	10001069,
	10001070,
	10001071,
	10001072,
	10001073,
	10001074,
	10001075,
	10001076,
	10001077,
	10001078,
	10001079,
	10001080,
	10001081,
	10001082,
	10001083,
	10001084,
	10001085,
	10001086,
	10001087,
	10001088,
	10001089,
	10001090,
	10001091,
	10001092,
	10001093,
	10001094,
	10001095,
	10001096,
	10001097,
	10001098,
	10001099,
	10001100,
	10001101,
	10001102,
	10001103,
	10001104,
	10001105,
	10001106,
	10001107,
	10001108,
	10001109,
	10001110,
	10001111,
	10001112,
	10001113,
	10001114,
	10001115,
	10001116,
	10001117,
	10001118,
	10001119,
	10001120,
	10001121,
	10001122,
	10001123,
	10001124,
	10001125,
	10001126,
	10001127,
	10001128,
	10001129,
	10001130,
	10001131,
	10001132,
	10001133,
	10001134,
	10001135,
	10001136,
	10001137,
	10001138,
	10001139,
	10001140,
	10001141,
	10001142,
	10001143,
	10001144,
	10001145,
	10001146,
	10001147,
	10001148,
	10001149,
	10001150,
	10001151,
	10001152,
	10001153,
	10001154,
	10001155,
	10001156,
	10001157,
	10001158,
	10001159,
	10001160,
	10001161,
	10001162,
	10001163,
	10001164,
	10001165,
	10001166,
	10001167,
	10001168,
	10001169,
	10001170,
	10001171,
	10001172,
	10001173,
	10001174,
	10001175,
	10001176,
	10001177,
	10001178,
	10001179,
	10001180,
	10001181,
	10001182,
	10001183,
	10001184,
	10001185,
	10001186,
	10001187,
	10001188,
	10001189,
	10001190,
	10001191,
	10001192,
	10001193,
	10001194,
	10001195,
	10001196,
	10001197,
	10001198,
	10001199,
	10001200,
	10001201,
	10001202,
	10001203,
	10001204,
	10001205,
	10001206,
	10001207,
	10001208,
	10001209,
	10001210,
	10001211,
	10001212,
	10001213,
	10001214,
	10001215,
	10001216,
	10001217,
	10001218,
	10001219,
	10001220,
	10001221,
	10001222,
	10001223,
	10001224,
	10001225,
	10001226,
	10001227,
	10001228,
	10001229,
	10001230,
	10001231,
	10001232,
	10001233,
	10001234,
	10001235,
	10001236,
	10001237,
	10001238,
	10001239,
	10001240,
	10001241,
	10001242,
	10001243,
	10001244,
	10001245,
	10001246,
	10001247,
	10001248,
	10001249,
	10001250,
	10001251,
	10001252,
	10001253,
	10001254,
	10001255,
	10001256,
	10001257,
	10001258,
	10001259,
	10001260,
	10001261,
	10001262,
	10001263,
	10001264,
	10001265,
	10001266,
	10001267,
	10001268,
	10001269,
	10001270,
	10001271,
	10001272,
	10001273,
	10001274,
	11001,
	11002,
	11003,
	11004,
	11005,
	11006,
	11007,
	11008,
	11009,
	11010,
	11011,
	11012,
	11013,
	11014
}
local var_0_7 = {
	10010001,
	10020001,
	10030001,
	10040001,
	10050001,
	10060001,
	10070001,
	10080001,
	10090001,
	10100001,
	10110001,
	10120001,
	10130001,
	10140001,
	10150001,
	10160001,
	10170001,
	10180001,
	10190001,
	10200001,
	10210001,
	10220001,
	10230001,
	10240001,
	10250001
}
local var_0_8 = 16
local var_0_9 = 16
local var_0_10 = 10
local var_0_11 = 5
local var_0_12 = {
	110,
	110,
	110,
	110,
	110
}

function var_0_0.save(arg_2_0)
	print("save basic hero force")
	arg_2_0:saveBaseForce()
	print("save basic equip force")
	arg_2_0:saveEquipForce()
	arg_2_0:verify()
end

function var_0_0.savePet(arg_3_0)
	print("save basic pet force")
	arg_3_0:savePetBaseForce()
	print("save pet equip force")
	arg_3_0:savePetEquipForce()
	print("finished")
	arg_3_0:verify()
end

function var_0_0.verify(arg_4_0)
	arg_4_0:verifyHero(10001001, 10, 2, 3, {
		1,
		0,
		0,
		1,
		0,
		1
	}, {
		0,
		0,
		1,
		0,
		2,
		1
	}, {
		10,
		6,
		1,
		1
	})
end

function var_0_0.verifyHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0 = var_0_1.new()
	local var_5_1 = {
		table_id = arg_5_1,
		lev = arg_5_2,
		star = arg_5_3,
		color = arg_5_4,
		equips = arg_5_5,
		fumo_levels = arg_5_6,
		skills = arg_5_7
	}

	var_5_0:populate(var_5_1)

	local var_5_2 = var_5_0:getZhandouli()

	print("Force is " .. var_5_2)
	print("\n")
	print("basic force is " .. var_5_0:getBasicForce())
	print("equip force is " .. var_5_0:getEquipForce())
	print("skill force is " .. var_5_0:getSkillForce())
	print("\n")

	local var_5_3 = arg_5_0:calcBasicForce(arg_5_1, arg_5_2, arg_5_3, arg_5_4)

	print("basic is " .. var_5_3)

	local var_5_4 = arg_5_0:calcEquipForce(arg_5_1, arg_5_4, arg_5_5)

	print("equip is " .. var_5_4)

	local var_5_5 = var_5_0:getEquipList(arg_5_4)
	local var_5_6 = 0

	for iter_5_0, iter_5_1 in pairs(var_5_5) do
		if arg_5_5[iter_5_0] > 0 then
			var_5_6 = var_5_6 + arg_5_0:calcFumoForce(iter_5_1, arg_5_6[iter_5_0])
		end
	end

	print("fumo is " .. var_5_6)
	print("total equip is " .. var_5_4 + var_5_6)

	local var_5_7 = 0

	for iter_5_2, iter_5_3 in pairs(arg_5_7) do
		if iter_5_3 > 0 then
			local var_5_8 = tonumber(var_0_4:getSkill(arg_5_1, iter_5_2)) or 0

			if var_5_8 > 0 then
				var_5_7 = var_5_7 + arg_5_0:calcSkillForce(arg_5_1, var_5_8, iter_5_3)
			end
		end
	end

	print("skill is " .. var_5_7)
	print("total force is " .. math.ceil(var_5_3 + var_5_4 + var_5_6 + var_5_7))
end

function var_0_0.saveBaseForce(arg_6_0)
	mode = mode or "wb"

	for iter_6_0, iter_6_1 in pairs(var_0_6) do
		local var_6_0 = io.open("force/force_base_" .. iter_6_1 .. ".csv", mode)

		print(iter_6_1)
		var_6_0:write("英雄ID\t等級\t星級\t顏色\t基本戰力\n")
		var_6_0:write("table_id\tlevel\tstar\tcolor\tforce\n")

		local var_6_1
		local var_6_2
		local var_6_3 = xyd.getPartnerTypeByTableID(iter_6_1)

		if var_6_3 == xyd.PartnerType.NORMAL then
			var_6_1 = 5
			var_6_2 = var_0_8
		elseif var_6_3 == xyd.PartnerType.SUPER then
			var_6_1 = 10
			var_6_2 = 1
		end

		if var_6_0 then
			print("table id : " .. iter_6_1)

			for iter_6_2 = 1, 100 do
				for iter_6_3 = 1, var_6_1 do
					for iter_6_4 = 1, var_6_2 do
						local var_6_4 = arg_6_0:calcBasicForceRow(iter_6_1, iter_6_2, iter_6_3, iter_6_4)

						if var_6_0:write(var_6_4) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end

			io.close(var_6_0)
		end
	end

	return true
end

function var_0_0.saveBookForce(arg_7_0)
	mode = mode or "wb"

	for iter_7_0, iter_7_1 in pairs(var_0_6) do
		local var_7_0 = io.open("force/force_book_" .. iter_7_1 .. ".csv", mode)

		print(iter_7_1)
		var_7_0:write("英雄ID\t等級\t星級\t图书架\t基本戰力\n")
		var_7_0:write("table_id\tlevel\tstar\tbook\tforce\n")

		if var_7_0 then
			print("table id : " .. iter_7_1)

			for iter_7_2 = 1, 100 do
				for iter_7_3 = 1, 5 do
					for iter_7_4 = 1, 80 do
						local var_7_1 = arg_7_0:calcBookForceRow(iter_7_1, iter_7_2, iter_7_3, iter_7_4)

						if var_7_0:write(var_7_1) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end

			io.close(var_7_0)
		end
	end

	return true
end

function var_0_0.saveHeroAttr(arg_8_0)
	mode = mode or "wb"

	for iter_8_0, iter_8_1 in pairs(var_0_6) do
		local var_8_0 = io.open("force/hero_attr_" .. iter_8_1 .. ".csv", mode)

		print(iter_8_1)
		var_8_0:write("英雄ID\t等級\t星級\t武力\t法术\t灵巧\n")
		var_8_0:write("table_id\tlevel\tstar\tbook\tforce\n")

		if var_8_0 then
			print("table id : " .. iter_8_1)

			for iter_8_2 = 1, 100 do
				for iter_8_3 = 1, 5 do
					for iter_8_4 = 1, 80 do
						local var_8_1 = arg_8_0:calcBookForceRow(iter_8_1, iter_8_2, iter_8_3, iter_8_4)

						if var_8_0:write(var_8_1) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end

			io.close(var_8_0)
		end
	end

	return true
end

function var_0_0.savePetBaseForce(arg_9_0)
	mode = mode or "wb"

	for iter_9_0, iter_9_1 in pairs(var_0_7) do
		local var_9_0 = io.open("force/force_pet_base_" .. iter_9_1 .. ".csv", mode)

		var_9_0:write("宠物ID\t等級\t星級\t顏色\t基本戰力\n")
		var_9_0:write("table_id\tlevel\tstar\tcolor\tforce\n")

		if var_9_0 then
			print("table id : " .. iter_9_1)

			for iter_9_2 = 1, 100 do
				for iter_9_3 = 1, 5 do
					for iter_9_4 = 1, var_0_8 do
						local var_9_1 = arg_9_0:calcPetBasicForceRow(iter_9_1, iter_9_2, iter_9_3, iter_9_4)

						if var_9_0:write(var_9_1) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end

			io.close(var_9_0)
		end
	end

	return true
end

function var_0_0.saveEquipForce(arg_10_0, ...)
	mode = mode or "wb"

	for iter_10_0, iter_10_1 in pairs(var_0_6) do
		local var_10_0 = xyd.getPartnerTypeByTableID(iter_10_1)
		local var_10_1 = var_0_8

		if var_10_0 ~= xyd.PartnerType.NORMAL then
			var_10_1 = 1
		end

		local var_10_2 = io.open("force/force_equip_" .. iter_10_1 .. ".csv", mode)

		var_10_2:write("英雄ID\t顏色\t裝備\t是否二觉\t基本戰力\n")
		var_10_2:write("table_id\tcolor\tequip\tis_twice\tforce\n")
		print("table id : " .. iter_10_1)

		for iter_10_2 = 1, var_10_1 do
			for iter_10_3 = 0, 1 do
				for iter_10_4 = 0, 1 do
					for iter_10_5 = 0, 1 do
						for iter_10_6 = 0, 1 do
							for iter_10_7 = 0, 1 do
								for iter_10_8 = 0, 1 do
									for iter_10_9 = 0, 1 do
										local var_10_3 = {
											iter_10_3,
											iter_10_4,
											iter_10_5,
											iter_10_6,
											iter_10_7,
											iter_10_8
										}
										local var_10_4 = arg_10_0:calcEquipForceRow(iter_10_1, iter_10_2, var_10_3, iter_10_9)

										if var_10_4 and var_10_2:write(var_10_4) == nil then
											print("error in writing record")

											return false
										end
									end
								end
							end
						end
					end
				end
			end
		end

		io.close(var_10_2)
	end

	return true
end

function var_0_0.savePetEquipForce(arg_11_0, ...)
	mode = mode or "wb"

	for iter_11_0, iter_11_1 in pairs(var_0_7) do
		local var_11_0 = io.open("force/force_pet_equip_" .. iter_11_1 .. ".csv", mode)

		var_11_0:write("宠物ID\t顏色\t裝備\t基本戰力\n")
		var_11_0:write("table_id\tcolor\tequip\tforce\n")
		print("table id : " .. iter_11_1)

		for iter_11_2 = 1, var_0_9 do
			for iter_11_3 = 0, 1 do
				for iter_11_4 = 0, 1 do
					for iter_11_5 = 0, 1 do
						local var_11_1 = {
							iter_11_3,
							iter_11_4,
							iter_11_5
						}
						local var_11_2 = arg_11_0:calcPetEquipForceRow(iter_11_1, iter_11_2, var_11_1)

						if var_11_0:write(var_11_2) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end
		end

		io.close(var_11_0)
	end

	return true
end

function var_0_0.saveEquipFumoForce(arg_12_0, ...)
	mode = mode or "wb"

	local var_12_0 = io.open("force/force_fumo.csv", mode)

	if var_12_0 then
		var_12_0:write("裝備ID\t附魔等級\t戰力\n")
		var_12_0:write("table_id\tfumo_level\tforce\n")

		local var_12_1 = {}

		for iter_12_0, iter_12_1 in pairs(var_0_6) do
			print("heroID:" .. iter_12_1)

			local var_12_2
			local var_12_3 = xyd.getPartnerTypeByTableID(iter_12_1)

			if var_12_3 == xyd.PartnerType.NORMAL then
				var_12_2 = var_0_8
			elseif var_12_3 == xyd.PartnerType.SUPER then
				var_12_2 = 1
			end

			for iter_12_2 = 1, var_12_2 do
				hero = var_0_1.new()

				local var_12_4 = {
					table_id = iter_12_1,
					color = iter_12_2
				}

				hero:populate(var_12_4)

				local var_12_5 = hero:getEquipList(iter_12_2)

				for iter_12_3, iter_12_4 in pairs(var_12_5) do
					if iter_12_4:getTableID() ~= 0 then
						local var_12_6 = var_12_1[iter_12_4:getTableID()] or {}

						for iter_12_5 = 1, var_0_11 do
							local var_12_7 = var_12_6[iter_12_5] or {}

							var_12_7.force = arg_12_0:calcFumoForce(iter_12_4, iter_12_5)
							var_12_6[iter_12_5] = var_12_7
						end

						var_12_1[iter_12_4:getTableID()] = var_12_6
					end
				end
			end

			local var_12_8 = var_0_4:afterAwaken(iter_12_1)

			if var_12_8 > 0 then
				local var_12_9 = var_0_4:awakeTwiceItem(var_12_8)

				if var_12_9 > 0 then
					local var_12_10 = var_0_2:new()
					local var_12_11 = {
						table_id = var_12_9,
						item_id = var_12_9
					}

					var_12_10:populate(var_12_11)

					local var_12_12 = var_12_1[var_12_10:getTableID()] or {}

					for iter_12_6 = 1, var_0_11 do
						local var_12_13 = var_12_12[iter_12_6] or {}

						var_12_13.force = arg_12_0:calcFumoForce(var_12_10, iter_12_6)
						var_12_12[iter_12_6] = var_12_13
					end

					var_12_1[var_12_10:getTableID()] = var_12_12
				end
			end
		end

		local var_12_14 = {}

		for iter_12_7, iter_12_8 in pairs(var_12_1) do
			var_12_14[#var_12_14 + 1] = iter_12_7
		end

		table.sort(var_12_14)

		for iter_12_9, iter_12_10 in pairs(var_12_14) do
			local var_12_15 = var_12_1[iter_12_10]

			for iter_12_11 = 1, var_0_11 do
				local var_12_16 = var_12_15[iter_12_11].force
				local var_12_17 = string.format("%d\t%d\t%f\n", iter_12_10, iter_12_11, var_12_16)

				if var_12_0:write(var_12_17) == nil then
					print("error in writing record")

					return false
				end
			end
		end

		io.close(var_12_0)

		return true
	else
		return false
	end
end

function var_0_0.calcBasicForceRow(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	return string.format("%d\t%d\t%d\t%d\t%f\n", arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_0:calcBasicForce(arg_13_1, arg_13_2, arg_13_3, arg_13_4))
end

function var_0_0.calcBookForceRow(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	return string.format("%d\t%d\t%d\t%d\t%f\n", arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_0:calcBookForce(arg_14_1, arg_14_2, arg_14_3, arg_14_4))
end

function var_0_0.calcPetBasicForceRow(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	return string.format("%d\t%d\t%d\t%d\t%f\n", arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_0:calcPetBasicForce(arg_15_1, arg_15_2, arg_15_3, arg_15_4))
end

function var_0_0.calcBasicForce(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = var_0_1.new()
	local var_16_1 = {
		table_id = arg_16_1,
		lev = arg_16_2,
		star = arg_16_3,
		color = arg_16_4
	}

	var_16_0:populate(var_16_1)

	return (var_16_0:getBasicForce())
end

function var_0_0.calcBookForce(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4)
	local var_17_0 = var_0_1.new()
	local var_17_1 = {
		table_id = arg_17_1,
		lev = arg_17_2,
		star = arg_17_3,
		book_shelf_lev = arg_17_4
	}

	var_17_0:populate(var_17_1)

	return (var_17_0:getBookShelfForce())
end

function var_0_0.calcPetBasicForce(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	local var_18_0 = var_0_3.new()
	local var_18_1 = {
		table_id = arg_18_1,
		lev = arg_18_2,
		star = arg_18_3,
		color = arg_18_4
	}

	var_18_0:populate(var_18_1)

	return (var_18_0:getBasicForce())
end

function var_0_0.calcEquipForceRow(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)
	local var_19_0 = ""

	for iter_19_0, iter_19_1 in pairs(arg_19_3) do
		local var_19_1 = tonumber(iter_19_1)

		if var_19_1 then
			var_19_0 = var_19_0 .. var_19_1

			if iter_19_0 < #arg_19_3 then
				var_19_0 = var_19_0 .. "|"
			end
		end
	end

	local var_19_2 = arg_19_0:calcEquipForce(arg_19_1, arg_19_2, arg_19_3, arg_19_4)

	if not var_19_2 then
		return nil
	end

	return string.format("%d\t%d\t%s\t%d\t%f\n", arg_19_1, arg_19_2, var_19_0, arg_19_4, var_19_2)
end

function var_0_0.calcPetEquipForceRow(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = ""

	for iter_20_0, iter_20_1 in pairs(arg_20_3) do
		local var_20_1 = tonumber(iter_20_1)

		if var_20_1 then
			var_20_0 = var_20_0 .. var_20_1

			if iter_20_0 < #arg_20_3 then
				var_20_0 = var_20_0 .. "|"
			end
		end
	end

	local var_20_2 = arg_20_0:calcPetEquipForce(arg_20_1, arg_20_2, arg_20_3)

	return string.format("%d\t%d\t%s\t%f\n", arg_20_1, arg_20_2, var_20_0, var_20_2)
end

function var_0_0.calcEquipForce(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	local var_21_0 = var_0_1.new()
	local var_21_1 = {
		table_id = arg_21_1,
		color = arg_21_2,
		equips = arg_21_3
	}

	if arg_21_4 == 1 then
		var_21_1.table_id = var_0_4:afterAwaken(arg_21_1)

		if var_21_1.table_id <= 0 then
			return nil
		end

		var_21_1.twice_awake_stage = 3
	end

	var_21_0:populate(var_21_1)

	return var_21_0:getEquipForce()
end

function var_0_0.calcPetEquipForce(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	local var_22_0 = var_0_3.new()
	local var_22_1 = {
		table_id = arg_22_1,
		color = arg_22_2,
		equips = arg_22_3
	}

	var_22_0:populate(var_22_1)

	return var_22_0:getEquipForce()
end

function var_0_0.calcFumoForce(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = 0

	for iter_23_0 = 1, xyd.AttributeType.TOTAL_ATTR_NUM do
		var_23_0 = var_23_0 + (arg_23_1:getFumoByLevel(arg_23_2)[iter_23_0] or 0) * xyd.tables.attr:attrScore(iter_23_0)
	end

	return var_23_0
end

function var_0_0.saveSkillForce(arg_24_0)
	mode = mode or "wb"

	local var_24_0 = io.open("force/force_skill.csv", mode)

	if var_24_0 then
		var_24_0:write("英雄ID\t技能索引\t等級\t戰力\n")
		var_24_0:write("table_id\tskill_index\tlevel\tforce\n")

		for iter_24_0, iter_24_1 in pairs(var_0_6) do
			print("table id : " .. iter_24_1)

			for iter_24_2 = 1, xyd.SKILL_INDEX.Awake do
				local var_24_1 = tonumber(var_0_4:getSkill(iter_24_1, iter_24_2)) or 0

				if var_24_1 > 0 then
					for iter_24_3 = 1, var_0_12[iter_24_2] do
						local var_24_2 = arg_24_0:calcSkillForceRow(iter_24_1, iter_24_2, var_24_1, iter_24_3)

						if var_24_0:write(var_24_2) == nil then
							print("error in writing record")

							return false
						end
					end
				end
			end
		end

		io.close(var_24_0)

		return true
	else
		return false
	end
end

function var_0_0.calcSkillForceRow(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	return string.format("%d\t%d\t%d\t%f\n", arg_25_1, arg_25_2, arg_25_4, arg_25_0:calcSkillForce(arg_25_1, arg_25_3, arg_25_4))
end

function var_0_0.calcSkillForce(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	return var_0_5:initPower(arg_26_2) + var_0_5:stepPower(arg_26_2) * arg_26_3
end

return var_0_0
