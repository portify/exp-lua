local EMPTY_LIST = {}
local push = table.insert

local function top(t)
  assert(#t >= 1, "empty stack")
  return t[#t]
end

local function pop(t)
  assert(#t >= 1, "empty stack")
  return table.remove(t)
end

return {
  get = function(stack, scope)
    push(stack, scope[pop(stack)])
  end,
  set = function(stack, scope)
    local name = pop(stack)
    local value = pop(stack)
    scope[name] = value
  end,
  call = function(stack, scope)
    pop(stack)(stack, scope)
  end,

  -- stack manipulation
  copy = function(stack)
    push(stack, top(stack))
  end,
  swap = function(stack)
    local t1 = pop(stack)
    local t2 = pop(stack)
    push(stack, t1)
    push(stack, t2)
  end,

  -- list manipulation
  ["[]"] = function(stack) push(stack, EMPTY_LIST) end,
  [":"] = function(stack)
    local value = pop(stack)
    local list = pop(stack)
    push(stack, function() return value, list end)
  end,
  head = function(stack) push(stack, select(1, pop(stack)())) end,
  tail = function(stack) push(stack, select(2, pop(stack)())) end,
  each = function(stack, scope)
    local func = pop(stack)
    local list = pop(stack)

    while list ~= EMPTY_LIST do
      local value
      value, list = list()
      push(stack, value)
      func(stack, scope)
    end
  end,
  map = function(stack, scope)
    local func = pop(stack)

    local function mapper(a)
      if a == EMPTY_LIST then return EMPTY_LIST end
      return function()
        local x, xs = a()
        push(stack, x)
        func(stack, scope)
        return pop(stack), mapper(xs)
      end
    end

    push(stack, mapper(pop(stack)))
  end,
  tonumber = function(stack)
    push(stack, tonumber(pop(stack)))
  end,

  -- io
  ["in"] = function(stack) push(stack, io.read()) end,
  out = function(stack) print(pop(stack)) end,

  -- math
  ["+"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs + rhs)
  end,
  ["-"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs - rhs)
  end,
  ["*"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs * rhs)
  end,
  ["/"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs / rhs)
  end,
  ["^"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs ^ rhs)
  end,
  ["%"] = function(stack)
    local rhs = pop(stack)
    local lhs = pop(stack)
    push(stack, lhs % rhs)
  end
}
