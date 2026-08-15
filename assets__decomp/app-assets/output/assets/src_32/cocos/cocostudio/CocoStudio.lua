ccs = ccs or {}

require("cocos.cocostudio.StudioConstants")

local function var_0_0(arg_1_0, arg_1_1)
	local var_1_0 = type(arg_1_1)
	local var_1_1

	if var_1_0 ~= "function" and var_1_0 ~= "table" then
		var_1_0 = nil
		arg_1_1 = nil
	end

	if var_1_0 == "function" or arg_1_1 and arg_1_1.__ctype == 1 then
		var_1_1 = {}

		if var_1_0 == "table" then
			for iter_1_0, iter_1_1 in pairs(arg_1_1) do
				var_1_1[iter_1_0] = iter_1_1
			end

			var_1_1.__create = arg_1_1.__create
			var_1_1.super = arg_1_1
		else
			var_1_1.__create = arg_1_1

			function var_1_1.ctor()
				return
			end
		end

		var_1_1.__cname = arg_1_0
		var_1_1.__ctype = 1

		function var_1_1.new(...)
			local var_3_0 = var_1_1.__create(...)

			for iter_3_0, iter_3_1 in pairs(var_1_1) do
				var_3_0[iter_3_0] = iter_3_1
			end

			var_3_0.class = var_1_1

			var_3_0:ctor(...)

			return var_3_0
		end
	else
		if arg_1_1 then
			var_1_1 = {}

			setmetatable(var_1_1, {
				__index = arg_1_1
			})

			var_1_1.super = arg_1_1
		else
			var_1_1 = {
				ctor = function()
					return
				end
			}
		end

		var_1_1.__cname = arg_1_0
		var_1_1.__ctype = 2
		var_1_1.__index = var_1_1

		function var_1_1.new(...)
			local var_5_0 = setmetatable({}, var_1_1)

			var_5_0.class = var_1_1

			var_5_0:ctor(...)

			return var_5_0
		end
	end

	return var_1_1
end

function ccs.sendTriggerEvent(arg_6_0)
	local var_6_0 = ccs.TriggerMng.getInstance():get(arg_6_0)

	if var_6_0 == nil then
		return
	end

	for iter_6_0 = 1, table.getn(var_6_0) do
		local var_6_1 = var_6_0[iter_6_0]

		if var_6_1 ~= nil and var_6_1:detect() then
			var_6_1:done()
		end
	end
end

function ccs.registerTriggerClass(arg_7_0, arg_7_1)
	ccs.TInfo.new(arg_7_0, arg_7_1)
end

ccs.TInfo = var_0_0("TInfo")
ccs.TInfo._className = ""
ccs.TInfo._fun = nil

