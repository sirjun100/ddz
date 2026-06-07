-- 文件: AiActionData.lua · 反编译 AI 模块（阅读用）

local AiActionData = class("AiActionData")

-- AiAction · 构造函数
function AiActionData:ctor(params)
  params = params or {}
  params.paramsMap = params.paramsMap or {}
  self.params_ = params
  if kIsDebug then
    if not params.aiLevel or params.aiLevel <= 0 or params.aiLevel > 7 then
      print("错误：ai等级错误" .. tostring(params.aiLevel))
    end
    if not params.direction or 0 >= params.direction or params.direction > 3 then
      print("错误：玩家方位错误" .. tostring(params.direction))
    end
  end
  self.lastSuitData_ = params.lastSuitData
  self.aiLevel_ = params.aiLevel or 1
  self.direction_ = params.direction
  self.cardTypeListDataArr_ = params.cardTypeListDataArr
  self.taskData_ = params.taskData
  self.log = params.printFun or print
  self.paramsMap = params.paramsMap or {}
  self.async = params.async
  self.result = params.result or {}
  if self.cardTypeListDataArr_ then
    for dir, cardTypeListData in ipairs(self.cardTypeListDataArr_) do
      cardTypeListData:setAsync(self.async)
      cardTypeListData:setDirection(dir)
    end
  end
end

-- AiAction · 出牌主入口：按局面分支决策并返回 AiSuitData（标记路径）
function AiActionData:getActionSuitData()
  if self.actionData_ == nil then
    local lastSuitData = self.lastSuitData_
    local aiLevel = self.aiLevel_
    local direction = self.direction_
    local actionMap = self:getActionNameMap()
    local actionName
    if lastSuitData then
      actionName = actionMap[aiLevel][direction].follow
    else
      actionName = actionMap[aiLevel][direction].start
    end
    local ActionDataClass = require(actionName)
    local params = self.params_
    local actionData = ActionDataClass.new(params)
    self.actionData_ = actionData
    local suitData, isFromEnd = actionData:getActionSuitData()
    if suitData then
      suitData = self:dealDaiPai(suitData)
      if aiLevel < 7 and not isFromEnd then
        suitData = self:checkIsBombAndIsEnemyWinCondition(actionData, suitData, lastSuitData)
      end
      if suitData then
        suitData = suitData:check(lastSuitData)
      end
    elseif lastSuitData == nil then
      suitData = actionData:normolStart()
      if kIsDebug then
        print("出牌逻辑有误，无出牌结果: " .. table.concat(actionData.result, "-"))
      end
    end
    self.log("==标记路径 " .. table.concat(actionData.result, "-"))
    self.actionSuitData_ = suitData
  end
  return self.actionSuitData_
end

