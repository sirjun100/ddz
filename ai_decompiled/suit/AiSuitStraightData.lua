-- 文件: suit/AiSuitStraightData.lua · 反编译 AI 模块（阅读用）

local AiSuitStraightData = class("AiSuitStraightData", AiSuitData)

-- 顺子 · 构造函数
function AiSuitStraightData:ctor(properties)
  AiSuitStraightData.super.ctor(self, properties)
end

-- 顺子 · 获取牌型枚举 SuitType
function AiSuitStraightData:getType()
  return SuitType.kStraight
end

-- 顺子 · 获取牌型名称
function AiSuitStraightData:getName()
  return "顺子"
end

-- 顺子 · 获取description
function AiSuitStraightData:getDescription()
  return "5个或5个以上连续的单张（2、大王、小王不能算）"
end

-- 顺子 · 获取audioname
function AiSuitStraightData:getAudioName()
  return SuitAudioName.kStraight
end

-- 顺子 · 获取evaluation
function AiSuitStraightData:getEvaluation()
  local evaluation = 0
  if self:getCardCount() ~= nil then
    evaluation = self:getCardCount() - 1
  end
  return evaluation
end

-- 顺子 · 获取discardweight
function AiSuitStraightData:getDiscardWeight()
  return 6
end

-- 顺子 · 获取牌型评分
function AiSuitStraightData:getScore()
  if self.score_ == nil then
    local score = 0
    local level = self:getLevel()
    local count = self:getCardCount()
    for i = level, level - count + 1, -1 do
      local cardTypeScore = self:getCardTypeScore(i)
      score = score + cardTypeScore
    end
    self.score_ = score + count * 2
  end
  return self.score_
end

-- 顺子 · 获取levelcount
function AiSuitStraightData:getLevelCount()
  local cardCount = self:getCardCount()
  local sameCount = self:getSameCount()
  local ret = cardCount / sameCount
  return ret
end

-- 顺子 · 获取samecount
function AiSuitStraightData:getSameCount()
  return 1
end

-- 顺子 · 获取minlevelcount
function AiSuitStraightData:getMinLevelCount()
  return 5
end

-- 顺子 · 创建with牌type
function AiSuitStraightData:createWithCardType(cardType, lazi, isLazi, levelCount)
  local sameCount = self:getSameCount()
  local cardCount = sameCount * levelCount
  local level = cardType
  local needCardCountList = {}
  for i = cardType - levelCount + 1, cardType do
    needCardCountList[i] = sameCount
  end
  local params = {
    cardCount = cardCount,
    level = level,
    needCardCountList = needCardCountList,
    lazi = lazi,
    isLazi = isLazi,
  }
  local ret = self:create(params)
  return ret
end

-- 顺子 · 创建with牌typelistdata
function AiSuitStraightData:createWithCardTypeListData(cardTypeListData, isFromSelectCard)
  if cardTypeListData == nil then
    return nil
  end
  local ret, ret2
  local count = cardTypeListData:getCardCount()
  local sameCount = self:getSameCount()
  local minCount = self:getMinLevelCount() * sameCount
  local maxCount = 12 * sameCount
  if count % sameCount == 0 and count >= minCount and count <= maxCount then
    local lazi = cardTypeListData:getLazi()
    local laziCount = cardTypeListData:getLaziCount()
    local needLevelCount = count / sameCount
    local ok = false
    local enableMore = true
    local enableLazi = false
    local list = cardTypeListData:getTypeListWithCount(sameCount + 1, enableMore, enableLazi)
    if list and 0 < #list then
    else
      local maxCard = 0
      local minCard = 0
      local list = cardTypeListData:getTypeListWithCount(1, enableMore, enableLazi)
      if list and 0 < #list then
        local c1 = list[1]
        local c2 = list[#list]
        if c2 <= CardType.kAce and needLevelCount > c2 - c1 then
          ok = true
          maxCard = math.min(c1 + needLevelCount - 1, CardType.kAce)
          minCard = maxCard - needLevelCount + 1
        end
      end
      if ok then
        local cardType = maxCard
        local lazi = lazi
        local isLazi = false
        local levelCount = needLevelCount
        ret = self:createWithCardType(cardType, lazi, isLazi, levelCount)
        if isFromSelectCard then
          local c1 = list[1]
          local c2 = list[#list]
          if c1 > CardType.kThree and needLevelCount > c2 - c1 then
            minCard = math.max(c2 - needLevelCount + 1, CardType.kThree)
            local cardType2 = math.min(minCard + needLevelCount - 1, CardType.kAce)
            if cardType2 ~= maxCard then
              local lazi = lazi
              local isLazi = false
              local levelCount = needLevelCount
              ret2 = self:createWithCardType(cardType2, lazi, isLazi, levelCount)
            end
          end
        end
      end
    end
  end
  return ret, ret2
end

-- 顺子 · 枚举手牌全部牌型组合
function AiSuitStraightData:getAllSuitData(cardTypeListData, mustLevelCount)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local sameCount = self:getSameCount()
  local minLevelCount = mustLevelCount and mustLevelCount or self:getMinLevelCount()
  local minCount = self:getMinLevelCount() * sameCount
  if count >= minCount then
    local lazi = cardTypeListData:getLazi()
    local laziCount = cardTypeListData:getLaziCount()
    local minNeedCount = minCount - laziCount
    local needCount = math.max(1, sameCount - laziCount)
    local enableMore = true
    local enableLazi = false
    local list = cardTypeListData:getTypeListWithCount(needCount, enableMore, enableLazi)
    if list and 0 < #list then
      for i = #list, 1, -1 do
        local c = list[i]
        if c > CardType.kAce then
          table.remove(list, i)
        end
      end
      local listCount = #list
      if 0 < listCount then
        local maxLevelCount = mustLevelCount and mustLevelCount or math.min(12, math.floor(count / sameCount))
        local tmpCard
        for i = 1, listCount do
          local c1 = list[i]
          for j = minLevelCount, maxLevelCount do
            local ck = math.min(c1 + j - 1, CardType.kAce)
            local maxCard = math.min(c1 + j - 1, CardType.kAce)
            local minCard = maxCard - j + 1
            if tmpCard and tmpCard >= minCard then
              break
            end
            local needCardCountList = {}
            for i = minCard, maxCard do
              needCardCountList[i] = sameCount
            end
            local enough = cardTypeListData:hasCardTypeWithMap(needCardCountList)
            if enough then
              local cardType = maxCard
              local lazi = lazi
              local isLazi = false
              local levelCount = j
              local suitData = self:createWithCardType(cardType, lazi, isLazi, levelCount)
              if suitData then
                table.insert(ret, suitData)
              end
            else
              break
            end
          end
          tmpCard = c1
        end
      end
    end
  end
  return ret
end

return AiSuitStraightData
