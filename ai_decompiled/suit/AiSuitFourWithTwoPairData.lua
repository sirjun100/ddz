-- 文件: suit/AiSuitFourWithTwoPairData.lua · 反编译 AI 模块（阅读用）

local AiSuitFourWithTwoPairData = class("AiSuitFourWithTwoPairData", AiSuitThreeWithOneSingleData)

-- 四带二对 · 构造函数
function AiSuitFourWithTwoPairData:ctor(properties)
  AiSuitFourWithTwoPairData.super.ctor(self, properties)
end

-- 四带二对 · 获取牌型枚举 SuitType
function AiSuitFourWithTwoPairData:getType()
  return SuitType.kFourWithTwoPair
end

-- 四带二对 · 获取牌型名称
function AiSuitFourWithTwoPairData:getName()
  return "四带2对"
end

-- 四带二对 · 获取description
function AiSuitFourWithTwoPairData:getDescription()
  return "4张相同的牌，同时带2个对子"
end

-- 四带二对 · 获取audioname
function AiSuitFourWithTwoPairData:getAudioName()
  return SuitAudioName.kFourWithTwoPair
end

-- 四带二对 · 获取evaluation
function AiSuitFourWithTwoPairData:getEvaluation()
  return 8
end

-- 四带二对 · 获取discardweight
function AiSuitFourWithTwoPairData:getDiscardWeight()
  return 0
end

-- 四带二对 · 获取牌型评分
function AiSuitFourWithTwoPairData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 四带二对 · 获取samecount
function AiSuitFourWithTwoPairData:getSameCount()
  return 4
end

-- 四带二对 · 获取牌型info
function AiSuitFourWithTwoPairData:getSuitInfo()
  local ret = {
    mainSuitType = SuitType.kBomb,
    matchSuitType = SuitType.kPair,
    matchCount = 2,
    needCount = 8,
  }
  return ret
end

-- 四带二对 · 枚举手牌全部牌型组合
function AiSuitFourWithTwoPairData:getAllSuitData(cardTypeListData)
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

return AiSuitFourWithTwoPairData
