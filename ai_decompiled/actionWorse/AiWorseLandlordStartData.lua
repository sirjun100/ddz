-- 文件: actionWorse/AiWorseLandlordStartData.lua · 反编译 AI 模块（阅读用）

local AiWorseLandlordStartData = class("AiWorseLandlordStartData", AiLandlordStartData)

-- 弱AI·地主首出 · 构造函数
function AiWorseLandlordStartData:ctor(params)
  AiWorseLandlordStartData.super.ctor(self, params)
end

-- 弱AI·地主首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（地主出牌）
function AiWorseLandlordStartData:getActionSuitData()
  self.log("=地主出牌")
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
  if self:isNeedPreventEnemysEnd() then
    return self:getPreventEnemysEndActionSuitData()
  end
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
  self.log("==【优先出的牌组合列表】=最优分组的牌组合")
  self:setFirstSuitDataArr(bestSuitDataArr)
  self:addResult("A5")
  return self:getNormalActionSuitData()
end

-- 弱AI·地主首出 · 判断是否need防守enemys收官
function AiWorseLandlordStartData:isNeedPreventEnemysEnd()
  return self:farmerLeftEnableWarningEnd() or self:farmerRightEnableWarningEnd()
end

-- 弱AI·地主首出 · 收官出牌：一手出完或走赢牌路径（地主出牌-收官）
function AiWorseLandlordStartData:getEndActionSuitData()
  self.log("==地主出牌-收官")
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
  if self:getFarmerRightCardCount() <= 2 or 2 >= self:getFarmerLeftCardCount() then
    local ret = AiUtils:filterEndSuitDataByEnemyLeftCardNum(firstSuitDataArr, self:getFarmerRightCardCount(), self:getFarmerLeftCardCount())
    if 0 < #ret then
      firstSuitDataArr = ret
      self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)", ret)
      self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) 数量是：" .. #ret)
    end
  end
  self:setFirstSuitDataArr(firstSuitDataArr)
  self:addResult("A1")
  return self:getBaseActionSuitData()
end

