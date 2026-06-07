-- 文件: suit/AiSuitThreeStraightWithSingleData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeStraightWithSingleData = class("AiSuitThreeStraightWithSingleData", AiSuitData)

-- 三张 · 构造函数
function AiSuitThreeStraightWithSingleData:ctor(properties)
  AiSuitThreeStraightWithSingleData.super.ctor(self, properties)
end

-- 三张 · 获取ui牌dataarr
function AiSuitThreeStraightWithSingleData:getUICardDataArr()
  local ret = {}
  local cardDataArr = self:getCardDataArr()
  table.insertto(ret, cardDataArr)
  local level = self:getLevel()
  local levelCount = self:getLevelCount()
  AiUtils:sortCardsForOutEx(ret, level - levelCount + 1, level)
  return ret
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeStraightWithSingleData:getType()
  return SuitType.kThreeStraightWithSingle
end

-- 三张 · 获取牌型名称
function AiSuitThreeStraightWithSingleData:getName()
  return "飞机，带单张的翅膀"
end

-- 三张 · 获取description
function AiSuitThreeStraightWithSingleData:getDescription()
  return "2个或2个以上连续的3张相同牌（2不能算），同时带相同数量的单张"
end

-- 三张 · 获取audioname
function AiSuitThreeStraightWithSingleData:getAudioName()
  return SuitAudioName.kThreeStraightWithSingle
end

-- 三张 · 获取evaluation
function AiSuitThreeStraightWithSingleData:getEvaluation()
  local evaluation = 0
  if self:getCardCount() ~= nil then
    evaluation = self:getCardCount()
  end
  return evaluation
end

-- 三张 · 获取discardweight
function AiSuitThreeStraightWithSingleData:getDiscardWeight()
  return 8
end

-- 三张 · 获取牌型评分
function AiSuitThreeStraightWithSingleData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 三张 · 获取levelcount
function AiSuitThreeStraightWithSingleData:getLevelCount()
  return self:getCardCount() / self:getSuitInfo().needCount
end

-- 三张 · 获取samecount
function AiSuitThreeStraightWithSingleData:getSameCount()
  return 3
end

-- 三张 · 获取minlevelcount
function AiSuitThreeStraightWithSingleData:getMinLevelCount()
  return 2
end

-- 三张 · 获取牌型info
function AiSuitThreeStraightWithSingleData:getSuitInfo()
  local ret = {
    straightMainSuitType = SuitType.kThreeStraight,
    mainSuitType = SuitType.kThree,
    matchSuitType = SuitType.kSingle,
    matchCount = 1,
    needCount = 4,
  }
  return ret
end

-- 三张 · 获取match牌型type
function AiSuitThreeStraightWithSingleData:getMatchSuitType()
  local suitInfo = self:getSuitInfo()
  return suitInfo.matchSuitType
end

-- 三张 · 获取match牌countmap
function AiSuitThreeStraightWithSingleData:getMatchCardCountMap()
  local needCardCountList = self:getNeedCardCountList()
  local level = self:getLevel()
  local levelCount = self:getLevelCount()
  local sameCount = self:getSameCount()
  local min = level - levelCount + 1
  local max = level
  local ret = {}
  for cardType, count in pairs(needCardCountList) do
    if cardType < min or cardType > max then
      ret[cardType] = count
    else
      ret[cardType] = count - sameCount
    end
  end
  return ret
end

-- 三张 · updatematchwith牌typelist
function AiSuitThreeStraightWithSingleData:updateMatchWithCardTypeList(cardTypeList)
  local level = self:getLevel()
  local levelCount = self:getLevelCount()
  local sameCount = self:getSameCount()
  local needCardCountList = {}
  local min = level - levelCount + 1
  local max = level
  for i = min, max do
    needCardCountList[i] = sameCount
  end
  for _, cardType in ipairs(cardTypeList) do
    if needCardCountList[cardType] then
      needCardCountList[cardType] = needCardCountList[cardType] + 1
    else
      needCardCountList[cardType] = 1
    end
  end
  self:setNeedCardCountList(needCardCountList)
  self:setCardDataArr(nil)
end

