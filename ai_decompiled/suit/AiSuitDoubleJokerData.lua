-- 文件: suit/AiSuitDoubleJokerData.lua · 反编译 AI 模块（阅读用）

local AiSuitDoubleJokerData = class("AiSuitDoubleJokerData", AiSuitData)

-- 王炸 · 构造函数
function AiSuitDoubleJokerData:ctor(properties)
  AiSuitDoubleJokerData.super.ctor(self, properties)
end

-- 王炸 · 获取牌型枚举 SuitType
function AiSuitDoubleJokerData:getType()
  return SuitType.kDoubleJoker
end

-- 王炸 · 获取牌型名称
function AiSuitDoubleJokerData:getName()
  return "王炸"
end

-- 王炸 · 获取description
function AiSuitDoubleJokerData:getDescription()
  return "大王、小王组合"
end

-- 王炸 · 获取audioname
function AiSuitDoubleJokerData:getAudioName()
  return SuitAudioName.kDoubleJoker
end

-- 王炸 · 获取evaluation
function AiSuitDoubleJokerData:getEvaluation()
  return 7
end

-- 王炸 · 获取discardweight
function AiSuitDoubleJokerData:getDiscardWeight()
  return -1
end

-- 王炸 · 获取牌型评分
function AiSuitDoubleJokerData:getScore()
  if self.score_ == nil then
    self.score_ = 152
  end
  return self.score_
end

-- 王炸 · 创建with牌typelistdata
function AiSuitDoubleJokerData:createWithCardTypeListData(cardTypeListData)
  if cardTypeListData == nil then
    return nil
  end
  local ret
  local count = cardTypeListData:getCardCount()
  if count == 2 then
    local needCardCountList = {
      [CardType.kLittleJoker] = 1,
      [CardType.kBigJoker] = 1,
    }
    local ok = cardTypeListData:hasCardTypeWithMap(needCardCountList)
    if ok then
      local params = {
        cardCount = 2,
        level = CardType.kBigJoker,
        needCardCountList = needCardCountList,
        lazi = lazi,
        isLazi = false,
      }
      ret = AiSuitDoubleJokerData:create(params)
    end
  end
  return ret
end

-- 王炸 · 枚举手牌全部牌型组合
function AiSuitDoubleJokerData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return nil
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  if 2 <= count then
    local needCardCountList = {
      [CardType.kLittleJoker] = 1,
      [CardType.kBigJoker] = 1,
    }
    local ok = cardTypeListData:hasCardTypeWithMap(needCardCountList)
    if ok then
      local params = {
        cardCount = 2,
        level = CardType.kBigJoker,
        needCardCountList = needCardCountList,
        lazi = lazi,
        isLazi = false,
      }
      local suitData = AiSuitDoubleJokerData:create(params)
      if suitData then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

return AiSuitDoubleJokerData
