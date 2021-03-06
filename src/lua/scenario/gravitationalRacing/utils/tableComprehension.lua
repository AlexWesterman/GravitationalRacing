local M = {}

local errorHandler = require("scenario/gravitationalRacing/utils/errorHandler")

local function mergeAppend(a, b, ...)
  --[[
  Merges two or more integer indexed tables into a new table, preventing overwriting
  of the same index
  Parameters:
    a   - the first table
    b   - the second table
    ... - any additional tables
  Returns:
    c - the merged table
  ]]--
  errorHandler.assertNil(a, b)

  local tables = {a, b, ...}

  local c = {}
  local index = 1

  for _, T in ipairs(tables) do
    for _, v in ipairs(T) do
      c[index] = v
      index = index + 1
    end
  end

  return c
end

local function merge(a, b)
  --[[
  TODO - allow more than two tables
  Merges table b and a into c. If b is nil, then it returns a
  This does not merge in place, so can be used to clone a table
  Parameters:
    a - the first table
    b - the second table
  Returns:
    c - the merged table
  ]]--
  errorHandler.assertNil(a, b)

  local c = {}

  for k, v in pairs(a or {}) do
    c[k] = v
  end

  for k, v in pairs(b or {}) do
    c[k] = v
  end

  return c
end

local function lengthOfTable(T)
  --[[
  Gets the length of a table
  Parameters:
    T - the table
  Returns:
    c - the length of the table
  ]]--
  errorHandler.assertNil(T)

  local c = 0
  for _, _ in pairs(T) do
    c = c + 1
  end

  return c
end

local function contains(T, v)
  --[[
  Returns whether a table T contains a value v
  This function is recursively defined
  Parameters:
    T - the table
    v - the value to find
  Returns:
    <boolean> - whether T contains v
  ]]--
  errorHandler.assertNil(T, v)

  for _, value in ipairs(T) do
    if type(value) == "table" then
      if contains(value, v) then
        return true
      end
    else
      if value == v then
        return true
      end
    end
  end

  return false
end

local function flattenDict(T)
  --[[
  Flattens a table T by removing all sub-tables in T
  This version flattens dictionaries
  This function is recursively defined
  Parameters:
    T - the table to flatten
  Returns:
    flattenedT - the flattened version of T
  ]]--
  errorHandler.assertNil(T)

  --Base Case
  if type(T) ~= "table" then
    return {T}
  end

  --General Case
  local flattenedT = {}
  for k1, element in pairs(T) do
    for k2, value in pairs(flattenDict(element)) do
      --If flattenDict is called on a value, k2 will be 1 ie. a number
      if type(k2) ~= "number" then
        --Value is now a value and not a table (if it was previously)
        flattenedT[k2] = value
      else
        flattenedT[k1] = value
      end
    end
  end

  return flattenedT
end

local function flattenDictToArr(T)
  --[[
  Flattens a dictionary T by removing all sub-tables in T and converting to an array
  This function is recursively defined
  Parameters:
    T - the dictionary
  Returns:
    flattenedT - the flattened version of T
  ]]--
  --Base Case
  if type(T) ~= "table" then
    return {T}
  end

  --General Case
  local flattenedT = {}
  for _, element in pairs(T) do
    for _, value in pairs(flattenDictToArr(element)) do
      table.insert(flattenedT, value)
    end
  end

  return flattenedT
end

local function flatten(T)
  --[[
  Flattens a table T by removing all sub-tables in T whilst maintaining order
  This function is recursively defined
  Parameters:
    T - the table
  Returns:
    flattenedT - the flattened version of T
  ]]--
  --Base Case
  if type(T) ~= "table" then
    return {T}
  end

  --General Case
  local flattenedT = {}
  for _, element in ipairs(T) do
    for _, value in ipairs(flatten(element)) do
      --Value is now a value and not a table (if it was previously)
      table.insert(flattenedT, value)
    end
  end

  return flattenedT
end

local function containsIndex(T, v, indexes)
  --[[
  Returns the index (multiple for sub-tables) for a particular value in a table
  This function is recursively defined
  Parameters:
    T       - the table
    v       - the value
    indexes - the indexes found thus far ({} for starting call)
  Returns:
    <table> - the index(es) to find v in T
  ]]--
  errorHandler.assertNil(T, v, indexes)

  indexes = indexes or {}

  for i, value in ipairs(T) do
    if type(value) == "table" then
      local subindex = containsIndex(value, v, indexes)
      if subindex then
        return flatten({i, subindex})
      end
    else
      if value == v then
        return i
      end
    end
  end

  return nil
end

local function hasNumericalIndexes(T)
  --[[
  Returns whether a table T is numerically indexed ie. an array
  Parameters:
    T - the table
  Returns:
    <boolean> - if T is numerically indexed
  ]]--
  for i = 1, lengthOfTable(T) do
    --If there is no key, it cannot be an array
    if not T[i] then
      return false
    end
  end

  return true
end

local function getSmallestValue(T)
  --[[
  Returns the lowest value in a table
  This function is recursively defined
  Parameters:
    T - the table
  Returns:
    smallest - the smallest value in T
  ]]--
  errorHandler.assertNil(T)

  local smallest = math.huge

  local smallestInSubTable = function(value, smallest)
    --[[
    Finds the smallest value in a sub-table (can also be number for base case)
    Parameters:
      value    - the value of this element
      smallest - the current smallest
    Returns:
      smallest - the new smallest
    ]]--
    errorHandler.assertNil(value, smallest)

    local valType = type(value)
    if valType == "table" then
      local smallestInSubTable = getSmallestValue(value)
      if smallestInSubTable < smallest then
        smallest = smallestInSubTable
      end
    elseif valType == "number" then
      if value < smallest then
        smallest = value
      end
    end

    return smallest
  end

  --Sort out dictionaries from arrays
  if hasNumericalIndexes(T) then
    for _, value in ipairs(T) do
      smallest = smallestInSubTable(value, smallest)
    end
  else
    for _, value in pairs(T) do
      smallest = smallestInSubTable(value, smallest)
    end
  end

  return smallest
end

local function removeKey(T, K)
  --[[
  Removes a key from a nested dictionary
  This function is recursively defined
  Parameters:
    T - the table
    K - the key to remove
  Returns:
    T - the adjusted table T
  ]]--
  errorHandler.assertNil(T, K)

  for k, v in pairs(T) do
    if k == K then
      T[k] = nil
    elseif type(v) == "table" then
      v = removeKey(v, K)
    end
  end

  return T
end

local function repeatTableFrom(T, originalT, n)
  --[[
  A helper function for the function duplicate, which adds the
  contents in originalT to T n times
  Parameters:
    T - the current table
    originalT - the original table
    n - the number of times to repeat the table
  Returns:
    <table> - the repeated table T
  ]]--
  errorHandler.assertNil(T, originalT, n)

  if n == 1 then
    return T
  end

  return repeatTableFrom(mergeAppend(T, originalT), originalT, n-1)
end

local function repeatTable(T, n)
  --[[
  Repeats the entries in a table T n times
  Uses a helper function to provide a simpler interface
  Parameters:
    T - the table
    n - the number of times to repeat
  Parameters:
    <table> - the repeated table T
  ]]--
  return repeatTableFrom(T, T, n)
end

M.mergeAppend = mergeAppend
M.merge = merge
M.lengthOfTable = lengthOfTable
M.contains = contains
M.flattenDictToArr = flattenDictToArr
M.flattenDict = flattenDict
M.flatten = flatten
M.containsIndex = containsIndex
M.getSmallestValue = getSmallestValue
M.removeKey = removeKey
M.repeatTable = repeatTable
return M
