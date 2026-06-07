-- 文件: suit/AiSuitThreeWithOnePairData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeWithOnePairData = class("AiSuitThreeWithOnePairData", AiSuitThreeWithOneSingleData)

-- 三张 · 构造函数
function AiSuitThreeWithOnePairData:ctor(properties)
  AiSuitThreeWithOnePairData.super.ctor(self, properties)
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeWithOnePairData:getType()
  return SuitType.kThreeWithOnePair
end

-- 三张 · 获取牌型名称
function AiSuitThreeWithOnePairData:getName()
  return "三带1对"
end

-- 三张 · 获取description
function AiSuitThreeWithOnePairData:getDescription()
  return "3张相同的牌，同时带1个对子"
end

-- 三张 · 获取audioname
function AiSuitThreeWithOnePairData:getAudioName()
  return SuitAudioName.kThreeWithOnePair
end

-- 三张 · 获取evaluation
function AiSuitThreeWithOnePairData:getEvaluation()
  return 5
end

-- 三张 · 获取discardweight
function AiSuitThreeWithOnePairData:getDiscardWeight()
  return 4
end

-- 三张 · 获取牌型评分
function AiSuitThreeWithOnePairData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 三张 · 获取samecount
function AiSuitThreeWithOnePairData:getSameCount()
  return 3
end

-- 三张 · 获取牌型info
function AiSuitThreeWithOnePairData:getSuitInfo()
  local ret = {
    mainSuitType = SuitType.kThree,
    matchSuitType = SuitType.kPair,
    matchCount = 1,
    needCount = 5,
  }
  return ret
end

-- 三张 · 枚举手牌全部牌型组合
function AiSuitThreeWithOnePairData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local minCount = 5
  if count >= minCount then
  end
  return ret
end

return AiSuitThreeWithOnePairData
