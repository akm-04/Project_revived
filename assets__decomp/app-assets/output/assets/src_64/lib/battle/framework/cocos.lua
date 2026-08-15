local var_0_0 = {
	printf = function(arg_1_0, ...)
		print(string.format(tostring(arg_1_0), ...))
	end,
	checknumber = function(arg_2_0, arg_2_1)
		return tonumber(arg_2_0, arg_2_1) or 0
	end,
	checkint = function(arg_3_0)
		return math.round(checknumber(arg_3_0))
	end,
	checkbool = function(arg_4_0)
		return arg_4_0 ~= nil and arg_4_0 ~= false
	end,
	checktable = function(arg_5_0)
		if type(arg_5_0) ~= "table" then
			arg_5_0 = {}
		end

		return arg_5_0
	end,
	isset = function(arg_6_0, arg_6_1)
		local var_6_0 = type(arg_6_0)

		return (var_6_0 == "table" or var_6_0 == "userdata") and arg_6_0[arg_6_1] ~= nil
	end,
	clone = function(arg_7_0)
		local var_7_0 = {}

		local function var_7_1(arg_8_0)
			if type(arg_8_0) ~= "table" then
				return arg_8_0
			elseif var_7_0[arg_8_0] then
				return var_7_0[arg_8_0]
			end

			local var_8_0 = {}

			var_7_0[arg_8_0] = var_8_0

			for iter_8_0, iter_8_1 in pairs(arg_8_0) do
				var_8_0[var_7_1(iter_8_0)] = var_7_1(iter_8_1)
			end

			return setmetatable(var_8_0, getmetatable(arg_8_0))
		end

		return var_7_1(arg_7_0)
	end,
	class = function(arg_9_0, arg_9_1)
		local var_9_0 = type(arg_9_1)
		local var_9_1

		if var_9_0 ~= "function" and var_9_0 ~= "table" then
			var_9_0 = nil
			arg_9_1 = nil
		end

		if var_9_0 == "function" or arg_9_1 and arg_9_1.__ctype == 1 then
			var_9_1 = {}

			if var_9_0 == "table" then
				for iter_9_0, iter_9_1 in pairs(arg_9_1) do
					var_9_1[iter_9_0] = iter_9_1
				end

				var_9_1.__create = arg_9_1.__create
				var_9_1.super = arg_9_1
			else
				var_9_1.__create = arg_9_1

				function var_9_1.ctor()
					return
				end
			end

			var_9_1.__cname = arg_9_0
			var_9_1.__ctype = 1

			function var_9_1.new(...)
				local var_11_0 = var_9_1.__create(...)

				for iter_11_0, iter_11_1 in pairs(var_9_1) do
					var_11_0[iter_11_0] = iter_11_1
				end

				var_11_0.class = var_9_1

				var_11_0:ctor(...)

				return var_11_0
			end
		else
			if arg_9_1 then
				var_9_1 = {}

				setmetatable(var_9_1, {
					__index = arg_9_1
				})

				var_9_1.super = arg_9_1
			else
				var_9_1 = {
					ctor = function()
						return
					end
				}
			end

			var_9_1.__cname = arg_9_0
			var_9_1.__ctype = 2
			var_9_1.__index = var_9_1

			function var_9_1.new(...)
				local var_13_0 = setmetatable({}, var_9_1)

				var_13_0.class = var_9_1

				var_13_0:ctor(...)

				return var_13_0
			end
		end

		return var_9_1
	end,
	iskindof = function(arg_14_0, arg_14_1)
		local var_14_0 = type(arg_14_0)
		local var_14_1

		if var_14_0 == "table" then
			var_14_1 = getmetatable(arg_14_0)
		elseif var_14_0 == "userdata" then
			var_14_1 = tolua.getpeer(arg_14_0)
		end

		while var_14_1 do
			if var_14_1.__cname == arg_14_1 then
				return true
			end

			var_14_1 = var_14_1.super
		end

		return false
	end,
	import = function(arg_15_0, arg_15_1)
		local var_15_0
		local var_15_1 = arg_15_0
		local var_15_2 = 1

		while true do
			if string.byte(arg_15_0, var_15_2) ~= 46 then
				var_15_1 = string.sub(arg_15_0, var_15_2)

				if var_15_0 and #var_15_0 > 0 then
					var_15_1 = table.concat(var_15_0, ".") .. "." .. var_15_1
				end

				break
			end

			var_15_2 = var_15_2 + 1

			if not var_15_0 then
				if not arg_15_1 then
					local var_15_3, var_15_4 = debug.getlocal(3, 1)

					arg_15_1 = var_15_4
				end

				var_15_0 = string.split(arg_15_1, ".")
			end

			table.remove(var_15_0, #var_15_0)
		end

		return require(var_15_1)
	end,
	handler = function(arg_16_0, arg_16_1)
		return function(...)
			return arg_16_1(arg_16_0, ...)
		end
	end,
	math = {}
}

function var_0_0.math.newrandomseed()
	local var_18_0, var_18_1 = pcall(function()
		return require("socket")
	end)

	if var_18_0 then
		math.randomseed(var_18_1.gettime() * 1000)
	else
		math.randomseed(os.time())
	end

	math.random()
	math.random()
	math.random()
	math.random()
end

function var_0_0.math.round(arg_20_0)
	arg_20_0 = checknumber(arg_20_0)

	return math.floor(arg_20_0 + 0.5)
end

function var_0_0.math.angle2radian(arg_21_0)
	return arg_21_0 * math.pi / 180
end

function var_0_0.math.radian2angle(arg_22_0)
	return arg_22_0 / math.pi * 180
end

var_0_0.io = {}

function var_0_0.io.exists(arg_23_0)
	local var_23_0 = io.open(arg_23_0, "r")

	if var_23_0 then
		io.close(var_23_0)

		return true
	end

	return false
end

function var_0_0.io.readfile(arg_24_0)
	local var_24_0 = io.open(arg_24_0, "r")

	if var_24_0 then
		local var_24_1 = var_24_0:read("*a")

		io.close(var_24_0)

		return var_24_1
	end

	return nil
end

function var_0_0.io.writefile(arg_25_0, arg_25_1, arg_25_2)
	arg_25_2 = arg_25_2 or "w+b"

	local var_25_0 = io.open(arg_25_0, arg_25_2)

	if var_25_0 then
		if var_25_0:write(arg_25_1) == nil then
			return false
		end

		io.close(var_25_0)

		return true
	else
		return false
	end
end

function var_0_0.io.pathinfo(arg_26_0)
	local var_26_0 = string.len(arg_26_0)
	local var_26_1 = var_26_0 + 1

	while var_26_0 > 0 do
		local var_26_2 = string.byte(arg_26_0, var_26_0)

		if var_26_2 == 46 then
			var_26_1 = var_26_0
		elseif var_26_2 == 47 then
			break
		end

		var_26_0 = var_26_0 - 1
	end

	local var_26_3 = string.sub(arg_26_0, 1, var_26_0)
	local var_26_4 = string.sub(arg_26_0, var_26_0 + 1)
	local var_26_5 = var_26_1 - var_26_0
	local var_26_6 = string.sub(var_26_4, 1, var_26_5 - 1)
	local var_26_7 = string.sub(var_26_4, var_26_5)

	return {
		dirname = var_26_3,
		filename = var_26_4,
		basename = var_26_6,
		extname = var_26_7
	}
end

function var_0_0.io.filesize(arg_27_0)
	local var_27_0 = false
	local var_27_1 = io.open(arg_27_0, "r")

	if var_27_1 then
		local var_27_2 = var_27_1:seek()

		var_27_0 = var_27_1:seek("end")

		var_27_1:seek("set", var_27_2)
		io.close(var_27_1)
	end

	return var_27_0
end

var_0_0.table = {}

function var_0_0.table.nums(arg_28_0)
	local var_28_0 = 0

	for iter_28_0, iter_28_1 in pairs(arg_28_0) do
		var_28_0 = var_28_0 + 1
	end

	return var_28_0
end

function var_0_0.table.keys(arg_29_0)
	local var_29_0 = {}

	for iter_29_0, iter_29_1 in pairs(arg_29_0) do
		var_29_0[#var_29_0 + 1] = iter_29_0
	end

	return var_29_0
end

function var_0_0.table.values(arg_30_0)
	local var_30_0 = {}

	for iter_30_0, iter_30_1 in pairs(arg_30_0) do
		var_30_0[#var_30_0 + 1] = iter_30_1
	end

	return var_30_0
end

function var_0_0.table.merge(arg_31_0, arg_31_1)
	for iter_31_0, iter_31_1 in pairs(arg_31_1) do
		arg_31_0[iter_31_0] = iter_31_1
	end
end

function var_0_0.table.insertto(arg_32_0, arg_32_1, arg_32_2)
	arg_32_2 = checkint(arg_32_2)

	if arg_32_2 <= 0 then
		arg_32_2 = #arg_32_0 + 1
	end

	local var_32_0 = #arg_32_1

	for iter_32_0 = 0, var_32_0 - 1 do
		arg_32_0[iter_32_0 + arg_32_2] = arg_32_1[iter_32_0 + 1]
	end
end

function var_0_0.table.indexof(arg_33_0, arg_33_1, arg_33_2)
	for iter_33_0 = arg_33_2 or 1, #arg_33_0 do
		if arg_33_0[iter_33_0] == arg_33_1 then
			return iter_33_0
		end
	end

	return false
end

function var_0_0.table.keyof(arg_34_0, arg_34_1)
	for iter_34_0, iter_34_1 in pairs(arg_34_0) do
		if iter_34_1 == arg_34_1 then
			return iter_34_0
		end
	end

	return nil
end

function var_0_0.table.removebyvalue(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = 0
	local var_35_1 = 1
	local var_35_2 = #arg_35_0

	while var_35_1 <= var_35_2 do
		if arg_35_0[var_35_1] == arg_35_1 then
			table.remove(arg_35_0, var_35_1)

			var_35_0 = var_35_0 + 1
			var_35_1 = var_35_1 - 1
			var_35_2 = var_35_2 - 1

			if not arg_35_2 then
				break
			end
		end

		var_35_1 = var_35_1 + 1
	end

	return var_35_0
end

function var_0_0.table.map(arg_36_0, arg_36_1)
	for iter_36_0, iter_36_1 in pairs(arg_36_0) do
		arg_36_0[iter_36_0] = arg_36_1(iter_36_1, iter_36_0)
	end
end

function var_0_0.table.walk(arg_37_0, arg_37_1)
	for iter_37_0, iter_37_1 in pairs(arg_37_0) do
		arg_37_1(iter_37_1, iter_37_0)
	end
end

function var_0_0.table.filter(arg_38_0, arg_38_1)
	for iter_38_0, iter_38_1 in pairs(arg_38_0) do
		if not arg_38_1(iter_38_1, iter_38_0) then
			arg_38_0[iter_38_0] = nil
		end
	end
end

function var_0_0.table.unique(arg_39_0, arg_39_1)
	local var_39_0 = {}
	local var_39_1 = {}
	local var_39_2 = 1

	for iter_39_0, iter_39_1 in pairs(arg_39_0) do
		if not var_39_0[iter_39_1] then
			if arg_39_1 then
				var_39_1[var_39_2] = iter_39_1
				var_39_2 = var_39_2 + 1
			else
				var_39_1[iter_39_0] = iter_39_1
			end

			var_39_0[iter_39_1] = true
		end
	end

	return var_39_1
end

var_0_0.string = {}
string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function var_0_0.string.htmlspecialchars(arg_40_0)
	for iter_40_0, iter_40_1 in pairs(string._htmlspecialchars_set) do
		arg_40_0 = string.gsub(arg_40_0, iter_40_0, iter_40_1)
	end

	return arg_40_0
end

function var_0_0.string.restorehtmlspecialchars(arg_41_0)
	for iter_41_0, iter_41_1 in pairs(string._htmlspecialchars_set) do
		arg_41_0 = string.gsub(arg_41_0, iter_41_1, iter_41_0)
	end

	return arg_41_0
end

function var_0_0.string.nl2br(arg_42_0)
	return string.gsub(arg_42_0, "\n", "<br />")
end

function var_0_0.string.text2html(arg_43_0)
	arg_43_0 = string.gsub(arg_43_0, "\t", "    ")
	arg_43_0 = string.htmlspecialchars(arg_43_0)
	arg_43_0 = string.gsub(arg_43_0, " ", "&nbsp;")
	arg_43_0 = string.nl2br(arg_43_0)

	return arg_43_0
end

function var_0_0.string.split(arg_44_0, arg_44_1)
	arg_44_0 = tostring(arg_44_0)
	arg_44_1 = tostring(arg_44_1)

	if arg_44_1 == "" then
		return false
	end

	local var_44_0 = 0
	local var_44_1 = {}

	for iter_44_0, iter_44_1 in function()
		return string.find(arg_44_0, arg_44_1, var_44_0, true)
	end do
		table.insert(var_44_1, string.sub(arg_44_0, var_44_0, iter_44_0 - 1))

		var_44_0 = iter_44_1 + 1
	end

	table.insert(var_44_1, string.sub(arg_44_0, var_44_0))

	return var_44_1
end

function var_0_0.string.ltrim(arg_46_0)
	return string.gsub(arg_46_0, "^[ \t\n\r]+", "")
end

function var_0_0.string.rtrim(arg_47_0)
	return string.gsub(arg_47_0, "[ \t\n\r]+$", "")
end

function var_0_0.string.trim(arg_48_0)
	arg_48_0 = string.gsub(arg_48_0, "^[ \t\n\r]+", "")

	return string.gsub(arg_48_0, "[ \t\n\r]+$", "")
end

function var_0_0.string.ucfirst(arg_49_0)
	return string.upper(string.sub(arg_49_0, 1, 1)) .. string.sub(arg_49_0, 2)
end

local function var_0_1(arg_50_0)
	return "%" .. string.format("%02X", string.byte(arg_50_0))
end

function var_0_0.string.urlencode(arg_51_0)
	arg_51_0 = string.gsub(tostring(arg_51_0), "\n", "\r\n")
	arg_51_0 = string.gsub(arg_51_0, "([^%w%.%- ])", var_0_1)

	return string.gsub(arg_51_0, " ", "+")
end

function var_0_0.string.urldecode(arg_52_0)
	arg_52_0 = string.gsub(arg_52_0, "+", " ")
	arg_52_0 = string.gsub(arg_52_0, "%%(%x%x)", function(arg_53_0)
		return string.char(checknumber(arg_53_0, 16))
	end)
	arg_52_0 = string.gsub(arg_52_0, "\r\n", "\n")

	return arg_52_0
end

function var_0_0.string.utf8len(arg_54_0)
	local var_54_0 = string.len(arg_54_0)
	local var_54_1 = 0
	local var_54_2 = {
		0,
		192,
		224,
		240,
		248,
		252
	}

	while var_54_0 ~= 0 do
		local var_54_3 = string.byte(arg_54_0, -var_54_0)
		local var_54_4 = #var_54_2

		while var_54_2[var_54_4] do
			if var_54_3 >= var_54_2[var_54_4] then
				var_54_0 = var_54_0 - var_54_4

				break
			end

			var_54_4 = var_54_4 - 1
		end

		var_54_1 = var_54_1 + 1
	end

	return var_54_1
end

function var_0_0.string.formatnumberthousands(arg_55_0)
	local var_55_0 = tostring(checknumber(arg_55_0))
	local var_55_1

	repeat
		local var_55_2

		var_55_0, var_55_2 = string.gsub(var_55_0, "^(-?%d+)(%d%d%d)", "%1,%2")
	until var_55_2 == 0

	return var_55_0
end

function var_0_0.getXinyoudi(arg_56_0)
	return xyd
end

return var_0_0
