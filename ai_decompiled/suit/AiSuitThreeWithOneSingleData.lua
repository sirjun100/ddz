-- 文件: suit/AiSuitThreeWithOneSingleData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeWithOneSingleData = class("AiSuitThreeWithOneSingleData", AiSuitData)

-- 三张 · 构造函数
function AiSuitThreeWithOneSingleData:ctor(properties)
  AiSuitThreeWithOneSingleData.super.ctor(self, properties)
end

-- 三张 · 获取ui牌dataarr
function AiSuitThreeWithOneSingleData:getUICardDataArr()
  local ret = {}
  local cardDataArr = self:getCardDataArr()
  table.insertto(ret, cardDataArr)
  local level = self:getLevel()
  local levelCount = self:getLevelCount()
  AiUtils:sortCardsForOutEx(ret, level, level)
  return ret
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeWithOneSingleData:getType()
  return SuitType.kThreeWithOneSingle
end

-- 三张 · 获取牌型名称
function AiSuitThreeWithOneSingleData:getName()
  return "三带1张"
end

-- 三张 · 获取description
function AiSuitThreeWithOneSingleData:getDescription()
  return "3张相同的牌，同时带1张"
end

-- 三张 · 获取audioname
function AiSuitThreeWithOneSingleData:getAudioName()
  return SuitAudioName.kThreeWithOneSingle
end

-- 三张 · 获取evaluation
function AiSuitThreeWithOneSingleData:getEvaluation()
  return 4
end

-- 三张 · 获取discardweight
function AiSuitThreeWithOneSingleData:getDiscardWeight()
  return 4
end

-- 三张 · 获取牌型评分
function AiSuitThreeWithOneSingleData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 三张 · 获取samecount
function AiSuitThreeWithOneSingleData:getSameCount()
  return 3
end

-- 三张 · 获取牌型info
function AiSuitThreeWithOneSingleData:getSuitInfo()
  local ret = {
    mainSuitType = SuitType.kThree,
    matchSuitType = SuitType.kSingle,
    matchCount = 1,
    needCount = 4,
  }
  return ret
end

-- 三张 · 获取match牌型type
function AiSuitThreeWithOneSingleData:getMatchSuitType()
  local suitInfo = self:getSuitInfo()
  return suitInfo.matchSuitType
end

-- 三张 · 获取match牌countmap
function AiSuitThreeWithOneSingleData:getMatchCardCountMap()
  local needCardCountList = self:getNeedCardCountList()
  local level = self:getLevel()
  local sameCount = self:getSameCount()
  local ret = {}
  for cardType, count in pairs(needCardCountList) do
    if cardType ~= level then
      ret[cardType] = count
    else
      ret[cardType] = count - sameCount
    end
  end
  return ret
end

-- 三张 · updatematchwith牌typelist
function AiSuitThreeWithOneSingleData:updateMatchWithCardTypeList(cardTypeList)
  local level = self:getLevel()
  local sameCount = self:getSameCount()
  local needCardCountList = {}
  needCardCountList[level] = sameCount
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

-- 三张 · 获取allmain牌型data
function AiSuitThreeWithOneSingleData:getAllMainSuitData(cardTypeListData)
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
function AiSuitThreeWithOneSingleData:getAllMatchSuitData(cardTypeListData)
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
function AiSuitThreeWithOneSingleData:createWithCardTypeListData(cardTypeListData, isFromSelectCard)
  if cardTypeListData == nil then
    return nil
  end
  local ret
  local suitInfo = self:getSuitInfo()
  local needCount = suitInfo.needCount
  local count = cardTypeListData:getCardCount()
  if count == needCount then
    local mainSuitDataArr = self:getAllMainSuitData(cardTypeListData)
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
            if isFromSelectCard then
              if ret == nil then
                ret = {}
              end
              table.insert(ret, self:createWithSuitDataArr(suitDataArr))
            else
              ret = self:createWithSuitDataArr(suitDataArr)
            end
          end
          cardTypeListData:addCardTypeWithMap(removeCountMap)
          if not isFromSelectCard and ret then
            break
          end
        end
      end
    end
  end
  if isFromSelectCard and ret then
    return ret[1], ret[2]
  else
    return ret
  end
end

-- 三张 · 枚举手牌全部牌型组合
function AiSuitThreeWithOneSingleData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local minCount = 4
  if count >= minCount then
  end
  return ret
end

-- 三张 · 创建with牌型dataarr
function AiSuitThreeWithOneSingleData:createWithSuitDataArr(suitDataArr)
  local ret
  local suitInfo = self:getSuitInfo()
  local matchCount = suitInfo.matchCount
  if suitDataArr and #suitDataArr == 1 + matchCount then
    local mainSuitData
    local matchSuitDataArr = {}
    local hasOther = false
    local mainSuitType = suitInfo.mainSuitType
    local matchSuitType = suitInfo.matchSuitType
    for _, suitData in ipairs(suitDataArr) do
      local suitType = suitData:getType()
      if mainSuitData == nil and suitType == mainSuitType then
        mainSuitData = suitData
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
    if mainSuitData and #matchSuitDataArr == matchCount then
      local mainCardCount = mainSuitData:getCardCount()
      local mainLevel = mainSuitData:getLevel()
      local cardCount = mainCardCount
      local level = mainLevel
      local needCardCountList = {
        [mainLevel] = mainCardCount,
      }
      local lazi = mainSuitData:getLazi()
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

return AiSuitThreeWithOneSingleData
