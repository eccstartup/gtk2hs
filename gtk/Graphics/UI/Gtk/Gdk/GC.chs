-- -*-haskell-*-
--  GIMP Toolkit (GTK) GC
--
--  Author : Axel Simon
--
--  Created: 28 September 2002
--
--  Version $Revision: 1.6 $ from $Date: 2005/11/26 16:00:21 $
--
--  Copyright (C) 2002-2005 Axel Simon
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
-- Graphics contexts - objects to encapsulate drawing properties
--
module Graphics.UI.Gtk.Gdk.GC (
-- * Detail
--
-- | All drawing operations in Gdk take a graphics context (GC) argument. A
-- graphics context encapsulates information about the way things are drawn,
-- such as the foreground color or line width. By using graphics contexts, the
-- number of arguments to each drawing call is greatly reduced, and
-- communication overhead is minimized, since identical arguments do not need
-- to be passed repeatedly.
--
-- Most values of a graphics context can be set at creation time by using
-- 'gcNewWithValues'. A few of the values in the GC, such as the dash
-- pattern, can only be set by the latter method.

  GC,
  GCClass,
  castToGC,
  gcNew,
  GCValues(GCValues),
  newGCValues,
  Color(..),
  foreground,
  background,
  Function(..),
  function,
  Fill(..),
  fill,
  tile,
  stipple,
  clipMask,
  SubwindowMode(..),
  subwindowMode,
  tsXOrigin,
  tsYOrigin,
  clipXOrigin,
  clipYOrigin,
  graphicsExposure,
  lineWidth,
  LineStyle(..),
  lineStyle,
  CapStyle(..),
  capStyle,
  JoinStyle(..),
  joinStyle,
  gcNewWithValues,
  gcSetValues,
  gcGetValues,
  gcSetClipRectangle,
  gcSetClipRegion,
  gcSetDashes) where

import Control.Monad	(when)
import Data.Maybe	(fromJust, isJust)
import Control.Exception (handle)

import System.Glib.FFI
import System.Glib.GObject		(constructNewGObject)
{#import Graphics.UI.Gtk.Types#}
import Graphics.UI.Gtk.General.Structs
import Graphics.UI.Gtk.General.Enums	(Function(..), Fill(..), SubwindowMode(..), LineStyle(..), 
					 CapStyle(..), JoinStyle(..))
{#import Graphics.UI.Gtk.Gdk.Region#}	(Region(Region))

{# context lib="gtk" prefix="gdk" #}

-- | Create an empty graphics context.
--
gcNew :: DrawableClass d => d -> IO GC
gcNew d = do
  gcPtr <- {#call unsafe gc_new#} (toDrawable d)
  if (gcPtr==nullPtr) then return (error "gcNew: null graphics context.")
		      else constructNewGObject mkGC (return gcPtr)


-- | Creates a graphics context with specific values.
--
gcNewWithValues :: DrawableClass d => d -> GCValues -> IO GC
gcNewWithValues d gcv = allocaBytes (sizeOf gcv) $ \vPtr -> do
  mask <- pokeGCValues vPtr gcv
  gc <- constructNewGObject mkGC $ {#call unsafe gc_new_with_values#} 
    (toDrawable d) (castPtr vPtr) mask
  handle (const $ return ()) $ when (isJust (tile gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.tile) gcv)
  handle (const $ return ()) $ when (isJust (stipple gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.stipple) gcv)
  handle (const $ return ()) $ when (isJust (clipMask gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.clipMask) gcv)
  return gc

-- | Change some of the values of a graphics context.
--
gcSetValues :: GC -> GCValues -> IO ()
gcSetValues gc gcv = allocaBytes (sizeOf gcv) $ \vPtr -> do
  mask <- pokeGCValues vPtr gcv
  gc <- {#call unsafe gc_set_values#} gc (castPtr vPtr) mask
  handle (const $ return ()) $ when (isJust (tile gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.tile) gcv)
  handle (const $ return ()) $ when (isJust (stipple gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.stipple) gcv)
  handle (const $ return ()) $ when (isJust (clipMask gcv)) $ 
    touchForeignPtr ((unPixmap.fromJust.clipMask) gcv)
  return gc

-- | Retrieve the values in a graphics context.
--
gcGetValues :: GC -> IO GCValues
gcGetValues gc = alloca $ \vPtr -> do
  {#call unsafe gc_get_values#} gc (castPtr vPtr)
  peek vPtr

-- | Set a clipping rectangle.
--
-- * All drawing operations are restricted to this rectangle. This rectangle
--   is interpreted relative to the clip origin.
--
gcSetClipRectangle :: GC -> Rectangle -> IO ()
gcSetClipRectangle gc r = with r $ \rPtr ->
  {#call unsafe gc_set_clip_rectangle#} gc (castPtr rPtr)

-- | Set a clipping region.
--
-- * All drawing operations are restricted to this region. This region
--   is interpreted relative to the clip origin.
--
gcSetClipRegion :: GC -> Region -> IO ()
gcSetClipRegion = {#call unsafe gc_set_clip_region#}

-- | Specify the pattern with which lines are drawn.
--
-- *  Every tuple in the list contains an even and an odd segment. Even
--    segments are drawn normally, whereby the 'lineStyle'
--    member of the graphics context defines if odd segements are drawn
--    or not. A @phase@ argument greater than 0 will drop
--    @phase@ pixels before starting to draw.
--
gcSetDashes :: GC -> Int -> [(Int,Int)] -> IO ()
gcSetDashes gc phase onOffList = do
  let onOff :: [{#type gint8#}]
      onOff = concatMap (\(on,off) -> [fromIntegral on, fromIntegral off]) 
	      onOffList
  withArray onOff $ \aPtr ->
    {#call unsafe gc_set_dashes#} gc (fromIntegral phase) aPtr
    (fromIntegral (length onOff))
