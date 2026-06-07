-- 文件: AiSuitData.lua · 反编译 AI 模块（阅读用）

local AiSuitData = class("AiSuitData", DataBase)
AiSuitData:addProperty("uid", 0)
AiSuitData:addProperty("cardDataArr", {})
AiSuitData:addProperty("cardCount", 0)
AiSuitData:addProperty("level", 0)
AiSuitData:addProperty("needCardCountList", {})
AiSuitData:addProperty("lazi", 0)
AiSuitData:addProperty("isLazi", false)
AiSuitData:addProperty("equalCount", 0)
AiSuitData:addProperty("biggerCount", 0)
AiSuitData:addProperty("smallerCount", 0)
AiSuitData:addProperty("useBombCount", 0)

-- AiSuit · 构造函数
function AiSuitData:ctor(properties)
  AiSuitData.super.ctor(self, properties)
end

-- AiSuit · 由 {uid,cards} 映射创建牌型对象
function AiSuitData:createWithMap(map, lazi)
  if map == nil or map.cards == nil then
    return nil
  end
  local ret
  local cardIdList = map.cards
  local uid = map.uid
  local params = { cardIdList = cardIdList, lazi = lazi }
  local cardListData = AiCardListData.new(params)
  if cardListData then
    ret = cardListData:toSuit()
    if ret then
      ret:setUid(map.uid)
    end
  end
  return ret
end

-- AiSuit · 转为 {uid,cards} 供回调
function AiSuitData:toMap()
  local ret = {}
  local uid = self:getUid()
  local cardDataArr = self:getCardDataArr()
  local cardIdList
  if cardDataArr and 0 < #cardDataArr then
    cardIdList = {}
    for _, cardData in ipairs(cardDataArr) do
      local cardId = cardData:getId()
      if 0 < cardId then
        table.insert(cardIdList, cardId)
      end
    end
  end
  ret.uid = uid
  ret.cards = cardIdList
  return ret
end

-- AiSuit · 牌型/手牌的可读字符串
function AiSuitData:toString()
  local str = string.format("%s(level:%2d):", self:getName(), self:getLevel())
  if self:getCardDataArr() and #self:getCardDataArr() > 0 then
    for _, aCard in ipairs(self:getCardDataArr()) do
      str = str .. " " .. aCard:toString()
    end
  else
    local needCardCountList = self:getNeedCardCountList()
    if needCardCountList then
      for cardType, count in pairs(needCardCountList) do
        for i = 1, count do
          str = str .. " " .. AiCardData:createWithType(cardType):toString()
        end
      end
    end
  end
  return str
end

-- AiSuit · 克隆当前对象
function AiSuitData:clone(data)
  if data == nil then
    return nil
  end
  local ret = data.new()
  if ret then
    ret.m_discardWeight = data.m_discardWeight
    ret.m_type = data.m_type
    ret.m_audioName = data.m_audioName
    ret.m_name = data.m_name
    ret.m_description = data.m_description
    ret.m_cards = copyListTable(data.m_cards)
    ret.m_cardCount = data.m_cardCount
    ret.m_level = data.m_level
    ret.m_needCardCountList = copyTab(data.m_needCardCountList)
    ret.m_hasCardCountList = copyTab(data.m_hasCardCountList)
    ret.m_isLazi = data.m_isLazi
    ret.m_lazi = data.m_lazi
    ret.m_type = data.m_type
    ret.m_realType = data.m_realType
    ret.m_colorType = data.m_colorType
    ret.m_isLazi = data.m_isLazi
  end
  return ret
end

