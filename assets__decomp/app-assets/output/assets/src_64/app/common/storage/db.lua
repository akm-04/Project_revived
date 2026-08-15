local var_0_0 = require("lsqlite3")

xyd = xyd or {}
xyd.db = {}

function xyd.db.openLogData()
	if xyd.db.LOG_DATA_DB == nil or not xyd.db.LOG_DATA_DB:isopen() then
		local var_1_0 = cc.FileUtils:getInstance():getDocumentPath() .. "log.db"

		xyd.db.LOG_DATA_DB = var_0_0.open(var_1_0)
	end

	return xyd.db.LOG_DATA_DB
end

function xyd.db.openUserDefaults()
	if xyd.db.USER_DEFAULTS_DB == nil or not xyd.db.USER_DEFAULTS_DB:isopen() then
		local var_2_0 = cc.FileUtils:getInstance():getDocumentPath() .. "defaults.db"

		xyd.db.USER_DEFAULTS_DB = var_0_0.open(var_2_0)
	end

	return xyd.db.USER_DEFAULTS_DB
end

function xyd.db.openGameData()
	if xyd.db.GAME_DATA_DB == nil or not xyd.db.GAME_DATA_DB:isopen() then
		local var_3_0 = cc.FileUtils:getInstance():getDocumentPath() .. "game.db"

		xyd.db.GAME_DATA_DB = var_0_0.open(var_3_0)
	end

	return xyd.db.GAME_DATA_DB
end

function xyd.db.openChatMessageData()
	if xyd.db.CHAT_MESSAGE_DB == nil or not xyd.db.CHAT_MESSAGE_DB:isopen() then
		local var_4_0 = cc.FileUtils:getInstance():getDocumentPath() .. "chat.db"

		xyd.db.CHAT_MESSAGE_DB = var_0_0.open(var_4_0)
	end

	return xyd.db.CHAT_MESSAGE_DB
end

function xyd.db.openFriendMessageData()
	if xyd.db.FRIEND_MESSAGE_DB == nil or not xyd.db.FRIEND_MESSAGE_DB:isopen() then
		local var_5_0 = cc.FileUtils:getInstance():getDocumentPath() .. "friendnew.db"

		xyd.db.FRIEND_MESSAGE_DB = var_0_0.open(var_5_0)
	end

	return xyd.db.FRIEND_MESSAGE_DB
end

function xyd.db.openFriendNewMessagesCountData()
	if xyd.db.FRIEND_NEW_MESSAGE_COUNT_DB == nil or not xyd.db.FRIEND_NEW_MESSAGE_COUNT_DB:isopen() then
		local var_6_0 = cc.FileUtils:getInstance():getDocumentPath() .. "msgcntnew.db"

		xyd.db.FRIEND_NEW_MESSAGE_COUNT_DB = var_0_0.open(var_6_0)
	end

	return xyd.db.FRIEND_NEW_MESSAGE_COUNT_DB
end

function xyd.db.openFriendMessagesNewestTimeData()
	if xyd.db.FRIEND_MESSAGE_NEWEST_TIME_DB == nil or not xyd.db.FRIEND_MESSAGE_NEWEST_TIME_DB:isopen() then
		local var_7_0 = cc.FileUtils:getInstance():getDocumentPath() .. "msgnewesttime.db"

		xyd.db.FRIEND_MESSAGE_NEWEST_TIME_DB = var_0_0.open(var_7_0)
	end

	return xyd.db.FRIEND_MESSAGE_NEWEST_TIME_DB
end

function xyd.db.openStateVariableData()
	if xyd.db.STATE_VARIABLE_DB == nil or not xyd.db.STATE_VARIABLE_DB:isopen() then
		local var_8_0 = cc.FileUtils:getInstance():getDocumentPath() .. "state.db"

		xyd.db.STATE_VARIABLE_DB = var_0_0.open(var_8_0)
	end

	return xyd.db.STATE_VARIABLE_DB
end

