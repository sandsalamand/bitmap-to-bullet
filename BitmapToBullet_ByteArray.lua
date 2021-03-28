[ENABLE]
{$lua}
if syntaxcheck then return end

--==========OPTIONS==========
local overloadTable = nil --12453000 black flame
local spawnTable = {[0]= 12453000,[1]= 13530000,[2]= 13530000,[3]= 13530000,[4]= 13530000,[5]= 13530000,[6]= 13530000,[7]= 13530000,[8]= 13530000,[9]= 111,[10]= 13530000,[11]= 13530000,[12]= 70,[13]= 13530000,[14]= 13530000,[15]= 0}
--0:black, 1:130, 2:130, 3:130, 4:130, 5:130, 6:130, 7:130, 8:130, 9:red, 10:130, 11:blue, 12:130, 13:130, 14:130, 15:white?
--4bpp bitmap colors ^, recommended that 15 be 0 since Paint makes bg white
local gapBetweenBullets = 0.3


local playerXPtr = "[[[BaseB]+40]+28]+80"
local playerYPtr = "[[[BaseB]+40]+28]+84"
local playerZPtr = "[[[BaseB]+40]+28]+88"

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
  if (byteArray[1] ~= 66) then -- if that doesnt work, try 0x4D for hex
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

local function LoadPixelArray(byteArray, bmpHeight, bmpWidth)
  local pixelArray = {}
  local widthInBytes = math.ceil(bmpWidth/2)
  local dwordOffset = 4 - (widthInBytes%4)
  local byteTracker = GetPixelArrayOffset(byteArray)
  local numOffset = byteTracker
  for yIndex = 1, bmpHeight, 1 do
    local row = {}
    for xIndex = 1, widthInBytes, 1 do
      twoPixels = byteArray[byteTracker + 1]
      --print("yIndex = ", yIndex, "byteTracker = ", byteTracker)
      byteTracker = byteTracker + 1
      firstPixel = bAnd(twoPixels, 0xF) -- 0F
      --print(firstPixel)
      secondPixel = bAnd(bShr(twoPixels, 4), 0xF)
      --print(secondPixel)
      --print(xIndex, ": ", row[xIndex])
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
local function SpawnPixelArray(pixelArray, dimensions, xOffset, yOffset, zOffset) -- need to add support for angles later, this will always print along the x-y axis and never use z
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
    --print("y = ", yIndex, "x = ", xIndex)
      if overloadTable ~= nil then
      	if spawnTable[pixelArray[yIndex][xIndex]] ~= 0 then
        	LaunchB(botLeftCorner, overloadTable, 0, 0, 0)
        end
      else
		--print (pixelArray[yIndex][xIndex])
        LaunchB(botLeftCorner, spawnTable[pixelArray[yIndex][xIndex]], 0, 0, 0) -- might need to swap x and y, idk how lua nested table accessing works
      end
      botLeftCorner.x = botLeftCorner.x + gapBetweenBullets
    end
    botLeftCorner.y = botLeftCorner.y + gapBetweenBullets
    botLeftCorner.x = leftSide
  end
end

function SpawnBitmap(bitmapName, x, y, z)
  local byteArray = GetByteArray(bitmapName)
  if byteArray == nil then print("byte array nil") return end
  local dimensions = GetBmpDimensions(byteArray)
  local bmpHeight = dimensions["height"]
  local bmpWidth = dimensions["width"]
  local pixelArray = LoadPixelArray(byteArray, bmpHeight, bmpWidth)
  SpawnPixelArray(pixelArray, dimensions, x, y, z)
end

[DISABLE]
{$lua}
if syntaxcheck then return end