------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . I N T E R R U P T S                --
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

with Ada.Unchecked_Conversion;
with System.Storage_Elements;
with System.BB.CPU_Primitives;
with System.BB.Protection;
with System.BB.Threads;
with System.BB.Threads.Queues;
with System.BB.Peripherals.Registers; use System.BB.Peripherals.Registers;
with Interfaces; use Interfaces;
with Interfaces.C;

package body System.BB.Interrupts is

   procedure Dbg (N : Character);
   pragma Import (C, Dbg);
   pragma Unreferenced (Dbg);

   use type System.Storage_Elements.Storage_Offset;

   procedure Default_Isr (Id : Interrupt_ID);
   --  Default handlers.

   ----------------
   -- Local data --
   ----------------

   Interrupt_Handlers : array (HW_Interrupt_ID) of Interrupt_Handler;

   Interrupt_Being_Handled : Interrupt_ID := No_Interrupt;
   pragma Atomic (Interrupt_Being_Handled);
   --  Interrupt_Being_Handled contains the interrupt currently being
   --  handled in the system, if any. It is equal to No_Interrupt when no
   --  interrupt is handled. Its value is updated by the trap handler.

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Irq_Handler;
   pragma Export (C, Irq_Handler, "irq_handler_ada");
   --  This wrapper procedure is in charge of setting the appropriate
   --  software priorities before calling the user-defined handler.

   --------------------
   -- Attach_Handler --
   --------------------

   procedure Attach_Handler (Handler : Interrupt_Handler;
                             Id      : Interrupt_ID) is
   begin
      --  Check that we are attaching to a real interrupt

      pragma Assert (Id /= No_Interrupt);

      --  Copy the user's handler to the appropriate place within the table

      Interrupt_Handlers (Id) := Handler;

   end Attach_Handler;

   ---------------------------
   -- Priority_Of_Interrupt --
   ---------------------------

   function Priority_Of_Interrupt
     (Id : Interrupt_ID) return System.Any_Priority
   is
      function To_Level (Id : Interrupt_ID) return Interrupt_Level;
      pragma Import (C, To_Level, "_NVIC_GetPriority");
   begin
      --  Assert that it is a real interrupt.
      pragma Assert (Id /= No_Interrupt);

      return To_Priority (To_Level (Id));
   end Priority_Of_Interrupt;

   -----------------
   -- To_Priority --
   -----------------

   function To_Priority
     (Level : Interrupt_Level) return System.Any_Priority
   is
   begin
      --  Assert that it is a real interrupt level.
      pragma Assert (Level /= No_Level);

      return (Any_Priority (Level) + Interrupt_Priority'First - 1);
   end To_Priority;

   -----------------------
   -- Current_Interrupt --
   -----------------------

   function Current_Interrupt return Interrupt_ID is
   begin
      return Interrupt_Being_Handled;
   end Current_Interrupt;

   -----------------------
   -- Interrupt_Wrapper --
   -----------------------

   procedure Irq_Handler
   is
      function Get_Current_Interrupt return Integer;
      pragma Import (C, Get_Current_Interrupt, "get_current_interrupt");
      Vec             : constant Integer := Get_Current_Interrupt;
      Interrupt       : HW_Interrupt_ID;
      Self_Id         : constant Threads.Thread_Id := Threads.Thread_Self;
      Caller_Priority : constant Any_Priority :=
                          Threads.Get_Priority (Self_Id);

      Previous_Interrupt_Level : constant Interrupt_ID :=
                                   Interrupt_Being_Handled;

   begin
      if Vec not in HW_Interrupt_ID'Range then
         --  Spurious one.
         return;
      end if;

      Interrupt := Interrupt_ID (Vec);

      --  Store the interrupt being handled

      Protection.Enter_Kernel;

      Interrupt_Being_Handled := Interrupt;

      --  Then, we must set the appropriate software priority corresponding
      --  to the interrupt being handled. It comprises also the appropriate
      --  interrupt masking.

      Threads.Queues.Change_Priority (Self_Id,
         Priority_Of_Interrupt (Interrupt));

      Protection.Leave_Kernel;

      Interrupt_Handlers (Interrupt).all (Interrupt);

      --  Restore the software priority to the state before the interrupt
      --  happened. Interrupt unmasking is not done here (it will be done
      --  later by the interrupt epilogue).

      Protection.Enter_Kernel;

      Threads.Queues.Change_Priority (Self_Id, Caller_Priority);

      --  Restore the interrupt that was being handled previously (if any)

      Interrupt_Being_Handled := Previous_Interrupt_Level;

      Protection.Leave_Kernel;
   end Irq_Handler;

   ----------------------------
   -- Within_Interrupt_Stack --
   ----------------------------

   function Within_Interrupt_Stack
     (Stack_Address : System.Address) return Boolean
   is
      pragma Unreferenced (Stack_Address);
   begin
      --  Always return false as the task stack is always used.
      return False;
   end Within_Interrupt_Stack;

   procedure Default_Isr (Id : Interrupt_ID) is
      pragma Unreferenced (Id);
   begin
      null;
   end Default_Isr;

   ---------------------------
   -- Initialize_Interrupts --
   ---------------------------

   procedure Initialize_Interrupts is
   begin
      for I in HW_Interrupt_ID loop
         Attach_Handler (Default_Isr'Access, I);
      end loop;
   end Initialize_Interrupts;

end System.BB.Interrupts;
