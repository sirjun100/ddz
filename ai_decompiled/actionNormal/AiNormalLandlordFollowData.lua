-- 文件: actionNormal/AiNormalLandlordFollowData.lua · 反编译 AI 模块（阅读用）

local AiNormalLandlordFollowData = class("AiNormalLandlordFollowData", AiLandlordFollowData)

-- 中等AI·地主跟牌 · 构造函数
function AiNormalLandlordFollowData:ctor(params)
  AiNormalLandlordFollowData.super.ctor(self, params)
end

-- 中等AI·地主跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（地主跟牌）
function AiNormalLandlordFollowData:getActionSuitData()
  self.log("=地主跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==地主要不起")
    self:addResult("B1")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(lastSuitData, taskData)
  if self:enableEnd() then
    return self:getEndActionSuitData(), true
  end
  if self:isNeedPreventEnemysEnd() then
    return self:getPreventEnemysEndActionSuitData()
  end
  return self:getNormalActionSuitData()
end

-- 中等AI·地主跟牌 · 判断是否need防守enemys收官（判断是否需要防对手收官）
function AiNormalLandlordFollowData:isNeedPreventEnemysEnd()
  self.log("=判断是否需要防对手收官")
  local lastSuitData = self.lastSuitData_
  local uid = lastSuitData:getUid()
  local farmerLeftData = self:getFarmerLeftData()
  local farmerRightData = self:getFarmerRightData()
  if farmerLeftData:getUid() == uid then
    if self:farmerLeftEnableWarningEnd() then
      self.log("==上家农民最后出牌，且能报牌收官了")
      return true
    end
    if farmerRightData:ai_isMatchWinCondition(lastSuitData) and self:farmerRightEnableWarningEnd() then
      self.log("==上家农民最后出牌，下家农民报牌收官，且最后出牌是下家农民d牌")
      return true
    end
  elseif self:farmerRightEnableWarningEnd() then
    self.log("===下家农民最后出牌，且能报牌收官了")
    return true
  end
  return false
end

-- 中等AI·地主跟牌 · 收官出牌：一手出完或走赢牌路径（地主跟牌-收官）
function AiNormalLandlordFollowData:getEndActionSuitData()
  self.log("==地主跟牌-收官")
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
  self:addResult("B2")
  return self:getBaseActionSuitData()
end

