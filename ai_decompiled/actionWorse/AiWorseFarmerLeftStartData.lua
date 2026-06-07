-- 文件: actionWorse/AiWorseFarmerLeftStartData.lua · 反编译 AI 模块（阅读用）

local AiWorseFarmerLeftStartData = class("AiWorseFarmerLeftStartData", AiFarmerLeftStartData)

-- 弱AI·上家农民首出 · 构造函数
function AiWorseFarmerLeftStartData:ctor(params)
  AiWorseFarmerLeftStartData.super.ctor(self, params)
end

-- 弱AI·上家农民首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（上家农民出牌）
function AiWorseFarmerLeftStartData:getActionSuitData()
  self.log("=上家农民出牌")
  local data = self:getData()
  if self:enableEnd() then
    return self:getEndActionSuitData(), true
  end
  if self:checkBestSuitIsTwo() then
    local ret = self:getLeftTwoSuitData()
    if ret ~= nil then
      return ret
    end
  end
  local friendEnableWarningEnd = self:farmerRightEnableWarningEnd()
  local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
  if friendEnableWarningEnd and enemyEnableWarningEnd then
    self.log("===队友、对手能收官")
    self:addResult("C2")
    local ok, suitData = self:getPreventStatusPreventEnemyActionSuitData()
    if ok then
      local ok2, suitData2 = self:getHelpFriendEndActionSuitData()
      if ok2 then
        return suitData2
      else
        return self:getAttackStatusNormalActionSuitData()
      end
    else
      return suitData
    end
  elseif friendEnableWarningEnd then
    self.log("===队友能收官")
    self:addResult("D4")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("===【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    local ok2, suitData2 = self:getHelpFriendEndActionSuitData()
    if ok2 then
      return suitData2
    else
      local allSuitData = data:ai_all_getNotDisBombSuitDataArr()
      self:addParamsWithKey("任意牌组合(不拆炸弹)", allSuitData)
      self.log("===【优先出的牌组合列表】=任意牌组合(不拆炸弹)")
      self:setFirstSuitDataArr(allSuitData)
      local ok3, suitData3 = self:getHelpFriendEndActionSuitData()
      if ok3 then
        return suitData3
      else
        self.log("===【优先出的牌组合列表】=最优分组的牌组合")
        self:setFirstSuitDataArr(bestSuitDataArr)
        return self:getAttackStatusNormalActionSuitData()
      end
    end
  elseif enemyEnableWarningEnd then
    self.log("===对手能收官")
    self:addResult("D3")
    local ok, suitData = self:getPreventStatusPreventEnemyActionSuitData()
    if ok then
      return self:getAttackStatusNormalActionSuitData()
    else
      return suitData
    end
  else
    self.log("===都不能收官")
    self:addResult("C5")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("===【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    return self:getAttackStatusNormalActionSuitData()
  end
end

-- 弱AI·上家农民首出 · 收官出牌：一手出完或走赢牌路径（上家农民出牌-收官）
function AiWorseFarmerLeftStartData:getEndActionSuitData()
  self.log("==上家农民出牌-收官")
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
  self:addResult("C1")
  return self:getBaseActionSuitData()
end

-- 弱AI·上家农民首出 · 协助队友收官的出牌（上家农民出牌-帮队友收官）
function AiWorseFarmerLeftStartData:getHelpFriendEndActionSuitData()
  self.log("===上家农民出牌-帮队友收官")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    firstSuitDataArr = AiUtils:filterNotBombAndFourWithTwoSuitDataArr(firstSuitDataArr)
    local g5 = friendData:ai_filterMatchWinCondition(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】除炸弹和四带二之外，队友的d牌组合 G5", g5)
    self.log(
      "===【优先出的牌组合列表】除炸弹和四带二之外，队友的d牌组合。假定是G5，G5数量是："
        .. #g5
    )
    if 0 < #g5 then
      self.log("=====【优先出的牌组合列表】=G5牌组合")
      self:setFirstSuitDataArr(g5)
      self:addResult("D46")
      goto lbl_48
    else
      self:addResult("D44")
    end
    return false, nil
  end
  ::lbl_48::
  ok = true
  suitData = self:getBaseActionSuitData()
  return ok, suitData
end

-- 弱AI·上家农民首出 · 防守姿态：阻止对手收官的出牌（上家农民出牌-防守姿态-防队手收官）
function AiWorseFarmerLeftStartData:getPreventStatusPreventEnemyActionSuitData()
  self.log("===上家农民出牌-防守姿态-防队手收官")
  local ok, suitData
  local data = self:getData()
  local enemyData = self:getLandlordData()
  do
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    local g20 = enemyData:ai_filterMismatchWinCondition(bestSuitDataArr)
    self:addParamsWithKey("最优分组中，对手的D牌组合 G20", g20)
    self.log("===最优分组中，对手的D牌组合。假定是G20，G20数量是：" .. #g20)
    if 0 < #g20 then
      self.log("====【优先出的牌组合列表】=G20牌组合")
      self:setFirstSuitDataArr(g20)
      ok = true
      suitData = nil
      self:addResult("D33")
    else
      local allSuitData = data:ai_all_getSuitDataArr()
      local g1 = enemyData:ai_filterMismatchWinCondition(allSuitData)
      self:addParamsWithKey("任意牌中，对手的D牌组合 G1", g1)
      self.log("===任意牌中，对手的D牌组合。假定是G1，G1数量是：" .. #g1)
      if 0 < #g1 then
        self.log("====【优先出的牌组合列表】=G1牌组合")
        self:setFirstSuitDataArr(g1)
        ok = true
        suitData = nil
        self:addResult("D32")
      else
        local g3 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getLandlordCardCount())
        if 0 < #g3 then
          self:addParamsWithKey(
            "过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) G3",
            g3
          )
          self.log(
            "==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是G3，G3数量是："
              .. #g3
          )
          self:setFirstSuitDataArr(g3)
          self:addResult("D312")
          ok = false
          suitData = self:getBaseActionSuitData()
          goto lbl_118
        else
          self.log("====最优分组中，全是大牌")
          self:addResult("D311")
        end
        self.log("=====【优先出的牌组合列表】=最优分组牌组合")
        self:setFirstSuitDataArr(bestSuitDataArr)
        ok = false
        suitData = self:getAttackStatusNormalActionSuitData()
        goto lbl_118
      end
    end
  end
  ::lbl_118::
  return ok, suitData
end

-- 弱AI·上家农民首出 · 进攻姿态：常规出牌（上家农民出牌-进攻姿态-常规出牌）
function AiWorseFarmerLeftStartData:getAttackStatusNormalActionSuitData()
  self.log("===上家农民出牌-进攻姿态-常规出牌")
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local firstMaxSuitDataArr = AiUtils:filterFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，首发最大牌组合", firstMaxSuitDataArr)
    self.log("====【优先出的牌组合列表】中，首发最大牌组合。数量是：" .. #firstMaxSuitDataArr)
    if 0 < #firstMaxSuitDataArr then
      self.log("=====【优先出的牌组合列表】=首发最大牌组合")
      self:setFirstSuitDataArr(firstMaxSuitDataArr)
      self:addResult("C51")
    else
      local f1 = AiUtils:filterLiuSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，L牌组合 F1", f1)
      self.log("=====【优先出的牌组合列表】中，L牌组合。假定是F1，F1数量是：" .. #f1)
      if 0 < #f1 then
        self.log("=====【优先出的牌组合列表】=F1牌组合")
        self:setFirstSuitDataArr(f1)
        self:addResult("C52")
      else
        self:addResult("C54")
      end
    end
  end
  return self:getBaseActionSuitData()
end

-- 弱AI·上家农民首出 · 剩两张牌时的特殊出牌处理（上家农民出牌-只剩两手牌）
function AiWorseFarmerLeftStartData:getLeftTwoSuitData()
  self.log("==上家农民出牌-只剩两手牌")
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

return AiWorseFarmerLeftStartData
