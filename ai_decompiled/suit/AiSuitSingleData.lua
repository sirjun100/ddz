-- 文件: suit/AiSuitSingleData.lua · 反编译 AI 模块（阅读用）

local AiSuitSingleData = class("AiSuitSingleData", AiSuitData)

-- 单张 · 构造函数
function AiSuitSingleData:ctor(properties)
  AiSuitSingleData.super.ctor(self, properties)
end

-- 单张 · 获取牌型枚举 SuitType
function AiSuitSingleData:getType()
  return SuitType.kSingle
end

-- 单张 · 获取牌型名称
function AiSuitSingleData:getName()
  return "单张"
end

-- 单张 · 获取description
function AiSuitSingleData:getDescription()
  return "1张牌"
end

-- 单张 · 获取audioname
function AiSuitSingleData:getAudioName()
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
    self.audioName_ = SuitAudioName.kSingle .. numName .. "." .. kAudioFormat
  end
  return self.audioName_
end

-- 单张 · 获取evaluation
function AiSuitSingleData:getEvaluation()
  return 1
end

-- 单张 · 获取discardweight
function AiSuitSingleData:getDiscardWeight()
  return 2
end

-- 单张 · 获取牌型评分
function AiSuitSingleData:getScore()
  if self.score_ == nil then
    local level = self:getLevel()
    local cardTypeScore = self:getCardTypeScore(level)
    self.score_ = cardTypeScore
  end
  return self.score_
end

-- 单张 · 获取samecount
function AiSuitSingleData:getSameCount()
  return 1
end

-- 单张 · 创建with牌type
function AiSuitSingleData:createWithCardType(cardType, lazi)
  local cardCount = 1
  local params = {
    cardCount = cardCount,
    level = cardType,
    needCardCountList = {
      [cardType] = cardCount,
    },
    lazi = lazi,
    isLazi = false,
  }
  local ret = self:create(params)
  return ret
end

-- 单张 · 创建with牌typelistdata
function AiSuitSingleData:createWithCardTypeListData(cardTypeListData)
  if cardTypeListData == nil then
    return nil
  end
  local ret
  local count = cardTypeListData:getCardCount()
  if count == 1 then
    local ok = false
    local cardType = CardType.kUnknow
    local enableMore = true
    local enableLazi = true
    local list = cardTypeListData:getTypeListWithCount(1, enableMore, enableLazi)
    if list and #list == 1 then
      ok = true
      cardType = list[1]
    end
    if ok then
      local lazi = cardTypeListData:getLazi()
      ret = self:createWithCardType(cardType, lazi)
    end
  end
  return ret
end

-- 单张 · 枚举手牌全部牌型组合
function AiSuitSingleData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  if 1 <= count then
    local lazi = cardTypeListData:getLazi()
    local needCount = 1
    local enableMore = true
    local enableLazi = true
    local list = cardTypeListData:getTypeListWithCount(needCount, enableMore, enableLazi)
    if list and 0 < #list then
      for _, cardType in ipairs(list) do
        local suitData = self:createWithCardType(cardType, lazi)
        if suitData then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

-- 单张 · 获取completeall牌型data
function AiSuitSingleData:getCompleteAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  if 0 < count then
    local lazi = cardTypeListData:getLazi()
    local cardTypeList = cardTypeListData:getCardTypeList()
    for _, cardType in ipairs(cardTypeList) do
      local suitData = self:createWithCardType(cardType, lazi, false)
      if suitData then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

return AiSuitSingleData
