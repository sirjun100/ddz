-- 文件: actionBest/AiBestFarmerRightFollowData.lua · 反编译 AI 模块（阅读用）

local AiBestFarmerRightFollowData = class("AiBestFarmerRightFollowData", AiFarmerRightFollowData)

-- 强AI·下家农民跟牌 · 构造函数
function AiBestFarmerRightFollowData:ctor(params)
  AiBestFarmerRightFollowData.super.ctor(self, params)
end

-- 强AI·下家农民跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（下家农民跟牌）
function AiBestFarmerRightFollowData:getActionSuitData()
  self.log("=下家农民跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==下家农民要不起")
    self:addResult("K1")
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
  elseif self:checkBestSuitIsTwo() then
    local ret = self:getExtendWinConditions()
    if ret ~= nil then
      return ret
    end
  end
  if self:getLandlordCardCount() <= 2 then
    local ret = self:getLandlordLeftTwoOrOneSuitData()
    if ret ~= nil then
      return ret
    end
  end
  if self:farmerLeftEnableEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  else
    self:addResult("K8")
  end
  local status = self:getStatus()
  self.log("=下家农民的姿态: " .. status)
  if status == 0 then
    return self:getPreventStatusActionSuitData()
  else
    return self:getAttackStatusActionSuitData()
  end
end

-- 强AI·下家农民跟牌 · 计算攻守姿态（0 防守 / 1 进攻）
function AiBestFarmerRightFollowData:getStatus()
  local data = self:getFarmerRightData()
  local friendData = self:getFarmerLeftData()
  local friendRobot = friendData:getRobot()
  local lun = data:ai_getBestFenzuData().lun_
  local friendLun = friendData:ai_getBestFenzuData().lun_
  local ret
  if friendRobot then
    if lun > friendLun + 1 then
      ret = 0
    else
      ret = 1
    end
  elseif lun > friendLun - 1 then
    ret = 0
  else
    ret = 1
  end
  return ret
end

