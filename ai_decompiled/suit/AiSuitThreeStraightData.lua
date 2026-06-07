-- 文件: suit/AiSuitThreeStraightData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeStraightData = class("AiSuitThreeStraightData", AiSuitStraightData)

-- 三张 · 构造函数
function AiSuitThreeStraightData:ctor(properties)
  AiSuitThreeStraightData.super.ctor(self, properties)
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeStraightData:getType()
  return SuitType.kThreeStraight
end

-- 三张 · 获取牌型名称
function AiSuitThreeStraightData:getName()
  return "飞机，不带翅膀"
end

-- 三张 · 获取description
function AiSuitThreeStraightData:getDescription()
  return "2个或2个以上连续的3张相同牌（2不能算），不带其他牌"
end

-- 三张 · 获取audioname
function AiSuitThreeStraightData:getAudioName()
  return SuitAudioName.kThreeStraight
end

-- 三张 · 获取evaluation
function AiSuitThreeStraightData:getEvaluation()
  local evaluation = 0
  if self:getCardCount() ~= nil then
    evaluation = self:getCardCount()
  end
  return evaluation
end

-- 三张 · 获取discardweight
function AiSuitThreeStraightData:getDiscardWeight()
  return 1
end

-- 三张 · 获取牌型评分
function AiSuitThreeStraightData:getScore()
  if self.score_ == nil then
    local score = 0
    local level = self:getLevel()
    local count = self:getCardCount()
    for i = level, level - count / 3 + 1, -1 do
      local cardTypeScore = self:getCardTypeScore(i)
      score = score + (cardTypeScore * 3 + 3)
    end
    self.score_ = score + count
  end
  return self.score_
end

-- 三张 · 获取samecount
function AiSuitThreeStraightData:getSameCount()
  return 3
end

-- 三张 · 获取minlevelcount
function AiSuitThreeStraightData:getMinLevelCount()
  return 2
end

return AiSuitThreeStraightData