-- 中等AI·地主跟牌 · 获取防守enemys收官出牌动作牌型data（地主跟牌-防对手s收官）
function AiNormalLandlordFollowData:getPreventEnemysEndActionSuitData()
  self.log("==地主跟牌-防对手s收官")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local farmerLeftData = self:getFarmerLeftData()
  local farmerRightData = self:getFarmerRightData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    local h1 = farmerLeftData:ai_filterMismatchWinCondition(bestBiggerSuitDataArr)
    h1 = farmerRightData:ai_filterMismatchWinCondition(h1)
    self:addParamsWithKey("最优分组的YQ牌组合中，对手s的D牌组合 H1", h1)
    self.log("===最优分组的YQ牌组合中，对手s的D牌组合。假定是H1, H1数量是：" .. #h1)
    if 0 < #h1 then
      if not AiUtils:isAllBomb(h1) then
        self.log("====H1中，不全是炸弹，【优先出的牌组合列表】=H1牌组合")
        self:setFirstSuitDataArr(h1)
        self:addResult("B3")
        goto lbl_315
      else
        self.log("====H1中，全是炸弹")
        self:addResult("B4")
      end
    else
      self:addResult("B5")
    end
    local splitBringSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的带牌YQ牌组合", splitBringSuitDataArr)
    local h6 = farmerLeftData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
    self:addParamsWithKey("最优分组的带牌YQ牌组合中，对手s的D牌组合 H6", h6)
    self.log("===最优分组的带牌组合的YQ牌组合中，对手s的D牌组合。假定是H6, H6数量是：" .. #h6)
    if 0 < #h6 then
      self.log("====【优先出的牌组合列表】=H6牌组合")
      self:setFirstSuitDataArr(h6)
      self:addResult("BC")
      goto lbl_315
    else
      self:addResult("BB")
    end
    local allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
    local diffBiggerSuitDataArr = AiUtils:filterBSuitDataArrFromASuitDataArr(allBiggerSuitDataArr, bestBiggerSuitDataArr)
    self:addParamsWithKey("任意YQ牌组合(不拆炸弹)中，最优分组YQ牌不相同的牌组合", diffBiggerSuitDataArr)
    self.log("===任意YQ牌组合(不拆炸弹)中，跟最优分组YQ牌不相同的牌组合数量是：" .. #diffBiggerSuitDataArr)
    local filter_h2
    if 0 < #diffBiggerSuitDataArr then
      local h2 = farmerLeftData:ai_filterMismatchWinCondition(diffBiggerSuitDataArr)
      h2 = farmerRightData:ai_filterMismatchWinCondition(h2)
      self:addParamsWithKey("任意YQ牌组合中，对手s的D牌组合 H2", h2)
      self.log("===任意YQ牌组合中，对手s的D牌组合。假定是H2, H2数量是：" .. #h2)
      if 0 < #h2 then
        if not AiUtils:isAllBomb(h2) then
          self.log("====H2中，不全是炸弹，【优先出的牌组合列表】=H2牌组合")
          self:setFirstSuitDataArr(h2)
          self:addResult("B51")
        else
          self.log("====H2中，全是炸弹")
          local h3 = data:ai_landlord_still_filterNotLoseSuitDataArr(h2)
          self:addParamsWithKey("H2中，某个牌组合不计它后，剩余的牌 不是必败 H3", h3)
          self.log("===H2中，某个牌组合不计它后，剩余的牌 不是必败。假定是H3, H3数量是：" .. #h3)
          if 0 < #h3 then
            self.log("====【优先出的牌组合列表】=H3牌组合")
            self:setFirstSuitDataArr(h3)
            self:addResult("B52")
            goto lbl_315
          else
            filter_h2 = h2
          end
          self:addResult("B53")
          else
            self:addResult("B54")
          end
          else
            self.log("====任意YQ牌组合中，没有跟最优分组YQ牌不相同的牌组合")
          end
          local isPairOrThree = data:ai_filterBombIsPairOrThree()
          self.log("===手牌除开炸弹是否只剩下1个对子或三不带:" .. tostring(isPairOrThree))
          if isPairOrThree and 0 < #allBiggerSuitDataArr then
            self.log("====【优先出的牌组合列表】=任意YQ牌组合(不拆炸弹)")
            self:setFirstSuitDataArr(allBiggerSuitDataArr)
            self:addResult("B556")
          else
            local bestNotBomb = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
            self:addParamsWithKey("最优分组的非炸弹的YQ牌组合", bestNotBomb)
            if 0 < #bestNotBomb then
              self.log("====【优先出的牌组合列表】=最优分组的非炸弹的YQ牌组合")
              self:setFirstSuitDataArr(bestNotBomb)
              self:addResult("B55")
            else
              if 0 < #allBiggerSuitDataArr then
                self.log("====【优先出的牌组合列表】=任意不拆炸弹YQ牌组合")
                local diffBiggerSuitDataArr2
                if filter_h2 ~= nil and 0 < #filter_h2 then
                  diffBiggerSuitDataArr2 = AiUtils:filterBSuitDataArrFromASuitDataArr(allBiggerSuitDataArr, filter_h2)
                  self:addParamsWithKey("任意YQ牌组合(不拆炸弹)中和H2不相同的牌组合", diffBiggerSuitDataArr2)
                  self.log("===任意YQ牌组合(不拆炸弹)中和H2不相同的牌组合数量是：" .. #diffBiggerSuitDataArr2)
                else
                  diffBiggerSuitDataArr2 = allBiggerSuitDataArr
                end
                if 0 < #diffBiggerSuitDataArr2 then
                  local h7 = data:ai_landlord_still_filterNotLoseSuitDataArr(diffBiggerSuitDataArr2)
                  self:addParamsWithKey("【优先出的牌组合列表】中，某个牌组合不计它后，剩余的牌 不是必败 H7", h7)
                  self.log("===【优先出的牌组合列表】中，某个牌组合不计它后，剩余的牌 不是必败。假定是H7, H7数量是：" .. #h7)
                  if 0 < #h7 then
                    self.log("====【优先出的牌组合列表】=H7牌组合")
                    self:setFirstSuitDataArr(h7)
                    self:addResult("B56")
                    goto lbl_315
                  end
                elseif filter_h2 ~= nil and 0 < #filter_h2 then
                  self.log("====任意YQ牌组合(不拆炸弹)中，没有跟H2不相同的牌组合")
                end
              end
              self:addResult("B57")
            end
          end
        end
  end
  ::lbl_315::
  return self:getBaseActionSuitData()
end

-- 中等AI·地主跟牌 · 获取常规出牌动作牌型data（地主跟牌-常规）
function AiNormalLandlordFollowData:getNormalActionSuitData()
  self.log("==地主跟牌-常规")
  local lastSuitData = self.lastSuitData_
  local data = self:getData()
  local farmerLeftData = self:getFarmerLeftData()
  local farmerRightData = self:getFarmerRightData()
  do
    local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
    self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
    self.log("===最优分组的YQ牌组合数量是：" .. #bestBiggerSuitDataArr)
    local bestBiggerNotBombSuitDataArr = AiUtils:filterNotBomb(bestBiggerSuitDataArr)
    self.log("===最优分组非炸弹的YQ牌组合数量是：" .. #bestBiggerNotBombSuitDataArr)
    local firstSuitDataArr
    if 0 < #bestBiggerNotBombSuitDataArr then
      firstSuitDataArr = bestBiggerNotBombSuitDataArr
      self:addResult("BD")
    else
      local splitBringSuitDataArr = data:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
      self:addParamsWithKey("最优分组的带牌YQ牌组合", splitBringSuitDataArr)
      self.log("===最优分组的带牌YQ牌组合数量是：" .. #splitBringSuitDataArr)
      if 0 < #splitBringSuitDataArr then
        firstSuitDataArr = splitBringSuitDataArr
        self:addResult("BE")
      elseif 0 < #bestBiggerSuitDataArr then
        firstSuitDataArr = bestBiggerSuitDataArr
        self:addResult("BF")
      end
    end
    if firstSuitDataArr and 0 < #firstSuitDataArr then
      if not AiUtils:isAllMaxSuitData(firstSuitDataArr) then
        self.log("====【优先出的牌组合列表】中，不全是最大牌。【优先出的牌组合列表】=最优分组的YQ牌组合")
        self:setFirstSuitDataArr(firstSuitDataArr)
        self:addResult("B7")
      else
        self.log("====【优先出的牌组合列表】中，全是最大牌")
        local h4 = data:ai_still_filterNotMoreLunSuitDataArr(firstSuitDataArr)
        self:addParamsWithKey("【优先出的牌组合列表】中，某个牌组合不计它后，剩余的牌 轮次不会增加 H4", h4)
        self.log("====【优先出的牌组合列表】中，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是H4, H4数量是：" .. #h4)
        if 0 < #h4 then
          self.log("=====【优先出的牌组合列表】=H4牌组合")
          self:setFirstSuitDataArr(h4)
          self:addResult("B8")
        else
          self:addResult("B9")
          else
            self:addResult("BA")
          end
          local allBiggerSuitDataArr
          if lastSuitData:getType() == SuitType.kFourWithTwoPair or lastSuitData:getType() == SuitType.kFourWithTwoSingle then
            allBiggerSuitDataArr = data:ai_all_filterBiggerSuitDataArr(lastSuitData)
            self:addParamsWithKey("任意YQ牌组合", allBiggerSuitDataArr)
          else
            allBiggerSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
            self:addParamsWithKey("任意YQ牌组合(不拆炸弹)", allBiggerSuitDataArr)
          end
          local diffBiggerSuitDataArr = AiUtils:filterBSuitDataArrFromASuitDataArr(allBiggerSuitDataArr, firstSuitDataArr)
          self:addParamsWithKey("任意YQ牌组合中和优先出的牌组合列表不相同的牌组合", diffBiggerSuitDataArr)
          self.log("===任意YQ牌组合中和优先出的牌组合列表不相同的牌组合数量是：" .. #diffBiggerSuitDataArr)
          if 0 < #diffBiggerSuitDataArr then
            local h5 = data:ai_still_filterNotMoreLunSuitDataArr(diffBiggerSuitDataArr)
            self:addParamsWithKey("任意YQ牌组合中，某个牌组合不计它后，剩余的牌 轮次不会增加 H5", h5)
            self.log("===任意YQ牌组合中，某个牌组合不计它后，剩余的牌 轮次不会增加。假定是H5, H5数量是：" .. #h5)
            if 0 < #h5 then
              self.log("====【优先出的牌组合列表】=H5牌组合")
              self:setFirstSuitDataArr(h5)
              self:addResult("BA1")
              goto lbl_267
            end
          else
            self.log("====任意YQ牌组合中，没有跟优先出的牌组合列表不相同的牌组合")
          end
          self.log("====跟牌后，轮次会增加")
          local isPairOrThree = data:ai_filterBombIsPairOrThree()
          self.log("===手牌除开炸弹是否只剩下1个对子或三不带:" .. tostring(isPairOrThree))
          if isPairOrThree then
            local allBiggerNotDisBombSuitDataArr = data:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
            if 0 < #allBiggerNotDisBombSuitDataArr then
              self.log("====【优先出的牌组合列表】=任意YQ牌组合(不拆炸弹)")
              self:setFirstSuitDataArr(allBiggerNotDisBombSuitDataArr)
              self:addResult("BA3")
          end
          else
            if farmerLeftData:getUid() == lastSuitData:getUid() and farmerLeftData:ai_bestFenzu_isLeftBombAndOneSuit() or farmerRightData:getUid() == lastSuitData:getUid() and farmerRightData:ai_bestFenzu_isLeftBombAndOneSuit() then
              self.log("====最后出牌的农民只剩下一个炸弹和一手牌，进入防对手收官流程")
              self:addResult("BA4")
              return self:getPreventEnemysEndActionSuitData()
            end
            self.log("====不是仅剩对子和三不带，Pass")
            self:addResult("BA2")
            return nil
          end
        end
      end
  end
  ::lbl_267::
  return self:getBaseActionSuitData()
end

return AiNormalLandlordFollowData
