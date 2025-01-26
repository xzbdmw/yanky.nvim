local utils = {}

function utils.get_default_register()
  local clipboard_flags = vim.split(vim.api.nvim_get_option_value("clipboard", {}), ",")
  local selected_register = '"'

  if vim.tbl_contains(clipboard_flags, "unnamedplus") then
    selected_register = "+"
  end

  if vim.tbl_contains(clipboard_flags, "unnamed") then
    selected_register = "*"
  end

  if selected_register ~= '"' then
    local clipboard_tool = vim.fn["provider#clipboard#Executable"]()
    if not clipboard_tool or "" == clipboard_tool then
      return '"'
    end
  end

  return selected_register
end

function utils.get_system_register()
  local clipboard_flags = vim.split(vim.api.nvim_get_option_value("clipboard", {}), ",")

  if vim.tbl_contains(clipboard_flags, "unnamedplus") then
    return "+"
  end
  return "*"
end

function utils.get_register_info(register)
  return {
    regcontents = vim.fn.getreg(register),
    regtype = vim.fn.getregtype(register),
  }
end

utils.compute_indent = function(lines)
  local res_indent, res_indent_width = nil, math.huge
  local blank_indent, blank_indent_width = nil, math.huge
  for _, l in ipairs(lines) do
    local cur_indent = l:match("^%s*")
    local cur_indent_width = cur_indent:len()
    local is_blank = cur_indent_width == l:len()
    if not is_blank and cur_indent_width < res_indent_width then
      res_indent, res_indent_width = cur_indent, cur_indent_width
    elseif is_blank and cur_indent_width < blank_indent_width then
      blank_indent, blank_indent_width = cur_indent, cur_indent_width
    end
  end
  return res_indent or blank_indent or ""
end

utils.update_indent = function(lines, new_indent)
  -- Replace current indent with new indent without affecting blank lines
  local n_cur_indent = utils.compute_indent(lines):len()
  return vim.tbl_map(function(l)
    if l:find("^%s*$") ~= nil then
      return l
    end
    return new_indent .. l:sub(n_cur_indent + 1)
  end, lines)
end

function utils.use_temporary_register(register, register_info, callback)
  if register_info.regtype == "V" then
    local s = vim.split(register_info.regcontents:gsub("\n$", ""), "\n")
    register_info.regcontents = utils.update_indent(s, vim.api.nvim_get_current_line():match("^(%s*)"))
  end
  local current_register_info = utils.get_register_info(register)
  vim.fn.setreg(register, register_info.regcontents, register_info.regtype)
  callback()
  vim.fn.setreg(register, current_register_info.regcontents, current_register_info.regtype)
end

return utils
