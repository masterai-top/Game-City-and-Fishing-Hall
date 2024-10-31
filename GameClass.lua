-- @Author: WangZh
-- @Date:   2016-07-18 11:08:14
-- @Last Modified by:   ZhuL
-- @Last Modified time: 2017-06-22 17:36:03


--@Game Controler 游戏控制器全局单例，用于编写全局游戏控制接口和模块接口
--@可通过全局变量 Game 获得该单例

require_ex("ui.common.uiext")
require_ex "ui.common.ComTipUI"
require("games.niu2.util.TinyUtil")

local curPlatform = cc.Application:getInstance():getTargetPlatform()
cc.exports.GAME_COLOR = {
    DEFAUL_INPUT_HOLDER = cc.c4b(92, 42, 21, 255),
    INPUT_HOLDER = cc.c4b(208, 208, 208,  100),
    ACTIVITY_INPUT_HOLDER = cc.c4b(208, 208, 208,  255),
    OTHER_INPUT_HOLDER = common_util.colorFromString("#FFF4BB")
}

local GameClass = class("GameClass")

function GameClass:ctor()
    if CC_SHOW_FPS and cc.PLATFORM_OS_WINDOWS == curPlatform then
        cc.Director:getInstance():setDisplayStats(true)
    end

    self._isFore = true

    self:scheduleUpdate()

    self._gamePath =
    {
        [SCENCE_ID.LOGO] = "plateform.logo",
        [SCENCE_ID.LOGIN] = "plateform.login",
        [SCENCE_ID.PLATEFORM] = "plateform.main",
        [SCENCE_ID.DDZ] = "games.ddz",
        [SCENCE_ID.GAME1] = "games.brnn",
        [SCENCE_ID.GAME2] = "games.fqzs",
        [SCENCE_ID.TCS] = "games.tcs",
        [SCENCE_ID.GAME3] = "games.redblack",
        [SCENCE_ID.GAME4] = "games.niuniu",
        [SCENCE_ID.GAME5] = "games.threecard",
        [SCENCE_ID.GAME6] = "games.fivecard2",
        [SCENCE_ID.GAME7] = "games.niu2",
        [SCENCE_ID.GAME8] = "games.rushNiu",
        [SCENCE_ID.GAME10] = "games.fish",
    }
    self._scenceIdx = nil
    self._waitingLayer = nil
    self._netbadLayer = nil
    self._ddzWaitLayer = nil
    self._blockStrs = {}

    self._canShowNetBad = true
    self._blockWaitingLayer = false

    self.m_is_clean = false
    self.m_is_restart = false
    self.m_ver_cfg = {}
end

function GameClass:schedule(callback, interval)
    interval = interval or 0
    local scheduler = cc.Director:getInstance():getScheduler()
    return scheduler:scheduleScriptFunc(callback, interval, false)
end

function GameClass:scheduleUpdate()
    self._updateEntry = self:schedule(handler(self , self.update) , 0)
end

function GameClass:update(dt)
    if self.modelMgr then
        self.modelMgr:onUpdate(dt)
    end

    if self.tinyCom then
        self.tinyCom:update(dt)
    end

    if self.storeCom then
        self.storeCom:update(dt)
    end
end

function GameClass:onBack()
    self._isFore = false
end

function GameClass:onFore()
    self._isFore = true
end

function GameClass:isFore()
    return self._isFore
end

function GameClass:setVerCfg(ver_cfg)
    self.m_ver_cfg = ver_cfg or {}
end

function GameClass:exitGame(is_exit)
    if not is_exit and sdk_util.isThirdSDK() then
        sdk_util.exit()
        return
    end
    if sdk_util.isMMSDK() then
        if not Game.uiManager:getLayer("ExitGameUI") then
            require_ex("ui.common.ExitGameUI").new():addToScene()
        end
        return
    end
    if not sdk_util.isThirdSDK() then
        -- showConfirmTip({fontSize=45}, function()
        --     Game:dispatchCustomEvent("CMD_DESTROY_EVENT", {timestamp = os.time()})
        --     cc.Director:getInstance():endToLua()
        -- end, UIZorder.Highest)

        if not Game.uiManager:getLayer("ExitGameUI") then
            require_ex("ui.common.ExitGameUI").new():addToScene()
        end
        return
    end

    self:dispatchCustomEvent("CMD_DESTROY_EVENT", {timestamp = os.time()})
    local director = cc.Director:getInstance()
    director:endToLua()
end

function GameClass:setOpenList(list)
    for index , num in ipairs(list) do
        local key = FUNC_TAB[index]
        local bOpen = num == 1
        if type(GAME_OPEN_FUNC_CFG[key]) == "table" then
            GAME_OPEN_FUNC_CFG[key][1] = bOpen
        end
    end
end

function GameClass:funcIsOpen(funcType, checkLimit)
    if type(funcType) ~= "table" then
        return false
    end

    if checkLimit then
        return funcType[1] and funcType[2]
    else
        return funcType[1] or false
    end
