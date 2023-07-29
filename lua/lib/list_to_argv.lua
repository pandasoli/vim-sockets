---@param data table
---@return string
function ListToArgv(data)
  local res = ''

  for i, val in ipairs(data) do
    if
      type(val) == 'nil'
      or type(val) == 'boolean'
      or type(val) == 'number'
    then
      res = res .. val
    elseif type(val) == 'string' then
      local str = val
        :gsub('"', '\\"')
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
        :gsub('\t', '\\t')
        :gsub('\027', '\\027')

      return '"' .. str .. '"'
    elseif type(val) == 'table' then
      res = res .. ListToArgv(val)
    end

    if i < #data - 1 then res = res .. ', ' end
  end

  return res
end
