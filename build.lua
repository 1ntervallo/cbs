local action = ...

local platform = "linux" -- "linux" / "windows" / "mac"
local flags = "-C opt-level=2 -A dead_code" 
local libs = ""

local exec = os.execute
local popen = io.popen
local open = io.open
local insert = table.insert
local concat = table.concat
local fmt = string.format

if platform == "" then
    error("Please input a platform in the 3rd line of this file.")
end

if action == "test" then
    flags = flags .. " --test"
end

if platform == "linux" then
    exec("mkdir -p bin")
    
    local bf, err = open("build.ninja", "w")
    if not bf then error("Failed to create build.ninja: " .. tostring(err)) end

    local content = {
        "flags = " .. flags,
        "rule rustc",
        "  command = rustc $flags --emit=link,dep-info=$out.d $in -o $out",
        "  depfile = $out.d",
        "  deps = gcc",
	"  description = RUSTC $out",
    }

    local pipe = popen("find src -type f -name 'main.rs'")
    local root_file = nil
    
    if pipe then
        for path in pipe:lines() do
            if path:match("main%.rs$") then
                root_file = path
                break
            end
        end
        pipe:close()
    end

    local bin = fmt("bin/gnu-linux-%s", action)

    insert(content, fmt("build %s: rustc %s", bin, root_file))

    bf:write(concat(content, "\n") .. "\n")
    bf:close()
    
    local ok = exec("ninja")

    if (action == "test" or action == "run") and ok then
	exec("./" .. bin)
    end
end
