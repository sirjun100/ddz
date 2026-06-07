-- 文件: actionBest/AiBestFarmerRightStartData.lua · 反编译 AI 模块（阅读用）

local AiBestFarmerRightStartData = class("AiBestFarmerRightStartData", AiFarmerRightStartData)

-- 强AI·下家农民首出 · 构造函数
function AiBestFarmerRightStartData:ctor(params)
  AiBestFarmerRightStartData.super.ctor(self, params)
end

-- 强AI·下家农民首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（下家农民出牌）
function AiBestFarmerRightStartData:getActionSuitData()
  self.log("=下家农民出牌")
  local data = self:getData()
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(nil, taskData)
  if self:enableEnd() then
    if self:isNeedHelpFriendEnd() then
      local ok, suitData = self:getHelpFriendEndActionSuitData()
      if ok then
        return suitData
      end
    end
    if self:checkLiuSuitIsAllSingle() then
      if self:enableSingleEnd() then
        return self:getSingleEndActionSuitData(), true
      end
    else
      return self:getEndActionSuitData(), true
    end
  elseif #data:getAllBomb() == 0 and self:farmerLeftEnableWarningEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  end
  if self:checkBestSuitIsTwo() then
    local ret = self:getExtendWinConditions()
    if ret ~= nil then
      return ret
    end
    ret = self:getLeftTwoSuitData()
    if ret ~= nil then
      return ret
    end
  end
  local status = self:getStatus()
  self.log("=下家农民的姿态: " .. status)
  if status == 0 then
    return self:getPreventStatusActionSuitData()
  else
    return self:getAttackStatusActionSuitData()
  end
end

-- 强AI·下家农民首出 · 计算攻守姿态（0 防守 / 1 进攻）
function AiBestFarmerRightStartData:getStatus()
  local data = self:getFarmerRightData()
  local friendData = self:getFarmerLeftData()
  local friendRobot = friendData:getRobot()
  local lun = data:ai_getBestFenzuData().lun_
  local friendLun = friendData:ai_getBestFenzuData().lun_
  local ret
  if friendRobot then
    if friendLun + 1 < lun - 1 then
      ret = 0
    else
      ret = 1
    end
  elseif lun > friendLun then
    ret = 0
  else
    ret = 1
  end
  return ret
end

