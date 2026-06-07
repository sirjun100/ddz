-- 文件: actionBase/AiFarmerLeftStartData.lua · 反编译 AI 模块（阅读用）

local AiFarmerLeftStartData = class("AiFarmerLeftStartData", AiActionData)

-- 上家农民首出 · 构造函数
function AiFarmerLeftStartData:ctor(params)
  AiFarmerLeftStartData.super.ctor(self, params)
end

-- 上家农民首出 · 出牌决策主流程
function AiFarmerLeftStartData:getActionSuitData() end

-- 上家农民首出 · 从优先出牌列表中选取一手（基类逻辑）
function AiFarmerLeftStartData:getBaseActionSuitData()
  local firstSuitDataArr = self:getFirstSuitDataArr()
  if firstSuitDataArr == nil or #firstSuitDataArr == 0 then
    return nil
  elseif #firstSuitDataArr == 1 then
    self.log("==【优先出的牌组合列表】只有一个，就它了")
    return firstSuitDataArr[1]
  end
  local isAllSingle = true
  for _, suitData in ipairs(firstSuitDataArr) do
    if suitData:getType() ~= SuitType.kSingle then
      isAllSingle = false
      break
    end
  end
  if isAllSingle then
    local enemy = self:getLandlordData()
    local cardCount = enemy:getCardCount()
    if cardCount == 1 then
      table.sort(firstSuitDataArr, function(a, b)
        return a:getLevel() < b:getLevel()
      end)
      self.log("==【优先出的牌组合列表】中都是单张，对手报单张，则从最大的单张出起")
      return firstSuitDataArr[#firstSuitDataArr]
    end
  end
  return self:getStartBaseActionSuitData()
end

return AiFarmerLeftStartData
