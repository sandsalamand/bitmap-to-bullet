[ENABLE]
alloc(bulletSpawn,128,DarkSoulsIII.exe)
registersymbol(bulletSpawn)
globalalloc(BulletData,512)
define(BulletSpawnCall,DarkSoulsIII.exe+978500)
registersymbol(BulletSpawnCall)
define(PlayerHandle,BulletData+0)
registersymbol(PlayerHandle)
define(BulletID,BulletData+10)
registersymbol(BulletID)
define(TurretFlag,BulletData+18)
registersymbol(TurretFlag)
define(Homing,BulletData+1C)
registersymbol(Homing)
define(IsServerSide,BulletData+3C)
registersymbol(IsServerSide)
define(BCoordX,BulletData+4C)
registersymbol(BCoordX)
define(BCoordY,BulletData+5C)
registersymbol(BCoordY)
define(BCoordZ,BulletData+6C)
registersymbol(BCoordZ)
define(BAngleX,BulletData+48)
registersymbol(BAngleX)
define(BAngleY,BulletData+58)
registersymbol(BAngleY)
define(BAngleZ,BulletData+68)
registersymbol(BAngleZ)
IsServerSide:
 dd 000000009

PlayerHandle:
 dd 10068000

bulletSpawn:
 mov   rcx, [DarkSoulsIII.exe+4772D78]
 lea   r8,  [BulletData]
 sub   rsp, 198
 lea   rdx, [rsp+30]
 call  BulletSpawnCall
 add   rsp, 198
 ret

[DISABLE]
dealloc(bulletSpawn)
unregistersymbol(bulletSpawn)
unregistersymbol(BulletSpawnCall)
unregistersymbol(PlayerHandle)
unregistersymbol(Homing)
unregistersymbol(BulletID)
unregistersymbol(TurretFlag)
unregistersymbol(IsServerSide)
unregistersymbol(BAngleX)
unregistersymbol(BCoordX)
unregistersymbol(BAngleY)
unregistersymbol(BCoordY)
unregistersymbol(BAngleZ)
unregistersymbol(BCoordZ)