-- AiAction · 按 aiLevel 与方位返回 Start/Follow 策略类路径
function AiActionData:getActionNameMap()
  if self.actionNameMap_ == nil then
    local map = {
      [1] = {
        [1] = {
          start = "ai.actionBest.AiBestLandlordStartData",
          follow = "ai.actionBest.AiBestLandlordFollowData",
        },
        [2] = {
          start = "ai.actionBest.AiBestFarmerRightStartData",
          follow = "ai.actionBest.AiBestFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionBest.AiBestFarmerLeftStartData",
          follow = "ai.actionBest.AiBestFarmerLeftFollowData",
        },
      },
      [2] = {
        [1] = {
          start = "ai.actionBest.AiBestLandlordStartData",
          follow = "ai.actionBest.AiBestLandlordFollowData",
        },
        [2] = {
          start = "ai.actionBest.AiBestFarmerRightStartData",
          follow = "ai.actionBest.AiBestFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionBest.AiBestFarmerLeftStartData",
          follow = "ai.actionBest.AiBestFarmerLeftFollowData",
        },
      },
      [3] = {
        [1] = {
          start = "ai.actionBest.AiBestLandlordStartData",
          follow = "ai.actionBest.AiBestLandlordFollowData",
        },
        [2] = {
          start = "ai.actionBest.AiBestFarmerRightStartData",
          follow = "ai.actionBest.AiBestFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionBest.AiBestFarmerLeftStartData",
          follow = "ai.actionBest.AiBestFarmerLeftFollowData",
        },
      },
      [4] = {
        [1] = {
          start = "ai.actionBest.AiBestLandlordStartData",
          follow = "ai.actionBest.AiBestLandlordFollowData",
        },
        [2] = {
          start = "ai.actionBest.AiBestFarmerRightStartData",
          follow = "ai.actionBest.AiBestFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionBest.AiBestFarmerLeftStartData",
          follow = "ai.actionBest.AiBestFarmerLeftFollowData",
        },
      },
      [5] = {
        [1] = {
          start = "ai.actionNormal.AiNormalLandlordStartData",
          follow = "ai.actionNormal.AiNormalLandlordFollowData",
        },
        [2] = {
          start = "ai.actionNormal.AiNormalFarmerRightStartData",
          follow = "ai.actionNormal.AiNormalFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionNormal.AiNormalFarmerLeftStartData",
          follow = "ai.actionNormal.AiNormalFarmerLeftFollowData",
        },
      },
      [6] = {
        [1] = {
          start = "ai.actionWorse.AiWorseLandlordStartData",
          follow = "ai.actionWorse.AiWorseLandlordFollowData",
        },
        [2] = {
          start = "ai.actionWorse.AiWorseFarmerRightStartData",
          follow = "ai.actionWorse.AiWorseFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionWorse.AiWorseFarmerLeftStartData",
          follow = "ai.actionWorse.AiWorseFarmerLeftFollowData",
        },
      },
      [7] = {
        [1] = {
          start = "ai.actionWorst.AiWorstLandlordStartData",
          follow = "ai.actionWorst.AiWorstLandlordFollowData",
        },
        [2] = {
          start = "ai.actionWorst.AiWorstFarmerRightStartData",
          follow = "ai.actionWorst.AiWorstFarmerRightFollowData",
        },
        [3] = {
          start = "ai.actionWorst.AiWorstFarmerLeftStartData",
          follow = "ai.actionWorst.AiWorstFarmerLeftFollowData",
        },
      },
    }
    self.actionNameMap_ = map
  end
  return self.actionNameMap_
end

-- AiAction · 获取优先出牌组合列表
function AiActionData:getFirstSuitDataArr()
  return self.firstSuitDataArr_
end

-- AiAction · 设置本回合优先尝试的牌型组合列表
function AiActionData:setFirstSuitDataArr(value)
  self.firstSuitDataArr_ = value
end

-- AiAction · 获取本方 AiCardTypeListData
function AiActionData:getData()
  local direction = self.direction_
  local cardTypeListDataArr = self.cardTypeListDataArr_
  return cardTypeListDataArr[direction]
end

-- AiAction · 获取databydirection
function AiActionData:getDataByDirection(direction)
  local cardTypeListDataArr = self.cardTypeListDataArr_
  return cardTypeListDataArr[direction]
end

-- AiAction · 判断当前是否具备收官条件
function AiActionData:enableEnd()
  local lastSuitData = self.lastSuitData_
  local cardTypeListData = self:getData()
  return cardTypeListData:ai_isMatchWinCondition(lastSuitData)
end

-- AiAction · 是否可警戒收官
function AiActionData:enableWarningEnd()
  local lastSuitData = self.lastSuitData_
  local cardTypeListData = self:getData()
  return cardTypeListData:getCardCount() <= 2 and cardTypeListData:ai_isMatchWinCondition(lastSuitData)
end

-- AiAction · 是否允许跟牌（有能压过的牌）
function AiActionData:enableFollow()
  local lastSuitData = self.lastSuitData_
  local cardTypeListData = self:getData()
  local biggerArr = cardTypeListData:ai_all_filterBiggerSuitDataArr(lastSuitData)
  return 0 < #biggerArr
end

-- AiAction · 获取地主方手牌数据
function AiActionData:getLandlordData()
  local cardTypeListDataArr = self.cardTypeListDataArr_
  return cardTypeListDataArr[1]
end

-- AiAction · 获取下家农民手牌数据
function AiActionData:getFarmerRightData()
  local cardTypeListDataArr = self.cardTypeListDataArr_
  return cardTypeListDataArr[2]
end

-- AiAction · 获取上家农民手牌数据
function AiActionData:getFarmerLeftData()
  local cardTypeListDataArr = self.cardTypeListDataArr_
  return cardTypeListDataArr[3]
end

