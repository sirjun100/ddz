-- 文件: actionWorst/AiWorstLandlordStartData.lua · 反编译 AI 模块（阅读用）

local AiWorstLandlordStartData = class("AiWorstLandlordStartData", AiLandlordStartData)

-- 最弱AI·地主首出 · 构造函数
function AiWorstLandlordStartData:ctor(params)
  AiWorstLandlordStartData.super.ctor(self, params)
end

-- 最弱AI·地主首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（地主出牌）
function AiWorstLandlordStartData:getActionSuitData()
  self.log("=地主出牌")
  local data = self:getData()
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
  self.log("==【优先出的牌组合列表】=最优分组的牌组合")
  self:setFirstSuitDataArr(bestSuitDataArr)
  return self:getBaseActionSuitData()
end

return AiWorstLandlordStartData
