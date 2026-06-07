-- 文件: actionWorse/AiWorseFarmerRightFollowData.lua · 反编译 AI 模块（阅读用）

local AiWorseFarmerRightFollowData = class("AiWorseFarmerRightFollowData", AiFarmerRightFollowData)

-- 弱AI·下家农民跟牌 · 构造函数
function AiWorseFarmerRightFollowData:ctor(params)
  AiWorseFarmerRightFollowData.super.ctor(self, params)
end

-- 弱AI·下家农民跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（下家农民跟牌）
function AiWorseFarmerRightFollowData:getActionSuitData()
  self.log("=下家农民跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==下家农民要不起")
    self:addResult("K1")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  if self:enableEnd() and not self:isNeedHelpFriendEnd() then
    return self:getEndActionSuitData(), true
  end
  if self:getLandlordCardCount() <= 2 then
    local ret = self:getLandlordLeftTwoOrOneSuitData()
    if ret ~= nil then
      return ret
    end
  end
  if self:farmerLeftEnableWarningEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  else
    self:addResult("K8")
  end
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  if self:landlordEnableWarningEnd() then
    self.log("===地主能报牌收官")
    if enemyData:getUid() == uid then
      self.log("===上手牌是对手出的")
      return self:getAttackStatusPreventEnemyActionSuitData()
    else
      self.log("===上手牌不是对手出的")
      return self:getAttackStatusNormalActionSuitData()
    end
  else
    self.log("===地主不能报牌收官")
    return self:getAttackStatusNormalActionSuitData()
  end
end

