-- 文件: AiCardTypeListData.lua · 反编译 AI 模块（阅读用）

local AiCardTypeListData = class("AiCardTypeListData", DataBase)
AiCardTypeListData:addProperty("cardTypeList", {})
AiCardTypeListData:addProperty("lazi", 0)
AiCardTypeListData:addProperty("uid", 0)
AiCardTypeListData:addProperty("robot", false)
AiCardTypeListData:addProperty("direction", nil)
AiCardTypeListData:addProperty("async", false)

-- AiCardTypeList · 构造函数
function AiCardTypeListData:ctor(properties)
  AiCardTypeListData.super.ctor(self, properties)
end

-- AiCardTypeList · 由牌点列表创建 AiCardTypeListData
function AiCardTypeListData:createWithCardTypeList(cardTypeList, lazi)
  local ret = self.new({ cardTypeList = cardTypeList, lazi = lazi })
  return ret
end

-- AiCardTypeList · 克隆当前对象
function AiCardTypeListData:clone()
  local cardTypeList = {}
  table.insertto(cardTypeList, self:getCardTypeList())
  local params = {
    cardTypeList = cardTypeList,
    lazi = self:getLazi(),
    uid = self:getUid(),
    direction = self:getDirection(),
    async = self:getAsync(),
  }
  local ret = AiCardTypeListData.new(params)
  return ret
end

-- AiCardTypeList · 输出调试日志
function AiCardTypeListData:log(desciption, printFun)
  desciption = desciption or "AiCardTypeListData:"
  printFun = printFun or print
  local str = desciption
  local cardTypeList = self:getCardTypeList()
  local lazi = self:getLazi()
  if cardTypeList and 0 < #cardTypeList then
    cardTypeListStr = " cardTypeList:" .. table.concat(cardTypeList, ", ")
    str = str .. cardTypeListStr
  end
  if 0 < lazi then
    laziStr = "; lazi:" .. tostring(lazi)
    str = str .. laziStr
  end
  printFun(str)
end

-- AiCardTypeList · 获取手牌张数
function AiCardTypeListData:getCardCount()
  local cardTypeList = self:getCardTypeList()
  return #cardTypeList
end

-- AiCardTypeList · 获取各牌点数量映射
function AiCardTypeListData:getCardTypeCountMap()
  if self.cardTypeCountMap_ == nil then
    local ret = {}
    for i = CardType.kThree, CardType.kBigJoker do
      ret[i] = 0
    end
    local cardTypeList = self:getCardTypeList()
    if cardTypeList ~= nil then
      for _, cardType in ipairs(cardTypeList) do
        ret[cardType] = ret[cardType] + 1
      end
    end
    self.cardTypeCountMap_ = ret
  end
  return self.cardTypeCountMap_
end

-- AiCardTypeList · 获取牌countwithtype
function AiCardTypeListData:getCardCountWithType(cardType)
  if cardType == nil then
    return 0
  end
  if cardType < CardType.kThree or cardType > CardType.kBigJoker then
    return 0
  end
  local cardTypeCountMap = self:getCardTypeCountMap()
  local ret = cardTypeCountMap[cardType]
  return ret
end

-- AiCardTypeList · 获取癞子数量
function AiCardTypeListData:getLaziCount()
  local lazi = self:getLazi()
  return self:getCardCountWithType(lazi)
end

-- AiCardTypeList · 判断是否有牌typewithcount
function AiCardTypeListData:hasCardTypeWithCount(cardType, count)
  if cardType == nil or count == nil then
    print("error: AiCardTypeListData:hasCardTypeWithCount cardType == nil or count == nil")
    return false
  end
  if cardType < CardType.kThree or cardType > CardType.kBigJoker then
    print("error: AiCardTypeListData:hasCardTypeWithCount cardType: ", cardType)
    return false
  end
  if count == 0 then
    print("error: AiCardTypeListData:hasCardTypeWithCount count: 0")
    return false
  end
  local ret = false
  local cardTypeCountMap = self:getCardTypeCountMap()
  local hasCount = cardTypeCountMap[cardType]
  if cardType < CardType.kLittleJoker then
    local laziCount = self:getLaziCount()
    if count <= count + laziCount then
      ret = true
    end
  elseif count <= count then
    ret = true
  end
  return ret
end

-- AiCardTypeList · 添加牌typewithcount
function AiCardTypeListData:addCardTypeWithCount(cardType, count)
  if cardType == nil or count == nil then
    print("error: AiCardTypeListData:addCardTypeWithCount cardType == nil or count == nil")
    return false
  end
  if cardType < CardType.kThree or cardType > CardType.kBigJoker then
    print("error: AiCardTypeListData:addCardTypeWithCount cardType: ", cardType)
    return false
  end
  if count == 0 then
    print("error: AiCardTypeListData:addCardTypeWithCount count: 0")
    return false
  end
  local cardTypeCountMap = self:getCardTypeCountMap()
  local hasCount = cardTypeCountMap[cardType]
  cardTypeCountMap[cardType] = hasCount + count
  local didInsert = false
  local cardTypeList = self:getCardTypeList()
  for i, aCardType in ipairs(cardTypeList) do
    if cardType <= aCardType then
      for j = 1, count do
        table.insert(cardTypeList, i, cardType)
      end
      didInsert = true
      break
    end
  end
  if not didInsert then
    for j = 1, count do
      table.insert(cardTypeList, cardType)
    end
  end
  return true
end

-- AiCardTypeList · 移除牌typewithcount
function AiCardTypeListData:removeCardTypeWithCount(cardType, count)
  if cardType == nil or count == nil then
    print("error: AiCardTypeListData:removeCardTypeWithCount cardType == nil or count == nil")
    return false
  end
  if cardType < CardType.kThree or cardType > CardType.kBigJoker then
    print("error: AiCardTypeListData:removeCardTypeWithCount cardType: ", cardType)
    return false
  end
  if count == 0 then
    print("error: AiCardTypeListData:removeCardTypeWithCount count: 0")
    return false
  end
  local didRemove = false
  local cardTypeCountMap = self:getCardTypeCountMap()
  local hasCount = cardTypeCountMap[cardType]
  if count <= hasCount then
    cardTypeCountMap[cardType] = hasCount - count
    local didRemoveCount = 0
    local cardTypeList = self:getCardTypeList()
    for i = #cardTypeList, 1, -1 do
      local hasCardType = cardTypeList[i]
      if hasCardType == cardType then
        table.remove(cardTypeList, i)
        didRemoveCount = didRemoveCount + 1
        if didRemoveCount == count then
          break
        end
      end
    end
    didRemove = true
  end
  return didRemove
end