function xyd.db.init()
	assert(xyd.db.openLogData():exec("        CREATE TABLE IF NOT EXISTS errorlog (\n            time INT NOT NULL DEFAULT 0,\n            app_v TEXT NOT NULL,\n            version TEXT NOT NULL,\n            isCrash INT NOT NULL DEFAULT 0,\n            dump TEXT NOT NULL,\n            log TEXT NOT NULL\n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openUserDefaults():exec("        CREATE TABLE IF NOT EXISTS settings (\n            id INT NOT NULL PRIMARY KEY,\n            battleSpeed INT NOT NULL DEFAULT 1,\n            isAutoBattle INT NOT NULL DEFAULT 0,\n            isAutoBoss INT NOT NULL DEFAULT 0,\n            backgroundMusicOn INT NOT NULL DEFAULT 1,\n            soundEffectOn INT NOT NULL DEFAULT 1,\n            screenRotation INT NOT NULL DEFAULT 1,\n            powerSavingMode INT NOT NULL DEFAULT 0,\n            battleMusicOn INT NOT NULL DEFAULT 1,\n            battleSoundOn INT NOT NULL DEFAULT 1,\n            autoStandbyOn INT NOT NULL DEFAULT 1,\n            autoDialogOn INT NOT NULL DEFAULT 1,\n            live2dOn INT NOT NULL DEFAULT 1,\n            bgCanLoad INT NOT NULL DEFAULT 0,\n            showFAQ INT NOT NULL DEFAULT 1\n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openChatMessageData():exec("        CREATE TABLE IF NOT EXISTS chatMessageRecord (\n            id TEXT NOT NULL PRIMARY KEY,\n            serverID INT NOT NULL DEFAULT 0,\n            playerID INT NOT NULL DEFAULT 0,\n            channelID INT NOT NULL DEFAULT 0,\n            speakerID INT NOT NULL DEFAULT 0,\n            speakerName TEXT NOT NULL,\n            speakerLev INT NOT NULL DEFAULT 1,\n            speakerAvatar INT NOT NULL DEFAULT 0,\n            time INT NOT NULL DEFAULT 0,\n            messageType INT NOT NULL DEFAULT 0,\n            message TEXT NOT NULL,\n            speakerFrame INT NOT NULL DEFAULT 0,\n            lev INT NOT NULL DEFAULT 0,\n            isGM INT NOT NULL DEFAULT 0,\n            npInfo TEXT NOT NULL DEFAULT \"0@0@0\"\n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openFriendMessageData():exec("        CREATE TABLE IF NOT EXISTS friendMessageRecord (\n            id TEXT NOT NULL PRIMARY KEY,\n            playerID INT NOT NULL DEFAULT 0,\n            friendID INT NOT NULL DEFAULT 0,\n            time INT NOT NULL DEFAULT 0,\n            message TEXT NOT NULL,\n            msgType INT NOT NULL DEFAULT 0,\n            isOwnSend INT NOT NULL DEFAULT 0\n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openFriendNewMessagesCountData():exec("        CREATE TABLE IF NOT EXISTS friendNewMessagesCount (\n            id TEXT NOT NULL PRIMARY KEY,\n            playerID INT NOT NULL DEFAULT 0,\n            friendID INT NOT NULL DEFAULT 0,\n            count INT NOT NULL DEFAULT 0      \n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openFriendMessagesNewestTimeData():exec("        CREATE TABLE IF NOT EXISTS friendMessagesNewestTime (\n            id TEXT NOT NULL PRIMARY KEY,\n            playerID INT NOT NULL DEFAULT 0,\n            friendID INT NOT NULL DEFAULT 0,\n            time INT NOT NULL DEFAULT 0      \n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openStateVariableData():exec("        CREATE TABLE IF NOT EXISTS stateVariable (\n            id TEXT NOT NULL PRIMARY KEY,\n            playerID INT NOT NULL DEFAULT 0,\n            name TEXT NOT NULL,\n            state TEXT NOT NULL DEFAULT \"0\"      \n        );\n    ") == var_0_0.OK)
	assert(xyd.db.openGameData():exec("        CREATE TABLE IF NOT EXISTS meta (\n            id INT NOT NULL PRIMARY KEY,\n            sid TEXT NOT NULL,\n            regionID INT NOT NULL,\n            regionName TEXT NOT NULL,\n            playerID INT NOT NULL DEFAULT 0,\n            playerName TEXT NOT NULL\n        );\n        CREATE TABLE IF NOT EXISTS player (\n            playerID INT NOT NULL PRIMARY KEY,\n            playerName TEXT NOT NULL,\n            mapLevel INT NOT NULL DEFAULT 1\n        );\n        CREATE TABLE IF NOT EXISTS formation (\n            formationID INT NOT NULL,\n            playerID INT NOT NULL DEFAULT 0,\n            formationData TEXT NOT NULL,\n            PRIMARY KEY (formationID,playerID)\n        );\n        CREATE TABLE IF NOT EXISTS wishitems (\n            id INT NOT NULL PRIMARY KEY,\n            refresh_time TEXT NOT NULL,\n            wish_times INT NOT NULL DEFAULT 0\n        );\n        CREATE TABLE IF NOT EXISTS storyGuideData (\n            id INT NOT NULL PRIMARY KEY,\n            storyID INT NOT NULL DEFAULT 0,\n            guideID INT NOT NULL DEFAULT 0,\n            funcIDs TEXT NOT NULL\n        );\n        CREATE TABLE IF NOT EXISTS mission (\n            tableID INT NOT NULL PRIMARY KEY,\n            isNew INT NOT NULL DEFAULT 0\n        );\n        CREATE TABLE IF NOT EXISTS xiaoZhuShou (\n            id INT NOT NULL PRIMARY KEY,\n            xiaoZhuShouID INT NOT NULL DEFAULT 0,\n            noShowEvent INT NOT NULL DEFAULT 0,\n            banners TEXT NOT NULL,\n            latestEventTime INT NOT NULL DEFAULT 0,\n            noEventTime INT NOT NULL DEFAULT 0\n        );\n        CREATE TABLE IF NOT EXISTS hero (\n            id INT NOT NULL PRIMARY KEY,\n            selfHeros TEXT NOT NULL,\n            friendHeros TEXT NOT NULL\n        );\n        CREATE TABLE IF NOT EXISTS mapLevel (\n            id INT NOT NULL PRIMARY KEY,\n            level INT NOT NULL DEFAULT 1\n        );\n        CREATE TABLE IF NOT EXISTS viewConf (\n            id INT NOT NULL PRIMARY KEY,\n            heroViewMode INT NOT NULL DEFAULT 1,\n            heroDataSortType INT NOT NULL DEFAULT 1,\n            socialViewMode INT NOT NULL DEFAULT 1\n        );\n        CREATE TABLE IF NOT EXISTS arenaDefender (\n            id INT NOT NULL PRIMARY KEY,\n            heroData TEXT NOT NULL\n        );\n        CREATE TABLE IF NOT EXISTS marchEnemies (\n            id INT NOT NULL PRIMARY KEY,\n            team_id INT NOT NULL DEFAULT 0,\n            team_name TEXT NOT NULL,\n            team_avatar TEXT NOT NULL,\n            team_level INT NOT NULL DEFAULT 0,\n            partner_id INT NOT NULL DEFAULT 0,\n            table_id INT NOT NULL DEFAULT 0,\n            level INT NOT NULL DEFAULT 0,\n            color INT NOT NULL DEFAULT 0,\n            star INT NOT NULL DEFAULT 0,\n            equips TEXT NOT NULL,\n            fumo TEXT NOT NULL\n        );\n        CREATE TABLE IF NOT EXISTS arenaReportKeys (\n            playerID INT NOT NULL DEFAULT 0,\n            report_key TEXT NOT NULL,\n            PRIMARY KEY (playerID, report_key)\n        );\n        CREATE TABLE IF NOT EXISTS peakArenaReportKeys (\n            playerID INT NOT NULL DEFAULT 0,\n            report_key TEXT NOT NULL,\n            PRIMARY KEY (playerID, report_key)\n        );\n        CREATE TABLE IF NOT EXISTS localGuides (\n            playerID INT NOT NULL DEFAULT 0,\n            localGuideID INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, localGuideID)\n        );\n        CREATE TABLE IF NOT EXISTS activitiesIdFlag (\n            playerID INT NOT NULL DEFAULT 0,\n            activity_id TEXT NOT NULL,\n            flag INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, activity_id)\n        );\n        CREATE TABLE IF NOT EXISTS vipWeekRedMark (\n            playerID INT NOT NULL DEFAULT 0,\n            serverID INT NOT NULL DEFAULT 0,\n            flag INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, serverID)\n        );\n        CREATE TABLE IF NOT EXISTS guildWarRedPoint (\n            id INT NOT NULL DEFAULT 1,\n            step INT NOT NULL DEFAULT 110\n        );\n        CREATE TABLE IF NOT EXISTS campaignAutoStatus (\n            campaignType INT NOT NULL,\n            playerID INT NOT NULL DEFAULT 0,\n            autoStatus INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (campaignType,playerID)\n        );\n        CREATE TABLE IF NOT EXISTS washInfo (\n            playerID INT NOT NULL PRIMARY KEY,\n            heroID INT NOT NULL DEFAULT 0,\n            isPet INT NOT NULL DEFAULT 0\n        );\n        CREATE TABLE IF NOT EXISTS boardRedMark (\n            playerID INT NOT NULL DEFAULT 0,\n            noticeID INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, noticeID)\n        );\n        CREATE TABLE IF NOT EXISTS elementEquipRedMark2 (\n            playerID INT NOT NULL DEFAULT 0,\n            partnerID INT NOT NULL DEFAULT 0,\n            isShow INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, partnerID)\n        );\n        CREATE TABLE IF NOT EXISTS gitTable (\n            charges TEXT NOT NULL,\n            giftbags TEXT NOT NULL,\n            PRIMARY KEY (charges,giftbags)\n        );\n        CREATE TABLE IF NOT EXISTS skinSkillRedMark (\n            playerID INT NOT NULL DEFAULT 0,\n            partnerID INT NOT NULL DEFAULT 0,\n            isShow INT NOT NULL DEFAULT 0,\n            PRIMARY KEY (playerID, partnerID)\n        );\n    ") == var_0_0.OK)

	xyd.db.errorLog = import("app.common.storage.ErrorLog").new()
	xyd.db.settings = import("app.common.storage.Settings").new()
	xyd.db.meta = import("app.common.storage.Meta").new()
	xyd.db.wishItem = import("app.common.storage.WishItem").new()
	xyd.db.storyGuideData = import("app.common.storage.StoryGuideData").new()
	xyd.db.mission = import("app.common.storage.Mission").new()
	xyd.db.xiaoZhuShou = import("app.common.storage.XiaoZhuShou").new()
	xyd.db.formation = import("app.common.storage.Formation").new()
	xyd.db.mapLevel = import("app.common.storage.MapLevel").new()
	xyd.db.viewConf = import("app.common.storage.ViewConf").new()
	xyd.db.arenaDefender = import("app.common.storage.ArenaDefender").new()
	xyd.db.marchEnemies = import("app.common.storage.MarchEnemies").new()
	xyd.db.arenaReportKeys = import("app.common.storage.ArenaReportKeys").new()
	xyd.db.peakArenaReportKeys = import("app.common.storage.PeakArenaReportKeys").new()
	xyd.db.localGuides = import("app.common.storage.LocalGuides").new()
	xyd.db.activitiesIds = import("app.common.storage.ActivitiesIds").new()
	xyd.db.chatMessages = import("app.common.storage.ChatMessageRecord").new()
	xyd.db.vipWeekRedMark = import("app.common.storage.VipWeekRedMarkRecord").new()
	xyd.db.guildWarRedPoint = import("app.common.storage.GuildWarRedPoint").new()
	xyd.db.friendMessages = import("app.common.storage.FriendMessageRecord").new()
	xyd.db.newMessagesCount = import("app.common.storage.FriendNewMessagesCount").new()
	xyd.db.newMessagesTime = import("app.common.storage.FriendMessagesNewestTime").new()
	xyd.db.stateVariable = import("app.common.storage.StateVariable").new()
	xyd.db.campaignAutoStatus = import("app.common.storage.CampaignAutoStatus").new()
	xyd.db.washInfo = import("app.common.storage.washInfo").new()
	xyd.db.boardRedMark = import("app.common.storage.BoardRedMark").new()
	xyd.db.elementEquipRedMark = import("app.common.storage.ElementEquipRedMark").new()
	xyd.db.vipGiftData = import("app.common.storage.VipGiftData").new()
	xyd.db.skinSkillRedMark = import("app.common.storage.SkinSkillRedMark").new()
end

function xyd.db.clean()
	xyd.db.openUserDefaults():exec("        DELETE FROM settings;\n    ")
	xyd.db.settings:reset()
	xyd.db.openGameData():exec("        DELETE FROM storyGuideData;\n        DELETE FROM xiaoZhuShou;\n        DELETE FROM mapLevel;\n        DELETE FROM viewConf;\n        DELETE FROM player;\n        DELETE FROM mission;\n        DELETE FROM arenaDefender;\n        DELETE FROM marchEnemies;\n        DELETE FROM localGuides;\n        DELETE FROM guildWarRedPoint;\n        DELETE FROM washInfo;\n    ")
	xyd.db.formation:reset()
	xyd.db.mapLevel:reset()
	xyd.db.storyGuideData:reset()
	xyd.db.mission:reset()
	xyd.db.viewConf:reset()
	xyd.db.xiaoZhuShou:reset()
	xyd.db.arenaDefender:reset()
	xyd.db.marchEnemies:reset()
	xyd.db.arenaReportKeys:reset()
	xyd.db.peakArenaReportKeys:reset()
	xyd.db.localGuides:reset()
	xyd.db.activitiesIds:reset()
	xyd.db.chatMessages:reset()
	xyd.db.guildWarRedPoint:reset()
	xyd.db.friendMessages:reset()
	xyd.db.newMessagesCount:reset()
	xyd.db.stateVariable:reset()
	xyd.db.campaignAutoStatus:reset()
	xyd.db.boardRedMark:reset()
	xyd.db.elementEquipRedMark:reset()
	xyd.db.vipGiftData:reset()
	xyd.db.skinSkillRedMark:reset()
end

function xyd.db.clearGameData()
	xyd.db.openGameData():exec("        DELETE FROM storyGuideData;\n        DELETE FROM xiaoZhuShou;\n        DELETE FROM mapLevel;\n        DELETE FROM viewConf;\n        DELETE FROM player;\n        DELETE FROM mission;\n        DELETE FROM arenaDefender;\n        DELETE FROM marchEnemies;\n        DELETE FROM localGuides;\n        DELETE FROM guildWarRedPoint;\n        DELETE FROM washInfo;\n    ")
	xyd.db.formation:reset()
	xyd.db.mapLevel:reset()
	xyd.db.storyGuideData:reset()
	xyd.db.mission:reset()
	xyd.db.viewConf:reset()
	xyd.db.xiaoZhuShou:reset()
	xyd.db.arenaDefender:reset()
	xyd.db.marchEnemies:reset()
	xyd.db.arenaReportKeys:reset()
	xyd.db.peakArenaReportKeys:reset()
	xyd.db.localGuides:reset()
	xyd.db.activitiesIds:reset()
	xyd.db.chatMessages:reset()
	xyd.db.guildWarRedPoint:reset()
	xyd.db.friendMessages:reset()
	xyd.db.newMessagesCount:reset()
	xyd.db.stateVariable:reset()
	xyd.db.campaignAutoStatus:reset()
	xyd.db.boardRedMark:reset()
	xyd.db.elementEquipRedMark:reset()
	xyd.db.vipGiftData:reset()
	xyd.db.skinSkillRedMark:reset()
end
