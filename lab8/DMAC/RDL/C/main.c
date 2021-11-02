#include <stdio.h>
#include "dmac_sfrs.h"

int main()
{
	int data;
	
	data = REG_READ(DMA_VER);
	REG_WRITE(DMA_VER, data);

	printf("%x\n", data);
}
