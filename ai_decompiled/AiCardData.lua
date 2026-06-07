-- 文件: AiCardData.lua · 反编译 AI 模块（阅读用）

local AiCardData = class("AiCardData", DataBase)
AiCardData:addProperty("id", 0)
AiCardData:addProperty("type", 0)
AiCardData:addProperty("realType", 0)
AiCardData:addProperty("colorType", 0)
AiCardData:addProperty("isLazi", false)

-- AiCard · 构造函数
function AiCardData:ctor(properties)
  if type(properties) == "number" then
    self:initWithId(properties)
  else
    AiCardData.super.ctor(self, properties)
  end
end

-- AiCard · 创建withtype
function AiCardData:createWithType(cardType, colorType)
  colorType = colorType or 0
  local id = 0
  if cardType == CardType.kBigJoker then
    id = 56
  elseif cardType == CardType.kLittleJoker then
    id = 55
  else
    id = cardType + colorType * 13
  end
  return AiCardData.new(id)
end

-- AiCard · 初始化withid
function AiCardData:initWithId(id)
  self:setId(id)
  local tmpId = id - 3
  if tmpId < 0 or 53 < tmpId then
    return nil
  end
  local realType = 0
  local colorType = 0
  colorType = math.floor(tmpId / 13)
  realType = tmpId - colorType * 13
  realType = realType + 3
  if colorType == CardColorType.kJoker then
    realType = realType + 13
  end
  self:setType(realType)
  self:setRealType(realType)
  self:setColorType(colorType)
  return self
end

-- AiCard · 牌型/手牌的可读字符串
function AiCardData:toString()
  local str = ""
  local cardType = self:getType()
  if cardType == CardType.kAce then
    str = "A"
  elseif cardType == CardType.kTwo then
    str = "2"
  elseif cardType == CardType.kBigJoker then
    str = "🃏大"
  elseif cardType == CardType.kLittleJoker then
    str = "🃏小"
  elseif cardType == CardType.kKing then
    str = "K"
  elseif cardType == CardType.kQueen then
    str = "Q"
  elseif cardType == CardType.kJack then
    str = "J"
  elseif cardType <= CardType.kTen and cardType >= CardType.kThree then
    str = "" .. cardType
  else
    str = "X"
  end
  local colorType = self:getColorType()
  if colorType == CardColorType.kDiamond then
    str = "♦️" .. str
  elseif colorType == CardColorType.kClub then
    str = "♣️" .. str
  elseif colorType == CardColorType.kHeart then
    str = "❤️" .. str
  elseif colorType == CardColorType.kSpade then
    str = "♠️" .. str
  end
  local isLazi = self:getIsLazi()
  if isLazi then
    str = str .. "*"
  end
  return str
end

-- AiCard · 克隆当前对象
function AiCardData:clone(data)
  if data == nil then
    return nil
  end
  local properties = {
    id = self:getId(),
    type = self:getType(),
    realType = self:getRealType(),
    colorType = self:getColorType(),
    isLazi = self:getIsLazi(),
  }
  return AiCardData.new(properties)
end

-- AiCard · numbername
function AiCardData:numberName()
  if self.numberName_ == nil or self:getIsLazi() then
    local name
    local cardType = self:getType()
    if cardType == CardType.kBigJoker or cardType == CardType.kLittleJoker then
      name = "joker"
    elseif cardType == CardType.kAce then
      name = "a"
    elseif cardType == CardType.kTwo then
      name = "2"
    elseif cardType == CardType.kKing then
      name = "k"
    elseif cardType == CardType.kQueen then
      name = "q"
    elseif cardType == CardType.kJack then
      name = "j"
    else
      name = tostring(cardType)
    end
    self.numberName_ = "num_b_" .. name .. ".png"
  end
  return self.numberName_
end

-- AiCard · smallcolorname
function AiCardData:smallColorName()
  if self.smallColorName_ == nil or self:getIsLazi() then
    local name
    if self:getIsLazi() then
      name = "poker_laizi_s.png"
    else
      local colorType = self:getColorType()
      if colorType == CardColorType.kJoker then
        name = ""
      elseif colorType == CardColorType.kDiamond then
        name = "poker_diamond_s.png"
      elseif colorType == CardColorType.kClub then
        name = "poker_club_s.png"
      elseif colorType == CardColorType.kHeart then
        name = "poker_heart_s.png"
      else
        name = "poker_spade_s.png"
      end
    end
    self.smallColorName_ = name
  end
  return self.smallColorName_
end