-- AiCardTypeList · 判断是否有牌typewithmap
function AiCardTypeListData:hasCardTypeWithMap(countMap)
  if countMap == nil or next(countMap) == nil then
    print("error: AiCardTypeListData:hasCardTypeWithMap countMap == nil or next(countMap) == nil")
    return false, nil
  end
  local cardCount = self:getCardCount()
  local allCardCount = 0
  for _, count in ipairs(countMap) do
    allCardCount = allCardCount + count
  end
  if cardCount < allCardCount then
    return false, nil
  end
  local has = true
  local removeCountMap = {}
  local cardTypeCountMap = self:getCardTypeCountMap()
  local lazi = self:getLazi()
  local laziCount = cardTypeCountMap[lazi]
  for cardType, count in pairs(countMap) do
    local hasCount = cardTypeCountMap[cardType]
    if count <= hasCount then
      if lazi == cardType then
        local removeLaziCount = removeCountMap[cardType] or 0
        if hasCount < count + removeLaziCount then
          has = false
          break
        end
        removeCountMap[cardType] = removeLaziCount + count
      else
        removeCountMap[cardType] = count
      end
    else
      if lazi == 0 then
        has = false
        break
      end
      if cardType == CardType.kBigJoker or cardType == CardType.kLittleJoker then
        has = false
        break
      end
      if lazi == cardType then
        has = false
        break
      end
      local removeLaziCount = removeCountMap[lazi] or 0
      if count - hasCount > laziCount - removeLaziCount then
        has = false
        break
      end
      if 0 < hasCount then
        removeCountMap[cardType] = hasCount
      end
      removeCountMap[lazi] = removeLaziCount + (count - hasCount)
    end
  end
  local needLaziCount = countMap[lazi] or 0
  local removeLaziCount = removeCountMap[lazi] or 0
  if allCardCount > needLaziCount and allCardCount == removeLaziCount then
    has = false
  end
  return has, removeCountMap
end

-- AiCardTypeList · 添加牌typewithmap
function AiCardTypeListData:addCardTypeWithMap(countMap)
  if countMap == nil or next(countMap) == nil then
    print("error: AiCardTypeListData:addCardTypeWithMap countMap == nil or next(countMap) == nil")
    return false
  end
  for cardType, count in pairs(countMap) do
    self:addCardTypeWithCount(cardType, count)
  end
  return true
end

-- AiCardTypeList · 移除牌typewithmap
function AiCardTypeListData:removeCardTypeWithMap(countMap)
  local has, removeCountMap = self:hasCardTypeWithMap(countMap)
  local didRemove = false
  if has then
    for cardType, count in pairs(removeCountMap) do
      self:removeCardTypeWithCount(cardType, count)
    end
    didRemove = true
  end
  return didRemove, removeCountMap
end

-- AiCardTypeList · 是否含王炸
function AiCardTypeListData:hasDoubleJoker()
  return self:getCardCountWithType(CardType.kLittleJoker) == 1 and self:getCardCountWithType(CardType.kBigJoker) == 1
end

-- AiCardTypeList · 手牌是否包含指定牌型
function AiCardTypeListData:hasSuitData(suitData)
  if suitData == nil then
    print("error: AiCardTypeListData:hasSuitData suitData == nil")
    return false
  end
  local needCardCountList = suitData:getNeedCardCountList()
  return self:hasCardTypeWithMap(needCardCountList)
end

-- AiCardTypeList · 从手牌中移除某牌型占用的牌
function AiCardTypeListData:removeCardTypeWithSuitData(suitData)
  if suitData == nil then
    print("error: AiCardTypeListData:removeCardTypeWithSuitData suitData == nil")
    return false
  end
  local needCardCountList = suitData:getNeedCardCountList()
  return self:removeCardTypeWithMap(needCardCountList)
end

-- AiCardTypeList · 获取满足张数条件的牌点列表
function AiCardTypeListData:getTypeListWithCount(count, enableMore, enableLazi)
  local ret = {}
  local cardTypeCountMap = self:getCardTypeCountMap()
  local lazi = self:getLazi()
  for cardType = CardType.kThree, CardType.kBigJoker do
    local hasCount = cardTypeCountMap[cardType]
    if enableLazi or cardType ~= lazi then
      if enableMore then
        if count <= hasCount then
          table.insert(ret, cardType)
        end
      elseif hasCount == count then
        table.insert(ret, cardType)
      end
    end
  end
  return ret
end

-- AiCardTypeList · 枚举所有单张牌型
function AiCardTypeListData:getSingleSuitDataArr()
  if self.singleSuitDataArr_ == nil then
    local allSuitData = self:getAllSuitData()
    local ret = {}
    for _, suitData in ipairs(allSuitData) do
      if suitData:getType() == SuitType.kSingle then
        table.insert(ret, suitData)
      end
    end
    local lazi = self:getLazi()
    local hasDoubleJoker = self:hasDoubleJoker()
    table.sort(ret, function(a, b)
      local a_level = a:getLevel()
      local b_level = b:getLevel()
      if a_level == lazi and b_level ~= lazi then
        return false
      end
      if a_level ~= lazi and b_level == lazi then
        return true
      end
      if hasDoubleJoker then
        if a_level >= CardType.kLittleJoker then
          if b_level >= CardType.kLittleJoker then
            return a_level < b_level
          else
            return false
          end
        elseif b_level >= CardType.kLittleJoker then
          return true
        end
      end
      local a_count = self:getCardCountWithType(a_level)
      local b_count = self:getCardCountWithType(b_level)
      if a_count == b_count then
        return a_level < b_level
      else
        return a_count < b_count
      end
    end)
    self.singleSuitDataArr_ = ret
  end
  return self.singleSuitDataArr_
end

-- AiCardTypeList · 枚举所有对子牌型
function AiCardTypeListData:getPairSuitDataArr()
  if self.pairSuitDataArr_ == nil then
    local allSuitData = self:getAllSuitData()
    local ret = {}
    for _, suitData in ipairs(allSuitData) do
      if suitData:getType() == SuitType.kPair then
        table.insert(ret, suitData)
      end
    end
    local lazi = self:getLazi()
    table.sort(ret, function(a, b)
      local a_level = a:getLevel()
      local b_level = b:getLevel()
      if a_level == lazi and b_level ~= lazi then
        return false
      end
      if a_level ~= lazi and b_level == lazi then
        return true
      end
      local a_count = self:getCardCountWithType(a_level)
      local b_count = self:getCardCountWithType(b_level)
      if a_count == b_count then
        return a_level < b_level
      else
        if a_count == 1 then
          return false
        end
        if b_count == 1 then
          return true
        end
        return a_count < b_count
      end
    end)
    self.pairSuitDataArr_ = ret
  end
  return self.pairSuitDataArr_
end

-- AiCardTypeList · 将手牌转为指定类型的 AiSuitData
function AiCardTypeListData:toSuit(lastSuitData, suitType, isFromSelectCard)
  local ret, allRet = AiSuitData:createWithCardTypeListData(self, lastSuitData, suitType, isFromSelectCard)
  return ret, allRet
end

-- AiCardTypeList · 枚举手牌全部牌型组合
function AiCardTypeListData:getAllSuitData()
  if self.allSuitData_ == nil then
    local ret = AiSuitData:getAllSuitData(self, nil, self:getAsync())
    self.allSuitData_ = ret
    if self:getAsync() then
      coroutine.yield()
    end
  end
  return self.allSuitData_
end

