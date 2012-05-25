/****************************************************************************
 *                                                                          *
 *                GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                  *
 *                                                                          *
 *                      C O N T E X T _ S W I T C H                         *
 *                                                                          *
 *                              Assembly File                               *
 *                                                                          *
 *                       Copyright (C) 2010 AdaCore                         *
 *                                                                          *
 * GNAT is free software;  you can  redistribute it  and/or modify it under *
 * terms of the  GNU General Public License as published  by the Free Soft- *
 * ware  Foundation;  either version 2,  or (at your option) any later ver- *
 * sion.  GNAT is distributed in the hope that it will be useful, but WITH- *
 * OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License *
 * for  more details.  You should have  received  a copy of the GNU General *
 * Public License  distributed with GNAT;  see file COPYING.  If not, write *
 * to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, *
 * MA 02111-1307, USA.                                                      *
 *                                                                          *
 * As a  special  exception,  if you  link  this file  with other  files to *
 * produce an executable,  this file does not by itself cause the resulting *
 * executable to be covered by the GNU General Public License. This except- *
 * ion does not  however invalidate  any other reasons  why the  executable *
 * file might be covered by the  GNU Public License.                        *
 *                                                                          *
 ****************************************************************************/

/* This file is the ARM specific implementation */
        
/* procedure context_switch.
   This routine performs a context switch between the two tasks that are
   specified in running_thread and first_thread. */

  .syntax unified
  .cpu cortex-m4
  .text
  .align 2

  .global pendsv_handler
  .type pendsv_handler,%function
pendsv_handler:
  stmdb sp!, {r4-r11}  /* Save the remaining registers. */
  cpsid i
  ldr   ip, Lrun
  ldr   ip, [ip]
  str   sp, [ip]       /* Save the new top of stack into the first member of the TCB. */

  @ running thread = first_thread
  ldr     ip, Lfirst
  ldr     ip, [ip]
  ldr     r0, Lrun
  str     ip, [r0]

  ldr   sp, [ip]       /* Load the new stack */
  cpsie i
  ldmia sp!, {r4-r11}  /* Pop the registers. */
  bx lr


  .align 2
Lrun:
  .word   __gnat_running_thread_table
Lfirst:
  .word   first_thread_table