-- 强AI·下家农民首出 · 收官出牌：一手出完或走赢牌路径（下家农民出牌-收官）
function AiBestFarmerRightStartData:getEndActionSuitData()
  self.log("==下家农民出牌-收官")
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
  local noTaskSuitDataArr = AiUtils:filterNotTaskSuitDataArr(winConditions, taskData)
  self:addParamsWithKey("非最后出牌任务的牌", noTaskSuitDataArr)
  local firstSuitDataArr
  if 0 < #noTaskSuitDataArr then
    if 1 <= #noTaskSuitDataArr and noTaskSuitDataArr[1]:getCardCount() == data:getCardCount() then
      self:addParamsWithKey("四带二收官组合", noTaskSuitDataArr)
      for _, suitData in ipairs(noTaskSuitDataArr) do
        local suitDataType = suitData:getType()
        if suitDataType == SuitType.kFourWithTwoPair or suitDataType == SuitType.kFourWithTwoSingle or suitDataType == SuitType.kFourStraight then
          local splitFourSuitDataArr = AiUtils:splitFourWithXSuit(suitData)
          self.log("===【优先出的牌组合列表】=用四带X收官，进收官扩展逻辑")
          local ret = self:getExtendWinConditionsBySuitDataArr(splitFourSuitDataArr)
          if ret then
            return ret
          end
        end
      end
    end
    self.log("==【优先出的牌组合列表】=非最后出牌任务的牌")
    firstSuitDataArr = noTaskSuitDataArr
  else
    self.log("==【优先出的牌组合列表】=收官的牌组合")
    firstSuitDataArr = winConditions
  end
  if self:getLandlordCardCount() <= 2 then
    local ret = AiUtils:filterEndSuitDataByEnemyLeftCardNum(firstSuitDataArr, self:getLandlordCardCount())
    if 0 < #ret then
      firstSuitDataArr = ret
      self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)", ret)
      self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) 数量是：" .. #ret)
    end
  end
  self:setFirstSuitDataArr(firstSuitDataArr)
  self:addResult("H1")
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民首出 · 协助队友收官的出牌（下家农民出牌-帮队友收官）
function AiBestFarmerRightStartData:getHelpFriendEndActionSuitData()
  self.log("===下家农民出牌-帮队友收官")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  do
    local discardMoreBomb = self:getDiscardMoreBomb()
    if discardMoreBomb then
      self.log("====【优先出的牌组合列表】=任意牌中，尽可能出的炸弹")
      self:setFirstSuitDataArr(discardMoreBomb)
      ok = true
      suitData = self:getBaseActionSuitData()
      self:addResult("J35")
    else
      local bestSuitDataArr = data:ai_getBestSuitDataArr()
      self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
      local bestNotBombSuitDataArr = AiUtils:filterNotBombAndFourWithTwoSuitDataArr(bestSuitDataArr)
      self:addParamsWithKey("最优分组除炸弹和四带二的牌组合", bestNotBombSuitDataArr)
      local e13 = friendData:ai_filterMatchWinCondition(bestNotBombSuitDataArr)
      self:addParamsWithKey("最优分组中，队友的d牌组合 E13", e13)
      self.log("===最优分组中，队友的d牌组合。假定是E13，E13数量是：" .. #e13)
      if 0 < #e13 then
        self.log("====【优先出的牌组合列表】=E13牌组合")
        self:setFirstSuitDataArr(e13)
        ok = true
        suitData = self:getBaseActionSuitData()
        self:addResult("J33")
      else
        local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
        self:addParamsWithKey("最优分组带牌牌组合", splitBringSuitDataArr)
        local e16 = friendData:ai_filterMatchWinCondition(splitBringSuitDataArr)
        self:addParamsWithKey("带牌牌组合中，队友的d牌组合 E16", e16)
        self.log("===带牌牌组合中，队友的d牌组合。假定是E16，E16数量是：" .. #e16)
        if 0 < #e16 then
          self.log("====【优先出的牌组合列表】=E16牌组合")
          self:setFirstSuitDataArr(e16)
          ok = true
          suitData = self:getBaseActionSuitData()
          self:addResult("J36")
        else
          local allSuitData = data:ai_all_getNotDisBombSuitDataArr()
          allSuitData = AiUtils:filterNotBomb(allSuitData)
          local e1 = friendData:ai_filterMatchWinCondition(allSuitData)
          self:addParamsWithKey("除炸弹外的任意牌中(不拆炸弹)，队友的d牌组合 E1", e1)
          self.log("===除炸弹外任意牌中(不拆炸弹)，队友的d牌组合。假定是E1，E1数量是：" .. #e1)
          if 0 < #e1 then
            self.log("====【优先出的牌组合列表】=E1牌组合")
            self:setFirstSuitDataArr(e1)
            ok = true
            suitData = self:getBaseActionSuitData()
            self:addResult("J31")
          else
            ok = false
            suitData = nil
            self:addResult("J32")
          end
        end
      end
    end
  end
  return ok, suitData
end

-- 强AI·下家农民首出 · 防守姿态出牌（下家农民出牌-防手姿态）
function AiBestFarmerRightStartData:getPreventStatusActionSuitData()
  self.log("==下家农民出牌-防手姿态")
  local data = self:getData()
  local friendEnableEnd = self:farmerLeftEnableEnd()
  local enemyEnableEnd = self:landlordEnableEnd()
  if friendEnableEnd and enemyEnableEnd then
    self.log("===队友、对手能收官")
    self:addResult("J2")
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    else
      return self:getPreventStatusPreventEnemyActionSuitData()
    end
  elseif friendEnableEnd then
    self.log("===队友能收官")
    self:addResult("J3")
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    else
      local bestSuitDataArr = data:ai_getBestSuitDataArr()
      self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
      self.log("====【优先出的牌组合列表】=最优分组的牌组合")
      self:setFirstSuitDataArr(bestSuitDataArr)
      return self:getAttackStatusNormalActionSuitData()
    end
  elseif enemyEnableEnd then
    self.log("===对手能收官")
    self:addResult("J4")
    return self:getPreventStatusPreventEnemyActionSuitData()
  else
    self.log("===都不能收官")
    self:addResult("J5")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("====【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    local ok, suitData = self:getPreventStatusNormalActionSuitData()
    if ok then
      return suitData
    else
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      self.log("====【优先出的牌组合列表】=带牌牌组合")
      self:setFirstSuitDataArr(splitBringSuitDataArr)
      local ok2, suitData2 = self:getPreventStatusNormalActionSuitData()
      if ok2 then
        return suitData2
      else
        local allSuitData = data:ai_all_getNotDisBombSuitDataArr()
        self:addParamsWithKey("任意牌组合(不拆炸弹)", allSuitData)
        self.log("====【优先出的牌组合列表】=任意牌组合(不拆炸弹)")
        self:setFirstSuitDataArr(allSuitData)
        local ok3, suitData3 = self:getPreventStatusNormalActionSuitData()
        if ok3 then
          return suitData3
        else
          self.log("====【优先出的牌组合列表】=最优分组的牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          return self:getAttackStatusNormalActionSuitData()
        end
      end
    end
  end
end

-- 强AI·下家农民首出 · 防守姿态：阻止对手收官的出牌（下家农民出牌-防守姿态-防队手收官）
function AiBestFarmerRightStartData:getPreventStatusPreventEnemyActionSuitData()
  self.log("===下家农民出牌-防守姿态-防队手收官")
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  local friendIsLose = friendData:ai_getIsLose()
  if friendIsLose then
    self:addResult("J431")
    return self:getAttackStatusPreventEnemyActionSuitData()
  else
    self:addResult("J432")
  end
  local friendBestSuitDataArr = friendData:ai_getBestSuitDataArr()
  self:addParamsWithKey("队友的最优分组", friendBestSuitDataArr)
  local friendMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(friendBestSuitDataArr)
  self:addParamsWithKey("队友的最优分组中，对手的D牌组合", friendMismatchWinConditionArr)
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("最优分组牌组合", bestSuitDataArr)
  local bestMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(bestSuitDataArr)
  self:addParamsWithKey("最优分组牌组合中，对手的D牌组合", bestMismatchWinConditionArr)
  local bestMatchWinConditionArr = enemyData:ai_filterMatchWinCondition(bestSuitDataArr)
  self:addParamsWithKey("最优分组牌组合中，对手的d牌组合", bestMatchWinConditionArr)
  local bestDd = AiUtils:filterAllSmallerSuitDataArr(friendMismatchWinConditionArr, bestMatchWinConditionArr)
  self:addParamsWithKey("比“队友的最优分组牌组合中，对手的D牌组合”小的“最优分组牌组合中，对手的d牌组合”", friendMismatchWinConditionArr)
  self.log("===最优分组牌组合中，对手的D牌组合数量：" .. #bestMismatchWinConditionArr .. "; 对手的d牌组合数量：" .. #bestMatchWinConditionArr .. "; Dd牌组合数量：" .. #bestDd)
  if not (0 < #bestMismatchWinConditionArr) and not (0 < #bestDd) then
    local friendSplitBringSuitDataArr = friendData:ai_bestFenzu_splitBringSuitDataArr()
    self:addParamsWithKey("队友的带牌牌组合", friendSplitBringSuitDataArr)
    local friendMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(friendSplitBringSuitDataArr)
    self:addParamsWithKey("队友的带牌牌组合中，对手的D牌组合", friendMismatchWinConditionArr)
    local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
    self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
    bestMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
    self:addParamsWithKey("带牌牌组合中，对手的D牌组合", bestMismatchWinConditionArr)
    local bestMatchWinConditionArr = enemyData:ai_filterMatchWinCondition(splitBringSuitDataArr)
    self:addParamsWithKey("带牌牌组合中，对手的d牌组合", bestMatchWinConditionArr)
    bestDd = AiUtils:filterAllSmallerSuitDataArr(friendMismatchWinConditionArr, bestMatchWinConditionArr)
    self:addParamsWithKey("比“队友的带牌牌组合中，对手的D牌组合”小的“带牌牌组合中，对手的d牌组合”", friendMismatchWinConditionArr)
    self.log("===带牌牌组合中，对手的D牌组合数量：" .. #bestMismatchWinConditionArr .. "; 对手的d牌组合数量：" .. #bestMatchWinConditionArr .. "; Dd牌组合数量：" .. #bestDd)
    if 0 < #bestMismatchWinConditionArr or 0 < #bestDd then
      self:addResult("J44")
    end
  else
    self:addResult("J42")
  end
  if 0 < #bestMismatchWinConditionArr or 0 < #bestDd then
    local e14 = {}
    table.insertto(e14, bestMismatchWinConditionArr)
    table.insertto(e14, bestDd)
    self:addParamsWithKey("E14牌组合", e14)
    self.log("=====【优先出的牌组合列表】=E14牌组合")
    self:setFirstSuitDataArr(e14)
  else
    local allSuitData = data:ai_all_getSuitDataArr()
    self:addParamsWithKey("任意牌组合", allSuitData)
    local mismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(allSuitData)
    self:addParamsWithKey("任意牌组合中，对手的D牌组合", mismatchWinConditionArr)
    local matchWinConditionArr = enemyData:ai_filterMatchWinCondition(allSuitData)
    self:addParamsWithKey("任意牌组合中，对手的d牌组合", matchWinConditionArr)
    local Dd = AiUtils:filterAllSmallerSuitDataArr(friendMismatchWinConditionArr, matchWinConditionArr)
    self:addParamsWithKey("比“队友的任意牌组合中，对手的D牌组合”小的“任意牌组合中(不拆炸弹)，对手的d牌组合”", friendMismatchWinConditionArr)
    self.log("===任意牌组合中(不拆炸弹)，对手的D牌组合数量：" .. #mismatchWinConditionArr .. "; 对手的d牌组合数量：" .. #matchWinConditionArr .. "; Dd牌组合数量：" .. #Dd)
    if 0 < #mismatchWinConditionArr or 0 < #Dd then
      local e2 = {}
      table.insertto(e2, mismatchWinConditionArr)
      table.insertto(e2, Dd)
      self:addParamsWithKey("E2牌组合", e2)
      self.log("=====【优先出的牌组合列表】=E2牌组合")
      self:setFirstSuitDataArr(e2)
      self:addResult("J43")
    else
      local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
      self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
      if enemyEnableWarningEnd then
        if not AiUtils:isAllMaxMaxSuitData(bestSuitDataArr) then
          self.log("====最优分组中，不全是大牌")
          local bestNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的牌组合", bestNotMaxSuitDataArr)
          local maxLevelSuitData = AiUtils:getMaxLevelSuitData(bestNotMaxSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的最大的牌组合", {maxLevelSuitData})
          self.log("=====【优先出的牌组合列表】=最优分组的非大牌的最大的牌组合")
          self:setFirstSuitDataArr({maxLevelSuitData})
          self:addResult("J402")
          return self:getBaseActionSuitData()
        else
          self.log("====最优分组中，全是大牌")
          self:addResult("J401")
        end
      else
        self:addResult("J41")
      end
      self.log("=====【优先出的牌组合列表】=最优分组牌组合")
      self:setFirstSuitDataArr(bestSuitDataArr)
      return self:getAttackStatusNormalActionSuitData()
    end
  end
  local ok, suitData = self:getPreventStatusNormalActionSuitData()
  if ok then
    return suitData
  else
    return self:getAttackStatusPreventEnemyActionSuitData()
  end
end

-- 强AI·下家农民首出 · 获取防守姿态常规出牌动作牌型data（下家农民出牌-防守姿态-常规出牌）
function AiBestFarmerRightStartData:getPreventStatusNormalActionSuitData()
  self.log("===下家农民出牌-防守姿态-常规出牌")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local e4 = friendData:ai_bestFenzu_filterAllSmallerFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，比“队友最优分组的首发最大牌”小的牌组合 E4", e4)
    self.log("====【优先出的牌组合列表】中，比“队友最优分组的首发最大牌”小的牌组合。假定是E4，E4数量是：" .. #e4)
    if 0 < #e4 then
      self.log("=====【优先出的牌组合列表】=E4牌组合")
      self:setFirstSuitDataArr(e4)
      self:addResult("J51")
    else
      local e9 = friendData:ai_liu_filterLiuKeyAndSmallerLmaxSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("优先出的牌组合列表】中，与“队友最优分组的L牌组合”同牌型的，队友的Lax牌的牌组合 E9", e9)
      self.log("====优先出的牌组合列表】中，与“队友最优分组的L牌组合”同牌型的，队友的Lax牌的牌组合。假定是E9，E9数量是：" .. #e9)
      if 0 < #e9 then
        do
          local e6 = friendData:ai_liu_filterMustLiuKeyAndSmallerLmaxSuitDataArr(e9)
          self:addParamsWithKey("E9中，与“队友最优分组的LB牌组合”同牌型的，队友的Lax牌的牌组合 E6", e6)
          self.log("====E9中，与“队友最优分组的LB牌组合”同牌型的，队友的Lax牌的牌组合。假定是E6，E6数量是：" .. #e6)
          if 0 < #e6 then
            self.log("======E9=E6")
            e9 = e6
            self:addResult("J52")
          else
            local e15 = friendData:ai_liu_filterMustLiuCKeyAndSmallerLmaxSuitDataArr(e9)
            self:addParamsWithKey("E9中，与“队友最优分组的LC牌组合”同牌型的，队友的Lax牌的牌组合 E15", e15)
            self.log("====E9中，与“队友最优分组的LB牌组合”同牌型的，队友的Lax牌的牌组合。假定是E15，E15数量是：" .. #e15)
            if 0 < #e15 then
              self.log("======E9=E15")
              e9 = e15
              self:addResult("J56")
            else
              self:addResult("J53")
            end
          end
          local e7 = data:ai_all_filterAllSmallerNotBombMaxSuitDataArr(e9)
          self:addParamsWithKey("E9中，同牌型有非炸弹最大牌（抢权最大牌、压制最大牌）的牌组合。假定是E7牌组合 E7", e7)
          self.log("=====E9中，同牌型有非炸弹最大牌（抢权最大牌、压制最大牌）的牌组合。假定是E7，E7数量是：" .. #e7)
          if 0 < #e7 then
            self.log("======【优先出的牌组合列表】=E7牌组合")
            self:setFirstSuitDataArr(e7)
            self:addResult("J531")
          else
            self.log("======【优先出的牌组合列表】=E9牌组合")
            self:setFirstSuitDataArr(e9)
            self:addResult("J532")
          end
        end
      else
        local e12 = friendData:ai_bestFenzu_filterAllSmallerMustEndMaxSuitDataArr(firstSuitDataArr)
        self:addParamsWithKey("任意牌中，比【“队友最优分组的压制强收官牌型”的最大牌】小的牌组合 E12", e12)
        self.log("====任意牌中，比【“队友最优分组的压制强收官牌型”的最大牌】小的牌组合。假定是E12，E12数量是：" .. #e12)
        if 0 < #e12 then
          self.log("=====【优先出的牌组合列表】=E12牌组合")
          self:setFirstSuitDataArr(e12)
          self:addResult("J54")
        else
          self:addResult("J55")
          return false, nil
        end
      end
    end
  end
  ok = true
  suitData = self:getBaseActionSuitData()
  return ok, suitData
end

-- 强AI·下家农民首出 · 进攻姿态出牌（下家农民出牌-进攻姿态）
function AiBestFarmerRightStartData:getAttackStatusActionSuitData()
  self.log("==下家农民出牌-进攻姿态")
  local data = self:getData()
  local friendEnableEnd = self:farmerLeftEnableEnd()
  local enemyEnableEnd = self:landlordEnableEnd()
  if friendEnableEnd and enemyEnableEnd then
    self.log("===队友、对手能收官")
    self:addResult("H2")
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    else
      return self:getAttackStatusPreventEnemyActionSuitData()
    end
  elseif friendEnableEnd then
    self.log("===队友能收官")
    self:addResult("H3")
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    else
      local bestSuitDataArr = data:ai_getBestSuitDataArr()
      self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
      self.log("====【优先出的牌组合列表】=最优分组的牌组合")
      self:setFirstSuitDataArr(bestSuitDataArr)
      return self:getAttackStatusNormalActionSuitData()
    end
  elseif enemyEnableEnd then
    self.log("===对手能收官")
    self:addResult("H4")
    return self:getAttackStatusPreventEnemyActionSuitData()
  else
    self.log("===都不能收官")
    self:addResult("H5")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("====【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    return self:getAttackStatusNormalActionSuitData()
  end
end

-- 强AI·下家农民首出 · 获取进攻姿态防守对手出牌动作牌型data（下家农民出牌-进攻姿态-防队手收官）
function AiBestFarmerRightStartData:getAttackStatusPreventEnemyActionSuitData()
  self.log("===下家农民出牌-进攻姿态-防队手收官")
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local friendBestSuitDataArr = friendData:ai_getBestSuitDataArr()
    self:addParamsWithKey("队友的最优分组", friendBestSuitDataArr)
    local friendMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(friendBestSuitDataArr)
    self:addParamsWithKey("队友的最优分组中，对手的D牌组合", friendMismatchWinConditionArr)
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组牌组合", bestSuitDataArr)
    local bestMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(bestSuitDataArr)
    self:addParamsWithKey("最优分组牌组合中，对手的D牌组合", bestMismatchWinConditionArr)
    local bestMatchWinConditionArr = enemyData:ai_filterMatchWinCondition(bestSuitDataArr)
    self:addParamsWithKey("最优分组牌组合中，对手的d牌组合", bestMatchWinConditionArr)
    local bestDd = AiUtils:filterAllSmallerSuitDataArr(friendMismatchWinConditionArr, bestMatchWinConditionArr)
    self:addParamsWithKey("比“队友的最优分组牌组合中，对手的D牌组合”小的“最优分组牌组合中，对手的d牌组合”", friendMismatchWinConditionArr)
    self.log("===最优分组牌组合中，对手的D牌组合数量：" .. #bestMismatchWinConditionArr .. "; 对手的d牌组合数量：" .. #bestMatchWinConditionArr .. "; Dd牌组合数量：" .. #bestDd)
    if not (0 < #bestMismatchWinConditionArr) and not (0 < #bestDd) then
      local friendSplitBringSuitDataArr = friendData:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("队友的带牌牌组合", friendSplitBringSuitDataArr)
      local friendMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(friendSplitBringSuitDataArr)
      self:addParamsWithKey("队友的带牌牌组合中，对手的D牌组合", friendMismatchWinConditionArr)
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      bestMismatchWinConditionArr = enemyData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
      self:addParamsWithKey("带牌牌组合中，对手的D牌组合", bestMismatchWinConditionArr)
      local bestMatchWinConditionArr = enemyData:ai_filterMatchWinCondition(splitBringSuitDataArr)
      self:addParamsWithKey("带牌牌组合中，对手的d牌组合", bestMatchWinConditionArr)
      bestDd = AiUtils:filterAllSmallerSuitDataArr(friendMismatchWinConditionArr, bestMatchWinConditionArr)
      self:addParamsWithKey("比“队友的带牌牌组合中，对手的D牌组合”小的“带牌牌组合中，对手的d牌组合”", friendMismatchWinConditionArr)
      self.log("===带牌牌组合中，对手的D牌组合数量：" .. #bestMismatchWinConditionArr .. "; 对手的d牌组合数量：" .. #bestMatchWinConditionArr .. "; Dd牌组合数量：" .. #bestDd)
      if 0 < #bestMismatchWinConditionArr or 0 < #bestDd then
        self:addResult("H402")
      end
    else
      self:addResult("H401")
    end
    if not (0 < #bestMismatchWinConditionArr) and not (0 < #bestDd) then
      local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
      self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
      if enemyEnableWarningEnd then
        if not AiUtils:isAllMaxMaxSuitData(bestSuitDataArr) then
          self.log("====最优分组中，不全是大牌")
          local bestNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的牌组合", bestNotMaxSuitDataArr)
          local maxLevelSuitData = AiUtils:getMaxLevelSuitData(bestNotMaxSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的最大的牌组合", {maxLevelSuitData})
          self.log("=====【优先出的牌组合列表】=最优分组的非大牌的最大的牌组合")
          self:setFirstSuitDataArr({maxLevelSuitData})
          self:addResult("H422")
          goto lbl_477
        else
          self.log("====最优分组中，全是大牌")
          self:addResult("H421")
        end
      else
        self:addResult("H41")
      end
      self.log("====【优先出的牌组合列表】=最优分组的牌组合")
      self:setFirstSuitDataArr(bestSuitDataArr)
      return self:getAttackStatusNormalActionSuitData()
    end
    local isLose = data:ai_getIsLose()
    self.log("====最优分组是否必败：" .. tostring(isLose))
    if isLose then
      local friendIsLose = friendData:ai_getIsLose()
      self.log("=====队友是否必败：" .. tostring(friendIsLose))
      if not friendIsLose then
        local c1 = {}
        table.insertto(c1, bestMismatchWinConditionArr)
        table.insertto(c1, bestDd)
        self:addParamsWithKey("C1牌组合", c1)
        self.log("=====【优先出的牌组合列表】=C1牌组合")
        self:setFirstSuitDataArr(c1)
        self:addResult("H45")
        local ok, suitData = self:getPreventStatusNormalActionSuitData()
        if ok then
          return suitData
        else
          self:addResult("H46")
        end
      else
        self:addResult("H47")
      end
      local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
      self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
      if enemyEnableWarningEnd then
        local c1 = {}
        table.insertto(c1, bestMismatchWinConditionArr)
        table.insertto(c1, bestDd)
        local c8 = AiUtils:filterFirstMaxSuitDataArr(c1)
        self:addParamsWithKey("C1中，首发最大牌组合 C8", c8)
        self.log("====【优先出的牌组合列表】中，首发最大牌组合。假定是C8，C8数量是：" .. #c8)
        if 0 < #c8 then
          self.log("=====【优先出的牌组合列表】=C8牌组合")
          self:setFirstSuitDataArr(c8)
          self:addResult("H430")
        else
          local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(c1)
          if 0 < #notMaxSuitDataArr then
            local c9 = AiUtils:filterNotSingleAndPairSuitDataArr(notMaxSuitDataArr)
            self:addParamsWithKey("C1中，非大牌非单张非对子 C9", c9)
            self.log("====【优先出的牌组合列表】中，C1中，非大牌非单张非对子的牌组合。假定是C9，C9数量是：" .. #c9)
            if 0 < #c9 then
              self.log("=====【优先出的牌组合列表】=C9牌组合")
              self:setFirstSuitDataArr(c9)
          end
          elseif not AiUtils:isAllMaxMaxSuitData(c1) then
            do
              self.log("====C1中，不全是大牌")
              self:addParamsWithKey("C1中，非大牌的牌组合", notMaxSuitDataArr)
              local maxLevelSuitData = AiUtils:getMaxLevelSuitData(notMaxSuitDataArr)
              self:addParamsWithKey("C1中，非大牌的最大的牌组合", {maxLevelSuitData})
              self.log("=====【优先出的牌组合列表】=C1中，非大牌的最大的牌组合")
              self:setFirstSuitDataArr({maxLevelSuitData})
              self:addResult("H431")
            end
          else
            if not AiUtils:isAllMaxMaxSuitData(bestSuitDataArr) then
              self.log("====最优分组中，不全是大牌")
              local bestNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestSuitDataArr)
              self:addParamsWithKey("最优分组的非大牌的牌组合", bestNotMaxSuitDataArr)
              local maxLevelSuitData = AiUtils:getMaxLevelSuitData(bestNotMaxSuitDataArr)
              self:addParamsWithKey("最优分组的非大牌的最大的牌组合", {maxLevelSuitData})
              self.log("=====【优先出的牌组合列表】=最优分组的非大牌的最大的牌组合")
              self:setFirstSuitDataArr({maxLevelSuitData})
              self:addResult("H432")
              goto lbl_477
            else
              self.log("=====【优先出的牌组合列表】=最优分组的牌组合")
              self:setFirstSuitDataArr(bestSuitDataArr)
              self:addResult("H433")
              return self:getAttackStatusNormalActionSuitData()
            end
            else
              self:addResult("H435")
            end
            self.log("====【优先出的牌组合列表】=最优分组的牌组合")
            self:setFirstSuitDataArr(bestSuitDataArr)
            self:addResult("H42")
            return self:getAttackStatusNormalActionSuitData()
          end
        end
    else
      local c1 = {}
      table.insertto(c1, bestMismatchWinConditionArr)
      table.insertto(c1, bestDd)
      self:addParamsWithKey("C1牌组合", c1)
      self.log("=====【优先出的牌组合列表】=C1牌组合")
      self:setFirstSuitDataArr(c1)
      self:addResult("H44")
      return self:getAttackStatusNormalActionSuitData()
    end
  end
  ::lbl_477::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民首出 · 进攻姿态：常规出牌（下家农民出牌-进攻姿态-常规出牌）
function AiBestFarmerRightStartData:getAttackStatusNormalActionSuitData()
  self.log("===下家农民出牌-进攻姿态-常规出牌")
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local c2 = AiUtils:filterFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，首发最大牌组合 C2", c2)
    self.log("====【优先出的牌组合列表】中，首发最大牌组合。假定是C2，C2数量是：" .. #c2)
    if 0 < #c2 then
      self.log("=====【优先出的牌组合列表】=C2牌组合")
      self:setFirstSuitDataArr(c2)
      self:addResult("H51")
    else
      local c3 = AiUtils:filterLiuSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，L牌组合 C3", c3)
      self.log("=====【优先出的牌组合列表】中，L牌组合。假定是C3，C3数量是：" .. #c3)
      if #c3 == 0 then
        self:addResult("H54")
      else
        local tc3 = AiUtils:getKeyMapWithSuitDataArr(c3)
        self:addParamsWithKey("C3牌组合的牌型", tc3)
        self.log("====C3牌组合的牌型。假定是tc3牌型，tc3数量是：" .. #table.keys(tc3))
        local tc4 = data:ai_liu_getMustLiuKeyMap()
        tc4 = AiUtils:getSameKeyMap(tc4, tc3)
        self:addParamsWithKey("【优先出的牌组合列表】中，LB牌组合的牌型 tc4", tc4)
        self.log("====【优先出的牌组合列表】中，LB牌组合的牌型。假定是tc4牌型，tc4数量是：" .. #table.keys(tc4))
        local firstKeyMap
        if next(tc4) then
          self.log("=====【优先出的牌型】=tc4")
          firstKeyMap = tc4
          self:addResult("H52")
        end
        if firstKeyMap == nil then
          local tc10 = data:ai_liu_getMustLiuCKeyMap()
          tc10 = AiUtils:getSameKeyMap(tc10, tc3)
          self:addParamsWithKey("【优先出的牌组合列表】中，LC牌组合的牌型 tc10", tc10)
          self.log("====【优先出的牌组合列表】中，LC牌组合的牌型。假定是tc10牌型，tc10数量是：" .. #table.keys(tc10))
          if next(tc10) then
            self.log("=====【优先出的牌型】=tc10")
            firstKeyMap = tc10
            self:addResult("H55")
          else
            self.log("=====【优先出的牌型】=tc3")
            firstKeyMap = tc3
            self:addResult("H53")
          end
        end
        local enemyLiuKeyMap = enemyData:ai_liu_getLiuKeyMap()
        local tc5 = AiUtils:getNotSameKeyMap(firstKeyMap, enemyLiuKeyMap)
        self:addParamsWithKey("【优先出的牌型】中，对手没有L牌组合的牌型 tc5", tc5)
        self.log("=====【优先出的牌型】中，对手没有L牌组合的牌型。假定是tc5牌型，tc5数量是：" .. #table.keys(tc5))
        if next(tc5) then
          do
            local c5 = AiUtils:filterSuitDataArrWithKeyMap(c3, tc5)
            self:addParamsWithKey("tc5牌型的C3牌组合", c5)
            self.log("======【优先出的牌组合列表】=tc5牌型的C3牌组合")
            self:setFirstSuitDataArr(c5)
            self:addResult("H531")
          end
        else
          local friendAllSuitData = friendData:ai_all_getSuitDataArr()
          self:addParamsWithKey("队友的任意牌组合", friendAllSuitData)
          local friendDP = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(friendAllSuitData)
          self:addParamsWithKey("队友的任意牌组合中，对手的DP牌组合", friendDP)
          local friendDPKeyMap = AiUtils:getKeyMapWithSuitDataArr(friendDP)
          self:addParamsWithKey("队友的任意牌组合中，对手的DP牌组合 的牌型", friendDPKeyMap)
          local tc6 = AiUtils:getSameKeyMap(firstKeyMap, friendDPKeyMap)
          self:addParamsWithKey("【优先出的牌型】中，队友有DP牌组合的牌型 tc6", tc6)
          self.log("=====【优先出的牌型】中，队友有DP牌组合的牌型。假定是tc6牌型，tc6数量是：" .. #table.keys(tc6))
          if next(tc6) then
            do
              local c6 = AiUtils:filterSuitDataArrWithKeyMap(c3, tc6)
              self:addParamsWithKey("tc6牌型的C3牌组合", c6)
              self.log("======【优先出的牌组合列表】=tc6牌型的C3牌组合")
              self:setFirstSuitDataArr(c6)
              self:addResult("H532")
            end
          else
            local friendMaxSuitKeyMap = friendData:ai_all_getNotBombMaxSuitKeyMap()
            local tc7 = AiUtils:getSameKeyMap(firstKeyMap, friendMaxSuitKeyMap)
            self:addParamsWithKey("【优先出的牌型】中，队友有非炸弹最大牌（抢权最大牌、压制最大牌）的牌型 tc7", tc7)
            self.log("=====【优先出的牌型】中，队友有非炸弹最大牌（抢权最大牌、压制最大牌）的牌型。假定是tc7牌型，tc7数量是：" .. #table.keys(tc7))
            if next(tc7) then
              do
                local c7 = AiUtils:filterSuitDataArrWithKeyMap(c3, tc7)
                self:addParamsWithKey("tc7牌型的C3牌组合", c7)
                self.log("======【优先出的牌组合列表】=tc7牌型的C3牌组合")
                self:setFirstSuitDataArr(c7)
                self:addResult("H533")
              end
            else
              local firstLiuSuitDataArr = AiUtils:filterSuitDataArrWithKeyMap(c3, firstKeyMap)
              self:addParamsWithKey("【优先出的牌型】的C3牌组合", firstLiuSuitDataArr)
              self.log("======【优先出的牌组合列表】=【优先出的牌型】的C3牌组合")
              self:setFirstSuitDataArr(firstLiuSuitDataArr)
              self:addResult("H534")
              goto lbl_322
            end
          end
        end
      end
    end
  end
  ::lbl_322::
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民首出 · 获取extend赢牌/收官conditions（下家农民出牌-收官扩展）
function AiBestFarmerRightStartData:getExtendWinConditions()
  self.log("==下家农民出牌-收官扩展")
  local data = self:getData()
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("深度最优分组的牌组合", bestSuitDataArr)
  local ret = data:ai_farmer_still_filterLandlordLostSuitDataArr(bestSuitDataArr)
  if 0 < #ret then
    self:addParamsWithKey("出了这一手牌手，对手必败，那么也算我能收官", ret)
    self.log("=====出了这一手牌手，对手必败的组合数量是：" .. #ret)
    self:setFirstSuitDataArr(ret)
    return self:getBaseActionSuitData()
  end
  self.log("=====出了这一手牌手，对手必败的组合数量是：0")
  return nil
end

-- 强AI·下家农民首出 · 获取extend赢牌/收官conditionsby牌型dataarr（下家农民出牌-收官扩展(四带X)）
function AiBestFarmerRightStartData:getExtendWinConditionsBySuitDataArr(suitDataArr)
  self.log("==下家农民出牌-收官扩展(四带X)")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local cardTypeListdata = data
  local biggerSuitDataArr = AiUtils:filterBiggerSuitDataArr(suitDataArr, lastSuitData)
  self:addParamsWithKey("四带X中YQ牌组合", biggerSuitDataArr)
  local outSuitDataArr
  if 3 <= #biggerSuitDataArr then
    local enemyData = self:getLandlordData()
    local flag = false
    for i, suitData in ipairs(biggerSuitDataArr) do
      if suitData:getType() ~= SuitType.kBomb then
        local winBombCount, winNotBombCount = AiUtils:getWinSuitDataNum(suitData, enemyData:getAllSuitData())
        if winBombCount <= 1 and winNotBombCount == 0 then
          cardTypeListdata = data:clone()
          cardTypeListdata.enemy1 = data.enemy1
          cardTypeListdata.friend = data.friend
          cardTypeListdata:removeCardTypeWithSuitData(suitData)
          outSuitDataArr = {suitData}
          table.remove(biggerSuitDataArr, i)
          flag = true
          break
        end
      end
    end
    if flag then
      self.log("=====四带X组合拆成3手牌，除开炸弹，对手要不起的大牌数量：1")
    else
      self.log("=====四带X组合拆成3手牌，除开炸弹，对手要不起的大牌数量：0")
      return nil
    end
  end
  local ret = cardTypeListdata:ai_farmer_still_filterLandlordLostSuitDataArr(biggerSuitDataArr)
  if 0 < #ret then
    if outSuitDataArr then
      self:addParamsWithKey("出了这一手牌手，对手必败，那么也算我能收官", outSuitDataArr)
      self.log("=====出了这一手牌手，对手必败的组合数量是：" .. #ret)
      self:setFirstSuitDataArr(outSuitDataArr)
    else
      self:addParamsWithKey("出了这一手牌手，对手必败，那么也算我能收官", ret)
      self.log("=====出了这一手牌手，对手必败的组合数量是：" .. #ret)
      self:setFirstSuitDataArr(ret)
    end
    return self:getBaseActionSuitData()
  end
  self.log("=====出了这一手牌手，对手必败的组合数量是：0")
  return nil
end

-- 强AI·下家农民首出 · 检查liu牌型判断是否all单张（下家农民-判断是否有溜牌且全是单张）
function AiBestFarmerRightStartData:checkLiuSuitIsAllSingle()
  self.log("==下家农民-判断是否有溜牌且全是单张")
  local data = self:getData()
  local enemyData = self:getLandlordData()
  local winConditions = data:ai_getWinConditions()
  self:addParamsWithKey("所有收官牌组合", winConditions)
  local is42SuitDataArr = AiUtils:getIs42SuitDataArr(winConditions)
  if 0 < #is42SuitDataArr then
    self.log("===有四带二的组合，不用判断单张溜牌")
    return false
  end
  local liuSuitDataArr = data:ai_liu_getLiuSuitDataArr()
  if liuSuitDataArr == nil or #liuSuitDataArr == 0 then
    self.log("===没有要溜的牌")
    return false
  end
  self:addParamsWithKey("要溜的牌", liuSuitDataArr)
  for _, suitData in ipairs(liuSuitDataArr) do
    if suitData:getType() ~= SuitType.kSingle then
      self.log("===要溜的牌不全是单张")
      return false
    end
  end
  local enemyBestFenzu = enemyData:ai_getBestFenzu()
  local enemyBestFenzuInfo = enemyBestFenzu:getBestFenzuInfo()
  local suitDataArr = enemyBestFenzuInfo.suitDataArr
  self:addParamsWithKey("对手最优分组", suitDataArr)
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() ~= SuitType.kSingle then
      self.log("===对手最优分组不全是单张")
      return false
    end
  end
  if #liuSuitDataArr <= #suitDataArr then
    self.log("===溜牌数量比对手单张数量少，能赢")
    return false
  end
  return true
end

-- 强AI·下家农民首出 · 是否可单张收官（下家农民出牌-判断是否能单张收官）
function AiBestFarmerRightStartData:enableSingleEnd()
  self.log("==下家农民出牌-判断是否能单张收官")
  local data = self:getData()
  local enemyData = self:getLandlordData()
  local liuSuitDataArr = data:ai_liu_getLiuSuitDataArr()
  local enemyBestFenzu = enemyData:ai_getBestFenzu()
  local enemyBestFenzuInfo = enemyBestFenzu:getBestFenzuInfo()
  local suitDataArr = enemyBestFenzuInfo.suitDataArr
  local enemyMinSuitData
  for _, enemySuitData in ipairs(suitDataArr) do
    if enemyMinSuitData == nil then
      enemyMinSuitData = enemySuitData
    elseif enemySuitData:getLevel() < enemyMinSuitData:getLevel() then
      enemyMinSuitData = enemySuitData
    end
  end
  local enemyBestFenzuWinCount = 0
  for _, suitData in ipairs(liuSuitDataArr) do
    if enemyMinSuitData:getLevel() > suitData:getLevel() then
      enemyBestFenzuWinCount = enemyBestFenzuWinCount + 1
    end
  end
  if enemyBestFenzuWinCount >= #suitDataArr then
    self.log("===比对手最小的牌小的溜牌数量超过对手手牌数，则不能收官")
    return false
  end
  return true
end

-- 强AI·下家农民首出 · 获取单张收官出牌动作牌型data（下家农民出牌-收官-单张出牌）
function AiBestFarmerRightStartData:getSingleEndActionSuitData()
  self.log("==下家农民出牌-收官-单张出牌")
  local data = self:getData()
  local liuSuitDataArr = data:ai_liu_getLiuSuitDataArr()
  if liuSuitDataArr[2] then
    self:setFirstSuitDataArr({
      liuSuitDataArr[2]
    })
  else
    self:setFirstSuitDataArr({
      liuSuitDataArr[1]
    })
  end
  return self:getBaseActionSuitData()
end

-- 强AI·下家农民首出 · 剩两张牌时的特殊出牌处理（下家农民出牌-只剩两手牌）
function AiBestFarmerRightStartData:getLeftTwoSuitData()
  self.log("==下家农民出牌-只剩两手牌")
  local data = self:getData()
  if self:getLandlordCardCount() > 2 then
    self.log("====== 自己只剩两手牌且地主剩余手牌数大于2，则从小打到大")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self:setFirstSuitDataArr(bestSuitDataArr)
    return self:getBaseActionSuitData()
  end
  return nil
end

return AiBestFarmerRightStartData
