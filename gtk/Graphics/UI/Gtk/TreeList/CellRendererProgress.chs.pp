-- -*-haskell-*-
--  GIMP Toolkit (GTK) Widget CellRendererProgress
--
--  Author : Duncan Coutts
--
--  Created: 2 November 2005
--
--  Version $Revision: 1.1 $ from $Date: 2005/11/12 15:10:37 $
--
--  Copyright (C) 2005 Duncan Coutts
--
--  This library is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public
--  License as published by the Free Software Foundation; either
--  version 2.1 of the License, or (at your option) any later version.
--
--  This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  Lesser General Public License for more details.
--
-- |
-- Maintainer  : gtk2hs-users@lists.sourceforge.net
-- Stability   : provisional
-- Portability : portable (depends on GHC)
--
-- Renders numbers as progress bars
--
-- * Module available since Gtk+ version 2.6
--
module Graphics.UI.Gtk.TreeList.CellRendererProgress (

-- * Class Hierarchy
-- |
-- @
-- |  'GObject'
-- |   +----'Object'
-- |         +----'CellRenderer'
-- |               +----CellRendererProgress
-- @

#if GTK_CHECK_VERSION(2,6,0)
-- * Types
  CellRendererProgress,
  CellRendererProgressClass,
  castToCellRendererProgress,
  toCellRendererProgress,

-- * Constructors
  cellRendererProgressNew,

-- * Attributes
#endif
  ) where

import Monad	(liftM)

import System.Glib.FFI
import Graphics.UI.Gtk.Abstract.Object		(makeNewObject)
{#import Graphics.UI.Gtk.Types#}

{# context lib="gtk" prefix="gtk" #}

#if GTK_CHECK_VERSION(2,6,0)
--------------------
-- Constructors

-- | Creates a new 'CellRendererProgress'.
--
cellRendererProgressNew :: IO CellRendererProgress
cellRendererProgressNew =
  makeNewObject mkCellRendererProgress $
  liftM (castPtr :: Ptr CellRenderer -> Ptr CellRendererProgress) $
  {# call gtk_cell_renderer_progress_new #}

--------------------
-- Attributes

#endif
