---@param data table
---@return boolean
function IsArray(data)
  local i = 1

  for k, _ in pairs(data) do
    if k ~= i then
      return false
    end

    i = i + 1
  end

  return true
end

function Generate_uuid(seed)
  local index = 0
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

  local uuid = template:gsub('[xy]', function(char)
    -- Increment an index to seed per char
    index = index + 1
    math.randomseed((seed or os.clock()) / index)

    local n = char == 'x'
      and math.random(0, 0xf)
      or math.random(8, 0xb)

    return string.format('%x', n)
  end)

  return uuid
end