-- 弱AI·下家农民跟牌 · 收官出牌：一手出完或走赢牌路径（下家农民跟牌-收官）
function AiWorseFarmerRightFollowData:getEndActionSuitData()
  self.log("==下家农民跟牌-收官")
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
  self:addResult("K2")
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民跟牌 · 协助队友收官的出牌（下家农民跟牌-帮队友收官）
function AiWorseFarmerRightFollowData:getHelpFriendEndActionSuitData()
  self.log("===下家农民跟牌-帮队友收官")
  local ok, suitData
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  if friendData:getUid() == lastSuitData:getUid() then
    self.log("====上手牌是队友出的，Pass")
    ok = true
    suitData = nil
    self:addResult("K3")
  else
    local lastMatchWinCondition = friendData:ai_isMatchWinCondition(lastSuitData)
    self.log("===上手牌是否是队友的d牌组合：" .. tostring(lastMatchWinCondition))
    if lastMatchWinCondition then
      ok = true
      suitData = nil
      self:addResult("KA")
      goto lbl_100
    else
      self:addResult("KB")
    end
    local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
    local allMaxBiggerSuitDataArr = AiUtils:filterMaxSuitDataArr(allBiggerSuitDataArr)
    self:addParamsWithKey("任意YQ牌组合中，最大牌(抢权最大牌、压制最大牌、绝对最大牌)", allMaxBiggerSuitDataArr)
    local j3 = data:ai_farmerRight_still_filterHasMatchFriendWinConditionSuitDataArr(allMaxBiggerSuitDataArr)
    self:addParamsWithKey("任意YQ牌组合中，某个最大牌(抢权最大牌、压制最大牌、绝对最大牌)不计它后，剩余的牌 有队友的d牌组合\nJ3", j3)
    self.log("====任意YQ牌组合中，某个最大牌(抢权最大牌、压制最大牌、绝对最大牌)不计它后，剩余的牌 有队友的d牌组合。\n假定是J3，J3数量是：" .. #j3)
    if 0 < #j3 then
      ok = true
      self.log("=====【优先出的牌组合列表】=J3牌组合")
      self:setFirstSuitDataArr(j3)
      suitData = self:getBaseActionSuitData()
      self:addResult("K6")
      goto lbl_100
    else
      ok = false
      suitData = nil
      self:addResult("K7")
      goto lbl_100
    end
  end
  ::lbl_100::
  return ok, suitData
end

-- 弱AI·下家农民跟牌 · 获取进攻姿态防守对手出牌动作牌型data（下家农民跟牌-进攻姿态-防队手收官）
function AiWorseFarmerRightFollowData:getAttackStatusPreventEnemyActionSuitData()
  self.log("===下家农民跟牌-进攻姿态-防队手收官")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    local k3 = enemyData:ai_filterMismatchWinCondition(bestBiggerSuitDataArr)
    self:addParamsWithKey("最优分组的YQ牌组合中，对手的D牌组合 K3", k3)
    self.log("====最优分组的YQ牌组合中，对手的D牌组合。假定是K3，K3数量是：" .. #k3)
    if 0 < #k3 then
      if not AiUtils:isAllBomb(k3) then
        self.log("====K3中，不全是炸弹。【优先出的牌组合列表】=K3牌组合")
        self:setFirstSuitDataArr(k3)
        self:addResult("L1")
      else
        self.log("====K3中，全是炸弹")
        local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
        local k11 = enemyData:ai_filterMismatchWinCondition(splitBringBiggerSuitDataArr)
        self:addParamsWithKey("最带牌牌组合的YQ牌组合中，对手的D牌组合 K11", k11)
        self.log("====最带牌牌组合的YQ牌组合中，对手的D牌组合。假定是K11，K11数量是：" .. #k11)
        if 0 < #k11 then
          self.log("====【优先出的牌组合列表】=K11牌组合")
          self:setFirstSuitDataArr(k11)
          self:addResult("L9")
        else
          local k4 = data:ai_farmerRight_still_filterNotLostSuitDataArr(k3)
          self:addParamsWithKey("K3中，某个牌组合不计它后，剩余的牌 不是必败 K4", k4)
          self.log("====K3中，某个牌组合不计它后，剩余的牌 不是必败。假定是K4，K4数量是：" .. #k4)
          if 0 < #k4 then
            self.log("====【优先出的牌组合列表】=K4牌组合")
            self:setFirstSuitDataArr(k4)
            self:addResult("L2")
          else
            self:addResult("L4")
            else
              local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
              self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
              local k10 = enemyData:ai_filterMismatchWinCondition(splitBringBiggerSuitDataArr)
              self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的D牌组合 K10", k10)
              self.log("====带牌牌组合的YQ牌组合中，对手的D牌组合。假定是K10，K10数量是：" .. #k10)
              if 0 < #k10 then
                self.log("====【优先出的牌组合列表】=K10牌组合")
                self:setFirstSuitDataArr(k10)
                self:addResult("LA")
                goto lbl_297
              end
              self:addResult("L3")
            end
            local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
            self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
            local k7 = enemyData:ai_filterMismatchWinCondition(allBiggerSuitDataArr)
            self:addParamsWithKey("任意YQ牌组合中，对手的D牌组合 K7", k7)
            self.log("====任意YQ牌组合中，对手的D牌组合。假定是K7，K7数量是：" .. #k7)
            if 0 < #k7 then
              if not AiUtils:isAllBomb(k7) then
                self.log("====K7中，不全是炸弹。【优先出的牌组合列表】=K7牌组合")
                self:setFirstSuitDataArr(k7)
                self:addResult("L342")
              else
                self.log("====K7中，全是炸弹。")
                local k8 = data:ai_farmerRight_still_filterNotLostSuitDataArr(k7)
                self:addParamsWithKey("K7中，某个牌组合不计它后，剩余的牌 不是必败 K8", k8)
                self.log("====K7中，某个牌组合不计它后，剩余的牌 不是必败。假定是K8，K8数量是：" .. #k8)
                if 0 < #k8 then
                  self.log("=====【优先出的牌组合列表】=K8牌组合")
                  self:setFirstSuitDataArr(k8)
                  self:addResult("L343")
                else
                  self:addResult("L344")
                  else
                    self:addResult("L341")
                  end
                  local k12 = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
                  self:addParamsWithKey("最优分组的非炸弹的YQ牌组合 K12", k12)
                  self.log("最优分组的非炸弹的YQ牌组合，假定是K12，K12数量是：" .. #k12)
                  if 0 < #k12 then
                    do
                      self.log("======【优先出的牌组合列表】=K12牌组合中最大的牌组合")
                      local k12BiggerSuitData = AiUtils:getMaxSuitDataWithArr(k12)
                      self:setFirstSuitDataArr({k12BiggerSuitData})
                      self:addResult("L3411")
                    end
                  else
                    local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
                    self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
                    local k13 = AiUtils:filterNotBomb(splitBringBiggerSuitDataArr)
                    self:addParamsWithKey("带牌组合的非炸弹的YQ牌组合 K13", k13)
                    self.log("带牌组合的非炸弹的YQ牌组合，假定是K13，K13数量是：" .. #k13)
                    if 0 < #k13 then
                      do
                        self.log("======【优先出的牌组合列表】=K13牌组合中最大的牌组合")
                        local k13BiggerSuitData = AiUtils:getMaxSuitDataWithArr(k13)
                        self:setFirstSuitDataArr({k13BiggerSuitData})
                        self:addResult("L3412")
                      end
                    else
                      self:addResult("L3413")
                      return nil
                    end
                  end
                end
              end
          end
        end
      end
  end
  ::lbl_297::
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民跟牌 · 进攻姿态：常规出牌（下家农民跟牌-进攻姿态-常规跟牌）
function AiWorseFarmerRightFollowData:getAttackStatusNormalActionSuitData()
  self.log("===下家农民跟牌-进攻姿态-常规跟牌")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
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
      self:addResult("LB")
    else
      local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
      self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
      if 0 < #splitBringBiggerSuitDataArr then
        firstSuitDataArr = splitBringBiggerSuitDataArr
        self.log("===带牌牌组合的YQ牌组合")
        self:addResult("LC")
      elseif 0 < #bestBiggerSuitDataArr then
        firstSuitDataArr = bestBiggerSuitDataArr
        self.log("===最优分组的YQ牌组合")
        self:addResult("LD")
      end
    end
    if firstSuitDataArr and 0 < #firstSuitDataArr then
      self:addParamsWithKey("最优分组/带牌组合的YQ牌组合", firstSuitDataArr)
      self.log("====最优分组/带牌组合的YQ牌组合，数量是：" .. #firstSuitDataArr)
      if AiUtils:isAllMaxSuitData(firstSuitDataArr) then
        self.log("====最优分组/带牌组合的YQ牌组合中，全是最大牌")
        local k14
        if friendData:getUid() == lastSuitData:getUid() then
          k14 = AiUtils:filterNotBomb(firstSuitDataArr)
          k14 = AiUtils:filterNotMaxSuitDataArr(k14)
          self.log("====上手牌是队友出的，k14=【优先出的牌组合列表】过滤掉炸弹和最大牌")
        else
          k14 = firstSuitDataArr
          self.log("====上手牌不是队友出的，k14=【优先出的牌组合列表】")
        end
        self:addParamsWithKey("【优先出的牌组合列表】 K14", k14)
        self.log("====【优先出的牌组合列表】，K14数量是：" .. #k14)
        if #k14 == 0 then
          self.log("====上手牌是队友出的，且优先出的牌组合只有炸弹，Pass")
          self:addResult("L83")
          return nil
        end
        local k8 = data:ai_still_filterNotMoreLunSuitDataArr(k14)
        self:addParamsWithKey("k14组合中，某个牌组合不计它后，剩余的牌 轮次不会增加 K8", k8)
        self.log("====k14牌组合中，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是K8牌组合, K8数量是：" .. #k8)
        if 0 < #k8 then
          self.log("===== k14=K8牌组合")
          self:setFirstSuitDataArr(k8)
          self:addResult("L6")
          goto lbl_186
        else
          self:addResult("L7")
          return nil
        end
      else
        self.log("====最优分组/带牌的YQ牌组合中，不全是最大牌。【优先出的牌组合列表】=最优分组/带牌的YQ牌组合")
        self:setFirstSuitDataArr(firstSuitDataArr)
        self:addResult("L5")
        goto lbl_186
      end
    else
      self:addResult("L8")
      return nil
    end
  end
  ::lbl_186::
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民跟牌 · 获取地主lefttwoorone牌型data（下家农民跟牌-地主报牌）
function AiWorseFarmerRightFollowData:getLandlordLeftTwoOrOneSuitData()
  self.log("==下家农民跟牌-地主报牌")
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  if self:getLandlordCardCount() == 1 then
    local curCardCount = data:getCardCount()
    if curCardCount == 3 or curCardCount == 4 then
      local cardTypeCountMap = data:getCardTypeCountMap()
      local haveTree = false
      for cardType, num in pairs(cardTypeCountMap) do
        if num == 3 then
          haveTree = true
          break
        end
      end
      if haveTree then
        local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
        local suitData = AiUtils:getMaxSuitDataWithArr(allBiggerSuitDataArr)
        self.log("===对手报单，且我手牌只剩三张或三带一，用任意YQ牌组合中最大的牌组合")
        self:setFirstSuitDataArr({suitData})
        return self:getBaseActionSuitData()
      end
    end
  end
  return nil
end

return AiWorseFarmerRightFollowData
