-- 文件: actionBest/AiBestFarmerLeftStartData.lua · 反编译 AI 模块（阅读用）

local AiBestFarmerLeftStartData = class("AiBestFarmerLeftStartData", AiFarmerLeftStartData)

-- 强AI·上家农民首出 · 构造函数
function AiBestFarmerLeftStartData:ctor(params)
  AiBestFarmerLeftStartData.super.ctor(self, params)
end

-- 强AI·上家农民首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（上家农民出牌）
function AiBestFarmerLeftStartData:getActionSuitData()
  self.log("=上家农民出牌")
  local data = self:getData()
  local taskData = self.taskData_
  data:ai_doDeepBestSuitDataArr(nil, taskData)
  if self:enableEnd() then
    if self:checkLiuSuitIsAllSingle() then
      if self:enableSingleEnd() then
        return self:getSingleEndActionSuitData(), true
      end
    else
      return self:getEndActionSuitData(), true
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
  self.log("=上家农民的姿态: " .. status)
  if status == 0 then
    return self:getPreventStatusActionSuitData()
  else
    return self:getAttackStatusActionSuitData()
  end
end

-- 强AI·上家农民首出 · 计算攻守姿态（0 防守 / 1 进攻）
function AiBestFarmerLeftStartData:getStatus()
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local friendRobot = friendData:getRobot()
  local lun = data:ai_getBestFenzuData().lun_
  local friendLun = friendData:ai_getBestFenzuData().lun_
  local ret
  if friendRobot then
    if lun < friendLun then
      ret = 1
    else
      ret = 0
    end
  elseif lun < friendLun - 1 then
    ret = 1
  else
    ret = 0
  end
  return ret
end

-- 强AI·上家农民首出 · 收官出牌：一手出完或走赢牌路径（上家农民出牌-收官）
function AiBestFarmerLeftStartData:getEndActionSuitData()
  self.log("==上家农民出牌-收官")
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
  self:addResult("C1")
  return self:getBaseActionSuitData()
end