-- 弱AI·地主首出 · 获取防守enemys收官出牌动作牌型data（地主出牌-防对手s收官）
function AiWorseLandlordStartData:getPreventEnemysEndActionSuitData()
  self.log("==地主出牌-防对手s收官")
  local data = self:getData()
  local farmerLeftData = self:getFarmerLeftData()
  local farmerRightData = self:getFarmerRightData()
  do
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    local b1 = farmerLeftData:ai_filterMismatchWinCondition(bestSuitDataArr)
    b1 = farmerRightData:ai_filterMismatchWinCondition(b1)
    self:addParamsWithKey("最优分组中，对手s的D牌组合的交集 B1", b1)
    self.log("====最优分组中，对手s的D牌组合的交集。假定是B1牌组合, B1数量是：" .. #b1)
    local firstSuitDataArr
    if 0 < #b1 then
      firstSuitDataArr = b1
      self:addResult("A4")
    else
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("最优分组的带牌牌组合", splitBringSuitDataArr)
      local b9 = farmerLeftData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
      b9 = farmerRightData:ai_filterMismatchWinCondition(b9)
      self:addParamsWithKey("带牌牌组合中，对手s的D牌组合的交集 B9", b9)
      self.log("====带牌牌组合中，对手s的D牌组合的交集。假定是B9牌组合, B9数量是：" .. #b9)
      if 0 < #b9 then
        firstSuitDataArr = b9
        self:addResult("A7")
      end
    end
    if firstSuitDataArr == nil or #firstSuitDataArr == 0 then
      if not self:farmerRightEnableWarningEnd() and not self:farmerLeftEnableWarningEnd() then
        print("BUG!!")
      elseif self:farmerRightEnableWarningEnd() or self:farmerLeftEnableWarningEnd() then
        if self:farmerRightEnableWarningEnd() then
          local b6 = farmerRightData:ai_filterMismatchWinCondition(bestSuitDataArr)
          self.log("====最优分组中，下家农民的D牌组合。假定是B6牌组合, B6数量是：" .. #b6)
          if 0 < #b6 then
            self.log("====【优先出的牌组合列表】=B6牌组合")
            self:setFirstSuitDataArr(b6)
            self:addResult("A61")
            goto lbl_370
          else
            self:addResult("A62")
          end
        else
          local b6 = farmerLeftData:ai_filterMismatchWinCondition(bestSuitDataArr)
          self.log("====最优分组中，上家农民的D牌组合。假定是B6牌组合, B6数量是：" .. #b6)
          if 0 < #b6 then
            self.log("====【优先出的牌组合列表】=B6牌组合")
            self:setFirstSuitDataArr(b6)
            self:addResult("A61")
            goto lbl_370
          else
            self:addResult("A62")
          end
        end
      else
        self:addResult("A63")
      end
      local b10 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getFarmerRightCardCount(), self:getFarmerLeftCardCount())
      if 0 < #b10 then
        self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) B10", b10)
        self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是B10，B10数量是：" .. #b10)
        self:setFirstSuitDataArr(b10)
        self:addResult("A31")
      else
        self:addResult("A32")
        self.log("====【优先出的牌组合列表】=最优分组的牌组合")
        self:setFirstSuitDataArr(bestSuitDataArr)
        do return self:getNormalActionSuitData() end
        if self:landlordIsLose() then
          self.log("==== 地主必败")
          local b5 = AiUtils:filterFirstMaxSuitDataArr(firstSuitDataArr)
          self:addParamsWithKey("B1中，首发最大牌组合 B5", b5)
          self.log("====【优先出的牌组合列表】中，首发最大牌组合。假定是B5，B5数量是：" .. #b5)
          if 0 < #b5 then
            self.log("=====【优先出的牌组合列表】=B5牌组合")
            self:setFirstSuitDataArr(b5)
            self:addResult("A45")
          else
            local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(firstSuitDataArr)
            if 0 < #notMaxSuitDataArr then
              local b7 = AiUtils:filterNotSingleAndPairSuitDataArr(notMaxSuitDataArr)
              self:addParamsWithKey("B1中，非大牌非单张非对子 B7", b7)
              self.log("====【优先出的牌组合列表】中，B1中，非大牌非单张非对子的牌组合。假定是B7，B7数量是：" .. #b7)
              if 0 < #b7 then
                self.log("=====【优先出的牌组合列表】=B7牌组合")
                self:setFirstSuitDataArr(b7)
                self:addResult("A47")
            end
            elseif not AiUtils:isAllMaxMaxSuitData(firstSuitDataArr) then
              do
                self.log("====B1中，不全是大牌")
                self:addParamsWithKey("B1中，非大牌的牌组合", notMaxSuitDataArr)
                local maxLevelSuitData = AiUtils:getMaxLevelSuitData(notMaxSuitDataArr)
                self:addParamsWithKey("B1中，非大牌的最大的牌组合", {maxLevelSuitData})
                self.log("=====【优先出的牌组合列表】=B1中，非大牌的最大的牌组合")
                self:setFirstSuitDataArr({maxLevelSuitData})
                self:addResult("A44")
              end
            else
              local is42SuitDataArr = AiUtils:getIs42SuitDataArr(data:ai_getBestFenzu():getMeAllBringSuitData())
              if 0 < #is42SuitDataArr then
                self:addParamsWithKey("任意四带二组合", is42SuitDataArr)
                self.log("==== 任意四带二组合，数量是：" .. #is42SuitDataArr)
                self:setFirstSuitDataArr(is42SuitDataArr)
                self:addResult("A48")
              else
                local b11 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getFarmerRightCardCount(), self:getFarmerLeftCardCount())
                if 0 < #b11 then
                  self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) B11", b11)
                  self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是B11，B11数量是：" .. #b11)
                  self:setFirstSuitDataArr(b11)
                  self:addResult("A43")
                  goto lbl_370
                else
                  self.log("=====【优先出的牌组合列表】=最优分组的牌组合")
                  self:setFirstSuitDataArr(bestSuitDataArr)
                  self:addResult("A46")
                end
                else
                  self.log("====【优先出的牌组合列表】=B1牌组合")
                  self:setFirstSuitDataArr(firstSuitDataArr)
                  self:addResult("A41")
                end
                return self:getNormalActionSuitData()
              end
            end
          end
      end
    end
  end
  ::lbl_370::
  return self:getBaseActionSuitData()
end

-- 弱AI·地主首出 · 获取常规出牌动作牌型data（地主出牌-常规）
function AiWorseLandlordStartData:getNormalActionSuitData()
  self.log("==地主出牌-常规")
  local data = self:getData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local b2 = AiUtils:filterFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，首发最大牌组合 B2", b2)
    self.log("===【优先出的牌组合列表】中，首发最大牌组合。假定是B2，B2数量是：" .. #b2)
    if 0 < #b2 then
      self.log("====【优先出的牌组合列表】=B2牌组合")
      self:setFirstSuitDataArr(b2)
      self:addResult("A51")
    else
      local b3 = AiUtils:filterLiuSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，L牌组合 B3", b3)
      self.log("===【优先出的牌组合列表】中，L牌组合。假定是B3，B3数量是：" .. #b3)
      if 0 < #b3 then
        local mustLiuKeyMap = data:ai_liu_getMustLiuKeyMap()
        self:addParamsWithKey("含LB牌组合的牌型", mustLiuKeyMap)
        local b4 = AiUtils:filterSuitDataArrWithKeyMap(b3, mustLiuKeyMap)
        self:addParamsWithKey("【优先出的牌组合列表】中，“含LB牌组合的牌型”的L牌组合 B4", b4)
        self.log("===【优先出的牌组合列表】中，“含LB牌组合的牌型”的L牌组合。假定是B4，B4数量是：" .. #b4)
        if 0 < #b4 then
          self.log("====【优先出的牌组合列表】=B4牌组合")
          self:setFirstSuitDataArr(b4)
          self:addResult("A53")
        else
          local mustLiuCKeyMap = data:ai_liu_getMustLiuCKeyMap()
          self:addParamsWithKey("含LC牌组合的牌型", mustLiuCKeyMap)
          local b8 = AiUtils:filterSuitDataArrWithKeyMap(b3, mustLiuCKeyMap)
          self:addParamsWithKey("【优先出的牌组合列表】中，“含LC牌组合的牌型”的L牌组合 B8", b8)
          self.log("===【优先出的牌组合列表】中，“含LC牌组合的牌型”的L牌组合。假定是B8，B8数量是：" .. #b8)
          if 0 < #b8 then
            self.log("====【优先出的牌组合列表】=B8牌组合")
            self:setFirstSuitDataArr(b8)
            self:addResult("A55")
            goto lbl_130
          else
            self.log("====【优先出的牌组合列表】=B3牌组合")
            self:setFirstSuitDataArr(b3)
            self:addResult("A54")
            goto lbl_130
          end
          self:addResult("A52")
        end
      end
    end
  end
  ::lbl_130::
  return self:getBaseActionSuitData()
end

-- 弱AI·地主首出 · 剩两张牌时的特殊出牌处理（地主出牌-只剩两手牌）
function AiWorseLandlordStartData:getLeftTwoSuitData()
  self.log("==地主出牌-只剩两手牌")
  local data = self:getData()
  if self:getFarmerRightCardCount() > 2 and 2 < self:getFarmerLeftCardCount() then
    self.log("====== 自己只剩两手牌且两个农民剩余手牌数大于2，则从小打到大")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self:setFirstSuitDataArr(bestSuitDataArr)
    return self:getBaseActionSuitData()
  end
  return nil
end

return AiWorseLandlordStartData
