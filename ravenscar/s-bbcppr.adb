------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . C P U _ P R I M I T I V E S            --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2010, AdaCore                     --
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

with Interfaces; use Interfaces;

with System;
with System.Machine_Code;
with System.Storage_Elements;
with System.BB.Threads.Queues;
with System.BB.Interrupts;
with System.BB.Protection;
with System.BB.Peripherals;

with Ada.Unchecked_Conversion;

with System.BB.Peripherals.Registers; use System.BB.Peripherals.Registers;

package body System.BB.CPU_Primitives is

--   procedure Dbg (N : Character);
--   pragma Import (C, Dbg);

   package SSE renames System.Storage_Elements;
   use type SSE.Integer_Address;
   use type SSE.Storage_Offset;

--   Flag_F : constant Unsigned_32 := 2#0100_0000#;
--   Flag_I : constant Unsigned_32 := 2#1000_0000#;
   --  Processor flags.

--   procedure Set_Cpsr_C (Val : Unsigned_32);
--   function Get_Cpsr return Unsigned_32;
   --  Setting and getting processor flags.

   ----------------
   -- Local data --
   ----------------

   --  jbte: Inversion a cause de thumb2, cf le .S
   SP  : constant Range_Of_Context :=  0;
--   SP  : constant Range_Of_Context :=  13;
--   LR  : constant Range_Of_Context :=  12;
--   Arg : constant Range_Of_Context :=  0;

   type Stack_Type is record
      R4 : Unsigned_32;
      R5 : Unsigned_32;
      R6 : Unsigned_32;
      R7 : Unsigned_32;
      R8 : Unsigned_32;
      R9 : Unsigned_32;
      R10 : Unsigned_32;
      R11 : Unsigned_32;
      R0 : Unsigned_32;
      R1 : Unsigned_32;
      R2 : Unsigned_32;
      R3 : Unsigned_32;
      R12 : Unsigned_32;
      LR : Unsigned_32;
      PC : Unsigned_32;
      xPST : Unsigned_32;
   end record;

   procedure Initialize_Stack (Stack_Pointer : System.Address;
                               Program_Counter : System.Address;
                               Argument : System.Address);

   procedure Initialize_Stack (Stack_Pointer : System.Address;
                               Program_Counter : System.Address;
                               Argument : System.Address) is
      Stack : Stack_Type;
      for Stack'Address use Stack_Pointer;
   begin
      Stack.R0 := Unsigned_32 (Argument);
      Stack.PC := Unsigned_32 (Program_Counter);
      Stack.xPST := 16#01000000#;
   end Initialize_Stack;

   ------------------------
   -- Initialize_Context --
   ------------------------

   procedure Initialize_Context
     (Buffer          : not null access Context_Buffer;
      Program_Counter : System.Address;
      Argument        : System.Address;
      Stack_Pointer   : System.Address)
   is
      Default_Stack_Size : constant System.Storage_Elements.Storage_Offset
            := Stack_Type'Size;
      Stack : constant System.Address := Stack_Pointer - Default_Stack_Size;
   begin
      Buffer (SP) := Stack;
--      Buffer (LR) := Program_Counter;
--      Buffer (Arg) := Argument;
      Initialize_Stack (Stack, Program_Counter, Argument);
   end Initialize_Context;

   -------------------------------
   -- Initialize_Floating_Point --
   -------------------------------

   procedure Initialize_Floating_Point is
   begin
      --  There is no floating point unit and therefore we have a null body

      null;
   end Initialize_Floating_Point;

   --------------
   -- Get_Cpsr --
   --------------

--   function Get_Cpsr return Unsigned_32 is
--      Res : Unsigned_32;
--   begin
--      System.Machine_Code.Asm ("mrs %0,cpsr",
--                               Outputs => Unsigned_32'Asm_Output ("=r", Res),
--                               Volatile => True);
--      return Res;
--   end Get_Cpsr;

   ----------------
   -- Set_Cpsr_C --
   ----------------

--   procedure Set_Cpsr_C (Val : Unsigned_32) is
--   begin
--      System.Machine_Code.Asm ("msr cpsr_c,%0",
--                               Inputs => Unsigned_32'Asm_Input ("r", Val),
--                               Volatile => True);
--   end Set_Cpsr_C;

   ------------------------
   -- Disable_Interrupts --
   ------------------------

   procedure Disable_Interrupts is
   begin
      System.Machine_Code.Asm ("cpsid i" & ASCII.LF & ASCII.HT &
                               "cpsid f",
                               Clobber => "memory",
                               Volatile => True);
--      Set_Cpsr_C (Get_Cpsr or Flag_I or Flag_F);
   end Disable_Interrupts;

   -----------------------
   -- Enable_Interrupts --
   -----------------------

   procedure Enable_Interrupts
     (Level : System.BB.Parameters.Interrupt_Level)
   is
   begin
      if Level = 0 then
         System.Machine_Code.Asm ("cpsie i" & ASCII.LF & ASCII.HT &
                                  "cpsie f",
                                  Clobber => "memory",
                                  Volatile => True);
--         Set_Cpsr_C (Get_Cpsr and not (Flag_I or Flag_F));
      end if;
   end Enable_Interrupts;

end System.BB.CPU_Primitives;
