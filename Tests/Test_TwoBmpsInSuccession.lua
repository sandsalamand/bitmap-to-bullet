[ENABLE]
{$lua}
if syntaxcheck then return end

SpawnBitmap("twentybytwenty.bmp", 0, 0, 10)
sleep(1000)
SpawnBitmap("angryface.bmp", 0, 0, 10)

[DISABLE]
{$lua}
if syntaxcheck then return end
