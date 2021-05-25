[ENABLE]
{$lua}
if syntaxcheck then return end

--==========OPTIONS==========
local overloadTable = nil --makes all bullets this color if not set to nil
local gapBetweenBullets = 0.3


local playerXPtr = "[[[144768E78]+40]+28]+80"
local playerYPtr = "[[[144768E78]+40]+28]+84"
local playerZPtr = "[[[144768E78]+40]+28]+88"

Point = {}
Point.__index = Point

function Point:Create(xPtr, yPtr, zPtr)
  local pnt = {}             -- new object
  setmetatable(pnt, Point)  -- make Point handle lookup
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
  local pnt = {}
  setmetatable(pnt, Point)
  pnt.xPtr = nil
  pnt.yPtr = nil
  pnt.zPtr = nil
  pnt.x = x
  pnt.y = y
  pnt.z = z
  return pnt
end

function Point:Update()
  self.x = readFloat(self.xPtr)
  self.y = readFloat(self.yPtr)
  self.z = readFloat(self.zPtr)
end

local function GetByteArray(bitmap)
  local fileStr = nil
  local tableFile = findTableFile(bitmap)
  if tableFile == nil then return nil end
  local byteStream = createMemoryStream()
  byteStream.Position = 0
  byteStream.copyFrom(tableFile.Stream, tableFile.Stream.Size)
  byteStream.Position = 0
  local byteArray = byteStream.read(tableFile.Stream.Size)
  byteStream.destroy()
  if (byteArray[1] ~= 66) then
    print("You tried to use a file that's not a bitmap!")
    return nil
  end
  return byteArray
end

local function LaunchB(point, bID, bAngX, bAngY, bAngZ)
	if (bID ~= 0) then
		writeFloat("BCoordX", point.x)
		writeFloat("BCoordY", point.y)
		writeFloat("BCoordZ", point.z)
  		writeInteger("BulletID", bID)
 		writeFloat("BAngleX", bAngX)
  		writeFloat("BAngleY", bAngY)
		writeFloat("BAngleZ", bAngZ)
  		autoAssemble("createThread(bulletSpawn)")
    end
end

local function GetDword(table, firstByte)
  local fourByte = {}
  for i = 0, 3, 1 do
    fourByte[i] = table[firstByte + i]
  end
  local dword = byteTableToDword(fourByte)
  return dword
end

local function GetPixelArrayOffset(byteArray)
  offset = GetDword(byteArray, 10)
  return offset
end

local function GetBmpDimensions(byteArray)
  local dimensions = {["width"] = 0, ["height"] = 0}
  dimensions["width"] = GetDword(byteArray, 18)
  dimensions["height"] = GetDword(byteArray, 22)
  return dimensions
end

local function LoadPixelArray(byteArray, dimensions)
  local pixelArray = {}
  local widthInBytes = math.ceil(dimensions["width"]/2)
  local dwordOffset = 4 - (widthInBytes%4)
  local byteTracker = GetPixelArrayOffset(byteArray)
  local numOffset = byteTracker
  for yIndex = 1, dimensions["height"], 1 do
    local row = {}
    for xIndex = 1, widthInBytes, 1 do
      twoPixels = byteArray[byteTracker + 1]
      byteTracker = byteTracker + 1
      firstPixel = bAnd(twoPixels, 0xF) -- 0F
      secondPixel = bAnd(bShr(twoPixels, 4), 0xF)
      table.insert(row, firstPixel)
      table.insert(row, secondPixel)
    end
    table.insert(pixelArray, row)
    row = nil
	byteTracker = byteTracker + dwordOffset
    -- ^ advances Position to end of DWORD
  end
  return pixelArray
end

--The 4-bits per pixel (4bpp) format supports 16 distinct colors and stores
--2 pixels per 1 byte, the left-most pixel being in the more significant nibble.
--Each pixel value is a 4-bit index into a table of up to 16 colors.
local function SpawnPixelArray(pixelArray, dimensions, xOffset, yOffset, zOffset, colorTable) -- need to add support for angles later, this will always print along the x-y axis and never use z
  local bmpHeight = dimensions["height"]
  local bmpWidth = dimensions["width"]
  local spawnPoint = Point:Create(playerXPtr, playerYPtr, playerZPtr)
  spawnPoint.x = spawnPoint.x + xOffset
  spawnPoint.y = spawnPoint.y + yOffset
  spawnPoint.z = spawnPoint.z + zOffset
  local botLeftCorner = Point:CreateNoPtrs(0, 0, spawnPoint.z)
  local leftSide = spawnPoint.x - (gapBetweenBullets * (bmpWidth/2))
  botLeftCorner.x = leftSide
  botLeftCorner.y = spawnPoint.y - (gapBetweenBullets * (bmpHeight/2))
  for yIndex = 1, bmpHeight, 1 do
    for xIndex = 1, bmpWidth, 1 do
      if overloadTable ~= nil then
      	if colorTable[pixelArray[yIndex][xIndex]] ~= 0 then
        	LaunchB(botLeftCorner, overloadTable, 0, 0, 0)
        end
      else
        LaunchB(botLeftCorner, colorTable[pixelArray[yIndex][xIndex]], 0, 0, 0)
      end
      botLeftCorner.x = botLeftCorner.x + gapBetweenBullets
    end
    botLeftCorner.y = botLeftCorner.y + gapBetweenBullets
    botLeftCorner.x = leftSide
  end
end

function SpawnBitmap(bitmapName, colorTable, x, y, z)
  local byteArray = GetByteArray(bitmapName)
  if byteArray == nil then print("byte array nil") return end
  local dimensions = GetBmpDimensions(byteArray)
  local pixelArray = LoadPixelArray(byteArray, dimensions)
  SpawnPixelArray(pixelArray, dimensions, x, y, z, colorTable)
end

[DISABLE]
{$lua}
if syntaxcheck then return end