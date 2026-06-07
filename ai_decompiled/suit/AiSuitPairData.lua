-- 文件: suit/AiSuitPairData.lua · 反编译 AI 模块（阅读用）

local AiSuitPairData = class("AiSuitPairData", AiSuitData)

-- 对子 · 构造函数
function AiSuitPairData:ctor(properties)
  AiSuitPairData.super.ctor(self, properties)
end

-- 对子 · 获取牌型枚举 SuitType
function AiSuitPairData:getType()
  return SuitType.kPair
end

-- 对子 · 获取牌型名称
function AiSuitPairData:getName()
  return "对子"
end

-- 对子 · 获取description
function AiSuitPairData:getDescription()
  return "2张相同的牌（大王、小王不算）"
end

-- 对子 · 获取audioname
function AiSuitPairData:getAudioName()
  if self.audioName_ == nil or #self.audioName_ == 0 then
    local numName
    if self:getLevel() == CardType.kLittleJoker then
      numName = "joker1"
    elseif self:getLevel() == CardType.kBigJoker then
      numName = "joker2"
    elseif self:getLevel() == CardType.kAce then
      numName = "a"
    elseif self:getLevel() == CardType.kTwo then
      numName = "2"
    elseif self:getLevel() == CardType.kKing then
      numName = "k"
    elseif self:getLevel() == CardType.kQueen then
      numName = "q"
    elseif self:getLevel() == CardType.kJack then
      numName = "j"
    else
      numName = string.format("%d", self:getLevel())
    end
    self.audioName_ = SuitAudioName.kPair .. numName .. "." .. kAudioFormat
  end
  return self.audioName_
end

-- 对子 · 获取evaluation
function AiSuitPairData:getEvaluation()
  return 2
end

-- 对子 · 获取discardweight
function AiSuitPairData:getDiscardWeight()
  return 2
end

-- 对子 · 获取牌型评分
function AiSuitPairData:getScore()
  if self.score_ == nil then
    local level = self:getLevel()
    local cardTypeScore = self:getCardTypeScore(level)
    self.score_ = cardTypeScore * 2 + 2
  end
  return self.score_
end

-- 对子 · 获取samecount
function AiSuitPairData:getSameCount()
  return 2
end

-- 对子 · 创建with牌type
function AiSuitPairData:createWithCardType(cardType, lazi, isLazi)
  local cardCount = self:getSameCount()
  local params = {
    cardCount = cardCount,
    level = cardType,
    needCardCountList = {
      [cardType] = cardCount,
    },
    lazi = lazi,
    isLazi = isLazi,
  }
  local ret = self:create(params)
  return ret
end

-- 对子 · 创建with牌typelistdata
function AiSuitPairData:createWithCardTypeListData(cardTypeListData)
  if cardTypeListData == nil then
    return nil
  end
  local ret
  local count = cardTypeListData:getCardCount()
  local sameCount = self:getSameCount()
  if count == sameCount then
    local lazi = cardTypeListData:getLazi()
    local laziCount = cardTypeListData:getLaziCount()
    local needCount = sameCount - laziCount
    local ok = false
    local cardType = CardType.kUnknow
    if 0 < needCount then
      local enableMore = true
      local enableLazi = false
      local list = cardTypeListData:getTypeListWithCount(needCount, enableMore, enableLazi)
      if list and #list == 1 and list[1] < CardType.kLittleJoker then
        ok = true
        cardType = list[1]
      end
    else
      ok = true
      cardType = lazi
    end
    if ok then
      ret = self:createWithCardType(cardType, lazi, false)
    end
  end
  return ret
end

-- 对子 · 枚举手牌全部牌型组合
function AiSuitPairData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local sameCount = self:getSameCount()
  if count >= sameCount then
    local lazi = cardTypeListData:getLazi()
    local laziCount = cardTypeListData:getLaziCount()
    local needCount = math.max(sameCount - laziCount, 1)
    if sameCount <= laziCount then
      local suitData = self:createWithCardType(lazi, lazi, true)
      if suitData then
        table.insert(ret, suitData)
      end
    end
    local enableMore = true
    local enableLazi = false
    local list = cardTypeListData:getTypeListWithCount(needCount, enableMore, enableLazi)
    if list and 0 < #list then
      for _, cardType in ipairs(list) do
        if cardType < CardType.kLittleJoker then
          local isLazi = false
          local hasCount = cardTypeListData:getCardCountWithType(cardType)
          if sameCount > hasCount then
            isLazi = true
          end
          local suitData = self:createWithCardType(cardType, lazi, isLazi)
          if suitData then
            table.insert(ret, suitData)
          end
        end
      end
    end
  end
  return ret
end

-- 对子 · 获取completeall牌型data
function AiSuitPairData:getCompleteAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local sameCount = self:getSameCount()
  if count >= sameCount and count % sameCount == 0 then
    local lazi = cardTypeListData:getLazi()
    local laziCount = cardTypeListData:getLaziCount()
    local hasError = false
    local needLaziCount = 0
    local tmpCardTypeList = {}
    local enableMore = true
    local enableLazi = false
    local list = cardTypeListData:getTypeListWithCount(1, enableMore, enableLazi)
    if list and 0 < #list then
      for _, cardType in ipairs(list) do
        if cardType < CardType.kLittleJoker then
          local cardCount = cardTypeListData:getCardCountWithType(cardType)
          local pairCount = math.floor(cardCount / sameCount)
          for i = 1, pairCount do
            table.insert(tmpCardTypeList, cardType)
          end
          local remainCount = cardCount % sameCount
          if 0 < remainCount then
            needLaziCount = needLaziCount + (sameCount - remainCount)
            if laziCount >= needLaziCount then
              table.insert(tmpCardTypeList, cardType)
            else
              hasError = true
              break
            end
          end
        else
          hasError = true
          break
        end
      end
    end
    if not hasError then
      local remainLaziCount = laziCount - needLaziCount
      if 0 < remainLaziCount then
        local remainCount = remainLaziCount % sameCount
        if remainCount == 0 then
          local pairCount = remainLaziCount / sameCount
          for i = 1, pairCount do
            table.insert(tmpCardTypeList, lazi)
          end
        else
          hasError = true
        end
      end
    end
    if not hasError then
      for _, cardType in ipairs(tmpCardTypeList) do
        local suitData = self:createWithCardType(cardType, lazi, false)
        if suitData then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

return AiSuitPairData