-- AiSuit · 比较两手牌型大小（是否大过对方）
function AiSuitData:isWin(data)
  if data == nil then
    return true
  end
  if self:getType() == SuitType.kDoubleJoker then
    return true
  end
  if data:getType() == SuitType.kDoubleJoker then
    return false
  end
  if self:getType() == SuitType.kBomb and data:getType() ~= SuitType.kBomb then
    return true
  end
  if self:getType() ~= SuitType.kBomb and data:getType() == SuitType.kBomb then
    return false
  end
  if self:getType() == SuitType.kBomb and data:getType() == SuitType.kBomb then
    if self:isLaziBomb() then
      return true
    end
    if data:isLaziBomb() then
      return false
    end
    if not self:getIsLazi() and data:getIsLazi() then
      return true
    end
    if self:getIsLazi() and not data:getIsLazi() then
      return false
    end
    return self:getLevel() > data:getLevel()
  end
  if self:getType() ~= data:getType() or self:getCardCount() ~= data:getCardCount() then
    return false
  end
  return self:getLevel() > data:getLevel()
end

-- AiSuit · 是否为癞子组成的炸弹
function AiSuitData:isLaziBomb()
  if self:getType() ~= SuitType.kBomb then
    return false
  end
  local lazi = self:getLazi()
  if lazi == nil or lazi <= 0 then
    return false
  end
  local level = self:getLevel()
  if level == lazi then
    return true
  else
    return false
  end
end

-- AiSuit · 获取ui牌dataarr
function AiSuitData:getUICardDataArr()
  local ret = {}
  local cardDataArr = self:getCardDataArr()
  table.insertto(ret, cardDataArr)
  AiUtils:sortCardsForOut(ret)
  return ret
end

-- AiSuit · 获取牌型枚举 SuitType
function AiSuitData:getType()
  return SuitType.kUnkown
end

-- AiSuit · 获取牌型名称
function AiSuitData:getName()
  return ""
end

-- AiSuit · 获取description
function AiSuitData:getDescription()
  return ""
end

-- AiSuit · 获取audioname
function AiSuitData:getAudioName()
  return ""
end

-- AiSuit · 获取evaluation
function AiSuitData:getEvaluation()
  return 0
end

-- AiSuit · 获取discardweight
function AiSuitData:getDiscardWeight()
  return 0
end

-- AiSuit · 获取牌型评分
function AiSuitData:getScore()
  return 0
end

-- AiSuit · 获取levelcount
function AiSuitData:getLevelCount()
  return 1
end

-- AiSuit · 获取samecount
function AiSuitData:getSameCount()
  return 1
end

-- AiSuit · 获取minlevelcount
function AiSuitData:getMinLevelCount()
  return 1
end

-- AiSuit · 获取key
function AiSuitData:getKey()
  if self.key_ == nil then
    local suitType = self:getType()
    local cardCount = self:getCardCount()
    self.key_ = string.format("%d-%d", suitType, cardCount)
  end
  return self.key_
end

-- AiSuit · 获取排序markkey
function AiSuitData:getSortMarkKey()
  if self.sortMarkKey_ == nil then
    local suitType = self:getType()
    local level = self:getLevel()
    local levelCount = self:getLevelCount()
    if self.getSuitInfo then
      local suitInfo = self:getSuitInfo()
      if suitInfo.straightMainSuitType then
        suitType = suitInfo.straightMainSuitType
      elseif suitInfo.mainSuitType then
        suitType = suitInfo.mainSuitType
      end
    end
    self.sortMarkKey_ = string.format("%d-%d-%d", suitType, level, levelCount)
  end
  return self.sortMarkKey_
end

-- AiSuit · 获取idkey
function AiSuitData:getIdKey()
  if self.idKey_ == nil then
    local suitType = self:getType()
    local level = self:getLevel()
    local levelCount = self:getLevelCount()
    self.idKey_ = string.format("%d-%d-%d", suitType, level, levelCount)
  end
  return self.idKey_
end

-- AiSuit · 获取scoremap
function AiSuitData:getScoreMap()
  if self.scoreMap_ == nil then
    self.scoreMap_ = {
      [3] = 21,
      [4] = 22,
      [5] = 23,
      [6] = 24,
      [7] = 25,
      [8] = 26,
      [9] = 27,
      [10] = 28,
      [11] = 29,
      [12] = 30,
      [13] = 31,
      [14] = 32,
      [15] = 35,
      [16] = 36,
      [17] = 40,
    }
  end
  return self.scoreMap_
end

-- AiSuit · 获取牌typescore
function AiSuitData:getCardTypeScore(cardType)
  local map = self:getScoreMap()
  return map[cardType] or 0
