-- 文件: actionWorst/AiWorstFarmerRightFollowData.lua · 反编译 AI 模块（阅读用）

local AiWorstFarmerRightFollowData = class("AiWorstFarmerRightFollowData", AiFarmerRightFollowData)

-- 最弱AI·下家农民跟牌 · 构造函数
function AiWorstFarmerRightFollowData:ctor(params)
  AiWorstFarmerRightFollowData.super.ctor(self, params)
end

-- 最弱AI·下家农民跟牌 · 出牌主入口：按局面分支决策并返回 AiSuitData（下家农民跟牌）
function AiWorstFarmerRightFollowData:getActionSuitData()
  self.log("=下家农民跟牌")
  local enableFollow = self:enableFollow()
  if not enableFollow then
    self.log("==下家农民要不起")
    return nil
  end
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  local bestBiggerSuitDataArr = data:ai_bestFenzu_filterBiggerSuitDataArr(lastSuitData)
  self:addParamsWithKey("最优分组的YQ牌组合", bestBiggerSuitDataArr)
  self.log("==【优先出的牌组合列表】=最优分组的YQ牌组合")
  local uid = lastSuitData:getUid()
  local friendData = self:getFarmerLeftData()
  local tmpSuitDataArr = bestBiggerSuitDataArr
  if friendData:getUid() == uid then
    self.log("====上手牌是队友出的")
    local friendClear = friendData:toSuit(nil, nil)
    if friendClear then
      if not self:enableEnd() then
        return nil
      else
        local bestSuitDataArr = data:ai_getBestSuitDataArr()
        self:addParamsWithKey("最优分组的牌组合", bestSuitDataArr)
        if 2 < #bestSuitDataArr then
          return nil
        end
      end
    end
    local a1 = AiUtils:filterNotBomb(tmpSuitDataArr)
    self:addParamsWithKey("【优先出的牌组合列表】中，非炸弹牌组合 A1", a1)
    self.log("【优先出的牌组合列表】中，非炸弹牌组合。假定是A1牌组合，A1数量是：" .. #a1)
    tmpSuitDataArr = a1
  end
  self:setFirstSuitDataArr(tmpSuitDataArr)
  return self:getBaseActionSuitData()
end

return AiWorstFarmerRightFollowData
