#Simple Image Textures

*Simple Image Textures* (SIT) is a library used to quickly load image sheets into CoronaSDK with [TexturePacker]().  Instead of having to manually load each individual image sheet into a project, this library loads them all into a table for easy access.  Just point SIT to the directory(s) where the resources are located and it does all the heavy lifting.

I created SIT initially as a added feature for another library called [Berry]().  After the feature was added, I decided to also make it into a stand alone tool that other developers (hopefully) might find useful.

### Quick Start Guide

```lua
local SIT = require('simple_image_textures')
local resources = SIT.new(texturepacker_directory)
```

### texturePackerDirectory

There are several ways sprites can be loaded with SIT.

1.  Place the TexturePacker images and lua files inside the same directory as `texturepacker_directory` and it will load them automatically 
2.  Use `SIT.addTexturePack( image_path, lua_path )` to load each texture pack individually.

Method 1 assumes by default that the image file and the lua file have the same name.  (ex.  items.png and items.lua)  If the files are named differently from one another, then the textures will need to be loaded via method 2.  (ex.  items.png and weapons.lua) 