-- AiCardTypeList · 枚举全部炸弹
function AiCardTypeListData:getAllBomb()
  if self.allBomb_ == nil then
    local ret = {}
    local allSuit = self:getAllSuitData()
    if allSuit and 0 < #allSuit then
      for _, suitData in ipairs(allSuit) do
        if suitData:getType() == SuitType.kDoubleJoker or suitData:getType() == SuitType.kBomb then
          table.insert(ret, suitData)
        end
      end
    end
    self.allBomb_ = ret
  end
  return self.allBomb_
end

-- AiCardTypeList · 获取all炸弹formaxcount
function AiCardTypeListData:getAllBombForMaxCount()
  local laziCount = self:getLaziCount()
  if laziCount == 0 then
    return self:getAllBomb()
  end
  local allBomb = self:getAllBomb()
  if #allBomb <= 1 then
    return allBomb
  end
  local ret = {}
  if 1 < #allBomb then
    local lazi = self:getLazi()
    local list = {
      [0] = {},
      [1] = {},
      [2] = {},
      [3] = {},
      [4] = {},
    }
    for _, suitData in ipairs(allBomb) do
      if suitData:getType() == SuitType.kDoubleJoker then
        table.insert(list[0], suitData)
      elseif suitData:getLevel() == lazi then
        table.insert(list[4], suitData)
      else
        local cardCount = self:getCardCountWithType(suitData:getLevel())
        table.insert(list[4 - cardCount], suitData)
      end
    end
    if 0 < #list[0] then
      for _, suitData in ipairs(list[0]) do
        table.insert(ret, suitData)
      end
    end
    table.sort(list[1], function(a, b)
      return a:getLevel() > b:getLevel()
    end)
    table.sort(list[2], function(a, b)
      return a:getLevel() > b:getLevel()
    end)
    table.sort(list[3], function(a, b)
      return a:getLevel() > b:getLevel()
    end)
    local arr = {}
    local count
    local didSort = false
    if laziCount <= #list[1] then
      arr = list[1]
      count = laziCount
      didSort = true
    elseif laziCount == 1 then
      count = 0
    elseif laziCount == 2 then
      if list[1][1] then
        table.insert(arr, list[1][1])
      end
      if list[2][1] then
        table.insert(arr, list[2][1])
      end
      count = 1
      didSort = false
    elseif laziCount == 3 then
      if #list[1] == 2 or #list[1] == 1 and 1 <= #list[2] then
        table.insert(ret, list[1][1])
        if list[1][2] then
          table.insert(arr, list[1][2])
        end
        if list[2][1] then
          table.insert(arr, list[2][1])
        end
        count = 1
        didSort = false
      else
        if list[1][1] then
          table.insert(arr, list[1][1])
        end
        if list[2][1] then
          table.insert(arr, list[2][1])
        end
        if list[3][1] then
          table.insert(arr, list[3][1])
        end
        count = 1
        didSort = false
      end
    elseif #list[1] == 3 or #list[1] == 2 and 1 <= #list[2] then
      table.insert(ret, list[1][1])
      table.insert(ret, list[1][2])
      if list[1][3] then
        table.insert(arr, list[1][3])
      end
      if list[2][1] then
        table.insert(arr, list[2][1])
      end
      count = 1
      didSort = false
    elseif #list[1] == 2 or #list[1] == 1 and 1 <= #list[2] + #list[3] then
      table.insert(ret, list[1][1])
      if list[1][2] then
        table.insert(arr, list[1][2])
      end
      if list[2][1] then
        table.insert(arr, list[2][1])
      end
      if list[3][1] then
        table.insert(arr, list[3][1])
      end
      count = 1
      didSort = false
    elseif 2 <= #list[2] then
      table.insert(ret, list[2][1])
      table.insert(ret, list[2][2])
      count = 2
      didSort = false
    else
      if list[1][1] then
        table.insert(arr, list[1][1])
      end
      if list[2][1] then
        table.insert(arr, list[2][1])
      end
      if list[3][1] then
        table.insert(arr, list[3][1])
      end
      if list[4][1] then
        table.insert(arr, list[4][1])
      end
      count = 1
      didSort = false
    end
    if count >= #arr then
      table.insertto(ret, arr)
    elseif 0 < #arr then
      if not didSort then
        table.sort(arr, function(a, b)
          return a:getLevel() > b:getLevel()
        end)
      end
      for i = 1, count do
        table.insert(ret, arr[i])
      end
    end
  end
  return ret
end

-- AiCardTypeList · 获取/创建最优分组引擎 AiBestFenzu
function AiCardTypeListData:ai_getBestFenzu()
  if self.bestFenzu_ == nil then
    local params = {
      me = self,
      enemy1 = self.enemy1,
      enemy2 = self.enemy2,
      friend = self.friend,
      lazi = self:getLazi(),
      lastSuitData = self.lastSuitData,
      async = self:getAsync(),
      allFenzu = self.allFenzu_,
    }
    self.bestFenzu_ = AiBestFenzu.new(params)
    self.allFenzu_ = self.bestFenzu_.allFenzu_
    if self:getAsync() then
      coroutine.yield()
    end
  end
  return self.bestFenzu_
end

-- AiCardTypeList · 获取当前最优拆牌方案 AiFenzuData
function AiCardTypeListData:ai_getBestFenzuData()
  if self.bestFenzuData_ == nil then
    local fenzuData = self:ai_getBestFenzu()
    local bestFenzuData = fenzuData:getBestFenzuData()
    if bestFenzuData == nil then
      print("Error: AiCardTypeListData:ai_getBestFenzuData bestFenzuData == nil")
    end
    self.bestFenzuData_ = bestFenzuData
    if self:getAsync() then
      coroutine.yield()
    end
  end
  return self.bestFenzuData_
end

-- AiCardTypeList · 获取最优分组下的牌型组合列表
function AiCardTypeListData:ai_getBestSuitDataArr()
  local ret = {}
  local bestFenzuData = self:ai_getBestFenzuData()
  if bestFenzuData then
    ret = bestFenzuData.suitDataArr_
  end
  return ret
end

-- AiCardTypeList · 深度搜索更优拆牌与出牌组合
function AiCardTypeListData:ai_doDeepBestSuitDataArr(lastSuitData, taskData)
  local fenzuData = self:ai_getBestFenzu()
  local bestFenzuData = fenzuData:getDeepBestFenzuData({ lastSuitData = lastSuitData, taskData = taskData })
  if bestFenzuData then
    self.bestFenzuData_ = bestFenzuData
  else
    print("Error: AiCardTypeListData:ai_doDeepBestSuitDataArr bestFenzuData == nil")
  end
  if self:getAsync() then
    coroutine.yield()
  end
end

-- AiCardTypeList · 获取可一手出完的收官组合列表
function AiCardTypeListData:ai_getWinConditions()
  if self.winConditions_ == nil then
    local fenzuData = self:ai_getBestFenzu()
    self.winConditions_ = fenzuData:getWinConditions()
  end
  return self.winConditions_
end

-- AiCardTypeList · 是否存在收官可能
function AiCardTypeListData:ai_getEnableEnd()
  if self.enableEnd_ == nil then
    local winConditions = self:ai_getWinConditions()
    self.enableEnd_ = 0 < #winConditions
  end
  return self.enableEnd_
end

