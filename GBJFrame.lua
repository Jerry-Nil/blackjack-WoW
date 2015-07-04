-- Author      : Jerry
-- Create Date : 9/27/2013 9:40:14 PM
-- Edit Date   : 9/7/2014

local STARTMSG = '21点游戏（2-10人），来的打1。'
local STARTMSG_TEST = '[测试信息]请参与测试的朋友公会打1，人数2-10即可，刷屏见谅'
local CHAN_A = 'ADDON'
local CHAN_G = 'GUILD'
local CHAN_P = 'PARTY'
local CHAN_R = 'RAID'
local CHAN_W = 'WHISPER'
local GAME_USER_MIN = 2
local GAME_USER_MAX = 10
local GAME_USER_STATUS_READY = 0
local GAME_USER_STATUS_OUT = 1
local GAME_USER_STATUS_GIVPUP = 2
local gameUserCount = 0
local nowUser = nil
local nowQueue = {}
local nowUserCount = 0
local nowUserNumber = 0
local nowUserGiveUp = 0
local maxPoint = 0
local maxUser = nil
local CARD = {'A','A','A','A',
		'2','2','2','2',
		'3','3','3','3',
		'4','4','4','4',
		'5','5','5','5',
		'6','6','6','6',
		'7','7','7','7',
		'8','8','8','8',
		'9','9','9','9',
		'10','10','10','10',
		'J','J','J','J',
		'Q','Q','Q','Q',
		'K','K','K','K'}
local PREFIX = '|cFFFF7711<|r|cFFFFFF99JLib Game>|r|cFFFF7711>|r'
local execFunc = nil
local execChan = nil
local gameStatus = 0 --0:未开始 1:邀请中 2:游戏中
gameQueue = {}
gameCardTable = {}
local GBJDEBUG = false

--CMD
SLASH_GBJ1 = '/gbj'
AddonMessagePrefixGBJ = RegisterAddonMessagePrefix('GBJ')
SlashCmdList['GBJ'] = function(input)
	if input == 'help' then
	elseif input == 'debug' then
		gbjdebug()
	elseif input == 'off' then
		GBJFrame:Hide()
	elseif input == 'on' then
		GBJFrame:Show()
	else
		GBJFrame:Show()
	end
end

--延时函数
local T,F
local function setTimeout(func, time)
	T,F=T or GetTime(),F or CreateFrame("frame")
	F:SetScript("OnUpdate",nil)
	if X then
		X=nil
	else
		X = function()
			local t=GetTime()
			--print(t,T)
			if t-T >= time then
				if type(func) == 'function' then
					func()
				end
				T = nil
				X = nil
				F:SetScript("OnUpdate",X)
			end
		end
	end
	F:SetScript("OnUpdate",X)
