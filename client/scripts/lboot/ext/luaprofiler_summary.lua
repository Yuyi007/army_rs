-- LuaProfiler
-- Copyright Kepler Project 2005-2007 (http://www.keplerproject.org/luaprofiler)
-- $Id: summary.lua,v 1.6 2009-03-16 15:55:32 alessandrohc Exp $

-- Function that reads one profile file
local function ReadProfile(file)

  local profile

  -- Check if argument is a file handle or a filename
  if io.type(file) == "file" then
    profile = file
  else
    -- Open profile
    profile = io.open(file)
  end

  -- Table for storing each profile's set of lines
  local line_buffer = {}

  -- Get all profile lines
  local i = 1
  for line in profile:lines() do
    line_buffer[i] = line
    i = i + 1
    end

  -- Close file
  profile:close()
  return line_buffer
end

-- Function that creates the summary info
local function CreateSummary(lines, summary)

  local global_time = 0

  -- Note: ignore first line
  for i = 2, table.getn(lines) do
    local stack_level, file, func, line = string.match(lines[i], "([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)")
    local local_time, total_time = string.match(lines[i], "[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t([^\t]+)\t([^\t]+)")
    local_time = string.gsub(local_time, ",", ".")
    total_time = string.gsub(total_time, ",", ".")

    if not (local_time and total_time) or
      (local_time == 'local_time' or total_time == 'total_time') then
      return global_time
    end

    local_time = tonumber(local_time)

    local word = string.format("%s:%s %s[%s]", file, line, func, stack_level)
    if summary[word] == nil then
      summary[word] = {};
      summary[word]["info"] = {}
      summary[word]["info"]["calls"] = 1
      summary[word]["info"]["total"] = local_time
      summary[word]["info"]["word"] = word
      summary[word]["info"]["file"] = file
      summary[word]["info"]["func"] = func
      summary[word]["info"]["stack_level"] = stack_level
    else
      summary[word]["info"]["calls"] = summary[word]["info"]["calls"] + 1
      summary[word]["info"]["total"] = summary[word]["info"]["total"] + local_time
    end

    global_time = global_time + local_time
  end

  return global_time
end

local function analyse(filename)
  -- Global time
  local global_t = 0

  -- Summary table
  local profile_info = {}

  -- Check file type
  local file = io.open(filename)
  if not file then
    print("File " .. filename .. " does not exist!")
    return nil
  end

  local firstline = file:read(11)

  -- File is single profile
  if firstline == "stack_level" then

    -- Single profile
    local lines = ReadProfile(file)
    global_t = CreateSummary(lines, profile_info)

  else

    -- File is list of profiles
    -- Reset position in file
    file:seek("set")

    -- Loop through profiles and create summary table
    for line in file:lines() do

      local profile_lines

      -- Read current profile
      profile_lines = ReadProfile(line)

      -- Build a table with profile info
      global_t = global_t + CreateSummary(profile_lines, profile_info)
    end

    file:close()
  end

  -- Sort table by total time
  local sorted = {}
  for k, v in pairs(profile_info) do table.insert(sorted, v) end
  table.sort(sorted, function (a, b)
    return tonumber(a["info"]["total"]) > tonumber(b["info"]["total"])
  end)

  return {
    sorted = sorted,
    global_t = global_t
  }
end

local function summary(filename, outfile, verbose)
  local result = analyse(filename)
  local sorted, global_t = result.sorted, result.global_t

  local ofile = io.open(outfile, 'w+')
  if not ofile then
    print("Output file " .. outfile .. " cannot be opened!")
    return nil
  end

  -- Output summary
  if verbose then
    ofile:write("Node name\tCalls\tAverage per call(ms)\tTotal time(ms)\t%Time\n")
  else
    ofile:write("Node name\tTotal time\n")
  end

  for k, v in pairs(sorted) do
    if v["info"]["func"] ~= "(null)" then
      local average = math.round(v["info"]["total"] / v["info"]["calls"] * 1000, 3)
      local total = math.round(v["info"]["total"] * 1000, 3)
      local percent = math.round(100 * v["info"]["total"] / global_t, 2)
      if verbose then
        ofile:write(v["info"]["word"] .. "\t" .. v["info"]["calls"] .. "\t"
          .. average .. "\t" .. total .. "\t" .. percent .. "\n")
      else
        ofile:write(v["info"]["word"] .. "\t" .. v["info"]["total"] .. "\n")
      end
    end
  end

  ofile:close()
end

return {
  summary = summary,
  analyse = analyse,
}