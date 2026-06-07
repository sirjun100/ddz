-- 文件: AiBestFenzu.lua · 反编译 AI 模块（阅读用）

local AiBestFenzu = class("AiBestFenzu")

-- AiBestFenzu · 构造函数
function AiBestFenzu:ctor(params)
  params = params or {}
  self.me = params.me
  self.enemy1 = params.enemy1
  self.enemy2 = params.enemy2
  self.friend = params.friend
  self.lazi = params.lazi
  self.lastSuitData = params.lastSuitData
  self.async = params.async
  self.allFenzu_ = params.allFenzu
  time0 = os.clock()
  local totalTime = time0
  self:initAllSuit()
  self.allSuitDeltaTime = os.clock() - time0
  time0 = os.clock()
  self:initSortMark()
  self.sortMarkDeltaTime = os.clock() - time0
  self:initTwoParams()
  time0 = os.clock()
  self:initAllFenzu()
  self.fenzuDeltaTime = os.clock() - time0
  time0 = os.clock()
  self:sortAllFenzuInfo()
  self.sortFenzuDeltaTime = os.clock() - time0
end

-- AiBestFenzu · 获取info
function AiBestFenzu:getInfo()
  local str = string.format(
    "initAllSuit：%f，initSortMark：%f，initAllFenzu：%f(getAllFenzu：%f)，sortAllFenzuInfo：%f，分组总时间：%f",
    self.allSuitDeltaTime,
    self.sortMarkDeltaTime,
    self.fenzuDeltaTime,
    self.fenzuDeltaTime2,
    self.sortFenzuDeltaTime,
    self.fenzuTotalTime
  )
  return str
end

-- AiBestFenzu · 返回最优分组信息
function AiBestFenzu:getBestFenzuInfo()
  local allFenzuInfo = self.allFenzuInfo
  return allFenzuInfo[1]
end

-- AiBestFenzu · 获取最强分组data
function AiBestFenzu:getBestFenzuData()
  local lastSuitData = self.lastSuitData
  local bestFenzuInfo = self:getBestFenzuInfo()
  local suitDataArr = self:doFenzu(bestFenzuInfo.suitDataArr, lastSuitData)
  local lun = bestFenzuInfo.lun
  local score = bestFenzuInfo.score
  local sortMark = self.sortMark
  for _, suitData in ipairs(suitDataArr) do
    local sortMarkKey = suitData:getSortMarkKey()
    local sortMark = self.sortMark[sortMarkKey]
    suitData:setBiggerCount(sortMark.biggerCount)
    suitData:setSmallerCount(sortMark.smallerCount)
    suitData:setEqualCount(sortMark.equalCount)
    suitData:setUseBombCount(sortMark.useBombCount)
  end
  local qiangQuanCount = self:suitDataArrDealForTwo(suitDataArr)
  local params = {
    suitDataArr = suitDataArr,
    sortMark = sortMark,
    lun = lun,
    score = score,
    qiangQuanCount = qiangQuanCount,
  }
  local ret = AiFenzuData.new(params)
  return ret
end

-- AiBestFenzu · 计算分组下的收官条件
function AiBestFenzu:getWinConditions()
  local map = {}
  local allFenzuInfo = self.allFenzuInfo
  for _, fenzuInfo in ipairs(allFenzuInfo) do
    local winConditions = fenzuInfo.winConditions
    if winConditions and 0 < #winConditions then
      for i, v in ipairs(winConditions) do
        map[v:getIdKey()] = v
      end
    end
  end
  local ret = table.values(map)
  return ret
end

