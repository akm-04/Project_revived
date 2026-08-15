local var_0_0 = require("lpeg")
local var_0_1 = require("table")
local var_0_2
local var_0_3

if _VERSION == "Lua 5.3" then
	function var_0_2(arg_1_0)
		return string.pack("<s4", arg_1_0)
	end

	function var_0_3(arg_2_0)
		arg_2_0 = (arg_2_0 + 1) * 2

		return string.pack("<I2", arg_2_0)
	end
else
	function var_0_2(arg_3_0)
		local var_3_0 = #arg_3_0
		local var_3_1 = var_3_0 % 256
		local var_3_2 = math.floor(var_3_0 / 256)
		local var_3_3 = var_3_2 % 256
		local var_3_4 = math.floor(var_3_2 / 256)
		local var_3_5 = var_3_4 % 256
		local var_3_6 = math.floor(var_3_4 / 256)

		return string.char(var_3_1) .. string.char(var_3_3) .. string.char(var_3_5) .. string.char(var_3_6) .. arg_3_0
	end

	function var_0_3(arg_4_0)
		arg_4_0 = (arg_4_0 + 1) * 2

		assert(arg_4_0 >= 0 and arg_4_0 < 65536)

		local var_4_0 = arg_4_0 % 256
		local var_4_1 = math.floor(arg_4_0 / 256)

		return string.char(var_4_0) .. string.char(var_4_1)
	end
end

local var_0_4 = var_0_0.P
local var_0_5 = var_0_0.S
local var_0_6 = var_0_0.R
local var_0_7 = var_0_0.C
local var_0_8 = var_0_0.Ct
local var_0_9 = var_0_0.Cg
local var_0_10 = var_0_0.Cc
local var_0_11 = var_0_0.V

local function var_0_12(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 > arg_5_2.pos then
		arg_5_2.line = arg_5_2.line + 1
		arg_5_2.pos = arg_5_1
	end

	return arg_5_1
end

local var_0_13 = var_0_0.Cmt(var_0_0.Carg(1), function(arg_6_0, arg_6_1, arg_6_2)
	error(string.format("syntax error at [%s] line (%d)", arg_6_2.file or "", arg_6_2.line))

	return arg_6_1
end)
local var_0_14 = var_0_4(-1)
local var_0_15 = var_0_0.Cmt((var_0_4("\n") + "\r\n") * var_0_0.Carg(1), var_0_12)
local var_0_16 = "#" * (1 - var_0_15)^0 * (var_0_15 + var_0_14)
local var_0_17 = var_0_5(" \t") + var_0_15 + var_0_16
local var_0_18 = var_0_17^0
local var_0_19 = var_0_17^1
local var_0_20 = var_0_6("az") + var_0_6("AZ") + "_"
local var_0_21 = var_0_20 * (var_0_20 + var_0_6("09"))^0
local var_0_22 = var_0_7(var_0_21)
local var_0_23 = var_0_7(var_0_21 * ("." * var_0_21)^0)
local var_0_24 = var_0_6("09")^1 / tonumber
local var_0_25 = "(" * var_0_18 * var_0_22 * var_0_18 * ")"
local var_0_26 = "(" * var_0_18 * var_0_7(var_0_24) * var_0_18 * ")"

local function var_0_27(arg_7_0)
	return var_0_8(var_0_18 * (arg_7_0 * var_0_19)^0 * arg_7_0^0 * var_0_18)
end

local function var_0_28(arg_8_0, arg_8_1)
	return var_0_8(var_0_9(var_0_10(arg_8_0), "type") * var_0_9(arg_8_1))
end

local var_0_29 = var_0_18 * var_0_4({
	"ALL",
	FIELD = var_0_28("field", var_0_22 * var_0_19 * var_0_24 * var_0_18 * ":" * var_0_18 * var_0_7("*")^-1 * var_0_23 * (var_0_25 + var_0_26)^0),
	STRUCT = var_0_4("{") * var_0_27(var_0_11("FIELD") + var_0_11("TYPE")) * var_0_4("}"),
	TYPE = var_0_28("type", var_0_4(".") * var_0_22 * var_0_18 * var_0_11("STRUCT")),
	SUBPROTO = var_0_8((var_0_7("request") + var_0_7("response")) * var_0_19 * (var_0_23 + var_0_11("STRUCT"))),
	PROTOCOL = var_0_28("protocol", var_0_22 * var_0_19 * var_0_24 * var_0_18 * var_0_4("{") * var_0_27(var_0_11("SUBPROTO")) * var_0_4("}")),
	ALL = var_0_27(var_0_11("TYPE") + var_0_11("PROTOCOL"))
}) * var_0_18
local var_0_30 = {}

function var_0_30.protocol(arg_9_0, arg_9_1)
	local var_9_0 = {
		tag = arg_9_1[2]
	}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1[3]) do
		assert(var_9_0[iter_9_1[1]] == nil)

		local var_9_1 = iter_9_1[2]

		if type(var_9_1) == "table" then
			local var_9_2 = var_9_1

			var_9_1 = arg_9_1[1] .. "." .. iter_9_1[1]
			arg_9_0.type[var_9_1] = var_0_30.type(arg_9_0, {
				var_9_1,
				var_9_2
			})
		end

		var_9_0[iter_9_1[1]] = var_9_1
	end

	return var_9_0