-- AiCardTypeList · AI手牌层：get Is Lose
function AiCardTypeListData:ai_getIsLose()
  if self.isLose_ == nil then
    local ret = false
    local direction = self:getDirection()
    if direction == 1 then
      local enemy1 = self.enemy1
      local enemy2 = self.enemy2
      if enemy1 and enemy2 then
        local bestSuitDataArr = self:ai_getBestSuitDataArr()
        local mismatchWinCondition = enemy1:ai_filterMismatchWinCondition(bestSuitDataArr)
        mismatchWinCondition = enemy2:ai_filterMismatchWinCondition(mismatchWinCondition)
        if 2 <= #bestSuitDataArr - #mismatchWinCondition then
          ret = true
        end
      end
    elseif direction == 2 or direction == 3 then
      local enemy1 = self.enemy1
      if enemy1 then
        local bestSuitDataArr = self:ai_getBestSuitDataArr()
        local matchWinCondition = enemy1:ai_filterMatchWinCondition(bestSuitDataArr)
        if 2 <= #matchWinCondition then
          ret = true
        end
      end
    end
    self.isLose_ = ret
  end
  return self.isLose_
end

-- AiCardTypeList · AI手牌层：get Enable Follow
function AiCardTypeListData:ai_getEnableFollow(lastSuitData)
  if self.enableFollow_ == nil then
    local ret = false
    local allSuitData = AiSuitData:getAllSuitData(self, lastSuitData)
    if 0 < #allSuitData then
      for _, suitData in ipairs(allSuitData) do
        if suitData:isWin(lastSuitData) then
          ret = true
          break
        end
      end
    end
    self.enableFollow_ = ret
  end
  return self.enableFollow_
end

-- AiCardTypeList · AI手牌层：is Pair
function AiCardTypeListData:ai_isPair()
  local cardTypeList = self:getCardTypeList()
  if #cardTypeList == 2 and cardTypeList[1] == cardTypeList[2] then
    return true
  else
    return false
  end
end

-- AiCardTypeList · AI手牌层：filter Bomb Is Pair Or Three
function AiCardTypeListData:ai_filterBombIsPairOrThree()
  local allBomb = self:getAllBomb()
  local bombCardTypeList = {}
  local lazi = self:getLazi()
  for _, suitData in ipairs(allBomb) do
    if
      suitData:getType() <= SuitType.kBomb and (not (lazi ~= 0 and suitData:getIsLazi()) or suitData:getLevel() == lazi)
    then
      bombCardTypeList[suitData:getLevel()] = true
    end
  end
  local cardTypeList = AiUtils:clone(self:getCardTypeList())
  for i = #cardTypeList, 1, -1 do
    local cardType = cardTypeList[i]
    if bombCardTypeList[cardType] then
      table.remove(cardTypeList, i)
    end
  end
  if #cardTypeList == 2 and cardTypeList[1] == cardTypeList[2] then
    return true
  elseif #cardTypeList == 3 and cardTypeList[1] == cardTypeList[2] and cardTypeList[1] == cardTypeList[3] then
    return true
  else
    return false
  end
end

-- AiCardTypeList · AI手牌层：best Fenzu is Left Bomb And One Suit
function AiCardTypeListData:ai_bestFenzu_isLeftBombAndOneSuit()
  local bestSuitDataArr = self:ai_getBestSuitDataArr()
  if
    #bestSuitDataArr == 2
    and (bestSuitDataArr[1]:getType() <= SuitType.kBomb or bestSuitDataArr[2]:getType() <= SuitType.kBomb)
  then
    return true
  end
  return false
end

-- AiCardTypeList · AI手牌层：best Fenzu get First Max Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_getFirstMaxSuitDataArr()
  if self.firstMaxSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.firstMaxSuitDataArr_ = AiUtils:filterFirstMaxSuitDataArr(bestSuitDataArr)
  end
  return self.firstMaxSuitDataArr_
end

-- AiCardTypeList · AI手牌层：best Fenzu get Max Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_getMaxSuitDataArr()
  if self.maxSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.maxSuitDataArr_ = AiUtils:filterMaxSuitDataArr(bestSuitDataArr)
  end
  return self.maxSuitDataArr_
end

-- AiCardTypeList · AI手牌层：best Fenzu get Min Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_getMinSuitDataArr()
  if self.minSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.minSuitDataArr_ = AiUtils:filterMinSuitDataArr(bestSuitDataArr)
  end
  return self.minSuitDataArr_
end

-- AiCardTypeList · AI手牌层：best Fenzu get First Max Suit Key Map
function AiCardTypeListData:ai_bestFenzu_getFirstMaxSuitKeyMap()
  if self.firstMaxSuitKeyMap_ == nil then
    local suitDataArr = self:ai_bestFenzu_getFirstMaxSuitDataArr()
    self.firstMaxSuitKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.firstMaxSuitKeyMap_
end

-- AiCardTypeList · AI手牌层：best Fenzu get Max Suit Key Map
function AiCardTypeListData:ai_bestFenzu_getMaxSuitKeyMap()
  if self.maxSuitKeyMap_ == nil then
    local suitDataArr = self:ai_bestFenzu_getMaxSuitDataArr()
    self.maxSuitKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.maxSuitKeyMap_
end

-- AiCardTypeList · AI手牌层：best Fenzu get Must End Suit Key Map
function AiCardTypeListData:ai_bestFenzu_getMustEndSuitKeyMap()
  if self.mustEndSuitKeyMap_ == nil then
    local suitDataArr = self:ai_getBestSuitDataArr()
    local ret = {}
    local map = {}
    for _, suitData in ipairs(suitDataArr) do
      if suitData:getType() > SuitType.kBomb then
        local key = suitData:getKey()
        if not map[key] then
          map[key] = 0
        end
        local biggerCount = suitData:getBiggerCount()
        if biggerCount == 0 then
          map[key] = map[key] + 1
        else
          map[key] = map[key] - 1
        end
      end
    end
    for key, count in pairs(map) do
      if 0 < count then
        ret[key] = true
      end
    end
    self.mustEndSuitKeyMap_ = ret
  end
  return self.mustEndSuitKeyMap_
end

-- AiCardTypeList · AI手牌层：best Fenzu get Better Then Enemy Suit Key Map
function AiCardTypeListData:ai_bestFenzu_getBetterThenEnemySuitKeyMap()
  local ret = {}
  return ret
end

-- AiCardTypeList · AI手牌层：liu get Liu Suit Data Arr
function AiCardTypeListData:ai_liu_getLiuSuitDataArr()
  if self.liuSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.liuSuitDataArr_ = AiUtils:filterLiuSuitDataArr(bestSuitDataArr)
  end
  return self.liuSuitDataArr_
end

-- AiCardTypeList · AI手牌层：liu get Must Liu Suit Data Arr
function AiCardTypeListData:ai_liu_getMustLiuSuitDataArr()
  if self.mustLiuSuitDataArr_ == nil then
    local bestFenzuData = self:ai_getBestFenzuData()
    self.mustLiuSuitDataArr_ = bestFenzuData:getAllMustLiuSuitData()
  end
  return self.mustLiuSuitDataArr_
