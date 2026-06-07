-- 文件: suit/AiSuitDoubleStraightData.lua · 反编译 AI 模块（阅读用）

local AiSuitDoubleStraightData = class("AiSuitDoubleStraightData", AiSuitStraightData)

-- 连对 · 构造函数
function AiSuitDoubleStraightData:ctor(properties)
  AiSuitDoubleStraightData.super.ctor(self, properties)
end

-- 连对 · 获取牌型枚举 SuitType
function AiSuitDoubleStraightData:getType()
  return SuitType.kDoubleStraight
end

-- 连对 · 获取牌型名称
function AiSuitDoubleStraightData:getName()
  return "连对"
end

-- 连对 · 获取description
function AiSuitDoubleStraightData:getDescription()
  return "3个或3个以上连续的对子（2和王不能算）"
end

-- 连对 · 获取audioname
function AiSuitDoubleStraightData:getAudioName()
  return SuitAudioName.kDoubleStraight
end

-- 连对 · 获取evaluation
function AiSuitDoubleStraightData:getEvaluation()
  local evaluation = 0
  if self:getCardCount() >= 6 then
    evaluation = 5 + self:getCardCount() - 6
  end
  return evaluation
end

-- 连对 · 获取discardweight
function AiSuitDoubleStraightData:getDiscardWeight()
  return 6
end

-- 连对 · 获取牌型评分
function AiSuitDoubleStraightData:getScore()
  if self.score_ == nil then
    local score = 0
    local level = self:getLevel()
    local count = self:getCardCount()
    for i = level, level - count / 2 + 1, -1 do
      local cardTypeScore = self:getCardTypeScore(i)
      score = score + (cardTypeScore * 2 + 2)
    end
    self.score_ = score + count
  end
  return self.score_
end

-- 连对 · 获取samecount
function AiSuitDoubleStraightData:getSameCount()
  return 2
end

-- 连对 · 获取minlevelcount
function AiSuitDoubleStraightData:getMinLevelCount()
  return 3
end

return AiSuitDoubleStraightData