-- AiBestFenzu · 深度筛选最优分组数据
function AiBestFenzu:getDeepBestFenzuData(params)
  local lastSuitData = params.lastSuitData
  local taskData = params.taskData
  local allFenzuInfo = self.allFenzuInfo
  local stepInfoList = allFenzuInfo
  local doLun = false
  do
    local allBombList = {}
    for _, fenzuInfo in ipairs(stepInfoList) do
      local suitDataArr = fenzuInfo.suitDataArr
      local isAllBomb = AiUtils:isAllBomb(suitDataArr)
      if isAllBomb then
        table.insert(allBombList, fenzuInfo)
      end
    end
    if 0 < #allBombList then
      stepInfoList = allBombList
      if #allBombList == 1 then
        goto lbl_279
      end
    end
    local enableWin = false
    local winInfoList = {}
    for _, fenzuInfo in ipairs(stepInfoList) do
      local suitDataArr = fenzuInfo.suitDataArr
      local winConditions = fenzuInfo.winConditions
      if winConditions and 0 < #winConditions then
        if lastSuitData then
          local ok = AiUtils:checkHasBiggerSuitData(winConditions, lastSuitData)
          if ok then
            table.insert(winInfoList, fenzuInfo)
          end
        else
          table.insert(winInfoList, fenzuInfo)
        end
      end
    end
    if 0 < #winInfoList then
      enableWin = true
      stepInfoList = winInfoList
    end
    local preventInfoList = {}
    for _, fenzuInfo in ipairs(stepInfoList) do
      local suitDataArr = fenzuInfo.suitDataArr
      local sum = #suitDataArr
      local misMatchWinConditionArr = self.enemy1:ai_filterMismatchWinCondition(suitDataArr)
      if sum - #misMatchWinConditionArr < 2 then
        if self.enemy2 then
          misMatchWinConditionArr = self.enemy2:ai_filterMismatchWinCondition(misMatchWinConditionArr)
          if sum - #misMatchWinConditionArr < 2 then
            table.insert(preventInfoList, fenzuInfo)
          end
        elseif lastSuitData == nil or AiUtils:checkHasBiggerSuitData(suitDataArr, lastSuitData) then
          table.insert(preventInfoList, fenzuInfo)
        end
      end
    end
    if 0 < #preventInfoList then
      stepInfoList = preventInfoList
    end
    if enableWin then
      do
        local maxBombInfoList = {}
        local maxBombCount = 0
        for _, fenzuInfo in ipairs(stepInfoList) do
          local suitDataArr = fenzuInfo.suitDataArr
          local bombArr = AiUtils:filterBomb(suitDataArr)
          if maxBombCount < #bombArr then
            maxBombCount = #bombArr
            maxBombInfoList = { fenzuInfo }
          elseif maxBombCount == #bombArr then
            table.insert(maxBombInfoList, fenzuInfo)
          end
        end
        if 0 < #maxBombInfoList then
          stepInfoList = maxBombInfoList
        end
        if taskData then
          local taskInfoList = {}
          for _, fenzuInfo in ipairs(stepInfoList) do
            local maybeLastSuitDataArr = fenzuInfo.maybeLastSuitDataArr
            local has = AiUtils:checkHasTaskSuitDataArr(maybeLastSuitDataArr, taskData)
            if has then
              table.insert(taskInfoList, fenzuInfo)
            end
          end
          if 0 < #taskInfoList then
            stepInfoList = taskInfoList
          end
        end
      end
    else
      local lunInfoList = {}
      doLun = true
      local minLun = 1000
      for _, fenzuInfo in ipairs(stepInfoList) do
        local lun = fenzuInfo.lun
        if minLun > lun then
          minLun = lun
          lunInfoList = { fenzuInfo }
        elseif lun == minLun then
          table.insert(lunInfoList, fenzuInfo)
        end
      end
      if 0 < #lunInfoList then
        stepInfoList = lunInfoList
      end
      if not enableWin then
        local maxBombInfoList = {}
        local maxBombCount = 0
        for _, fenzuInfo in ipairs(stepInfoList) do
          local suitDataArr = fenzuInfo.suitDataArr
          local bombArr = AiUtils:filterBomb(suitDataArr)
          if maxBombCount < #bombArr then
            maxBombCount = #bombArr
            maxBombInfoList = { fenzuInfo }
          elseif maxBombCount == #bombArr then
            table.insert(maxBombInfoList, fenzuInfo)
          end
        end
        if 0 < #maxBombInfoList then
          stepInfoList = maxBombInfoList
        end
      end
      if lastSuitData then
        local followInfoList = {}
        for _, fenzuInfo in ipairs(stepInfoList) do
          local suitDataArr = fenzuInfo.suitDataArr
          local has = AiUtils:checkHasBiggerSuitData(suitDataArr, lastSuitData)
          if has then
            table.insert(followInfoList, fenzuInfo)
          end
        end
        if 0 < #followInfoList then
          stepInfoList = followInfoList
        end
      end
    end
  end
  ::lbl_279::

  -- AiBestFenzu ·
  local function noBombIsWinLastSuitFunc(fenzuInfo)
    local suitDataArr = fenzuInfo.suitDataArr
    for _, suitData in ipairs(suitDataArr) do
      if
        suitData:getType() > SuitType.kBomb
        and suitData:getType() == lastSuitData:getType()
        and suitData:getLevel() > lastSuitData:getLevel()
      then
        return true
      end
    end
    return false
  end

  local bestFenzuInfo, fIsWin, bIsWin
  for _, fenzuInfo in ipairs(stepInfoList) do
    if bestFenzuInfo == nil then
      bestFenzuInfo = fenzuInfo
    elseif lastSuitData ~= nil then
      fIsWin = noBombIsWinLastSuitFunc(fenzuInfo)
      bIsWin = noBombIsWinLastSuitFunc(bestFenzuInfo)
      if not fIsWin and bIsWin then
      elseif #fenzuInfo.suitDataArr == #bestFenzuInfo.suitDataArr and fIsWin and not bIsWin then
        bestFenzuInfo = fenzuInfo
      elseif #fenzuInfo.suitDataArr < #bestFenzuInfo.suitDataArr then
        bestFenzuInfo = fenzuInfo
      end
    elseif #fenzuInfo.suitDataArr < #bestFenzuInfo.suitDataArr then
      bestFenzuInfo = fenzuInfo
    end
  end
  local suitDataArr = self:doFenzu(bestFenzuInfo.suitDataArr, lastSuitData)
  local lun = bestFenzuInfo.lun
  local score = bestFenzuInfo.score
  local sortMark = self.sortMark
  for _, suitData in ipairs(suitDataArr) do
    local sortMarkKey = suitData:getSortMarkKey()
    local sortMark = self.sortMark[sortMarkKey]
    suitData:setBiggerCount(sortMark.biggerCount)
    suitData:setSmallerCount(sortMark.smallerCount)
    suitData:setEqualCount(sortMark.equalCount)
    suitData:setUseBombCount(sortMark.useBombCount)
  end
  local qiangQuanCount = self:suitDataArrDealForTwo(suitDataArr)
  local params = {
    suitDataArr = suitDataArr,
    sortMark = sortMark,
    lun = lun,
    score = score,
    qiangQuanCount = qiangQuanCount,
  }
  local ret = AiFenzuData.new(params)
  return ret
end

-- AiBestFenzu · 是否允许跟牌（有能压过的牌）
function AiBestFenzu:enableFollow(fenzuInfo, lastSuitData)
  if lastSuitData == nil then
    return true
  end
  local suitDataArr = fenzuInfo.suitDataArr
  local mainSuitType, matchSuitType
  if lastSuitData.getSuitInfo then
    mainSuitType = lastSuitData:getSuitInfo().mainSuitType
    matchSuitType = lastSuitData:getSuitInfo().matchSuitType
  else
    mainSuitType = lastSuitData:getType()
  end
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() ~= mainSuitType or matchSuitType ~= nil or suitData then
    end
  end
end