-- AiAction · 地主是否可收官
function AiActionData:landlordEnableEnd()
  local cardTypeListData = self:getLandlordData()
  return cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 农民right是否可收官
function AiActionData:farmerRightEnableEnd()
  local cardTypeListData = self:getFarmerRightData()
  return cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 农民left是否可收官
function AiActionData:farmerLeftEnableEnd()
  local cardTypeListData = self:getFarmerLeftData()
  return cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 地主是否处于报单/收官警戒
function AiActionData:landlordEnableWarningEnd()
  local cardTypeListData = self:getLandlordData()
  return cardTypeListData:getCardCount() <= 2 and cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 下家农民是否处于报单/收官警戒
function AiActionData:farmerRightEnableWarningEnd()
  local cardTypeListData = self:getFarmerRightData()
  return cardTypeListData:getCardCount() <= 2 and cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 上家农民是否处于报单/收官警戒
function AiActionData:farmerLeftEnableWarningEnd()
  local cardTypeListData = self:getFarmerLeftData()
  return cardTypeListData:getCardCount() <= 2 and cardTypeListData:ai_getEnableEnd()
end

-- AiAction · 获取地主牌count
function AiActionData:getLandlordCardCount()
  local cardTypeListData = self:getLandlordData()
  return cardTypeListData:getCardCount()
end

-- AiAction · 获取农民right牌count
function AiActionData:getFarmerRightCardCount()
  local cardTypeListData = self:getFarmerRightData()
  return cardTypeListData:getCardCount()
end

-- AiAction · 获取农民left牌count
function AiActionData:getFarmerLeftCardCount()
  local cardTypeListData = self:getFarmerLeftData()
  return cardTypeListData:getCardCount()
end

-- AiAction · 地主判断是否lose
function AiActionData:landlordIsLose()
  local cardTypeListData = self:getLandlordData()
  return cardTypeListData:ai_getIsLose()
end

-- AiAction · 农民right判断是否lose
function AiActionData:farmerRightIsLose()
  local cardTypeListData = self:getFarmerRightData()
  return cardTypeListData:ai_getIsLose()
end

-- AiAction · 农民left判断是否lose
function AiActionData:farmerLeftIsLose()
  local cardTypeListData = self:getFarmerLeftData()
  return cardTypeListData:ai_getIsLose()
end