end

-- AiCardTypeList · AI手牌层：liu get Must Liu C Suit Data Arr
function AiCardTypeListData:ai_liu_getMustLiuCSuitDataArr()
  if self.mustLiuCSuitDataArr_ == nil then
    local bestFenzuData = self:ai_getBestFenzuData()
    self.mustLiuCSuitDataArr_ = bestFenzuData:getAllMustLiuCSuitData()
  end
  return self.mustLiuCSuitDataArr_
end

-- AiCardTypeList · AI手牌层：liu get Liu Key Map
function AiCardTypeListData:ai_liu_getLiuKeyMap()
  if self.liuKeyMap_ == nil then
    local suitDataArr = self:ai_liu_getLiuSuitDataArr()
    self.liuKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.liuKeyMap_
end

-- AiCardTypeList · AI手牌层：liu get Must Liu Key Map
function AiCardTypeListData:ai_liu_getMustLiuKeyMap()
  if self.mustLiuKeyMap_ == nil then
    local suitDataArr = self:ai_liu_getMustLiuSuitDataArr()
    self.mustLiuKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.mustLiuKeyMap_
end

-- AiCardTypeList · AI手牌层：liu get Must Liu C Key Map
function AiCardTypeListData:ai_liu_getMustLiuCKeyMap()
  if self.mustLiuCKeyMap_ == nil then
    local suitDataArr = self:ai_liu_getMustLiuCSuitDataArr()
    self.mustLiuCKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.mustLiuCKeyMap_
end

-- AiCardTypeList · AI手牌层：all get Suit Data Arr
function AiCardTypeListData:ai_all_getSuitDataArr()
  if self.ai_allSuitDataArr_ == nil then
    local ret = {}
    table.insertto(ret, self:getAllSuitData())
    local bringSuitDataArr = AiUtils:bringSuitDataArr(ret, self)
    table.insertto(ret, bringSuitDataArr)
    local bestFenzu = self:ai_getBestFenzu()
    local sortMark = bestFenzu.sortMark
    for _, suitData in ipairs(ret) do
      local sortMarkKey = suitData:getSortMarkKey()
      suitData:setBiggerCount(sortMark[sortMarkKey].biggerCount)
      suitData:setSmallerCount(sortMark[sortMarkKey].smallerCount)
      suitData:setEqualCount(sortMark[sortMarkKey].equalCount)
      suitData:setUseBombCount(sortMark[sortMarkKey].useBombCount)
    end
    self.ai_allSuitDataArr_ = ret
  end
  return self.ai_allSuitDataArr_
end

-- AiCardTypeList · AI手牌层：all get Max Suit Data Arr
function AiCardTypeListData:ai_all_getMaxSuitDataArr()
  if self.allMaxSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_all_getSuitDataArr()
    self.allMaxSuitDataArr_ = AiUtils:filterMaxSuitDataArr(bestSuitDataArr)
  end
  return self.allMaxSuitDataArr_
end

-- AiCardTypeList · AI手牌层：all get Not Bomb Max Suit Data Arr
function AiCardTypeListData:ai_all_getNotBombMaxSuitDataArr()
  if self.allNotBombMaxSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_all_getSuitDataArr()
    self.allNotBombMaxSuitDataArr_ = AiUtils:filterNotBombMaxSuitDataArr(bestSuitDataArr)
  end
  return self.allNotBombMaxSuitDataArr_
end

-- AiCardTypeList · AI手牌层：all get Max Suit Key Map
function AiCardTypeListData:ai_all_getMaxSuitKeyMap()
  if self.allMaxSuitKeyMap_ == nil then
    local suitDataArr = self:ai_all_getMaxSuitDataArr()
    self.allMaxSuitKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.allMaxSuitKeyMap_
end

-- AiCardTypeList · AI手牌层：all get Not Bomb Max Suit Key Map
function AiCardTypeListData:ai_all_getNotBombMaxSuitKeyMap()
  if self.allNotBombMaxSuitKeyMap_ == nil then
    local suitDataArr = self:ai_all_getNotBombMaxSuitDataArr()
    self.allNotBombMaxSuitKeyMap_ = AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  end
  return self.allNotBombMaxSuitKeyMap_
end

-- AiCardTypeList · 枚举不拆炸弹的任意牌型组合
function AiCardTypeListData:ai_all_getNotDisBombSuitDataArr()
  if self.allNotDisBombSuitDataArr_ == nil then
    local allSuitDataArr = self:ai_all_getSuitDataArr()
    self.allNotDisBombSuitDataArr_, self.allDisBombSuitDataArr_ =
      AiUtils:filterNotDisBombSuitDataArr(allSuitDataArr, self:getAllBomb(), self:getLazi())
  end
  return self.allNotDisBombSuitDataArr_, self.allDisBombSuitDataArr_
end

-- AiCardTypeList · 判断牌型是否属于赢牌/收官路径
function AiCardTypeListData:ai_isMatchWinCondition(suitData)
  local winConditions = self:ai_getWinConditions()
  local ret = AiUtils:checkHasBiggerSuitData(winConditions, suitData)
  return ret
end

-- AiCardTypeList · AI手牌层：filter Match Win Condition
function AiCardTypeListData:ai_filterMatchWinCondition(suitDataArr)
  local winConditions = self:ai_getWinConditions()
  if winConditions == nil or #winConditions == 0 then
    return {}
  end
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if self:ai_isMatchWinCondition(suitData) then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：filter Mismatch Win Condition
function AiCardTypeListData:ai_filterMismatchWinCondition(suitDataArr)
  local winConditions = self:ai_getWinConditions()
  if winConditions == nil or #winConditions == 0 then
    return suitDataArr
  end
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if not self:ai_isMatchWinCondition(suitData) then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：filter Bigger Win Conditions
function AiCardTypeListData:ai_filterBiggerWinConditions(lastSuitData)
  local winConditions = self:ai_getWinConditions()
  local ret = AiUtils:filterBiggerSuitDataArr(winConditions, lastSuitData)
  return ret
end

-- AiCardTypeList · AI手牌层：best Fenzu filter Bigger Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
  if self.biggerSuitDataArr == nil or self.biggerSuitDataArrLastSuitData_ ~= lastSuitData then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.biggerSuitDataArr = AiUtils:filterBiggerSuitDataArr(bestSuitDataArr, lastSuitData)
    self.biggerSuitDataArrLastSuitData_ = lastSuitData
  end
  return self.biggerSuitDataArr
end