-- AiBestFenzu · do分组
function AiBestFenzu:doFenzu(suitDataArr, lastSuitData)
  local ret = {}
  local lastSuitType
  if lastSuitData then
    lastSuitType = lastSuitData:getType()
  end
  local singleList = {}
  local pairList = {}
  local threeList = {}
  local threeStraightList = {}
  for i = #suitDataArr, 1, -1 do
    local aSuit = suitDataArr[i]
    local suitType = aSuit:getType()
    if suitType == SuitType.kSingle then
      table.insert(singleList, aSuit)
    elseif suitType == SuitType.kPair then
      table.insert(pairList, aSuit)
    elseif suitType == SuitType.kThree then
      table.insert(threeList, aSuit)
    elseif suitType == SuitType.kThreeStraight then
      table.insert(threeStraightList, aSuit)
    else
      table.insert(ret, aSuit)
    end
  end
  table.sort(singleList, function(aSuit, bSuit)
    return aSuit:getLevel() < bSuit:getLevel()
  end)
  table.sort(pairList, function(aSuit, bSuit)
    return aSuit:getLevel() < bSuit:getLevel()
  end)
  table.sort(threeList, function(aSuit, bSuit)
    return aSuit:getLevel() > bSuit:getLevel()
  end)
  table.sort(threeStraightList, function(aSuit, bSuit)
    return aSuit:getLevel() > bSuit:getLevel()
  end)
  if lastSuitType == SuitType.kThreeStraightWithPair or lastSuitType == SuitType.kThreeStraightWithSingle then
    if 0 < #threeStraightList then
      for i = #threeStraightList, 1, -1 do
        local aStraight = threeStraightList[i]
        local needCount = aStraight:getCardCount() / 3
        local singleCount = #singleList
        local pairCount = #pairList
        local suitList = {}
        local AiSuitThreeStraightWithData
        if lastSuitType == SuitType.kThreeStraightWithPair then
          if needCount <= pairCount then
            AiSuitThreeStraightWithData = AiSuitThreeStraightWithPairData
            for i = 1, needCount do
              local aPair = pairList[1]
              table.insert(suitList, aPair)
              table.remove(pairList, 1)
            end
          end
        elseif needCount <= singleCount then
          AiSuitThreeStraightWithData = AiSuitThreeStraightWithSingleData
          for i = 1, needCount do
            local aSingle = singleList[1]
            table.insert(suitList, aSingle)
            table.remove(singleList, 1)
          end
        elseif needCount <= singleCount + pairCount * 2 then
          AiSuitThreeStraightWithData = AiSuitThreeStraightWithSingleData
          local addCount = 0
          repeat
            local aSingle, aPair
            if 0 < #singleList then
              aSingle = singleList[1]
            end
            if 0 < #pairList then
              aPair = pairList[1]
            end
            if aSingle and aPair then
              if aPair:getLevel() > aSingle:getLevel() then
                aPair = nil
              else
                aSingle = nil
              end
            end
            if aPair then
              local suitData = AiSuitSingleData:createWithCardType(aPair:getLevel(), aPair:getLazi(), false)
              if needCount - addCount == 1 then
                table.insert(suitList, suitData)
                table.insert(singleList, suitData)
                addCount = addCount + 1
              else
                table.insert(suitList, suitData)
                table.insert(suitList, suitData)
                addCount = addCount + 2
              end
              table.remove(pairList, 1)
            elseif aSingle then
              table.insert(suitList, aSingle)
              table.remove(singleList, 1)
              addCount = addCount + 1
            else
              print("飞机配牌bug!!!")
              break
            end
          until needCount <= addCount or false
        end
        if 0 < #suitList and AiSuitThreeStraightWithData then
          table.insert(suitList, aStraight)
          local suit = AiSuitThreeStraightWithData:createWithSuitDataArrHasStraight(suitList)
          if suit then
            table.insert(ret, suit)
            table.remove(threeStraightList, i)
          end
        else
          break
        end
      end
    end
  elseif
    (lastSuitType == SuitType.kThreeWithOnePair or lastSuitType == SuitType.kThreeWithOneSingle) and 0 < #threeList
  then
    local threeCount = #threeList
    for i = threeCount, 1, -1 do
      local aThree = threeList[i]
      local aPair, aSingle
      if aThree:getLevel() > lastSuitData:getLevel() then
        if lastSuitType == SuitType.kThreeWithOnePair then
          aPair = pairList[1]
        else
          if #singleList == 0 and i == threeCount and 0 < #pairList then
            local chaiPair = pairList[1]
            local suitData = AiSuitSingleData:createWithCardType(chaiPair:getLevel(), chaiPair:getLazi(), false)
            table.insert(singleList, suitData)
            table.insert(singleList, suitData)
            table.remove(pairList, 1)
          end
          aSingle = singleList[1]
        end
        if aPair then
          local suit = AiSuitThreeWithOnePairData:createWithSuitDataArr({ aThree, aPair })
          if suit then
            table.insert(ret, suit)
            table.remove(threeList, i)
            table.remove(pairList, 1)
            break
          end
        elseif aSingle then
          local suit = AiSuitThreeWithOneSingleData:createWithSuitDataArr({ aThree, aSingle })
          if suit then
            table.insert(ret, suit)
            table.remove(threeList, i)
            table.remove(singleList, 1)
            break
          end
        else
          break
        end
      end
    end
  end
  local singleCardTypeList = {}
  for _, suitData in ipairs(singleList) do
    table.insert(singleCardTypeList, suitData:getLevel())
  end
  local singleLun = self:getSingleLun(singleCardTypeList, false)
  local pairLun = 0
  local sortMark = self.sortMark
  for _, suitData in ipairs(pairList) do
    local sortMarkKey = suitData:getSortMarkKey()
    local biggerCount = sortMark[sortMarkKey].biggerCount
    if biggerCount == 0 then
      pairLun = pairLun - 1
    else
      pairLun = pairLun + 1
    end
  end
  if 0 < #threeStraightList then
    for i = #threeStraightList, 1, -1 do
      local aStraight = threeStraightList[i]
      local needCount = aStraight:getCardCount() / 3
      local singleCount = #singleList
      local pairCount = #pairList
      local suitList = {}
      local firstWithType
      if 0 < pairCount and singleLun < pairLun then
        firstWithType = SuitType.kPair
      elseif 0 < singleCount and singleLun > pairLun then
        firstWithType = SuitType.kSingle
      elseif singleCount < pairCount then
        firstWithType = SuitType.kPair
      elseif singleCount > pairCount then
        firstWithType = SuitType.kSingle
      elseif 0 < pairCount and 0 < singleCount then
        if singleList[1]:getLevel() <= pairList[1]:getLevel() then
          firstWithType = SuitType.kSingle
        else
          firstWithType = SuitType.kPair
        end
      else
        firstWithType = nil
      end
      local AiSuitThreeStraightWithData
      if needCount <= pairCount and firstWithType == SuitType.kPair then
        AiSuitThreeStraightWithData = AiSuitThreeStraightWithPairData
        for i = 1, needCount do
          local aPair = pairList[1]
          table.insert(suitList, aPair)
          table.remove(pairList, 1)
          pairLun = pairLun - 1
        end
      elseif needCount <= singleCount then
        AiSuitThreeStraightWithData = AiSuitThreeStraightWithSingleData
        for i = 1, needCount do
          local aSingle = singleList[1]
          table.insert(suitList, aSingle)
          table.remove(singleList, 1)
          singleLun = singleLun - 1
        end
      elseif needCount <= singleCount + pairCount * 2 then
        AiSuitThreeStraightWithData = AiSuitThreeStraightWithSingleData
        local addCount = 0
        repeat
          local aSingle, aPair
          if 0 < #singleList then
            aSingle = singleList[1]
          end
          if 0 < #pairList then
            aPair = pairList[1]
          end
          if aSingle and aPair then
            if aPair:getLevel() > aSingle:getLevel() then
              aPair = nil
            else
              aSingle = nil
            end
          end
          if aPair then
            local suitData = AiSuitSingleData:createWithCardType(aPair:getLevel(), aPair:getLazi(), false)
            if needCount - addCount == 1 then
              table.insert(suitList, suitData)
              table.insert(singleList, suitData)
              addCount = addCount + 1
              singleLun = singleLun + 1
            else
              table.insert(suitList, suitData)
              table.insert(suitList, suitData)
              addCount = addCount + 2
            end
            table.remove(pairList, 1)
            pairLun = pairLun - 1
          elseif aSingle then
            table.insert(suitList, aSingle)
            table.remove(singleList, 1)
            addCount = addCount + 1
            singleLun = singleLun - 1
          else
            break
          end
        until needCount <= addCount or false
      end
      if 0 < #suitList and AiSuitThreeStraightWithData then
        table.insert(suitList, aStraight)
        local suit = AiSuitThreeStraightWithData:createWithSuitDataArrHasStraight(suitList)
        if suit then
          table.insert(ret, suit)
          table.remove(threeStraightList, i)
        end
      end
    end
  end
  if 0 < #threeList then
    for i = #threeList, 1, -1 do
      local aThree = threeList[i]
      local singleCount = #singleList
      local pairCount = #pairList
      local aPair, aSingle, firstWithType
      if 0 < pairCount and pairLun > singleLun then
        firstWithType = SuitType.kPair
      elseif 0 < singleCount and pairLun < singleLun then
        firstWithType = SuitType.kSingle
      elseif singleCount < pairCount then
        firstWithType = SuitType.kPair
      elseif singleCount > pairCount then
        firstWithType = SuitType.kSingle
      elseif 0 < pairCount and 0 < singleCount then
        if singleList[1]:getLevel() <= pairList[1]:getLevel() then
          firstWithType = SuitType.kSingle
        else
          firstWithType = SuitType.kPair
        end
      else
        firstWithType = nil
      end
      if 0 < pairCount then
        aPair = pairList[1]
      end
      if 0 < singleCount then
        aSingle = singleList[1]
      end
      if aPair and aSingle then
        if firstWithType == SuitType.kPair then
          aSingle = nil
        elseif firstWithType == SuitType.kSingle then
          aPair = nil
        elseif aPair:getLevel() > aSingle:getLevel() then
          aPair = nil
        else
          aSingle = nil
        end
      end
      if aPair then
        local suit = AiSuitThreeWithOnePairData:createWithSuitDataArr({ aThree, aPair })
        if suit then
          table.insert(ret, suit)
          table.remove(threeList, i)
          table.remove(pairList, 1)
          pairLun = pairLun - 1
        end
      elseif aSingle then
        local suit = AiSuitThreeWithOneSingleData:createWithSuitDataArr({ aThree, aSingle })
        if suit then
          table.insert(ret, suit)
          table.remove(threeList, i)
          table.remove(singleList, 1)
          singleLun = singleLun - 1
        end
      else
        break
      end
    end
  end
  if 0 < #singleList then
    for _, aSuit in ipairs(singleList) do
      table.insert(ret, aSuit)
    end
  end
  if 0 < #pairList then
    for _, aSuit in ipairs(pairList) do
      table.insert(ret, aSuit)
    end
  end
  if 0 < #threeList then
    for _, aSuit in ipairs(threeList) do
      table.insert(ret, aSuit)
    end
  end
  if 0 < #threeStraightList then
    for _, aSuit in ipairs(threeStraightList) do
      table.insert(ret, aSuit)
    end
  end
  return ret