end

function GameClass:setFuncOpen(funcType, open)
    -- LIMIT_LIST[funcType] = open
    if type(funcType) ~= "table" then
        return
    end
    local bOpen = open
    if type(bOpen) == "number" then
        bOpen = (bOpen == 1)
    end
    funcType[2] = bOpen
    self:dispatchCustomEvent(GlobalEvent.ON_FUNC_STATE_CHANGE)
end

function GameClass:setBlockWaitingLayer(value)
    self._blockWaitingLayer = value
end

function GameClass:preloadMusic()
end

function GameClass:preloadEffect()
end

function GameClass:genBlockStr()
    self._blockStrs = split_string(BlockTxt,',')
end

function GameClass:checkIsHadBlock(str)
    for k,v in pairs(self._blockStrs) do
        local i, j = string.find(str, v)
        if i and j then
            return true
        end
    end
    return false
end

function GameClass:logOut()
    netCom.closeNetWork(true)
    self.connectHandler:onLogout()
    self:dispatchCustomEvent(GlobalEvent.GAME_ON_LOGOUT_EVENT, {})
end

function GameClass:closeNetWork()
    self.connectHandler:reinitConnectEnv()
    netCom.closeNetWork()
    self.connectHandler:clearTimeLimit()
    self.connectHandler:doConnect()
end

function GameClass:destroy()
end

function GameClass:reconnect(okCallBack)
    if okCallBack ~= nil then
        self.connectHandler:registerConnectOkCallBack(okCallBack)
    end
    self.connectHandler:reinitConnectEnv()

    if self.connectHandler:isDoingConnect() ~= true then
        self.connectHandler:doConnect()
    end
end

function GameClass:addGlobalEvent()
    local currPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == currPlatform then
        local function onKeyReleased(keyCode, event)
            if keyCode == cc.KeyCode.KEY_BACK then
                if not Game.uiManager then
                    return
                end

                if Game.guideCtrler:isGuiding() then
                    Game:exitGame(false)
                    return
                end

                local len = Game.uiManager:popShowUILayer()
                Log(LOG.TAG.UI, LOG.LV.INFO, "===on BACK clicked!=== len is: " .. tostring(len))
                if len > 0 then
                    return
                end
                if Game:getScenceIdx() == SCENCE_ID.DDZ
                    or Game:getScenceIdx() == SCENCE_ID.GAME1
                    or Game:getScenceIdx() == SCENCE_ID.GAME2
                    or Game:getScenceIdx() == SCENCE_ID.GAME3
                    or Game:getScenceIdx() == SCENCE_ID.GAME4
                    or Game:getScenceIdx() == SCENCE_ID.GAME5
                    or Game:getScenceIdx() == SCENCE_ID.GAME6
                    or Game:getScenceIdx() == SCENCE_ID.GAME7 then
                    Game:getNowScenceObj():exitScene()
                    return
                end
                Game:exitGame(false)

            elseif keyCode == cc.KeyCode.KEY_MENU  then
                Log(LOG.TAG.UI, LOG.LV.INFO, "===on MENU clicked!===")
            end
        end

        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithFixedPriority(listener, 1)
    end
end

--打开GM命令界面
function GameClass.openGMView()
    if gmLayer then gmLayer = nil end

    cc.exports.gmLayer = require("ui.gm.GmInputUI").new()
    Game:addLayer(gmLayer)
end

function GameClass:cacheAllClear()
    local scheduler = cc.Director:getInstance():getScheduler()
    if self._updateEntry then
        scheduler:unscheduleScriptEntry(self._updateEntry)
        self._updateEntry = nil
    end
    if Game.betMng then
        Game.betMng:betStop()
    end

    -- local dispatcher = cc.Director:getInstance():getEventDispatcher()
    -- dispatcher:removeAllEventListeners()

    cc.FileUtils:getInstance():purgeCachedEntries()
    cc.SpriteFrameCache:destroyInstance()
    cc.Director:getInstance():getTextureCache():removeAllTextures()
end

function GameClass:initNetWork()
    self.connectHandler:startSchedule()
    local platform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == platform or cc.PLATFORM_OS_IPHONE == platform or cc.PLATFORM_OS_IPAD == platform then
        self.connectHandler:doConnect()
    else
        self.connectHandler:doConnect()
    end
end

function GameClass:initRechargeUrl()
    local rechargeHost = RECHARGE_HOST
    if cc.PLATFORM_OS_ANDROID == platform or cc.PLATFORM_OS_IPHONE == platform  or cc.PLATFORM_OS_IPAD == platform then
        rechargeHost = "http://"..DOMAIN_NAME..":8002/"
    end
    platform_util.setUnionPayUrl(rechargeHost.."api/unionpay/appconsume.php")
    platform_util.setWechatPayUrl(rechargeHost.."api/weixinpay/appconsume.php")
    platform_util.setAliPayUrl(rechargeHost.."api/alipay/appconsume.php")
