-- 文件: actionWorst/AiWorstLandlordFollowData.lua · 反编译 AI 模块（阅读用）

local AiWorstLandlordFollowData = class("AiWorstLandlordFollowData", AiLandlordFollowData)

-- 最弱AI·地主跟牌 · 构造函数
function AiWorstLandlordFollowData:ctor(params)
  AiWorstLandlordFollowData.super.ctor(self, params)
end

-- 最弱AI·地主跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（地主跟牌）
function AiWorstLandlordFollowData:getActionSuitData()
  self.log("=地主跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==地主要不起")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
  self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
  self.log("==【优先出的牌组合列表】=最优分组的YQ牌组合")
  self:setFirstSuitDataArr(bestBiggerSuitDataArr)
  return self:getBaseActionSuitData()
end

return AiWorstLandlordFollowData