function ccs.TInfo.ctor(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_2 ~= nil then
		arg_8_0._className = arg_8_1
		arg_8_0._fun = arg_8_2
	else
		arg_8_0._className = arg_8_1._className
		arg_8_0._fun = arg_8_1._fun
	end

	ccs.ObjectFactory.getInstance():registerType(arg_8_0)
end

ccs.ObjectFactory = var_0_0("ObjectFactory")
ccs.ObjectFactory._typeMap = nil
ccs.ObjectFactory._instance = nil

function ccs.ObjectFactory.ctor(arg_9_0)
	arg_9_0._typeMap = {}
end

function ccs.ObjectFactory.getInstance()
	if ccs.ObjectFactory._instance == nil then
		ccs.ObjectFactory._instance = ccs.ObjectFactory.new()
	end

	return ccs.ObjectFactory._instance
end

function ccs.ObjectFactory.destroyInstance()
	ccs.ObjectFactory._instance = nil
end

function ccs.ObjectFactory.createObject(arg_12_0, arg_12_1)
	local var_12_0
	local var_12_1 = arg_12_0._typeMap[arg_12_1]

	if var_12_1 ~= nil then
		var_12_0 = var_12_1._fun()
	end

	return var_12_0
end

function ccs.ObjectFactory.registerType(arg_13_0, arg_13_1)
	arg_13_0._typeMap[arg_13_1._className] = arg_13_1
end

ccs.TriggerObj = var_0_0("TriggerObj")
ccs.TriggerObj._cons = {}
ccs.TriggerObj._acts = {}
ccs.TriggerObj._enable = false
ccs.TriggerObj._id = 0
ccs.TriggerObj._vInt = {}

function ccs.TriggerObj.extend(arg_14_0)
	local var_14_0 = tolua.getpeer(arg_14_0)

	if not var_14_0 then
		var_14_0 = {}

		tolua.setpeer(arg_14_0, var_14_0)
	end

	setmetatable(var_14_0, TriggerObj)

	return arg_14_0
end

function ccs.TriggerObj.ctor(arg_15_0)
	arg_15_0:init()
end

function ccs.TriggerObj.init(arg_16_0)
	arg_16_0._id = 0
	arg_16_0._enable = true
	arg_16_0._cons = {}
	arg_16_0._acts = {}
	arg_16_0._vInt = {}
end

function ccs.TriggerObj.detect(arg_17_0)
	if not arg_17_0._enable or table.getn(arg_17_0._cons) == 0 then
		return true
	end

	local var_17_0 = true
	local var_17_1

	for iter_17_0 = 1, table.getn(arg_17_0._cons) do
		local var_17_2 = arg_17_0._cons[iter_17_0]

		if var_17_2 ~= nil and var_17_2.detect ~= nil then
			var_17_0 = var_17_0 and var_17_2:detect()
		end
	end

	return var_17_0
end

function ccs.TriggerObj.done(arg_18_0)
	if not arg_18_0._enable or table.getn(arg_18_0._acts) == 0 then
		return
	end

	local var_18_0

	for iter_18_0 = 1, table.getn(arg_18_0._acts) do
		local var_18_1 = arg_18_0._acts[iter_18_0]

		if var_18_1 ~= nil and var_18_1.done then
			var_18_1:done()
		end
	end
end

function ccs.TriggerObj.removeAll(arg_19_0)
	local var_19_0

	for iter_19_0 = 1, table.getn(arg_19_0._cons) do
		local var_19_1 = arg_19_0._cons[iter_19_0]

		if var_19_1 ~= nil then
			var_19_1:removeAll()
		end
	end

	arg_19_0._cons = {}

	for iter_19_1 = 1, table.getn(arg_19_0._acts) do
		local var_19_2 = arg_19_0._acts[iter_19_1]

		if var_19_2 ~= nil then
			var_19_2:removeAll()
		end
	end

	arg_19_0._acts = {}
end

function ccs.TriggerObj.serialize(arg_20_0, arg_20_1)
	arg_20_0._id = arg_20_1.id

	local var_20_0 = 0
	local var_20_1 = arg_20_1.conditions

	if var_20_1 ~= nil then
		local var_20_2 = table.getn(var_20_1)

		for iter_20_0 = 1, var_20_2 do
			local var_20_3 = var_20_1[iter_20_0]
			local var_20_4 = var_20_3.classname

			if var_20_4 ~= nil then
				local var_20_5 = ccs.ObjectFactory.getInstance():createObject(var_20_4)

				assert(var_20_5 ~= nil, string.format("class named %s can not implement!", var_20_4))
				var_20_5:serialize(var_20_3)
				var_20_5:init()
				table.insert(arg_20_0._cons, var_20_5)
			end
		end
	end

	local var_20_6 = arg_20_1.actions

	if var_20_6 ~= nil then
		local var_20_7 = table.getn(var_20_6)

		for iter_20_1 = 1, var_20_7 do
			local var_20_8 = var_20_6[iter_20_1]
			local var_20_9 = var_20_8.classname

			if var_20_9 ~= nil then
				local var_20_10 = ccs.ObjectFactory.getInstance():createObject(var_20_9)

				assert(var_20_10 ~= nil, string.format("class named %s can not implement!", var_20_9))
				var_20_10:serialize(var_20_8)
				var_20_10:init()
				table.insert(arg_20_0._acts, var_20_10)
			end
		end
	end

	local var_20_11 = arg_20_1.events

	if var_20_11 ~= nil then
		local var_20_12 = table.getn(var_20_11)

		for iter_20_2 = 1, var_20_12 do
			local var_20_13 = var_20_11[iter_20_2].id

			if var_20_13 >= 0 then
				table.insert(arg_20_0._vInt, var_20_13)
			end
		end
	end
end

function ccs.TriggerObj.getId(arg_21_0)
	return arg_21_0._id
end

function ccs.TriggerObj.setEnable(arg_22_0, arg_22_1)
	arg_22_0._enable = arg_22_1
end

function ccs.TriggerObj.getEvents(arg_23_0)
	return arg_23_0._vInt
end

ccs.TriggerMng = var_0_0("TriggerMng")
ccs.TriggerMng._eventTriggers = nil
ccs.TriggerMng._triggerObjs = nil
ccs.TriggerMng._movementDispatches = nil
ccs.TriggerMng._instance = nil

function ccs.TriggerMng.ctor(arg_24_0)
	arg_24_0._triggerObjs = {}
	arg_24_0._movementDispatches = {}
	arg_24_0._eventTriggers = {}
end

function ccs.TriggerMng.getInstance()
	if ccs.TriggerMng._instance == nil then
		ccs.TriggerMng._instance = ccs.TriggerMng.new()
	end

	return ccs.TriggerMng._instance
end

function ccs.TriggerMng.destroyInstance()
	if ccs.TriggerMng._instance ~= nil then
		ccs.TriggerMng._instance:removeAll()

		ccs.TriggerMng._instance = nil
	end
end

function ccs.TriggerMng.triggerMngVersion(arg_27_0)
	return "1.0.0.0"
end

function ccs.TriggerMng.parse(arg_28_0, arg_28_1)
	local var_28_0 = json.decode(arg_28_1, 1)

	if var_28_0 == nil then
		return
	end

	local var_28_1 = table.getn(var_28_0)

	for iter_28_0 = 1, var_28_1 do
		local var_28_2 = var_28_0[iter_28_0]
		local var_28_3 = ccs.TriggerObj.new()

		var_28_3:serialize(var_28_2)

		local var_28_4 = var_28_3:getEvents()

		for iter_28_1 = 1, table.getn(var_28_4) do
			local var_28_5 = var_28_4[iter_28_1]

			arg_28_0:add(var_28_5, var_28_3)
		end

		arg_28_0._triggerObjs[var_28_3:getId()] = var_28_3
	end
end

function ccs.TriggerMng.get(arg_29_0, arg_29_1)
	return arg_29_0._eventTriggers[arg_29_1]
end

function ccs.TriggerMng.getTriggerObj(arg_30_0, arg_30_1)
	return arg_30_0._triggerObjs[arg_30_1]
end

function ccs.TriggerMng.add(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_0._eventTriggers[arg_31_1]

	if var_31_0 == nil then
		var_31_0 = {}
	end

	local var_31_1 = false

	for iter_31_0 = 1, table.getn(var_31_0) do
		if var_31_0[iter_31_0] == triggers then
			var_31_1 = true

			break
		end
	end

	if not var_31_1 then
		table.insert(var_31_0, arg_31_2)

		arg_31_0._eventTriggers[arg_31_1] = var_31_0
	end
end

function ccs.TriggerMng.removeAll(arg_32_0)
	for iter_32_0 in pairs(arg_32_0._eventTriggers) do
		local var_32_0 = arg_32_0._eventTriggers[iter_32_0]

		for iter_32_1 = 1, table.getn(var_32_0) do
			var_32_0[iter_32_1]:removeAll()
		end
	end

	arg_32_0._eventTriggers = {}
end

function ccs.TriggerMng.remove(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_2 ~= nil then
		return arg_33_0:removeObjByEvent(arg_33_1, arg_33_2)
	end

	assert(arg_33_1 >= 0, "event must be larger than 0")

	if arg_33_0._eventTriggers == nil then
		return false
	end

	local var_33_0 = arg_33_0._eventTriggers[arg_33_1]

	if var_33_0 == nil then
		return false
	end

	for iter_33_0 = 1, table.getn(var_33_0) do
		local var_33_1 = triggers[iter_33_0]

		if var_33_1 ~= nil then
			var_33_1:removeAll()
		end
	end

	arg_33_0._eventTriggers[arg_33_1] = nil

	return true
end

function ccs.TriggerMng.removeObjByEvent(arg_34_0, arg_34_1, arg_34_2)
	assert(arg_34_1 >= 0, "event must be larger than 0")

	if arg_34_0._eventTriggers == nil then
		return false
	end

	local var_34_0 = arg_34_0._eventTriggers[arg_34_1]

	if var_34_0 == nil then
		return false
	end

	for iter_34_0 = 1, table.getn(var_34_0) do
		local var_34_1 = var_34_0[iter_34_0]

		if var_34_1 ~= nil and var_34_1 == arg_34_2 then
			var_34_1:removeAll()
			table.remove(var_34_0, iter_34_0)

			return true
		end
	end
end

function ccs.TriggerMng.removeTriggerObj(arg_35_0, arg_35_1)
	local var_35_0 = arg_35_0.getTriggerObj(arg_35_1)

	if var_35_0 == nil then
		return false
	end

	local var_35_1 = var_35_0:getEvents()

	for iter_35_0 = 1, table.getn(var_35_1) do
		arg_35_0:remove(var_35_1[iter_35_0], var_35_0)
	end

	return true
end

function ccs.TriggerMng.isEmpty(arg_36_0)
	return arg_36_0._eventTriggers ~= nil or table.getn(arg_36_0._eventTriggers) <= 0
end

function __onParseConfig(arg_37_0, arg_37_1)
	if arg_37_0 == cc.ConfigType.COCOSTUDIO then
		ccs.TriggerMng.getInstance():parse(arg_37_1)
	end
end