-- AiCard · bigcolorname
function AiCardData:bigColorName()
  if self.bigColorName_ == nil or self:getIsLazi() then
    local name
    if self:getIsLazi() then
      name = "poker_laizi_d.png"
    else
      local colorType = self:getColorType()
      if colorType == CardColorType.kJoker then
        local cardType = self:getType()
        if cardType == CardType.kBigJoker then
          name = "poker_joker_d.png"
        else
          name = "poker_joker_s.png"
        end
      elseif colorType == CardColorType.kDiamond then
        name = "poker_diamond_d.png"
      elseif colorType == CardColorType.kClub then
        name = "poker_club_d.png"
      elseif colorType == CardColorType.kHeart then
        name = "poker_heart_d.png"
      else
        name = "poker_spade_d.png"
      end
    end
    self.bigColorName_ = name
  end
  return self.bigColorName_
end

-- AiCard · 判断是否equaltype
function AiCardData:isEqualType(data)
  return data ~= nil and data:getType() == self:getType()
end

-- AiCard · 判断是否equal
function AiCardData:isEqual(data)
  return data ~= nil and data:getId() == self:getId()
end

-- AiCard · 判断是否是否可顺子
function AiCardData:isEnableStraight()
  local cardType = self:getType()
  return cardType >= CardType.kThree and cardType <= CardType.kAce
end

-- AiCard · 移除one牌fromarr
function AiCardData:removeOneCardFromArr(arr, cardData)
  if arr == nil or #arr == 0 then
    cclog("Warning:AiCardData:removeOneCardFromArr:删除失败，列表是空")
    return false
  end
  if cardData == nil then
    cclog("Warning:AiCardData:removeOneCardFromArr:删除失败，牌是空")
    return false
  end
  for index, tmpCardData in ipairs(arr) do
    if cardData:isEqual(tmpCardData) then
      table.remove(arr, index)
      return true
    end
  end
  cclog("Warning:AiCardData:removeOneCardFromArr:删除失败，没找到这个牌" .. cardData:toString())
  return false
end

-- AiCard · 移除all牌fromarrwithtype
function AiCardData:removeAllCardFromArrWithType(arr, cardType)
  if arr == nil or #arr == 0 then
    cclog("Warning:AiCardData:removeAllCardFromArrWithType:删除失败，列表是空")
    return false
  end
  local count = 0
  for i = #arr, 1, -1 do
    local tmpCardData = arr[i]
    local realType = tmpCardData:getRealType()
    if realType == cardType then
      table.remove(arr, i)
      count = count + 1
    end
  end
  if count == 0 then
    cclog("Warning:AiCardData:removeAllCardFromArrWithType:删除失败，没找到该类型的牌，" .. cardType)
    return false
  end
  cclog("删除了%d张%d", count, cardType)
  return true
end

-- AiCard · 移除牌dataarrfromarr
function AiCardData:removeCardDataArrFromArr(arr, cardDataArr)
  if arr == nil or #arr == 0 then
    cclog("Warning:AiCardData:removeCardDataArrFromArr:删除失败，列表是空")
    return false
  end
  if cardDataArr == nil or #cardDataArr == 0 then
    cclog("Warning:AiCardData:removeCardDataArrFromArr:删除失败，子列表是空")
    return false
  end
  local tmpArr = {}
  for _, cardData in ipairs(arr) do
    table.insert(tmpArr, cardData)
  end
  local flag = true
  for _, cardData in ipairs(cardDataArr) do
    if not AiCardData:removeOneCardFromArr(tmpArr, cardData) then
      flag = false
      break
    end
  end
  if flag == false then
    cclog("Warning:AiCardData:removeCardDataArrFromArr:删除失败，删除元素失败")
    return false
  end
  for _, cardData in ipairs(cardDataArr) do
    AiCardData:removeOneCardFromArr(arr, cardData)
  end
  return true
end

-- AiCard · test
function AiCardData:test()
  local cardIdList = {}
  for i = 3, 56 do
    table.insert(cardIdList, i)
  end
  local cardDataArr = AiCardData:createDataArrWithList(cardIdList)
  for _, cardData in ipairs(cardDataArr) do
    print("cardData:", cardData:toString())
    print("     numberName:", cardData:numberName())
    print("     smallColorName:", cardData:smallColorName())
    print("     bigColorName:", cardData:bigColorName())
    print("     isEnableStraight:", cardData:isEnableStraight())
  end
  AiUtils:logCardDataArr(cardDataArr)
  cardDataArr[5]:setIsLazi(true)
  cardDataArr[18]:setIsLazi(true)
  cardDataArr[31]:setIsLazi(true)
  cardDataArr[44]:setIsLazi(true)
  local cardIdList2 = {}
  for i = 20, 56 do
    table.insert(cardIdList2, i)
  end
  local cardDataArr2 = AiCardData:createDataArrWithList(cardIdList2)
  AiCardData:removeCardDataArrFromArr(cardDataArr, cardDataArr2)
  AiUtils:logCardDataArr(cardDataArr, "removeCardDataArrFromArr:")
  AiCardData:removeAllCardFromArrWithType(cardDataArr, CardType.kThree)
  AiUtils:logCardDataArr(cardDataArr, "removeAllCardFromArrWithType:")
end

return AiCardData