end

--@游戏模块初始化
function GameClass:init(is_clean)
    self.m_is_clean = is_clean or false
    self._nowScenceObj = nil

    self:preloadMusic()
    self:preloadEffect()
    self:initFrameModule()
    self:genBlockStr()
    self:addGlobalEvent()
    -- self:initNetWork()
    self:initRechargeUrl()
end

function GameClass:initFrameModule()
    self.localDB = require("data.LocalDB")
    self.modelMgr = require_ex("models.modelmgr")

    self.eventDB = require_ex("data.EventDB")
    self.betMng = require_ex("data.BetManager")
    self.networkMgr = require_ex("data.NetworkManager")
    self.uiManager = require_ex("ui.common.UIManager")
    self.httpCom = require_ex("util.HttpCom")

    self.connectHandler = require_ex("lib.ConnectHandler")
    self.effectManager = require_ex("util.effect_utils.EffectManager")

    self.shopCom = require_ex("data.ShopCom")
    self.shopDB = require_ex("data.ShopDB")

    self.juCom = require_ex("data.JuCom")
    self.juDB = require_ex("data.JuDB")

    -- 用户模块
    self.modelMgr:RegistModel(Model.PLAYER, "data.PlayerDB")
    self.modelMgr:RegistLogic(Model.PLAYER, "data.PlayerCom")
    self.modelMgr:BindDawnCom(Model.PLAYER)
    self.playerDB = self:GetModel(Model.PLAYER)
    self.playerCom = self:GetCom(Model.PLAYER)

    -- 斗地主模块
    self.modelMgr:RegistModel(Model.DDZ, "games.ddz.models.DDZPlayDB")
    self.modelMgr:RegistLogic(Model.DDZ, "games.ddz.models.DDZPlayCom")
    self.modelMgr:BindOnEventCom(Model.DDZ)
    self.modelMgr:BindUpdateModel(Model.DDZ)
    self.DDZPlayDB = self:GetModel(Model.DDZ)
    self.DDZPlayCom = self:GetCom(Model.DDZ)
    self.DDZNetCom = require_ex("games.ddz.models.DDZNetCom")
    self.DDZUtil = require_ex("games.ddz.models.DDZUtil")

    -- 充值模块
    self.modelMgr:RegistModel(Model.CHARGE, "data.RechargeDB")
    self.modelMgr:RegistLogic(Model.CHARGE, "data.RechargeCom")
    self.rechargeDB = self:GetModel(Model.CHARGE)
    self.rechargeCom = self:GetCom(Model.CHARGE)

    self.propCom = require_ex("data.PropCom")
    self.bagDB = require_ex("data.BagDB")
    self.bagCom = require_ex("data.BagCom")
    self.tradingDB = require_ex("data.TradingDB")
    self.tradingCom = require_ex("data.TradingCom")
    self.inforCom = require_ex("data.InforCom")
    self.vipDB = require_ex("data.VipDB")
    self.vipCom = require_ex("data.VipCom")
    self.settingCom = require_ex("data.SettingCom")
    self.loginDB = require_ex("data.LoginDB")
    self.loginCom = require_ex("data.LoginCom")

    -- 任务模块
    self.modelMgr:RegistModel(Model.TASK, "data.TaskDB")
    self.modelMgr:RegistLogic(Model.TASK, "data.MissionCom")
    self.modelMgr:BindDawnCom(Model.TASK)
    self.modelMgr:BindOnEventCom(Model.TASK)
    self.taskDB = self:GetModel(Model.TASK)
    self.misnCom = self:GetCom(Model.TASK)

    -- 签到模块
    self.modelMgr:RegistModel(Model.SIGN, "data.SignInDB")
    self.modelMgr:RegistLogic(Model.SIGN, "data.SignInCom")
    self.modelMgr:BindDawnCom(Model.SIGN)
    self.signInDB = self:GetModel(Model.SIGN)
    self.signInCom = self:GetCom(Model.SIGN)

    self.mailCom = require_ex("data.MailCom"):init()
    self.chatCom = require_ex("data.ChatCom"):init()
    self.noticeCom = require_ex("data.NoticeCom"):init()

    self.activityCom = require_ex("data.ActivityCom")
    self.activityDB = require_ex("data.ActivityDB")
    self.onlineCom = require_ex("data.OnlineCom")
    self.onlineDB = require_ex("data.OnlineDB")
    self.esqCom = require_ex("data.EsqCom")

    self.guideCtrler = require_ex("data.GuideC")

    self.tinyCom = require_ex("data.TinyCom")
    self.heroDB = require_ex("data.HeroDB")
    self.heroCom = require_ex("data.HeroCom")
    self.storeDB = require_ex("data.StoreDB")
    self.storeCom = require_ex("data.StoreCom")
    self.signDB = require_ex("data.SignDB")
    self.signCom = require_ex("data.SignCom")
    self.rankingCom = require_ex("data.RankingCom")
    self.recommendCom = require_ex("data.RecommendCom")

    cc.exports.TimeUtil = require("lib.TimeEx").new()
