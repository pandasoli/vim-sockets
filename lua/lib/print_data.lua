---@param data any
---@param ident string|nil
---@return string
function PrintData(data, ident)
  ident = ident or ''

  if type(data) == 'nil' then
    return 'nil'
  elseif type(data) == 'number' then
    return data
  elseif type(data) == 'boolean' then
    return data and 'true' or 'false'
  elseif type(data) == 'string' then
    local str = data
      :gsub('"', '\\"')
      :gsub('\n', '\\n')
      :gsub('\r', '\\r')
      :gsub('\t', '\\t')
      :gsub('\027', '\\027')

    return '"' .. str .. '"'
  elseif type(data) == 'function' then
    return 'function() end'
  elseif type(data) == 'table' then
    local res = '{\n'
    ident = ident .. '  '

    local i = 0
    local lkeys = 0

    for _, _ in pairs(data) do
      lkeys = lkeys + 1
    end

    for k, v in pairs(data) do
      res = res ..
        ident .. '"' .. k .. '": ' ..
        PrintData(v, ident) ..
        ((i < lkeys - 1) and ',' or '') ..
        '\n'

      i = i + 1
    end

    ident = ident:sub(0, -3)
    return res .. (ident .. '}')
  end

  return '\"Could not undertand the type ' .. type(data) .. '.\"'
end