end

-- AiSuit · 获取牌型classlist
function AiSuitData:getSuitClassList()
  if self.suitClassList_ == nil then
    self.suitClassList_ = {
      AiSuitDoubleJokerData,
      AiSuitBombData,
      AiSuitThreeStraightWithPairData,
      AiSuitThreeStraightWithSingleData,
      AiSuitThreeStraightData,
      AiSuitDoubleStraightData,
      AiSuitStraightData,
      AiSuitFourWithTwoPairData,
      AiSuitFourWithTwoSingleData,
      AiSuitThreeWithOnePairData,
      AiSuitThreeWithOneSingleData,
      AiSuitThreeData,
      AiSuitPairData,
      AiSuitSingleData,
    }
  end
  return self.suitClassList_
end

-- AiSuit · 获取牌型classmap
function AiSuitData:getSuitClassMap()
  if self.suitClassMap_ == nil then
    self.suitClassMap_ = {
      [SuitType.kDoubleJoker] = AiSuitDoubleJokerData,
      [SuitType.kBomb] = AiSuitBombData,
      [SuitType.kThreeStraightWithPair] = AiSuitThreeStraightWithPairData,
      [SuitType.kThreeStraightWithSingle] = AiSuitThreeStraightWithSingleData,
      [SuitType.kThreeStraight] = AiSuitThreeStraightData,
      [SuitType.kDoubleStraight] = AiSuitDoubleStraightData,
      [SuitType.kStraight] = AiSuitStraightData,
      [SuitType.kFourWithTwoPair] = AiSuitFourWithTwoPairData,
      [SuitType.kFourWithTwoSingle] = AiSuitFourWithTwoSingleData,
      [SuitType.kThreeWithOnePair] = AiSuitThreeWithOnePairData,
      [SuitType.kThreeWithOneSingle] = AiSuitThreeWithOneSingleData,
      [SuitType.kThree] = AiSuitThreeData,
      [SuitType.kPair] = AiSuitPairData,
      [SuitType.kSingle] = AiSuitSingleData,
    }
  end
  return self.suitClassMap_
end

-- AiSuit · 获取classwith牌型type
function AiSuitData:getClassWithSuitType(suitType)
  local map = self:getSuitClassMap()
  return map[suitType]
end

-- AiSuit · 获取simple牌型classlist
function AiSuitData:getSimpleSuitClassList()
  if self.simpleSuitClassList_ == nil then
    self.simpleSuitClassList_ = {
      AiSuitDoubleJokerData,
      AiSuitBombData,
      AiSuitThreeStraightData,
      AiSuitDoubleStraightData,
      AiSuitStraightData,
      AiSuitThreeData,
      AiSuitPairData,
      AiSuitSingleData,
    }
  end
  return self.simpleSuitClassList_
end

-- AiSuit · 创建with牌typelistdata
function AiSuitData:createWithCardTypeListData(cardTypeListData, lastSuitData, suitType, isFromSelectCard)
  local suitClassList
  if lastSuitData == nil then
    if suitType == nil then
      suitClassList = AiSuitData:getSuitClassList()
    else
      suitClassList = {
        AiSuitData:getClassWithSuitType(suitType),
      }
    end
  else
    local lastSuitType = lastSuitData:getType()
    if lastSuitType == SuitType.kDoubleJoker then
      suitClassList = {}
    elseif lastSuitType == SuitType.kBomb then
      suitClassList = {
        AiSuitData:getClassWithSuitType(SuitType.kDoubleJoker),
        AiSuitData:getClassWithSuitType(SuitType.kBomb),
      }
    else
      suitClassList = {
        AiSuitData:getClassWithSuitType(SuitType.kDoubleJoker),
        AiSuitData:getClassWithSuitType(SuitType.kBomb),
        AiSuitData:getClassWithSuitType(lastSuitType),
      }
    end
  end
  local ret = {}
  for _, suitClass in ipairs(suitClassList) do
    local suitData, suitData2 = suitClass:createWithCardTypeListData(cardTypeListData, isFromSelectCard)
    if suitData and (lastSuitData == nil or suitData:isWin(lastSuitData)) then
      table.insert(ret, suitData)
    end
    if suitData2 and (lastSuitData == nil or suitData2:isWin(lastSuitData)) then
      table.insert(ret, suitData2)
    end
  end
  return ret[1], ret
