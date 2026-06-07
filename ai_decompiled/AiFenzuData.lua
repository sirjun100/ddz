-- 文件: AiFenzuData.lua · 反编译 AI 模块（阅读用）

local AiFenzuData = class("AiFenzuData")

-- AiFenzu · 构造函数
function AiFenzuData:ctor(params)
  self.suitDataArr_ = params.suitDataArr
  self.sortMark_ = params.sortMark
  self.lun_ = params.lun
  self.score_ = params.score
  self.qiangQuanCount_ = params.qiangQuanCount
  self:init()
end

-- AiFenzu · 初始化
function AiFenzuData:init()
  local suitDataArr = self.suitDataArr_
  local sortMark = self.sortMark_
  local lun = self.lua_
  local score = self.score_
  table.sort(suitDataArr, function(a, b)
    return a:getLevel() < b:getLevel()
  end)
  self.notBombSuitDataArrDict_ = {}
  self.maxCountMap_ = {}
  for _, suitData in ipairs(suitDataArr) do
    if suitData:getType() > SuitType.kBomb then
      local key = suitData:getKey()
      if self.notBombSuitDataArrDict_[key] == nil then
        self.notBombSuitDataArrDict_[key] = {}
      end
      table.insert(self.notBombSuitDataArrDict_[key], suitData)
      local sortMarkKey = suitData:getSortMarkKey()
      local sortMark = self.sortMark_[sortMarkKey]
      if sortMark.biggerCount == 0 then
        if self.maxCountMap_[key] == nil then
          self.maxCountMap_[key] = 0
        end
        self.maxCountMap_[key] = self.maxCountMap_[key] + 1
      end
    end
  end
  local qiangQuanCount = self.qiangQuanCount_
  if 0 < qiangQuanCount then
    local key = "17-1"
    self.maxCountMap_[key] = qiangQuanCount
  end
end

-- AiFenzu · 获取牌型dataarrwithkey
function AiFenzuData:getSuitDataArrWithKey(suitKey)
  return self.notBombSuitDataArrDict_[suitKey] or {}
end

-- AiFenzu · 获取maxcountwithkey
function AiFenzuData:getMaxCountWithKey(suitKey)
  return self.maxCountMap_[suitKey] or 0
end

-- AiFenzu · 获取liu牌型dataarrwithkey
function AiFenzuData:getLiuSuitDataArrWithKey(suitKey)
  local ret = {}
  local maxCount = self:getMaxCountWithKey(suitKey)
  local suitDataArr = self:getSuitDataArrWithKey(suitKey)
  local suitCount = #suitDataArr
  for i = 1, suitCount - maxCount do
    local suitData = suitDataArr[i]
    if not suitData.isQiangQuan then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiFenzu · 获取mustliu牌型dataarrwithkey
function AiFenzuData:getMustLiuSuitDataArrWithKey(suitKey)
  local ret = {}
  local maxCount = self:getMaxCountWithKey(suitKey)
  local suitDataArr = self:getSuitDataArrWithKey(suitKey)
  local suitCount = #suitDataArr
  for i = maxCount + 1, suitCount - maxCount do
    local suitData = suitDataArr[i]
    if 0 < maxCount and not suitData.isQiangQuan then
      table.insert(ret, suitData)
    end
  end
  return ret
end

-- AiFenzu · 获取mustliuc牌型dataarrwithkey
function AiFenzuData:getMustLiuCSuitDataArrWithKey(suitKey)
  local ret = {}
  local maxCount = self:getMaxCountWithKey(suitKey)
  if maxCount == 0 then
    local suitDataArr = self:getSuitDataArrWithKey(suitKey)
    local suitCount = #suitDataArr
    for i = 1, suitCount do
      local suitData = suitDataArr[i]
      if not suitData.isQiangQuan then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiFenzu · 获取lmin牌型datawithkey
function AiFenzuData:getLminSuitDataWithKey(suitKey)
  local ret
  local maxCount = self:getMaxCountWithKey(suitKey)
  local suitDataArr = self:getSuitDataArrWithKey(suitKey)
  local suitCount = #suitDataArr
  if maxCount < suitCount then
    local suitData = suitDataArr[1]
    if suitData and not suitData.isQiangQuan then
      ret = suitData
    end
  end
  return ret
end

-- AiFenzu · 获取lmax牌型datawithkey
function AiFenzuData:getLmaxSuitDataWithKey(suitKey)
  local ret
  local maxCount = self:getMaxCountWithKey(suitKey)
  local suitDataArr = self:getSuitDataArrWithKey(suitKey)
  local suitCount = #suitDataArr
  if maxCount < suitCount then
    for i = suitCount - maxCount, 1, -1 do
      local suitData = suitDataArr[suitCount - maxCount]
      if not suitData.isQiangQuan then
        ret = suitData
        break
      end
    end
  end
  return ret
end

-- AiFenzu · 获取lmax过滤max牌型datawithkey
function AiFenzuData:getLmaxFilterMaxSuitDataWithKey(suitKey)
  local ret
  local type = 1
  local maxCount = self:getMaxCountWithKey(suitKey)
  local suitDataArr = self:getSuitDataArrWithKey(suitKey)
  local suitCount = #suitDataArr
  if maxCount < suitCount then
    for i = suitCount - maxCount, 1, -1 do
      local suitData = suitDataArr[suitCount - maxCount]
      if not suitData.isQiangQuan and suitData:getLevel() < CardType.kTwo then
        ret = suitData
        if maxCount == 0 then
          type = 1
          break
        end
        type = 2
        break
      end
    end
  else
    type = 3
  end
  return ret, type
end

