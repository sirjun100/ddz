-- 文件: actionBase/AiLandlordStartData.lua · 反编译 AI 模块（阅读用）

local AiLandlordStartData = class("AiLandlordStartData", AiActionData)

-- 地主首出 · 构造函数
function AiLandlordStartData:ctor(params)
  AiLandlordStartData.super.ctor(self, params)
end

-- 地主首出 · 出牌决策主流程
function AiLandlordStartData:getActionSuitData() end

-- 地主首出 · 从优先出牌列表中选取一手（基类逻辑）
function AiLandlordStartData:getBaseActionSuitData()
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
    local enemy1 = self:getFarmerRightData()
    local cardCount1 = enemy1:getCardCount()
    local enemy2 = self:getFarmerLeftData()
    local cardCount2 = enemy2:getCardCount()
    if cardCount1 == 1 or cardCount2 == 1 then
      table.sort(firstSuitDataArr, function(a, b)
        return a:getLevel() < b:getLevel()
      end)
      local maxLevel = firstSuitDataArr[#firstSuitDataArr]:getLevel()
      local minLevel1 = firstSuitDataArr[1]:getLevel()
      local lose = false
      local minLose = false
      if cardCount1 == 1 then
        local enemyMax1 = enemy1:getCardTypeList()[1] or 0
        if maxLevel < enemyMax1 then
          lose = true
        end
        if minLevel1 < enemyMax1 then
          minLose = true
        end
      end
      if not lose and cardCount2 == 1 then
        local enemyMax2 = enemy2:getCardTypeList()[1] or 0
        if maxLevel < enemyMax2 then
          lose = true
        end
        if minLevel1 < enemyMax2 then
          minLose = true
        end
      end
      if lose then
        self.log(
          "==【优先出的牌组合列表】中都是单张，对手报单张，且压不住，则从倒数第二的单张出起"
        )
        return firstSuitDataArr[2]
      elseif minLose then
        self.log(
          "==【优先出的牌组合列表】中都是单张，对手报单张，最小的压不住，则从倒数第二的单张出起"
        )
        return firstSuitDataArr[2]
      else
        self.log(
          "==【优先出的牌组合列表】中都是单张，对手报单张，且压得住，则从最小的单张出起"
        )
        return firstSuitDataArr[1]
      end
    end
  end
  return self:getStartBaseActionSuitData()
end

return AiLandlordStartData