end

function GameClass:dataMonitor()
    -- self.bagDB:testDataMonitor()
    -- self.tradingDB:testDataMonitor()
end

function GameClass:setNowScenceObj(object)
    self._nowScenceObj = object
    self:registerKeyboard(object)
end

function GameClass:getNowScenceObj()
    return self._nowScenceObj
end

-- Game:GetCom(Model.TASK)
function GameClass:GetCom(model_id)
    return self.modelMgr:GetCom(model_id)
end

-- Game:GetModel(Model.TASK)
function GameClass:GetModel(model_id)
    return self.modelMgr:GetModel(model_id)
end

-- Game:onEvent(DDZEvent.dd, info)
function GameClass:onEvent(event_id, evnet_data)
    self.modelMgr:onEvent(event_id, evnet_data)
end

--@根据路径开启应用包
function GameClass:openPkgWithPath(path)
    -- body
    local configs = {
        viewsRoot  = path..".views",
        modelsRoot = path..".models",
        defaultSceneName = "MainScene",
    }
    require_ex(path..".MyApp"):create(configs):run()
    self:dispatchCustomEvent(GlobalEvent.CHANGE_SCENE_EVENT)

    -- 预加载Spine
    self:preloadSpine()
end

function GameClass:isGameNeedReconn()
    if SCENCE_ID.LOGIN ~= self._scenceIdx then
        return true
    end
    return false
end

function GameClass:gameStart(is_start)
    cc.UserDefault:getInstance():setBoolForKey("game_reload", false)
    local function _enterLogin(updated, callback)
        Game.uiManager:hideLoading()

        if not is_start and sdk_util.isThirdSDK() then
            return
        end
        self:openGameWithIdx(SCENCE_ID.LOGIN)

        if callback then callback() end
    end

    local params = {
        csb = "ui/common/updateUI.csb",
        gameid = 0,
        version = platform_util.getAppVersion(),
        onenter = function (callback, updated)
            _enterLogin(updated, callback)
        end,
        onexit = _enterLogin,
    }
    local updateScene = display.newScene("UPD")
    local updateUI = require("ui.common.GameEntryUI"):new(params)
    display.runScene(updateScene)
    updateScene:addChild(updateUI)
    maskScene(updateScene)
    self._nowScenceObj = updateScene

    if sdk_util.isMMSDK() then
        Game.uiManager:showLoading()
    end

    if sdk_util.isAppstorePay() then
        local list = sdk_util.getProductList()
        sdk_util.common({handleType = "PayInit", productIds = list})
    end
end

function GameClass:showNetCloseTips()
    local isNetBad = self.networkMgr:getNetBad()
    if isNetBad == true then
        Game.guideCtrler:closeGuide()
        Game.uiManager:closeUILayers()
        self:destroyNetBadUI()

        showConfirmTip({
            sTip="网络被断开，是否重新连接？",
            sBtnName1 = stringCfgCom.content("que_ding"),
            sBtnName2 = stringCfgCom.content("qu_xiao"),
            fCallBack1 = function()
                local isNetBad = self.networkMgr:getNetBad()
                if isNetBad == true then
                    self:closeNetWork()
                    performWithDelay(self:getNowScenceObj(), function ()
                        Game:showNetCloseTips()
                    end, 2)
                end
            end,
            fCallBack2 = function()
                cc.Director:getInstance():endToLua()
            end,
            sLayerName = "ComfirmTips_Do_Reconn"
        }, nil, UIZorder.Highest)
    end
end

--@真正启动游戏
function GameClass:onGameFinishLogin()
    local function _enterHall(updated, callback)
        if updated then
            updated = function ()
                Game.activityCom:setUpdate(true)
            end
        end

		local platform = cc.Application:getInstance():getTargetPlatform()
		if cc.PLATFORM_OS_IPHONE == platform  or cc.PLATFORM_OS_IPAD == platform then
			local nowVersion = platform_util.getAppVersion()
			if ONLINE_SVR_VER > nowVersion then
				local params =
				{
					sTip = "APP 版本过低，请更新最新版本后进行游戏！",
					sBtnName1 = "退出游戏",
					sBtnName2 = "下载游戏",

					fCallBack1 = function()
						Game:exitGame()
					end,
					fCallBack2 = function()
						platform_util.goAppStoreByUrl(NEW_APP_DOWNLOAD)
					end,
				}
				showComTip(params)
				return
			end
		end

        self.connectHandler:loginToGameSvr(function()
            self.bagCom:refreshBagData()

            if self._scenceIdx ~= SCENCE_ID.PLATEFORM then
                if self._scenceIdx == SCENCE_ID.GAME1 then
                    Game:openGameWithIdx(SCENCE_ID.GAME1, nil, true)

                elseif self._scenceIdx == SCENCE_ID.GAME2 then
                    Game:openGameWithIdx(SCENCE_ID.GAME2, nil, true)

                elseif self._scenceIdx == SCENCE_ID.GAME3 then
                    Game:openGameWithIdx(SCENCE_ID.GAME3, nil, true)
                else
                    self:openGameWithIdx(SCENCE_ID.PLATEFORM, updated)
                end
            else
                local showLayer = Game:getNowScenceObj():getShowLayer()
                if showLayer then
                    showLayer:refresh()
                end
            end

            if callback then
                callback()
            end
        end)
    end

    -- local params = {
    --     csb = "ui/common/updateUI.csb",
    --     gameid = 0,
    --     version = platform_util.getAppVersion(),
    --     onenter = function (callback, updated)
    --         _enterHall(updated, callback)
    --     end,
    --     onexit = _enterHall,
    -- }
    -- Game:addLayer(require("ui.common.GameEntryUI"):new(params))

    _enterHall()
