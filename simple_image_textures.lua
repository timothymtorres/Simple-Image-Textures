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
SIT.image_sheets  = {}

--------------------------------------------------------------------------------
-- Creates an image sheet from a TexturePack/Tiled tileset and returns it
--
-- @param tileset The object which contains information about tileset.
-- @return The newly created image sheet.
--------------------------------------------------------------------------------   
local function createImageSheet( tileset )

	local options, name

	if tileset.image then -- Tiled tileset

		local tsiw,   tsih    = tileset.image_width, tileset.image_height
		local margin, spacing = tileset.margin,     tileset.spacing
		local w,      h       = tileset.tilewidth,  tileset.tileheight

		name = tileset.image
		options = {
			frames             = {},
			sheetContentWidth  = tsiw,
			sheetContentHeight = tsih,
		}

		local frames = options.frames
		local tileset_height    = tileset.tilecount / tileset.columns 
		local tileset_width     = tileset.columns 

		for j=1, tileset_height do

		  for i=1, tileset_width do

		    local element = {
				x      = ( i - 1 ) * ( w + spacing ) + margin,
				y      = ( j - 1 ) *( h + spacing ) + margin,
				width  = w,
				height = h,
		    }

		    frames[#frames + 1] = element

		  end

		end

	elseif tileset.sheet then -- TexturePacker tileset

		options = tileset:getSheet()

	end

	local directory = tileset.directory .. ( name or '' ) 
	return graphics.newImageSheet( directory, options )

end

--------------------------------------------------------------------------------
-- Returns an image sheet or nil
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param id The GID or image_name to find the image sheet.
-- @return The image sheet or nil.
-- @return The frame_index for image in image sheet.
--------------------------------------------------------------------------------   
local function getImageSheet( image_sheets, id )
 
	local image_sheet = image_sheets[id]
	if image_sheet then return image_sheet.sheet, image_sheet.frame end

end

--------------------------------------------------------------------------------
-- Returns width and height values for an image
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param id The id of the image.
-- @return The image width and height
--------------------------------------------------------------------------------   
local function getImageSize( images, id ) 

	local image = images[id]
	if image then return image.width, image.height end

end

--------------------------------------------------------------------------------
-- Returns directory path for an image
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param id The id of the image.
-- @return The image directory
--------------------------------------------------------------------------------   
local function getImagePath( images, id ) 

	local image = images[id]
	if image then return image.path end

end

--------------------------------------------------------------------------------
--- Gets a Tile image from a GID.
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param id The gid to use to find tileset.
-- @return The tileset at the gid location.
--------------------------------------------------------------------------------
local function getTileset( tilesets, id ) return tilesets[id] end

--------------------------------------------------------------------------------
-- Creates image sheet and loads it into the cache
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param texture_pack The sprites from a texture_pack file.
-------------------------------------------------------------------------------- 
local function cacheTexturePack( cache, texture_pack )

	local sheet = createImageSheet( texture_pack )

	for image_name, i in pairs(texture_pack.frameIndex) do

		assert( not cache.texture_packs[texture_name],
				"Duplicate key in cache detected" 
		)

		local image = texture_pack.sheet.frames[i]

		cache.texture_packs[image_name] = {
			sheet = sheet,
			frame = i,
			width = image.width,
			height = image.height,
		}

	end

end

--------------------------------------------------------------------------------
-- Returns the name of an image file that matches a name
--
-- @param directory A directory to scan for the image
-- @param name The name of the image file to look for
-- @return The image file name
-------------------------------------------------------------------------------- 
function getMatchingImage( directory, name )

	for image in lfs.dir( directory ) do

		-- Pattern captures the name and exension of a file
		local image_name, extension = image:match("(.*)%.(.+)$")
		if image_name == name and extension ~= 'lua' then return image end

	end

end

--------------------------------------------------------------------------------
-- Creates and loads Texturepacker tilesets from directory
--
-- @param cache A table that stores GID, image_names, tileset_names for lookup 
-- @param directory A directory to scan for texturepacker lua files
-------------------------------------------------------------------------------- 
local function loadTexturePacker( cache, directory )

    local path = system.pathForFile( directory, system.ResourceDirectory ) 

	for file in lfs.dir( path ) do

		-- This pattern captures the name and extension of a file string
		local file_name, extension = file:match("(.*)%.(.+)$")
		local is_lua_file = file ~= '.' and file ~= '..' and extension == 'lua'

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

				local image_file_name = getMatchingImage( path, file_name )

				texture_pack.directory = directory .. '/' .. image_file_name

				cacheTexturePack( cache, texture_pack )

			end

		end

	end

end

--------------------------------------------------------------------------------
--- Create object and add it to a layer
-- @param object The object that will be inserted
--------------------------------------------------------------------------------
local function createObject( object )

    local image

	elseif object.texture then

		local image_sheet, frame = getImageSheet( map.cache.texture_packs, 
												  object.texture )

		local width, height = getImageSize( map.cache.texture_packs, 
											object.texture )

		image = display.newImageRect( layer, image_sheet, frame, width, height )
		image.x, image.y = object.x, object.y

	return image

end


-- -------------------------------------------------------------------------- --
--                                  PUBLIC METHODS                            --	
-- -------------------------------------------------------------------------- --

--------------------------------------------------------------------------------
-- Creates a table to load texturepacker images in.
--
-- @param texturepacker_dir The path to texturepacker images.
-- @return The table for loaded textures
--------------------------------------------------------------------------------

function SIT.new(texturepacker_dir)

	loadTexturePacker(texturepacker_dir)
	
	return SIT
end

--------------------------------------------------------------------------------
--- Add texturepacker sprite to a layer in the map
-- @param layer The map layer sprite will be placed in
-- @param image_name The name of image that will be used
-- @param x The x position to put image at
-- @param y The y position to put image at
-- @return A display object created from texturepacker image
--------------------------------------------------------------------------------
function Map:addSprite( layer, image_name, x, y )

	layer = map:getLayer( layer )

	local object = {
		texture = image_name,
		x = x,
		y = y 
	}

	return createObject( self, object, layer )

end

--------------------------------------------------------------------------------
--- Create and load texture packer image sheet
-- @param image_path The file path to the image
-- @param lua_path The file path to the lua file
--------------------------------------------------------------------------------
function Map:addTexturePack( image_path, lua_path )

	-- Check if image exists at path and crashes if it doesn't
	assert( system.pathForFile( image_path, system.ResourceDirectory), 
			'Texture packer image file does not exist at "'.. image_path 
			.. '"' )

	-- Captures directory and name from image_path
	local image_directory, image_name = image_path:match("(.*/)(.*%..+)$")

	-- Removes the .lua extension (if present) for lua_path
	lua_path = lua_path:match("(.*)%..+$") or lua_path

	-- Replace slashes with periods in require path else file won't load
	local lua_module = lua_path:gsub("[/\]", ".")
	local texture_pack = require(lua_module)

	if texture_pack then

		texture_pack.directory = image_directory .. image_name
		cacheTexturePack( self.cache, texture_pack )

	end

end

return SIT