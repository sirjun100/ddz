-- 文件: AiUtils.lua · 反编译 AI 模块（阅读用）

local AiUtils = {}
local CardTypeMap = {
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 14,
  [15] = 15,
  [16] = 3,
  [17] = 4,
  [18] = 5,
  [19] = 6,
  [20] = 7,
  [21] = 8,
  [22] = 9,
  [23] = 10,
  [24] = 11,
  [25] = 12,
  [26] = 13,
  [27] = 14,
  [28] = 15,
  [29] = 3,
  [30] = 4,
  [31] = 5,
  [32] = 6,
  [33] = 7,
  [34] = 8,
  [35] = 9,
  [36] = 10,
  [37] = 11,
  [38] = 12,
  [39] = 13,
  [40] = 14,
  [41] = 15,
  [42] = 3,
  [43] = 4,
  [44] = 5,
  [45] = 6,
  [46] = 7,
  [47] = 8,
  [48] = 9,
  [49] = 10,
  [50] = 11,
  [51] = 12,
  [52] = 13,
  [53] = 14,
  [54] = 15,
  [55] = 16,
  [56] = 17,
}

-- AiUtils · 牌 id 转牌点 CardType
function AiUtils:cardIdToCardType(cardId)
  return CardTypeMap[cardId]
end

-- AiUtils · 牌 id 列表转牌点列表
function AiUtils:cardIdListToCardTypeList(cardIdList)
  local ret = {}
  for _, cardId in ipairs(cardIdList) do
    table.insert(ret, AiUtils:cardIdToCardType(cardId))
  end
  return ret
end

-- AiUtils · AiCardData 数组转牌 id 列表
function AiUtils:cardDataArrToCardIdList(cardDataArr)
  local ret = {}
  for _, cardData in ipairs(cardDataArr) do
    table.insert(ret, cardData:getId())
  end
  return ret
end

-- AiUtils · 牌 id 列表转 AiCardData 数组
function AiUtils:cardIdListToCardDataArr(cardIdList, lazi)
  local ret = {}
  for _, cardId in ipairs(cardIdList) do
    local cardData = AiCardData.new(cardId)
    if cardId == lazi then
      cardData:setIsLazi(true)
    end
    table.insert(ret, cardData)
  end
  return ret
end

-- AiUtils · 从牌型数组中取最小一手
function AiUtils:getMinSuitDataWithArr(suitDataArr)
  if suitDataArr == nil or #suitDataArr == 0 then
    return nil
  end
  local tmp, level, tmpLevle
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() == SuitType.kStraight then
      level = suitData:getLevel() - 3
    else
      level = suitData:getLevel()
    end
    if
      tmp == nil
      or suitData:getType() == SuitType.kBomb and tmp:isWin(suitData)
      or suitData:getType() ~= SuitType.kBomb and tmpLevle > level
    then
      tmp = suitData
      tmpLevle = level
    end
  end
  return tmp
end

-- AiUtils · 从牌型数组中取最大一手
function AiUtils:getMaxSuitDataWithArr(suitDataArr)
  if suitDataArr == nil or #suitDataArr == 0 then
    return nil
  end
  local tmp, level, tmpLevle
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() == SuitType.kStraight then
      level = suitData:getLevel() - 3
    else
      level = suitData:getLevel()
    end
    if tmp == nil or suitData:getType() == SuitType.kBomb and tmp:isWin(suitData) or tmpLevle < level then
      tmp = suitData
      tmpLevle = level
    end
  end
  return tmp
end

-- AiUtils · 牌型dataarr转换为牌型dataarrdict
function AiUtils:suitDataArrToSuitDataArrDict(suitDataArr)
  if suitDataArr == nil or #suitDataArr == 0 then
    return {}
  end
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    local key = suitData:getKey()
    if ret[key] == nil then
      ret[key] = {}
    end
    table.insert(ret[key], suitData)
  end
  return ret
end

