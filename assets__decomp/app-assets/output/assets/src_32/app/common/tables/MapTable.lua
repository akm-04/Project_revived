local var_0_0 = class("MapTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.prevMapIDs_ = {}
	arg_1_0.nextMapIDs_ = {}
	arg_1_0.firstStages_ = {}
	arg_1_0.types_ = {}
	arg_1_0.dungeonTypes_ = {}
	arg_1_0.dropRunes_ = {}
	arg_1_0.dropEssences_ = {}
	arg_1_0.icons_ = {}
	arg_1_0.dropHeros_ = {}
	arg_1_0.dropInfos_ = {}
	arg_1_0.sceneBackgrounds_ = {}
	arg_1_0.waterColors_ = {}
	arg_1_0.fireColors_ = {}
	arg_1_0.windColors_ = {}
	arg_1_0.godColors_ = {}
	arg_1_0.devilColors_ = {}
	arg_1_0.musics_ = {}
	arg_1_0.openStoryIDs_ = {}

	import("app.common.tables.TableParser").parse("map.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.prevMapIDs_[var_2_0] = tonumber(arg_2_0.prev_id)
		arg_1_0.nextMapIDs_[var_2_0] = tonumber(arg_2_0.next_id)
		arg_1_0.firstStages_[var_2_0] = tonumber(arg_2_0.first_stage)
		arg_1_0.types_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.dungeonTypes_[var_2_0] = tonumber(arg_2_0.dungeon_type)
		arg_1_0.dropRunes_[var_2_0] = tonumber(arg_2_0.drop_rune)
		arg_1_0.dropEssences_[var_2_0] = tonumber(arg_2_0.drop_essence)
		arg_1_0.icons_[var_2_0] = arg_2_0.icon
		arg_1_0.sceneBackgrounds_[var_2_0] = arg_2_0.scene_map
		arg_1_0.waterColors_[var_2_0] = xyd.hex2color4b(arg_2_0.water_color, true)
		arg_1_0.fireColors_[var_2_0] = xyd.hex2color4b(arg_2_0.fire_color, true)
		arg_1_0.windColors_[var_2_0] = xyd.hex2color4b(arg_2_0.wind_color, true)
		arg_1_0.godColors_[var_2_0] = xyd.hex2color4b(arg_2_0.god_color, true)
		arg_1_0.devilColors_[var_2_0] = xyd.hex2color4b(arg_2_0.devil_color, true)
		arg_1_0.musics_[var_2_0] = arg_2_0.music
		arg_1_0.openStoryIDs_[var_2_0] = tonumber(arg_2_0.open_story_id)
		arg_1_0.dropHeros_[var_2_0] = {}

		for iter_2_0 in string.gmatch(arg_2_0.drop_partner, "[^|]+") do
			local var_2_1 = {}

			for iter_2_1 in string.gmatch(iter_2_0, "%d+") do
				table.insert(var_2_1, tonumber(iter_2_1))
			end

			table.insert(arg_1_0.dropHeros_[var_2_0], {
				tableID = var_2_1[1],
				star = var_2_1[2],
				level = var_2_1[3]
			})
		end

		arg_1_0.dropInfos_[var_2_0] = {}

		local function var_2_2(arg_3_0, arg_3_1)
			local var_3_0 = arg_2_0[arg_3_0]
			local var_3_1 = arg_2_0[arg_3_1]
			local var_3_2 = string.gsub(var_3_1, "|", "\n")

			if var_3_0 and string.len(var_3_0) > 0 then
				table.insert(arg_1_0.dropInfos_[var_2_0], {
					icon = var_3_0,
					desc = var_3_2
				})
			end
		end

		var_2_2("drop_icon_1", "drop_desc_1")
		var_2_2("drop_icon_2", "drop_desc_2")
		var_2_2("drop_icon_3", "drop_desc_3")
	end)
end

function var_0_0.firstInstance(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.prevMapIDs_) do
		if iter_4_1 == 0 and arg_4_0.nextMapIDs_[iter_4_0] ~= 0 then
			return iter_4_0
		end
	end

	return nil
end

function var_0_0.instances(arg_5_0)
	if arg_5_0.instances_ == nil then
		arg_5_0.instances_ = {}

		if arg_5_0:firstInstance() then
			local var_5_0 = arg_5_0:firstInstance()

			table.insert(arg_5_0.instances_, var_5_0)

			local var_5_1 = arg_5_0.nextMapIDs_[var_5_0]

			while var_5_1 ~= 0 do
				table.insert(arg_5_0.instances_, var_5_1)

				var_5_1 = arg_5_0.nextMapIDs_[var_5_1]
			end
		end
	end

	return arg_5_0.instances_
end

function var_0_0.instanceAtIdx(arg_6_0, arg_6_1)
	return arg_6_0:instances()[arg_6_1]
end

function var_0_0.name(arg_7_0, arg_7_1)
	return arg_7_0.names_[arg_7_1]
end

function var_0_0.prevMapID(arg_8_0, arg_8_1)
	return arg_8_0.prevMapIDs_[arg_8_1]
end

function var_0_0.nextMapID(arg_9_0, arg_9_1)
	return arg_9_0.nextMapIDs_[arg_9_1]
end

function var_0_0.firstStage(arg_10_0, arg_10_1)
	return arg_10_0.firstStages_[arg_10_1]
end

function var_0_0.mapType(arg_11_0, arg_11_1)
	return arg_11_0.types_[arg_11_1]
end

function var_0_0.dungeonType(arg_12_0, arg_12_1)
	return arg_12_0.dungeonTypes_[arg_12_1]
end

function var_0_0.dropRune(arg_13_0, arg_13_1)
	return arg_13_0.dropRunes_[arg_13_1]
end

function var_0_0.dropEssence(arg_14_0, arg_14_1)
	return arg_14_0.dropEssences_[arg_14_1]
end

function var_0_0.icon(arg_15_0, arg_15_1)
	return arg_15_0.icons_[arg_15_1]
end

function var_0_0.dropHero(arg_16_0, arg_16_1)
	return arg_16_0.dropHeros_[arg_16_1]
end

function var_0_0.dropInfo(arg_17_0, arg_17_1)
	return arg_17_0.dropInfos_[arg_17_1]
end

function var_0_0.sceneBackground(arg_18_0, arg_18_1)
	return arg_18_0.sceneBackgrounds_[arg_18_1]
end

function var_0_0.waterColor(arg_19_0, arg_19_1)
	return arg_19_0.waterColors_[arg_19_1] or xyd.color.WHITE
end

function var_0_0.fireColor(arg_20_0, arg_20_1)
	return arg_20_0.fireColors_[arg_20_1] or xyd.color.WHITE
end

function var_0_0.windColor(arg_21_0, arg_21_1)
	return arg_21_0.windColors_[arg_21_1] or xyd.color.WHITE
end

function var_0_0.godColor(arg_22_0, arg_22_1)
	return arg_22_0.godColors_[arg_22_1] or xyd.color.WHITE
end

function var_0_0.devilColor(arg_23_0, arg_23_1)
	return arg_23_0.devilColors_[arg_23_1] or xyd.color.WHITE
end

function var_0_0.music(arg_24_0, arg_24_1)
	return arg_24_0.musics_[arg_24_1] or ""
end

function var_0_0.openStoryID(arg_25_0, arg_25_1)
	return arg_25_0.openStoryIDs_[arg_25_1]
end

function var_0_0.isOpenMapStory(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.openStoryIDs_) do
		if iter_26_1 == arg_26_1 then
			return true
		end
	end

	return false
end

return var_0_0
