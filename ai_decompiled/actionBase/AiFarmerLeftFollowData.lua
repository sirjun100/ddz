-- 文件: actionBase/AiFarmerLeftFollowData.lua · 反编译 AI 模块（阅读用）

local AiFarmerLeftFollowData = class("AiFarmerLeftFollowData", AiActionData)

-- 上家农民跟牌 · 构造函数
function AiFarmerLeftFollowData:ctor(params)
  AiFarmerLeftFollowData.super.ctor(self, params)
end

-- 上家农民跟牌 · 出牌决策主流程
function AiFarmerLeftFollowData:getActionSuitData() end

-- 上家农民跟牌 · 从优先出牌列表中选取一手（基类逻辑）
function AiFarmerLeftFollowData:getBaseActionSuitData()
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
  return self:getFollowBaseActionSuitData()
end

-- 上家农民跟牌 · 判断是否need协助队友收官（是否需要让队友收官）
function AiFarmerLeftFollowData:isNeedHelpFriendEnd()
  self.log("==是否需要让队友收官")
  local data = self:getData()
  local lastSuitData = self.lastSuitData_
  local winConditions = data:ai_getWinConditions()
  self:addParamsWithKey("所有收官牌组合", winConditions)
  if winConditions ~= nil then
    if #winConditions == 1 then
      self.log("===自己只剩最后一手牌，则不让队友")
      return false
    else
      local dataClear = data:toSuit()
      if dataClear and dataClear:isWin(lastSuitData) then
        self.log("===自己只剩最后一手牌，则不让队友2")
        return false
      end
    end
  end
  if not self:farmerRightEnableEnd() then
    self.log("===队友不能收官")
    return false
  end
  local uid = lastSuitData:getUid()
  local friendData = self:getFarmerRightData()
  local enemyData = self:getLandlordData()
  if friendData:getUid() ~= uid then
    self.log("===队友能收官，但是上手牌不是队友出的")
    return false
  end
  local enemyWinConditions = enemyData:ai_getWinConditions()
  if enemyWinConditions ~= nil and #enemyWinConditions == 1 and enemyData:ai_isMatchWinCondition(lastSuitData) then
    self.log("===队友能收官，且上手牌是队友出的，但地主能先出完")
    return false
  end
  if #data:getAllBomb() > #friendData:getAllBomb() then
    self.log("===队友能收官，且上手牌是队友出的，但是炸弹没我多")
    return false
  end
  if #data:ai_getBestSuitDataArr() <= #friendData:ai_getBestSuitDataArr() then
    self.log(
      "===队友能收官，且上手牌是队友出的，且炸弹数量大于或等于我，但最优分组牌组合数量比我多(或一样)"
    )
    return false
  end
  self.log(
    "===队友能收官，且上手牌是队友出的，且炸弹数量大于或等于我，且最优分组牌组合数量比我少"
  )
  return true
end

return AiFarmerLeftFollowData
