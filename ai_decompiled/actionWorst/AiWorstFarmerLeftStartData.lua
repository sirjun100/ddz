-- 文件: actionWorst/AiWorstFarmerLeftStartData.lua · 反编译 AI 模块（阅读用）

local AiWorstFarmerLeftStartData = class("AiWorstFarmerLeftStartData", AiFarmerLeftStartData)

-- 最弱AI·上家农民首出 · 构造函数
function AiWorstFarmerLeftStartData:ctor(params)
  AiWorstFarmerLeftStartData.super.ctor(self, params)
end

-- 最弱AI·上家农民首出 · 出牌主入口：按局面分支决策并返回 AiSuitData（上家农民出牌）
function AiWorstFarmerLeftStartData:getActionSuitData()
  self.log("=上家农民出牌")
  local data = self:getData()
  local bestSuitDataArr = data:ai_getBestSuitDataArr()
  self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
  self.log("==【优先出的牌组合列表】=最优分组的牌组合")
  self:setFirstSuitDataArr(bestSuitDataArr)
  return self:getBaseActionSuitData()
end

return AiWorstFarmerLeftStartData
