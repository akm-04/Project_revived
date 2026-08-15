local var_0_0 = class("CabinetBookTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.star_ = {}
	arg_1_0.skillId_ = {}
	arg_1_0.ids_ = {}
	arg_1_0.author_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.piece_ = {}
	arg_1_0.relevant_hero_ = {}
	arg_1_0.hero_to_books_ = {}
	arg_1_0.heros_ = {}
	arg_1_0.skillpage_ = {}
	arg_1_0.is_hide_ = {}

	import("app.common.tables.TableParser").parse("event_centre_cabinetbook.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.star_[var_2_0] = tonumber(arg_2_0.star)
		arg_1_0.skillId_[var_2_0] = xyd.splitToNumber(arg_2_0.skill_id, "|")
		arg_1_0.author_[var_2_0] = tonumber(arg_2_0.author)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.piece_[var_2_0] = tonumber(arg_2_0.piece)
		arg_1_0.relevant_hero_[var_2_0] = xyd.splitToNumber(arg_2_0.relevant_hero, "|")
		arg_1_0.skillpage_[var_2_0] = tonumber(arg_2_0.skillpage)
		arg_1_0.is_hide_[var_2_0] = tonumber(arg_2_0.is_hide)

		table.insert(arg_1_0.ids_, var_2_0)

		for iter_2_0, iter_2_1 in pairs(arg_1_0.relevant_hero_[var_2_0]) do
			if arg_1_0.hero_to_books_[iter_2_1] == nil then
				arg_1_0.hero_to_books_[iter_2_1] = {}

				table.insert(arg_1_0.heros_, iter_2_1)
			end

			table.insert(arg_1_0.hero_to_books_[iter_2_1], var_2_0)
		end
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 1
end

function var_0_0.star(arg_6_0, arg_6_1)
	return arg_6_0.star_[arg_6_1] or 0
end

function var_0_0.skillId(arg_7_0, arg_7_1)
	return arg_7_0.skillId_[arg_7_1] or {}
end

function var_0_0.author(arg_8_0, arg_8_1)
	return arg_8_0.author_[arg_8_1] or 0
end

function var_0_0.desc(arg_9_0, arg_9_1)
	return arg_9_0.desc_[arg_9_1] or ""
end

function var_0_0.piece(arg_10_0, arg_10_1)
	return arg_10_0.piece_[arg_10_1] or 0
end

function var_0_0.skillPage(arg_11_0, arg_11_1)
	return arg_11_0.skillpage_[arg_11_1] or 0
end

function var_0_0.isHide(arg_12_0, arg_12_1)
	return arg_12_0.is_hide_[arg_12_1] or 0
end

function var_0_0.relevantHero(arg_13_0, arg_13_1)
	return arg_13_0.relevant_hero_[arg_13_1] or {}
end

function var_0_0.getHeros(arg_14_0)
	return arg_14_0.heros_ or {}
end

function var_0_0.getHeroBook(arg_15_0, arg_15_1)
	return arg_15_0.hero_to_books_[arg_15_1] or {}
end

return var_0_0
