------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--    S Y S T E M . M U L T I P R O C E S S O R S . S P I N _ L O C K S     --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                    Copyright (C) 2010-2011, AdaCore                      --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

package body System.Multiprocessors.Spin_Locks is

   ----------
   -- Lock --
   ----------

   procedure Lock (Slock : in out Spin_Lock) is
      pragma Unreferenced (Slock);
   begin
      null;
   end Lock;

   ------------
   -- Locked --
   ------------

   function Locked (Slock : Spin_Lock) return Boolean is
      pragma Unreferenced (Slock);
   begin
      return False;
   end Locked;

   --------------
   -- Try_Lock --
   --------------

   procedure Try_Lock (Slock : in out Spin_Lock; Succeeded : out Boolean) is
      pragma Unreferenced (Slock);
   begin
      Succeeded := True;
   end Try_Lock;

   ------------
   -- Unlock --
   ------------

   procedure Unlock (Slock : in out Spin_Lock) is
   begin
      null;
   end Unlock;

end System.Multiprocessors.Spin_Locks;
