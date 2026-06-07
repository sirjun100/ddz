-- 文件: AiCardListData.lua · 反编译 AI 模块（阅读用）

local AiCardListData = class("AiCardListData", DataBase)
AiCardListData:addProperty("cardIdList", {})
AiCardListData:addProperty("lazi", 0)
AiCardListData:addProperty("uid", 0)
AiCardListData:addProperty("direction", nil)

-- AiCardList · 构造函数
function AiCardListData:ctor(properties)
  AiCardListData.super.ctor(self, properties)
end

-- AiCardList · 获取ui牌dataarr
function AiCardListData:getUICardDataArr()
  local ret = {}
  local cardIdList = self:getCardIdList()
  local lazi = self:getLazi()
  for _, cardId in ipairs(cardIdList) do
    local cardData = AiCardData.new(cardId)
    if cardData:getType() == lazi then
      cardData:setIsLazi(true)
    end
    table.insert(ret, cardData)
  end
  AiUtils:sortCardsForHand(ret)
  return ret
end

-- AiCardList · 获取typelistdata
function AiCardListData:getTypeListData()
  if self.typeListData_ == nil then
    local cardTypeList = self:getCardTypeList()
    local lazi = self:getLazi()
    local uid = self:getUid()
    local direction = self:getDirection()
    local map = {
      cardTypeList = cardTypeList,
      lazi = lazi,
      uid = uid,
      direction = direction,
    }
    self.typeListData_ = AiCardTypeListData.new(map)
  end
  return self.typeListData_
end

-- AiCardList · 获取牌typelist
function AiCardListData:getCardTypeList()
  local ret = {}
  local cardIdList = self:getCardIdList() or {}
  for _, cardId in ipairs(cardIdList) do
    local cardType = AiUtils:cardIdToCardType(cardId)
    if cardType then
      table.insert(ret, cardType)
    end
  end
  return ret
end

-- AiCardList · 获取手牌张数
function AiCardListData:getCardCount()
  local ret = 0
  local cardIdList = self:getCardIdList()
  if cardIdList then
    ret = #cardIdList
  end
  return ret
end

-- AiCardList · 获取牌idlistwith牌type
function AiCardListData:getCardIdListWithCardType(cardType, maxCount)
  local ret = {}
  local cardIdList = self:getCardIdList()
  if cardIdList and 0 < #cardIdList then
    for _, cardId in ipairs(cardIdList) do
      local tmpCardType = AiUtils:cardIdToCardType(cardId)
      if tmpCardType == cardType then
        table.insert(ret, cardId)
        if maxCount and maxCount <= #ret then
          break
        end
      end
    end
  end
  return ret
end

-- AiCardList · 获取癞子牌idlist
function AiCardListData:getLaziCardIdList(maxCount)
  local lazi = self:getLazi()
  if lazi == nil or lazi <= 0 then
    return {}
  end
  return self:getCardIdListWithCardType(lazi, maxCount)
end

