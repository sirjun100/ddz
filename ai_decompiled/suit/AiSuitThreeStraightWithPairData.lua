-- 文件: suit/AiSuitThreeStraightWithPairData.lua · 反编译 AI 模块（阅读用）

local AiSuitThreeStraightWithPairData = class("AiSuitThreeStraightWithPairData", AiSuitThreeStraightWithSingleData)

-- 三张 · 构造函数
function AiSuitThreeStraightWithPairData:ctor(properties)
  AiSuitThreeStraightWithPairData.super.ctor(self, properties)
end

-- 三张 · 获取牌型枚举 SuitType
function AiSuitThreeStraightWithPairData:getType()
  return SuitType.kThreeStraightWithPair
end

-- 三张 · 获取牌型名称
function AiSuitThreeStraightWithPairData:getName()
  return "飞机，带对子的翅膀"
end

-- 三张 · 获取description
function AiSuitThreeStraightWithPairData:getDescription()
  return "2个或2个以上连续的3张相同牌（2不能算），同时带相同数量的对子"
end

-- 三张 · 获取audioname
function AiSuitThreeStraightWithPairData:getAudioName()
  return SuitAudioName.kThreeStraightWithPair
end

-- 三张 · 获取evaluation
function AiSuitThreeStraightWithPairData:getEvaluation()
  local evaluation = 0
  if self:getCardCount() ~= nil then
    evaluation = self:getCardCount()
  end
  return evaluation
end

-- 三张 · 获取discardweight
function AiSuitThreeStraightWithPairData:getDiscardWeight()
  return 8
end

-- 三张 · 获取牌型评分
function AiSuitThreeStraightWithPairData:getScore()
  if self.score_ == nil then
    self.score_ = 0
  end
  return self.score_
end

-- 三张 · 获取samecount
function AiSuitThreeStraightWithPairData:getSameCount()
  return 3
end

-- 三张 · 获取minlevelcount
function AiSuitThreeStraightWithPairData:getMinLevelCount()
  return 2
end

-- 三张 · 获取牌型info
function AiSuitThreeStraightWithPairData:getSuitInfo()
  local ret = {
    straightMainSuitType = SuitType.kThreeStraight,
    mainSuitType = SuitType.kThree,
    matchSuitType = SuitType.kPair,
    matchCount = 1,
    needCount = 5,
  }
  return ret
end

return AiSuitThreeStraightWithPairData
