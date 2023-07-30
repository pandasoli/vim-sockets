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
