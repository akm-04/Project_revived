local var_0_0 = {}

local function var_0_1()
	local var_1_0 = 0
	local var_1_1 = {}

	if cc.Application:getInstance():getTargetPlatform() == var_1_0 then
		table.insert(var_1_1, "res/web")
		table.insert(var_1_1, "resources/en_en/web")
		table.insert(var_1_1, "resources/en_en")
	else
		table.insert(var_1_1, xyd.versionUpdatePath .. "res/web")
		table.insert(var_1_1, xyd.versionUpdatePath .. "res")
		table.insert(var_1_1, "res")
	end

	cc.FileUtils:getInstance():setSearchPaths(var_1_1)
end

function var_0_0.run()
	local var_2_0 = 0
	local var_2_1 = 3
	local var_2_2 = 4
	local var_2_3 = 5
	local var_2_4 = cc.Application:getInstance():getTargetPlatform()

	if var_2_4 == var_2_0 then
		package.path = xyd.versionUpdatePath .. "src_32/;source/"
	elseif xyd.getVersionName() == "1.591.0" then
		package.path = xyd.versionUpdatePath .. "src_32/;src/"
	end

	if var_2_4 == var_2_1 then
		xyd.versionUpdateURL = "http://play.google.com/store/apps/details?id=" .. xyd.getPackageName()
	elseif var_2_4 == var_2_2 or var_2_4 == var_2_3 then
		xyd.versionUpdateURL = "itms-apps://itunes.apple.com/us/app/apple-store/id1091131962"
	end

	var_0_1()
	require("UpdateScene"):run()
end

return var_0_0
