-- 文件: actionWorse/AiWorseFarmerLeftFollowData.lua · 反编译 AI 模块（阅读用）

local AiWorseFarmerLeftFollowData = class("AiWorseFarmerLeftFollowData", AiFarmerLeftFollowData)

-- 弱AI·上家农民跟牌 · 构造函数
function AiWorseFarmerLeftFollowData:ctor(params)
  AiWorseFarmerLeftFollowData.super.ctor(self, params)
end

-- 弱AI·上家农民跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（上家农民跟牌）
function AiWorseFarmerLeftFollowData:getActionSuitData()
  self.log("=上家农民跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==上家农民要不起")
    self:addResult("E1")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  if self:enableEnd() and not self:isNeedHelpFriendEnd() then
    return self:getEndActionSuitData(), true
  end
  if self:isNeedPreventEnemysEnd() then
    return self:getPreventStatusPreventEnemyActionSuitData()
  end
  if self:farmerRightEnableWarningEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  else
    self:addResult("E9")
  end
  return self:getAttackStatusNormalActionSuitData()
end

-- 弱AI·上家农民跟牌 · 判断是否need防守enemys收官（判断是否需要防对手收官）
function AiWorseFarmerLeftFollowData:isNeedPreventEnemysEnd()
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

-- 弱AI·上家农民跟牌 · 收官出牌：一手出完或走赢牌路径（上家农民跟牌-收官）
function AiWorseFarmerLeftFollowData:getEndActionSuitData()
  self.log("==上家农民跟牌-收官")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(lastSuitData, taskData)
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

-- 弱AI·上家农民跟牌 · 协助队友收官的出牌（上家农民跟牌-帮队友收官）
function AiWorseFarmerLeftFollowData:getHelpFriendEndActionSuitData()
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
      n4 = AiUtils:filterNotDisBombSuitDataArr(n4, data:getAllBomb(), data:getLazi())
      self:addParamsWithKey("N4中不拆炸弹的组合", n4)
      if 0 < #n4 then
        ok = true
        self.log("==【优先出的牌组合列表】=N4牌组合")
        self:setFirstSuitDataArr(n4)
        suitData = self:getBaseActionSuitData()
        self:addResult("E7")
      end
    else
      ok = false
      suitData = nil
      self:addResult("E8")
    end
  end
  return ok, suitData
end

-- 弱AI·上家农民跟牌 · 防守姿态：阻止对手收官的出牌（上家农民跟牌-防守姿态-防队手收官）
function AiWorseFarmerLeftFollowData:getPreventStatusPreventEnemyActionSuitData()
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
        goto lbl_353
      else
        self.log("====N1中，全是炸弹")
        self:addResult("E5")
      end
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
          local n3 = data:ai_farmerRight_still_filterNotLostSuitDataArr(n2)
          self:addParamsWithKey("N2中，某个牌组合不计它后，剩余的牌 不是必败 N3", n3)
          self.log("====N2中，某个牌组合不计它后，剩余的牌 不是必败。假定是N3牌组合，N3数量是：" .. #n3)
          if 0 < #n3 then
            self.log("=====【优先出的牌组合列表】=N3牌组合")
            self:setFirstSuitDataArr(n3)
            self:addResult("E42")
          else
            local bestNotBomb = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
            self:addParamsWithKey("最优分组的非炸弹的YQ牌组合", bestNotBomb)
            self.log("====【优先出的牌组合列表】=最优分组的非炸弹的YQ牌组合")
            self:setFirstSuitDataArr(bestNotBomb)
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
  ::lbl_353::
  return self:getBaseActionSuitData()
end

-- 弱AI·上家农民跟牌 · 进攻姿态：常规出牌（上家农民跟牌-进攻姿态-常规跟牌）
function AiWorseFarmerLeftFollowData:getAttackStatusNormalActionSuitData()
  self.log("===上家农民跟牌-进攻姿态-常规跟牌")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerRightData()
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
    if firstSuitDataArr and 0 < #firstSuitDataArr then
      if not AiUtils:isAllMaxSuitData(firstSuitDataArr) then
        self.log("====最优分组/带牌组合的YQ牌组合中，不全是最大牌。【优先出的牌组合列表】=最优分组/带牌组合的YQ牌组合")
        self:setFirstSuitDataArr(firstSuitDataArr)
        self:addResult("F1")
      else
        self.log("====最优分组/带牌组合的YQ牌组合中，全是最大牌")
        local n14
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
          return nil
        end
      end
    else
      self:addResult("F4")
      return nil
    end
  end
  return self:getBaseActionSuitData()
end

return AiWorseFarmerLeftFollowData
