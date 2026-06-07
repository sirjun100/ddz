-- 文件: actionWorse/AiWorseFarmerRightStartData.lua · 反编译 AI 模块（阅读用）

local AiWorseFarmerRightStartData = class("AiWorseFarmerRightStartData", AiFarmerRightStartData)

-- 弱AI·下家农民首出 · 构造函数
function AiWorseFarmerRightStartData:ctor(params)
  AiWorseFarmerRightStartData.super.ctor(self, params)
end

-- 弱AI·下家农民首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（下家农民出牌）
function AiWorseFarmerRightStartData:getActionSuitData()
  self.log("=下家农民出牌")
  local data = self:getData()
  if self:enableEnd() then
    if self:isNeedHelpFriendEnd() then
      local ok, suitData = self:getHelpFriendEndActionSuitData()
      if ok then
        return suitData
      end
    end
    return self:getEndActionSuitData(), true
  elseif self:farmerLeftEnableWarningEnd() then
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    end
  end
  if self:checkBestSuitIsTwo() then
    local ret = self:getLeftTwoSuitData()
    if ret ~= nil then
      return ret
    end
  end
  local friendEnableWarningEnd = self:farmerLeftEnableWarningEnd()
  local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
  if friendEnableWarningEnd and enemyEnableWarningEnd then
    self.log("===队友、对手能报牌收官")
    self:addResult("H2")
    local ok, suitData = self:getHelpFriendEndActionSuitData()
    if ok then
      return suitData
    else
      return self:getAttackStatusPreventEnemyActionSuitData()
    end
  elseif friendEnableWarningEnd then
    self.log("===队友能报牌收官")
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
  elseif enemyEnableWarningEnd then
    self.log("===对手能报牌收官")
    self:addResult("H4")
    return self:getAttackStatusPreventEnemyActionSuitData()
  else
    self.log("===自己不能收官，其它人都不能报牌收官")
    self:addResult("H5")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("====【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    return self:getAttackStatusNormalActionSuitData()
  end
end

-- 弱AI·下家农民首出 · 收官出牌：一手出完或走赢牌路径（下家农民出牌-收官）
function AiWorseFarmerRightStartData:getEndActionSuitData()
  self.log("==下家农民出牌-收官")
  local data = self:getData()
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(nil, taskData)
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
      self:addParamsWithKey(
        "过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)",
        ret
      )
      self.log(
        "==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) 数量是："
          .. #ret
      )
    end
  end
  self:setFirstSuitDataArr(firstSuitDataArr)
  self:addResult("H1")
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民首出 · 协助队友收官的出牌（下家农民出牌-帮队友收官）
function AiWorseFarmerRightStartData:getHelpFriendEndActionSuitData()
  self.log("===下家农民出牌-帮队友收官")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  do
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
        local e1 = friendData:ai_filterMatchWinCondition(allSuitData)
        self:addParamsWithKey("除炸弹外的任意牌中(不拆炸弹)，队友的d牌组合 E1", e1)
        self.log(
          "===除炸弹外任意牌中(不拆炸弹)，队友的d牌组合。假定是E1，E1数量是：" .. #e1
        )
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
  return ok, suitData
end

-- 弱AI·下家农民首出 · 获取进攻姿态防守对手出牌动作牌型data（下家农民出牌-进攻姿态-防队手收官）
function AiWorseFarmerRightStartData:getAttackStatusPreventEnemyActionSuitData()
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
    self:addParamsWithKey(
      "比“队友的最优分组牌组合中，对手的D牌组合”小的“最优分组牌组合中，对手的d牌组合”",
      friendMismatchWinConditionArr
    )
    self.log(
      "===最优分组牌组合中，对手的D牌组合数量："
        .. #bestMismatchWinConditionArr
        .. "; 对手的d牌组合数量："
        .. #bestMatchWinConditionArr
        .. "; Dd牌组合数量："
        .. #bestDd
    )
    if not (0 < #bestMismatchWinConditionArr) and not (0 < #bestDd) then
      if not AiUtils:isAllMaxMaxSuitData(bestSuitDataArr) then
        self.log("====最优分组中，不全是大牌")
        local bestNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestSuitDataArr)
        self:addParamsWithKey("最优分组的非大牌的牌组合", bestNotMaxSuitDataArr)
        local maxLevelSuitData = AiUtils:getMaxLevelSuitData(bestNotMaxSuitDataArr)
        self:addParamsWithKey("最优分组的非大牌的最大的牌组合", { maxLevelSuitData })
        self.log("=====【优先出的牌组合列表】=最优分组的非大牌的最大的牌组合")
        self:setFirstSuitDataArr({ maxLevelSuitData })
        self:addResult("H422")
        goto lbl_315
      else
        self.log("====最优分组中，全是大牌")
        self:addResult("H421")
      end
      self.log("====【优先出的牌组合列表】=最优分组的牌组合")
      self:setFirstSuitDataArr(bestSuitDataArr)
      return self:getAttackStatusNormalActionSuitData()
    end
    local isLose = data:ai_getIsLose()
    self.log("====最优分组是否必败：" .. tostring(isLose))
    if isLose then
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
          self.log(
            "====【优先出的牌组合列表】中，C1中，非大牌非单张非对子的牌组合。假定是C9，C9数量是："
              .. #c9
          )
          if 0 < #c9 then
            self.log("=====【优先出的牌组合列表】=C9牌组合")
            self:setFirstSuitDataArr(c9)
          end
        elseif not AiUtils:isAllMaxMaxSuitData(c1) then
          do
            self.log("====C1中，不全是大牌")
            self:addParamsWithKey("C1中，非大牌的牌组合", notMaxSuitDataArr)
            local maxLevelSuitData = AiUtils:getMaxLevelSuitData(notMaxSuitDataArr)
            self:addParamsWithKey("C1中，非大牌的最大的牌组合", { maxLevelSuitData })
            self.log("=====【优先出的牌组合列表】=C1中，非大牌的最大的牌组合")
            self:setFirstSuitDataArr({ maxLevelSuitData })
            self:addResult("H431")
          end
        elseif not AiUtils:isAllMaxMaxSuitData(bestSuitDataArr) then
          self.log("====最优分组中，不全是大牌")
          local bestNotMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(bestSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的牌组合", bestNotMaxSuitDataArr)
          local maxLevelSuitData = AiUtils:getMaxLevelSuitData(bestNotMaxSuitDataArr)
          self:addParamsWithKey("最优分组的非大牌的最大的牌组合", { maxLevelSuitData })
          self.log("=====【优先出的牌组合列表】=最优分组的非大牌的最大的牌组合")
          self:setFirstSuitDataArr({ maxLevelSuitData })
          self:addResult("H432")
          goto lbl_315
        else
          self.log("=====【优先出的牌组合列表】=最优分组的牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          self:addResult("H433")
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
  ::lbl_315::
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民首出 · 进攻姿态：常规出牌（下家农民出牌-进攻姿态-常规出牌）
function AiWorseFarmerRightStartData:getAttackStatusNormalActionSuitData()
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
        self.log(
          "====【优先出的牌组合列表】中，LB牌组合的牌型。假定是tc4牌型，tc4数量是："
            .. #table.keys(tc4)
        )
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
          self.log(
            "====【优先出的牌组合列表】中，LC牌组合的牌型。假定是tc10牌型，tc10数量是："
              .. #table.keys(tc10)
          )
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
        local firstLiuSuitDataArr = AiUtils:filterSuitDataArrWithKeyMap(c3, firstKeyMap)
        self:addParamsWithKey("【优先出的牌型】的C3牌组合", firstLiuSuitDataArr)
        self.log("======【优先出的牌组合列表】=【优先出的牌型】的C3牌组合")
        self:setFirstSuitDataArr(firstLiuSuitDataArr)
        self:addResult("H534")
        goto lbl_171
      end
    end
  end
  ::lbl_171::
  return self:getBaseActionSuitData()
end

-- 弱AI·下家农民首出 · 剩两张牌时的特殊出牌处理（下家农民出牌-只剩两手牌）
function AiWorseFarmerRightStartData:getLeftTwoSuitData()
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

return AiWorseFarmerRightStartData