-- AiAction · 首出：在优先列表中按 A0/A1/A2/A3 规则选最小合适牌（用【优先出的牌组合列表】基础出牌）
function AiActionData:getStartBaseActionSuitData()
  self.log("==用【优先出的牌组合列表】基础出牌")
  local suitDataArr = self:getFirstSuitDataArr()
  self:addParamsWithKey("【优先出的牌组合列表】", suitDataArr)
  local tmpSuitDataArr = suitDataArr
  if not (#tmpSuitDataArr <= 1) then
    if AiUtils:isAll42(tmpSuitDataArr) then
      do
        local a3 = AiUtils:getFourWithTwoPairSuitDataArr(tmpSuitDataArr)
        if 0 < #a3 then
          self.log(
            "【优先出的牌组合列表】全是四带二组合。是否有四带两对的组合，假定是A3牌组合，A3数量是："
              .. #a3
          )
          tmpSuitDataArr = a3
        end
      end
    else
      local a0 = AiUtils:filterNot42(tmpSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，非四带二组合 A0", a0)
      self.log(
        "【优先出的牌组合列表】中，非四带二组合。假定是A0牌组合，A0数量是：" .. #a0
      )
      if #a0 == 1 then
        tmpSuitDataArr = a0
      elseif AiUtils:isAllBomb(a0) then
        tmpSuitDataArr = a0
      else
        local a3 = AiUtils:filterNotBomb(a0)
        self:addParamsWithKey("A0中，非炸弹牌组合 A3", a3)
        self.log("A0中，非炸弹牌组合。假定是A3牌组合，A3数量是：" .. #a3)
        if #a3 == 1 then
          tmpSuitDataArr = a3
        elseif AiUtils:isAllMaxMaxSuitData(a3) then
          tmpSuitDataArr = a3
        else
          local a1 = AiUtils:filterNotMaxMaxSuitDataArr(a3)
          self:addParamsWithKey("A3中，非大牌的组合 A1", a1)
          self.log("A3中，非大牌的组合。假定是A1牌组合，A1数量是：" .. #a1)
          if #a1 == 1 then
            tmpSuitDataArr = a1
          else
            local suitDataArrDict = AiUtils:suitDataArrToSuitDataArrDict(a1)
            local keys = table.keys(suitDataArrDict)
            self:addParamsWithKey("【优先出的牌组合列表】中，各个牌型", keys)
            self.log("【优先出的牌组合列表】中，牌型数量是：" .. #keys)
            if #keys == 1 then
              tmpSuitDataArr = a1
            else
              local a2 = {}
              for _, suitDataArr in pairs(suitDataArrDict) do
                if 3 <= #suitDataArr then
                  table.insertto(a2, suitDataArr)
                end
              end
              self:addParamsWithKey(
                "【优先出的牌组合列表】中，牌型中组合数量>=3的牌组合 A2",
                a2
              )
              self.log(
                "【优先出的牌组合列表】中，牌型中组合数量>=3的牌组合。假定是A2牌组合，A2数量是："
                  .. #a2
              )
              if 0 < #a2 then
                tmpSuitDataArr = a2
              else
                tmpSuitDataArr = a1
              end
            end
          end
        end
      end
    end
  end
  local ret = AiUtils:getMinSuitDataWithArr(tmpSuitDataArr)
  return ret
end

-- AiAction · 跟牌：在可压牌列表中选取合适一手（用【优先出的牌组合列表】基础跟牌）
function AiActionData:getFollowBaseActionSuitData()
  self.log("==用【优先出的牌组合列表】基础跟牌")
  local suitDataArr = self:getFirstSuitDataArr()
  self:addParamsWithKey("【优先出的牌组合列表】", suitDataArr)
  local tmpSuitDataArr = suitDataArr
  if tmpSuitDataArr ~= nil and not (#tmpSuitDataArr <= 1) and not AiUtils:isAll42(tmpSuitDataArr) then
    local a0 = AiUtils:filterNot42(tmpSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，非四带二组合 A0", a0)
    self.log("【优先出的牌组合列表】中，非四带二组合。假定是A0牌组合，A0数量是：" .. #a0)
    if #a0 == 1 then
      tmpSuitDataArr = a0
    elseif AiUtils:isAllBomb(a0) then
      tmpSuitDataArr = a0
    else
      local a1 = AiUtils:filterNotBomb(a0)
      self:addParamsWithKey("A0中，非炸弹牌组合 A1", a1)
      self.log("A0中，非炸弹牌组合。假定是A1牌组合，A1数量是：" .. #a1)
      local data = self:getData()
      local a2 = AiUtils:filterNotDisBombSuitDataArr(a1, data:getAllBomb(), data:getLazi())
      self:addParamsWithKey("A1中，不拆炸弹的牌组合 A2", a2)
      self.log("A1中，不拆炸弹的牌组合。假定是A2牌组合，A2数量是：" .. #a2)
      if 0 < #a2 then
        if 0 < data:getLaziCount() then
          local a3 = AiUtils:filterNotLaziSuitDataArr(a2, data:getLazi(), data)
          self:addParamsWithKey("A2中，不含癞子的牌组合 A3", a3)
          self.log("A2中，不含癞子的牌组合。假定是A3牌组合，A3数量是：" .. #a3)
          if 0 < #a3 then
            tmpSuitDataArr = a3
          end
        else
          tmpSuitDataArr = a2
        end
      else
        if 0 < data:getLaziCount() then
          local a3 = AiUtils:filterNotLaziSuitDataArr(a1, data:getLazi(), data)
          self:addParamsWithKey("A1中，不含癞子的牌组合 A3", a3)
          self.log("A1中，不含癞子的牌组合。假定是A3牌组合，A3数量是：" .. #a3)
          if 0 < #a3 then
            tmpSuitDataArr = a3
          end
        else
          tmpSuitDataArr = a1
        end
      end
    end
  end
  local ret = AiUtils:getMinSuitDataWithArr(tmpSuitDataArr)
  return ret
end

-- AiAction · 处理带牌/附带出牌（三带一、四带二等）
function AiActionData:dealDaiPai(suitData)
  local suitType = suitData:getType()
  if
    suitType ~= SuitType.kThreeStraightWithPair
    and suitType ~= SuitType.kThreeStraightWithSingle
    and suitType ~= SuitType.kFourWithTwoPair
    and suitType ~= SuitType.kFourWithTwoSingle
    and suitType ~= SuitType.kThreeWithOnePair
    and suitType ~= SuitType.kThreeWithOneSingle
  then
    return suitData
  end
  local isInArr = false
  local cardTypeListData = self:getData()
  local bestSuitDataArr = cardTypeListData:ai_getBestSuitDataArr()
  for _, bestSuitData in ipairs(bestSuitDataArr) do
    if bestSuitData:getKey() == suitData:getKey() and bestSuitData:getLevel() == suitData:getLevel() then
      isInArr = true
      break
    end
  end
  if not isInArr then
    return suitData
  end
  local cardTypeList = {}
  for _, bestSuitData in ipairs(bestSuitDataArr) do
    if bestSuitData.getMatchSuitType and bestSuitData:getMatchSuitType() == suitData:getMatchSuitType() then
      local matchCardCountMap = bestSuitData:getMatchCardCountMap()
      for cardType, count in pairs(matchCardCountMap) do
        for i = 1, count do
          table.insert(cardTypeList, cardType)
        end
      end
    end
  end
  table.sort(cardTypeList)
  local needCount = 0
  local matchCardCountMap = suitData:getMatchCardCountMap()
  for cardType, count in pairs(matchCardCountMap) do
    needCount = needCount + count
  end
  local needCardTypeList = {}
  for i = 1, needCount do
    needCardTypeList[i] = cardTypeList[i]
  end
  local ret = suitData
  ret:updateMatchWithCardTypeList(needCardTypeList)
  return ret
end

-- AiAction · 首出无结果时的兜底出牌
function AiActionData:normolStart()
  local data = self:getData()
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:setFirstSuitDataArr(bestSuitDataArr)
  return self:getBaseActionSuitData()
end

-- AiAction · 检查最优拆牌是否只剩两张
function AiActionData:checkBestSuitIsTwo()
  local cardTypeListData = self:getData()
  local bestSuitDataArr = cardTypeListData:ai_getBestSuitDataArr()
  if bestSuitDataArr ~= nil then
    return #bestSuitDataArr == 2
  else
    return false
  end
end

-- AiAction · 炸弹与对手收官条件冲突时的修正
function AiActionData:checkIsBombAndIsEnemyWinCondition(actionData, suitData, lastSuitData)
  local suitType = suitData:getType()
  if suitType ~= SuitType.kBomb then
    return suitData
  end
  local cardTypeListData = self:getData()
  local ret = cardTypeListData:ai_still_filterIsEnemyWinCondition(suitData)
  if lastSuitData then
    self.log("==跟牌出炸弹扩展判断")
    if ret then
      self.log("===出完炸弹后，我出的炸弹是对手的d牌，则不出")
      return nil
    else
      self.log("===出完炸弹后，我出的炸弹不是对手的d牌，则出")
      return suitData
    end
  else
    self.log("==出牌出炸弹扩展判断")
    if ret then
      self.log("===出完炸弹后，我出的炸弹是对手的d牌，则用最优分组基础出牌")
      local bestSuitDataArr = cardTypeListData:ai_getBestSuitDataArr()
      actionData:setFirstSuitDataArr(bestSuitDataArr)
      return actionData:getBaseActionSuitData()
    else
      self.log("===出完炸弹后，我出的炸弹不是对手的d牌，则出")
      return suitData
    end
  end
end

-- AiAction · 检查my牌型判断是否王and队友牌型判断是否two
function AiActionData:checkMySuitIsJokerAndFriendSuitIsTwo(friendData, lastSuitData, bestNotBomb)
  if friendData == nil or lastSuitData == nil then
    return false
  end
  local uid = lastSuitData:getUid()
  if
    friendData:getUid() == uid
    and bestNotBomb ~= nil
    and #bestNotBomb == 1
    and lastSuitData:getType() == SuitType.kSingle
    and bestNotBomb[1]:getType() == SuitType.kSingle
    and lastSuitData:getLevel() == 15
    and bestNotBomb[1]:getLevel() == 16
  then
    return true
  end
  return false
end

-- AiAction · 调试：记录命名候选牌组
function AiActionData:addParamsWithKey(key, value)
  self.paramsMap[key] = value
end

-- AiAction · 调试：追加决策路径标记
function AiActionData:addResult(result)
  table.insert(self.result, result)
end

return AiActionData