end

--[[
@prama mixViewFunc    string/function/nil  返回场景后默认打开的界面/调用函数
    e.g. "ui.mainhall.MoreGameUI"
    e.g. function() ... end
]]
function GameClass:openGameWithIdx(idx, mixViewFunc, ignoreck)
    Log(LOG.TAG.UI, LOG.LV.INFO, "===GameClass openGameWithIdx idx is: " .. tostring(idx))
    if self._scenceIdx == SCENCE_ID.DDZ then
        local ddzPlayUi = Game.DDZPlayCom:getPlayUi()
        if not tolua.isnull(ddzPlayUi) then
            ddzPlayUi:prepareClear()
        end
        Game.DDZPlayCom:setPlayUi(nil)
    end
    if not ignoreck and not Game.recommendCom:onEnterGames(idx) then
        return
    end

    if self._scenceIdx == SCENCE_ID.DDZ
        or self._scenceIdx == SCENCE_ID.PLATEFORM
        or self._scenceIdx == SCENCE_ID.GAME1
        or self._scenceIdx == SCENCE_ID.GAME2 then

        if not self.m_is_clean then
            print("======openGameWithIdx release sprite frames=====")
            display.removeUnusedSpriteFrames()
        end
    end
    self.uiManager:cleanAllLayer()

    self._scenceIdx = idx
    self:openPkgWithPath(self._gamePath[idx])

    if type(mixViewFunc) == "string" then
        Game:addLayer(require_ex(mixViewFunc):new())
    elseif type(mixViewFunc) == "function" then
        mixViewFunc()
    end
end

function GameClass:getScenceIdx()
    return self._scenceIdx
end

--@Modify Jiangy
local checkLuaExt = {".lua", ".luac"}

function GameClass:isGameExist(gameIdx)
    if not gameIdx or not GAMESIDX_TO_SCENCE_ID[gameIdx] then
        return false
    end
    local fileInstan = cc.FileUtils:getInstance()
    local writablePath = fileInstan:getWritablePath()
    local updatePath = writablePath.."update/"
    local appExist = false
    local sceneIdx = GAMESIDX_TO_SCENCE_ID[gameIdx]

    for k,v in pairs(checkLuaExt) do
        local localPath = self._gamePath[sceneIdx]
        local gameAppPath = updatePath.."src/games/game"..gameIdx.."/MyApp"..v
        if localPath then
            localPath = string.gsub(localPath, "%.", "/").."/MyApp"..v
            print("LocalPath: "..localPath)
            local fullName = fileInstan:fullPathForFilename(localPath)
            if fullName ~= "" then
                appExist = true
            end
        end

        if not appExist then
            print("UpdatePath: "..gameAppPath)
            appExist = fileInstan:isFileExist(gameAppPath)
        end
        if appExist == true then
            break
        end
    end

    if appExist == true then
        return true
    else
        return false
    end
end

function GameClass:getWaitLayer()
    return self._waitingLayer
end

function GameClass:setWaitLayer(value)
    self._waitingLayer = value
end

function GameClass:setDDZWaitLayer(value)
    self._ddzWaitLayer = value
end

function GameClass:setWaitUITxt(tipsText, type, callback)
    if self._waitingLayer ~= nil then
        self._waitingLayer:setTipsText(tipsText, callback)

    elseif self._ddzWaitLayer ~= nil then
        self._ddzWaitLayer:setTipsText(tipsText, callback)
    else
        self:showWaitUI(tipsText, type, callback)
    end
end

