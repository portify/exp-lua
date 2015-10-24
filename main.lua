local program = setmetatable({
  __call = function(prog, stack, scope)
    for _, item in ipairs(prog) do
      if item.op == "push" then
        table.insert(stack, item.value)
      elseif item.op == "call" then
        local func = scope[item.name]
        if func == nil then error("unknown symbol " .. item.name) end
        func(stack, scope)
      else
        error("unknown op " .. item.op)
      end
    end
  end
}, {
  __call = function(mt, t)
    return setmetatable(t or {}, mt)
  end
})

local function stringset(str)
  local set = {}
  for i=1, #str do
    set[str:sub(i, i)] = true
  end
  return set
end

local is_space = stringset " \f\t\r\n"
local is_digit = stringset "0123456789." -- technically . shouldn't be here
local is_ident = stringset "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`~1!2@3#4$5%6^7&8*90-_=+,<.>/?;:[{]}\\|"

local function compile(source)
  local programs = {program()}
  local i = 1

  while i <= #source do
    local char = source:sub(i, i)
    i = i + 1

    if char == "(" then
      table.insert(programs, program())
    elseif char == ")" then
      assert(#programs > 1, "extra )")
      local top = table.remove(programs)
      table.insert(programs[#programs], {op = "push", value = top})
    elseif char == '"' or char == "'" then
      local sep = char
      local chars = {}

      while true do
        assert(i <= #source, 'missing "')
        char = source:sub(i, i)
        i = i + 1
        if char == sep then break end
        table.insert(chars, char)
      end

      local value = table.concat(chars)
      table.insert(programs[#programs], {op = "push", value = value})
    elseif is_digit[char] or (char == "-" and i <= #source and is_digit[source:sub(i, i)]) then
      local start = i

      while i <= #source and is_digit[source:sub(i, i)] do
        i = i + 1
      end

      local value = tonumber(source:sub(start - 1, i - 1))
      table.insert(programs[#programs], {op = "push", value = value})
    elseif is_ident[char] then
      local chars = {char}

      while i <= #source do
        char = source:sub(i, i)
        if not is_ident[char] then break end
        i = i + 1
        table.insert(chars, char)
      end

      local name = table.concat(chars)
      table.insert(programs[#programs], {op = "call", name = name})
    elseif not is_space[char] then
      error("unknown token")
    end
  end

  assert(#programs == 1, "missing )")
  return programs[1]
end

-- local function print_program(prog)
--   for _, item in ipairs(prog) do
--     if item.op == "push" then
--       print("push", item.value)
--     elseif item.op == "call" then
--       print("call", item.name)
--     else
--       error("unknown op " .. item.op)
--     end
--   end
-- end

local prog = compile(table.concat(arg, " "))
local stack = {}
local scope = setmetatable({}, {__index = require "ops"})

prog(stack, scope)
for i=#stack, 1, -1 do print(stack[i]) end