-- AiCardList · install牌型data
function AiCardListData:installSuitData(suitData)
  if suitData:getCardCount() > self:getCardCount() then
    print("error: AiCardListData:installSuitData 牌不够", suitData:getCardCount(), self:getCardCount())
    return false
  end
  local needCardCountList = suitData:getNeedCardCountList()
  local cardDataArr = {}
  local lazi = self:getLazi()
  local laziCardIdList = self:getLaziCardIdList()
  local laziCount = #laziCardIdList
  local needLaziCount = 0
  local isLazi = false
  for cardType, count in pairs(needCardCountList) do
    if 0 < count then
      local hasCount = 0
      local cardIdList
      if cardType == lazi then
        local newNeedLaziCount = needLaziCount + count
        if laziCount < newNeedLaziCount then
          print("error: AiCardListData:installSuitData 癞子不够")
          return false
        end
        for i = needLaziCount + 1, newNeedLaziCount do
          local cardData = AiCardData.new(laziCardIdList[i])
          cardData:setIsLazi(true)
          table.insert(cardDataArr, cardData)
        end
        needLaziCount = needLaziCount + count
      else
        cardIdList = self:getCardIdListWithCardType(cardType, count)
        for _, cardId in ipairs(cardIdList) do
          local cardData = AiCardData.new(cardId)
          table.insert(cardDataArr, cardData)
        end
        if count > #cardIdList then
          if cardType == CardType.kBigJoker or cardType == CardType.kLittleJoker then
            print("error: AiCardListData:installSuitData 缺少的是大小王，癞子不能变大小王")
            return false
          end
          local newNeedLaziCount = needLaziCount + (count - #cardIdList)
          if laziCount < newNeedLaziCount then
            print("error: AiCardListData:installSuitData 癞子不够")
            return false
          end
          for i = needLaziCount + 1, newNeedLaziCount do
            local cardData = AiCardData.new(laziCardIdList[i])
            cardData:setType(cardType)
            cardData:setIsLazi(true)
            table.insert(cardDataArr, cardData)
          end
          needLaziCount = newNeedLaziCount
          isLazi = true
        end
      end
    end
  end
  suitData:setCardDataArr(cardDataArr)
  suitData:setIsLazi(isLazi)
  return true
end

-- AiCardList · 判断是否有牌id
function AiCardListData:hasCardId(cardId)
  if cardId == nil then
    return false
  end
  local cardIdList = self:getCardIdList()
  if cardIdList then
    for _, tmpCardId in ipairs(cardIdList) do
      if tmpCardId == cardId then
        return true
      end
    end
  end
  return false
end

-- AiCardList · 判断是否有牌idlist
function AiCardListData:hasCardIdList(cardIdList)
  if cardIdList == nil or #cardIdList == 0 then
    return true
  end
  local ret = true
  for _, cardId in ipairs(cardIdList) do
    local has = self:hasCardId(cardId)
    if not has then
      ret = false
      break
    end
  end
  return ret
end

-- AiCardList · 添加牌id
function AiCardListData:addCardId(cardId)
  if cardId == nil then
    return true
  end
  local didAdd = false
  local cardType = AiUtils:cardIdToCardType(cardId)
  local cardIdList = self:getCardIdList()
  if cardIdList then
    for i, tmpCardId in ipairs(cardIdList) do
      local tmpCardType = AiUtils:cardIdToCardType(tmpCardId)
      if cardType < tmpCardType or tmpCardType == cardType and cardId < tmpCardId then
        table.insert(cardIdList, i, cardId)
        didAdd = true
        break
      end
    end
    if not didAdd then
      table.insert(cardIdList, cardId)
      didAdd = true
    end
  end
  return didAdd
end

-- AiCardList · 添加牌idlist
function AiCardListData:addCardIdList(cardIdList)
  if cardIdList and 0 < #cardIdList then
    for _, cardId in ipairs(cardIdList) do
      self:addCardId(cardId)
    end
  end
  return true
end

-- AiCardList · 添加牌idlistwith牌型data
function AiCardListData:addCardIdListWithSuitData(suitData)
  local ret = false
  if suitData then
    local cardIdList = {}
    local cardDataArr = suitData:getCardDataArr()
    for _, cardData in ipairs(cardDataArr) do
      local cardId = cardData:getId()
      table.insert(cardIdList, cardId)
    end
    ret = self:addCardIdList(cardIdList)
  end
  return ret
end

-- AiCardList · 移除牌id
function AiCardListData:removeCardId(cardId)
  local didRemove = false
  local cardIdList = self:getCardIdList()
  if cardIdList and 0 < #cardIdList then
    for i, tmpCardId in ipairs(cardIdList) do
      if tmpCardId == cardId then
        table.remove(cardIdList, i)
        didRemove = true
        break
      end
    end
  end
  return didRemove
end

-- AiCardList · 移除牌idlist
function AiCardListData:removeCardIdList(cardIdList)
  if cardIdList and 0 < #cardIdList then
    local enableRemove = self:hasCardIdList(cardIdList)
    if enableRemove then
      for _, cardId in ipairs(cardIdList) do
        self:removeCardId(cardId)
      end
      return true
    else
      return false
    end
  else
    return true
  end
end

-- AiCardList · 移除牌idlistwith牌型data
function AiCardListData:removeCardIdListWithSuitData(suitData)
  local ret = false
  if suitData then
    local cardIdList = {}
    local cardDataArr = suitData:getCardDataArr()
    for _, cardData in ipairs(cardDataArr) do
      local cardId = cardData:getId()
      table.insert(cardIdList, cardId)
    end
    ret = self:removeCardIdList(cardIdList)
  end
  return ret
end

-- AiCardList · 托管模式下的出牌选择
function AiCardListData:getSuitDataForHost(lastSuitData)
  local ret
  local cardTypeListData = self:getTypeListData()
  local clearSuitData = cardTypeListData:toSuit(lastSuitData)
  if clearSuitData then
    ret = clearSuitData
  elseif lastSuitData then
    local biggerSuitDataArr = self:getHintSuitDataArr(lastSuitData)
    if biggerSuitDataArr then
      ret = biggerSuitDataArr[1]
    end
  else
    local allSuitData = self:getHostOutSuitDataArr(cardTypeListData)
    if allSuitData then
      ret = allSuitData[1]
    end
  end
  if ret then
    self:installSuitData(ret)
  end
  return ret
end

-- AiCardList · 获取托管out牌型dataarr
function AiCardListData:getHostOutSuitDataArr(cardTypeListData)
  local suitDataArr = cardTypeListData:ai_all_filterBiggerSuitDataArrFromHint()
  if 0 < #suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitType = suitData:getType()
      local cardCount = 0
      local level = suitData:getLevel()
      if level == self:getLazi() then
        suitData.isChunlazi_ = true
      else
        suitData.isChunlazi_ = false
        if level == CardType.kLittleJoker or level == CardType.kBigJoker then
          cardCount = cardTypeListData:getCardCountWithType(CardType.kLittleJoker)
            + cardTypeListData:getCardCountWithType(CardType.kBigJoker)
        else
          cardCount = cardTypeListData:getCardCountWithType(suitData:getLevel())
        end
        if
          suitType == SuitType.kPair and 2 < cardCount
          or suitType == SuitType.kThree and 3 < cardCount
          or suitType == SuitType.kSingle and 1 < cardCount
        then
          suitData.isGGH_ = false
        else
          suitData.isGGH_ = true
        end
      end
    end
    table.sort(suitDataArr, function(aSuit, bSuit)
      local flag = false
      if aSuit:getCardCount() == self:getCardCount() then
        return true
      end
      if bSuit:getCardCount() == self:getCardCount() then
        return false
      end
      if aSuit:getType() == SuitType.kDoubleJoker then
        return false
      end
      if bSuit:getType() == SuitType.kDoubleJoker then
        return true
      end
      if aSuit.isChunlazi_ == bSuit.isChunlazi_ then
        if aSuit:getType() == SuitType.kBomb and bSuit:getType() ~= SuitType.kBomb then
          flag = false
        elseif aSuit:getType() ~= SuitType.kBomb and bSuit:getType() == SuitType.kBomb then
          flag = true
        elseif aSuit:getLevel() == bSuit:getLevel() then
          flag = aSuit:getCardCount() > bSuit:getCardCount()
        elseif aSuit.isGGH_ == bSuit.isGGH_ then
          if aSuit:getIsLazi() == bSuit:getIsLazi() then
            flag = aSuit:getLevel() < bSuit:getLevel()
          else
            flag = not aSuit:getIsLazi()
          end
        else
          flag = aSuit.isGGH_
        end
      else
        flag = not aSuit.isChunlazi_
      end
      return flag
    end)
  end
  return suitDataArr
end

-- AiCardList · 获取hint牌型dataarr
function AiCardListData:getHintSuitDataArr(lastSuitData)
  if self.hintSuitDataArr_ == nil or lastSuitData ~= self.hintLastSuitData_ then
    self.hintLastSuitData_ = lastSuitData
    self.hintSuitDataArr_ = {}
    local cardTypeListData = self:getTypeListData()
    local suitDataArr = cardTypeListData:ai_all_filterBiggerSuitDataArrFromHint(lastSuitData)
    local haveDoubleJoker = false
    if 0 < #suitDataArr then
      local allBombSuitDataArr = self:getAllBomb()
      local lazi = self:getLazi()

      -- AiCardList ·
      local function checkSuitDataIsInBomb(checkSuitData)
        if allBombSuitDataArr and 0 < #allBombSuitDataArr then
          local needCardCountList = checkSuitData:getNeedCardCountList()
          local bombLevel
          for _, bombSuitData in ipairs(allBombSuitDataArr) do
            if not bombSuitData:getIsLazi() then
              bombLevel = bombSuitData:getLevel()
              if needCardCountList[bombLevel] and 0 < needCardCountList[bombLevel] then
                return true
              end
            end
          end
        end
        return false
      end

      for _, suitData in ipairs(suitDataArr) do
        local suitType = suitData:getType()
        local cardCount = 0
        local level = suitData:getLevel()
        if level == lazi then
          suitData.isChunlazi_ = true
        else
          suitData.isChunlazi_ = false
          if level == CardType.kLittleJoker or level == CardType.kBigJoker then
            cardCount = cardTypeListData:getCardCountWithType(CardType.kLittleJoker)
              + cardTypeListData:getCardCountWithType(CardType.kBigJoker)
          else
            cardCount = cardTypeListData:getCardCountWithType(suitData:getLevel())
          end
          if
            suitType == SuitType.kPair and cardCount == 2
            or (suitType == SuitType.kThree or suitType == SuitType.kThreeWithOneSingle or suitType == SuitType.kThreeWithOnePair) and cardCount == 3
            or suitType == SuitType.kSingle and cardCount == 1
            or suitType == SuitType.kBomb
            or suitType == SuitType.kDoubleJoker
          then
            suitData.isGGH_ = true
          else
            suitData.isGGH_ = false
          end
        end
        if suitType == SuitType.kDoubleJoker then
          haveDoubleJoker = true
        end
        if suitType ~= SuitType.kDoubleJoker and suitType ~= SuitType.kBomb then
          suitData.isDisBomb = checkSuitDataIsInBomb(suitData)
        end
      end
      if haveDoubleJoker then
        for _, suitData in ipairs(suitDataArr) do
          if suitData:getType() == SuitType.kSingle and suitData:getLevel() >= 16 then
            suitData.isDisBomb = true
          end
        end
      end
      table.sort(suitDataArr, function(aSuit, bSuit)
        local flag = false
        if aSuit:getCardCount() == self:getCardCount() and bSuit:getCardCount() ~= self:getCardCount() then
          return true
        end
        if aSuit:getCardCount() ~= self:getCardCount() and bSuit:getCardCount() == self:getCardCount() then
          return false
        end
        if aSuit:getType() == SuitType.kDoubleJoker then
          if bSuit.isDisBomb and (lastSuitData == nil or lastSuitData:getType() ~= SuitType.kSingle) then
            return true
          else
            return false
          end
        end
        if bSuit:getType() == SuitType.kDoubleJoker then
          if aSuit.isDisBomb and (lastSuitData == nil or lastSuitData:getType() ~= SuitType.kSingle) then
            return false
          else
            return true
          end
        end
        if aSuit.isChunlazi_ == bSuit.isChunlazi_ then
          if lastSuitData == nil then
            if aSuit:getType() == SuitType.kBomb and bSuit:getType() ~= SuitType.kBomb then
              flag = false
            elseif aSuit:getType() ~= SuitType.kBomb and bSuit:getType() == SuitType.kBomb then
              flag = true
            elseif aSuit:getLevel() == bSuit:getLevel() then
              flag = aSuit:getCardCount() > bSuit:getCardCount()
            elseif aSuit.isGGH_ == bSuit.isGGH_ then
              if aSuit:getIsLazi() == bSuit:getIsLazi() then
                flag = aSuit:getLevel() < bSuit:getLevel()
              else
                flag = not aSuit:getIsLazi()
              end
            else
              flag = aSuit.isGGH_
            end
          elseif aSuit:getType() == bSuit:getType() then
            if aSuit:getCardCount() == bSuit:getCardCount() then
              if not aSuit.isDisBomb and bSuit.isDisBomb then
                flag = true
              elseif aSuit.isDisBomb and not bSuit.isDisBomb then
                flag = false
              elseif aSuit.isDisBomb and bSuit.isDisBomb then
                flag = aSuit:getLevel() < bSuit:getLevel()
              elseif aSuit.isGGH_ == bSuit.isGGH_ then
                if aSuit:getIsLazi() == bSuit:getIsLazi() then
                  flag = aSuit:getLevel() < bSuit:getLevel()
                else
                  flag = aSuit:getIsLazi()
                end
              else
                flag = aSuit.isGGH_
              end
            else
              flag = aSuit:getCardCount() < bSuit:getCardCount()
            end
          elseif aSuit:getType() == SuitType.kBomb and bSuit.isDisBomb then
            flag = true
          elseif bSuit:getType() == SuitType.kBomb and aSuit.isDisBomb then
            flag = false
          elseif aSuit:getType() == SuitType.kDoubleJoker or bSuit:getType() == SuitType.kDoubleJoker then
            flag = true
          else
            flag = aSuit:getType() > bSuit:getType()
          end
        else
          flag = not aSuit.isChunlazi_
        end
        return flag
      end)
      for _, suitData in ipairs(suitDataArr) do
        self:installSuitData(suitData)
      end
    end
    self.hintSuitDataArr_ = suitDataArr
  end
  return self.hintSuitDataArr_
end

-- AiCardList · 枚举全部炸弹
function AiCardListData:getAllBomb()
  local cardTypeListData = self:getTypeListData()
  local ret = cardTypeListData:getAllBomb()
  return ret
end

-- AiCardList · 将手牌转为指定类型的 AiSuitData
function AiCardListData:toSuit(lastSuitData, suitType, isFromSelectCard)
  local cardTypeListData = self:getTypeListData()
  local ret, allRet = cardTypeListData:toSuit(lastSuitData, suitType, isFromSelectCard)
  if ret then
    self:installSuitData(ret)
  end
  return ret, allRet
end

-- AiCardList · out
function AiCardListData:out(suitData)
  local ret = self:removeCardIdListWithSuitData(suitData)
  if ret then
    self:clear()
  end
  return ret
end

-- AiCardList · clear
function AiCardListData:clear()
  self.typeListData_ = nil
  self.hintSuitDataArr_ = nil
end

-- AiCardList · test
function AiCardListData:test() end

return AiCardListData