function GameClass:showWaitUI(tipsText, type, callback, ignoreTipNet)  --遮罩等待框
    if self._blockWaitingLayer == true then
        return
    end
    if type ==nil or type == WAIT_TYPE.NORMAL or type == WAIT_TYPE.WAIT_CLOSE then
        if self._waitingLayer == nil and self._netbadLayer == nil then
            local layer = require("ui.wait.WaitUI").new(type == WAIT_TYPE.WAIT_CLOSE, ignoreTipNet)
            if tipsText ~= nil then
                layer:setTipsText(tipsText)
            end
            Game:addLayer(layer)
            self._waitingLayer = layer
        end
    elseif type == WAIT_TYPE.RUN_ANI then
         if self._ddzWaitLayer == nil then
            local layer = require("ui.wait.WaitUITypeRun").new()
            layer:setTipsText(tipsText)
            layer:setBackCallback(callback)
            Game:addLayer(layer)

            self._ddzWaitLayer = layer
        end
    elseif type == WAIT_TYPE.NET_BAD then
         if self._netbadLayer == nil and self._canShowNetBad == true then
            self:destroyWaitUI()
            local layer = require("ui.wait.WaitUITypeNetBad").new()
            if tipsText ~= nil then
                layer:setTipsText(tipsText)
            end
            Game:addLayer(layer, UIZorder.TipsHeight)
            self._netbadLayer = layer
            self._canShowNetBad = false
            return self._netbadLayer
        end
    end
end

function GameClass:destroyWaitUI()
   if not tolua.isnull(self._waitingLayer) then
        Log(LOG.TAG.UI, LOG.LV.INFO, "===GameClass destroyWaitUI ======")
        self._waitingLayer:destoryInstance()
        self._waitingLayer = nil
   end
end

function GameClass:destroyDDZWaitUI()
   if not tolua.isnull(self._ddzWaitLayer) then
        Log(LOG.TAG.UI, LOG.LV.INFO, "===GameClass destroyDDZWaitUI ======")
        self._ddzWaitLayer:destoryInstance()
        self._ddzWaitLayer = nil
   end
end

function GameClass:rebackNetBadUI()
   self._canShowNetBad = true
   self._netbadLayer = nil
   self.networkMgr:clearEnv()
end

function GameClass:destroyNetBadUI()
    self.networkMgr:clearEnv()
    if not tolua.isnull(self._netbadLayer) then
        self._netbadLayer:destoryInstance()
        self._netbadLayer = nil
        self._canShowNetBad = true
   end
end

function GameClass:registerKeyboard(node)
    local function onKeyReleased(keyCode, event)
        if keyCode == 35 then
            if gmLayer ~= nil then return end
            Game.openGMView()
        end
    end
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED )
    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function GameClass:tipMsg(str, delay, callback, afterDestoryCallBack)
    if type(str) == "string" and string.len(str) > 0 then
        local param = {
            content = str,
            dur = delay,
            callback = callback,
            afterDestory = afterDestoryCallBack
        }
        Game.tinyCom:push(param)
    end
end

--[[
提示错误
]]
function GameClass:tipError(errCode, delay, callback , afterDestoryCallBack)
    errCode = tonumber(errCode)
    local cfgData = cfg_util.getConfigValue(MsgConfig, errCode) or {}
    local tip = cfgData.text or tostring(errCode)
    local event = checknumber(cfgData.event)
    -- 加倍失败不提示
    if errCode == 16000006
        or errCode == 16000005
        or errCode == 16000009 then
        return
    end
    self.guideCtrler:closeGuide()

    dump(cfgData)
    if event == 1 then
        -- 充值提示
        if Game:funcIsOpen(GAME_OPEN_FUNC_CFG.RECHARGE)  == true then
            showConfirmTip({sTip=tip, sBtnName1=stringCfgCom.content("chong_zhi")}, function()
                Game.rechargeCom:openRechargeView()
            end)
        end
    elseif event == 2 then
        -- 跳转商城
        showConfirmTip({sTip=tip, sBtnName1=stringCfgCom.content("vip_goumai")}, function()
            Game.storeCom:openStoreView(GoodsType.Box)
        end)
    else
        self:tipMsg(self:tipWithVIP(errCode, tip), delay, callback , afterDestoryCallBack)
    end
end

function GameClass:tipWithVIP(errCode, tip)
    local data = Game.vipDB:getSvipSysAddtion()
    if data and #data > 0 then
        if errCode == 22005006 then
            for i,v in ipairs(data) do
                if v[1] == 22 then
                    tip = tip..", SVIP额外加成："..math.floor(v[2]/100).."%"
                    break
                end
            end
        elseif errCode == 21002007 then
            for i,v in ipairs(data) do
                if v[1] == 21 then
                    tip = tip..", SVIP额外加成："..math.floor(v[2]/100).."%"
                    break
                end
            end
        elseif errCode == 30002005 then
            for i,v in ipairs(data) do
                if v[1] == 30 then
                    tip = tip..", SVIP额外加成："..math.floor(v[2]/100).."%"
                    break
                end
            end
        elseif errCode == 17002002 then
            for i,v in ipairs(data) do
                if v[1] == 17 then
                    tip = tip..", SVIP额外加成："..v[2].."件"
                    break
                end
            end
        end
    end
    if errCode == 22005007 then
        local min = SystemLimitConfig.min_left_coin("hundred_douniu")
        return string.format(tip, tostring(min))

    elseif errCode == 21002009 then
        local min = SystemLimitConfig.min_left_coin("fowlsbeasts")
        return string.format(tip, tostring(min))
        
    elseif errCode == 30002006 then
        local min = SystemLimitConfig.min_left_coin("redblack")
        return string.format(tip, tostring(min))
    end
    return tip