-- AiCardTypeList · AI手牌层：best Fenzu filter All Smaller First Max Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_filterAllSmallerFirstMaxSuitDataArr(suitDataArr)
  local ret = {}
  local firstMaxSuitDataArr = self:ai_bestFenzu_getFirstMaxSuitDataArr()
  if 0 < #firstMaxSuitDataArr then
    local keyMap = self:ai_bestFenzu_getFirstMaxSuitKeyMap()
    ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
    ret = AiUtils:filterAllSmallerSuitDataArr(firstMaxSuitDataArr, ret)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：best Fenzu filter All Smaller Max Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_filterAllSmallerMaxSuitDataArr(suitDataArr)
  local ret = {}
  local maxSuitDataArr = self:ai_bestFenzu_getMaxSuitDataArr()
  if 0 < #maxSuitDataArr then
    local keyMap = self:ai_bestFenzu_getMaxSuitKeyMap()
    ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
    ret = AiUtils:filterAllSmallerSuitDataArr(maxSuitDataArr, ret)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：best Fenzu filter All Smaller Must End Max Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_filterAllSmallerMustEndMaxSuitDataArr(suitDataArr)
  local ret = {}
  local maxSuitDataArr = self:ai_bestFenzu_getMaxSuitDataArr()
  if 0 < #maxSuitDataArr then
    local keyMap = self:ai_bestFenzu_getMustEndSuitKeyMap()
    ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
    ret = AiUtils:filterAllSmallerSuitDataArr(maxSuitDataArr, ret)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：best Fenzu split Bring Suit Data Arr
function AiCardTypeListData:ai_bestFenzu_splitBringSuitDataArr()
  if self.bestFenzuSplitBringSuitDataArr_ == nil then
    local bestSuitDataArr = self:ai_getBestSuitDataArr()
    self.bestFenzuSplitBringSuitDataArr_ = AiUtils:splitBringSuitDataArr(bestSuitDataArr, self:getLazi())
    if #self.bestFenzuSplitBringSuitDataArr_ > 0 then
      local bestFenzu = self:ai_getBestFenzu()
      local sortMark = bestFenzu.sortMark
      for _, suitData in ipairs(self.bestFenzuSplitBringSuitDataArr_) do
        local sortMarkKey = suitData:getSortMarkKey()
        suitData:setBiggerCount(sortMark[sortMarkKey].biggerCount)
        suitData:setSmallerCount(sortMark[sortMarkKey].smallerCount)
        suitData:setEqualCount(sortMark[sortMarkKey].equalCount)
        suitData:setUseBombCount(sortMark[sortMarkKey].useBombCount)
      end
    end
  end
  return self.bestFenzuSplitBringSuitDataArr_
end

-- AiCardTypeList · AI手牌层：split Bring filter Bigger Suit Data Arr
function AiCardTypeListData:ai_splitBring_filterBiggerSuitDataArr(lastSuitData)
  if self.splitBringBiggerSuitDataArr == nil or self.splitBringBiggerSuitDataArrLastSuitData_ ~= lastSuitData then
    local splitBringSuitDataArr = self:ai_bestFenzu_splitBringSuitDataArr()
    self.splitBringBiggerSuitDataArr = AiUtils:filterBiggerSuitDataArr(splitBringSuitDataArr, lastSuitData)
    if #self.splitBringBiggerSuitDataArr > 0 then
      local bestFenzu = self:ai_getBestFenzu()
      local sortMark = bestFenzu.sortMark
      for _, suitData in ipairs(self.splitBringBiggerSuitDataArr) do
        local sortMarkKey = suitData:getSortMarkKey()
        suitData:setBiggerCount(sortMark[sortMarkKey].biggerCount)
        suitData:setSmallerCount(sortMark[sortMarkKey].smallerCount)
        suitData:setEqualCount(sortMark[sortMarkKey].equalCount)
        suitData:setUseBombCount(sortMark[sortMarkKey].useBombCount)
      end
    end
    self.splitBringBiggerSuitDataArrLastSuitData_ = lastSuitData
  end
  return self.splitBringBiggerSuitDataArr
end

