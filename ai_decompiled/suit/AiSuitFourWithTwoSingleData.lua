-- 文件: suit/AiSuitFourWithTwoSingleData.lua · 反编译 AI 模块（阅读用）

local AiSuitFourWithTwoSingleData = class("AiSuitFourWithTwoSingleData", AiSuitThreeWithOneSingleData)

-- 四带二单 · 构造函数
function AiSuitFourWithTwoSingleData:ctor(properties)
  AiSuitFourWithTwoSingleData.super.ctor(self, properties)
end

-- 四带二单 · 获取牌型枚举 SuitType
function AiSuitFourWithTwoSingleData:getType()
  return SuitType.kFourWithTwoSingle
end

-- 四带二单 · 获取牌型名称
function AiSuitFourWithTwoSingleData:getName()
  return "四带2张"
end

-- 四带二单 · 获取description
function AiSuitFourWithTwoSingleData:getDescription()
  return "4张相同的牌，同时带2张"
end

-- 四带二单 · 获取audioname
function AiSuitFourWithTwoSingleData:getAudioName()
  return SuitAudioName.kFourWithTwoSingle
end

-- 四带二单 · 获取evaluation
function AiSuitFourWithTwoSingleData:getEvaluation()
  return 6
end

-- 四带二单 · 获取discardweight
function AiSuitFourWithTwoSingleData:getDiscardWeight()
  return 0
end

-- 四带二单 · 获取牌型评分
function AiSuitFourWithTwoSingleData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 四带二单 · 获取samecount
function AiSuitFourWithTwoSingleData:getSameCount()
  return 4
end

-- 四带二单 · 获取牌型info
function AiSuitFourWithTwoSingleData:getSuitInfo()
  local ret = {
    mainSuitType = SuitType.kBomb,
    matchSuitType = SuitType.kSingle,
    matchCount = 2,
    needCount = 6,
  }
  return ret
end

-- 四带二单 · 枚举手牌全部牌型组合
function AiSuitFourWithTwoSingleData:getAllSuitData(cardTypeListData)
  if cardTypeListData == nil then
    return {}
  end
  local ret = {}
  local count = cardTypeListData:getCardCount()
  local minCount = 6
  if count >= minCount then
  end
  return ret
end

return AiSuitFourWithTwoSingleData