end

function var_0_30.type(arg_10_0, arg_10_1)
	local var_10_0 = {}
	local var_10_1 = arg_10_1[1]
	local var_10_2 = {}
	local var_10_3 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1[2]) do
		if iter_10_1.type == "field" then
			local var_10_4 = iter_10_1[1]

			if var_10_3[var_10_4] then
				error(string.format("redefine %s in type %s", var_10_4, var_10_1))
			end

			var_10_3[var_10_4] = true

			local var_10_5 = iter_10_1[2]

			if var_10_2[var_10_5] then
				error(string.format("redefine tag %d in type %s", var_10_5, var_10_1))
			end

			var_10_2[var_10_5] = true

			local var_10_6 = {
				name = var_10_4,
				tag = var_10_5
			}

			var_0_1.insert(var_10_0, var_10_6)

			local var_10_7 = iter_10_1[3]

			if var_10_7 == "*" then
				var_10_6.array = true
				var_10_7 = iter_10_1[4]
			end

			local var_10_8 = iter_10_1[5]

			if var_10_8 then
				if var_10_7 == "integer" then
					var_10_6.decimal = var_10_8
				else
					assert(var_10_6.array)

					var_10_6.key = var_10_8
				end
			end

			var_10_6.typename = var_10_7
		else
			assert(iter_10_1.type == "type")

			local var_10_9 = var_10_1 .. "." .. iter_10_1[1]

			iter_10_1[1] = var_10_9

			assert(arg_10_0.type[var_10_9] == nil, "redefined " .. var_10_9)

			arg_10_0.type[var_10_9] = var_0_30.type(arg_10_0, iter_10_1)
		end
	end

	var_0_1.sort(var_10_0, function(arg_11_0, arg_11_1)
		return arg_11_0.tag < arg_11_1.tag
	end)

	return var_10_0
end

local function var_0_31(arg_12_0)
	local var_12_0 = {
		type = {},
		protocol = {}
	}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0) do
		local var_12_1 = var_12_0[iter_12_1.type]
		local var_12_2 = iter_12_1[1]

		assert(var_12_1[var_12_2] == nil, "redefined " .. var_12_2)

		var_12_1[var_12_2] = var_0_30[iter_12_1.type](var_12_0, iter_12_1)
	end

	return var_12_0
end

local var_0_32 = {
	boolean = 1,
	string = 2,
	integer = 0
}

local function var_0_33(arg_13_0, arg_13_1, arg_13_2)
	if var_0_32[arg_13_2] then
		return arg_13_2
	end

	local var_13_0 = arg_13_1 .. "." .. arg_13_2

	if arg_13_0[var_13_0] then
		return var_13_0
	else
		arg_13_1 = arg_13_1:match("(.+)%..+$")

		if arg_13_1 then
			return var_0_33(arg_13_0, arg_13_1, arg_13_2)
		elseif arg_13_0[arg_13_2] then
			return arg_13_2
		end
	end
end

