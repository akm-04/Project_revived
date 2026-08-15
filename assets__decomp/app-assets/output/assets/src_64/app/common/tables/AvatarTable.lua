local var_0_0 = class("AvatarTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.avatar_type_ = {}
	arg_1_0.description_ = {}
	arg_1_0.open_ = {}
	arg_1_0.type_ = {}
	arg_1_0.partner_id_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.vip_level_ = {}
	arg_1_0.value1_ = {}
	arg_1_0.value2_ = {}
	arg_1_0.is_show_ = {}
	arg_1_0.avatarTime_ = {}
	arg_1_0.base_avatar = {}
	arg_1_0.hero_avatar = {}
	arg_1_0.awaken_avatar = {}
	arg_1_0.specil_avatar = {}
	arg_1_0.avatar_frame = {}
	arg_1_0.active_avatar_ = {}
	arg_1_0.icon_json_ = {}
	arg_1_0.no_turn_ = {}

	import("app.common.tables.TableParser").parse("avatar.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.avatar_type_[var_2_0] = tonumber(arg_2_0.avatar_type)
		arg_1_0.description_[var_2_0] = arg_2_0.description
		arg_1_0.open_[var_2_0] = arg_2_0.open
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.partner_id_[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.icon_[var_2_0] = tonumber(arg_2_0.icon)
		arg_1_0.vip_level_[var_2_0] = tonumber(arg_2_0.vip_level)
		arg_1_0.value1_[var_2_0] = tonumber(arg_2_0.value1)
		arg_1_0.value2_[var_2_0] = tonumber(arg_2_0.value2)
		arg_1_0.is_show_[var_2_0] = tonumber(arg_2_0.is_show)
		arg_1_0.avatarTime_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.active_avatar_[var_2_0] = tonumber(arg_2_0.active_avatar)
		arg_1_0.icon_json_[var_2_0] = arg_2_0.icon_json
		arg_1_0.no_turn_[var_2_0] = tonumber(arg_2_0.no_turn)

		if arg_1_0.avatar_type_[var_2_0] == 1 then
			if arg_1_0.type_[var_2_0] == 1 then
				table.insert(arg_1_0.base_avatar, var_2_0)
			elseif arg_1_0.type_[var_2_0] == 2 or arg_1_0.type_[var_2_0] == 13 then
				arg_1_0.hero_avatar[arg_1_0.partner_id_[var_2_0]] = var_2_0
			elseif arg_1_0.type_[var_2_0] == 3 then
				arg_1_0.awaken_avatar[arg_1_0.partner_id_[var_2_0]] = var_2_0
			else
				table.insert(arg_1_0.specil_avatar, var_2_0)
			end
		elseif arg_1_0.avatar_type_[var_2_0] == 2 then
			table.insert(arg_1_0.avatar_frame, var_2_0)
		end
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1]
end

function var_0_0.suffix(arg_4_0, arg_4_1)
	return arg_4_0.suffix_[arg_4_1] or ""
end

function var_0_0.attrScore(arg_5_0, arg_5_1)
	return arg_5_0.attrScore_[arg_5_1] or 0
end

function var_0_0.getAvatarTime(arg_6_0, arg_6_1)
	return arg_6_0.avatarTime_[arg_6_1] or -1
end

function var_0_0.isActive(arg_7_0, arg_7_1)
	return (arg_7_0.active_avatar_[arg_7_1] or 0) == 1
end

function var_0_0.iconJson(arg_8_0, arg_8_1)
	return arg_8_0.icon_json_[arg_8_1] or ""
end

function var_0_0.icon(arg_9_0, arg_9_1)
	return arg_9_0.icon_[arg_9_1] or 120001001
end

function var_0_0.noTurn(arg_10_0, arg_10_1)
	return (arg_10_0.no_turn_[arg_10_1] or 0) == 1
end

return var_0_0