-- 三张 · 获取all顺子main牌型data
function AiSuitThreeStraightWithSingleData:getAllStraightMainSuitData(cardTypeListData, mustLevelCount)
  local ret = {}
  local suitInfo = self:getSuitInfo()
  local straightMainSuitType = suitInfo.straightMainSuitType
  local suitClass = AiSuitData:getClassWithSuitType(straightMainSuitType)
  if suitClass then
    ret = suitClass:getAllSuitData(cardTypeListData, mustLevelCount)
  end
  return ret
end

-- 三张 · 获取allmain牌型data
function AiSuitThreeStraightWithSingleData:getAllMainSuitData(cardTypeListData)
  local ret = {}
  local suitInfo = self:getSuitInfo()
  local mainSuitType = suitInfo.mainSuitType
  local suitClass = AiSuitData:getClassWithSuitType(mainSuitType)
  if suitClass then
    ret = suitClass:getAllSuitData(cardTypeListData)
  end
  return ret
end

-- 三张 · 获取allmatch牌型data
function AiSuitThreeStraightWithSingleData:getAllMatchSuitData(cardTypeListData)
  local ret = {}
  local suitInfo = self:getSuitInfo()
  local matchSuitType = suitInfo.matchSuitType
  local suitClass = AiSuitData:getClassWithSuitType(matchSuitType)
  if suitClass then
    ret = suitClass:getCompleteAllSuitData(cardTypeListData)
  end
  return ret
end

-- 三张 · 创建with牌typelistdata
function AiSuitThreeStraightWithSingleData:createWithCardTypeListData(cardTypeListData)
  if cardTypeListData == nil then
    return nil
  end
  local ret
  local count = cardTypeListData:getCardCount()
  local suitInfo = self:getSuitInfo()
  local needCount = suitInfo.needCount
  local minLevelCount = 2
  local maxLevelCount = 12
  local levelCount = count / needCount
  if count % needCount == 0 and minLevelCount <= levelCount and maxLevelCount >= levelCount then
    local mainSuitDataArr = self:getAllStraightMainSuitData(cardTypeListData, levelCount)
    if mainSuitDataArr and 0 < #mainSuitDataArr then
      table.sort(mainSuitDataArr, function(a, b)
        return a:getLevel() > b:getLevel()
      end)
      for _, suitData in ipairs(mainSuitDataArr) do
        local didRemove, removeCountMap = cardTypeListData:removeCardTypeWithSuitData(suitData)
        if didRemove then
          local matchSuitDataArr = self:getAllMatchSuitData(cardTypeListData)
          if matchSuitDataArr and 0 < #matchSuitDataArr then
            local suitDataArr = { suitData }
            for _, tmpSuitData in ipairs(matchSuitDataArr) do
              table.insert(suitDataArr, tmpSuitData)
            end
            ret = self:createWithSuitDataArrHasStraight(suitDataArr)
          end
          cardTypeListData:addCardTypeWithMap(removeCountMap)
          if ret then
            break
          end
        end
      end
    end
  end
  return ret
end

-- 三张 · 枚举手牌全部牌型组合
function AiSuitThreeStraightWithSingleData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local minCount = 8
  if count >= minCount then
  end
  return ret
end