end

-- AiBestFenzu · 初始化手牌全部合法牌型
function AiBestFenzu:initAllSuit()
  if self.me then
    self.meAllSuitData = self.me:getAllSuitData()
    table.sort(self.meAllSuitData, function(a, b)
      if a:getType() == SuitType.kDoubleJoker then
        return false
      end
      if b:getType() == SuitType.kDoubleJoker then
        return true
      end
      if a:getType() == SuitType.kBomb and b:getType() ~= SuitType.kBomb then
        return false
      elseif a:getType() ~= SuitType.kBomb and b:getType() == SuitType.kBomb then
        return true
      else
        return a:getCardCount() < b:getCardCount()
      end
    end)
    self.singleMap = {}
    self.pairMap = {}
    for _, suitData in ipairs(self.meAllSuitData) do
      local suitType = suitData:getType()
      if suitType == SuitType.kSingle then
        self.singleMap[suitData:getLevel()] = suitData
      elseif suitType == SuitType.kPair then
        self.pairMap[suitData:getLevel()] = suitData
      end
    end
    self.meAllBringSuitData = {}
    table.insertto(self.meAllBringSuitData, self.meAllSuitData)
    local bringSuitDataArr = AiUtils:bringSuitDataArr(self.meAllBringSuitData, self.me, nil, self.async)
    table.insertto(self.meAllBringSuitData, bringSuitDataArr)
  end
  if self.enemy1 then
    self.enemy1AllSuitData = {}
    table.insertto(self.enemy1AllSuitData, self.enemy1:getAllSuitData())
    local bringSuitDataArr = AiUtils:bringSuitDataArr(self.enemy1AllSuitData, self.enemy1, nil, self.async)
    table.insertto(self.enemy1AllSuitData, bringSuitDataArr)
  end
  if self.enemy2 then
    self.enemy2AllSuitData = {}
    table.insertto(self.enemy2AllSuitData, self.enemy2:getAllSuitData())
    local bringSuitDataArr = AiUtils:bringSuitDataArr(self.enemy2AllSuitData, self.enemy2, nil, self.async)
    table.insertto(self.enemy2AllSuitData, bringSuitDataArr)
  end
end

-- AiBestFenzu · 初始化牌型大小标记与炸弹消耗标记
function AiBestFenzu:initSortMark()
  self.sortMark = self:getSuitDataSortMark(self.meAllBringSuitData, self.enemy1AllSuitData, self.enemy2AllSuitData)
end

-- AiBestFenzu · 生成所有拆牌分组方案
function AiBestFenzu:initAllFenzu()
  self.allFenzuInfo = {}
  self.fenzuTimes = 0
  self.maxFenzuTimes = 1000
  local allFenzu, flag
  if self.allFenzu_ ~= nil then
    self.allFenzu_ = AiUtils:clearAllFenzuInfo(self.allFenzu_)
    allFenzu = self.allFenzu_
    self.fenzuDeltaTime2 = 0
  end
  if allFenzu == nil then
    flag, allFenzu = self:getAllFenzu(self.me, self.meAllSuitData)
    allFenzu = allFenzu or {}
    if self.async then
      coroutine.yield()
    end
  end
  local hasOneSuit = false
  for _, fenzu in ipairs(allFenzu) do
    if #fenzu == 1 then
      hasOneSuit = true
    end
  end
  if not hasOneSuit then
    local suitData = self.me:toSuit()
    if suitData then
      local lastSuitData = self.lastSuitData
      if
        (lastSuitData == nil or self.me:getUid() == lastSuitData:getUid() or suitData:isWin(lastSuitData))
        and not AiUtils:checkNotBombSuitDataHasBomb(suitData)
      then
        suitData.isToSuit = true
        table.insert(allFenzu, { suitData })
      else
      end
    end
  end
  self.allFenzu_ = allFenzu
  local enemyBombArr, clear1
  if self.enemy1 then
    clear1 = self.enemy1:toSuit(nil, nil)
    local enemyBombArr1 = self.enemy1:getAllBombForMaxCount()
    enemyBombArr = {}
    table.insertto(enemyBombArr, enemyBombArr1)
  end
  local clear2
  if self.enemy2 then
    clear2 = self.enemy2:toSuit(nil, nil)
    local enemyBombArr2 = self.enemy2:getAllBombForMaxCount()
    table.insertto(enemyBombArr, enemyBombArr2)
  end
  local count = 0
  for _, fenzu in ipairs(allFenzu) do
    local fenzuInfo, lun = self:getFenzuInfo(fenzu, clear1, clear2, enemyBombArr)
    table.insert(self.allFenzuInfo, fenzuInfo)
    if lun <= 3 then
      count = count + 1
      if self.async and count % 5 == 0 then
        coroutine.yield()
      end
    end
  end
end

