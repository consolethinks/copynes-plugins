path  = fd_GetPath();
f_dir = string.format("%s",path);

f_rom = f_dir.."\\M428.nes";
f_prom= f_dir.."\\M428.nes";
f_vrom= f_dir.."\\vrom.nes";
f_sram= f_dir.."\\sram.sav";

r = fd_WriteDir(f_dir);

vrom = 1;

map=428;
scr4=0;
batt=0;
vmir = 0;
vsys = 0;
prom = 128;
vrom = 64;
head = fd_GetNesHead(map,scr4,batt,vmir,vsys,prom,vrom)
os.remove(f_rom);
i = fd_WriteFile(f_rom,head,1);
print("write ines:"..i);



k=0;
k_max = prom/16;

fd_CpuWriteInt(0xA001,0x80);
fd_CpuWriteInt(0x8000,0x00);
fd_CpuWriteInt(0x8001,0x00);

while k<k_max
	do
		fd_CpuWriteInt(0x6001,k*32);
		crc,data  = fd_CpuReadAscii(0x8000,0x4000);
		info = string.format("CRC %.8X  %d%%",crc,(k*100)/k_max);
		print(info);
		i = fd_WriteFile(f_rom,data,1);
		k=k+1;
end;

k=0;
k_max = vrom/8;
while k<k_max
	do
		fd_CpuWriteInt(0x6001,k);
		crc,data  = fd_PpuReadAscii(0x0000,0x2000);
		info = string.format("CRC %.8X  %d%%",crc,(k*100)/k_max);
		print(info);
		i = fd_WriteFile(f_rom,data,1);
		k=k+1;
end;


