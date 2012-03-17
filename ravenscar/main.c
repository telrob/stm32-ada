/* ---------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--------------------------------------------------------------------------- */

#include <stddef.h>
#include <stdint.h>
#include "stm32f4xx.h"

extern void SystemInit(void);
static inline uint32_t _RCC_GetClocksFreq();
static inline void _NVIC_PriorityGroupConfig(uint32_t NVIC_PriorityGroup);

void init_board() {
  SystemInit();
  _NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);


  /* Initialize LEDs and User_Button on STM32F4-Discovery --------------------*/
/*  STM_EVAL_PBInit(BUTTON_USER, BUTTON_MODE_EXTI); 

  STM_EVAL_LEDInit(LED4);
  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED5);
  STM_EVAL_LEDInit(LED6);

  STM_EVAL_LEDToggle((Led_TypeDef)0);*/
}

void setup_systick(int frequency) {
  SysTick_Config(_RCC_GetClocksFreq() / frequency);
  NVIC_SetPriority (PendSV_IRQn, (1<<__NVIC_PRIO_BITS) - 1);
}

int get_current_interrupt() {
  IPSR_Type ipsr;
  ipsr.w = __get_IPSR();
  return ipsr.b.ISR;
}

void context_switch() {
  *((uint32_t volatile *)0xE000ED04) = 0x10000000; // trigger PendSV
}

// Export some static inline function for Ada.
void _NVIC_EnableIRQ(IRQn_Type IRQn) {
  NVIC_EnableIRQ(IRQn - 16);
}

void _NVIC_DisableIRQ(IRQn_Type IRQn) {
  NVIC_DisableIRQ(IRQn - 16);
}

uint32_t _NVIC_GetPendingIRQ(IRQn_Type IRQn) {
  return NVIC_GetPendingIRQ(IRQn - 16);
}

void _NVIC_SetPendingIRQ(IRQn_Type IRQn) {
  NVIC_SetPendingIRQ(IRQn - 16);
}

void _NVIC_ClearPendingIRQ(IRQn_Type IRQn) {
    NVIC_ClearPendingIRQ(IRQn - 16);
}

uint32_t _NVIC_GetActive(IRQn_Type IRQn) {
    return NVIC_GetActive(IRQn - 16);
}

void _NVIC_SetPriority(IRQn_Type IRQn, uint32_t priority) {
    NVIC_SetPriority(IRQn - 16, 16 - priority);
}

uint32_t _NVIC_GetPriority(IRQn_Type IRQn) {
    return 16 - NVIC_GetPriority(IRQn - 16);
}

void data_abort_pc (void)
{
}

void data_abort_C (void)
{
}
/*
void __aeabi_unwind_cpp_pr0 (void)
{
  while (1) ;
}*/

extern void put_exception (unsigned int) __attribute__ ((weak));

void __attribute__ ((weak)) __gnat_last_chance_handler (void)
{
  unsigned int addr = (int) __builtin_return_address (0);

  if (put_exception != NULL)
    put_exception (addr);

  while (1)
    ;
}

// Adapted from "arti64.c"

long long int __gnat_mulv64 (long long int x, long long int y)
{
  unsigned neg = (x >= 0) ^ (y >= 0);
  long long unsigned xa = x >= 0 ? (long long unsigned) x
                                 : -(long long unsigned) x;
  long long unsigned ya = y >= 0 ? (long long unsigned) y
                                 : -(long long unsigned) y;
  unsigned xhi = (unsigned) (xa >> 32);
  unsigned yhi = (unsigned) (ya >> 32);
  unsigned xlo = (unsigned) xa;
  unsigned ylo = (unsigned) ya;
  long long unsigned mid
    = xhi ? (long long unsigned) xhi * (long long unsigned) ylo
         : (long long unsigned) yhi * (long long unsigned) xlo;
  long long unsigned low = (long long unsigned) xlo * (long long unsigned) ylo;

  if ((xhi && yhi) ||  mid + (low  >> 32) > 0x7fffffff + neg)
    __gnat_last_chance_handler();

  low += ((long long unsigned) (unsigned) mid) << 32;

  return (long long int) (neg ? -low : low);
}

// Adapted from "stm32f4xx_rcc.c" and "misc.c" to make the RTS self contained.

#define AIRCR_VECTKEY_MASK    ((uint32_t)0x05FA0000)
static __I uint8_t APBAHBPrescTable[16] = {0, 0, 0, 0, 1, 2, 3, 4, 1, 2, 3, 4, 6, 7, 8, 9};

static inline uint32_t _RCC_GetClocksFreq()
{
  uint32_t tmp = 0, presc = 0, pllvco = 0, pllp = 2, pllsource = 0, pllm = 2;
  uint32_t SYSCLK_Frequency;

  /* Get SYSCLK source -------------------------------------------------------*/
  tmp = RCC->CFGR & RCC_CFGR_SWS;

  switch (tmp)
  {
    case 0x00:  /* HSI used as system clock source */
      SYSCLK_Frequency = HSI_VALUE;
      break;
    case 0x04:  /* HSE used as system clock  source */
      SYSCLK_Frequency = HSE_VALUE;
      break;
    case 0x08:  /* PLL used as system clock  source */

      /* PLL_VCO = (HSE_VALUE or HSI_VALUE / PLLM) * PLLN
         SYSCLK = PLL_VCO / PLLP
         */    
      pllsource = (RCC->PLLCFGR & RCC_PLLCFGR_PLLSRC) >> 22;
      pllm = RCC->PLLCFGR & RCC_PLLCFGR_PLLM;
      
      if (pllsource != 0)
      {
        /* HSE used as PLL clock source */
        pllvco = (HSE_VALUE / pllm) * ((RCC->PLLCFGR & RCC_PLLCFGR_PLLN) >> 6);
      }
      else
      {
        /* HSI used as PLL clock source */
        pllvco = (HSI_VALUE / pllm) * ((RCC->PLLCFGR & RCC_PLLCFGR_PLLN) >> 6);      
      }

      pllp = (((RCC->PLLCFGR & RCC_PLLCFGR_PLLP) >>16) + 1 ) *2;
      SYSCLK_Frequency = pllvco/pllp;
      break;
    default:
      SYSCLK_Frequency = HSI_VALUE;
      break;
  }
  /* Compute HCLK, PCLK1 and PCLK2 clocks frequencies ------------------------*/

  /* Get HCLK prescaler */
  tmp = RCC->CFGR & RCC_CFGR_HPRE;
  tmp = tmp >> 4;
  presc = APBAHBPrescTable[tmp];
  /* HCLK clock frequency */
  return SYSCLK_Frequency >> presc;
}

static inline void _NVIC_PriorityGroupConfig(uint32_t NVIC_PriorityGroup)
{
  /* Check the parameters */
  assert_param(IS_NVIC_PRIORITY_GROUP(NVIC_PriorityGroup));

  /* Set the PRIGROUP[10:8] bits according to NVIC_PriorityGroup value */
  SCB->AIRCR = AIRCR_VECTKEY_MASK | NVIC_PriorityGroup;
}

