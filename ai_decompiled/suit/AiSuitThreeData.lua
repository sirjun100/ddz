-- 文件: suit/AiSuitThreeData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeData = class("AiSuitThreeData", AiSuitPairData)

-- 三张 · 构造函数
function AiSuitThreeData:ctor(properties)
  AiSuitThreeData.super.ctor(self, properties)
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeData:getType()
  return SuitType.kThree
end

-- 三张 · 获取牌型名称
function AiSuitThreeData:getName()
  return "纯三张"
end

-- 三张 · 获取description
function AiSuitThreeData:getDescription()
  return "3张相同的牌"
end

-- 三张 · 获取audioname
function AiSuitThreeData:getAudioName()
  return SuitAudioName.kThree
end

-- 三张 · 获取evaluation
function AiSuitThreeData:getEvaluation()
  return 3
end

-- 三张 · 获取discardweight
function AiSuitThreeData:getDiscardWeight()
  return 4
end

-- 三张 · 获取牌型评分
function AiSuitThreeData:getScore()
  if self.score_ == nil then
    local level = self:getLevel()
    local cardTypeScore = self:getCardTypeScore(level)
    self.score_ = cardTypeScore * 3 + 3
  end
  return self.score_
end

-- 三张 · 获取samecount
function AiSuitThreeData:getSameCount()
  return 3
end

return AiSuitThreeData