-- AiBestFenzu · 对分组按轮次 lun、得分排序
function AiBestFenzu:sortAllFenzuInfo()
  local lastSuitData = self.lastSuitData
  local bombCardTypeList = {}
  local haveBomb = false
  for _, suitData in ipairs(self.meAllSuitData) do
    if suitData:getType() <= SuitType.kBomb then
      bombCardTypeList[suitData:getLevel()] = true
      haveBomb = true
    end
  end
  if lastSuitData ~= nil then
    local suitDataArr
    for _, fenzuInfo in ipairs(self.allFenzuInfo) do
      suitDataArr = fenzuInfo.suitDataArr
      fenzuInfo.noBombIsWin = nil
      for _, suitData in ipairs(suitDataArr) do
        if
          suitData:getType() > SuitType.kBomb
          and suitData:getType() == lastSuitData:getType()
          and suitData:getLevel() > lastSuitData:getLevel()
        then
          if not haveBomb then
            fenzuInfo.noBombIsWin = true
            break
          end
          local isUseBomb = false
          local needCardCountList = suitData:getNeedCardCountList()
          for cardType, num in pairs(needCardCountList) do
            if bombCardTypeList[cardType] then
              isUseBomb = true
              break
            end
          end
          if not isUseBomb then
            fenzuInfo.noBombIsWin = true
            break
          end
        end
      end
    end
  end
  if self.async then
    coroutine.yield()
  end
  local aIsWin, bIsWin
  table.sort(self.allFenzuInfo, function(a, b)
    if a.lun == b.lun then
      if lastSuitData ~= nil then
        aIsWin = a.noBombIsWin
        bIsWin = b.noBombIsWin
        if aIsWin and not bIsWin then
          return true
        elseif bIsWin and not aIsWin then
          return false
        else
          return a.score > b.score
        end
      else
        return a.score > b.score
      end
    else
      return a.lun < b.lun
    end
  end)
end

-- AiBestFenzu · 初始化twoparams
function AiBestFenzu:initTwoParams()
  self.needDealQiangQuan = false
  self.qiangQuanDelta = 0
  self.qiangQuanMinTwoCount = 0
  local twoSortKey = "17-15-1"
  local sortMark = self.sortMark[twoSortKey]
  if sortMark and sortMark.biggerCount and 0 < sortMark.biggerCount then
    self.needDealQiangQuan = true
    local me = self.me
    local enemy1 = self.enemy1
    local enemy2 = self.enemy2
    local meTwoCount = 0
    local meHasLittleJoker = false
    local meHasBigJoker = false
    if me then
      meTwoCount = me:getCardCountWithType(CardType.kTwo)
      meHasLittleJoker = 0 < me:getCardCountWithType(CardType.kLittleJoker)
      meHasBigJoker = 0 < me:getCardCountWithType(CardType.kBigJoker)
    end
    local enemy1HasLittleJoker = false
    local enemy1HasBigJoker = false
    local enemy1HasLittleJoker = false
    local enemy1HasDoubleJoker = false
    if enemy1 then
      enemy1HasLittleJoker = 0 < enemy1:getCardCountWithType(CardType.kLittleJoker)
      enemy1HasBigJoker = 0 < enemy1:getCardCountWithType(CardType.kBigJoker)
      if enemy1HasLittleJoker and enemy1HasBigJoker then
        enemy1HasDoubleJoker = true
      end
    end
    local enemy2HasLittleJoker = false
    local enemy2HasBigJoker = false
    local enemy2HasLittleJoker = false
    local enemy2HasDoubleJoker = false
    if enemy2 then
      enemy2HasLittleJoker = 0 < enemy2:getCardCountWithType(CardType.kLittleJoker)
      enemy2HasBigJoker = 0 < enemy2:getCardCountWithType(CardType.kBigJoker)
      if enemy2HasLittleJoker and enemy2HasBigJoker then
        enemy2HasDoubleJoker = true
      end
    end
    local enemyHasDoubleJoker = enemy1HasDoubleJoker or enemy2HasDoubleJoker
    local enemyJokerCount = 0
    enemyHasLittleJoker = enemy1HasLittleJoker or enemy2HasLittleJoker
    if enemyHasLittleJoker then
      enemyJokerCount = enemyJokerCount + 1
    end
    enemyHasBigJoker = enemy1HasBigJoker or enemy2HasBigJoker
    if enemyHasBigJoker then
      enemyJokerCount = enemyJokerCount + 1
    end
    if enemyHasDoubleJoker then
      self.qiangQuanDelta = 0
      self.qiangQuanMinTwoCount = 1
    elseif not meHasLittleJoker and not meHasBigJoker then
      self.qiangQuanDelta = enemyJokerCount
      self.qiangQuanMinTwoCount = enemyJokerCount + 1
    elseif meHasBigJoker then
      self.qiangQuanDelta = 1
      self.qiangQuanMinTwoCount = 2
    elseif meHasLittleJoker then
      self.qiangQuanDelta = 0
      self.qiangQuanMinTwoCount = 2
    end
    if meTwoCount <= self.qiangQuanDelta then
      self.needDealQiangQuan = false
    end
  end
end

-- AiBestFenzu · 获取分组info
function AiBestFenzu:getFenzuInfo(suitDataArr, clear1, clear2, enemyBombArr)
  local sortMark = self.sortMark
  local lastSuitData = self.lastSuitData
  local lun = 0
  local score = 0
  local doubleJokerCount = 0
  local bombCount = 0
  local threeStraightCount = 0
  local threeCount = 0
  local doubleCount = 0
  local singleCount = 0
  local needMergeSuit = {}
  local countMap = {}
  local singleCardTypeList = {}
  for i, suitData in ipairs(suitDataArr) do
    if suitData:getType() == SuitType.kSingle then
      table.insert(singleCardTypeList, suitData:getLevel())
    end
    local sortMarkKey = suitData:getSortMarkKey()
    if sortMark[sortMarkKey] then
      if suitData:getType() == SuitType.kDoubleJoker then
        doubleJokerCount = doubleJokerCount + 1
      elseif suitData:getType() == SuitType.kBomb then
        bombCount = bombCount + 1
      elseif suitData:getType() == SuitType.kThree then
        threeCount = threeCount + 1
      elseif suitData:getType() == SuitType.kThreeStraight then
        threeCount = threeCount + suitData:getLevelCount()
      end
      if suitData:getType() ~= SuitType.kDoubleJoker and suitData:getType() ~= SuitType.kBomb then
        local suitKey = suitData:getKey()
        if countMap[suitKey] == nil then
          countMap[suitKey] = { maxCount = 0, minCount = 0 }
        end
        local biggerCount = sortMark[sortMarkKey].biggerCount
        if biggerCount == 0 then
          countMap[suitKey].maxCount = countMap[suitKey].maxCount + 1
        else
          countMap[suitKey].minCount = countMap[suitKey].minCount + 1
        end
      end
    end
    score = score + suitData:getScore()
  end
  for suitKey, tab in pairs(countMap) do
    local maxCount = tab.maxCount
    local minCount = tab.minCount
    local count = math.max(0, minCount - maxCount)
    if suitKey == "16-2" then
      doubleCount = count
      lun = lun + count
    elseif suitKey == "17-1" then
    else
      lun = lun + count
    end
  end
  singleCount = self:getSingleLun(singleCardTypeList, false)
  if 0 < singleCount then
    lun = lun + singleCount
  end
  local deltaLun = 0
  if 0 < threeCount then
    if threeCount > singleCount then
      deltaLun = deltaLun + singleCount
      threeCount = threeCount - singleCount
      singleCount = 0
    else
      deltaLun = deltaLun + threeCount
      threeCount = 0
      singleCount = singleCount - threeCount
    end
  end
  if 0 < threeCount then
    if doubleCount < threeCount then
      deltaLun = deltaLun + doubleCount
      threeCount = threeCount - doubleCount
      doubleCount = 0
    else
      deltaLun = deltaLun + threeCount
      threeCount = 0
      doubleCount = doubleCount - threeCount
    end
  end
  lun = math.max(0, lun - bombCount - doubleJokerCount - deltaLun)
  if lun == 0 then
    lun = -bombCount - doubleJokerCount
  end
  local winConditions, maybeLastSuitDataArr
  if lun <= 3 then
    suitDataArr = self:doFenzu(suitDataArr, lastSuitData)
    for _, suitData in ipairs(suitDataArr) do
      local sortMarkKey = suitData:getSortMarkKey()
      local sortMark = self.sortMark[sortMarkKey]
      suitData:setBiggerCount(sortMark.biggerCount)
      suitData:setSmallerCount(sortMark.smallerCount)
      suitData:setEqualCount(sortMark.equalCount)
      suitData:setUseBombCount(sortMark.useBombCount)
    end
    winConditions, maybeLastSuitDataArr =
      AiUtils:getWinConditions(self.me, suitDataArr, lastSuitData, clear1, clear2, enemyBombArr)
  else
    for _, suitData in ipairs(suitDataArr) do
      local sortMarkKey = suitData:getSortMarkKey()
      local sortMark = self.sortMark[sortMarkKey]
      suitData:setBiggerCount(sortMark.biggerCount)
      suitData:setSmallerCount(sortMark.smallerCount)
      suitData:setEqualCount(sortMark.equalCount)
      suitData:setUseBombCount(sortMark.useBombCount)
    end
  end
  local ret = {
    suitDataArr = suitDataArr,
    lun = lun,
    score = score,
    winConditions = winConditions,
    maybeLastSuitDataArr = maybeLastSuitDataArr,
  }
  return ret, lun