-- AiFenzu · 获取allliu牌型data
function AiFenzuData:getAllLiuSuitData()
  local ret = {}
  local suitDataArrDict = self.notBombSuitDataArrDict_ or {}
  for suitKey, _ in pairs(suitDataArrDict) do
    local suitDataArr = self:getLiuSuitDataArrWithKey(suitKey)
    table.insertto(ret, suitDataArr)
  end
  return ret
end

-- AiFenzu · 获取allmustliu牌型data
function AiFenzuData:getAllMustLiuSuitData()
  local ret = {}
  local suitDataArrDict = self.notBombSuitDataArrDict_ or {}
  for suitKey, _ in pairs(suitDataArrDict) do
    local suitDataArr = self:getMustLiuSuitDataArrWithKey(suitKey)
    table.insertto(ret, suitDataArr)
  end
  return ret
end

-- AiFenzu · 获取allmustliuc牌型data
function AiFenzuData:getAllMustLiuCSuitData()
  local ret = {}
  local suitDataArrDict = self.notBombSuitDataArrDict_ or {}
  for suitKey, _ in pairs(suitDataArrDict) do
    local suitDataArr = self:getMustLiuCSuitDataArrWithKey(suitKey)
    table.insertto(ret, suitDataArr)
  end
  return ret
end

-- AiFenzu · 获取alllmin牌型data
function AiFenzuData:getAllLminSuitData()
  local ret = {}
  local suitDataArrDict = self.notBombSuitDataArrDict_ or {}
  for suitKey, _ in pairs(suitDataArrDict) do
    local suitDataArr = self:getLminSuitDataWithKey(suitKey)
    table.insertto(ret, suitDataArr)
  end
  return ret
end

-- AiFenzu · 获取alllmax牌型data
function AiFenzuData:getAllLmaxSuitData()
  local ret = {}
  local suitDataArrDict = self.notBombSuitDataArrDict_ or {}
  for suitKey, _ in pairs(suitDataArrDict) do
    local suitDataArr = self:getLmaxSuitDataWithKey(suitKey)
    table.insertto(ret, suitDataArr)
  end
  return ret
end

-- AiFenzu · 过滤smallerlmin牌型dataarr
function AiFenzuData:filterSmallerLminSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitKey = suitData:getKey()
      local lminSuitData = self:getLminSuitDataWithKey(suitKey)
      if lminSuitData and lminSuitData:isWin(suitData) then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiFenzu · 过滤smallerlmax牌型dataarr
function AiFenzuData:filterSmallerLmaxSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitKey = suitData:getKey()
      local lmaxSuitData = self:getLmaxSuitDataWithKey(suitKey)
      if lmaxSuitData and lmaxSuitData:isWin(suitData) then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiFenzu · 过滤biggerlmax牌型dataarr
function AiFenzuData:filterBiggerLmaxSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitKey = suitData:getKey()
      local lmaxSuitData = self:getLmaxSuitDataWithKey(suitKey)
      if lmaxSuitData == nil or not lmaxSuitData:isWin(suitData) then
        table.insert(ret, suitData)
      end
    end
  end
  return ret
end

-- AiFenzu · 过滤biggermustliutwo牌型dataarr
function AiFenzuData:filterBiggerMustLiuTwoSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitKey = suitData:getKey()
      local mustLiuSuitDataArr = self:getMustLiuSuitDataArrWithKey(suitKey)
      if mustLiuSuitDataArr and 2 <= #mustLiuSuitDataArr then
        local mustLiuSuitDataTwo = mustLiuSuitDataArr[2]
        if not mustLiuSuitDataTwo:isWin(suitData) then
          table.insert(ret, suitData)
        end
      end
      local mustLiuCSuitDataArr = self:getMustLiuCSuitDataArrWithKey(suitKey)
      if mustLiuCSuitDataArr and 2 <= #mustLiuCSuitDataArr then
        local mustLiuSuitCDataTwo = mustLiuCSuitDataArr[2]
        if not mustLiuSuitCDataTwo:isWin(suitData) then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

-- AiFenzu · 过滤biggerliutwo牌型dataarr
function AiFenzuData:filterBiggerLiuTwoSuitDataArr(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitKey = suitData:getKey()
      local liuSuitDataArr = self:getLiuSuitDataArrWithKey(suitKey)
      if liuSuitDataArr and 2 <= #liuSuitDataArr then
        local liuSuitDataTwo = liuSuitDataArr[2]
        if not liuSuitDataTwo:isWin(suitData) then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

-- AiFenzu · 过滤biggerlmax牌型dataarrwithoutmax
function AiFenzuData:filterBiggerLmaxSuitDataArrWithoutMax(suitDataArr)
  local ret = {}
  if suitDataArr then
    for _, suitData in ipairs(suitDataArr) do
      local suitType = suitData:getType()
      if suitType > SuitType.kBomb then
        local biggerCount = suitData:getBiggerCount()
        local smallerCount = suitData:getSmallerCount()
        local equalCount = suitData:getEqualCount()
        local suitKey = suitData:getKey()
        local lmaxSuitData, type = self:getLmaxFilterMaxSuitDataWithKey(suitKey)
        if type == 1 then
          if suitData:getLevel() < CardType.kTwo and (lmaxSuitData == nil or not lmaxSuitData:isWin(suitData)) then
            table.insert(ret, suitData)
          end
        elseif type == 2 then
          if
            0 < biggerCount
            and not suitData.isQiangQuan
            and (lmaxSuitData == nil or not lmaxSuitData:isWin(suitData))
          then
            table.insert(ret, suitData)
          end
        elseif
          (0 < biggerCount or biggerCount == 0 and smallerCount == 0 and equalCount == 0) and not suitData.isQiangQuan
        then
          table.insert(ret, suitData)
        end
      end
    end
  end
  return ret
end

return AiFenzuData