end

-- 分发事件
function GameClass:dispatchCustomEvent(eventName, eventData)
    local event = cc.EventCustom:new(eventName)
    if eventData then
        event.data = eventData
    end
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
end

function GameClass:addEventListenerWithFixedPriority(eventName , callback , priority)
    priority = priority or 1
    local listener = cc.EventListenerCustom:create(eventName , callback)
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(listener, priority)
end

function GameClass:addEventListenerWithSceneGraphPriority(node , eventName , callback)
    local listener = cc.EventListenerCustom:create(eventName, callback)
    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end


-- 用于储存不需要执行动作的UI
cc.exports.RippleUI = {
    LoginFront = true,
    DDZLaiZiUI = true,
    DDZClassicUI = true,
    GameEntryUI = true,
    GuideUI = true,
    EsqUI = true,
    MsgTip = true,
    HeroBook = true,
    HeroShow = true,
    Store = true,
    RechargeUI = true,
    Store = true,
    ShopUI = true,
    SelectMode = true,
    MissionView = true,
    VipView = true,
    BagMainUI = true,
    MailBox = true,
    ActivityUI = true,
    BullUI = true,
    AnimalsUI = true,
    RedPack = true,
    TaskUI = true,
    DDZMatchSign = true,
    DDZMatchWait = true,
    RankingView = true,
    RechargeView = true,
    SelectHero = true,
    Mail = true,
    RankingMatch = true,
    SelectRole = true,
    SmeltView = true,
    JuUI = true,
    JuChiplistUI = true,
    JuRecordUI = true,
}

-- 此函数添加了UI管理器功能，如果name参数不为空，UI界面
-- 将会被加入到UI管理器中储存，关闭界面时应调用新接口destroy
-- UI管理器主要用于刷新界面，同时关闭多界面，等对界面的批量操作，
-- 实现对UI的规范管理
function GameClass:addLayer(layer, zOrder, layerName, isCenter, isRepeat, unManage)
    local className = layerName or layer.__cname
    local name = layer.__cname

    if self.guideCtrler:isGuiding() then
        if self.guideCtrler:getCurViewName() ~= name
            and name ~= "GuideUI" and name ~= "ComfirmTips_Do_Reconn" and not layer.signal then

            print("===GameClass addLayer name is: " .. tostring(name))
            print("===GameClass addLayer isGuiding is: " .. tostring(self.guideCtrler:isGuiding()))
            print("===GameClass addLayer getCurViewName is: " .. tostring(self.guideCtrler:getCurViewName()))
            return
        end
    end

    if not RippleUI[name] and name then
        if Game.uiManager:isBlocking(name) == false then
            local args = { type = ActionType.Ripple }
            local eff = self.effectManager:getEffectByName("NodeAction").new(layer, args)
            eff:run()
        end
    end

    if self.uiManager and (not unManage) then
        self.uiManager:addLayer(className, layer, isRepeat)
    end

    if isCenter then
        local s = cc.Director:getInstance():getWinSize()
        layer:setPosition(s.width/2, s.height/2)
    end
    self._nowScenceObj:addChild(layer, (zOrder or UIZorder.UILayer))

    local event = cc.EventCustom:new(GlobalEvent.VIEW_OPEN_EVENT)
    event.data = { name = name, addr = layer }
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

    if Game.uiManager:checkIsJuThree(name) == true then
        Game.uiManager:blockJuThreeShake()
    end
end

