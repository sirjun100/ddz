-- 文件: actionNormal/AiNormalFarmerLeftFollowData.lua · 反编译 AI 模块（阅读用）

local AiNormalFarmerLeftFollowData = class("AiNormalFarmerLeftFollowData", AiFarmerLeftFollowData)

-- 中等AI·上家农民跟牌 · 构造函数
function AiNormalFarmerLeftFollowData:ctor(params)
  AiNormalFarmerLeftFollowData.super.ctor(self, params)
end

-- 中等AI·上家农民跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（上家农民跟牌）
function AiNormalFarmerLeftFollowData:getActionSuitData()
  self.log("=上家农民跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==上家农民要不起")
    self:addResult("E1")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(lastSuitData, taskData)
  if self:enableEnd() then
    if not self:isNeedHelpFriendEnd() then
      return self:getEndActionSuitData(), true
    end
  else
    if self:checkBestSuitIsTwo() then
      local ret = self:getExtendWinConditions()
      if ret ~= nil then
        return ret
      end
    end
    if self:isNeedPreventEnemysEnd() then
      return self:getPreventStatusPreventEnemyActionSuitData()
    end
  end
  if self:farmerRightEnableWarningEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  else
    self:addResult("E9")
  end
  local status = self:getStatus()
  self.log("=上家农民的姿态: " .. status)
  if status == 0 then
    return self:getPreventStatusActionSuitData()
  else
    return self:getAttackStatusActionSuitData()
  end
end

-- 中等AI·上家农民跟牌 · 计算攻守姿态（0 防守 / 1 进攻）
function AiNormalFarmerLeftFollowData:getStatus()
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local friendRobot = friendData:getRobot()
  local lun = data:ai_getBestFenzuData().lun_
  local friendLun = friendData:ai_getBestFenzuData().lun_
  local ret
  if friendRobot then
    if friendLun > lun + 1 then
      ret = 1
    else
      ret = 0
    end
  elseif lun + 1 < friendLun - 1 then
    ret = 1
  else
    ret = 0
  end
  return ret
end

-- 中等AI·上家农民跟牌 · 判断是否need防守enemys收官（判断是否需要防对手收官）
function AiNormalFarmerLeftFollowData:isNeedPreventEnemysEnd()
  self.log("=判断是否需要防对手收官")
  local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
  if enemyEnableWarningEnd then
    local lastSuitData = self.lastSuitData_
    local uid = lastSuitData:getUid()
    local enemyData = self:getLandlordData()
    if enemyData:getUid() == uid then
      return true
    else
      local isMatchWinCondition = enemyData:ai_isMatchWinCondition(lastSuitData)
      if isMatchWinCondition then
        return true
      end
    end
  end
  return false
end

-- 中等AI·上家农民跟牌 · 收官出牌：一手出完或走赢牌路径（上家农民跟牌-收官）
function AiNormalFarmerLeftFollowData:getEndActionSuitData()
  self.log("==上家农民跟牌-收官")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local taskData = self.taskData_
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("深度最优分组的牌组合", bestSuitDataArr)
  local winConditions = data:ai_getWinConditions()
  self:addParamsWithKey("所有收官牌组合", winConditions)
  local intersectionSuitDataArr = AiUtils:filterIntersectionSuitDataArr(bestSuitDataArr, winConditions)
  self:addParamsWithKey("深度最优分组的收官牌组合", intersectionSuitDataArr)
  if 0 < #intersectionSuitDataArr then
    winConditions = intersectionSuitDataArr
  end
  local biggerWinConditions = AiUtils:filterBiggerSuitDataArr(winConditions, lastSuitData)
  if #biggerWinConditions == 0 then
    biggerWinConditions = data:ai_filterBiggerWinConditions(lastSuitData)
  end
  self:addParamsWithKey("收官的YQ牌组合", biggerWinConditions)
  local noTaskSuitDataArr = AiUtils:filterNotTaskSuitDataArr(biggerWinConditions, taskData)
  self:addParamsWithKey("非最后出牌任务的牌", noTaskSuitDataArr)
  if 0 < #noTaskSuitDataArr then
    self.log("==【优先出的牌组合列表】=非最后出牌任务的牌")
    self:setFirstSuitDataArr(noTaskSuitDataArr)
  else
    self.log("==【优先出的牌组合列表】=收官的YQ牌组合")
    self:setFirstSuitDataArr(biggerWinConditions)
  end
  self:addResult("E2")
  return self:getBaseActionSuitData()