-- 强AI·下家农民跟牌 · 收官出牌：一手出完或走赢牌路径（下家农民跟牌-收官）
function AiBestFarmerRightFollowData:getEndActionSuitData()
  self.log("==下家农民跟牌-收官")
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
  self:addResult("K2")
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民跟牌 · 协助队友收官的出牌（下家农民跟牌-帮队友收官）
function AiBestFarmerRightFollowData:getHelpFriendEndActionSuitData()
  self.log("===下家农民跟牌-帮队友收官")
  local ok, suitData
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  local discardMoreBomb = self:getDiscardMoreBomb()
  if discardMoreBomb then
    self.log("====【优先出的牌组合列表】=任意牌组合中，尽可能出的炸弹")
    self:setFirstSuitDataArr(discardMoreBomb)
    ok = true
    suitData = self:getBaseActionSuitData()
    self:addResult("K9")
  elseif friendData:getUid() == lastSuitData:getUid() then
    self.log("====上手牌是队友出的，Pass")
    ok = true
    suitData = nil
    self:addResult("K3")
  else
    local lastMatchWinCondition = friendData:ai_isMatchWinCondition(lastSuitData)
    self.log("===上手牌是否是队友的d牌组合：" .. tostring(lastMatchWinCondition))
    if self:farmerLeftEnableWarningEnd() then
      self.log("====队友报牌收官")
      if lastMatchWinCondition then
        ok = true
        suitData = nil
        self:addResult("KA")
        goto lbl_245
      else
        self:addResult("KB")
      end
    else
      self.log("====队友不是报牌收官")
      if lastMatchWinCondition then
        local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
        bestBiggerSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
        if 0 < #bestBiggerSuitDataArr then
          local j1 = friendData:ai_filterMatchWinCondition(bestBiggerSuitDataArr)
          self:addParamsWithKey("最优分组非大牌的YQ牌组合中，队友d牌组合的牌组合 J1", j1)
          self.log("=====最优分组非大牌的YQ牌组合中，队友d牌组合的牌组合。假定是J1，J1数量是：" .. #j1)
          if 0 < #j1 then
            ok = true
            self.log("=====【优先出的牌组合列表】=J1牌组合")
            self:setFirstSuitDataArr(j1)
            suitData = self:getBaseActionSuitData()
            self:addResult("K4")
            goto lbl_245
          else
            self.log("====不能顺牌，Pass")
            self:addResult("K5")
            suitData = nil
            goto lbl_245
          end
        end
      else
        local enemyIsLose = enemyData:ai_getIsLose()
        if enemyIsLose then
          self.log("====对手必败")
          local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
          bestBiggerSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
          if 0 < #bestBiggerSuitDataArr then
            local j4 = AiUtils:filterLiuSuitDataArr(bestBiggerSuitDataArr)
            self:addParamsWithKey("最优分组非大牌的YQ牌组合中，L牌组合 J4", j4)
            self.log("====最优分组的YQ牌组合中，L牌组合。假定是J4，J4数量是：" .. #j4)
            if 0 < #j4 then
              ok = true
              self.log("=====【优先出的牌组合列表】=J4牌组合")
              self:setFirstSuitDataArr(j4)
              suitData = self:getBaseActionSuitData()
              self:addResult("KC")
              goto lbl_245
            else
              self.log("====不能顺牌，Pass")
              self:addResult("KE")
              suitData = nil
              goto lbl_245
            end
          end
        else
          self.log("====对手不是必败")
          self:addResult("KD")
        end
      end
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
      goto lbl_245
    else
      ok = false
      suitData = nil
      self:addResult("K7")
      goto lbl_245
    end
  end
  ::lbl_245::
  return ok, suitData
end

-- 强AI·下家农民跟牌 · 防守姿态出牌（下家农民跟牌-防手姿态）
function AiBestFarmerRightFollowData:getPreventStatusActionSuitData()
  self.log("==下家农民跟牌-防手姿态")
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  if enemyData:getUid() ~= uid then
    self.log("===不是对手的出牌")
    local friendSuitDataArr = friendData:ai_all_getSuitDataArr()
    self:addParamsWithKey("队友任意牌组合", friendSuitDataArr)
    local friendMisMatchWinCondition = enemyData:ai_filterMismatchWinCondition(friendSuitDataArr)
    self:addParamsWithKey("队友任意牌组合中，对手的D牌组合", friendMisMatchWinCondition)
    self.log("===队友任意牌组合中，对手的D牌组合数量是：" .. #friendMisMatchWinCondition)
    if #friendMisMatchWinCondition == 0 then
      self.log("====队友必败，防对手收官")
      self:addResult("M01")
      return self:getPreventStatusPreventEnemyActionSuitData()
    else
      self.log("====队友不是必败，PASS")
      self:addResult("M1")
      return nil
    end
  end
  if self:landlordEnableEnd() then
    self.log("===地主能收官")
    self:addResult("M02")
    return self:getPreventStatusPreventEnemyActionSuitData()
  else
    self.log("===地主不能收官")
    return self:getPreventStatusNormalActionSuitData()
  end
end

-- 强AI·下家农民跟牌 · 防守姿态：阻止对手收官的出牌（下家农民跟牌-防守姿态-防队手收官）
function AiBestFarmerRightFollowData:getPreventStatusPreventEnemyActionSuitData()
  self.log("===下家农民跟牌-防守姿态-防队手收官")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
    local m1 = enemyData:ai_filterMismatchWinCondition(bestBiggerSuitDataArr)
    self:addParamsWithKey("最优分组的YQ牌组合中，对手的D牌组合 M1", m1)
    self.log("===最优分组的YQ牌组合中，对手的D牌组合。假定是M1，M1数量是：" .. #m1)
    if 0 < #m1 then
      if not AiUtils:isAllBomb(m1) then
        self.log("====M1中，不全是炸弹。【优先出的牌组合列表】=M1牌组合")
        self:setFirstSuitDataArr(m1)
        self:addResult("M2")
      else
        self.log("====M1中，全是炸弹")
        self:addResult("M3")
        else
          local m16 = enemyData:ai_filterMismatchWinCondition(splitBringBiggerSuitDataArr)
          self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的D牌组合 M16", m16)
          self.log("====带牌牌组合的YQ牌组合中，对手的D牌组合。假定是M16，M16数量是：" .. #m16)
          if 0 < #m16 then
            self.log("====【优先出的牌组合列表】=M16牌组合")
            self:setFirstSuitDataArr(m16)
            self:addResult("MF")
            goto lbl_355
          end
          self:addResult("ME")
        end
        local friendBestBiggerSuitDataArr = friendData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("队友最优分组的YQ牌组合", friendBestBiggerSuitDataArr)
        self.log("===队友最优分组的YQ牌组合数量是：" .. #friendBestBiggerSuitDataArr)
        local m24 = enemyData:ai_filterMismatchWinCondition(friendBestBiggerSuitDataArr)
        self:addParamsWithKey("队友最优分组合中，对手的D牌组合 M24", m24)
        self.log("====队友最优分组合中，对手的D牌组合。假定是M24，M24数量是：" .. #m24)
        local firstSuitDataArr
        if 0 < #m24 then
          firstSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
          self:addParamsWithKey("任意YQ牌组合中，不拆炸弹的组合", firstSuitDataArr)
          self.log("===任意YQ牌组合中，不拆炸弹的组合数量是：" .. #firstSuitDataArr)
          self:addResult("MH")
        else
          firstSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("任意YQ牌组合", firstSuitDataArr)
          self.log("===任意YQ牌组合数量是：" .. #firstSuitDataArr)
          self:addResult("M4")
        end
        local m2 = enemyData:ai_filterMismatchWinCondition(firstSuitDataArr)
        self:addParamsWithKey("【优先出的牌组合列表】中，对手的D牌组合 M2", m2)
        self.log("===【优先出的牌组合列表】中，对手的D牌组合。假定是M2，M2数量是：" .. #m2)
        if 0 < #m2 then
          if not AiUtils:isAllBomb(m2) then
            self.log("====M2中，不全是炸弹。【优先出的牌组合列表】=M2牌组合")
            self:setFirstSuitDataArr(m2)
            self:addResult("M41")
          else
            self.log("====M2中，全是炸弹")
            local m3 = data:ai_farmerRight_still_filterFriendSmallerMaxAndFriendNotLoseSuitDataArr(m2)
            self:addParamsWithKey("M2中，某个牌组合不计它后，剩余的牌 能把出牌权交给队友，且队友不是必败 M3", m3)
            self.log("====M2中，某个牌组合不计它后，剩余的牌 能把出牌权交给队友，且队友不是必败。假定是M3，M3数量是：" .. #m3)
            if 0 < #m3 then
              self.log("=====【优先出的牌组合列表】=M3牌组合")
              self:setFirstSuitDataArr(m3)
              self:addResult("M42")
            else
              self:addResult("M43")
              do return self:getAttackStatusPreventEnemyActionSuitData() end
              local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
              self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
              if enemyEnableWarningEnd then
                local m20 = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
                self:addParamsWithKey("最优分组的非炸弹的YQ牌组合 M20", m20)
                self.log("最优分组的非炸弹的YQ牌组合，假定是M20，M20数量是：" .. #m20)
                if 0 < #m20 then
                  do
                    self.log("======【优先出的牌组合列表】=M20牌组合中最大的牌组合")
                    local m20BiggerSuitData = AiUtils:getMaxSuitDataWithArr(m20)
                    self:setFirstSuitDataArr({m20BiggerSuitData})
                    self:addResult("M441")
                  end
                else
                  local m21 = AiUtils:filterNotBomb(splitBringBiggerSuitDataArr)
                  self:addParamsWithKey("带牌组合的非炸弹的YQ牌组合 M21", m21)
                  self.log("带牌组合的非炸弹的YQ牌组合，假定是M21，M21数量是：" .. #m21)
                  if 0 < #m21 then
                    do
                      self.log("======【优先出的牌组合列表】=M21牌组合中最大的牌组合")
                      local m21BiggerSuitData = AiUtils:getMaxSuitDataWithArr(m21)
                      self:setFirstSuitDataArr({m21BiggerSuitData})
                      self:addResult("M442")
                    end
                  else
                    self:addResult("M443")
                    return nil
                  end
                end
              else
                local m22 = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                self:addParamsWithKey("最优分组的非大牌的YQ牌组合 M22", m22)
                self.log("最优分组的非炸弹的YQ牌组合，假定是M22，M22数量是：" .. #m22)
                if 0 < #m22 then
                  self.log("======【优先出的牌组合列表】=M22牌组合")
                  self:setFirstSuitDataArr(m22)
                  self:addResult("M444")
                else
                  local m23 = AiUtils:filterNotMaxMaxSuitDataArr(splitBringBiggerSuitDataArr)
                  self:addParamsWithKey("带牌组合的非大牌的YQ牌组合 M23", m23)
                  self.log("带牌组合的非大牌的YQ牌组合，假定是M23，M23数量是：" .. #m23)
                  if 0 < #m23 then
                    self.log("======【优先出的牌组合列表】=M23牌组合")
                    self:setFirstSuitDataArr(m23)
                    self:addResult("M445")
                  else
                    self:addResult("M446")
                    return nil
                  end
                end
              end
            end
          end
        end
      end
  end
  ::lbl_355::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民跟牌 · 获取防守姿态常规出牌动作牌型data（下家农民跟牌-防守姿态-常规跟牌）
function AiBestFarmerRightFollowData:getPreventStatusNormalActionSuitData()
  self.log("===下家农民跟牌-防守姿态-常规跟牌")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local friendBestBiggerSuitDataArr = friendData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("队友最优分组的YQ牌组合", friendBestBiggerSuitDataArr)
    self.log("===队友最优分组的YQ牌组合数量是：" .. #friendBestBiggerSuitDataArr)
    if 0 < #friendBestBiggerSuitDataArr then
      local m4 = AiUtils:filterLiuSuitDataArr(friendBestBiggerSuitDataArr)
      self:addParamsWithKey("队友最优分组的YQ牌组合中，L牌组合 M4", m4)
      self.log("====队友最优分组的YQ牌组合中，L牌组合。假定是M4，M4数量是：" .. #m4)
      if 0 < #m4 then
        local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
        self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
        local m5 = friendData:ai_liu_filterSmallerLmaxSuitDataArr(bestBiggerSuitDataArr)
        self:addParamsWithKey("最优分组的YQ牌组合中，比M4中最大的牌组合更小的牌组合 M5", m5)
        self.log("=====最优分组的YQ牌组合中，比M4中最大的牌组合更小的牌组合。假定是M5，M5数量是：" .. #m5)
        if 0 < #m5 then
          self.log("======【优先出的牌组合列表】=M5牌组合")
          self:setFirstSuitDataArr(m5)
          self:addResult("M5")
        else
          local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
          local m17 = friendData:ai_liu_filterSmallerLmaxSuitDataArr(splitBringBiggerSuitDataArr)
          self:addParamsWithKey("带牌牌组合的YQ牌组合中，比M4中最大的牌组合更小的牌组合 M17", m17)
          self.log("=====带牌牌组合的YQ牌组合中，比M4中最大的牌组合更小的牌组合。假定是M17，M17数量是：" .. #m17)
          if 0 < #m17 then
            self.log("======【优先出的牌组合列表】=M17牌组合")
            self:setFirstSuitDataArr(m17)
            self:addResult("MI")
            goto lbl_589
          else
            self.log("======不能顺牌，Pass")
            self:addResult("M6")
            return nil
          end
          local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
          self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
          local bestNotBomb = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
          self:addParamsWithKey("最优分组的非炸弹的YQ牌组合", bestNotBomb)
          self.log("=====最优分组的YQ牌组合中，非炸弹的牌组合数量是：" .. #bestNotBomb)
          local friendMustEndKeyMap = friendData:ai_bestFenzu_getMustEndSuitKeyMap()
          self:addParamsWithKey("队友压制强收官牌型", friendMustEndKeyMap)
          local lastSuitDataKeyMap = AiUtils:suitDataArrToSuitDataArrDict({lastSuitData})
          self:addParamsWithKey("当前跟牌牌型", lastSuitDataKeyMap)
          local samKeyMap = AiUtils:getSameKeyMap(friendMustEndKeyMap, lastSuitDataKeyMap)
          if 0 < table.nums(samKeyMap) then
            self.log("====当前跟牌的牌型是否是队友压制强收官牌型：true")
            local friendMustEndSuitDataArr = friendData:ai_bestFenzu_getMaxSuitDataArr()
            friendMustEndSuitDataArr = AiUtils:filterSuitDataArrWithKeyMap(friendMustEndSuitDataArr, samKeyMap)
            self:addParamsWithKey("当前跟牌的牌型中，队友压制强收官牌型的所有牌", friendMustEndSuitDataArr)
            local friendMustEndMinSuitData = AiUtils:getMinSuitDataWithArr(friendMustEndSuitDataArr)
            local bestLiuSuitDataArr = AiUtils:filterLiuSuitDataArr(bestNotBomb)
            if 0 < #bestLiuSuitDataArr then
              local m15 = AiUtils:filterAllSmallerSuitDataArr({friendMustEndMinSuitData}, bestLiuSuitDataArr)
              self:addParamsWithKey("最优分组的YQ牌中，比队友“当前跟牌牌型的所有牌”更小的L牌牌组合。M15", m15)
              self.log("最优分组的YQ牌中，比队友“当前跟牌牌型的所有牌”更小的L牌牌组合。假定是M15，M15的数量是：" .. #m15)
              if 0 < #m15 then
                self.log("======【优先出的牌组合列表】=M15牌组合")
                self:setFirstSuitDataArr(m15)
                self:addResult("MD1")
            end
            else
              local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
              self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
              local splitBringLiuSuitDataArr = AiUtils:filterLiuSuitDataArr(splitBringBiggerSuitDataArr)
              if 0 < #splitBringLiuSuitDataArr then
                local m18 = AiUtils:filterAllSmallerSuitDataArr({friendMustEndMinSuitData}, splitBringLiuSuitDataArr)
                self:addParamsWithKey("带牌组合的YQ牌中，比队友“当前跟牌牌型的所有牌”更小的L牌牌组合。M18", m18)
                self.log("带牌组合的YQ牌中，比队友“当前跟牌牌型的所有牌”更小的L牌牌组合。假定是M18，M18的数量是：" .. #m18)
                if 0 < #m18 then
                  self.log("======【优先出的牌组合列表】=M18牌组合")
                  self:setFirstSuitDataArr(m18)
                  self:addResult("MD3")
              end
              else
                self:addResult("MD2")
                goto lbl_589
                else
                  self.log("====当前跟牌的牌型是否是队友压制强收官牌型：false")
                end
                local allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
                self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
                local m6 = AiUtils:filterNotBombMaxSuitDataArr(allBiggerSuitDataArr)
                self:addParamsWithKey("任意YQ牌组合中(不拆炸弹)，非炸弹最大牌（抢权最大牌、压制最大牌） M6", m6)
                local m7 = data:ai_farmerRight_still_filterHasFriendLmaxSuitDataArr(m6)
                self:addParamsWithKey("M6中，某个牌组合不计它后，剩余的牌 能帮队友溜牌 M7", m7)
                self.log("===M6中，某个牌组合不计它后，剩余的牌 能帮队友溜牌。假定是M7，M7数量是：" .. #m7)
                if 0 < #m7 then
                  self:setFirstSuitDataArr(m7)
                  self:addResult("M7")
                else
                  local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestNotBomb)
                  local m8 = AiUtils:filterLiuSuitDataArr(notMaxSuitDataArr)
                  self:addParamsWithKey("最优分组非大牌的YQ牌组合中，L牌组合 M8", m8)
                  self.log("====最优分组非大牌的YQ牌组合中，L牌组合。假定是M8，M8数量是：" .. #m8)
                  if 0 < #m8 then
                    self.log("=====【优先出的牌组合列表】=M8牌组合")
                    self:setFirstSuitDataArr(m8)
                    self:addResult("M8")
                  else
                    local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
                    self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
                    local splitBringNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(splitBringBiggerSuitDataArr)
                    local m19 = AiUtils:filterLiuSuitDataArr(splitBringNotMaxSuitDataArr)
                    self:addParamsWithKey("带牌牌组合非大牌的YQ牌组合中，L牌组合 M19", m19)
                    self.log("====带牌牌组合非大牌的YQ牌组合中，L牌组合。假定是M19，M19数量是：" .. #m19)
                    if 0 < #m19 then
                      self.log("=====【优先出的牌组合列表】=M19牌组合")
                      self:setFirstSuitDataArr(m19)
                      self:addResult("MJ")
                      goto lbl_589
                    else
                      self.log("=====自己不强跟，Pass")
                      self:addResult("M9")
                      return nil
                    end
                    local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
                    self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
                    local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
                    self:addParamsWithKey("对手最优分组的YQ牌组合", enemyBiggerSuitDataArr)
                    local enemyLiuBiggerSuitDataArr = AiUtils:filterLiuSuitDataArr(enemyBiggerSuitDataArr)
                    self:addParamsWithKey("对手最优分组的YQ牌组合中，L牌", enemyLiuBiggerSuitDataArr)
                    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
                    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
                    local liuSuitDataArr = AiUtils:filterLiuSuitDataArr(allBiggerSuitDataArr)
                    self:addParamsWithKey("任意YQ牌组合中，L牌组合", liuSuitDataArr)
                    local x = AiUtils:getMaxYaSuitData(enemyLiuBiggerSuitDataArr, liuSuitDataArr)
                    self.log("===对手能被自己【任意YQ牌组合中，L牌组合】压住的L牌组合中的最大牌。假定是X，X是：" .. (x and x:toString() or "nil"))
                    if x then
                      self:addParamsWithKey("对手能被自己【任意YQ牌组合中，L牌组合】压住的L牌组合中的最大牌 X", {x})
                      local tmp = {}
                      if 0 < #bestBiggerSuitDataArr then
                        table.insertto(tmp, bestBiggerSuitDataArr)
                      end
                      local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
                      self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
                      if 0 < #splitBringBiggerSuitDataArr then
                        table.insertto(tmp, splitBringBiggerSuitDataArr)
                      end
                      if 0 < #tmp then
                        tmp = AiUtils:filterLiuSuitDataArr(tmp)
                      end
                      self:addParamsWithKey("最优分组和带牌牌组合的YQ牌组合，L牌组合", tmp)
                      local m13 = AiUtils:filterNotSmallerSuitDataArr(tmp, x)
                      self:addParamsWithKey("最优分组和带牌牌组合中，非最大牌的L牌组合中，不比X小的牌组合 M13", m13)
                      self.log("===最优分组和带牌牌组合中，非最大牌的L牌组合中，不比X小的牌组合。假定是M13，M13数量是：" .. #m13)
                      if 0 < #m13 then
                        self.log("====【优先出的牌组合列表】=M13牌组合")
                        self:setFirstSuitDataArr(m13)
                        self:addResult("MC")
                    end
                    else
                      local allBiggerNotDisBombSuitDataArr = AiUtils:filterNotDisBombSuitDataArr(allBiggerSuitDataArr, data:getAllBomb(), data:getLazi())
                      self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerNotDisBombSuitDataArr)
                      local m9 = AiUtils:filterNotBombMaxSuitDataArr(allBiggerNotDisBombSuitDataArr)
                      self:addParamsWithKey("任意YQ牌组合中(不拆炸弹)，非炸弹最大牌（抢权最大牌、压制最大牌） M9", m9)
                      local m12 = data:ai_farmerRight_still_filterFriendSmallerMaxAndFriendNotLoseSuitDataArr(m9, true)
                      self:addParamsWithKey("M9中，某个牌组合不计它后，剩余的牌 能把出牌权交给队友，且队友不是必败 M12", m12)
                      self.log("===M9中，某个牌组合不计它后，剩余的牌 能把出牌权交给队友，且队友不是必败。假定是M12，M12数量是：" .. #m12)
                      if 0 < #m12 then
                        self.log("====【优先出的牌组合列表】=M12牌组合")
                        self:setFirstSuitDataArr(m12)
                        self:addResult("MB")
                      else
                        local m10 = data:ai_farmerRight_still_filterHasFriendLmaxSuitDataArr(m9)
                        self:addParamsWithKey("M9中，某个牌组合不计它后，剩余的牌 能帮队友溜牌 M10", m10)
                        self.log("===M9中，某个牌组合不计它后，剩余的牌 能帮队友溜牌。假定是M10，M10数量是：" .. #m10)
                        if 0 < #m10 then
                          self.log("====【优先出的牌组合列表】=M10牌组合")
                          self:setFirstSuitDataArr(m10)
                          self:addResult("MA")
                        else
                          local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                          self.log("=====【优先出的牌组合列表】=最优分组的非大牌的YQ牌组合")
                          self:setFirstSuitDataArr(notMaxSuitDataArr)
                          self:addResult("MG")
                        end
                      end
                    end
                  end
                end
              end
            end
        end
      end
    end
  end
  ::lbl_589::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民跟牌 · 进攻姿态出牌（下家农民跟牌-进攻姿态）
function AiBestFarmerRightFollowData:getAttackStatusActionSuitData()
  self.log("==下家农民跟牌-进攻姿态")
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  local needPrevent = false
  if self:landlordEnableEnd() then
    self.log("===对手能收官")
    if enemyData:getUid() == uid then
      self.log("===上手牌是对手出的")
      needPrevent = true
      self:addResult("L01")
    else
      local friendSuitDataArr = friendData:ai_all_getSuitDataArr()
      self:addParamsWithKey("队友任意牌组合", friendSuitDataArr)
      local friendMisMatchWinCondition = enemyData:ai_filterMismatchWinCondition(friendSuitDataArr)
      self:addParamsWithKey("队友任意牌组合中，对手的D牌组合", friendMisMatchWinCondition)
      self.log("=====队友任意牌组合中，对手的D牌组合数量是：" .. #friendMisMatchWinCondition)
      if #friendMisMatchWinCondition == 0 then
        needPrevent = true
        self:addResult("L02")
      else
        needPrevent = false
        self:addResult("L03")
      end
    end
  else
    self.log("===对手不能收官")
    needPrevent = false
    self:addResult("L04")
  end
  if needPrevent then
    return self:getAttackStatusPreventEnemyActionSuitData()
  else
    return self:getAttackStatusNormalActionSuitData()
  end
end

-- 强AI·下家农民跟牌 · 获取进攻姿态防守对手出牌动作牌型data（下家农民跟牌-进攻姿态-防队手收官）
function AiBestFarmerRightFollowData:getAttackStatusPreventEnemyActionSuitData()
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
        self:addParamsWithKey("带牌牌组合的YQ牌组合中，对手的D牌组合 K11", k11)
        self.log("====带牌牌组合的YQ牌组合中，对手的D牌组合。假定是K11，K11数量是：" .. #k11)
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
                goto lbl_545
              end
              self:addResult("L3")
            end
            local allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
            self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
            local friendBiggerSuitDataArr = friendData:ai_all_filterBiggerSuitDataArr(lastSuitData)
            self:addParamsWithKey("队友任意YQ牌组合", friendBiggerSuitDataArr)
            local k5 = enemyData:ai_filterMismatchWinCondition(friendBiggerSuitDataArr)
            self:addParamsWithKey("队友任意YQ牌组合中，对手的D牌组合 K5", k5)
            self.log("====队友任意YQ牌组合中，对手的D牌组合。假定是K5，K5数量是：" .. #k5)
            if 0 < #k5 then
              if not AiUtils:isAllBomb(k5) then
                do
                  allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
                  self.log("=====队友任意YQ牌能防住对手，就不拆炸弹了")
                  local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                  self:addParamsWithKey("最优分组的非大牌的YQ牌组合", notMaxSuitDataArr)
                  self.log("=====队友的K5中，不全是炸弹。【优先出的牌组合列表】=最优分组的非大牌的YQ牌组合")
                  if #notMaxSuitDataArr == 0 and 0 < #allBiggerSuitDataArr then
                    local bestSuitDataArr = data:ai_getBestSuitDataArr()
                    if #bestSuitDataArr == 1 and (bestSuitDataArr[1]:getType() == SuitType.kThreeWithOneSingle or bestSuitDataArr[1]:getType() == SuitType.kThree) then
                      local k8 = AiUtils:filterAllSmallerSuitDataArr(k5, allBiggerSuitDataArr)
                      self:addParamsWithKey("=====队友任意YQ牌组合中有对手的D牌组合，且是自己D牌组合 K8", k8)
                      self.log("=====队友任意YQ牌组合中有对手的D牌组合，且是自己D牌组合。假定是K8，K8数量是：" .. #k8)
                      if 0 < #k8 then
                        self:setFirstSuitDataArr(k8)
                    end
                  end
                  else
                    self:setFirstSuitDataArr(notMaxSuitDataArr)
                    self:addResult("L31")
                  end
                end
              else
                self.log("=====队友的K5中，全是炸弹")
                local arr = friendData:ai_farmerLeft_still_filterNotLoseOrFriendSmallerMaxSuitDataArr(k5)
                self:addParamsWithKey("队友的K5中，某个牌组合不计它后，剩余的牌 符合下列任意条件 ...", arr)
                self.log("=====队友的K5中，某个牌组合不计它后，剩余的牌 符合下列任意条件：1、队友不是必败；2、队友用对手的D牌组合可以把出牌权交个自己，且自己不是必败。\n符合条件的数量：" .. #arr)
                if 0 < #arr then
                  do
                    local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                    self:addParamsWithKey("最优分组的非大牌的YQ牌组合", notMaxSuitDataArr)
                    self.log("======【优先出的牌组合列表】=最优分组的非大牌的YQ牌组合")
                    self:setFirstSuitDataArr(notMaxSuitDataArr)
                    self:addResult("L32")
                  end
                else
                  self:addResult("L33")
                  else
                    self:addResult("L34")
                  end
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
                        local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
                        self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
                        if not enemyEnableWarningEnd then
                          local K14 = AiUtils:filterNotMaxMaxSuitDataArr(bestBiggerSuitDataArr)
                          self:addParamsWithKey("最优分组的非大牌的YQ牌组合 K14", K14)
                          self.log("最优分组的非大牌的YQ牌组合，假定是K14，K14数量是：" .. #K14)
                          if 0 < #K14 then
                            self.log("======【优先出的牌组合列表】=K14牌组合")
                            self:setFirstSuitDataArr(K14)
                            self:addResult("L3414")
                          else
                            local splitBringBiggerSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
                            self:addParamsWithKey("带牌牌组合的YQ牌组合", splitBringBiggerSuitDataArr)
                            local k15 = AiUtils:filterNotMaxMaxSuitDataArr(splitBringBiggerSuitDataArr)
                            self:addParamsWithKey("带牌组合的非大牌的YQ牌组合 K15", k15)
                            self.log("带牌组合的非大牌的YQ牌组合，假定是K15，K15数量是：" .. #k15)
                            if 0 < #k15 then
                              self.log("======【优先出的牌组合列表】=K15牌组合")
                              self:setFirstSuitDataArr(k15)
                              self:addResult("L3415")
                            else
                              if friendData:getUid() == lastSuitData:getUid() then
                                local friendBiggerNotBombSuitDataArr = AiUtils:filterNotBomb(friendBiggerSuitDataArr)
                                self:addParamsWithKey("队友最优分组的非炸弹的YQ牌组合", friendBiggerNotBombSuitDataArr)
                                self.log("队友最优分组的非炸弹的YQ牌组合，数量是：" .. #friendBiggerNotBombSuitDataArr)
                                if 0 < #friendBiggerNotBombSuitDataArr then
                                  self.log("上手牌是队友出的，或者队友任意非炸弹YQ牌有跟得起的牌组合，则Pass")
                                  self:addResult("L3417")
                                  return nil
                                end
                              end
                              self:addResult("L3416")
                              self.log("上手牌不是队友出的，且队友任意非炸弹YQ牌没有跟得起的牌组合")
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
              end
          end
        end
      end
  end
  ::lbl_545::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民跟牌 · 进攻姿态：常规出牌（下家农民跟牌-进攻姿态-常规跟牌）
function AiBestFarmerRightFollowData:getAttackStatusNormalActionSuitData()
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
    local k14
    if firstSuitDataArr and 0 < #firstSuitDataArr then
      self:addParamsWithKey("最优分组/带牌组合的YQ牌组合", firstSuitDataArr)
      self.log("====最优分组/带牌组合的YQ牌组合，数量是：" .. #firstSuitDataArr)
      if AiUtils:isAllMaxSuitData(firstSuitDataArr) then
        self.log("====最优分组/带牌组合的YQ牌组合中，全是最大牌")
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
          goto lbl_243
        else
          self:addResult("L7")
        end
      else
        self.log("====最优分组/带牌的YQ牌组合中，不全是最大牌。【优先出的牌组合列表】=最优分组/带牌的YQ牌组合")
        self:setFirstSuitDataArr(firstSuitDataArr)
        self:addResult("L5")
        goto lbl_243
      end
    else
      self:addResult("L8")
    end
    local allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
    local diffBiggerSuitDataArr = AiUtils:filterBSuitDataArrFromASuitDataArr(allBiggerSuitDataArr, k14)
    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)中和k14不相同的牌组合", diffBiggerSuitDataArr)
    self.log("===任意YQ牌组合(不拆炸弹)中和k14不相同的牌组合数量是：" .. #diffBiggerSuitDataArr)
    if 0 < #diffBiggerSuitDataArr then
      local k9 = data:ai_still_filterNotMoreLunSuitDataArr(diffBiggerSuitDataArr)
      self:addParamsWithKey("任意YQ牌组合中(不拆炸弹)，某个牌组合不计它后，剩余的牌 轮次不会增加 K9", k9)
      self.log("===任意YQ牌组合中(不拆炸弹)，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是K9, K9数量是：" .. #k9)
      if 0 < #k9 then
        self.log("====【优先出的牌组合列表】=K9牌组合")
        self:setFirstSuitDataArr(k9)
        self:addResult("L81")
        goto lbl_243
      end
    else
      self.log("====任意YQ牌组合(不拆炸弹)中，没有跟k14不相同的牌组合")
    end
    self.log("====跟牌后，轮次会增加，Pass")
    self:addResult("L82")
    return nil
  end
  ::lbl_243::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民跟牌 · 获取extend赢牌/收官conditions（下家农民跟牌-收官扩展）
function AiBestFarmerRightFollowData:getExtendWinConditions()
  self.log("==下家农民跟牌-收官扩展")
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

-- 强AI·下家农民跟牌 · 获取地主lefttwoorone牌型data（下家农民跟牌-地主报牌）
function AiBestFarmerRightFollowData:getLandlordLeftTwoOrOneSuitData()
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

return AiBestFarmerRightFollowData