--[[
Spine预加载
]]
local SpinePreload = {
    [SCENCE_ID.LOGO] = {},
    [SCENCE_ID.LOGIN] = {},
    [SCENCE_ID.PLATEFORM] = {
        "gameres/general/effect/jubaoge/kaishiyazhu/jbg_ksyz",
        "gameres/general/effect/jubaoge/kaishiyaojiang/jbg_ksyj",
        "gameres/general/effect/jubaoge/daojishi/jubaoge_effect_daojishi",
        "gameres/uisystem/duijiangyouxi/animation/lunzi/DuiJiangYouXi_Anmation_LunZi",
        "gameres/uisystem/duijiangyouxi/animation/niao/DuiJiangYouXi_Anmation_Niao",
        "gameres/uisystem/duijiangyouxi/animation/zhanggui/DuiJiangYouXi_Anmation_ZhangGui",
    },
    [SCENCE_ID.DDZ] = {},
    [SCENCE_ID.GAME1] = {},
    [SCENCE_ID.GAME2] = {},
    [SCENCE_ID.GAME3] = {},
    [SCENCE_ID.GAME10] = {
        "subgame/catchFish/spine/wang/wang1/by_wang01",
        "subgame/catchFish/spine/fish/01/by_01",
        "subgame/catchFish/spine/fish/02/by_02",
        "subgame/catchFish/spine/fish/03/by_03",
        "subgame/catchFish/spine/fish/04/by_04",
        "subgame/catchFish/spine/fish/05/by_05",
        "subgame/catchFish/spine/fish/06/by_06",
        "subgame/catchFish/spine/fish/07/by_07",
        "subgame/catchFish/spine/fish/08/by_08",
        "subgame/catchFish/spine/fish/09/by_09",
        "subgame/catchFish/spine/fish/10/by_10",
        "subgame/catchFish/spine/fish/11/by_11",
        "subgame/catchFish/spine/fish/12/by_12",
        "subgame/catchFish/spine/fish/13/by_13",
        "subgame/catchFish/spine/fish/14/by_14",
        "subgame/catchFish/spine/fish/15/by_15",
        "subgame/catchFish/spine/fish/16/by_16",
        "subgame/catchFish/spine/fish/17/by_17",
        "subgame/catchFish/spine/fish/18/by_18",
        "subgame/catchFish/spine/fish/19/by_19",
        "subgame/catchFish/spine/fish/20/by_20",
        "subgame/catchFish/spine/fish/21/by_21",
        "subgame/catchFish/spine/fish/22/by_22",
        "subgame/catchFish/spine/fish/23/by_23",
        "subgame/catchFish/spine/fish/24/by_24",
    },
}

function GameClass:preloadSpine()
    if self._scenceIdx and SpinePreload[self._scenceIdx] and #SpinePreload[self._scenceIdx] > 0 then
        local Actor = require_ex("ui.common.Actor")
        for _, spine in ipairs(SpinePreload[self._scenceIdx]) do
            Actor:new(spine)
        end
    end
end

function GameClass:reload(ui)
    local verCfg = self.m_ver_cfg or {}
    local isReStart = self.m_is_restart
    cc.UserDefault:getInstance():setBoolForKey("game_reload", true)

    local app_version = platform_util.getAppVersion() or ""
    local pre_version = cc.UserDefault:getInstance():getStringForKey("pre_res_ver_0", app_version)
    local nex_version = Game.localDB:getUsrValue("res_ver_0") or "00.00.000"
    local verList = string.split(nex_version, ".") or {}
    dump(verList)

    for i,v in ipairs(verCfg or {}) do
        if pre_version < v and nex_version > v then
            isReStart = true
            break
        end
    end
    print("=========isReStart is: " .. tostring(isReStart))
    if not isReStart then
        if verList and verList[3] then
            local r = string.sub(verList[3], 3, 3) or "0"
            if r == "1" then isReStart = true end
        end
    end

    local ReloadList = {
        "config.",
        "data.",
        "game_config",
        "GameClass",
        "games.",
        "lib.",
        "packages.",
        "plateform.",
        "protocolnew.",
        "ui.",
        "util.",
    }
    performWithDelay(ui or self:getNowScenceObj(), function()
        local fileUtils = cc.FileUtils:getInstance()
        if fileUtils:isFileExist("res/so/libcocos2dlua.patch") then
            platform_util.updateSo()

        elseif device.platform == "android" and isReStart then
            cc.UserDefault:getInstance():setBoolForKey("game_restart", true)
            platform_util.doReStartGame()
        else
            Game:cacheAllClear()
            for k, _ in pairs(package.preload) do
                for _, v in ipairs(ReloadList) do
                    if string.find(k, v) == 1 then
                        package.preload[k] = nil
                        break
                    end
                end
            end
            for k, _ in pairs(package.loaded) do
                for _, v in ipairs(ReloadList) do
                    if string.find(k, v) == 1 then
                        package.loaded[k] = nil
                        break
                    end
                end
            end

            local fileInstance = cc.FileUtils:getInstance()
            fileInstance:setPopupNotify(false)

            local writablePath = fileInstance:getWritablePath()
            fileInstance:createDirectory(writablePath.."/update/")

            fileInstance:addSearchPath("src/", true)
            fileInstance:addSearchPath("res/", true)

            fileInstance:addSearchPath(writablePath.."/update/", true)
            fileInstance:addSearchPath(writablePath.."/update/".."src/", true)
            fileInstance:addSearchPath(writablePath.."/update/".."res/", true)

            require_ex "game_config"
            require_ex "cocos.init"

            require_ex "GameClass"
            Game:init(true)
            Game:gameStart(true)
        end
    end, 0.5)
end

function GameClass:setLogoutFlag(flag)
    self.__logoutFlag = flag
end

function GameClass:getLogoutFlag()
    return self.__logoutFlag
end

-- =======================
-- 全局单例
cc.exports.Game = GameClass:new()