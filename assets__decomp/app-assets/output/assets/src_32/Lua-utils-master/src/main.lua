function __G__TRACKBACK__(arg_1_0)
	print("----------------------------------------")
	print("LUA ERROR: " .. tostring(arg_1_0) .. "\n")
	print(debug.traceback("", 2))
	print("----------------------------------------")
end

package.path = package.path .. ";src/?.lua;src/framework/protobuf/?.lua"

require("app.MyApp").new():run()