-- AiCardTypeList · AI手牌层：liu filter Smaller Lmin Suit Data Arr
function AiCardTypeListData:ai_liu_filterSmallerLminSuitDataArr(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterSmallerLminSuitDataArr(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Smaller Lmax Suit Data Arr
function AiCardTypeListData:ai_liu_filterSmallerLmaxSuitDataArr(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterSmallerLmaxSuitDataArr(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Bigger Lmax Suit Data Arr
function AiCardTypeListData:ai_liu_filterBiggerLmaxSuitDataArr(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterBiggerLmaxSuitDataArr(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Bigger Must Liu Two Suit Data Arr
function AiCardTypeListData:ai_liu_filterBiggerMustLiuTwoSuitDataArr(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterBiggerMustLiuTwoSuitDataArr(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Bigger Liu Two Suit Data Arr
function AiCardTypeListData:ai_liu_filterBiggerLiuTwoSuitDataArr(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterBiggerLiuTwoSuitDataArr(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Bigger Lmax Suit Data Arr Without Max
function AiCardTypeListData:ai_liu_filterBiggerLmaxSuitDataArrWithoutMax(suitDataArr)
  local bestFenzuData = self:ai_getBestFenzuData()
  local ret = bestFenzuData:filterBiggerLmaxSuitDataArrWithoutMax(suitDataArr)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Must Liu Key And Smaller Lmax Suit Data Arr
function AiCardTypeListData:ai_liu_filterMustLiuKeyAndSmallerLmaxSuitDataArr(suitDataArr)
  local ret = {}
  local keyMap = self:ai_liu_getMustLiuKeyMap()
  ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
  ret = self:ai_liu_filterSmallerLmaxSuitDataArr(ret)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Must Liu C Key And Smaller Lmax Suit Data Arr
function AiCardTypeListData:ai_liu_filterMustLiuCKeyAndSmallerLmaxSuitDataArr(suitDataArr)
  local ret = {}
  local keyMap = self:ai_liu_getMustLiuCKeyMap()
  ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
  ret = self:ai_liu_filterSmallerLmaxSuitDataArr(ret)
  return ret
end

-- AiCardTypeList · AI手牌层：liu filter Liu Key And Smaller Lmax Suit Data Arr
function AiCardTypeListData:ai_liu_filterLiuKeyAndSmallerLmaxSuitDataArr(suitDataArr)
  local ret = {}
  local keyMap = self:ai_liu_getLiuKeyMap()
  ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
  ret = self:ai_liu_filterSmallerLmaxSuitDataArr(ret)
  return ret
end

-- AiCardTypeList · 筛选能压过上家的所有牌型
function AiCardTypeListData:ai_all_filterBiggerSuitDataArr(lastSuitData)
  local ret = {}
  if lastSuitData == nil then
    ret = self:ai_all_getSuitDataArr()
  else
    local suitDataArr = self:ai_all_getSuitDataArr()
    ret = AiUtils:filterBiggerSuitDataArr(suitDataArr, lastSuitData)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：all filter Bigger Not Dis Bomb Suit Data Arr
function AiCardTypeListData:ai_all_filterBiggerNotDisBombSuitDataArr(lastSuitData)
  local ret = {}
  local ret2
  if lastSuitData == nil then
    ret, ret2 = self:ai_all_getNotDisBombSuitDataArr()
  else
    local suitDataArr, suitDataArr2 = self:ai_all_getNotDisBombSuitDataArr()
    ret = AiUtils:filterBiggerSuitDataArr(suitDataArr, lastSuitData)
    if suitDataArr2 then
      ret2 = AiUtils:filterBiggerSuitDataArr(suitDataArr2, lastSuitData)
    end
  end
  return ret, ret2
end

-- AiCardTypeList · AI手牌层：all filter Bigger Suit Data Arr From Hint
function AiCardTypeListData:ai_all_filterBiggerSuitDataArrFromHint(lastSuitData)
  local ret = {}
  local allSuitData = {}
  table.insertto(allSuitData, self:getAllSuitData())
  local bringSuitDataArr = AiUtils:bringSuitDataArr(allSuitData, self, true)
  table.insertto(allSuitData, bringSuitDataArr)
  if lastSuitData == nil then
    local cardTypeCountMap = self:getCardTypeCountMap()
    local cardTypeList = self:getCardTypeList()
    local haveDoubleJoker, count, suitType
    for _, suitData in ipairs(allSuitData) do
      count = suitData:getCardCount()
      suitType = suitData:getType()
      if
        not (
          (
            suitType ~= SuitType.kBomb
              and suitType ~= SuitType.kThree
              and suitType ~= SuitType.kPair
              and suitType ~= SuitType.kSingle
            or cardTypeCountMap[suitData:getLevel()] ~= count
          )
          and (
            #cardTypeList ~= count or not (count <= 4) and AiUtils:isAllBombCardType(suitData:getNeedCardCountList())
          )
        ) or suitType == SuitType.kDoubleJoker
      then
        table.insert(ret, suitData)
        if suitType == SuitType.kDoubleJoker then
          haveDoubleJoker = true
        end
      end
    end
    if haveDoubleJoker then
      for i = #ret, 1, -1 do
        if ret[i]:getType() == SuitType.kSingle and (ret[i]:getLevel() == 16 or ret[i]:getLevel() == 17) then
          table.remove(ret, i)
        end
      end
    end
  else
    ret = AiUtils:filterBiggerSuitDataArr(allSuitData, lastSuitData)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：all filter All Smaller Max Suit Data Arr
function AiCardTypeListData:ai_all_filterAllSmallerMaxSuitDataArr(suitDataArr)
  local ret = {}
  local maxSuitDataArr = self:ai_all_getMaxSuitDataArr()
  if 0 < #maxSuitDataArr then
    local keyMap = self:ai_all_getMaxSuitKeyMap()
    ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
    ret = AiUtils:filterAllSmallerSuitDataArr(maxSuitDataArr, ret)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：all filter All Smaller Not Bomb Max Suit Data Arr
function AiCardTypeListData:ai_all_filterAllSmallerNotBombMaxSuitDataArr(suitDataArr)
  local ret = {}
  local maxSuitDataArr = self:ai_all_getNotBombMaxSuitDataArr()
  if 0 < #maxSuitDataArr then
    local keyMap = self:ai_all_getNotBombMaxSuitKeyMap()
    ret = AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
    ret = AiUtils:filterAllSmallerSuitDataArr(maxSuitDataArr, ret)
  end
  return ret
end

-- AiCardTypeList · AI手牌层：filter Has Match Friend Win Condition Suit Data Arr
function AiCardTypeListData:ai_filterHasMatchFriendWinConditionSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    local enemyBiggerSuitDataArr = self.enemy1:ai_all_filterBiggerSuitDataArr(suitData)
    local enemyBiggerMisMatchWinCondition = self.friend:ai_filterMismatchWinCondition(enemyBiggerSuitDataArr)
    if #enemyBiggerMisMatchWinCondition == 0 then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：lun With Remove Suit Data
function AiCardTypeListData:ai_lunWithRemoveSuitData(suitData)
  if self:getCardCount() == suitData:getCardCount() then
    return 0
  end
  local ret = 100
  local isEnableEnd = false
  local didRemove, countMap = self:removeCardTypeWithSuitData(suitData)
  if didRemove then
    local params = {
      me = self,
      enemy1 = self.enemy1,
      enemy2 = self.enemy2,
      friend = self.friend,
      lazi = self:getLazi(),
      async = self:getAsync(),
    }
    local fenzuData = AiBestFenzu.new(params)
    local bestFenzuInfo = fenzuData:getBestFenzuInfo()
    ret = bestFenzuInfo.lun
    isEnableEnd = 0 < #fenzuData:getWinConditions()
    self:addCardTypeWithMap(countMap)
  end
  return ret, isEnableEnd
end

-- AiCardTypeList · AI手牌层：still filter Not More Lun Suit Data Arr
function AiCardTypeListData:ai_still_filterNotMoreLunSuitDataArr(suitDataArr)
  local ret = {}
  local bestFenzuData = self:ai_getBestFenzuData()
  local lun = bestFenzuData.lun_
  for _, suitData in ipairs(suitDataArr) do
    local tmpLun, isEnableEnd = self:ai_lunWithRemoveSuitData(suitData)
    if lun >= tmpLun or tmpLun <= 0 then
      table.insert(ret, suitData)
    elseif isEnableEnd then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：landlord still filter Not Lose Suit Data Arr
function AiCardTypeListData:ai_landlord_still_filterNotLoseSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.enemy2 == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local enemyDataClone2 = self.enemy2:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.enemy2 = enemyDataClone2
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.friend = enemyDataClone2
      enemyDataClone2.enemy1 = dataClone
      enemyDataClone2.friend = enemyDataClone1
      local isLose = dataClone:ai_getIsLose()
      if not isLose then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Right still filter Has Match Friend Win Condition Suit Data Arr
function AiCardTypeListData:ai_farmerRight_still_filterHasMatchFriendWinConditionSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local allSuitData = dataClone:ai_all_getSuitDataArr()
      local matchWinConditionSuitDataArr = friendDataClone:ai_filterMatchWinCondition(allSuitData)
      if 0 < #matchWinConditionSuitDataArr then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Right still filter Friend Smaller Max And Friend Not Lose Suit Data Arr
function AiCardTypeListData:ai_farmerRight_still_filterFriendSmallerMaxAndFriendNotLoseSuitDataArr(
  suitDataArr,
  isNotDisBomb
)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local allSuitData
      if isNotDisBomb then
        allSuitData = dataClone:ai_all_getNotDisBombSuitDataArr()
      else
        allSuitData = dataClone:ai_all_getSuitDataArr()
      end
      local smallerMaxSuitDataArr = friendDataClone:ai_bestFenzu_filterAllSmallerMaxSuitDataArr(allSuitData)
      if 0 < #smallerMaxSuitDataArr then
        local friendIsLose = friendDataClone:ai_getIsLose()
        if not friendIsLose then
          table.insert(ret, suitData)
        end
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Right still filter Not Lost Suit Data Arr
function AiCardTypeListData:ai_farmerRight_still_filterNotLostSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local isLose = dataClone:ai_getIsLose()
      if not isLose then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Right still filter Has Friend Lmax Suit Data Arr
function AiCardTypeListData:ai_farmerRight_still_filterHasFriendLmaxSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local bestSuitDataArr = dataClone:ai_all_getNotDisBombSuitDataArr()
      local smallerLmaxSuitDataArr = friendDataClone:ai_liu_filterSmallerLmaxSuitDataArr(bestSuitDataArr)
      if 0 < #smallerLmaxSuitDataArr then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Left still filter Has Match Friend Win Condition Suit Data Arr
function AiCardTypeListData:ai_farmerLeft_still_filterHasMatchFriendWinConditionSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local allSuitData = dataClone:ai_all_getNotDisBombSuitDataArr()
      local n5 = friendDataClone:ai_filterMatchWinCondition(allSuitData)
      if 0 < #n5 then
        for _, tmpSuitData in ipairs(n5) do
          local enemyBiggerSuitDataArr = enemyDataClone1:ai_all_filterBiggerSuitDataArr(tmpSuitData)
          local enemyBiggerMisMatchWinCondition = friendDataClone:ai_filterMismatchWinCondition(enemyBiggerSuitDataArr)
          if #enemyBiggerMisMatchWinCondition == 0 then
            table.insert(ret, suitData)
            break
          end
        end
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Left still filter Has Friend Lmax Or Smaller Max Suit Data Arr
function AiCardTypeListData:ai_farmerLeft_still_filterHasFriendLmaxOrSmallerMaxSuitDataArr(suitDataArr, lastSuitData)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local allSuitData = dataClone:ai_all_getSuitDataArr()
      local smallerMaxSuitDataArr = friendDataClone:ai_bestFenzu_filterAllSmallerMaxSuitDataArr(allSuitData)
      if 0 < #smallerMaxSuitDataArr then
        table.insert(ret, suitData)
      else
        local smallerLmaxSuitDataArr = friendDataClone:ai_liu_filterSmallerLmaxSuitDataArr(allSuitData)
        if 0 < #smallerLmaxSuitDataArr then
          local maxSmallerLmaxSuitDataArr = AiUtils:filterNotBombMaxSuitDataArr(smallerLmaxSuitDataArr)
          if 0 < #maxSmallerLmaxSuitDataArr then
            table.insert(ret, suitData)
            break
          end
        end
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer Left still filter Not Lose Or Friend Smaller Max Suit Data Arr
function AiCardTypeListData:ai_farmerLeft_still_filterNotLoseOrFriendSmallerMaxSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local isLose = dataClone:ai_getIsLose()
      if not isLose then
        table.insert(ret, suitData)
      else
        local friendIsLose = friendDataClone:ai_getIsLose()
        if not friendIsLose then
          local allSuitData = dataClone:ai_all_getNotDisBombSuitDataArr()
          local mismatchWinConditionArr = enemyDataClone1:ai_filterMismatchWinCondition(allSuitData)
          local smallerMaxSuitDataArr =
            friendDataClone:ai_bestFenzu_filterAllSmallerMaxSuitDataArr(mismatchWinConditionArr)
          if 0 < #smallerMaxSuitDataArr then
            table.insert(ret, suitData)
          else
            local firstMaxSuitDataArr =
              friendDataClone:ai_bestFenzu_filterAllSmallerFirstMaxSuitDataArr(mismatchWinConditionArr)
            if 0 < #firstMaxSuitDataArr then
              table.insert(ret, suitData)
            end
          end
        end
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：landlord still filter Farmer Lose Suit Data Arr
function AiCardTypeListData:ai_landlord_still_filterFarmerLoseSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.enemy2 == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local enemyDataClone2 = self.enemy2:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.enemy2 = enemyDataClone2
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.friend = enemyDataClone2
      enemyDataClone2.enemy1 = dataClone
      enemyDataClone2.friend = enemyDataClone1
      local enemyIsLose1 = enemyDataClone1:ai_getIsLose()
      local enemyIsLose2 = enemyDataClone2:ai_getIsLose()
      if enemyIsLose1 and enemyIsLose2 then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：farmer still filter Landlord Lost Suit Data Arr
function AiCardTypeListData:ai_farmer_still_filterLandlordLostSuitDataArr(suitDataArr)
  if self.enemy1 == nil or self.friend == nil then
    return {}
  end
  local ret = {}
  local cardCount = self:getCardCount()
  for _, suitData in ipairs(suitDataArr) do
    if cardCount == suitData:getCardCount() then
      table.insert(ret, suitData)
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local enemyIsLose = enemyDataClone1:ai_getIsLose()
      if enemyIsLose then
        table.insert(ret, suitData)
      end
      if self:getAsync() then
        coroutine.yield()
      end
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：still filter Is Enemy Win Condition
function AiCardTypeListData:ai_still_filterIsEnemyWinCondition(suitData)
  local direction = self:getDirection()
  if direction ~= nil then
    if direction == 1 and (self.enemy1 == nil or self.enemy2 == nil) then
      return false
    elseif direction ~= 1 and (self.enemy1 == nil or self.friend == nil) then
      return false
    end
  else
    return false
  end
  local ret = false
  local cardCount = self:getCardCount()
  if cardCount == suitData:getCardCount() then
    ret = false
  else
    if direction == 1 then
      local enemyDataClone1 = self.enemy1:clone()
      local enemyDataClone2 = self.enemy2:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.enemy2 = enemyDataClone2
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.friend = enemyDataClone2
      enemyDataClone2.enemy1 = dataClone
      enemyDataClone2.friend = enemyDataClone1
      local allSuitData = { suitData }
      local matchWinConditionSuitDataArr = enemyDataClone1:ai_filterMatchWinCondition(allSuitData)
      if 0 < #matchWinConditionSuitDataArr then
        ret = true
      else
        matchWinConditionSuitDataArr = enemyDataClone2:ai_filterMatchWinCondition(allSuitData)
        if 0 < #matchWinConditionSuitDataArr then
          ret = true
        end
      end
    else
      local enemyDataClone1 = self.enemy1:clone()
      local friendDataClone = self.friend:clone()
      local dataClone = self:clone()
      dataClone:removeCardTypeWithSuitData(suitData)
      dataClone.enemy1 = enemyDataClone1
      dataClone.friend = friendDataClone
      enemyDataClone1.enemy1 = dataClone
      enemyDataClone1.enemy2 = friendDataClone
      friendDataClone.enemy1 = enemyDataClone1
      friendDataClone.friend = dataClone
      local allSuitData = { suitData }
      local matchWinConditionSuitDataArr = enemyDataClone1:ai_filterMatchWinCondition(allSuitData)
      if 0 < #matchWinConditionSuitDataArr then
        ret = true
      end
    end
    if self:getAsync() then
      coroutine.yield()
    end
  end
  return ret
end

-- AiCardTypeList · AI手牌层：clear
function AiCardTypeListData:ai_clear()
  self.bestFenzu_ = nil
  self.bestFenzuData_ = nil
  self.winConditions_ = nil
  self.enableEnd_ = nil
  self.firstMaxSuitDataArr_ = nil
  self.maxSuitDataArr_ = nil
  self.minSuitDataArr_ = nil
  self.firstMaxSuitKeyMap_ = nil
  self.maxSuitKeyMap_ = nil
  self.mustEndSuitKeyMap_ = nil
  self.liuSuitDataArr_ = nil
  self.mustLiuSuitDataArr_ = nil
  self.liuKeyMap_ = nil
  self.ai_allSuitDataArr_ = nil
  self.ai_allSimpleSuitDataArr_ = nil
  self.bestFenzuSplitBringSuitDataArr_ = nil
end

-- AiCardTypeList · test
function AiCardTypeListData:test() end

return AiCardTypeListData