local function var_0_34(arg_14_0)
	local var_14_0 = {}
	local var_14_1 = arg_14_0.type

	for iter_14_0, iter_14_1 in pairs(arg_14_0.protocol) do
		local var_14_2 = iter_14_1.tag
		local var_14_3 = iter_14_1.request
		local var_14_4 = iter_14_1.response

		if var_14_0[var_14_2] then
			error(string.format("redefined protocol tag %d at %s", var_14_2, iter_14_0))
		end

		if var_14_3 and not var_14_1[var_14_3] then
			error(string.format("Undefined request type %s in protocol %s", var_14_3, iter_14_0))
		end

		if var_14_4 and not var_14_1[var_14_4] then
			error(string.format("Undefined response type %s in protocol %s", var_14_4, iter_14_0))
		end

		var_14_0[var_14_2] = iter_14_1
	end

	return arg_14_0
end

local function var_0_35(arg_15_0)
	for iter_15_0, iter_15_1 in pairs(arg_15_0.type) do
		for iter_15_2, iter_15_3 in pairs(iter_15_1) do
			local var_15_0 = iter_15_3.typename
			local var_15_1 = var_0_33(arg_15_0.type, iter_15_0, var_15_0)

			if var_15_1 == nil then
				error(string.format("Undefined type %s in type %s", var_15_0, iter_15_0))
			end

			iter_15_3.typename = var_15_1
		end
	end

	return arg_15_0
end

local function var_0_36(arg_16_0, arg_16_1)
	local var_16_0 = {
		line = 1,
		pos = 0,
		file = arg_16_1
	}
	local var_16_1 = var_0_0.match(var_0_29 * -1 + var_0_13, arg_16_0, 1, var_16_0)

	return var_0_35(var_0_34(var_0_31(var_16_1)))
end

local function var_0_37(arg_17_0)
	local var_17_0 = {}

	if arg_17_0.array then
		if arg_17_0.key then
			var_0_1.insert(var_17_0, "\x06\x00")
		else
			var_0_1.insert(var_17_0, "\x05\x00")
		end
	else
		var_0_1.insert(var_17_0, "\x04\x00")
	end

	var_0_1.insert(var_17_0, "\x00\x00")

	if arg_17_0.buildin then
		var_0_1.insert(var_17_0, var_0_3(arg_17_0.buildin))

		if arg_17_0.decimal then
			var_0_1.insert(var_17_0, var_0_3(arg_17_0.decimal))
		else
			var_0_1.insert(var_17_0, "\x01\x00")
		end

		var_0_1.insert(var_17_0, var_0_3(arg_17_0.tag))
	else
		var_0_1.insert(var_17_0, "\x01\x00")
		var_0_1.insert(var_17_0, var_0_3(arg_17_0.type))
		var_0_1.insert(var_17_0, var_0_3(arg_17_0.tag))
	end

	if arg_17_0.array then
		var_0_1.insert(var_17_0, var_0_3(1))
	end

	if arg_17_0.key then
		var_0_1.insert(var_17_0, var_0_3(arg_17_0.key))
	end

	var_0_1.insert(var_17_0, var_0_2(arg_17_0.name))

	return var_0_2(var_0_1.concat(var_17_0))
end

