-- -*-haskell-*-
--  GIMP Toolkit (GTK) Widget GArrow
--
--  Author : Axel Simon
--          
--  Created: 23 May 2001
--
--  Version $Revision: 1.1 $ from $Date: 2005/01/08 15:28:02 $
--
--  Copyright (c) 1999..2002 Axel Simon
--
--  This file is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This file is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
-- |
--
-- An Arrow pointing to one of the four cardinal direction.
--

module Graphics.UI.Gtk.Misc.GArrow (
  Arrow,
  ArrowClass,
  castToArrow,
  ArrowType(..),
  ShadowType(..),
  arrowNew,
  arrowSet
  ) where

import Monad	(liftM)

import System.Glib.FFI
import Graphics.UI.Gtk.Abstract.Object	(makeNewObject)
{#import Graphics.UI.Gtk.Types#}
{#import Graphics.UI.Gtk.Signals#}
import Graphics.UI.Gtk.General.Enums	(ArrowType(..), ShadowType(..))

{# context lib="gtk" prefix="gtk" #}

-- methods

-- | Create a new arrow with display options.
--
arrowNew :: ArrowType -> ShadowType -> IO Arrow
arrowNew at st = makeNewObject mkArrow $ liftM castPtr $ 
  {#call unsafe arrow_new#} ((fromIntegral.fromEnum) at) 
  ((fromIntegral.fromEnum) st)

-- | Change the visual appearance of this widget.
--
arrowSet :: ArrowClass a => a -> ArrowType -> ShadowType -> IO ()
arrowSet a at st = {#call arrow_set#} (toArrow a) ((fromIntegral.fromEnum) at)
  ((fromIntegral.fromEnum) st)

