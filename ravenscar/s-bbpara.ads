------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . P A R A M E T E R S                --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2011, AdaCore                     --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
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
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially  developed  by --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

--  This package defines basic parameters used by the low level tasking system

--  This is the ARM version of this package

with System.Parameters;
with System.Storage_Elements;

package System.BB.Parameters is
   pragma Pure (System.BB.Parameters);

   -----------------------
   -- Stack information --
   -----------------------

   --  Boundaries of the stack for the environment task, defined by the linker
   --  script file.

   Top_Of_Environment_Stack : constant System.Address;
   pragma Import (Asm, Top_Of_Environment_Stack, "__stack_top");
   --  Top of the stack to be used by the environment task

   Bottom_Of_Environment_Stack : constant System.Address;
   pragma Import (Asm, Bottom_Of_Environment_Stack, "__stack_bottom");
   --  Bottom of the stack to be used by the environment task

   --------------------
   -- Hardware clock --
   --------------------

   Clock_Frequency : constant Positive := 1_000;
   --  Ticks per second.

   ----------------
   -- Interrupts --
   ----------------

   --  These definitions are in this package in order to isolate target
   --  dependencies.

   Interrupt_Levels : constant Positive := 16;
   --  Number of interrupt levels in the STM43F4 architecture.

   subtype Interrupt_Level is Natural range 0 .. Interrupt_Levels;
   --  Type that defines the range of possible interrupt levels

   Interrupts : constant := 97;
   --  The number of interrupts on the STM32.

   ------------
   -- Stacks --
   ------------

   Interrupt_Stack_Size : constant := 1 * 1024;  --  bytes
   --  Size of each of the interrupt stacks

   ----------
   -- CPUS --
   ----------

   Max_Number_Of_CPUs : constant := 1;
   --  Maximum number of CPUs

   Multiprocessor : constant Boolean := Max_Number_Of_CPUs /= 1;
   --  Are we on a multiprocessor board?

end System.BB.Parameters;
