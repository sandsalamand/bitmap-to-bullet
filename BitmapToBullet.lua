[ENABLE]
{$lua}
if syntaxcheck then return end

local bitmapPath = [[C:\Users\sands\Desktop\20by20.bmp]]
local spawnTable = {130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 0, 0}
local gapBetweenBullets = 1

local pixelByteSize = 4
local playerXPtr = "[[[BaseB]+40]+28]+80"
local playerYPtr = "[[[BaseB]+40]+28]+84"
local playerZPtr = "[[[BaseB]+40]+28]+88"

function file_exists(fileName)
  local f = io.open(fileName, "rb")
  if f then f:close() end --could be made more efficient by returning file descriptor to parse_file
  return f ~= nil
end

function GetFileDescriptor(filename, flags)
  if not (file_exists(filename)) then return nil end
  local fileDescriptor = assert(io.open (inputPath, flags), "failed to open input file")
  return fileDescriptor
end

Point = {}
Point.__index = Point

function Point:Create(xPtr, yPtr, zPtr)
   local pnt = {}             -- new object
   setmetatable(pnt, Point)  -- make Account handle lookup
   pnt.xPtr = xPtr
   pnt.yPtr = yPtr
   pnt.zPtr = zPtr
   pnt.x = readFloat(xPtr)
   pnt.y = readFloat(yPtr)
   pnt.z = readFloat(zPtr)
   if (pnt.x == nil or pnt.y == nil or pnt.z == nil) then return nil end
   return pnt
end

function Point:CreateNoPtrs(x, y, z)
   local pnt = {}             -- new object
   setmetatable(pnt, Point)  -- make Account handle lookup
   pnt.xPtr = nil
   pnt.yPtr = nil
   pnt.zPtr = nil
   pnt.x = x
   pnt.y = y
   pnt.z = z
   if (pnt.x == nil or pnt.y == nil or pnt.z == nil) then return nil end
   return pnt
end

function Point:Update()
   self.x = readFloat(self.xPtr)
   self.y = readFloat(self.yPtr)
   self.z = readFloat(self.zPtr)
end

local function LaunchB(point, bID, bAngX, bAngY, bAngZ)
	writeFloat("BCoordX", point.x)
	writeFloat("BCoordY", point.y)
	writeFloat("BCoordZ", point.z)
    writeInteger("BulletID", bID)
    writeFloat("BAngleX", bAngX)
    writeFloat("BAngleY", bAngY)
	writeFloat("BAngleZ", bAngZ)
    autoAssemble("createThread(bulletSpawn)")
end

playerPoint = Point:Create(playerXPtr, playerYPtr, playerZPtr)

local function GetPixelArrayOffset(handle) --file descriptor
	local firstByte = handle:read(2) -- first 2 bytes are file type
    if (firstByte != 42) then -- if that doesnt work, try 0x4D for hex
    	print("You tried to use a file that's not a bitmap!")
        return nil
	end
    handle:seek(10)
	local offset = handle:read(4) -- 10th byte contains 4-byte offset of pixel array
	return offset
end

local function GetBmpDimensions(handle)
  handle:seek(18) -- 18, or 12 in hex, is width
  local bmpWidth = handle:read(4)
  handle:seek(22) -- 16 in hex
  local bmpHeight = handle:read(4)
  
  local dimensions = {["width"] = bmpWidth, ["height"] = bmpHeight}
  return dimensions
end

local function LoadPixelArray(offset, handle)
  handle:seek(offset)
  local i = 0
  local PixelArray = {}
  local row = {}
  for (yIndex = 0, bmpHeight, 1) do
    for (xIndex = 0, bmpWidth, 1) do
      twoPixels = handle:read(1)
      handle:seek(offset + i)
      i++
      firstPixel = bit32.band(twoPixels, 15) -- 0F
      secondPixel = bit32.band(bit32.arshift(twoPixels, 4), 15)
      row[xIndex] = firstPixel -- need to convert binary pixel to integer first??
      xIndex += 1
      row[xIndex] = secondPixel -- ^
    end
    PixelArray[yIndex] = row
  end
  return PixelArray
end

--The 4-bits per pixel (4bpp) format supports 16 distinct colors and stores
--2 pixels per 1 byte, the left-most pixel being in the more significant nibble.
--Each pixel value is a 4-bit index into a table of up to 16 colors.
local function SpawnPixelArray(handle, bitmapHeight, bitmapWidth, xOffset, yOffset, zOffset) -- need to add support for angles later, this will always print along the x-y axis and never use z
  local spawnPoint = Point:Create(playerXPtr, playerYPtr, playerZPtr)
  spawnPoint.x += xOffset
  spawnPoint.y += yOffset
  spawnPoint.z += zOffset
  local botLeftCorner = Point:CreateNoPtrs(0, 0, spawnPoint.z)
  botLeftCorner.x = spawnPoint.x - bmpWidth/2 
  botLeftCorner.y = spawnPoint.y - bmpHeight/2
  for (yIndex = 0, bmpHeight, 1) do
    for (xIndex = 0, bmpWidth, 1) do
      bulletToLaunch = spawnTable[pixelArray[xIndex][yIndex]] -- might need to swap x and y, idk how lua nested table accessing works
      if bulletToLaunch ~= 0 then LaunchB(botLeftCorner, bulletToLaunch, 0, 0, 0) end
      botLeftCorner.x += gapBetweenBullets
    end
    botLeftCorner.y += gapBetweenBullets
  end
end

--[[local function AdvanceFilePointer(handle)
	handle:seek("cur", pixelByteSize) --advances the file by 4 (bytes I assume?)
end]]

local function MainLoop()

end

local bitmapFd = GetFileDescriptor(bitmapPath, rb) -- might need to make global if it's not visible in MainLoop
if bitmapFd == nil then return end
local dimensions = GetBmpDimensions(bitmapFd)
bmpHeight = dimensions["height"] -- try to make these local
bmpWidth = dimensions["width"]
SpawnPixelArray(bitmapFd, bmpHeight, bmpWidth, 0, 0, 0)
--bitmapFd:seek(GetPixelArrayOffset(bitmapFd)) -- sets the file pointer to start of pixel array

--[[spawnTimer = createTimer(getMainForm())
spawnTimer.Interval = 500
spawnTimer.OnTimer = MainLoop
spawnTimer.setEnabled(true)]]

[DISABLE]
{$lua}
if syntaxcheck then return end
if spawnTimer ~= nil then
  spawnTimer.setEnabled(false)
end