end
--洗牌
table.shuffle = function(self)
	local j,x,i
	for i=1,#self do
		j = math.random(#self)
		x = self[i]
		self[i] = self[j]
		self[j] = x
	end
	return self;
end
--num 游戏人数
function setCard(num)
	for i=1,math.ceil((num-1)/3) do
		for j=1,#CARD do
			table.insert(gameCardTable,CARD[j])
		end
	end
	table.shuffle(gameCardTable)
	table.shuffle(gameCardTable)
	table.shuffle(gameCardTable)
	--debug start
	--gameCardTable = {'A','5','10','6','A','5','10','6','A','5','10','6'}
	--debug end
end
--清牌
function clearCard()
	gameCardTable = {}
end
--debug
function gbjdebug()
	if GBJDEBUG then
		GBJDEBUG = false
		print('\124cffffff00Game BlackJack Debug \124cffff0000Off\124r')
	else
		GBJDEBUG = true
		print('\124cffffff00Game BlackJack Debug \124cff00ff00On\124r')
	end
end
--游戏邀请
function GameInvite(type)
	GuildName = GetGuildInfo("player")
	if gameStatus ~= 0 then
		print(PREFIX..'|cFFFF5555正在进行游戏|r')
		return false
	end
	if type == CHAN_G then
		if GuildName == nil then
			print(PREFIX..'|cFFFF5555你还未加入一个公会，不能使用公会频道进行游戏|r')
		else
			SendChatMessage(STARTMSG,CHAN_G)
			execChan = CHAN_G
			execFunc = InviteExec
			gameStatus = 1
		end
	elseif type == CHAN_R then
		if not IsInRaid() then
			print(PREFIX..'|cFFFF5555你还未加入一个团队，不能使用团队频道进行游戏|r')
		else
			SendChatMessage(STARTMSG,CHAN_R)
			execChan = CHAN_R
			execFunc = InviteExec
			gameStatus = 1
		end
	elseif type == CHAN_P then
		if not IsInGroup() then
			print(PREFIX..'|cFFFF5555你还未加入一个小队，不能使用小队频道进行游戏|r')
		else
			SendChatMessage(STARTMSG,CHAN_P)
			execChan = CHAN_P
			execFunc = InviteExec
			gameStatus = 1
		end
	else
	end
end
--邀请处理
function InviteExec(msg, author)
	--print(msg, author)
	if table.getn(gameQueue) >= GAME_USER_MAX then
		SendChatMessage('人数已到上限',execChan);
		return false
	end
	if msg == '1' and gameStatus == 1 then
		gameQueue[author] = {
			['name'] = author,
			['card'] = {},
			['status'] = GAME_USER_STATUS_READY
		}
	elseif msg == '1' and gameStatus ~= 1 then
		SendChatMessage('邀请已经结束',execChan);
		return false
	end
	if table.getn(gameQueue) >= GAME_USER_MAX then
		execFunc = nil
	end
	str = ''
	for k,v in pairs(gameQueue) do
		str = str..k..'. '
	end
	print(PREFIX..'游戏队列:'..str)
end
--游戏
function startGame()
	if gameStatus == 2 then
		--print(gameStatus)
		--print('asdasdasd')
		return false
	end
	gameUserCount = 0
	for k,v in pairs(gameQueue) do
		--str = str..k..'. '
		gameUserCount = gameUserCount+1
	end
	--print('num of game queue is',num)
	if gameUserCount < GAME_USER_MIN or gameUserCount > GAME_USER_MAX then
		return false
	end
	execFunc = nil
	gameStatus = 2
	setCard(gameUserCount)
	--print(table.concat(gameCardTable,', '))
	--print(table.concat(table.shuffle(gameCardTable),', '))
	
	for k,v in pairs(gameQueue) do
		tempCard = table.remove(gameCardTable,1)
		table.insert(v['card'],tempCard)
		SendChatMessage('你的暗牌是'..tempCard,CHAN_W,nil,k)
	end
	
	SendChatMessage('暗牌已发,开始发明牌',execChan)
	
	for k,v in pairs(gameQueue) do
		tempCard = table.remove(gameCardTable,1)
		table.insert(v['card'],tempCard)
		SendChatMessage(k..'：'..tempCard,execChan)
		table.insert(nowQueue,k)
	end
	
	nowUserCount = gameUserCount
	nowUserNumber = 0
	nowUser = gameQueue[nowUserNumber]
	execFunc = GameExec
	gameControl()
end
--测试，已废弃
function testt()
	print(table.concat(gameCardTable,', '))
end
--游戏流程控制
function gameControl()
	--nowUser
	--nowQueue
	--nowUserCount
	--nowUserNumber
	if #gameCardTable == 0 then
		SendChatMessage('牌已发完，大家翻牌',execChan)
		checkAll(true)
		endGame()
	end
	if nowUserNumber == 0 then
		nowUserNumber = 1
		nowUser = nowQueue[1]
		SendChatMessage(nowUser..'要牌吗？要的打1，不要打2',execChan)
	elseif nowUserNumber <= nowUserCount then
		nowUser = nowQueue[nowUserNumber]
		tmpUser = gameQueue[nowUser]
		if tmpUser['status'] == GAME_USER_STATUS_GIVPUP then
			nowUserGiveUp = nowUserGiveUp+1
			nowUserNumber = nowUserNumber+1
			gameControl()
			return
		else
			SendChatMessage(nowUser..'要牌吗？要的打1，不要打2',execChan)
		end
	else
		--print(nowUserGiveUp,nowUserCount)
		if nowUserGiveUp == nowUserCount then
			checkAll(true)
			endGame()
			return false
		end
		local unbust,bust = checkAll()
		if unbust > 0 then
			nowQueue = {}
			for k,v in pairs(gameQueue) do
				if v['status'] == GAME_USER_STATUS_READY or v['status'] == GAME_USER_STATUS_GIVPUP then
					table.insert(nowQueue,k)
				end
			end
			nowUserCount = #nowQueue
			nowUserNumber = 1
			nowUser = nowQueue[nowUserNumber]
			nowUserGiveUp = 0
			gameControl()
		else
			endGame()
		end
	end
end
function countPoint(tbl)
	local _tmp = 0
	table.sort(tbl,function(i,j)
      if i == 'A' then
         return false
      elseif j=='A' then
         return true
      else
         return i<j
      end
	end)
	for i=1,table.getn(tbl) do
		local tmpCard = tbl[i]
		if tmpCard == 'J' or tmpCard == 'Q' or tmpCard == 'K' then
			_tmp = _tmp+10
		elseif tmpCard == 'A' then
			if _tmp+11 <= 21 then
				_tmp = _tmp+11
			else
				_tmp = _tmp+1
			end
		else
			_tmp = _tmp + tonumber(tmpCard)
		end
	end
	return _tmp
end
--检查是否爆
function checkAll(all)
	local count = 0
	local start = 2
	if all == true then
		start = 1
	end
	for k,v in pairs(gameQueue) do
		local tmp = 0
		local tmpCardList = {}
		for i=start,#v['card'] do
			table.insert(tmpCardList,v['card'][i])
		end
		tmp = countPoint(tmpCardList)
		--print(tmp)
		if tmp > 21 and not all then
			SendChatMessage(k..'的明牌'..tmp..'点，已经爆了',execChan)
			v['status'] = GAME_USER_STATUS_OUT
			count = count+1
		elseif tmp > 21 and all then
			SendChatMessage(k..'的牌是'..table.concat(v['card'],', ')..'，合计'..tmp..'点爆了',execChan)
			v['status'] = GAME_USER_STATUS_OUT
			count = count+1
		else
			if all then
				if tmp > maxPoint then
					maxPoint = tmp
					maxUser = k
				elseif tmp == maxPoint then
					maxUser = maxUser..','..k
				else
				end
			end
			SendChatMessage(k..'的牌是'..table.concat(v['card'],', ',start)..'，合计'..tmp..'点',execChan)
		end
	end
	--print('check end')
	return gameUserCount-count,count
end
--游戏中的回馈处理
function GameExec(msg,author)
	--print(msg,author,nowUser,nowUserNumber)
	local userTmp
	if msg == '1' and author == nowUser then
		--SendChatMessage('发牌中',execChan)
		--print(nowUser)
		userTmp = gameQueue[nowUser]
		--print(userTmp)
		tempCard = table.remove(gameCardTable,1)
		table.insert(userTmp['card'],tempCard)
		SendChatMessage(userTmp['name']..'获得新牌：'..tempCard,execChan)
		
		nowUserNumber = nowUserNumber+1
		gameControl()
	elseif msg == '2' and author == nowUser then
		userTmp = gameQueue[nowUser]
		userTmp['status'] = GAME_USER_STATUS_GIVPUP
		nowUserGiveUp = nowUserGiveUp+1
		nowUserNumber = nowUserNumber+1
		gameControl()
	else
	end
end
--结束游戏
function endGame()
	if maxPoint > 0 then
		SendChatMessage('{兴奋}恭喜'..maxUser..'以'..maxPoint..'点获胜!',execChan)
	else
	end
	execFunc = nil

	gameUserCount = 0
	nowUser = nil
	nowQueue = {}
	nowUserCount = 0
	nowUserNumber = 0
	nowUserGiveUp = 0
	maxPoint = 0
	maxUser = nil
	gameQueue = {}
	gameStatus = 0
	gameCardTable = {}
end

function BtnClose_OnClick()
	GBJFrame:Hide()
end
function BtnExit_OnClick()
	GBJFrame:Hide()
end
function BtnInviteGuild_OnClick()
	GameInvite(CHAN_G)
end

function BtnInviteParty_OnClick()
	GameInvite(CHAN_P)
end

function BtnInviteRaid_OnClick()
	GameInvite(CHAN_R)
end
function BtnStartGame_OnClick()
	startGame()
end
function BtnEndGame_OnClick()
	endGame()
end
function Button1_OnClick()
	gbjdebug()
end

GBJFrame:SetScript('OnEvent',function(self, event, ...)
	-- local arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12 = select(1, ...)
	local prefix
	local msg
	local _type
	local author
	local lang
	local chan
	if event == 'CHAT_MSG_ADDON' then
		prefix,msg,_type,author = select(1, ...)
		chan = CHAN_A
		if GBJDEBUG then
			print(prefix,msg,_type,sender)
		end
	elseif event == 'CHAT_MSG_GUILD' then
		msg,author,lang = select(1, ...)
		chan = CHAN_G
		if GBJDEBUG then
			print(msg,author,lang)
		end
	elseif event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER' then
		msg,author,lang = select(1, ...)
		chan = CHAN_R
		if GBJDEBUG then
			print(msg,author,lang)
		end
	elseif event == 'CHAT_MSG_PARTY' or event == 'CHAT_MSG_PARTY_LEADER' then
		msg,author,lang = select(1, ...)
		chan = CHAN_P
		if GBJDEBUG then
			print(msg,author,lang)
		end
	end
	if GBJDEBUG then
		print('Debug:',event,chan,execChan,msg,author)
	end
	if type(execFunc) == 'function' and chan == execChan then
		execFunc(msg,author)
	end
end)
GBJFrame:RegisterEvent('CHAT_MSG_ADDON')
GBJFrame:RegisterEvent('CHAT_MSG_GUILD')
-- GBJFrame:RegisterEvent('CHAT_MSG_WHISPER')
-- GBJFrame:RegisterEvent('CHAT_MSG_CHANNEL')
GBJFrame:RegisterEvent('CHAT_MSG_RAID')
GBJFrame:RegisterEvent('CHAT_MSG_RAID_LEADER')
GBJFrame:RegisterEvent('CHAT_MSG_PARTY')
GBJFrame:RegisterEvent('CHAT_MSG_PARTY_LEADER')