-- AiUtils · 计算分组下的收官条件
function AiUtils:getWinConditions(cardTypeListData, suitDataArr, lastSuitData, clear1, clear2, _enemyBombArr)
  local ret = {}
  local maybeLastSuitDataArr = {}
  local enemy1 = cardTypeListData.enemy1
  local enemy2 = cardTypeListData.enemy2
  if not enemy1 then
    return {}, {}
  end
  local bestSuitDataArr = suitDataArr or cardTypeListData:ai_getBestSuitDataArr()
  if #bestSuitDataArr == 1 and not self:checkNotBombSuitDataHasBomb(bestSuitDataArr[1]) then
    ret = bestSuitDataArr
    maybeLastSuitDataArr = bestSuitDataArr
    return ret, maybeLastSuitDataArr
  end
  local bombArr = {}
  local notBombArr = {}
  for _, suitData in ipairs(bestSuitDataArr) do
    if suitData:getType() <= SuitType.kBomb then
      table.insert(bombArr, suitData)
    else
      table.insert(notBombArr, suitData)
    end
  end
  local enemyBombArr = _enemyBombArr or {}
  if #bombArr == 1 and #enemyBombArr == 0 then
    local tmpRet, tmpMaybeLastSuitDataArr
    if enemy2 == nil and enemy1:getCardCount() == 1 then
      tmpRet, tmpMaybeLastSuitDataArr = self:getWinConditionsFor4211(bestSuitDataArr)
      if tmpRet then
        table.insertto(ret, tmpRet)
        table.insertto(maybeLastSuitDataArr, tmpMaybeLastSuitDataArr)
      end
    end
    if tmpRet == nil then
      tmpRet, tmpMaybeLastSuitDataArr = self:getWinConditionsFor421(bestSuitDataArr)
      if tmpRet then
        table.insertto(ret, tmpRet)
        table.insertto(maybeLastSuitDataArr, tmpMaybeLastSuitDataArr)
      end
    end
  elseif #bombArr == 2 and 0 < #enemyBombArr and #bestSuitDataArr == 4 then
    local maxBombArr = {}
    local minBomb
    for _, suitData in ipairs(bombArr) do
      local flag = true
      for _, enemySuitData in ipairs(enemyBombArr) do
        if not suitData:isWin(enemySuitData) then
          flag = false
          minBomb = suitData
          break
        end
      end
      if flag then
        table.insert(maxBombArr, suitData)
      end
    end
    if 1 <= #maxBombArr then
      if 1 < #maxBombArr then
        AiSuitData:sortSuits(maxBombArr)
        minBomb = maxBombArr[1]
      end
      local tmpRet = self:getWinConditionsFor442(bestSuitDataArr, maxBombArr[#maxBombArr], minBomb)
      if tmpRet then
        table.insertto(ret, tmpRet)
      end
    end
  elseif #bestSuitDataArr == 2 and lastSuitData == nil and #bombArr == 1 and #notBombArr == 1 then
    local otherSuitCount = notBombArr[1]:getCardCount()
    local enemy1CardCount = enemy1:getCardCount()
    local enemy2CardCount = enemy2 ~= nil and enemy2:getCardCount() or 0
    if otherSuitCount ~= enemy1CardCount and otherSuitCount ~= enemy2CardCount then
      table.insertto(ret, notBombArr)
      return ret, maybeLastSuitDataArr
    end
  end
  local disableSuitData
  if clear1 or clear2 then
    for _, suitData in ipairs(bestSuitDataArr) do
      if clear1 and clear1:isWin(suitData) or clear2 and clear2:isWin(suitData) then
        if disableSuitData then
          return ret, maybeLastSuitDataArr
        end
        disableSuitData = suitData
      end
    end
  end
  local bombTypeList = {}
  local enemyBombTypeList = {}
  for _, bomb in ipairs(bombArr) do
    local level = bomb:getLevel()
    local isLaziBomb = bomb:isLaziBomb()
    local isLazi = bomb:getIsLazi()
    if isLaziBomb then
      level = 15 + level / 16
    elseif isLazi then
      level = level / 16
    end
    table.insert(bombTypeList, level)
  end
  table.sort(bombTypeList, function(a, b)
    return b < a
  end)
  for _, bomb in ipairs(enemyBombArr) do
    local level = bomb:getLevel()
    local isLaziBomb = bomb:isLaziBomb()
    local isLazi = bomb:getIsLazi()
    if isLaziBomb then
      level = 15 + level / 16
    elseif isLazi then
      level = level / 16
    end
    table.insert(enemyBombTypeList, level)
  end
  table.sort(enemyBombTypeList, function(a, b)
    return b < a
  end)
  local winBombCount = AiUtils:pkBomb(bombTypeList, enemyBombTypeList)
  local bombLun, bombLunMinCount = AiUtils:bestCalculateLun(bombTypeList, enemyBombTypeList)
  if winBombCount < 0 then
    if #bombArr == 0 then
      return ret, maybeLastSuitDataArr
    elseif 1 < bombLun + #notBombArr then
      return ret, maybeLastSuitDataArr
    end
  end
  local maxSuitDataArr = {}
  local equalMaxSuitDataArr = {}
  local otherSuitDataArr = {}
  for _, suitData in ipairs(notBombArr) do
    local biggerCount = suitData:getBiggerCount()
    local equalCount = suitData:getEqualCount()
    local smallerCount = suitData:getSmallerCount()
    if biggerCount == 0 then
      if equalCount == 0 then
        table.insert(maxSuitDataArr, suitData)
      else
        table.insert(equalMaxSuitDataArr, suitData)
      end
    else
      table.insert(otherSuitDataArr, suitData)
    end
  end
  local isAllSuit = false
  if 0 < #bombArr and bombLun + #notBombArr <= 1 then
    ret = {}
    if bombLun + #notBombArr == 1 then
      AiSuitData:sortSuits(bombArr)
      for i = 1, bombLunMinCount do
        table.insert(ret, bombArr[i])
      end
      table.insertto(ret, notBombArr)
    elseif bombLun + #notBombArr < 1 then
      table.insertto(ret, bombArr)
      table.insertto(ret, notBombArr)
    end
    if #ret == #bestSuitDataArr then
      isAllSuit = true
    end
    if disableSuitData then
      for i, suitData in ipairs(ret) do
        if suitData == disableSuitData then
          table.remove(ret, i)
          break
        end
      end
      table.insert(maybeLastSuitDataArr, disableSuitData)
    else
      table.insertto(maybeLastSuitDataArr, ret)
    end
  end
  if isAllSuit then
    return ret, maybeLastSuitDataArr
  end
  if winBombCount < 0 then
    return ret, maybeLastSuitDataArr
  end
  local remainCount = #otherSuitDataArr - (#maxSuitDataArr + #equalMaxSuitDataArr + winBombCount)
  if disableSuitData then
    remainCount = remainCount + 1
  end
  if 1 < remainCount then
    return ret, maybeLastSuitDataArr
  end
  local maxSuitDataArrDict = AiUtils:suitDataArrToSuitDataArrDict(maxSuitDataArr)
  local equalMaxSuitDataArrDict = AiUtils:suitDataArrToSuitDataArrDict(equalMaxSuitDataArr)
  local otherSuitDataArrDict = AiUtils:suitDataArrToSuitDataArrDict(otherSuitDataArr)
  local remainCount = 0 - winBombCount
  if disableSuitData then
    remainCount = remainCount + 1
  end
  local lastSuitDataArr = {}
  local middleSuitDataArr = {}
  for key, suitDataArr in pairs(otherSuitDataArrDict) do
    local tmpMaxSuitDataArr = maxSuitDataArrDict[key] or {}
    local count1 = #suitDataArr
    local count2 = #tmpMaxSuitDataArr
    local count = math.max(0, count1 - count2)
    remainCount = remainCount + count
    if disableSuitData and 0 < count and table.indexof(suitDataArr, disableSuitData) then
      remainCount = remainCount - 1
    end
    if 1 < remainCount then
      return ret, maybeLastSuitDataArr
    end
  end
  if remainCount < 1 then
    if 0 < winBombCount then
      AiSuitData:sortSuits(bombArr)
      for i = 1, winBombCount do
        table.insert(ret, bombArr[i])
      end
    end
    table.insertto(ret, notBombArr)
    if disableSuitData then
      for i, suitData in ipairs(ret) do
        if suitData == disableSuitData then
          table.remove(ret, i)
          break
        end
      end
      table.insert(maybeLastSuitDataArr, disableSuitData)
    else
      table.insertto(maybeLastSuitDataArr, ret)
    end
    ret = AiUtils:deDuplicationWithSuitDataArr(ret)
    maybeLastSuitDataArr = AiUtils:deDuplicationWithSuitDataArr(maybeLastSuitDataArr)
    return ret, maybeLastSuitDataArr
  end
  local allWinSuitData = {}
  local lastEqualSuitDataArr = {}
  local useWinBombCount = winBombCount
  for key, suitDataArr in pairs(otherSuitDataArrDict) do
    local tmpMaxSuitDataArr = maxSuitDataArrDict[key] or {}
    local tmpEqualMaxSuitDataArr = equalMaxSuitDataArrDict[key] or {}
    local count1 = #suitDataArr
    local count2 = #tmpMaxSuitDataArr
    if count1 - count2 - useWinBombCount == 1 then
      if 0 < count2 + useWinBombCount then
        table.insertto(allWinSuitData, suitDataArr)
        table.insertto(allWinSuitData, tmpEqualMaxSuitDataArr)
      elseif 0 < #tmpEqualMaxSuitDataArr then
        table.insertto(lastEqualSuitDataArr, tmpEqualMaxSuitDataArr)
      else
        table.insertto(lastSuitDataArr, suitDataArr)
      end
    elseif count1 - count2 - useWinBombCount == 0 then
      table.insertto(allWinSuitData, suitDataArr)
      table.insertto(middleSuitDataArr, tmpEqualMaxSuitDataArr)
      table.insertto(middleSuitDataArr, tmpMaxSuitDataArr)
    else
      table.insertto(allWinSuitData, suitDataArr)
      table.insertto(allWinSuitData, tmpEqualMaxSuitDataArr)
      table.insertto(allWinSuitData, tmpMaxSuitDataArr)
    end
    maxSuitDataArrDict[key] = nil
    equalMaxSuitDataArrDict[key] = nil
  end
  for key, tmpMaxSuitDataArr in pairs(maxSuitDataArrDict) do
    table.insertto(allWinSuitData, tmpMaxSuitDataArr)
  end
  for key, tmpMaxSuitDataArr in pairs(equalMaxSuitDataArrDict) do
    table.insertto(allWinSuitData, tmpMaxSuitDataArr)
  end
  if #lastSuitDataArr == 0 and #lastEqualSuitDataArr == 0 and 0 < #middleSuitDataArr then
    table.insertto(allWinSuitData, middleSuitDataArr)
  end
  if 0 < #allWinSuitData then
    table.insertto(ret, allWinSuitData)
  else
    table.insertto(ret, lastSuitDataArr)
  end
  if 0 < #lastEqualSuitDataArr then
    table.insertto(ret, lastEqualSuitDataArr)
  end
  if disableSuitData then
    for i, suitData in ipairs(ret) do
      if suitData == disableSuitData then
        table.remove(ret, i)
        break
      end
    end
    table.insert(maybeLastSuitDataArr, disableSuitData)
  elseif 0 < #lastSuitDataArr then
    table.insertto(maybeLastSuitDataArr, lastSuitDataArr)
  else
    table.insertto(maybeLastSuitDataArr, ret)
  end
  ret = AiUtils:deDuplicationWithSuitDataArr(ret)
  maybeLastSuitDataArr = AiUtils:deDuplicationWithSuitDataArr(maybeLastSuitDataArr)
  return ret, maybeLastSuitDataArr
end

-- AiUtils · 获取赢牌/收官conditionsfor421
function AiUtils:getWinConditionsFor421(suitDataArr)
  if #suitDataArr ~= 4 then
    return nil
  end
  local bombArr = {}
  local singleSuitDataArr = {}
  local pairSuitDataArr = {}
  local otherSuitDataArr = {}
  for _, suitData in ipairs(suitDataArr) do
    local suitType = suitData:getType()
    if suitType == SuitType.kBomb then
      table.insert(bombArr, suitData)
    elseif suitType == SuitType.kSingle and #singleSuitDataArr < 2 then
      table.insert(singleSuitDataArr, suitData)
    elseif suitType == SuitType.kPair and #pairSuitDataArr < 2 then
      table.insert(pairSuitDataArr, suitData)
    else
      table.insert(otherSuitDataArr, suitData)
    end
  end
  if #bombArr ~= 1 then
    return nil
  end
  if #singleSuitDataArr == 2 then
    local arr = bombArr
    table.insertto(arr, singleSuitDataArr)
    local suitData = AiSuitFourWithTwoSingleData:createWithSuitDataArr(arr)
    if suitData then
      local ret = { suitData }
      local maybeLastSuitDataArr
      if #pairSuitDataArr == 1 then
        maybeLastSuitDataArr = pairSuitDataArr
      else
        maybeLastSuitDataArr = otherSuitDataArr
      end
      return ret, maybeLastSuitDataArr
    else
      return nil
    end
  elseif #pairSuitDataArr == 2 then
    local arr = bombArr
    table.insertto(arr, pairSuitDataArr)
    local suitData = AiSuitFourWithTwoPairData:createWithSuitDataArr(arr)
    if suitData then
      local ret = { suitData }
      local maybeLastSuitDataArr
      if #singleSuitDataArr == 1 then
        maybeLastSuitDataArr = singleSuitDataArr
      else
        maybeLastSuitDataArr = otherSuitDataArr
      end
      return ret, maybeLastSuitDataArr
    else
      return nil
    end
  else
    return nil
  end
end

-- AiUtils · 获取赢牌/收官conditionsfor4211
function AiUtils:getWinConditionsFor4211(suitDataArr)
  if #suitDataArr ~= 4 then
    return nil
  end
  local bombArr = {}
  local singleSuitDataArr = {}
  local pairSuitDataArr = {}
  local otherSuitDataArr = {}
  for _, suitData in ipairs(suitDataArr) do
    local suitType = suitData:getType()
    if suitType == SuitType.kBomb then
      table.insert(bombArr, suitData)
    elseif suitType == SuitType.kSingle then
      table.insert(singleSuitDataArr, suitData)
    elseif suitType == SuitType.kPair then
      table.insert(pairSuitDataArr, suitData)
    else
      table.insert(otherSuitDataArr, suitData)
    end
  end
  if #bombArr ~= 1 then
    return nil
  end
  if #singleSuitDataArr == 3 then
    local arr = bombArr
    table.insertto(arr, {
      singleSuitDataArr[1],
      singleSuitDataArr[2],
    })
    local suitData = AiSuitFourWithTwoSingleData:createWithSuitDataArr(arr)
    if suitData then
      local ret = { suitData }
      local maybeLastSuitDataArr = {
        singleSuitDataArr[3],
      }
      return ret, maybeLastSuitDataArr
    else
      return nil
    end
  else
    return nil
  end
end

-- AiUtils · 获取赢牌/收官conditionsfor442
function AiUtils:getWinConditionsFor442(suitDataArr, maxBomb, minBomb)
  local singleSuitDataArr = {}
  local pairSuitDataArr = {}
  local otherSuitDataArr = {}
  for _, suitData in ipairs(suitDataArr) do
    local suitType = suitData:getType()
    if suitType == SuitType.kSingle and #singleSuitDataArr < 2 then
      table.insert(singleSuitDataArr, suitData)
    elseif suitType == SuitType.kPair and #pairSuitDataArr < 2 then
      table.insert(pairSuitDataArr, suitData)
    else
      table.insert(otherSuitDataArr, suitData)
    end
  end
  if #singleSuitDataArr == 2 then
    local arr = { minBomb }
    table.insertto(arr, singleSuitDataArr)
    local suitData = AiSuitFourWithTwoSingleData:createWithSuitDataArr(arr)
    if suitData then
      local ret = { maxBomb, suitData }
      return ret
    else
      return nil
    end
  elseif #pairSuitDataArr == 2 then
    local arr = { minBomb }
    table.insertto(arr, pairSuitDataArr)
    local suitData = AiSuitFourWithTwoPairData:createWithSuitDataArr(arr)
    if suitData then
      local ret = { maxBomb, suitData }
      return ret
    else
      return nil
    end
  else
    return nil
  end
end

-- AiUtils · 最强calculate轮次
function AiUtils:bestCalculateLun(cardTypeList, enemyCardTypeList)
  local r1 = enemyCardTypeList
  local r2 = cardTypeList
  local sumCount = #r2
  local r4t = {}
  for index, cardType in ipairs(r2) do
    local count = 0
    for _, enemyCardType in ipairs(r1) do
      if cardType < enemyCardType then
        count = count + 1
      else
        break
      end
    end
    r4t[index] = count
  end
  local r5t = {}
  for i = 1, sumCount do
    r5t[i] = i - r4t[i]
  end
  local r6t = {}
  for i = 1, sumCount do
    r6t[i] = r5t[i] - r4t[i]
  end
  local r4 = {}
  for index, cardType in ipairs(r2) do
    local count = 0
    local equal = r6t[index] <= 0
    for _, enemyCardType in ipairs(r1) do
      if equal then
        if enemyCardType >= cardType then
          count = count + 1
        else
          break
        end
      elseif enemyCardType > cardType then
        count = count + 1
      else
        break
      end
    end
    r4[index] = count
  end
  local r5 = {}
  for i = 1, sumCount do
    r5[i] = i - r4[i]
  end
  local r6 = {}
  local minStartIndex = sumCount + 1
  for i = 1, sumCount do
    if 0 < r5[i] then
      r6[i] = r5[i] - r4[i]
    else
      minStartIndex = i
      break
    end
  end
  local minCount = sumCount - minStartIndex + 1
  local maxCount = 0
  for k, v in ipairs(r6) do
    if 0 < v then
      maxCount = maxCount + 1
    end
  end
  return minCount - maxCount, minCount, cardTypeList[minStartIndex]
end

-- AiUtils · correct单张轮次
function AiUtils:correctSingleLun(cardTypeList, enemyLeftCardType)
  local sumCount = #cardTypeList
  local minStartIndex = 0
  for index, cardType in ipairs(cardTypeList) do
    if cardType < enemyLeftCardType then
      minStartIndex = index
      break
    end
  end
  local minCount = sumCount - minStartIndex + 1
  return minCount
end

-- AiUtils · pk炸弹
function AiUtils:pkBomb(bombTypeList, enemyBombTypeList)
  if #bombTypeList < #enemyBombTypeList then
    return -1
  end
  if #enemyBombTypeList == 0 then
    return #bombTypeList
  end
  for index, bombType in ipairs(bombTypeList) do
    local enemyBombType = enemyBombTypeList[index]
    if enemyBombType == nil then
      return #bombTypeList - index + 1
    end
    if bombType < enemyBombType then
      return -1
    end
  end
  return 0
end

-- AiUtils · 获取maxlevel牌型data
function AiUtils:getMaxLevelSuitData(suitDataArr)
  if suitDataArr == nil or #suitDataArr == 0 then
    return nil
  end
  local ret
  for _, suitData in ipairs(suitDataArr) do
    if ret == nil or suitData:getLevel() > ret:getLevel() then
      ret = suitData
    end
  end
  return ret
end

-- AiUtils · 判断是否all炸弹
function AiUtils:isAllBomb(suitDataArr)
  local ret = true
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      ret = false
      break
    end
  end
  return ret
end

-- AiUtils · 判断是否all炸弹牌type
function AiUtils:isAllBombCardType(needCardCountList)
  local ret = true
  local cardTypeMap = {}
  for cardType, num in pairs(needCardCountList) do
    cardTypeMap[cardType] = cardTypeMap[cardType] or 0
    cardTypeMap[cardType] = cardTypeMap[cardType] + num
  end
  if cardTypeMap[16] ~= nil and cardTypeMap[17] ~= nil then
    cardTypeMap[16] = 4
    cardTypeMap[17] = 4
  end
  for cardType, num in pairs(cardTypeMap) do
    if num < 4 then
      ret = false
      break
    end
  end
  return ret
end

-- AiUtils · 判断是否all42
function AiUtils:isAll42(suitDataArr)
  local ret = true
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() ~= SuitType.kFourWithTwoPair and suitData:getType() ~= SuitType.kFourWithTwoSingle then
      ret = false
      break
    end
  end
  return ret
end

-- AiUtils · 获取is42牌型dataarr
function AiUtils:getIs42SuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr ~= nil then
    for _, suitData in ipairs(suitDataArr) do
      if suitData:getType() == SuitType.kFourWithTwoPair or suitData:getType() == SuitType.kFourWithTwoSingle then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 获取四张withtwo对子牌型dataarr
function AiUtils:getFourWithTwoPairSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr ~= nil then
    for _, suitData in ipairs(suitDataArr) do
      if suitData:getType() == SuitType.kFourWithTwoPair then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 判断是否allmax牌型data
function AiUtils:isAllMaxSuitData(suitDataArr)
  local ret = true
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      if 0 < biggerCount and not suitData.isQiangQuan then
        ret = false
        break
      end
    end
  end
  return ret
end

-- AiUtils · 判断是否allmaxmax牌型data
function AiUtils:isAllMaxMaxSuitData(suitDataArr)
  local ret = true
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb and suitData:getLevel() < CardType.kTwo then
      ret = false
      break
    end
  end
  return ret
end

-- AiUtils · 获取last牌型判断是否max牌型data
function AiUtils:getLastSuitIsMaxSuitData(cardTypeListData, enemyCardTypeListData, lastSuitData)
  if cardTypeListData == nil or enemyCardTypeListData == nil or lastSuitData == nil then
    return true
  end
  local bestFenzu = cardTypeListData:ai_getBestFenzu()
  local enemyAllSuitData
  if bestFenzu.enemy1AllSuitData ~= nil then
    enemyAllSuitData = bestFenzu.enemy1AllSuitData
  else
    enemyAllSuitData = {}
    table.insertto(enemyAllSuitData, enemyCardTypeListData:getAllSuitData())
    local bringSuitDataArr = AiUtils:bringSuitDataArr(enemyAllSuitData, enemyCardTypeListData, nil, true)
    table.insertto(enemyAllSuitData, bringSuitDataArr)
  end
  local biggerCount = 0
  for _, enemySuitData in ipairs(enemyAllSuitData) do
    if
      lastSuitData:getType() == enemySuitData:getType()
      and lastSuitData:getCardCount() == enemySuitData:getCardCount()
    then
      local meWin = lastSuitData:isWin(enemySuitData)
      if not meWin then
        local enemy1Win = enemySuitData:isWin(lastSuitData)
        if enemy1Win then
          biggerCount = biggerCount + 1
        end
      end
    end
  end
  return biggerCount == 0 or lastSuitData:getType() <= SuitType.kBomb or lastSuitData:getLevel() >= CardType.kTwo
end

-- AiUtils · 检查任务牌型
function AiUtils:checkTask(suitType, taskId)
  if not taskId then
    return false
  end
  local serverLastTaskType = SuitTypeToLastTaskIDMap[suitType]
  local lastTaskConfig = TableDataManager:getInstance():getLastCardTaskWithId(taskId)
  if serverLastTaskType ~= nil and lastTaskConfig ~= nil then
    for i, v in ipairs(lastTaskConfig:getType()) do
      if v == serverLastTaskType then
        return true
      end
    end
  end
  return false
end

-- AiUtils · 过滤not任务牌型牌型dataarr
function AiUtils:filterNotTaskSuitDataArr(suitDataArr, taskData)
  if taskData == nil then
    return suitDataArr
  end
  local notTaskArr = {}
  local taskArr = {}
  local id = taskData.id
  for _, suitData in ipairs(suitDataArr) do
    local suitType = suitData:getType()
    if not AiUtils:checkTask(suitType, id) then
      table.insert(notTaskArr, suitData)
    else
      table.insert(taskArr, suitData)
    end
  end
  if 0 < #notTaskArr and 1 < #taskArr then
    return suitDataArr
  else
    return notTaskArr
  end
end

-- AiUtils · 检查判断是否有任务牌型牌型dataarr
function AiUtils:checkHasTaskSuitDataArr(suitDataArr, taskData)
  if taskData == nil then
    return false
  end
  local ret = {}
  local id = taskData.id
  for _, suitData in ipairs(suitDataArr) do
    local suitType = suitData:getType()
    if AiUtils:checkTask(suitType, id) then
      return true
    end
  end
  return false
end

-- AiUtils · 过滤炸弹
function AiUtils:filterBomb(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() <= SuitType.kBomb then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤not炸弹
function AiUtils:filterNotBomb(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤notdis炸弹牌型dataarr
function AiUtils:filterNotDisBombSuitDataArr(suitDataArr, allBombSuitDataArr, lazi)
  local bombCardTypeList = {}
  local bombSuitDataArr = {}
  local notBombSuitDataArr = {}
  lazi = lazi or 0
  for _, suitData in ipairs(allBombSuitDataArr) do
    if
      suitData:getType() == SuitType.kBomb and (not (lazi ~= 0 and suitData:getIsLazi()) or suitData:getLevel() == lazi)
    then
      bombCardTypeList[suitData:getLevel()] = true
    else
    end
  end
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      table.insert(notBombSuitDataArr, suitData)
    else
      table.insert(bombSuitDataArr, suitData)
    end
  end
  local ret = bombSuitDataArr
  if #notBombSuitDataArr == 0 then
    return ret
  end
  local ret2 = {}
  for _, suitData in ipairs(notBombSuitDataArr) do
    local flag = true
    local needCardCountList = suitData:getNeedCardCountList()
    for cardType, num in pairs(needCardCountList) do
      if bombCardTypeList[cardType] then
        flag = false
        table.insert(ret2, suitData)
        break
      end
    end
    if flag then
      table.insert(ret, suitData)
    end
  end
  return ret, ret2
end

-- AiUtils · 过滤not42
function AiUtils:filterNot42(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() ~= SuitType.kFourWithTwoPair and suitData:getType() ~= SuitType.kFourWithTwoSingle then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤firstmax牌型dataarr
function AiUtils:filterFirstMaxSuitDataArr(suitDataArr)
  local ret = {}
  local maxPairLevel, maxThreeLevel = 0, 0
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb and suitData:getLevel() < 15 then
      local biggerCount = suitData:getBiggerCount()
      local smallerCount = suitData:getSmallerCount()
      local equalCount = suitData:getEqualCount()
      local type = suitData:getType()
      if
        type == SuitType.kSingle
        or type == SuitType.kPair
        or type == SuitType.kThree
        or type == SuitType.kThreeWithOneSingle
        or type == SuitType.kThreeWithOnePair
        or type == SuitType.kDoubleStraight
        or type == SuitType.kThreeStraight
        or type == SuitType.kThreeStraightWithSingle
        or type == SuitType.kThreeStraightWithPair
      then
        local useBombCount = suitData:getUseBombCount()
        if 0 < useBombCount then
          local useBombCountB = 0
          local useBombCountE = 0
          local useBombCountS = 0
          if 10000 <= useBombCount then
            useBombCountB = math.floor(useBombCount / 10000)
            useBombCount = useBombCount % 10000
            useBombCountE = math.floor(useBombCount / 100)
            useBombCountS = useBombCount % 100
          elseif 100 <= useBombCount then
            useBombCountE = math.floor(useBombCount / 100)
            useBombCountS = useBombCount % 100
          else
            useBombCountS = useBombCount
          end
          biggerCount = biggerCount - useBombCountB
          equalCount = equalCount - useBombCountE
          smallerCount = smallerCount - useBombCountS
        end
      end
      if biggerCount == 0 and smallerCount == 0 then
        table.insert(ret, suitData)
      end
      local suitLevel = suitData:getLevel()
      if type == SuitType.kPair and maxPairLevel < suitLevel then
        maxPairLevel = suitLevel
      elseif
        (type == SuitType.kThree or type == SuitType.kThreeWithOneSingle or type == SuitType.kThreeWithOnePair)
        and maxThreeLevel < suitLevel
      then
        maxThreeLevel = suitLevel
      end
    end
  end
  for i = #ret, 1, -1 do
    local suitData = ret[i]
    local type = suitData:getType()
    if
      (
        type == SuitType.kThreeStraight
        or type == SuitType.kThreeStraightWithSingle
        or type == SuitType.kThreeStraightWithPair
      )
      and 10 <= maxThreeLevel
      and maxThreeLevel < suitData:getLevel()
    then
      table.remove(ret, i)
    elseif type == SuitType.kDoubleStraight and 10 <= maxPairLevel and maxPairLevel < suitData:getLevel() then
      table.remove(ret, i)
    end
  end
  return ret
end

-- AiUtils · 过滤max牌型dataarr
function AiUtils:filterMaxSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      if biggerCount == 0 or suitData.isQiangQuan then
        table.insert(ret, suitData)
      end
    else
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤notmax牌型dataarr
function AiUtils:filterNotMaxSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      if 0 < biggerCount and not suitData.isQiangQuan then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤notmaxmax牌型dataarr
function AiUtils:filterNotMaxMaxSuitDataArr(suitDataArr)
  if suitDataArr == nil then
    dump(debug.traceback("", 2))
  end
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb and suitData:getLevel() < CardType.kTwo then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤not单张and对子牌型dataarr
function AiUtils:filterNotSingleAndPairSuitDataArr(suitDataArr)
  local ret = {}
  local suitDataType
  for _, suitData in ipairs(suitDataArr) do
    suitDataType = suitData:getType()
    if suitDataType ~= SuitType.kSingle and suitDataType ~= SuitType.kPair then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤not炸弹and四张withtwo牌型dataarr
function AiUtils:filterNotBombAndFourWithTwoSuitDataArr(suitDataArr)
  local ret = {}
  local suitDataType
  for _, suitData in ipairs(suitDataArr) do
    suitDataType = suitData:getType()
    if
      suitDataType > SuitType.kBomb
      and suitDataType ~= SuitType.kFourWithTwoPair
      and suitDataType ~= SuitType.kFourWithTwoSingle
    then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · 过滤not炸弹max牌型dataarr
function AiUtils:filterNotBombMaxSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      if biggerCount == 0 or suitData.isQiangQuan then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤min牌型dataarr
function AiUtils:filterMinSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      local smallerCount = suitData:getSmallerCount()
      if 0 < biggerCount and smallerCount == 0 then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤liu牌型dataarr
function AiUtils:filterLiuSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local biggerCount = suitData:getBiggerCount()
      if 0 < biggerCount and not suitData.isQiangQuan then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤smallertwoliu牌型dataarr
function AiUtils:filterSmallerTwoLiuSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb and suitData:getLevel() < CardType.kTwo then
      local biggerCount = suitData:getBiggerCount()
      if 0 < biggerCount then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤bigger牌型dataarr
function AiUtils:filterBiggerSuitDataArr(suitDataArr, lastSuitData)
  local ret = {}
  if lastSuitData == nil then
    ret = suitDataArr
  else
    for _, suitData in ipairs(suitDataArr) do
      if suitData:isWin(lastSuitData) then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤intersection牌型dataarr
function AiUtils:filterIntersectionSuitDataArr(aSuitDataArr, bSuitDataArr)
  local ret = {}
  if aSuitDataArr and bSuitDataArr and 0 < #aSuitDataArr and 0 < #bSuitDataArr then
    for _, aSuitData in ipairs(aSuitDataArr) do
      for _, bSuitData in ipairs(bSuitDataArr) do
        if aSuitData:getIdKey() == bSuitData:getIdKey() then
          table.insert(ret, aSuitData)
          break
        end
      end
    end
  end
  return ret
end

-- AiUtils · 过滤notsmaller牌型dataarr
function AiUtils:filterNotSmallerSuitDataArr(suitDataArr, lastSuitData)
  local ret = {}
  if lastSuitData == nil then
    ret = suitDataArr
  else
    for _, suitData in ipairs(suitDataArr) do
      if
        (lastSuitData:getType() == suitData:getType() or suitData:getType() <= SuitType.kBomb)
        and not lastSuitData:isWin(suitData)
      then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤allbigger牌型dataarr
function AiUtils:filterAllBiggerSuitDataArr(minSuitDataArr, suitDataArr)
  local ret = {}
  if 0 < #minSuitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local ok = true
      for _, minSuitData in ipairs(minSuitDataArr) do
        if minSuitData:isWin(suitData) then
          ok = false
          break
        end
      end
      if ok then
        table.insert(ret, suitData)
      end
    end
  else
    ret = suitDataArr
  end
  return ret
end

-- AiUtils · 过滤allsmaller牌型dataarr
function AiUtils:filterAllSmallerSuitDataArr(maxSuitDataArr, suitDataArr)
  local ret = {}
  if 0 < #maxSuitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      for _, maxSuitData in ipairs(maxSuitDataArr) do
        if maxSuitData:isWin(suitData) then
          table.insert(ret, suitData)
          break
        end
      end
    end
  end
  return ret
end

-- AiUtils · 过滤tryya牌型dataarr
function AiUtils:filterTryYaSuitDataArr(enemySuitDataArr, suitDataArr)
  local ret = {}
  local max = AiUtils:getMaxYaSuitData(enemySuitDataArr, suitDataArr)
  if max then
    for _, suitData in ipairs(suitDataArr) do
      if not max:isWin(suitData) then
        table.insert(ret, suitData)
      end
    end
  else
    ret = suitDataArr
  end
  return ret
end

-- AiUtils · 获取maxya牌型data
function AiUtils:getMaxYaSuitData(enemySuitDataArr, suitDataArr)
  local ret
  if 0 < #enemySuitDataArr and 0 < #suitDataArr then
    local smallerSuitDataArr = {}
    for _, enemySuitData in ipairs(enemySuitDataArr) do
      for _, suitData in ipairs(suitDataArr) do
        if not enemySuitData:isWin(suitData) then
          table.insert(smallerSuitDataArr, enemySuitData)
          break
        end
      end
    end
    if 0 < #smallerSuitDataArr then
      ret = AiUtils:getMaxLevelSuitData(smallerSuitDataArr)
    end
  end
  return ret
end

-- AiUtils · 过滤牌型dataarrwithkeymap
function AiUtils:filterSuitDataArrWithKeyMap(suitDataArr, keyMap)
  local ret = {}
  if next(keyMap) then
    for _, suitData in ipairs(suitDataArr) do
      if keyMap[suitData:getKey()] then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤notsamekey牌型dataarr
function AiUtils:filterNotSameKeySuitDataArr(suitDataArr, keyMap)
  local ret = {}
  if next(keyMap) then
    for _, suitData in ipairs(suitDataArr) do
      if not keyMap[suitData:getKey()] then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiUtils · 过滤not癞子牌型dataarr
function AiUtils:filterNotLaziSuitDataArr(suitDataArr, lazi, cardTypeListData)
  local ret = {}
  if lazi ~= nil and 0 < lazi then
    for _, suitData in ipairs(suitDataArr) do
      if suitData:getType() ~= lazi then
        local flag = false
        local needCardCountList = suitData:getNeedCardCountList()
        for cardType, num in pairs(needCardCountList) do
          if cardType == lazi then
            flag = true
            break
          else
            local haveNum = cardTypeListData:getCardCountWithType(cardType)
            if num > haveNum then
              flag = true
              break
            end
          end
        end
        if not flag then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

-- AiUtils · 过滤b牌型dataarrfroma牌型dataarr
function AiUtils:filterBSuitDataArrFromASuitDataArr(aSuitDataArr, bSuitDataArr)
  if bSuitDataArr == nil or #bSuitDataArr == 0 then
    return aSuitDataArr
  end
  local ret = {}
  for _, aSuitData in ipairs(aSuitDataArr) do
    local flag = true
    for _, bSuitData in ipairs(bSuitDataArr) do
      if aSuitData:getType() == bSuitData:getType() and aSuitData:getLevel() == bSuitData:getLevel() then
        flag = false
        break
      end
    end
    if flag then
      table.insert(ret, aSuitData)
    end
  end
  return ret
end

-- AiUtils · 过滤收官牌型databy对手left牌num
function AiUtils:filterEndSuitDataByEnemyLeftCardNum(suitDataArr, LeftCardNum1, LeftCardNum2)
  local ret = {}
  local suitType
  if LeftCardNum1 == 1 or LeftCardNum2 ~= nil and LeftCardNum2 == 1 then
    suitType = SuitType.kSingle
  else
    suitType = SuitType.kPair
  end
  local sameSuitDataArr = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      if suitData:getType() ~= suitType then
        table.insert(ret, suitData)
      else
        table.insert(sameSuitDataArr, suitData)
      end
    end
  end
  if #ret == 0 and 1 < #sameSuitDataArr then
    local biggerSuitData = sameSuitDataArr[1]
    for _, suitData in ipairs(sameSuitDataArr) do
      if suitData:getLevel() > biggerSuitData:getLevel() then
        biggerSuitData = suitData
      end
    end
    ret = { biggerSuitData }
  end
  return ret
end

-- AiUtils · 获取赢牌/收官牌型datanum
function AiUtils:getWinSuitDataNum(suitData, enemyAllSuitDataArr1, enemyAllSuitDataArr2)
  local winBombSuitData, winNotBombSuitData = {}, {}

  -- AiUtils ·
  local function checkIsSameCardType(arr, suitData)
    for i, v in ipairs(arr) do
      if
        v:getLevel() == suitData:getLevel()
        or v:getType() == SuitType.kDoubleJoker and (suitData:getLevel() == 16 or suitData:getLevel() == 17)
      then
        return true
      end
    end
    return false
  end

  local _suitData
  for i = #enemyAllSuitDataArr1, 1, -1 do
    _suitData = enemyAllSuitDataArr1[i]
    if
      not checkIsSameCardType(winBombSuitData, _suitData)
      and not checkIsSameCardType(winNotBombSuitData, _suitData)
      and _suitData:isWin(suitData)
    then
      if _suitData:getType() == SuitType.kBomb or _suitData:getType() == SuitType.kDoubleJoker then
        table.insert(winBombSuitData, _suitData)
      else
        table.insert(winNotBombSuitData, _suitData)
      end
    end
  end
  if enemyAllSuitDataArr2 ~= nil then
    for i = #enemyAllSuitDataArr2, 1, -1 do
      _suitData = enemyAllSuitDataArr2[i]
      if
        not checkIsSameCardType(winBombSuitData, _suitData)
        and not checkIsSameCardType(winNotBombSuitData, _suitData)
        and _suitData:isWin(suitData)
      then
        if _suitData:getType() == SuitType.kBomb or _suitData:getType() == SuitType.kDoubleJoker then
          table.insert(winBombSuitData, _suitData)
        else
          table.insert(winNotBombSuitData, _suitData)
        end
      end
    end
  end
  return #winBombSuitData, #winNotBombSuitData
end

-- AiUtils · 获取keymapwith牌型dataarr
function AiUtils:getKeyMapWithSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    ret[suitData:getKey()] = true
  end
  return ret
end

-- AiUtils · 获取samekeymap
function AiUtils:getSameKeyMap(keyMap, otherKeyMap)
  local ret = {}
  for key, _ in pairs(keyMap) do
    if otherKeyMap[key] then
      ret[key] = true
    end
  end
  return ret
end

-- AiUtils · 获取notsamekeymap
function AiUtils:getNotSameKeyMap(keyMap, otherKeyMap)
  local ret = {}
  for key, _ in pairs(keyMap) do
    if not otherKeyMap[key] then
      ret[key] = true
    end
  end
  return ret
end

-- AiUtils · aiselected牌
function AiUtils:aiSelectedCard(cardIdList, lazi, didSort, hasLazi)
  if #cardIdList <= 4 then
    return cardIdList
  end
  local tmpCardTypeList = AiUtils:cardIdListToCardTypeList(cardIdList)
  if not didSort then
    table.sort(tmpCardTypeList, function(a, b)
      return a < b
    end)
  end
  if hasLazi and tmpCardTypeList[1] == tmpCardTypeList[2] then
    return cardIdList
  end
  local maxCardType = tmpCardTypeList[#tmpCardTypeList]
  local minCardType = tmpCardTypeList[1]
  if 15 <= maxCardType or maxCardType - minCardType < 4 then
    return cardIdList
  end
  local cardListData = AiCardListData.new({ cardIdList = cardIdList, lazi = lazi })
  local suitData = cardListData:toSuit()
  if suitData then
    return cardIdList
  end
  local cardType = maxCardType
  local levelCount = maxCardType - minCardType + 1
  local isLazi = false
  local suitData = AiSuitStraightData:createWithCardType(cardType, lazi, isLazi, levelCount)
  local ok = cardListData:installSuitData(suitData)
  if ok then
    local cardDataArr = suitData:getCardDataArr()
    local ret = AiUtils:cardDataArrToCardIdList(cardDataArr)
    return ret, true
  end
  return cardIdList
end

-- AiUtils · 检查判断是否有bigger牌型data
function AiUtils:checkHasBiggerSuitData(suitDataArr, lastSuitData)
  if suitDataArr == nil or #suitDataArr == 0 then
    return false
  end
  if not lastSuitData then
    return true
  end
  local ret = false
  for _, suitData in ipairs(suitDataArr) do
    if suitData:isWin(lastSuitData) then
      ret = true
      break
    end
  end
  return ret
end

-- AiUtils · bring牌型data
function AiUtils:bringSuitData(suitType, suitData, cardTypeListData, isFromHint)
  local sumCount = cardTypeListData:getCardCount()
  local lazi = cardTypeListData:getLazi()
  local level = suitData:getLevel()
  local levelCount = suitData:getLevelCount()
  local cardCount = suitData:getCardCount()
  local suitClass = AiSuitData:getClassWithSuitType(suitType)
  local suitInfo = suitClass:getSuitInfo()
  local matchSuitType = suitInfo.matchSuitType
  local matchCount = suitInfo.matchCount * levelCount
  local max = level
  local min = level - levelCount + 1
  if matchSuitType == SuitType.kSingle then
    if sumCount < cardCount + matchCount then
      return nil
    end
    local tmpSingleSuitDataArr = cardTypeListData:getSingleSuitDataArr()
    local singleSuitDataArr = {}
    table.insertto(singleSuitDataArr, tmpSingleSuitDataArr)
    for i = min, max do
      local count = cardTypeListData:getCardCountWithType(i)
      if count <= cardCount / levelCount then
        for index, suitData in ipairs(singleSuitDataArr) do
          if suitData:getLevel() == i then
            table.remove(singleSuitDataArr, index)
            break
          end
        end
      end
    end
    local laziCount = cardTypeListData:getLaziCount()
    if 0 < laziCount then
      local has, removeCountMap = cardTypeListData:hasSuitData(suitData)
      local removeLaziCount = removeCountMap[lazi] or 0
      laziCount = laziCount - removeLaziCount
    end
    local suitDataArr = { suitData }
    local didAddCount = 0
    for _, suitData in ipairs(singleSuitDataArr) do
      local singleLevel = suitData:getLevel()
      local count = cardTypeListData:getCardCountWithType(singleLevel)
      if min <= singleLevel and max >= singleLevel then
        count = count - 3
      end
      if singleLevel == lazi then
        count = count - laziCount
      end
      for i = 1, count do
        table.insert(suitDataArr, suitData)
        didAddCount = didAddCount + 1
        if didAddCount == matchCount then
          break
        end
      end
      if didAddCount == matchCount then
        break
      end
    end
    if didAddCount == matchCount then
      local ret = suitClass:createWithSuitDataArr(suitDataArr)
      return ret
    else
      return nil
    end
  else
    if sumCount < cardCount + matchCount * 2 then
      return nil
    end
    local tmpPairSuitDataArr = cardTypeListData:getPairSuitDataArr()
    local pairSuitDataArr = {}
    table.insertto(pairSuitDataArr, tmpPairSuitDataArr)
    local laziPairSuitData
    for i = min, max do
      local count = cardTypeListData:getCardCountWithType(i)
      if count < 4 then
        for index, suitData in ipairs(pairSuitDataArr) do
          if suitData:getLevel() == i then
            table.remove(pairSuitDataArr, index)
            break
          end
        end
      end
    end
    if lazi and 0 < lazi then
      for index, suitData in ipairs(pairSuitDataArr) do
        if suitData:getLevel() == lazi then
          laziPairSuitData = suitData
          table.remove(pairSuitDataArr, index)
          break
        end
      end
    end
    local suitDataArr = { suitData }
    local didAddCount = 0
    for _, suitData in ipairs(pairSuitDataArr) do
      local pairLevel = suitData:getLevel()
      local count = cardTypeListData:getCardCountWithType(pairLevel)
      if count == 2 then
        table.insert(suitDataArr, suitData)
        didAddCount = didAddCount + 1
        if didAddCount == matchCount then
          break
        end
      end
    end
    if matchCount > didAddCount then
      for _, suitData in ipairs(pairSuitDataArr) do
        local pairLevel = suitData:getLevel()
        local count = cardTypeListData:getCardCountWithType(pairLevel)
        if count == 3 then
          table.insert(suitDataArr, suitData)
          didAddCount = didAddCount + 1
          if didAddCount == matchCount then
            break
          end
        end
      end
    end
    if matchCount > didAddCount then
      local laziCount = cardTypeListData:getLaziCount()
      if 0 < laziCount then
        local has, removeCountMap = cardTypeListData:hasSuitData(suitData)
        local removeLaziCount = removeCountMap[lazi] or 0
        laziCount = laziCount - removeLaziCount
      end
      if 0 < laziCount then
        table.sort(pairSuitDataArr, function(a, b)
          return a:getLevel() < b:getLevel()
        end)
        for _, suitData in ipairs(pairSuitDataArr) do
          local pairLevel = suitData:getLevel()
          local count = cardTypeListData:getCardCountWithType(pairLevel)
          if
            count == 1
            or count == 3
            or cardCount / levelCount == 3 and count == 4 and (min > pairLevel or max < pairLevel)
          then
            table.insert(suitDataArr, suitData)
            didAddCount = didAddCount + 1
            laziCount = laziCount - 1
            if didAddCount == matchCount or laziCount == 0 then
              break
            end
          end
        end
      end
    end
    if matchCount > didAddCount and lazi and 0 < lazi and laziCount == 2 then
      table.insert(suitDataArr, laziPairSuitData)
      didAddCount = didAddCount + 1
    end
    if (isFromHint or suitType ~= SuitType.kFourWithTwoPair) and matchCount > didAddCount then
      for _, suitData in ipairs(pairSuitDataArr) do
        local pairLevel = suitData:getLevel()
        local count = cardTypeListData:getCardCountWithType(pairLevel)
        if count == 4 and (min > pairLevel or max < pairLevel) then
          table.insert(suitDataArr, suitData)
          didAddCount = didAddCount + 1
          if didAddCount == matchCount then
            for index, tmp in ipairs(suitDataArr) do
              if tmp:getType() == SuitType.kPair and pairLevel < tmp:getLevel() then
                table.remove(suitDataArr, index)
                table.insert(suitDataArr, suitData)
                break
              end
            end
            break
          end
          table.insert(suitDataArr, suitData)
          didAddCount = didAddCount + 1
          if didAddCount == matchCount then
            break
          end
        end
      end
    end
    if matchCount > didAddCount and lazi and 0 < lazi and laziCount == 4 then
      table.insert(suitDataArr, laziPairSuitData)
      table.insert(suitDataArr, laziPairSuitData)
      didAddCount = didAddCount + 2
    end
    if didAddCount == matchCount then
      local ret = suitClass:createWithSuitDataArr(suitDataArr)
      return ret
    else
      return nil
    end
  end
end

-- AiUtils · bring牌型dataarr
function AiUtils:bringSuitDataArr(suitDataArr, cardTypeListData, isFromHint, isAsync)
  local ret = {}
  local keyMap = {
    [SuitType.kBomb] = true,
    [SuitType.kThreeStraight] = true,
    [SuitType.kThree] = true,
  }
  local needBringSuitDataArr = {}
  for _, suitData in ipairs(suitDataArr) do
    if keyMap[suitData:getType()] then
      table.insert(needBringSuitDataArr, suitData)
    end
  end
  if #needBringSuitDataArr == 0 then
    return ret
  end
  for i, suitData in ipairs(needBringSuitDataArr) do
    if isAsync and i % 5 == 0 then
      coroutine.yield()
    end
    local bringSingle, bringPair
    local suitType = suitData:getType()
    if suitType == SuitType.kBomb then
      bringSingle = SuitType.kFourWithTwoSingle
      bringPair = SuitType.kFourWithTwoPair
    elseif suitType == SuitType.kThreeStraight then
      bringSingle = SuitType.kThreeStraightWithSingle
      bringPair = SuitType.kThreeStraightWithPair
    elseif suitType == SuitType.kThree then
      bringSingle = SuitType.kThreeWithOneSingle
      bringPair = SuitType.kThreeWithOnePair
    end
    if bringSingle then
      local bringSuitData = AiUtils:bringSuitData(bringSingle, suitData, cardTypeListData)
      if bringSuitData then
        table.insert(ret, bringSuitData)
      end
    end
    if bringPair then
      local bringSuitData = AiUtils:bringSuitData(bringPair, suitData, cardTypeListData, isFromHint)
      if bringSuitData then
        table.insert(ret, bringSuitData)
      end
    end
  end
  return ret
end

-- AiUtils · splitbring牌型dataarr
function AiUtils:splitBringSuitDataArr(suitDataArr, lazi)
  local ret = {}
  if #suitDataArr == 0 then
    return ret
  end
  for _, suitData in ipairs(suitDataArr) do
    local type = suitData:getType()
    if
      type == SuitType.kThreeStraightWithPair
      or type == SuitType.kFourWithTwoPair
      or type == SuitType.kThreeWithOnePair
    then
      local pairSuitData
      local matchCardCountMap = suitData:getMatchCardCountMap()
      for cardType, count in pairs(matchCardCountMap) do
        if 0 < count then
          pairSuitData = AiSuitPairData:createWithCardType(cardType, lazi, false)
          if pairSuitData ~= nil then
            table.insert(ret, pairSuitData)
          end
        end
      end
    elseif
      type == SuitType.kThreeStraightWithSingle
      or type == SuitType.kFourWithTwoSingle
      or type == SuitType.kThreeWithOneSingle
    then
      local singleSuitData
      local matchCardCountMap = suitData:getMatchCardCountMap()
      for cardType, count in pairs(matchCardCountMap) do
        if 0 < count then
          singleSuitData = AiSuitSingleData:createWithCardType(cardType, lazi, false)
          if singleSuitData ~= nil then
            table.insert(ret, singleSuitData)
          end
        end
      end
    end
  end
  return ret
end

-- AiUtils · 检查判断是否maxlevel
function AiUtils:checkIsMaxLevel(cardTypeList, level)
  local ret = true
  if cardTypeList ~= nil then
    for _, cardType in ipairs(cardTypeList) do
      if level < cardType then
        ret = false
        break
      end
    end
  end
  return ret
end

-- AiUtils · 检查not炸弹牌型data判断是否有炸弹
function AiUtils:checkNotBombSuitDataHasBomb(suitData)
  local ret = false
  if suitData == nil then
    return ret
  end
  local suitDataType = suitData:getType()
  if
    suitDataType == SuitType.kThreeStraightWithSingle
    or suitDataType == SuitType.kThreeStraightWithPair
    or suitDataType == SuitType.kThreeWithOneSingle
    or suitDataType == SuitType.kThreeWithOnePair
  then
    local needCardCountList = suitData:getNeedCardCountList()
    local cardTypeList = {}
    for cardType, count in pairs(needCardCountList) do
      if cardTypeList[cardType] == nil then
        cardTypeList[cardType] = 0
      end
      cardTypeList[cardType] = cardTypeList[cardType] + count
      if 4 <= cardTypeList[cardType] then
        ret = true
        break
      end
    end
  end
  return ret
end

-- AiUtils · 排序cardsforhand
function AiUtils:sortCardsForHand(cardDataArr)
  table.sort(cardDataArr, function(a, b)
    local a_isLazi = a:getIsLazi()
    local b_isLazi = b:getIsLazi()
    if a_isLazi == b_isLazi then
      local a_realType = a:getRealType()
      local b_realType = b:getRealType()
      if a_realType == b_realType then
        local a_colorType = a:getColorType()
        local b_colorType = b:getColorType()
        return a_colorType < b_colorType
      else
        return a_realType < b_realType
      end
    else
      return not a_isLazi
    end
  end)
end

-- AiUtils · 排序cardsforout
function AiUtils:sortCardsForOut(cardDataArr)
  table.sort(cardDataArr, function(a, b)
    local a_type = a:getType()
    local b_type = b:getType()
    if a_type == b_type then
      local a_colorType = a:getColorType()
      local b_colorType = b:getColorType()
      return a_colorType < b_colorType
    else
      return a_type < b_type
    end
  end)
end

-- AiUtils · 排序cardsforoutex
function AiUtils:sortCardsForOutEx(cardDataArr, minLevel, maxLevel)
  table.sort(cardDataArr, function(a, b)
    local a_type = a:getType()
    local b_type = b:getType()
    local a_inLevel = a_type >= minLevel and a_type <= maxLevel
    local b_inLevel = b_type >= minLevel and b_type <= maxLevel
    if a_inLevel == b_inLevel then
      if a_type == b_type then
        local a_colorType = a:getColorType()
        local b_colorType = b:getColorType()
        return a_colorType < b_colorType
      else
        return a_type < b_type
      end
    else
      return not a_inLevel
    end
  end)
end

-- AiUtils · deduplicationwith牌型dataarr
function AiUtils:deDuplicationWithSuitDataArr(suitDataArr)
  local ret = {}
  for _, suitData in ipairs(suitDataArr) do
    local didAdd = false
    for _, retSuitData in ipairs(ret) do
      if suitData == retSuitData then
        didAdd = true
        break
      end
    end
    if not didAdd then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiUtils · clearall分组info
function AiUtils:clearAllFenzuInfo(allFenzu)
  local flag
  for i, fenzu in ipairs(allFenzu) do
    flag = false
    for _, suitData in ipairs(fenzu) do
      suitData:setBiggerCount(0)
      suitData:setSmallerCount(0)
      suitData:setEqualCount(0)
      suitData:setUseBombCount(0)
      if suitData.isToSuit then
        flag = true
        break
      end
    end
    if flag then
      local removeFenzu = table.remove(allFenzu, i)
    end
  end
  return allFenzu
end

-- AiUtils · split四张withx牌型
function AiUtils:splitFourWithXSuit(suitData)
  local suitDataType = suitData:getType()
  local lazi = suitData:getLazi()
  local needCardCountList = suitData:getNeedCardCountList()
  local ret = {}
  local tempSuitData
  for cardType, count in pairs(needCardCountList) do
    tempSuitData = nil
    if count == 4 then
      tempSuitData = AiSuitBombData:createWithCardType(cardType, lazi, false)
    elseif count == 2 then
      tempSuitData = AiSuitPairData:createWithCardType(cardType, lazi, false)
    elseif count == 1 then
      tempSuitData = AiSuitSingleData:createWithCardType(cardType, lazi, false)
    end
    if tempSuitData then
      table.insert(ret, tempSuitData)
    end
  end
  return ret
end

-- AiUtils · 检查牌id判断是否癞子
function AiUtils:checkCardIdIsLazi(cardIdList, lazi)
  if lazi == nil or lazi < 3 then
    return false
  end
  local laziCount = 0
  for i, id in ipairs(cardIdList) do
    if self:cardIdToCardType(id) == lazi then
      laziCount = laziCount + 1
    end
  end
  if 0 < laziCount and laziCount < #cardIdList then
    return true
  else
    return false
  end
end

-- AiUtils · 过滤only牌型
function AiUtils:filterOnlySuit(suitDataArr, filterNum)
  if #suitDataArr == 1 then
    return suitDataArr
  end
  local ret = {}
  local suitTypeDataArr = {}
  local count = 0
  for i, suit in ipairs(suitDataArr) do
    if suitTypeDataArr[suit:getType()] == nil then
      suitTypeDataArr[suit:getType()] = {}
      count = count + 1
    end
    table.insert(suitTypeDataArr[suit:getType()], suit)
  end
  if filterNum <= count then
    for i, arr in pairs(suitTypeDataArr) do
      if 1 < #arr then
        table.sort(arr, function(a, b)
          return a:getLevel() > b:getLevel()
        end)
      end
      table.insert(ret, arr[1])
    end
  else
    ret = suitDataArr
  end
  return ret
end

-- AiUtils · print分组list
function AiUtils:printFenzuList(stepInfoList, title)
  if stepInfoList == nil then
    return
  end
  for _, fenzuInfo in ipairs(stepInfoList) do
    local suitDataArr = fenzuInfo.suitDataArr
    for i, v in ipairs(suitDataArr) do
      print(title .. " ---- lun=" .. fenzuInfo.lun .. ", " .. v:toString())
      if i % 5 == 0 then
        coroutine.yield()
      end
    end
    print("\n")
  end
end

-- AiUtils · log牌型dataarr
function AiUtils:logSuitDataArr(suitDataArr, desciption, printFun)
  desciption = desciption or "LogSuitDataArr:"
  printFun = printFun or print
  printFun("======" .. tostring(desciption))
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      printFun(suitData:toString())
    end
  end
  printFun("======\n")
end

-- AiUtils · log牌dataarr
function AiUtils:logCardDataArr(cardDataArr, desciption, printFun)
  desciption = desciption or "LogCardDataArr:"
  printFun = printFun or print
  local str = desciption
  if cardDataArr ~= nil then
    for _, cardData in ipairs(cardDataArr) do
      str = str .. " " .. cardData:toString()
    end
  end
  printFun(str)
end

-- AiUtils · log牌typelist
function AiUtils:logCardTypeList(cardTypeList, desciption, printFun)
  desciption = desciption or "LogCardDataArr:"
  printFun = printFun or print
  local str = desciption
  if cardTypeList ~= nil then
    for _, cardType in ipairs(cardTypeList) do
      local cardData = AiCardData:createWithType(cardType)
      str = str .. " " .. cardData:toString()
    end
  end
  printFun(str)
end

-- AiUtils · 克隆当前对象
function AiUtils:clone(object)
  local lookup_table = {}

  -- AiUtils ·
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local newObject = {}
    lookup_table[object] = newObject
    for key, value in pairs(object) do
      newObject[_copy(key)] = _copy(value)
    end
    return setmetatable(newObject, getmetatable(object))
  end

  return _copy(object)
end

-- AiUtils · 在协程中异步执行函数
function AiUtils:async(coroutineFun, callback, interval)
  interval = interval or 0
  local handler

  -- AiUtils ·
  local function update()
    handler = create_timeout(interval, function()
      local ret = {
        coroutine.resume(coroutineFun),
      }
      local status = coroutine.status(coroutineFun)
      if status == "dead" then
        handler()
        handler = nil
        if callback then
          callback(ret)
        end
      else
        update()
      end
    end)
  end

  update()
  return handler
end

-- AiUtils · cancelasync
function AiUtils:cancelAsync(handler)
  handler()
  handler = nil
end

-- AiUtils · test
function AiUtils:test() end

return AiUtils
