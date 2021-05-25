[ENABLE]
{$lua}
if syntaxcheck then return end

--Colors set to 0 will not be spawned
--the number on the right is the bulletId spawned for that color

myColorTable = {
[0]= 12453000,		--black
[1]= 13530000,
[2]= 13530000,
[3]= 13530000,
[4]= 13530000,
[5]= 13530000,
[6]= 13530000,
[7]= 13530000,
[8]= 13530000,
[9]= 111,			--red
[10]= 13530000,
[11]= 13530000,		--?
[12]= 70,			--blue
[13]= 13530000,
[14]= 13530000,
[15]= 0				--recommended that color 15 be 0 since Paint makes bg white
}

[DISABLE]
{$lua}
if syntaxcheck then return end