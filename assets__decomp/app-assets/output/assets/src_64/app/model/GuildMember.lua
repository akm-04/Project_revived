local var_0_0 = class("GuildMember", import(".Player"))

function var_0_0.ctor(arg_1_0)
	var_0_0.super.ctor(arg_1_0)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.populate(arg_3_0, arg_3_1)
	arg_3_0.playerID_ = tonumber(arg_3_1.player_id)
	arg_3_0.playerName_ = arg_3_1.player_name
	arg_3_0.lev_ = tonumber(arg_3_1.lev)
	arg_3_0.rank_ = tonumber(arg_3_1.rank)
	arg_3_0.point_ = tonumber(arg_3_1.point)
	arg_3_0.lastTime_ = tonumber(arg_3_1.last_time)
	arg_3_0.roleType_ = tonumber(arg_3_1.role_type)
	arg_3_0.repHero_ = import("app.model.RepHero").new()

	arg_3_0.repHero_:populate(arg_3_1.rep_partner)
end