end

-- AiBestFenzu · 获取单张轮次
function AiBestFenzu:getSingleLun(cardTypeList, didSort)
  if cardTypeList == nil or #cardTypeList == 0 then
    return 0
  end
  if not didSort then
    table.sort(cardTypeList, function(a, b)
      return b < a
    end)
  end
  local enemysCardTypeList = self:getEnemysCardTypeList()
  local lun, minCount, cantBringCardType = AiUtils:bestCalculateLun(cardTypeList, enemysCardTypeList)
  if lun == #cardTypeList then
    local needDealQiangQuan = self.needDealQiangQuan
    if needDealQiangQuan then
      local qiangQuanDelta = self.qiangQuanDelta
      local maybeQiangQuanCount = 0
      for _, cardType in ipairs(cardTypeList) do
        if cardType == CardType.kTwo then
          maybeQiangQuanCount = maybeQiangQuanCount + 1
        end
      end
      local qiangQuanCount = maybeQiangQuanCount - qiangQuanDelta
      if 0 < qiangQuanCount then
        lun = lun - qiangQuanCount * 2
      end
    end
  end
  local enemy1LeftCardType, enemy2LeftCardType = 0, 0
  local leftCardType
  if self.enemy1 and self.enemy1:getCardCount() == 1 then
    local enemyCardType = self.enemy1:getCardTypeList()
    enemy1LeftCardType = enemyCardType[1]
  end
  if self.enemy2 and self.enemy2:getCardCount() == 1 then
    local enemyCardType = self.enemy2:getCardTypeList()
    enemy2LeftCardType = enemyCardType[1]
  end
  leftCardType = enemy1LeftCardType >= enemy2LeftCardType and enemy1LeftCardType or enemy2LeftCardType
  if leftCardType ~= 0 and cantBringCardType ~= nil and cantBringCardType < leftCardType then
    local correctLun = AiUtils:correctSingleLun(cardTypeList, leftCardType)
    lun = correctLun
  end
  lun = math.max(0, lun)
  return lun
end

-- AiBestFenzu · 获取enemys牌typelist
function AiBestFenzu:getEnemysCardTypeList()
  if self.enemysCardTypeList_ == nil then
    local ret = {}
    if self.enemy1 then
      table.insertto(ret, self.enemy1:getCardTypeList())
    end
    if self.enemy2 then
      table.insertto(ret, self.enemy2:getCardTypeList())
    end
    table.sort(ret, function(a, b)
      return b < a
    end)
    self.enemysCardTypeList_ = ret
  end
  return self.enemysCardTypeList_
end

-- AiBestFenzu · 获取all分组
function AiBestFenzu:getAllFenzu(cardTypeListData, suitDataArr)
  local cardCount = cardTypeListData:getCardCount()
  if cardCount == 0 then
    return true, {}
  end
  if 0 < cardCount and #suitDataArr == 0 then
    return false, {}
  end
  if self.fenzuTimes > self.maxFenzuTimes then
    return false, {}
  end
  local tmpSuitDataArr = {}
  table.insertto(tmpSuitDataArr, suitDataArr)
  local ok = false
  local ret = {}
  local laziCount = cardTypeListData:getLaziCount()
  for index = #tmpSuitDataArr, 1, -1 do
    self.fenzuTimes = self.fenzuTimes + 1
    if self.fenzuTimes % 50 == 0 and self.async then
      coroutine.yield()
    end
    local suitData = tmpSuitDataArr[index]
    remove = false
    if suitData:getCardCount() == 1 then
      local cardTypeList = cardTypeListData:getCardTypeList()
      local list = self:getAllSingleSuitData(cardTypeList)
      if list and 0 < #list then
        table.insert(ret, list)
      end
      break
    elseif suitData:getType() ~= SuitType.kDoubleJoker and suitData:getCardCount() == 2 and laziCount == 0 then
      local cardTypeCountMap = cardTypeListData:getCardTypeCountMap()
      local arr = self:fun(cardTypeCountMap)
      if arr and 0 < #arr then
        table.insertto(ret, arr)
      end
      break
    elseif cardCount >= suitData:getCardCount() then
      local didRemove, removeCountMap = cardTypeListData:removeCardTypeWithSuitData(suitData)
      if didRemove then
        if suitData:getCardCount() > 1 and suitData:getType() ~= SuitType.kStraight then
          table.remove(tmpSuitDataArr, index)
          remove = true
        end
        local tmpOk, allFenzu = self:getAllFenzu(cardTypeListData, tmpSuitDataArr)
        if tmpOk then
          if #allFenzu == 0 then
            table.insert(ret, { suitData })
          else
            for _, list in ipairs(allFenzu) do
              table.insert(list, suitData)
              table.insert(ret, list)
            end
          end
        end
        cardTypeListData:addCardTypeWithMap(removeCountMap)
      end
    end
    if not remove then
      table.remove(tmpSuitDataArr, index)
    end
  end
  ok = 0 < #ret
  return ok, ret
end

