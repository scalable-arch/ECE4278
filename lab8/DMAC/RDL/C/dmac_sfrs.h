#include <stdint.h>		// included for uint32_t, int32_t, ...etc
#include "../OUTPUT/DMAC_CFG.h"

// Use function-like macros with text replacements
// 
#define DMAC_BASE_ADDR 0x3F000000

#define REG_READ(name) \
	(*((volatile uint32_t *)(DMAC_BASE_ADDR + DMAC_CFG_##name##_ADDRESS)))

#define REG_WRITE(name, value) \
	*((volatile uint32_t *)(DMAC_BASE_ADDR + DMAC_CFG_##name##_ADDRESS)) = value