-- 三张 · 创建with牌型dataarr
function AiSuitThreeStraightWithSingleData:createWithSuitDataArr(suitDataArr)
  local ret
  local suitInfo = self:getSuitInfo()
  local matchCount = suitInfo.matchCount
  local suitData1 = suitDataArr[1]
  if suitData1:getType() == self:getSuitInfo().straightMainSuitType then
    return self:createWithSuitDataArrHasStraight(suitDataArr)
  end
  if suitDataArr and #suitDataArr % (1 + matchCount) == 0 and #suitDataArr / (1 + matchCount) >= 2 then
    local mainSuitDataArr = {}
    local matchSuitDataArr = {}
    local hasOther = false
    local hasEquit = false
    local equitMap = {}
    local mainSuitType = suitInfo.mainSuitType
    local matchSuitType = suitInfo.matchSuitType
    for _, suitData in ipairs(suitDataArr) do
      local suitType = suitData:getType()
      if suitType == mainSuitType then
        local level = suitData:getLevel()
        if level > CardType.kAce then
          hasOther = true
          break
        end
        if equitMap[suitData:getLevel()] then
          hasEquit = true
          break
        end
        equitMap[suitData:getLevel()] = true
        table.insert(mainSuitDataArr, suitData)
      elseif suitType == matchSuitType then
        table.insert(matchSuitDataArr, suitData)
      else
        hasOther = true
        break
      end
    end
    if hasOther or hasEquit then
      return nil
    end
    if #mainSuitDataArr * matchCount == #matchSuitDataArr then
      table.sort(mainSuitDataArr, function(a, b)
        return a:getLevel() < b:getLevel()
      end)
      local minSuitData = mainSuitDataArr[1]
      local maxSuitData = mainSuitDataArr[#mainSuitDataArr]
      local minLevel = minSuitData:getLevel()
      local maxLevel = maxSuitData:getLevel()
      if maxLevel - minLevel + 1 ~= #mainSuitDataArr then
        return nil
      end
      local cardCount = 0
      local level = 0
      local needCardCountList = {}
      local lazi = mainSuitData:getLazi()
      for _, suitData in ipairs(mainSuitDataArr) do
        local tmpCardCount = suitData:getCardCount()
        cardCount = cardCount + tmpCardCount
        local tmpLevel = suitData:getLevel()
        if needCardCountList[tmpLevel] then
          needCardCountList[tmpLevel] = needCardCountList[tmpLevel] + tmpCardCount
        else
          needCardCountList[tmpLevel] = tmpCardCount
        end
      end
      for _, suitData in ipairs(matchSuitDataArr) do
        local tmpCardCount = suitData:getCardCount()
        local tmpLevel = suitData:getLevel()
        if needCardCountList[tmpLevel] then
          needCardCountList[tmpLevel] = needCardCountList[tmpLevel] + tmpCardCount
        else
          needCardCountList[tmpLevel] = tmpCardCount
        end
      end
      local params = {
        cardCount = cardCount,
        level = level,
        needCardCountList = needCardCountList,
        lazi = lazi,
        isLazi = false,
      }
      ret = self:create(params)
    end
  end
  return ret
end

-- 三张 · 创建with牌型dataarr判断是否有顺子
function AiSuitThreeStraightWithSingleData:createWithSuitDataArrHasStraight(suitDataArr)
  local ret
  local suitInfo = self:getSuitInfo()
  if suitDataArr and 2 <= #suitDataArr then
    local straightSuitData
    local matchSuitDataArr = {}
    local hasOther = false
    local equitMap = {}
    local straightMainSuitType = suitInfo.straightMainSuitType
    local matchSuitType = suitInfo.matchSuitType
    for _, suitData in ipairs(suitDataArr) do
      local suitType = suitData:getType()
      if straightSuitData == nil and suitType == straightMainSuitType then
        straightSuitData = suitData
      elseif suitType == matchSuitType then
        table.insert(matchSuitDataArr, suitData)
      else
        hasOther = true
        break
      end
    end
    if hasOther then
      return nil
    end
    if straightSuitData == nil then
      return nil
    end
    local levelCount = straightSuitData:getLevelCount()
    local matchCount = suitInfo.matchCount
    if levelCount * matchCount == #matchSuitDataArr then
      local level = straightSuitData:getLevel()
      local needCardCountList = {}
      local lazi = straightSuitData:getLazi()
      local cardCount = straightSuitData:getCardCount()
      local mainNeedCardCountList = straightSuitData:getNeedCardCountList()
      for cardType, count in pairs(mainNeedCardCountList) do
        needCardCountList[cardType] = count
      end
      for _, suitData in ipairs(matchSuitDataArr) do
        local tmpCardCount = suitData:getCardCount()
        cardCount = cardCount + tmpCardCount
        local tmpLevel = suitData:getLevel()
        if needCardCountList[tmpLevel] then
          needCardCountList[tmpLevel] = needCardCountList[tmpLevel] + tmpCardCount
        else
          needCardCountList[tmpLevel] = tmpCardCount
        end
      end
      local params = {
        cardCount = cardCount,
        level = level,
        needCardCountList = needCardCountList,
        lazi = lazi,
        isLazi = false,
      }
      ret = self:create(params)
    end
  end
  return ret
end

return AiSuitThreeStraightWithSingleData