end

-- 中等AI·上家农民跟牌 · 协助队友收官的出牌（上家农民跟牌-帮队友收官）
function AiNormalFarmerLeftFollowData:getHelpFriendEndActionSuitData()
  self.log("===上家农民跟牌-帮队友收官")
  local ok, suitData
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  if friendData:getUid() == uid then
    local enemyEnableFollow, enemyIsLose, friendIsWarningEnd, lastSuitIsMax
    self.log("====上手牌是队友出的")
    local enemyBiggerSuitDataArr = enemyData:ai_all_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("对手任意YQ牌组合", enemyBiggerSuitDataArr)
    self.log("====对手任意YQ牌组合数量是：" .. #enemyBiggerSuitDataArr)
    if 0 < #enemyBiggerSuitDataArr then
      enemyEnableFollow = true
    else
      enemyEnableFollow = false
      self:addResult("E61")
    end
    self.log("====对手是否要不起：" .. tostring(not enemyEnableFollow))
    if enemyEnableFollow then
      enemyIsLose = enemyData:ai_getIsLose()
      if enemyIsLose then
        self:addResult("E62")
      end
    else
      enemyIsLose = nil
    end
    self.log("====对手是否必败：" .. tostring(enemyIsLose))
    if not enemyEnableFollow or enemyIsLose then
      self.log("=====PASS")
      ok, suitData = true, nil
      return ok, suitData
    else
      friendIsWarningEnd = nil
    end
    if enemyIsLose == false then
      local lastSuitDataArr = {lastSuitData}
      lastSuitIsMax = AiUtils:isAllBomb(lastSuitDataArr)
      if lastSuitIsMax == false then
        lastSuitIsMax = AiUtils:getLastSuitIsMaxSuitData(data, enemyData, lastSuitData)
      end
      self.log("====队友出的是否是最大牌：" .. tostring(lastSuitIsMax))
      if lastSuitIsMax then
        self:addResult("E66")
        self.log("=====PASS")
        ok, suitData = true, nil
        return ok, suitData
      else
        self:addResult("E67")
      end
    else
      lastSuitIsMax = nil
    end
  else
    self:addResult("E69")
  end
  if not ok then
    local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
    local allMaxBiggerSuitDataArr = AiUtils:filterMaxSuitDataArr(allBiggerSuitDataArr)
    self:addParamsWithKey("任意YQ牌组合中，最大牌(抢权最大牌、压制最大牌、绝对最大牌)", allMaxBiggerSuitDataArr)
    local n4 = data:ai_farmerLeft_still_filterHasMatchFriendWinConditionSuitDataArr(allMaxBiggerSuitDataArr)
    self:addParamsWithKey("任意YQ牌组合中，某个最大牌(抢权最大牌、压制最大牌、绝对最大牌)不计它后，剩余的牌 有队友的d牌组合（N5），且N5中有某个牌组合对手要得起的牌组合都是队友的d牌组合。\nN4", n4)
    self.log("====任意YQ牌组合中，某个最大牌(抢权最大牌、压制最大牌、绝对最大牌)不计它后，剩余的牌 有队友的d牌组合（N5），且N5中有某个牌组合对手要得起的牌组合都是队友的d牌组合。\n假定是N4，N4数量是：" .. #n4)
    if 0 < #n4 then
      ok = true
      self.log("==【优先出的牌组合列表】=N4牌组合")
      self:setFirstSuitDataArr(n4)
      suitData = self:getBaseActionSuitData()
      self:addResult("E7")
    else
      ok = false
      suitData = nil
      self:addResult("E8")
    end
  end
  return ok, suitData
end

-- 中等AI·上家农民跟牌 · 防守姿态出牌（上家农民跟牌-防手姿态）
function AiNormalFarmerLeftFollowData:getPreventStatusActionSuitData()
  self.log("==上家农民跟牌-防手姿态")
  return self:getPreventStatusNormalActionSuitData()
end

-- 中等AI·上家农民跟牌 · 防守姿态：阻止对手收官的出牌（上家农民跟牌-防守姿态-防队手收官）
function AiNormalFarmerLeftFollowData:getPreventStatusPreventEnemyActionSuitData()
  self.log("===上家农民跟牌-防守姿态-防队手收官")
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    local n1 = enemyData:ai_filterMismatchWinCondition(bestBiggerSuitDataArr)
    self:addParamsWithKey("最优分组的YQ牌组合中，对手的D牌组合 N1", n1)
    self.log("===最优分组的YQ牌组合中，对手的D牌组合。假定是N1，N1数量是：" .. #n1)
    if 0 < #n1 then
      if not AiUtils:isAllBomb(n1) then
        self.log("====N1中，不全是炸弹。【优先出的牌组合列表】=N1牌组合")
        self:setFirstSuitDataArr(n1)
        self:addResult("E3")
      else
        self.log("====N1中，全是炸弹")
        self:addResult("E5")
        else
          self:addResult("E4")
        end
        local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
        local n7 = enemyData:ai_filterMismatchWinCondition(splitBringBiggerSuitDataArr)
        self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的D牌组合 N7", n7)
        self.log("===带牌牌组合的YQ牌组合中，对手的D牌组合。假定是N7，N7数量是：" .. #n7)
        if 0 < #n7 then
          self.log("=====【优先出的牌组合列表】=N7牌组合")
          self:setFirstSuitDataArr(n7)
          self:addResult("EA")
        else
          local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
          local n2 = enemyData:ai_filterMismatchWinCondition(allBiggerSuitDataArr)
          self:addParamsWithKey("任意YQ牌组合中，对手的D牌组合 N2", n2)
          self.log("===任意YQ牌组合中，对手的D牌组合。假定是N2，N2数量是：" .. #n2)
          if 0 < #n2 then
            if not AiUtils:isAllBomb(n2) then
              self.log("====N2中，不全是炸弹。【优先出的牌组合列表】=N2牌组合")
              self:setFirstSuitDataArr(n2)
              self:addResult("E41")
            else
              self.log("====N2中，全是炸弹")
              local n3 = data:ai_farmerLeft_still_filterNotLoseOrFriendSmallerMaxSuitDataArr(n2)
              self:addParamsWithKey("N2中，某个牌组合不计它后，剩余的牌 符合下列任意条件：1、不是必败；2、用对手的D牌组合可以把出牌权交个队友，且队友不是必败。\nN3", n3)
              self.log("====N2中，某个牌组合不计它后，剩余的牌 符合下列任意条件：1、不是必败；2、用对手的D牌组合可以把出牌权交个队友，且队友不是必败。\n假定是N3，N3数量是：" .. #n3)
              if 0 < #n3 then
                self.log("=====【优先出的牌组合列表】=N3牌组合")
                self:setFirstSuitDataArr(n3)
                self:addResult("E42")
              else
                self:addResult("E43")
                else
                  self:addResult("E4B")
                end
                if lastSuitData:getUid() == friendData:getUid() and AiUtils:getLastSuitIsMaxSuitData(data, enemyData, lastSuitData) then
                  self.log("====上手牌是队友出的，且是最大牌或大牌，Pass")
                  self:addResult("E4A")
                  return nil
                end
                local n8 = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
                self:addParamsWithKey("最优分组的非炸弹的YQ牌组合 N8", n8)
                self.log("最优分组的非炸弹的YQ牌组合，假定是N8，N8数量是：" .. #n8)
                if 0 < #n8 then
                  self.log("======【优先出的牌组合列表】=N8牌组合中最大的牌组合")
                  local n8BiggerSuitData = AiUtils:getMaxSuitDataWithArr(n8)
                  if self:getLandlordCardCount() == 1 and lastSuitData:getType() == SuitType.kSingle and not AiUtils:checkIsMaxLevel(data:getCardTypeList(), n8BiggerSuitData:getLevel()) then
                    n8BiggerSuitData = {}
                    self.log("======【优先出的牌组合列表】=对手报单，N8牌组合中最大的牌组合不是自己的最大牌")
                    self:addResult("E51")
                  end
                  if 0 < #n8BiggerSuitData then
                    self:setFirstSuitDataArr({n8BiggerSuitData})
                    self:addResult("E44")
                end
                else
                  local n9 = AiUtils:filterNotBomb(splitBringBiggerSuitDataArr)
                  self:addParamsWithKey("带牌组合的非炸弹的YQ牌组合 N9", n9)
                  self.log("带牌组合的非炸弹的YQ牌组合，假定是N9，N9数量是：" .. #n9)
                  if 0 < #n9 then
                    do
                      self.log("======【优先出的牌组合列表】=N9牌组合中最大的牌组合")
                      local n9BiggerSuitData = AiUtils:getMaxSuitDataWithArr(n9)
                      self:setFirstSuitDataArr({n9BiggerSuitData})
                      self:addResult("E45")
                    end
                  else
                    local allBiggerNotDisBombSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
                    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerNotDisBombSuitDataArr)
                    self.log("任意YQ牌组合(不拆炸弹)，数量是：" .. #allBiggerNotDisBombSuitDataArr)
                    if 0 < #allBiggerNotDisBombSuitDataArr then
                      do
                        local n15 = AiUtils:filterNotBomb(allBiggerNotDisBombSuitDataArr)
                        self:addParamsWithKey("任意不拆炸弹YQ牌组合的非炸弹牌组合 N15", n15)
                        self.log("任意不拆炸弹YQ牌组合的非炸弹牌组合，假定是N15，N15数量是：" .. #n15)
                        if 0 < #n15 then
                          self.log("======【优先出的牌组合列表】=N15牌组合")
                          self:setFirstSuitDataArr(n15)
                          self:addResult("E50")
                        else
                          self.log("======【优先出的牌组合列表】=任意YQ牌组合(不拆炸弹)牌组合")
                          self:setFirstSuitDataArr(allBiggerNotDisBombSuitDataArr)
                          self:addResult("E51")
                        end
                      end
                    else
                      self:addResult("E46")
                      return nil
                    end
                  end
                end
              end
            end
        end
      end
  end
  return self:getBaseActionSuitData()
end

-- 中等AI·上家农民跟牌 · 获取防守姿态常规出牌动作牌型data（上家农民跟牌-防守姿态-常规跟牌）
function AiNormalFarmerLeftFollowData:getPreventStatusNormalActionSuitData()
  self.log("===上家农民跟牌-防守姿态-常规跟牌")
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    local allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
    if friendData:getUid() ~= uid then
      do
        self.log("====上手牌不是队友出的，地主出的")
        local o8 = AiUtils:filterNotBombMaxSuitDataArr(bestBiggerSuitDataArr)
        self:addParamsWithKey("最优分组YQ牌组合中，非炸弹最大牌（抢权最大牌、压制最大牌） O8", o8)
        self.log("====最优分组YQ牌组合中，非炸弹最大牌（抢权最大牌、压制最大牌）。假定O8，O8数量是：" .. #o8)
        local o9 = data:ai_farmerLeft_still_filterHasFriendLmaxOrSmallerMaxSuitDataArr(o8, lastSuitData)
        self:addParamsWithKey("O8中，某个牌组合不计它后，剩余的牌 能帮队友溜牌，或者把出牌权交给队友\nO9", o9)
        self.log("=====O8中，某个牌组合不计它后，剩余的牌 能帮队友溜牌，或者把出牌权交给队友。\n假定是O9，O9数量是：" .. #o9)
        if 0 < #o9 then
          self.log("======【优先出的牌组合列表】=O9牌组合")
          self:setFirstSuitDataArr(o9)
          self:addResult("G7")
        else
          local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
          local o17 = AiUtils:filterNotBombMaxSuitDataArr(splitBringBiggerSuitDataArr)
          self:addParamsWithKey("带牌牌组合YQ牌组合中，非炸弹最大牌（抢权最大牌、压制最大牌） O17", o17)
          self.log("====带牌牌组合YQ牌组合中，非炸弹最大牌（抢权最大牌、压制最大牌）。假定O17，O17数量是：" .. #o17)
          local o18 = data:ai_farmerLeft_still_filterHasFriendLmaxOrSmallerMaxSuitDataArr(o17, lastSuitData)
          self:addParamsWithKey("O17中，某个牌组合不计它后，剩余的牌 能帮队友溜牌，或者把出牌权交给队友\nO18", o18)
          self.log("=====O17中，某个牌组合不计它后，剩余的牌 能帮队友溜牌，或者把出牌权交给队友。\n假定是O18，O18数量是：" .. #o18)
          if 0 < #o18 then
            self.log("======【优先出的牌组合列表】=O18牌组合")
            self:setFirstSuitDataArr(o18)
            self:addResult("G8")
          else
            local o3 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(bestBiggerSuitDataArr)
            self:addParamsWithKey("最优分组的YQ牌组合中，对手的DP牌组合 O3", o3)
            self.log("====最优分组的YQ牌组合中，对手的DP牌组合。假定是O3，O3数量是：" .. #o3)
            if 0 < #o3 then
              self.log("=====【优先出的牌组合列表】=O3牌组合")
              self:setFirstSuitDataArr(o3)
              self:addResult("G0")
            else
              local o4 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(splitBringBiggerSuitDataArr)
              self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的DP牌组合 O4", o4)
              self.log("====带牌牌组合的YQ牌组合中，对手的DP牌组合。假定是O4，O4数量是：" .. #o4)
              if 0 < #o4 then
                self.log("=====【优先出的牌组合列表】=O4牌组合")
                self:setFirstSuitDataArr(o4)
                self:addResult("G3")
              else
                local allBiggerDisBombSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
                self:addParamsWithKey("任意YQ牌组合", allBiggerDisBombSuitDataArr)
                local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
                self:addParamsWithKey("对手最优分组的YQ牌组合", enemyBiggerSuitDataArr)
                local enemyLiuBiggerSuitDataArr = AiUtils:filterLiuSuitDataArr(enemyBiggerSuitDataArr)
                self:addParamsWithKey("对手最优分组的YQ牌组合中，L牌", enemyLiuBiggerSuitDataArr)
                local bestNotBomb = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
                self:addParamsWithKey("最优分组的非炸弹的YQ牌组合", bestNotBomb)
                local liuSuitDataArr = AiUtils:filterLiuSuitDataArr(allBiggerDisBombSuitDataArr)
                self:addParamsWithKey("任意YQ牌组合中，L牌组合", liuSuitDataArr)
                local x = AiUtils:getMaxYaSuitData(enemyLiuBiggerSuitDataArr, liuSuitDataArr)
                self.log("===对手能被自己【任意YQ牌组合的L牌组合】压住的L牌组合中的最大牌。假定是X，X是：" .. (x and x:toString() or "nil"))
                if x then
                  self:addParamsWithKey("对手能被自己【任意YQ牌组合的L牌组合】压住的L牌组合中的最大牌 X", {x})
                  local bestLiu = AiUtils:filterLiuSuitDataArr(bestNotBomb)
                  self:addParamsWithKey("最优分组中，L牌组合", bestLiu)
                  local o5_max = AiUtils:getMaxLevelSuitData(bestLiu)
                  if o5_max then
                    do
                      local arr = {o5_max}
                      self:addParamsWithKey("O5牌组合的最大牌", arr)
                      self.log("====【优先出的牌组合列表】=O5牌组合中的最大牌")
                      self:setFirstSuitDataArr(arr)
                      self:addResult("G4")
                    end
                  else
                    local splitBringLiu = AiUtils:filterLiuSuitDataArr(splitBringBiggerSuitDataArr)
                    self:addParamsWithKey("带牌牌组合中，L牌组合", splitBringLiu)
                    local o6_max = AiUtils:getMaxLevelSuitData(splitBringLiu)
                    if o6_max then
                      local arr = {o6_max}
                      self:addParamsWithKey("O6牌组合的最大牌", arr)
                      self.log("====【优先出的牌组合列表】=O6牌组合中的最大牌")
                      self:setFirstSuitDataArr(arr)
                      self:addResult("G5")
                    else
                      self.log("=====【优先出的牌组合列表】=最优分组的非最大牌的YQ牌组合")
                      local notMaxSuitDataArr = AiUtils:filterNotMaxSuitDataArr(bestBiggerSuitDataArr)
                      self:setFirstSuitDataArr(notMaxSuitDataArr)
                      self:addResult("G6")
                    end
                  end
                end
              end
            end
          end
        end
      end
    else
      self.log("====上手牌是队友出的，不是地主出的")
      local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
      local enemyBiggerNotBombSuitDataArr = AiUtils:filterNotBomb(enemyBiggerSuitDataArr)
      self:addParamsWithKey("对手最优分组YQ牌组合(除开炸弹)", enemyBiggerNotBombSuitDataArr)
      self.log("====对手最优分组YQ牌组合(除开炸弹)数量是：" .. #enemyBiggerNotBombSuitDataArr)
      local enemySplitBringSuitDataArr = enemyData:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
      self:addParamsWithKey("对手带牌牌组合YQ牌", enemySplitBringSuitDataArr)
      self.log("====对手带牌牌组合YQ牌数量是：" .. #enemySplitBringSuitDataArr)
      if 0 < #enemySplitBringSuitDataArr then
        table.insertto(enemyBiggerNotBombSuitDataArr, enemySplitBringSuitDataArr)
      end
      if #enemyBiggerNotBombSuitDataArr == 0 then
        self.log("=====对手要不起，Pass")
        self:addResult("GG")
        return nil
      end
      local level = lastSuitData:getLevel()
      self.log("=====上手牌大小" .. level)
      if 12 <= level then
        local DP = enemyData:ai_liu_filterBiggerLmaxSuitDataArr({lastSuitData})
        if #DP == 1 then
          self.log("======上手队友出的牌是对手的Y牌组合，且牌>=Q，Pass")
          self:addResult("GD1")
          return nil
        end
      end
      local o12 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(bestBiggerSuitDataArr)
      self:addParamsWithKey("最优分组的YQ牌组合中，对手的DP牌组合 O12", o12)
      self.log("====最优分组的YQ牌组合中，对手的DP牌组合。假定是O12，O12数量是：" .. #o12)
      if 0 < #o12 then
        self.log("=====【优先出的牌组合列表】=O12牌组合")
        self:setFirstSuitDataArr(o12)
        self:addResult("GD2")
      else
        local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
        local o13 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(splitBringBiggerSuitDataArr)
        self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的DP牌组合 O13", o13)
        self.log("====带牌牌组合的YQ牌组合中，对手的DP牌组合。假定是O13，O13数量是：" .. #o13)
        if 0 < #o13 then
          self.log("=====【优先出的牌组合列表】=O13牌组合")
          self:setFirstSuitDataArr(o13)
          self:addResult("GD5")
        else
          local allBiggerDisBombSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("任意YQ牌组合", allBiggerDisBombSuitDataArr)
          local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("对手最优分组的YQ牌组合", enemyBiggerSuitDataArr)
          local enemyLiuBiggerSuitDataArr = AiUtils:filterLiuSuitDataArr(enemyBiggerSuitDataArr)
          self:addParamsWithKey("对手最优分组的YQ牌组合中，L牌", enemyLiuBiggerSuitDataArr)
          local bestNotBomb = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
          self:addParamsWithKey("最优分组的非炸弹的YQ牌组合", bestNotBomb)
          local liuSuitDataArr = AiUtils:filterLiuSuitDataArr(allBiggerDisBombSuitDataArr)
          self:addParamsWithKey("任意YQ牌组合中，L牌组合", liuSuitDataArr)
          local x = AiUtils:getMaxYaSuitData(enemyLiuBiggerSuitDataArr, liuSuitDataArr)
          self.log("===对手能被自己【任意YQ牌组合的L牌组合】压住的L牌组合中的最大牌。假定是X，X是：" .. (x and x:toString() or "nil"))
          if x then
            self:addParamsWithKey("对手能被自己【任意YQ牌组合的L牌组合】压住的L牌组合中的最大牌 X", {x})
            local bestLiu = AiUtils:filterLiuSuitDataArr(bestNotBomb)
            self:addParamsWithKey("最优分组YQ牌组合中，L牌组合", bestLiu)
            local o14_max = AiUtils:getMaxLevelSuitData(bestLiu)
            if o14_max then
              do
                local arr = {o14_max}
                self:addParamsWithKey("O14牌组合的最大牌", arr)
                self.log("====【优先出的牌组合列表】=O14牌组合中的最大牌")
                self:setFirstSuitDataArr(arr)
                self:addResult("GD4")
              end
            else
              local splitBringLiu = AiUtils:filterLiuSuitDataArr(splitBringBiggerSuitDataArr)
              self:addParamsWithKey("带牌YQ牌组合中，L牌组合", splitBringLiu)
              local o15_max = AiUtils:getMaxLevelSuitData(splitBringLiu)
              if o15_max then
                local arr = {o15_max}
                self:addParamsWithKey("O15牌组合的最大牌", arr)
                self.log("====【优先出的牌组合列表】=O15牌组合中的最大牌")
                self:setFirstSuitDataArr(arr)
                self:addResult("GD6")
              else
                self.log("=====【优先出的牌组合列表】=最优分组的非大牌的YQ牌组合")
                local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                self:setFirstSuitDataArr(notMaxSuitDataArr)
                self:addResult("GD7")
              end
            end
          end
        end
      end
    end
  end
  return self:getBaseActionSuitData()
end

-- 中等AI·上家农民跟牌 · 进攻姿态出牌（上家农民跟牌-进攻姿态）
function AiNormalFarmerLeftFollowData:getAttackStatusActionSuitData()
  self.log("==上家农民跟牌-进攻姿态")
  return self:getAttackStatusNormalActionSuitData()
end

-- 中等AI·上家农民跟牌 · 进攻姿态：常规出牌（上家农民跟牌-进攻姿态-常规跟牌）
function AiNormalFarmerLeftFollowData:getAttackStatusNormalActionSuitData()
  self.log("===上家农民跟牌-进攻姿态-常规跟牌")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    self.log("===最优分组的YQ牌组合数量是：" .. #bestBiggerSuitDataArr)
    local bestBiggerNotBombSuitDataArr = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
    self.log("===最优分组非炸弹的YQ牌组合数量是：" .. #bestBiggerNotBombSuitDataArr)
    local firstSuitDataArr
    if 0 < #bestBiggerNotBombSuitDataArr then
      firstSuitDataArr = bestBiggerNotBombSuitDataArr
      self.log("===最优分组非炸弹的YQ牌组合")
      self:addResult("F5")
    else
      local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
      self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
      self.log("===带牌牌组合的YQ牌组合数量是：" .. #splitBringBiggerSuitDataArr)
      if 0 < #splitBringBiggerSuitDataArr then
        firstSuitDataArr = splitBringBiggerSuitDataArr
        self:addResult("F6")
      elseif 0 < #bestBiggerSuitDataArr then
        firstSuitDataArr = bestBiggerSuitDataArr
        self:addResult("F7")
      end
    end
    local n14
    if firstSuitDataArr and 0 < #firstSuitDataArr then
      if not AiUtils:isAllMaxSuitData(firstSuitDataArr) then
        self.log("====最优分组/带牌组合的YQ牌组合中，不全是最大牌。【优先出的牌组合列表】=最优分组/带牌组合的YQ牌组合")
        self:setFirstSuitDataArr(firstSuitDataArr)
        self:addResult("F1")
      else
        self.log("====最优分组/带牌组合的YQ牌组合中，全是最大牌")
        if friendData:getUid() == lastSuitData:getUid() then
          n14 = AiUtils:filterNotBomb(firstSuitDataArr)
          self.log("====上手牌是队友出的，n14=【优先出的牌组合列表】过滤掉炸弹")
          self:addResult("F44")
        else
          n14 = firstSuitDataArr
          self.log("====上手牌不是队友出的，n14=【优先出的牌组合列表】")
        end
        self:addParamsWithKey("【优先出的牌组合列表】 N14", n14)
        self.log("====【优先出的牌组合列表】，N14数量是：" .. #n14)
        if #n14 == 0 then
          self.log("====上手牌是队友出的，且优先出的牌组合只有炸弹，Pass")
          self:addResult("F43")
          return nil
        end
        local n5 = data:ai_still_filterNotMoreLunSuitDataArr(n14)
        self:addParamsWithKey("n14组合中，某个牌组合不计它后，剩余的牌 轮次不会增加 N5", n5)
        self.log("====n14组合中，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是N5牌组合, N5数量是：" .. #n5)
        if 0 < #n5 then
          self.log("=====【优先出的牌组合列表】=N5牌组合")
          self:setFirstSuitDataArr(n5)
          self:addResult("F2")
        else
          self:addResult("F3")
          if friendData:getUid() == lastSuitData:getUid() then
            self:addResult("F46")
            return nil
          end
          else
            self:addResult("F4")
          end
          local allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
          self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
          local diffBiggerSuitDataArr = AiUtils:filterBSuitDataArrFromASuitDataArr(allBiggerSuitDataArr, n14)
          self:addParamsWithKey("任意YQ牌组合(不拆炸弹)中和n14不相同的牌组合", diffBiggerSuitDataArr)
          self.log("===任意YQ牌组合(不拆炸弹)中和n14不相同的牌组合数量是：" .. #diffBiggerSuitDataArr)
          if 0 < #diffBiggerSuitDataArr then
            local n6 = data:ai_still_filterNotMoreLunSuitDataArr(diffBiggerSuitDataArr)
            self:addParamsWithKey("任意YQ牌组合中(不拆炸弹)，某个牌组合不计它后，剩余的牌 轮次不会增加 N6", n6)
            self.log("===任意YQ牌组合中(不拆炸弹)，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是N6, N6数量是：" .. #n6)
            if 0 < #n6 then
              self.log("====【优先出的牌组合列表】=N6牌组合")
              self:setFirstSuitDataArr(n6)
              self:addResult("F41")
              goto lbl_261
            end
          else
            self.log("====任意YQ牌组合(不拆炸弹)中，没有跟n14不相同的牌组合")
          end
          if enemyData:getUid() == lastSuitData:getUid() and enemyData:ai_bestFenzu_isLeftBombAndOneSuit() then
            self.log("====最后出牌的地主只剩下一个炸弹和一手牌，进入防对手收官流程")
            self:addResult("F45")
            return self:getPreventStatusPreventEnemyActionSuitData()
          end
          self.log("====跟牌后，轮次会增加，Pass")
          self:addResult("F42")
          return nil
        end
      end
  end
  ::lbl_261::
  return self:getBaseActionSuitData()
end

-- 中等AI·上家农民跟牌 · 获取extend赢牌/收官conditions（上家农民跟牌-收官扩展）
function AiNormalFarmerLeftFollowData:getExtendWinConditions()
  self.log("==上家农民跟牌-收官扩展")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
  self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
  local ret = data:ai_farmer_still_filterLandlordLostSuitDataArr(bestBiggerSuitDataArr)
  if 0 < #ret then
    self:addParamsWithKey("出了这一手牌手，对手必败，那么也算我能收官", ret)
    self.log("=====出了这一手牌手，对手必败的组合数量是：" .. #ret)
    self:setFirstSuitDataArr(ret)
    return self:getBaseActionSuitData()
  end
  self.log("=====出了这一手牌手，对手必败的组合数量是：0")
  return nil
end

return AiNormalFarmerLeftFollowData
