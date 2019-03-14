--------------------------------------------------------------------------------
-- @module  Simple Image Textures
-- @author Timothy Torres
-- @license MIT
-- @copyright Timothy Torres, March-2019
-- -------------------------------------------------------------------------- --
--                                  MODULE                                    --												
-- -------------------------------------------------------------------------- --
local lfs  = require 'lfs'  -- lfs stands for LuaFileSystem
local SIT = {}
SIT.texture_packs = {}

--------------------------------------------------------------------------------
--- Creates image sheet and texture data then loads it into SIT
-- @param texture_pack The sprites from a texture_pack file.
-------------------------------------------------------------------------------- 
local function loadTexturePack(texture_pack)
	local options = texture_pack:getSheet()
	local directory = texture_pack.directory
	local image_sheet = graphics.newImageSheet(directory, options)

	for image_name, i in pairs(texture_pack.frameIndex) do
		assert(not SIT.texture_packs[texture_name],
				"Duplicate texture image name detected")
		
		local image = texture_pack.sheet.frames[i]
		SIT.texture_packs[image_name] = {
			image_sheet = image_sheet,
			frame = i,
			width = image.width,
			height = image.height,
		}
	end
end

--------------------------------------------------------------------------------
--- Returns the name of an image file that matches a name
-- @param directory A directory to scan for the image
-- @param name The name of the image file to look for
-- @return The image file name
-------------------------------------------------------------------------------- 
function getMatchingImage(directory, name)
	for image in lfs.dir(directory) do
		-- Pattern captures the name and exension of a file
		local image_name, extension = image:match("(.*)%.(.+)$")
		if image_name == name and extension ~= 'lua' then return image end
	end

	local msg = 'Texture packer image file '..name..' does not exist inside '..
		        'directory "'..directory.. '"'
	assert(false, msg)
end

--------------------------------------------------------------------------------
--- Loads TexturePacker images into a table for easy use
-- @param directory The directory to texturepacker images.
--------------------------------------------------------------------------------
function SIT.new(directory)
    local path = system.pathForFile(directory, system.ResourceDirectory) 

	for file in lfs.dir(path) do
		-- This pattern captures the name and extension of a file string
		local file_name, extension = file:match("(.*)%.(.+)$")
		local is_lua_file = file ~= '.' and file ~= '..' and extension == 'lua'

		local attr = lfs.attributes(path..'/'..file)
		local is_directory = file ~= '.' and file ~= '..' and attr.mode == 'directory'

		if is_lua_file then
		    local require_path = directory .. '.' .. file_name
		    -- Replace slashes with periods in require path else file won't load
			lua_path = require_path:gsub("[/\]", ".")
			-- Using pcall to prevent any require() lua modules from crashing
			local is_code_safe, texture_pack = pcall(require, lua_path)
			local is_texturepacker_data = is_code_safe and  
										  type(texture_pack) == 'table' and
										  texture_pack.sheet 

			if is_texturepacker_data then
				local image_name = getMatchingImage(path, file_name)
				--local image_path = directory .. '/' .. image_name
				texture_pack.directory = directory .. '/' .. image_name
				loadTexturePack(texture_pack)
			end
		elseif is_directory then  -- search sub-directories
			SIT.new(directory .. '/' .. file)
		end
	end
end

--------------------------------------------------------------------------------
--- Retrieves texture information from SIT
-- @param name The texture data to retrieve
-- @return Image sheet, frame, width, and height for texture
--------------------------------------------------------------------------------
function SIT.getTexture(name)
	local texture = SIT.texture_packs[name]
	return texture.image_sheet, texture.frame, texture.width, texture.height
end

return SIT