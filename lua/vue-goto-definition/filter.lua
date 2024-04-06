local Log = require("vue-goto-definition").Log
local sf = require("vue-goto-definition.utils").string_format

---@class Filter
---@field items fun(items: DefinitionItems, opts: table):table
---@return Filter
local M = {}

local function dedupe_filenames(items)
	local seen = {}
	local filtered = {}
	for _, item in ipairs(items) do
		if not seen[item.filename] then
			table.insert(filtered, item)
			seen[item.filename] = true
		end
	end
	if #filtered == 0 then
		Log.debug([[filter._dedupe_filenames: filtered list is empty: returning original items]])
		return items
	end
	if #filtered ~= #items then
		Log.debug(sf([[filter._dedupe_filenames: found %s items after deduping filenames]], #filtered))
	end
	return filtered
end

local function same_filename(items)
	--  TODO: 2024-04-06 - Remove definitions with filename and lnum as
	--  current file and line number
	--  TODO: 2024-04-06 - Dedupe definitions that are duplicate filename and lnum
	return items
end

local function apply_filters(items, opts)
	local filtered = vim.tbl_filter(function(item)
		local is_auto_import = opts.filters.auto_imports and item.filename:match(opts.patterns.auto_imports)
		local is_component = opts.filters.auto_components and item.filename:match(opts.patterns.auto_components)
		local is_same_file = opts.filters.same_file and item.filename == vim.fn.expand("%:p")
		return not is_auto_import and not is_component and not is_same_file
	end, items or {})
	if #filtered == 0 then
		Log.debug([[filter._apply_filters: filtered list is empty: returning original items]])
		return items
	end
	if #filtered ~= #items then
		Log.debug(sf([[filter._apply_filters: found %s items after applying filters]], #filtered))
	end
	return filtered
end

local function remove_declarations(items, opts)
	local filtered = vim.tbl_filter(function(item)
		return not item.filename:match(opts.patterns.declaration)
	end, items)
	if #filtered == 0 then
		Log.debug([[filter._remove_declarations: filtered list is empty: returning original items]])
		return items
	end
	if #filtered ~= #items then
		Log.debug(sf([[filter._remove_declarations: found %s items after declaration filter]], #filtered))
	end
	return filtered
end

function M.items(items, opts)
	items = same_filename(items)
	if opts.filters.duplicate_filename then
		items = dedupe_filenames(items)
	end
	Log.debug(sf(
		[[filter.items: filtering %s items:

  %s
  ]],
		#items,
		items
	))
	items = apply_filters(items, opts)
	if #items < 2 then
		return items
	end
	if opts.filters.declaration then
		items = remove_declarations(items, opts)
	end
	Log.debug(sf(
		[[filter.items: returning %s filtered items:

  %s
  ]],
		#items,
		items
	))
	return items
end

return M
