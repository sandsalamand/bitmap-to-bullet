[ENABLE]
{$lua}
if syntaxcheck then return end

local bitmapName = "bmp.bmp"
local spawnOffset = {["x"] = 0, ["y"] = 5, ["z"] = 10}
local overloadTable = 130
local spawnTable = {[0]= 13530000,[1]= 13530000,[2]= 13530000,[3]= 13530000,[4]= 13530000,[5]= 13530000,[6]= 13530000,[7]= 13530000,[8]= 0,[9]= 13530000,[10]= 13530000,[11]= 13530000,[12]= 13530000,[13]= 13530000,[14]= 13530000,[15]= 13530000}
--0:black, 1:130, 2:130, 3:130, 4:130, 5:130, 6:130, 7:130, 8:white, 9:130, 10:130, 11:130, 12:130, 13:130, 14:130, 15:0
--4bpp bitmap colors ^, recommended that 8 be 0 since Paint makes bg white
local gapBetweenBullets = 0.5

local playerXPtr = "[[[BaseB]+40]+28]+80"
local playerYPtr = "[[[BaseB]+40]+28]+84"
local playerZPtr = "[[[BaseB]+40]+28]+88"

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
  return pnt
end

function Point:Update()
  self.x = readFloat(self.xPtr)
  self.y = readFloat(self.yPtr)
  self.z = readFloat(self.zPtr)
end

local function GetByteStream(bitmap)
  local fileStr = nil
  local tableFile = findTableFile(bitmap)
  if tableFile == nil then return nil end
  local byteStream = createMemoryStream()
  byteStream.Position = 0
  byteStream.copyFrom(tableFile.Stream, tableFile.Stream.Size)
  byteStream.Position = 0
  local firstByte = byteStream.read(1)
  if (firstByte[1] ~= 66) then -- if that doesnt work, try 0x4D for hex
    print("You tried to use a file that's not a bitmap!")
    return nil
  end
  return byteStream
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

local function GetPixelArrayOffset(byteStream)
  byteStream.Position = 10
  local offset = byteTableToDword(byteStream.read(4))
  --find a way to concat the byte array into one binary variable
  return offset
end

local function GetBmpDimensions(byteStream)
  local dimensions = {["width"] = 0, ["height"] = 0}
  byteStream.Position = 18 -- 12 in hex
  dimensions["width"] = byteTableToDword(byteStream.read(4))
  byteStream.Position = 22 -- 16 in hex
  dimensions["height"] = byteTableToDword(byteStream.read(4))

  return dimensions
end

local function LoadPixelArray(offset, byteStream, bmpHeight, bmpWidth)
  local numOffset = offset
  local i = 0
  local pixelArray = {}
  local row = {}
  byteStream.Position = numOffset
  for yIndex = 0, bmpHeight, 1 do
    for xIndex = 0, bmpWidth, 1 do
      twoPixels = byteStream.read(1)
      byteStream.Position = numOffset + i
      i = i + 1
      firstPixel = bAnd(twoPixels[1], 0xF) -- 0F
      secondPixel = bAnd(bShr(twoPixels[1], 4), 0xF)
      row[xIndex] = firstPixel -- need to convert binary pixel to integer first?
      xIndex = xIndex + 1
      row[xIndex] = secondPixel -- ^
    end
    pixelArray[yIndex] = row
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
  local leftSide = spawnPoint.x - (bmpWidth/2)
  botLeftCorner.x = leftSide
  botLeftCorner.y = spawnPoint.y - (bmpHeight/2)
  for yIndex = 0, bmpHeight, 1 do
    for xIndex = 0, bmpWidth, 1 do
      print(pixelArray[xIndex][yIndex])
      if overloadTable ~= nil then
      	if spawnTable[pixelArray[xIndex][yIndex]] == 0 then bulletToLaunch = nil
        else bulletToLaunch = overloadTable
        end
      else bulletToLaunch = spawnTable[pixelArray[xIndex][yIndex]] -- might need to swap x and y, idk how lua nested table accessing works
	  end
      if bulletToLaunch ~= nil then LaunchB(botLeftCorner, bulletToLaunch, 0, 0, 0) end
      botLeftCorner.x = botLeftCorner.x + gapBetweenBullets
    end
    botLeftCorner.y = botLeftCorner.y + gapBetweenBullets
    botLeftCorner.x = leftSide
  end
end

local function SpawnFromFile(bitmapName)
  local byteStream = GetByteStream(bitmapName)
  if byteStream == nil then return end
  local dimensions = GetBmpDimensions(byteStream)
  local bmpHeight = dimensions["height"]
  local bmpWidth = dimensions["width"]
  local pixelArray = LoadPixelArray(GetPixelArrayOffset(byteStream), byteStream, bmpHeight, bmpWidth)
  SpawnPixelArray(pixelArray, dimensions, spawnOffset["x"], spawnOffset["y"], spawnOffset["z"])
  byteStream.destroy()
end

SpawnFromFile(bitmapName)

[DISABLE]
{$lua}
if syntaxcheck then return end