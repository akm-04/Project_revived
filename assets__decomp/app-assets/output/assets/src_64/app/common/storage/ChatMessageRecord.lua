local var_0_0 = class("ChatMessageRecord")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openChatMessageData()

	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE chatMessageRecord ADD COLUMN speakerFrame INT NOT NULL DEFAULT 0;\n    ")
	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE chatMessageRecord ADD COLUMN isGM INT NOT NULL DEFAULT 0;\n    ")
	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE chatMessageRecord ADD COLUMN npInfo TEXT NOT NULL DEFAULT \"0@0@0\";\n    ")
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.messageInfos_ = {}
end

function var_0_0.getChatMessages(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openChatMessageData():prepare("SELECT * FROM chatMessageRecord WHERE playerID = ? AND serverID = ? AND channelID = ?")

	var_3_0:bind_values(arg_3_1, arg_3_2, arg_3_3)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.messageInfos_, iter_3_0)
	end

	return arg_3_0.messageInfos_
end

function var_0_0.addChatMessage(arg_4_0, arg_4_1)
	if not arg_4_1.serverID or not arg_4_1.playerID or not arg_4_1.channelID or not arg_4_1.id or not arg_4_1.time or not arg_4_1.message or not arg_4_1.speakerName or not arg_4_1.speakerID or not arg_4_1.npInfo then
		return
	end

	local var_4_0 = xyd.db.openChatMessageData():prepare("        INSERT INTO chatMessageRecord (id, serverID, playerID, channelID, speakerID, speakerName, speakerLev, speakerAvatar, time, messageType, message, speakerFrame, isGM, npInfo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)\n    ")

	var_4_0:bind_values(arg_4_1.id, arg_4_1.serverID, arg_4_1.playerID, arg_4_1.channelID, arg_4_1.speakerID, arg_4_1.speakerName, arg_4_1.speakerLev, arg_4_1.speakerAvatar, arg_4_1.time, arg_4_1.messageType, arg_4_1.message, arg_4_1.speakerFrame, arg_4_1.isGM, arg_4_1.npInfo)
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.deleteChatMessage(arg_5_0, arg_5_1)
	local var_5_0 = xyd.db.openChatMessageData():prepare("DELETE FROM chatMessageRecord WHERE id = ?")

	var_5_0:bind_values(arg_5_1)
	var_5_0:step()
	var_5_0:reset()
end

return var_0_0
