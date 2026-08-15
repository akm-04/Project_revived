local var_0_0 = class("Guild", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.populate(arg_3_0, arg_3_1)
	arg_3_0.guildID_ = arg_3_1.guild_id
	arg_3_0.createdPlayerID_ = arg_3_1.created_player_id
	arg_3_0.maxMemberNum_ = arg_3_1.max_num
	arg_3_0.createTime_ = arg_3_1.created_time
	arg_3_0.guildName_ = arg_3_1.guild_name
	arg_3_0.guildDesc_ = arg_3_1.guild_desc
	arg_3_0.bulletin_ = arg_3_1.bulletin
	arg_3_0.members_ = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_1.list) do
		local var_3_0 = import("app.model.GuildMember").new()

		var_3_0:populate(iter_3_1)
		table.insert(arg_3_0.members_, var_3_0)
	end
end
