function __G__TRACKBACK__(arg_1_0)
	print("----------------------------------------")
	print("LUA ERROR: " .. tostring(arg_1_0) .. "\n")
	print(debug.traceback("", 2))
	print("----------------------------------------")
end

cc.Director:getInstance():setDisplayStats(xyd.isDebug())

xyd.USER_DEFAULTS_VERSION_KEY = "__version__"
xyd.versionUpdatePath = cc.FileUtils:getInstance():getSupportPath() .. xyd.getPackageName() .. "/"

cc.FileUtils:getInstance():createDirectory(xyd.versionUpdatePath)

if xyd.addSkipBackupAttributeToItemAtPath ~= nil then
	xyd.addSkipBackupAttributeToItemAtPath(xyd.versionUpdatePath)
end

local function var_0_0(arg_2_0)
	local var_2_0, var_2_1, var_2_2 = arg_2_0:match("(%d+)%.(%d+)%.(%d+)")
	local var_2_3 = {
		main = tonumber(var_2_0 or 0),
		mid = tonumber(var_2_1 or 0),
		sub = tonumber(var_2_2 or 0)
	}

	setmetatable(var_2_3, {
		__tostring = function()
			return arg_2_0
		end
	})

	return var_2_3
end

local function var_0_1(arg_4_0, arg_4_1)
	if arg_4_0.main ~= arg_4_1.main then
		return arg_4_0.main - arg_4_1.main
	elseif arg_4_0.mid ~= arg_4_1.mid then
		return arg_4_0.mid - arg_4_1.mid
	else
		return arg_4_0.sub - arg_4_1.sub
	end
end

local var_0_2 = 0
local var_0_3 = 3
local var_0_4 = 4

if cc.Application:getInstance():getTargetPlatform() == var_0_2 then
	package.path = xyd.versionUpdatePath .. "src_64/;source/"
else
	package.path = xyd.versionUpdatePath .. "src_64/;src_64/"
end

if jit then
	print("--------------------------turn off jit---------------------")
	jit.off()
	jit.flush()
end

require("boot_64").run()