local function var_0_38(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = {}
	local var_18_1 = {}

	for iter_18_0, iter_18_1 in ipairs(arg_18_1) do
		var_18_1.array = iter_18_1.array
		var_18_1.name = iter_18_1.name
		var_18_1.tag = iter_18_1.tag
		var_18_1.decimal = iter_18_1.decimal
		var_18_1.buildin = var_0_32[iter_18_1.typename]

		local var_18_2

		if not var_18_1.buildin then
			var_18_2 = assert(arg_18_2[iter_18_1.typename])
			var_18_1.type = var_18_2.id
		else
			var_18_1.type = nil
		end

		if iter_18_1.key then
			var_18_1.key = var_18_2.fields[iter_18_1.key]

			if not var_18_1.key then
				error("Invalid map index :" .. iter_18_1.key)
			end
		else
			var_18_1.key = nil
		end

		var_0_1.insert(var_18_0, var_0_37(var_18_1))
	end

	local var_18_3

	if #var_18_0 == 0 then
		var_18_3 = {
			"\x01\x00",
			"\x00\x00",
			var_0_2(arg_18_0)
		}
	else
		var_18_3 = {
			"\x02\x00",
			"\x00\x00",
			"\x00\x00",
			var_0_2(arg_18_0),
			var_0_2(var_0_1.concat(var_18_0))
		}
	end

	return var_0_2(var_0_1.concat(var_18_3))
end

local function var_0_39(arg_19_0, arg_19_1, arg_19_2)
	if arg_19_1.request then
		local var_19_0 = arg_19_2[arg_19_1.request]

		if var_19_0 == nil then
			error(string.format("Protocol %s request type %s not found", arg_19_0, arg_19_1.request))
		end

		local var_19_1 = var_19_0.id
	end

	local var_19_2 = {
		"\x04\x00",
		"\x00\x00",
		var_0_3(arg_19_1.tag)
	}

	if arg_19_1.request == nil and arg_19_1.response == nil then
		var_19_2[1] = "\x02\x00"
	else
		if arg_19_1.request then
			var_0_1.insert(var_19_2, var_0_3(arg_19_2[arg_19_1.request].id))
		else
			var_0_1.insert(var_19_2, "\x01\x00")
		end

		if arg_19_1.response then
			var_0_1.insert(var_19_2, var_0_3(arg_19_2[arg_19_1.response].id))
		else
			var_19_2[1] = "\x03\x00"
		end
	end

	var_0_1.insert(var_19_2, var_0_2(arg_19_0))

	return var_0_2(var_0_1.concat(var_19_2))
end

local function var_0_40(arg_20_0, arg_20_1)
	if next(arg_20_0) == nil then
		assert(next(arg_20_1) == nil)

		return "\x00\x00"
	end

	local var_20_0
	local var_20_1
	local var_20_2 = {}

	for iter_20_0 in pairs(arg_20_0) do
		var_0_1.insert(var_20_2, iter_20_0)
	end

	var_0_1.sort(var_20_2)

	for iter_20_1, iter_20_2 in ipairs(var_20_2) do
		local var_20_3 = {}

		for iter_20_3, iter_20_4 in ipairs(arg_20_0[iter_20_2]) do
			if var_0_32[iter_20_4.typename] then
				var_20_3[iter_20_4.name] = iter_20_4.tag
			end
		end

		var_20_2[iter_20_2] = {
			id = iter_20_1 - 1,
			fields = var_20_3
		}
	end

	local var_20_4 = {}

	for iter_20_5, iter_20_6 in ipairs(var_20_2) do
		var_0_1.insert(var_20_4, var_0_38(iter_20_6, arg_20_0[iter_20_6], var_20_2))
	end

	local var_20_5 = var_0_2(var_0_1.concat(var_20_4))

	if next(arg_20_1) then
		local var_20_6 = {}

		for iter_20_7, iter_20_8 in pairs(arg_20_1) do
			var_0_1.insert(var_20_6, iter_20_8)

			iter_20_8.name = iter_20_7
		end

		var_0_1.sort(var_20_6, function(arg_21_0, arg_21_1)
			return arg_21_0.tag < arg_21_1.tag
		end)

		var_20_1 = {}

		for iter_20_9, iter_20_10 in ipairs(var_20_6) do
			var_0_1.insert(var_20_1, var_0_39(iter_20_10.name, iter_20_10, var_20_2))
		end

		var_20_1 = var_0_2(var_0_1.concat(var_20_1))
	end

	local var_20_7

	if var_20_1 == nil then
		var_20_7 = {
			"\x01\x00",
			"\x00\x00",
			var_20_5
		}
	else
		var_20_7 = {
			"\x02\x00",
			"\x00\x00",
			"\x00\x00",
			var_20_5,
			var_20_1
		}
	end

	return var_0_1.concat(var_20_7)
end

local function var_0_41(arg_22_0)
	return var_0_40(arg_22_0.type, arg_22_0.protocol)
end

return {
	dump = function(arg_23_0)
		local var_23_0 = ""

		for iter_23_0 = 1, #arg_23_0 do
			var_23_0 = var_23_0 .. string.format("%02X ", string.byte(arg_23_0, iter_23_0))

			if iter_23_0 % 8 == 0 then
				if iter_23_0 % 16 == 0 then
					print(var_23_0)

					var_23_0 = ""
				else
					var_23_0 = var_23_0 .. "- "
				end
			end
		end

		print(var_23_0)
	end,
	parse = function(arg_24_0, arg_24_1)
		local var_24_0 = var_0_36(arg_24_0, arg_24_1 or "=text")

		return (var_0_41(var_24_0))
	end
}
