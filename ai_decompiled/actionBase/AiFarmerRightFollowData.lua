-- 文件: actionBase/AiFarmerRightFollowData.lua · 反编译 AI 模块（阅读用）

local AiFarmerRightFollowData = class("AiFarmerRightFollowData", AiActionData)

-- 下家农民跟牌 · 构造函数
function AiFarmerRightFollowData:ctor(params)
  AiFarmerRightFollowData.super.ctor(self, params)
end

-- 下家农民跟牌 · 出牌决策主流程
function AiFarmerRightFollowData:getActionSuitData() end

-- 下家农民跟牌 · 从优先出牌列表中选取一手（基类逻辑）
function AiFarmerRightFollowData:getBaseActionSuitData()
  return self:getFollowBaseActionSuitData()
end

-- 下家农民跟牌 · 获取discardmore炸弹（队友不是剩一张牌）
function AiFarmerRightFollowData:getDiscardMoreBomb()
  local data = self:getData()
  local friendData = self:getFarmerLeftData()
  local enemyData = self:getLandlordData()
  local lastSuitData = self.lastSuitData_
  local friendClear = friendData:toSuit()
  if not friendClear or friendClear:getType() ~= SuitType.kSingle then
    self.log("=====队友不是剩一张牌")
    return nil
  end
  local bombArr = data:getAllBombForMaxCount()
  self:addParamsWithKey("任意牌组合的炸弹", bombArr)
  if #bombArr == 0 then
    self.log("=====任意牌组合中，没有炸弹")
    return nil
  end
  bombArr = AiUtils:filterBiggerSuitDataArr(bombArr, lastSuitData)
  local cloneData = data:clone()
  cloneData.enemy1 = data.enemy1
  cloneData.enemy2 = data.enemy2
  cloneData.friend = data.friend
  for _, suitData in ipairs(bombArr) do
    cloneData:removeCardTypeWithSuitData(suitData)
  end
  local d = {}
  local suitDataArr = cloneData:ai_all_getSuitDataArr()
  for _, suitData in ipairs(suitDataArr) do
    if friendClear:isWin(suitData) then
      table.insert(d, suitData)
    end
  end
  self:addParamsWithKey("任意牌组合中，除了炸弹，能让队友溜走最后一手牌的牌组合", d)
  if #d == 0 then
    self.log("=====任意牌组合中，除了炸弹，没有能让队友溜走最后一手牌的牌组合")
    return nil
  end
  local enemyBombArr = enemyData:getAllBomb()
  if #enemyBombArr == 0 then
    self.log("=====对手没有炸弹，可以先出所有炸弹")
    return bombArr
  end
  local maxBomb
  for _, suitData in ipairs(bombArr) do
    if maxBomb == nil or suitData:isWin(maxBomb) then
      maxBomb = suitData
    end
  end
  local isMax = true
  for _, suitData in ipairs(enemyBombArr) do
    if suitData:isWin(maxBomb) then
      isMax = false
      break
    end
  end
  if not isMax then
    self.log("=====任意牌组合中，自己对比对手的炸弹不是最大的")
    return nil
  end
  local mismatchWinCondition = enemyData:ai_filterMismatchWinCondition(bombArr)
  self:addParamsWithKey("任意牌组合中，不是对手收官条件的炸弹牌组合", d)
  if #mismatchWinCondition == 0 then
    self.log("=====所有炸弹都是对手的收官条件")
    return nil
  else
    self.log("=====出不是对手收官条件的炸弹牌组合")
    return mismatchWinCondition
  end
end

-- 下家农民跟牌 · 判断是否need协助队友收官（是否需要让队友收官）
function AiFarmerRightFollowData:isNeedHelpFriendEnd()
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
  if not self:farmerLeftEnableEnd() then
    self.log("===队友不能收官")
    return false
  end
  local uid = lastSuitData:getUid()
  local friendData = self:getFarmerLeftData()
  if friendData:getUid() ~= uid then
    self.log("===队友能收官，但是上手牌不是队友出的")
    return false
  end
  if lastSuitData:getLevel() >= CardType.kAce and self:getLandlordCardCount() > 2 then
    self.log(
      "===队友能收官，且上手牌是队友出的，且大于A，且地主手牌数量大于2张，则Pass"
    )
    return true
  end
  if #data:getAllBomb() > #friendData:getAllBomb() then
    self.log("===队友能收官，且上手牌是队友出的，但是炸弹没我多")
    return false
  end
  if #data:ai_getBestSuitDataArr() < #friendData:ai_getBestSuitDataArr() then
    self.log(
      "===队友能收官，且上手牌是队友出的，且炸弹数量大于或等于我，但最优分组牌组合数量比我多"
    )
    return false
  end
  self.log(
    "===队友能收官，且上手牌是队友出的，且炸弹数量大于或等于我，且最优分组牌组合数量比我少"
  )
  return true
end

return AiFarmerRightFollowData
