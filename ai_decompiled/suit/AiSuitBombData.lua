-- 文件: suit/AiSuitBombData.lua · 反编译 AI 模块（阅读用）

local AiSuitBombData = class("AiSuitBombData", AiSuitPairData)

-- 炸弹 · 构造函数
function AiSuitBombData:ctor(properties)
  AiSuitBombData.super.ctor(self, properties)
end

-- 炸弹 · 获取牌型枚举 SuitType
function AiSuitBombData:getType()
  return SuitType.kBomb
end

-- 炸弹 · 获取牌型名称
function AiSuitBombData:getName()
  return "炸弹"
end

-- 炸弹 · 获取description
function AiSuitBombData:getDescription()
  return "4张相同的牌"
end

-- 炸弹 · 获取audioname
function AiSuitBombData:getAudioName()
  return SuitAudioName.kBomb
end

-- 炸弹 · 获取evaluation
function AiSuitBombData:getEvaluation()
  return 7
end

-- 炸弹 · 获取discardweight
function AiSuitBombData:getDiscardWeight()
  return 0
end

-- 炸弹 · 获取牌型评分
function AiSuitBombData:getScore()
  if self.score_ == nil then
    local level = self:getLevel()
    local cardTypeScore = self:getCardTypeScore(level)
    self.score_ = cardTypeScore * 5 + 4
  end
  return self.score_
end

-- 炸弹 · 获取samecount
function AiSuitBombData:getSameCount()
  return 4
end

return AiSuitBombData
