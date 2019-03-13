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
--- Loads TexturePacker images into a table for easy use
-- @param texture_path The path to texturepacker images. (can be directory or 
-- image path)
-- @param lua_path (optional) The path to match a lua file to texturepack image
--------------------------------------------------------------------------------
function SIT.new(texture_path, lua_path)
	local attr = lfs.attributes(texture_path)
	if attr.mode == 'directory' then loadTextures(texture_path)
	elseif attr.mode == 'file' then loadTexturePack(texture_path, lua_path)
	end
end

--------------------------------------------------------------------------------
--- Retrieves texture information from SIT
-- @param texture_name The texture data to retrieve
-- @return Image sheet, frame, width, and height for texture
--------------------------------------------------------------------------------
function SIT.getTexture(texture_name)
	local texture = SIT.texture_packs[texture_name]
	return texture.image_sheet, texture.frame, texture.width, texture.height
end

--------------------------------------------------------------------------------
--- Creates a table to load texturepacker images in.
-- @param directory The path to texturepacker images.
--------------------------------------------------------------------------------
local function loadTextures(directory)
    local path = system.pathForFile(directory, system.ResourceDirectory) 

	for file in lfs.dir(path) do
		-- This pattern captures the name and extension of a file string
		local file_name, extension = file:match("(.*)%.(.+)$")
		local is_lua_file = file ~= '.' and file ~= '..' and extension == 'lua'

		local attr = lfs.attributes(file)

		if is_lua_file then
		    local require_path = directory .. '.' .. file_name
		    -- Replace slashes with periods in require path else file won't load
			local lua_module = require_path:gsub("[/\]", ".")
			-- Using pcall to prevent any require() lua modules from crashing
			local is_code_safe, texture_pack = pcall(require, lua_module)
			local is_texturepacker_data = is_code_safe and  
										  type(texture_pack) == 'table' and
										  texture_pack.sheet 

			if is_texturepacker_data then
				local image_file_name = getMatchingImage(path, file_name)
				texture_pack.directory = directory .. '/' .. image_file_name
				cacheTexturePack(texture_pack)
			end
		elseif attr.mode == 'directory' then  -- search sub-directories
			loadTextures(directory .. '/' .. file)
		end
	end
end

--------------------------------------------------------------------------------
--- Create and load texture packer image sheet
-- @param image_path The file path to the image
-- @param lua_path The file path to the lua file
--------------------------------------------------------------------------------
local function loadTexturePack(image_path, lua_path)
	-- Check if image exists at path and crashes if it doesn't
	assert(system.pathForFile(image_path, system.ResourceDirectory), 
			'Texture packer image file does not exist at "'.. image_path 
			.. '"')
	-- Captures directory and name from image_path
	local image_directory, image_name = image_path:match("(.*/)(.*%..+)$")
	-- Removes the .lua extension (if present) for lua_path
	lua_path = lua_path:match("(.*)%..+$") or lua_path
	-- Replace slashes with periods in require path else file won't load
	local lua_module = lua_path:gsub("[/\]", ".")
	local texture_pack = require(lua_module)
	if texture_pack then
		texture_pack.directory = image_directory .. image_name
		cacheTexturePack(texture_pack)
	end
end

--------------------------------------------------------------------------------
--- Creates image sheet and texture data then loads it into SIT
-- @param texture_pack The sprites from a texture_pack file.
-------------------------------------------------------------------------------- 
local function cacheTexturePack(texture_pack)
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

return SIT