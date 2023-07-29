require 'sockets.utils'

---@param data any
---@return string
function EncodeJSON(data)
  if
    type(data) == 'nil'
    or type(data) == 'number'
    or type(data) == 'boolean'
  then
    return tostring(data)
  elseif type(data) == 'string' then
    local str = data
      :gsub('"', '\\"')
      :gsub('\n', '\\n')
      :gsub('\r', '\\r')
      :gsub('\t', '\\t')
      :gsub('\027', '\\027')

    return '"' .. str .. '"'
  elseif type(data) == 'table' then
    local res = ''
    local lkeys = 1
    local is_array = IsArray(data)

    for _, _ in pairs(data) do
      lkeys = lkeys + 1
    end

    if is_array then
      for i, val in ipairs(data) do
        res = res .. EncodeJSON(val)

        if i < lkeys - 1 then
          res = res .. ', '
        end
      end
    else
      local i = 1
      for k, v in pairs(data) do
        res = res
          .. EncodeJSON(tostring(k)) .. ': '
          .. EncodeJSON(v)

        if i < lkeys - 1 then
          res = res .. ', '
        end

        i = i + 1
      end
    end

    if is_array then res = '[' .. res .. ']'
    else res = '{' .. res .. '}'
    end

    return res
  end

  return 'nil'
end