-- AiBestFenzu · fun
function AiBestFenzu:fun(cardTypeCountMap)
  local cardTypeList1 = {}
  local cardTypeList2 = {}
  local cardTypeList3 = {}
  local cardTypeList4 = {}
  for cardType = 3, 17 do
    local cardCount = cardTypeCountMap[cardType]
    if cardCount == 1 then
      table.insert(cardTypeList1, cardType)
    elseif cardCount == 2 then
      table.insert(cardTypeList2, cardType)
    elseif cardCount == 3 then
      table.insert(cardTypeList3, cardType)
    elseif cardCount == 4 then
      table.insert(cardTypeList4, cardType)
    end
  end
  if #cardTypeList4 == 0 and #cardTypeList3 == 0 and #cardTypeList2 == 0 then
    local singleSuitDataArr = self:getAllSingleSuitData(cardTypeList1)
    return { singleSuitDataArr }
  end
  local sortMark = self.sortMark
  if 0 < #cardTypeList4 then
    local mustWorse = false
    for _, cardType in ipairs(cardTypeList4) do
      local pairSortMarkKey = string.format("16-%d-1", cardType)
      if cardType ~= CardType.kTwo and 0 < sortMark[pairSortMarkKey].biggerCount then
        mustWorse = true
        break
      end
    end
    if mustWorse then
      return nil
    end
  end
  if 0 < #cardTypeList3 then
    local mustWorse = false
    for _, cardType in ipairs(cardTypeList3) do
      local pairSortMarkKey = string.format("16-%d-1", cardType)
      if cardType ~= CardType.kTwo and 0 < sortMark[pairSortMarkKey].biggerCount then
        mustWorse = true
        break
      end
    end
    if mustWorse then
      return nil
    end
  end
  local biggerSingleCount = 0
  local smallerSingleCount = 0
  local singleSuitDataArr = self:getAllSingleSuitData(cardTypeList1)
  if 0 < #singleSuitDataArr then
    for _, suitData in ipairs(singleSuitDataArr) do
      local sortMarkKey = suitData:getSortMarkKey()
      if 0 < sortMark[sortMarkKey].biggerCount then
        smallerSingleCount = smallerSingleCount + 1
      else
        biggerSingleCount = biggerSingleCount + 1
      end
    end
  end
  local biggerPairCount = 0
  local smallerPairCount = 0
  local biggerPairCount_21 = 0
  local smallerPairCount_21 = 0
  local pairSuitDataArr = self:getAllPairSuitData(cardTypeList2)
  if 0 < #pairSuitDataArr then
    for _, suitData in ipairs(pairSuitDataArr) do
      local sortMarkKey = string.format("17-%d-1", suitData:getLevel())
      if 0 < sortMark[sortMarkKey].biggerCount then
        smallerPairCount_21 = smallerPairCount_21 + 1
      else
        biggerPairCount_21 = biggerPairCount_21 + 1
      end
      local sortMarkKey = suitData:getSortMarkKey()
      if 0 < sortMark[sortMarkKey].biggerCount then
        smallerPairCount = smallerPairCount + 1
      else
        biggerPairCount = biggerPairCount + 1
      end
    end
  end
  if 0 < #cardTypeList3 then
    local single = self:getAllSingleSuitData(cardTypeList3)
    local pair = self:getAllPairSuitData(cardTypeList3)
    table.insertto(singleSuitDataArr, single)
    table.insertto(pairSuitDataArr, pair)
    for _, cardType in ipairs(cardTypeList3) do
      local sortMarkKey = string.format("17-%d-1", cardType)
      if 0 < sortMark[sortMarkKey].biggerCount then
        smallerSingleCount = smallerSingleCount + 1
        smallerPairCount_21 = smallerPairCount_21 + 1
      else
        biggerSingleCount = biggerSingleCount + 1
        biggerPairCount_21 = biggerPairCount_21 + 1
      end
    end
    biggerPairCount = biggerPairCount + #pair
  end
  if 0 < #cardTypeList4 then
    local pair = self:getAllPairSuitData(cardTypeList4)
    table.insertto(pairSuitDataArr, pair)
    table.insertto(pairSuitDataArr, pair)
    biggerPairCount = biggerPairCount + #pair * 2
    for _, cardType in ipairs(cardTypeList4) do
      local sortMarkKey = string.format("17-%d-1", cardType)
      if 0 < sortMark[sortMarkKey].biggerCount then
        smallerPairCount_21 = smallerPairCount_21 + 2
      else
        biggerPairCount_21 = biggerPairCount_21 + 2
      end
    end
  end
  local ret = {}
  local singleLun = math.max(0, smallerSingleCount - biggerSingleCount)
  local pairLun = math.max(0, smallerPairCount - biggerPairCount)
  if 0 < singleLun then
    local maxChaiCount = math.floor(singleLun / 2 + 0.5)
    local chaiCount = math.min(biggerPairCount_21, maxChaiCount)
    if chaiCount == 0 then
      chaiCount = 1
    end
    if 1 < chaiCount then
      local pairCount = #pairSuitDataArr
      for i = pairCount, pairCount - chaiCount + 2, -1 do
        local suitData = pairSuitDataArr[i]
        local single = self.singleMap[suitData:getLevel()]
        table.insert(singleSuitDataArr, single)
        table.insert(singleSuitDataArr, single)
        table.remove(pairSuitDataArr, i)
      end
    end
    local tmp = {}
    table.insertto(tmp, singleSuitDataArr)
    table.insertto(tmp, pairSuitDataArr)
    table.insert(ret, tmp)
    local suitData = pairSuitDataArr[#pairSuitDataArr]
    local single = self.singleMap[suitData:getLevel()]
    table.insert(singleSuitDataArr, single)
    table.insert(singleSuitDataArr, single)
    table.remove(pairSuitDataArr, #pairSuitDataArr)
    local tmp = {}
    table.insertto(tmp, singleSuitDataArr)
    table.insertto(tmp, pairSuitDataArr)
    table.insert(ret, tmp)
  else
    local remainBiggerSingleCount = biggerSingleCount - smallerSingleCount
    if 0 < remainBiggerSingleCount and 0 < pairLun then
      local maxChaiCount = math.floor(remainBiggerSingleCount / 2)
      local chaiCount = math.min(pairLun, maxChaiCount)
      if chaiCount == 0 then
        chaiCount = 1
      end
      if 1 < chaiCount then
        for i = chaiCount - 1, 1, -1 do
          local suitData = pairSuitDataArr[i]
          local single = self.singleMap[suitData:getLevel()]
          table.insert(singleSuitDataArr, single)
          table.insert(singleSuitDataArr, single)
          table.remove(pairSuitDataArr, i)
        end
      end
      local tmp = {}
      table.insertto(tmp, singleSuitDataArr)
      table.insertto(tmp, pairSuitDataArr)
      table.insert(ret, tmp)
      local suitData = pairSuitDataArr[1]
      local single = self.singleMap[suitData:getLevel()]
      table.insert(singleSuitDataArr, single)
      table.insert(singleSuitDataArr, single)
      table.remove(pairSuitDataArr, 1)
      local tmp = {}
      table.insertto(tmp, singleSuitDataArr)
      table.insertto(tmp, pairSuitDataArr)
      table.insert(ret, tmp)
    else
      local tmp = {}
      table.insertto(tmp, singleSuitDataArr)
      table.insertto(tmp, pairSuitDataArr)
      table.insert(ret, tmp)
      local suitData = pairSuitDataArr[#pairSuitDataArr]
      local single = self.singleMap[suitData:getLevel()]
      table.insert(singleSuitDataArr, single)
      table.insert(singleSuitDataArr, single)
      table.remove(pairSuitDataArr, #pairSuitDataArr)
      local tmp = {}
      table.insertto(tmp, singleSuitDataArr)
      table.insertto(tmp, pairSuitDataArr)
      table.insert(ret, tmp)
    end
  end
  return ret
end

-- AiBestFenzu · 获取all单张牌型data
function AiBestFenzu:getAllSingleSuitData(cardTypeList)
  local ret = {}
  for _, cardType in ipairs(cardTypeList) do
    local suitData = self.singleMap[cardType]
    table.insert(ret, suitData)
  end
  return ret
end

-- AiBestFenzu · 获取all对子牌型data
function AiBestFenzu:getAllPairSuitData(cardTypeList)
  local ret = {}
  for _, cardType in ipairs(cardTypeList) do
    local suitData = self.pairMap[cardType]
    table.insert(ret, suitData)
  end
  return ret
end

-- AiBestFenzu · 获取牌型data排序mark
function AiBestFenzu:getSuitDataSortMark(meSuitDataArr, enemy1SuitDataArr, enemy2SuitDataArr)
  if meSuitDataArr == nil or #meSuitDataArr == 0 then
    return {}
  end
  local ret = {}
  local enemy1BombCardTypeList, enemy1HaveBomb, enemy2BombCardTypeList, enemy2HaveBomb
  if enemy1SuitDataArr ~= nil then
    enemy1BombCardTypeList = {}
    enemy1HaveBomb = false
    for _, suitData in ipairs(enemy1SuitDataArr) do
      if suitData:getType() <= SuitType.kBomb and suitData:getIsLazi() == false then
        enemy1BombCardTypeList[suitData:getLevel()] = true
        enemy1HaveBomb = true
      end
    end
  end
  if enemy2SuitDataArr ~= nil then
    enemy2BombCardTypeList = {}
    enemy2HaveBomb = false
    for _, suitData in ipairs(enemy2SuitDataArr) do
      if suitData:getType() <= SuitType.kBomb and suitData:getIsLazi() == false then
        enemy2BombCardTypeList[suitData:getLevel()] = true
        enemy2HaveBomb = true
      end
    end
  end
  for index, meSuitData in ipairs(meSuitDataArr) do
    if self.async and index % 10 == 0 then
      coroutine.yield()
    end
    local biggerCount = 0
    local smallerCount = 0
    local equalCount = 0
    local useBombCount = 0
    if enemy1SuitDataArr ~= nil then
      local isUseBomb = false
      for _, enemy1SuitData in ipairs(enemy1SuitDataArr) do
        isUseBomb = false
        if
          meSuitData:getType() == enemy1SuitData:getType()
          and meSuitData:getCardCount() == enemy1SuitData:getCardCount()
        then
          if enemy1HaveBomb then
            local needCardCountList = enemy1SuitData:getNeedCardCountList()
            for cardType, num in pairs(needCardCountList) do
              if enemy1BombCardTypeList[cardType] then
                isUseBomb = true
                break
              end
            end
          end
          local meWin = meSuitData:isWin(enemy1SuitData)
          if not meWin then
            local enemy1Win = enemy1SuitData:isWin(meSuitData)
            if not enemy1Win then
              equalCount = equalCount + 1
              if isUseBomb then
                useBombCount = useBombCount + 100
              end
            else
              biggerCount = biggerCount + 1
              if isUseBomb then
                useBombCount = useBombCount + 10000
              end
            end
          else
            smallerCount = smallerCount + 1
            if isUseBomb then
              useBombCount = useBombCount + 1
            end
          end
        end
      end
    end
    if enemy2SuitDataArr ~= nil then
      local isUseBomb = false
      for _, enemy2SuitData in ipairs(enemy2SuitDataArr) do
        isUseBomb = false
        if
          meSuitData:getType() == enemy2SuitData:getType()
          and meSuitData:getCardCount() == enemy2SuitData:getCardCount()
        then
          if enemy2HaveBomb then
            local needCardCountList = enemy2SuitData:getNeedCardCountList()
            for cardType, num in pairs(needCardCountList) do
              if enemy2BombCardTypeList[cardType] then
                isUseBomb = true
                break
              end
            end
          end
          local meWin = meSuitData:isWin(enemy2SuitData)
          if not meWin then
            local enemy2Win = enemy2SuitData:isWin(meSuitData)
            if not enemy2Win then
              equalCount = equalCount + 1
              if isUseBomb then
                useBombCount = useBombCount + 100
              end
            else
              biggerCount = biggerCount + 1
              if isUseBomb then
                useBombCount = useBombCount + 10000
              end
            end
          else
            smallerCount = smallerCount + 1
            if isUseBomb then
              useBombCount = useBombCount + 1
            end
          end
        end
      end
    end
    local sortMarkKey = meSuitData:getSortMarkKey()
    ret[sortMarkKey] = {
      biggerCount = biggerCount,
      smallerCount = smallerCount,
      equalCount = equalCount,
      useBombCount = useBombCount,
    }
  end
  return ret
end

-- AiBestFenzu · 牌型dataarrdealfortwo
function AiBestFenzu:suitDataArrDealForTwo(suitDataArr)
  local maybeQiangQuanCount = 0
  local twoSuitDataArr = {}
  local littleJoker
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() == SuitType.kSingle then
      if suitData:getLevel() == CardType.kTwo then
        maybeQiangQuanCount = maybeQiangQuanCount + 1
        table.insert(twoSuitDataArr, suitData)
      elseif suitData:getLevel() == CardType.kLittleJoker then
        littleJoker = suitData
      end
    end
  end
  local qiangQuanCount = 0
  local twoIsQiangQuan = false
  local needDealQiangQuan = self.needDealQiangQuan
  if needDealQiangQuan then
    local qiangQuanDelta = self.qiangQuanDelta
    if 0 < maybeQiangQuanCount - qiangQuanDelta then
      qiangQuanCount = maybeQiangQuanCount - qiangQuanDelta
    end
    local qiangQuanMinTwoCount = self.qiangQuanMinTwoCount
    local twoCount = #twoSuitDataArr
    if qiangQuanMinTwoCount <= twoCount then
      twoIsQiangQuan = true
    end
  end
  for _, suitData in ipairs(twoSuitDataArr) do
    suitData.isQiangQuan = twoIsQiangQuan
  end
  if littleJoker and 0 < qiangQuanCount then
    littleJoker.isQiangQuan = true
  end
  return qiangQuanCount
end

-- AiBestFenzu · 获取meallbring牌型data
function AiBestFenzu:getMeAllBringSuitData()
  return self.meAllBringSuitData
end

-- AiBestFenzu · log牌型datalist
function AiBestFenzu:logSuitDataList(suitDataList, desciption)
  print("======" .. tostring(desciption))
  if suitDataList then
    for _, suitData in ipairs(suitDataList) do
      print(suitData:toString() .. " 评分：" .. suitData:getScore())
    end
  end
  print("======\n")
end

-- AiBestFenzu · test
function AiBestFenzu:test(async) end

return AiBestFenzu