-- 强AI·上家农民首出 · 协助队友收官的出牌（上家农民出牌-帮队友收官）
function AiBestFarmerLeftStartData:getHelpFriendEndActionSuitData()
  self.log("===上家农民出牌-帮队友收官")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    firstSuitDataArr = AiUtils:filterNotBombAndFourWithTwoSuitDataArr(firstSuitDataArr)
    local g5 = friendData:ai_filterMatchWinCondition(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】除炸弹和四带二之外，队友的d牌组合 G5", g5)
    self.log("===【优先出的牌组合列表】除炸弹和四带二之外，队友的d牌组合。假定是G5，G5数量是：" .. #g5)
    if 0 < #g5 then
      local g6 = AiUtils:filterFirstMaxSuitDataArr(g5)
      self:addParamsWithKey("G5中，首发最大牌组合 G6", g6)
      self.log("====G5中，首发最大牌组合。假定是G6，G6数量是：" .. #g6)
      if 0 < #g6 then
        self.log("=====【优先出的牌组合列表】=G6牌组合")
        self:setFirstSuitDataArr(g6)
        self:addResult("D41")
      else
        local g21 = data:ai_filterHasMatchFriendWinConditionSuitDataArr(g5)
        self:addParamsWithKey("G5中，对手任意YQ牌都是队友d牌组合 G21", g21)
        self.log("====G5中，对手任意YQ牌都是队友d牌组合。假定是G21，G21数量是：" .. #g21)
        if 0 < #g21 then
          self.log("=====【优先出的牌组合列表】=G21牌组合")
          self:setFirstSuitDataArr(g21)
          self:addResult("D45")
        else
          local friendMustEndKeyMap = friendData:ai_bestFenzu_getMustEndSuitKeyMap()
          self:addParamsWithKey("队友压制强收官牌型", friendMustEndKeyMap)
          local g7 = AiUtils:filterSuitDataArrWithKeyMap(g5, friendMustEndKeyMap)
          self:addParamsWithKey("G5中，与队友压制强收官牌型同牌型的牌组合 G7", g7)
          self.log("====G5中，与队友压制强收官牌型同牌型的牌组合。假定是G7，G7数量是：" .. #g7)
          if 0 < #g7 then
            self.log("=====【优先出的牌组合列表】=G7牌组合")
            self:setFirstSuitDataArr(g7)
            self:addResult("D42")
            goto lbl_126
          else
            self:addResult("D43")
          end
          else
            self:addResult("D44")
          end
          return false, nil
        end
      end
  end
  ::lbl_126::
  ok = true
  suitData = self:getBaseActionSuitData()
  return ok, suitData
end

-- 强AI·上家农民首出 · 防守姿态出牌（上家农民出牌-防手姿态）
function AiBestFarmerLeftStartData:getPreventStatusActionSuitData()
  self.log("==上家农民出牌-防手姿态")
  local friendEnableEnd = self:farmerRightEnableEnd()
  local enemyEnableEnd = self:landlordEnableEnd()
  local friendData = self:getFarmerRightData()
  local data = self:getData()
  if friendEnableEnd and enemyEnableEnd then
    self.log("===队友、对手能收官")
    self:addResult("D2")
    local ok, suitData = self:getPreventStatusPreventEnemyActionSuitData()
    if ok then
      local ok2, suitData2 = self:getHelpFriendEndActionSuitData()
      if ok2 then
        return suitData2
      else
        return self:getAttackStatusPreventEnemyActionSuitData()
      end
    else
      return suitData
    end
  elseif enemyEnableEnd then
    self.log("===对手能收官")
    self:addResult("D3")
    local ok, suitData = self:getPreventStatusPreventEnemyActionSuitData()
    if ok then
      local friendIsLose = friendData:ai_getIsLose()
      if not friendIsLose then
        local ok2, suitData2 = self:getPreventStatusNormalHelpFriendActionSuitData()
        if ok2 then
          return suitData2
        else
          self:addResult("D37")
          return self:getAttackStatusPreventEnemyActionSuitData()
        end
      else
        self:addResult("D36")
        return self:getAttackStatusPreventEnemyActionSuitData()
      end
    else
      return suitData
    end
  elseif friendEnableEnd then
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
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      self.log("====【优先出的牌组合列表】=带牌牌组合")
      self:setFirstSuitDataArr(splitBringSuitDataArr)
      local ok3, suitData3 = self:getHelpFriendEndActionSuitData()
      if ok3 then
        return suitData3
      else
        local allSuitData = data:ai_all_getNotDisBombSuitDataArr()
        self:addParamsWithKey("任意牌组合(不拆炸弹)", allSuitData)
        self.log("===【优先出的牌组合列表】=任意牌组合(不拆炸弹)")
        self:setFirstSuitDataArr(allSuitData)
        local ok4, suitData4 = self:getHelpFriendEndActionSuitData()
        if ok4 then
          return suitData4
        else
          self.log("===【优先出的牌组合列表】=最优分组的牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          return self:getAttackStatusNormalActionSuitData()
        end
      end
    end
  else
    self.log("===都不能收官")
    self:addResult("D5")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("===【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    local ok2, suitData2 = self:getPreventStatusNormalHelpFriendActionSuitData()
    if ok2 then
      return suitData2
    else
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      self.log("====【优先出的牌组合列表】=带牌牌组合")
      self:setFirstSuitDataArr(splitBringSuitDataArr)
      local ok3, suitData3 = self:getPreventStatusNormalHelpFriendActionSuitData()
      if ok3 then
        return suitData3
      else
        self.log("===【优先出的牌组合列表】=最优分组的牌组合")
        self:setFirstSuitDataArr(bestSuitDataArr)
        local ok4, suitData4 = self:getPreventStatusNormalHitEnemyActionSuitData()
        if ok4 then
          return suitData4
        else
          self.log("===【优先出的牌组合列表】=最优分组的牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          return self:getAttackStatusNormalActionSuitData()
        end
      end
    end
  end
end

-- 强AI·上家农民首出 · 防守姿态：阻止对手收官的出牌（上家农民出牌-防守姿态-防队手收官）
function AiBestFarmerLeftStartData:getPreventStatusPreventEnemyActionSuitData()
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
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      local g24 = enemyData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
      self:addParamsWithKey("带牌牌组合中，对手的D牌组合 G24", g24)
      self.log("===带牌牌组合中，对手的D牌组合。假定是G24，G24数量是：" .. #g24)
      if 0 < #g24 then
        self.log("====【优先出的牌组合列表】=G24牌组合")
        self:setFirstSuitDataArr(g24)
        ok = true
        suitData = nil
        self:addResult("D35")
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
          local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
          self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
          if enemyEnableWarningEnd then
            local g3 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getLandlordCardCount())
            if 0 < #g3 then
              self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) G3", g3)
              self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是G3，G3数量是：" .. #g3)
              self:setFirstSuitDataArr(g3)
              ok = false
              suitData = self:getBaseActionSuitData()
              self:addResult("D312")
              goto lbl_163
            else
              self:addResult("D311")
            end
          else
            self:addResult("D34")
          end
          self.log("=====【优先出的牌组合列表】=最优分组牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          ok = false
          suitData = self:getAttackStatusNormalActionSuitData()
          goto lbl_163
        end
      end
    end
  end
  ::lbl_163::
  return ok, suitData
end

-- 强AI·上家农民首出 · 获取防守姿态常规协助队友出牌动作牌型data（上家农民出牌-防守姿态-常规出牌(帮队友)）
function AiBestFarmerLeftStartData:getPreventStatusNormalHelpFriendActionSuitData()
  self.log("===上家农民出牌-防守姿态-常规出牌(帮队友)")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local g8 = friendData:ai_bestFenzu_filterAllSmallerFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，比队友首发最大牌小的牌组合 G8", g8)
    self.log("====【优先出的牌组合列表】中，比队友首发最大牌小的牌组合。假定是G8，G8数量是：" .. #g8)
    if 0 < #g8 then
      self.log("=====【优先出的牌组合列表】=G8牌组合")
      self:setFirstSuitDataArr(g8)
      self:addResult("D51")
    else
      local g14 = friendData:ai_liu_filterLiuKeyAndSmallerLmaxSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，与队友L牌同牌型的，队友的Lax牌组合 G14", g14)
      self.log("====【优先出的牌组合列表】中，与队友L牌同牌型的，队友的Lax牌组合。假定是G14，G14数量是：" .. #g14)
      if 0 < #g14 then
        local enemyBestFenzu = enemyData:ai_getBestSuitDataArr()
        local notBombSuitDataArr = AiUtils:filterNotBomb(enemyBestFenzu)
        self:addParamsWithKey("对手最优分组(除开炸弹)的牌组合", notBombSuitDataArr)
        local enemySplitBringSuitDataArr = enemyData:ai_bestFenzu_splitBringSuitDataArr()
        if 0 < #enemySplitBringSuitDataArr then
          table.insertto(notBombSuitDataArr, enemySplitBringSuitDataArr)
        end
        local g19 = AiUtils:filterAllBiggerSuitDataArr(notBombSuitDataArr, g14)
        self:addParamsWithKey("g14中，对手最优分组和带牌牌组合(除开炸弹)要不起的牌组合 G19", g19)
        self.log("===== g14中，对手最优分组和带牌牌组合(除开炸弹)要不起的牌组合。假定是G19，G19数量是：" .. #g19)
        if 0 < #g19 then
          self.log("======【优先出的牌组合列表】=G19牌组合")
          self:setFirstSuitDataArr(g19)
          self:addResult("D52")
      end
      else
        local g18 = friendData:ai_bestFenzu_filterAllSmallerMustEndMaxSuitDataArr(firstSuitDataArr)
        self:addParamsWithKey("【优先出的牌组合列表】中，比队友的压制强收官牌小的牌组合 G18", g18)
        self.log("====【优先出的牌组合列表】中，比队友的压制强收官牌小的牌组合。假定是G18，G18数量是：" .. #g18)
        if 0 < #g18 then
          local g181 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(g18)
          self:addParamsWithKey("G18中，对手的DP牌组合 G18_DP", g181)
          self.log("=====G18中，对手的DP牌组合。假定是G18_DP，G18_DP数量是：" .. #g181)
          if 0 < #g181 then
            self.log("======【优先出的牌组合列表】=G18_DP牌组合")
            self:setFirstSuitDataArr(g181)
            self:addResult("D5541")
          else
            local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
            self:addParamsWithKey("对手最优分组的YQ牌组合", enemyBiggerSuitDataArr)
            local enemyLiuBiggerSuitDataArr = AiUtils:filterLiuSuitDataArr(enemyBiggerSuitDataArr)
            self:addParamsWithKey("对手最优分组的YQ牌组合中，L牌", enemyLiuBiggerSuitDataArr)
            local x = AiUtils:getMaxYaSuitData(enemyLiuBiggerSuitDataArr, g18)
            self.log("===对手能被自己【G18牌组合】压住的L牌组合中的最大牌。假定是X，X是：" .. (x and x:toString() or "nil"))
            if x then
              self:addParamsWithKey("对手能被自己【G18牌组合】压住的L牌组合中的最大牌 X", {x})
              local g26 = AiUtils:filterNotSmallerSuitDataArr(g18, x)
              self:addParamsWithKey("对手能被自己【G18牌组合】压住的L牌组合中的最大牌 G26", g26)
              self.log("===对手能被自己【G18牌组合】压住的L牌组合中的最大牌。假定是G26，G26数量是：" .. #g26)
              if 0 < #g26 then
                self.log("====【优先出的牌组合列表】=G26牌组合")
                self:setFirstSuitDataArr(g26)
                self:addResult("D5546")
            end
            else
              local friendBetterKeyMap = friendData:ai_bestFenzu_getBetterThenEnemySuitKeyMap()
              self:addParamsWithKey("队友比对手优势的牌型", friendBetterKeyMap)
              local g25 = AiUtils:filterSuitDataArrWithKeyMap(g18, friendBetterKeyMap)
              self:addParamsWithKey("G18中，队友比对手优势的牌型的牌组合 G25", g25)
              self.log("=====G18中，队友比对手优势的牌型的牌组合。假定是G25，G25数量是：" .. #g25)
              if 0 < #g25 then
                self.log("======【优先出的牌组合列表】=G25牌组合")
                self:setFirstSuitDataArr(g25)
                self:addResult("D5543")
              else
                self:addResult("D5544")
                else
                  self:addResult("D5545")
                end
                return false, nil
              end
            end
          end
      end
    end
  end
  ok = true
  suitData = self:getBaseActionSuitData()
  return ok, suitData
end

-- 强AI·上家农民首出 · 获取防守姿态常规hit对手出牌动作牌型data（上家农民出牌-防守姿态-常规出牌(顶对手)）
function AiBestFarmerLeftStartData:getPreventStatusNormalHitEnemyActionSuitData()
  self.log("===上家农民出牌-防守姿态-常规出牌(顶对手)")
  local ok, suitData
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local friendBestFenzu = friendData:ai_getBestSuitDataArr()
    local g22 = AiUtils:filterAllSmallerSuitDataArr(friendBestFenzu, firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，队友最优分组要得起的牌组合 G22", g22)
    self.log("====【优先出的牌组合列表】中，队友最优分组要得起的牌组合。假定是G22，G22数量是：" .. #g22)
    local g221 = enemyData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(g22)
    self:addParamsWithKey("G22中，对手的DP牌组合 G22_DP", g221)
    self.log("=====G22中，对手的DP牌组合。假定是G22_DP，G22_DP数量是：" .. #g221)
    if 0 < #g221 then
      self.log("=====【优先出的牌组合列表】=G221牌组合")
      self:setFirstSuitDataArr(g221)
      self:addResult("D561")
    else
      local enemyBiggerSuitDataArr = enemyData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
      self:addParamsWithKey("对手最优分组的YQ牌组合", enemyBiggerSuitDataArr)
      local enemyLiuBiggerSuitDataArr = AiUtils:filterLiuSuitDataArr(enemyBiggerSuitDataArr)
      self:addParamsWithKey("对手最优分组的YQ牌组合中，L牌", enemyLiuBiggerSuitDataArr)
      local smallerTwoLiuSuitDataArr = AiUtils:filterSmallerTwoLiuSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("优先出的牌组合中，小于2的L牌组合", smallerTwoLiuSuitDataArr)
      local x = AiUtils:getMaxYaSuitData(enemyLiuBiggerSuitDataArr, smallerTwoLiuSuitDataArr)
      self.log("===对手能被自己【任意YQ牌组合中，小于2的L牌组合】压住的L牌组合中的最大牌。假定是X，X是：" .. (x and x:toString() or "nil"))
      if x then
        self:addParamsWithKey("对手能被自己【任意YQ牌组合中，小于2的L牌组合】压住的L牌组合中的最大牌 X", {x})
        local g23 = AiUtils:filterNotSmallerSuitDataArr(smallerTwoLiuSuitDataArr, x)
        self:addParamsWithKey("最优分组中，小于2的L牌组合中，不比X小的牌组合 G23", g23)
        self.log("===最优分组中，小于2的L牌组合中，不比X小的牌组合。假定是G23，G23数量是：" .. #g23)
        if 0 < #g23 then
          self.log("====【优先出的牌组合列表】=G23牌组合")
          self:setFirstSuitDataArr(g23)
          self:addResult("D562")
      end
      else
        self:addResult("D563")
        return false, nil
      end
    end
  end
  ok = true
  suitData = self:getBaseActionSuitData()
  return ok, suitData
end

-- 强AI·上家农民首出 · 进攻姿态出牌（上家农民出牌-进攻姿态）
function AiBestFarmerLeftStartData:getAttackStatusActionSuitData()
  self.log("==上家农民出牌-进攻姿态")
  local data = self:getData()
  local friendEnableEnd = self:farmerRightEnableEnd()
  local enemyEnableEnd = self:landlordEnableEnd()
  if friendEnableEnd and enemyEnableEnd then
    self.log("===队友、对手能收官")
    self:addResult("C2")
    local ok, suitData = self:getPreventStatusPreventEnemyActionSuitData()
    if ok then
      local ok2, suitData2 = self:getHelpFriendEndActionSuitData()
      if ok2 then
        return suitData2
      else
        return self:getAttackStatusPreventEnemyActionSuitData()
      end
    else
      return suitData
    end
  elseif friendEnableEnd then
    self.log("===队友能收官")
    self:addResult("C3")
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    self.log("===【优先出的牌组合列表】=最优分组的牌组合")
    self:setFirstSuitDataArr(bestSuitDataArr)
    local ok2, suitData2 = self:getHelpFriendEndActionSuitData()
    if ok2 then
      return suitData2
    else
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      self.log("====【优先出的牌组合列表】=带牌牌组合")
      self:setFirstSuitDataArr(splitBringSuitDataArr)
      local ok3, suitData3 = self:getHelpFriendEndActionSuitData()
      if ok3 then
        return suitData3
      else
        local allSuitData = data:ai_all_getNotDisBombSuitDataArr()
        self:addParamsWithKey("任意牌组合(不拆炸弹)", allSuitData)
        self.log("===【优先出的牌组合列表】=任意牌组合(不拆炸弹)")
        self:setFirstSuitDataArr(allSuitData)
        local ok4, suitData4 = self:getHelpFriendEndActionSuitData()
        if ok4 then
          return suitData4
        else
          self.log("===【优先出的牌组合列表】=最优分组的牌组合")
          self:setFirstSuitDataArr(bestSuitDataArr)
          return self:getAttackStatusNormalActionSuitData()
        end
      end
    end
  elseif enemyEnableEnd then
    self.log("===对手能收官")
    self:addResult("C4")
    return self:getAttackStatusPreventEnemyActionSuitData()
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

-- 强AI·上家农民首出 · 获取进攻姿态防守对手出牌动作牌型data（上家农民出牌-进攻姿态-防队手收官）
function AiBestFarmerLeftStartData:getAttackStatusPreventEnemyActionSuitData()
  self.log("===上家农民出牌-进攻姿态-防队手收官")
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local bestSuitDataArr = data:ai_getBestSuitDataArr()
    self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
    local f0 = enemyData:ai_filterMismatchWinCondition(bestSuitDataArr)
    self:addParamsWithKey("最优分组中，对手的D牌组合 F0", f0)
    self.log("===最优分组中，对手的D牌组合。假定是F0，F0数量是：" .. #f0)
    local firstSuitDataArr
    if 0 < #f0 then
      firstSuitDataArr = f0
      self:addResult("C4A")
    else
      local splitBringSuitDataArr = data:ai_bestFenzu_splitBringSuitDataArr()
      self:addParamsWithKey("带牌牌组合", splitBringSuitDataArr)
      local f10 = enemyData:ai_filterMismatchWinCondition(splitBringSuitDataArr)
      self:addParamsWithKey("带牌牌组合中，对手的D牌组合 F10", f10)
      self.log("===带牌牌组合中，对手的D牌组合。假定是F10，F10数量是：" .. #f10)
      if 0 < #f10 then
        firstSuitDataArr = f10
        self:addResult("C4B")
      end
    end
    f0 = firstSuitDataArr
    if f0 and 0 < #f0 then
      local isLose = data:ai_getIsLose()
      self.log("====是否必败：" .. tostring(isLose))
      if isLose then
        local friendIsLose = friendData:ai_getIsLose()
        if not friendIsLose then
          self.log("=====【优先出的牌组合列表】=F0牌组合")
          self:setFirstSuitDataArr(f0)
          self:addResult("C42")
          local ok2, suitData2 = self:getPreventStatusNormalHelpFriendActionSuitData()
          if ok2 then
            return suitData2
          else
            self:addResult("C48")
          end
        end
        if self:landlordEnableWarningEnd() then
          local F6 = AiUtils:filterFirstMaxSuitDataArr(f0)
          self:addParamsWithKey("F0中，首发最大牌组合 F6", F6)
          self.log("====【优先出的牌组合列表】中，首发最大牌组合。假定是F6，F6数量是：" .. #F6)
          if 0 < #F6 then
            self.log("=====【优先出的牌组合列表】=F6牌组合")
            self:setFirstSuitDataArr(F6)
            self:addResult("C440")
          else
            local notMaxSuitDataArr = AiUtils:filterNotMaxMaxSuitDataArr(f0)
            if 0 < #notMaxSuitDataArr then
              local f7 = AiUtils:filterNotSingleAndPairSuitDataArr(notMaxSuitDataArr)
              self:addParamsWithKey("F0中，非大牌非单张非对子 F7", f7)
              self.log("====【优先出的牌组合列表】中，F0中，非大牌非单张非对子的牌组合。假定是F7，F7数量是：" .. #f7)
              if 0 < #f7 then
                self.log("=====【优先出的牌组合列表】=F7牌组合")
                self:setFirstSuitDataArr(f7)
                self:addResult("C444")
            end
            elseif not AiUtils:isAllMaxMaxSuitData(f0) then
              do
                self.log("====F0中，不全是大牌")
                self:addParamsWithKey("F0中，非大牌的牌组合", notMaxSuitDataArr)
                local maxLevelSuitData = AiUtils:getMaxLevelSuitData(notMaxSuitDataArr)
                self:addParamsWithKey("F0中，非大牌的最大的牌组合", {maxLevelSuitData})
                self.log("=====【优先出的牌组合列表】=F0中，非大牌的最大的牌组合")
                self:setFirstSuitDataArr({maxLevelSuitData})
                self:addResult("C441")
              end
            else
              local is42SuitDataArr = AiUtils:getIs42SuitDataArr(data:ai_getBestFenzu():getMeAllBringSuitData())
              if 0 < #is42SuitDataArr then
                self:addParamsWithKey("任意四带二组合", is42SuitDataArr)
                self.log("==== 任意四带二组合，数量是：" .. #is42SuitDataArr)
                self:setFirstSuitDataArr(is42SuitDataArr)
                self:addResult("C445")
              else
                local g9 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getLandlordCardCount())
                if 0 < #g9 then
                  self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) G9", g9)
                  self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是G9，G9数量是：" .. #g9)
                  self:setFirstSuitDataArr(g9)
                  self:addResult("C442")
                  goto lbl_336
                else
                  self.log("=====【优先出的牌组合列表】=最优分组的牌组合")
                  self:setFirstSuitDataArr(bestSuitDataArr)
                  self:addResult("C443")
                end
                else
                  self.log("=====【优先出的牌组合列表】=最优分组的牌组合")
                  self:setFirstSuitDataArr(bestSuitDataArr)
                  self:addResult("C45")
                end
                else
                  self.log("=====【优先出的牌组合列表】=F0牌组合")
                  self:setFirstSuitDataArr(f0)
                  self:addResult("C43")
                end
                do return self:getAttackStatusNormalActionSuitData() end
                local enemyEnableWarningEnd = self:landlordEnableWarningEnd()
                self.log("=====对手是否报牌收官：" .. tostring(enemyEnableWarningEnd))
                if enemyEnableWarningEnd then
                  local g4 = AiUtils:filterEndSuitDataByEnemyLeftCardNum(bestSuitDataArr, self:getLandlordCardCount())
                  if 0 < #g4 then
                    self:addParamsWithKey("过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌) G4", g4)
                    self.log("==== 过滤与对手报牌数量相同的牌型(如果只有同牌型，则过滤得到相同牌型里的最大牌)，假定是G4，G4数量是：" .. #g4)
                    self:setFirstSuitDataArr(g4)
                    self:addResult("C412")
                    goto lbl_336
                  else
                    self:addResult("C411")
                  end
                else
                  self:addResult("C46")
                end
                self.log("=====【优先出的牌组合列表】=最优分组牌组合")
                self:setFirstSuitDataArr(bestSuitDataArr)
                return self:getAttackStatusNormalActionSuitData()
              end
            end
          end
    end
  end
  ::lbl_336::
  return self:getBaseActionSuitData()
end

-- 强AI·上家农民首出 · 进攻姿态：常规出牌（上家农民出牌-进攻姿态-常规出牌）
function AiBestFarmerLeftStartData:getAttackStatusNormalActionSuitData()
  self.log("===上家农民出牌-进攻姿态-常规出牌")
  local data = self:getData()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  do
    local firstSuitDataArr = self:getFirstSuitDataArr()
    local firstMaxSuitDataArr = AiUtils:filterFirstMaxSuitDataArr(firstSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，首发最大牌组合 F8", firstMaxSuitDataArr)
    self.log("====【优先出的牌组合列表】中，首发最大牌组合。假定是F8，F8数量是：" .. #firstMaxSuitDataArr)
    if 0 < #firstMaxSuitDataArr then
      self.log("=====【优先出的牌组合列表】=F8牌组合")
      self:setFirstSuitDataArr(firstMaxSuitDataArr)
      self:addResult("C51")
    else
      local f1 = AiUtils:filterLiuSuitDataArr(firstSuitDataArr)
      self:addParamsWithKey("【优先出的牌组合列表】中，L牌组合 F1", f1)
      self.log("=====【优先出的牌组合列表】中，L牌组合。假定是F1，F1数量是：" .. #f1)
      if #f1 == 0 then
        self:addResult("C54")
      else
        local tf1 = AiUtils:getKeyMapWithSuitDataArr(f1)
        self:addParamsWithKey("F1的牌型 tf1", tf1)
        self.log("====F1的牌型。假定是tf1牌型，tf1数量是：" .. #table.keys(tf1))
        local tf2 = data:ai_liu_getMustLiuKeyMap()
        tf2 = AiUtils:getSameKeyMap(tf1, tf2)
        self:addParamsWithKey("tf1中，LB牌组合的牌型 tf2", tf2)
        self.log("====tf1中，LB牌组合的牌型。假定是tf2牌型，tf2数量是：" .. #table.keys(tf2))
        local firstKeyMap
        if next(tf2) then
          self.log("=====【优先出的牌型】=tf2")
          firstKeyMap = tf2
          self:addResult("C52")
        end
        if firstKeyMap == nil then
          local tf9 = data:ai_liu_getMustLiuCKeyMap()
          tf9 = AiUtils:getSameKeyMap(tf1, tf9)
          self:addParamsWithKey("tf1中，LC牌组合的牌型 tf9", tf9)
          self.log("====tf1中，LC牌组合的牌型。假定是tf9牌型，tf9数量是：" .. #table.keys(tf9))
          if next(tf9) then
            self.log("=====【优先出的牌型】=tf9")
            firstKeyMap = tf9
            self:addResult("C55")
          else
            self.log("=====【优先出的牌型】=tf1")
            firstKeyMap = tf1
            self:addResult("C53")
          end
        end
        local enemyLiuKeyMap = enemyData:ai_liu_getLiuKeyMap()
        self:addParamsWithKey("对手L牌组合的牌型", enemyLiuKeyMap)
        local tf3 = AiUtils:getNotSameKeyMap(firstKeyMap, enemyLiuKeyMap)
        self:addParamsWithKey("【优先出的牌型】中，对手没有L牌组合的牌型 tf3", tf3)
        self.log("=====【优先出的牌型】中，对手没有L牌组合的牌型。假定是tf3牌型，tf3数量是：" .. #table.keys(tf3))
        if next(tf3) then
          do
            local f3 = AiUtils:filterSuitDataArrWithKeyMap(f1, tf3)
            self:addParamsWithKey("tf3牌型的F1牌组合", f3)
            self.log("======【优先出的牌组合列表】=tf3牌型的F1牌组合")
            self:setFirstSuitDataArr(f3)
            self:addResult("C531")
          end
        else
          local friendMaxSuitKeyMap = friendData:ai_all_getNotBombMaxSuitKeyMap()
          self:addParamsWithKey("队友有非炸弹最大牌（抢权最大牌、压制最大牌）的牌型", friendMaxSuitKeyMap)
          local tf4 = AiUtils:getSameKeyMap(firstKeyMap, friendMaxSuitKeyMap)
          self:addParamsWithKey("【优先出的牌型】中，队友有非炸弹最大牌（抢权最大牌、压制最大牌）的牌型 tf4", tf4)
          self.log("=====【优先出的牌型】中，队友有非炸弹最大牌（抢权最大牌、压制最大牌）的牌型。假定是tf4牌型，tf4数量是：" .. #table.keys(tf4))
          if next(tf4) then
            do
              local f4 = AiUtils:filterSuitDataArrWithKeyMap(f1, tf4)
              self:addParamsWithKey("tf4牌型的F1牌组合", f4)
              self.log("======【优先出的牌组合列表】=tf4牌型的F1牌组合")
              self:setFirstSuitDataArr(f4)
              self:addResult("C532")
            end
          else
            local betterThenEnemySuitKeyMap = data:ai_bestFenzu_getBetterThenEnemySuitKeyMap()
            self:addParamsWithKey("自己比对手优势的牌型", betterThenEnemySuitKeyMap)
            local tf5 = AiUtils:getSameKeyMap(firstKeyMap, betterThenEnemySuitKeyMap)
            self:addParamsWithKey("【优先出的牌型】中，自己比对手优势的牌型 tf5", tf5)
            self.log("=====【优先出的牌型】中，自己比对手优势的牌型。假定是tf5牌型，tf5数量是：" .. #table.keys(tf5))
            if next(tf5) then
              do
                local f5 = AiUtils:filterSuitDataArrWithKeyMap(f1, tf5)
                self:addParamsWithKey("tf5牌型的F1牌组合", f5)
                self.log("======【优先出的牌组合列表】=tf5牌型的F1牌组合")
                self:setFirstSuitDataArr(f5)
                self:addResult("C533")
              end
            else
              local firstLiuSuitDataArr = AiUtils:filterSuitDataArrWithKeyMap(f1, firstKeyMap)
              self:addParamsWithKey("【优先出的牌型】的F1牌组合", firstLiuSuitDataArr)
              self.log("======【优先出的牌组合列表】=【优先出的牌型】的F1牌组合")
              self:setFirstSuitDataArr(firstLiuSuitDataArr)
              self:addResult("C534")
            end
          end
        end
      end
    end
  end
  return self:getBaseActionSuitData()
end

-- 强AI·上家农民首出 · 获取extend赢牌/收官conditions（上家农民出牌-收官扩展）
function AiBestFarmerLeftStartData:getExtendWinConditions()
  self.log("==上家农民出牌-收官扩展")
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

-- 强AI·上家农民首出 · 获取extend赢牌/收官conditionsby牌型dataarr（上家农民出牌-收官扩展(四带X)）
function AiBestFarmerLeftStartData:getExtendWinConditionsBySuitDataArr(suitDataArr)
  self.log("==上家农民出牌-收官扩展(四带X)")
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

-- 强AI·上家农民首出 · 检查liu牌型判断是否all单张（上家农民-判断是否有溜牌且全是单张）
function AiBestFarmerLeftStartData:checkLiuSuitIsAllSingle()
  self.log("==上家农民-判断是否有溜牌且全是单张")
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

-- 强AI·上家农民首出 · 是否可单张收官（上家农民出牌-判断是否能单张收官）
function AiBestFarmerLeftStartData:enableSingleEnd()
  self.log("==上家农民出牌-判断是否能单张收官")
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

-- 强AI·上家农民首出 · 获取单张收官出牌动作牌型data（上家农民出牌-收官-单张出牌）
function AiBestFarmerLeftStartData:getSingleEndActionSuitData()
  self.log("==上家农民出牌-收官-单张出牌")
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

-- 强AI·上家农民首出 · 剩两张牌时的特殊出牌处理（上家农民出牌-只剩两手牌）
function AiBestFarmerLeftStartData:getLeftTwoSuitData()
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

return AiBestFarmerLeftStartData
