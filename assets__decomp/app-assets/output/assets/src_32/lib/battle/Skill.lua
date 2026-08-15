local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Skill")
local var_0_4 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_5 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model

function var_0_3.ctor(arg_1_0, arg_1_1)
	arg_1_0.rootID_ = arg_1_1.skillID
	arg_1_0.fighter_ = arg_1_1.fighter
	arg_1_0.startCount_ = var_0_1.ctx.battle.count

	arg_1_0:init()

	arg_1_0.records_ = {}
	arg_1_0.recordQueue_ = {}
	arg_1_0.records_.queue = {}
	arg_1_0.reportData_ = {}
	arg_1_0.recordReport_ = {}
end

function var_0_3.init(arg_2_0)
	arg_2_0:pushQueue()
end

function var_0_3.isEmptyQueue(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return #arg_3_0.reportData_ < 1
	end

	return #arg_3_0.idQueue_ < 1
end

function var_0_3.lastQueue(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return #arg_4_0.reportData_ <= 1
	end

	return #arg_4_0.idQueue_ <= 1
end

function var_0_3.getFront(arg_5_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if next(arg_5_0.reportData_) == nil then
			return
		end

		return arg_5_0.reportData_[1].start - var_0_1.ctx.battle.count, arg_5_0.reportData_[1].skillID
	end

	return arg_5_0.pretimeQueue_[1], arg_5_0.idQueue_[1]
end

function var_0_3.updateCount(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.pretimeQueue_) do
		arg_6_0.pretimeQueue_[iter_6_0] = iter_6_1 - 1
	end
end

function var_0_3.pushQueue(arg_7_0)
	arg_7_0.idQueue_ = {}
	arg_7_0.pretimeQueue_ = {}

	local var_7_0 = var_0_6:children(arg_7_0.rootID_)

	if var_7_0 and #var_7_0 > 1 then
		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			local var_7_1 = var_0_6:pretime(iter_7_1)

			table.insert(arg_7_0.pretimeQueue_, var_7_1)
			table.insert(arg_7_0.idQueue_, iter_7_1)

			if var_0_6:unitNum(iter_7_1) > 1 then
				for iter_7_2 = 2, var_0_6:unitNum(iter_7_1) do
					table.insert(arg_7_0.pretimeQueue_, var_7_1 + (iter_7_2 - 1) * var_0_6:interval(iter_7_1))
					table.insert(arg_7_0.idQueue_, iter_7_1)
				end
			end
		end

		return
	end

	if var_0_6:unitNum(arg_7_0.rootID_) < 1 then
		-- block empty
	end

	for iter_7_3 = 1, var_0_6:unitNum(arg_7_0.rootID_) do
		local var_7_2 = var_0_6:pretime(arg_7_0.rootID_)

		table.insert(arg_7_0.pretimeQueue_, var_7_2 + (iter_7_3 - 1) * var_0_6:interval(arg_7_0.rootID_))
		table.insert(arg_7_0.idQueue_, arg_7_0.rootID_)
	end
end

function var_0_3.popQueue(arg_8_0)
	if arg_8_0:isEmptyQueue() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_8_0 = table.remove(arg_8_0.reportData_, 1)

		table.insert(arg_8_0.recordReport_, var_8_0)

		return
	end

	table.remove(arg_8_0.pretimeQueue_, 1)
	table.remove(arg_8_0.idQueue_, 1)
end

function var_0_3.getRemp(arg_9_0)
	return var_0_6:reMP(arg_9_0.rootID_)
end

function var_0_3.record_1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0, var_10_1 = arg_10_0:getFront()
	local var_10_2 = {
		start = var_0_1.ctx.battle.count,
		skillID = var_10_1,
		pos = {
			x = arg_10_2:getDesPos("x"),
			y = arg_10_2:getDesPos("y")
		}
	}

	var_10_2.type = "moveunit"
	var_10_2.targets = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		table.insert(var_10_2.targets, iter_10_1.fighterIndex)
	end

	table.insert(arg_10_0.records_.queue, var_0_0.clone(var_10_2))

	var_10_2.unit = arg_10_2

	table.insert(arg_10_0.recordQueue_, var_10_2)
end

function var_0_3.record_2(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0, var_11_1 = arg_11_0:getFront()
	local var_11_2 = {
		start = var_0_1.ctx.battle.count,
		skillID = var_11_1
	}

	var_11_2.type = "attackunit"
	var_11_2.targets = {}
	arg_11_1 = arg_11_1 or {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
		table.insert(var_11_2.targets, iter_11_1.fighterIndex)
	end

	table.insert(arg_11_0.records_.queue, var_0_0.clone(var_11_2))

	var_11_2.units = arg_11_2

	table.insert(arg_11_0.recordQueue_, var_11_2)
end

function var_0_3.writeReport(arg_12_0)
	for iter_12_0, iter_12_1 in ipairs(arg_12_0.recordQueue_) do
		if iter_12_1.type == "attackunit" then
			local var_12_0 = {}

			for iter_12_2, iter_12_3 in ipairs(iter_12_1.units) do
				table.insert(var_12_0, iter_12_3:writeReport())
			end

			arg_12_0.records_.queue[iter_12_0].units = var_12_0
		elseif iter_12_1.type == "moveunit" then
			arg_12_0.records_.queue[iter_12_0].unit = iter_12_1.unit:writeReport()
		end
	end

	arg_12_0.records_.rootID_ = arg_12_0.rootID_
	arg_12_0.records_.start = arg_12_0.startCount_

	return arg_12_0.records_
end

function var_0_3.readReport(arg_13_0, arg_13_1)
	arg_13_0.startCount_ = tonumber(arg_13_1.start)

	for iter_13_0, iter_13_1 in ipairs(arg_13_1.queue) do
		if iter_13_1.type == "moveunit" then
			local var_13_0 = var_0_0.clone(iter_13_1)
			local var_13_1 = {
				skillID = tonumber(iter_13_1.skillID),
				count = tonumber(iter_13_1.start),
				fighter = arg_13_0.fighter_
			}
			local var_13_2 = var_0_4.new(var_13_1)

			var_13_2:readReport(iter_13_1)

			var_13_0.unit = var_13_2

			table.insert(arg_13_0.reportData_, var_13_0)
		elseif iter_13_1.type == "attackunit" then
			local var_13_3 = var_0_0.clone(iter_13_1)

			var_13_3.units = {}

			for iter_13_2, iter_13_3 in ipairs(iter_13_1.units) do
				local var_13_4 = {
					skillID = tonumber(iter_13_3.skillID),
					fighter = arg_13_0.fighter_,
					target = var_0_1.ctx.battle.getFighter(iter_13_3.initTarget),
					count = tonumber(iter_13_3.start),
					reportdata = iter_13_3
				}
				local var_13_5 = var_0_5.new(var_13_4)

				table.insert(var_13_3.units, var_13_5)
			end

			table.insert(arg_13_0.reportData_, var_13_3)
		end
	end
end

function var_0_3.printEndCount(arg_14_0)
	if #arg_14_0.reportData_ > 0 then
		return arg_14_0.reportData_[#arg_14_0.reportData_].start
	end

	return 0
end

return var_0_3