end

-- AiSuit · 枚举手牌全部牌型组合
function AiSuitData:getAllSuitData(cardTypeListData, lastSuitData, async)
  local suitClassList
  if lastSuitData == nil then
    suitClassList = AiSuitData:getSimpleSuitClassList()
  else
    local lastSuitType = lastSuitData:getType()
    if lastSuitType == SuitType.kDoubleJoker then
      suitClassList = {}
    elseif lastSuitType == SuitType.kBomb then
      suitClassList = {
        AiSuitData:getClassWithSuitType(SuitType.kDoubleJoker),
        AiSuitData:getClassWithSuitType(SuitType.kBomb),
      }
    else
      suitClassList = {
        AiSuitData:getClassWithSuitType(SuitType.kDoubleJoker),
        AiSuitData:getClassWithSuitType(SuitType.kBomb),
        AiSuitData:getClassWithSuitType(lastSuitType),
      }
    end
  end
  local ret = {}
  for i, suitClass in ipairs(suitClassList) do
    if async and i % 4 == 0 then
      coroutine.yield()
    end
    local suitDataArr = suitClass:getAllSuitData(cardTypeListData)
    if suitDataArr and 0 < #suitDataArr then
      for _, suitData in ipairs(suitDataArr) do
        table.insert(ret, suitData)
      end
    end
  end
  AiSuitData:sortSuits(ret)
  return ret
end

-- AiSuit · need检查
function AiSuitData:needCheck()
  local suitType = self:getType()
  if suitType == SuitType.kThreeWithOneSingle then
    return true
  else
    return false
  end
end

-- AiSuit · 校验牌型是否合法、能否压过上家
function AiSuitData:check(lastSuitData)
  local needCheck = self:needCheck()
  if not needCheck then
    return self
  end
  local needCardCountList = self:getNeedCardCountList()
  local cardTypeList = {}
  for k, v in pairs(needCardCountList) do
    for i = 1, v do
      table.insert(cardTypeList, k)
    end
  end
  local lazi = self:getLazi()
  local cardTypeListData = AiCardTypeListData.new({ cardTypeList = cardTypeList, lazi = lazi })
  local suitData = AiSuitData:createWithCardTypeListData(cardTypeListData, lastSuitData, nil)
  if suitData and suitData:getType() ~= self:getType() then
    return suitData
  else
    return self
  end
end

-- AiSuit · 排序suits
function AiSuitData:sortSuits(suitDataArr)
  table.sort(suitDataArr, function(a, b)
    local flag = false
    if a ~= nil and b ~= nil then
      if a:getType() == b:getType() then
        if a:getCardCount() == b:getCardCount() then
          if a:isLaziBomb() then
            return false
          end
          if b:isLaziBomb() then
            return true
          end
          if not a:getIsLazi() and b:getIsLazi() then
            return false
          end
          if a:getIsLazi() and not b:getIsLazi() then
            return true
          end
          return a:getLevel() < b:getLevel()
        else
          flag = a:getCardCount() <= b:getCardCount()
        end
      else
        flag = a:getType() >= b:getType()
      end
    end
    return flag
  end)
end

-- AiSuit · 排序suitsforhint
function AiSuitData:sortSuitsForHint(suitDataArr)
  table.sort(suitDataArr, function(a, b)
    local flag = false
    if a ~= nil and b ~= nil then
      if a:getDiscardWeight() == b:getDiscardWeight() then
        if a:getLevel() == b:getLevel() then
          flag = a:getType() > b:getType()
        else
          flag = a:getLevel() < b:getLevel()
        end
      else
        flag = a:getDiscardWeight() > b:getDiscardWeight()
      end
    end
    return flag
  end)
end

-- AiSuit · test
function AiSuitData:test() end

return AiSuitData
