-- -*-haskell-*-
--  GIMP Toolkit (GTK) - pango non-GObject types PangoTypes
--
--  Author : Axel Simon
--
--  Created: 9 Feburary 2003
--
--  Version $Revision: 1.16 $ from $Date: 2005/12/07 12:57:37 $
--
--  Copyright (C) 1999-2005 Axel Simon
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
-- #hide

-- |
-- Maintainer  : gtk2hs-users@lists.sourceforge.net
-- Stability   : provisional
-- Portability : portable (depends on GHC)
--
-- Define types used in Pango which are not derived from GObject.
--
module Graphics.UI.Gtk.Pango.Types (
  PangoUnit,
  puToInt, puToUInt,
  intToPu, uIntToPu,
  PangoRectangle(PangoRectangle),
  fromRect,
  toRect,

  PangoString(PangoString),
  makeNewPangoString,
  withPangoString,

  PangoItem(PangoItem),
  PangoItemRaw(PangoItemRaw),
  makeNewPangoItemRaw,
  withPangoItemRaw,
  pangoItemGetFont,
  pangoItemGetLanguage,

  GlyphItem(GlyphItem),
  GlyphStringRaw(GlyphStringRaw),
  makeNewGlyphStringRaw,

  PangoLayout(PangoLayout),

  LayoutIter(LayoutIter),
  LayoutIterRaw(LayoutIterRaw),
  makeNewLayoutIterRaw,

  LayoutLine(LayoutLine),
  LayoutLineRaw(LayoutLineRaw),
  makeNewLayoutLineRaw,
  FontDescription(FontDescription),
  makeNewFontDescription,
  Language(Language),
  emptyLanguage,
  languageFromString,

  FontMetrics(..)
  ) where

import Control.Monad (liftM)
import Data.IORef ( IORef )
import System.Glib.FFI
import System.Glib.UTFString
import Graphics.UI.Gtk.General.Structs ( pangoScale, Rectangle(..),
					 pangoItemRawGetFont,
					 pangoItemRawGetLanguage )
{#import Graphics.UI.Gtk.Types#} (Font, PangoLayoutRaw)

{# context lib="pango" prefix="pango" #}

-- A pango unit is an internal euclidian metric, that is, a measure for 
-- lengths and position.
--
-- * Deprecated. Replaced by Double.
type PangoUnit = Double

puToInt :: Double -> {#type gint#}
puToInt u = truncate (u*pangoScale)

puToUInt :: Double -> {#type guint#}
puToUInt u = let u' = u*pangoScale in if u<0 then 0 else truncate u

intToPu :: {#type gint#} -> Double
intToPu i = fromIntegral i/pangoScale

uIntToPu :: {#type guint#} -> Double
uIntToPu i = fromIntegral i/pangoScale


-- | Rectangles describing an area in 'Double's.
--
-- * Specifies x, y, width and height
--
data PangoRectangle = PangoRectangle Double Double Double Double
		      deriving Show

-- Cheating functions: We marshal PangoRectangles as Rectangles.
fromRect :: Rectangle -> PangoRectangle
fromRect (Rectangle x y w h) =
  PangoRectangle (fromIntegral x/pangoScale)
		 (fromIntegral y/pangoScale)
		 (fromIntegral w/pangoScale)
		 (fromIntegral h/pangoScale)

toRect :: PangoRectangle -> Rectangle
toRect (PangoRectangle x y w h) = Rectangle (truncate (x*pangoScale))
				            (truncate (y*pangoScale))
				            (truncate (w*pangoScale))
				            (truncate (h*pangoScale))

-- A string that is stored with each GlyphString, PangoItem
data PangoString = PangoString UTFCorrection CInt (ForeignPtr CChar)

makeNewPangoString :: String -> IO PangoString
makeNewPangoString str = do
  let correct = genUTFOfs str
  (strPtr, len) <- newUTFStringLen str
  let cLen = fromIntegral len
  liftM (PangoString correct cLen) $ newForeignPtr strPtr finalizerFree

withPangoString :: PangoString -> 
		   (UTFCorrection -> CInt -> Ptr CChar -> IO a) -> IO a
withPangoString (PangoString c l ptr) act = withForeignPtr ptr $ \strPtr ->
  act c l strPtr

-- paired with PangoString to create a Haskell GlyphString
{#pointer *PangoGlyphString as GlyphStringRaw foreign newtype #}

makeNewGlyphStringRaw :: Ptr GlyphStringRaw -> IO GlyphStringRaw
makeNewGlyphStringRaw llPtr = do
  liftM GlyphStringRaw $ newForeignPtr llPtr pango_glyph_string_free

foreign import ccall unsafe "&pango_glyph_string_free"
  pango_glyph_string_free :: FinalizerPtr GlyphStringRaw

-- paired with PangoString and UTFCorrection to create a Haskell PangoItem
{#pointer *PangoItem as PangoItemRaw foreign newtype #}

makeNewPangoItemRaw :: Ptr PangoItemRaw -> IO PangoItemRaw
makeNewPangoItemRaw llPtr = do
  liftM PangoItemRaw $ newForeignPtr llPtr pango_item_free

withPangoItemRaw :: PangoItemRaw -> (Ptr PangoItemRaw -> IO a) -> IO a
withPangoItemRaw (PangoItemRaw pir) act = withForeignPtr pir act

foreign import ccall unsafe "&pango_item_free"
  pango_item_free :: FinalizerPtr PangoItemRaw

-- | Extract the font used for this 'PangoItem'.
--
pangoItemGetFont :: PangoItem -> IO Font
pangoItemGetFont (PangoItem _ (PangoItemRaw pir)) =
  withForeignPtr pir pangoItemRawGetFont

-- | Extract the 'Language' used for this 'PangoItem'.
--
pangoItemGetLanguage :: PangoItem -> IO Language
pangoItemGetLanguage (PangoItem _ (PangoItemRaw pir)) =
  liftM (Language . castPtr) $ withForeignPtr pir pangoItemRawGetLanguage

#if PANGO_CHECK_VERSION(1,2,0)
{#pointer *PangoGlyphItem as GlyphItemRaw #}
#endif

-- With each GlyphString we pair a UTFCorrection
-- and the marshalled UTF8 string. Together, this data
-- enables us to bind all functions that take or return
-- indices into the CString, rather then unicode position. Note that text
-- handling is particularly horrible with UTF8: Several UTF8 bytes can make
-- up one Unicode character (a Haskell Char), and several Unicode characters
-- can form a cluster (e.g. a letter and an accent). We protect the user from
-- UTF8\/Haskell String conversions, but not from clusters.

-- | A sequence of characters that are rendered with the same settings.
--
-- * A preprocessing stage done by 'itemize' splits the input text into
--   several chunks such that each chunk can be rendered with the same
--   font, direction, slant, etc. Some attributes such as the color,
--   underline or strikethrough do not affect a break into several
--   'PangoItem's. See also 'GlyphItem'.
--
data PangoItem = PangoItem PangoString PangoItemRaw

-- | A sequence of glyphs for a chunk of a string.
--
-- * A glyph item contains the graphical representation of a 'PangoItem'.
--   Clusters (like @e@ and an accent modifier) as well as legatures
--   (such as @ffi@ turning into a single letter that omits the dot over the
--   @i@) are usually represented as a single glyph. 
--
data GlyphItem = GlyphItem PangoItem GlyphStringRaw 

-- | A rendered paragraph.
data PangoLayout = PangoLayout (IORef PangoString) PangoLayoutRaw

-- | An iterator to examine a layout.
--
data LayoutIter = LayoutIter (IORef PangoString) LayoutIterRaw

{#pointer *PangoLayoutIter as LayoutIterRaw foreign newtype #}

makeNewLayoutIterRaw :: Ptr LayoutIterRaw -> IO LayoutIterRaw
makeNewLayoutIterRaw liPtr =
  liftM LayoutIterRaw $ newForeignPtr liPtr layout_iter_free

foreign import ccall unsafe "&pango_layout_iter_free"
  layout_iter_free :: FinalizerPtr LayoutIterRaw

-- | A single line in a 'PangoLayout'.
--
data LayoutLine = LayoutLine (IORef PangoString) LayoutLineRaw

{#pointer *PangoLayoutLine as LayoutLineRaw foreign newtype #}

makeNewLayoutLineRaw :: Ptr LayoutLineRaw -> IO LayoutLineRaw
makeNewLayoutLineRaw llPtr = do
  liftM LayoutLineRaw $ newForeignPtr llPtr pango_layout_line_unref

foreign import ccall unsafe "&pango_layout_line_unref"
  pango_layout_line_unref :: FinalizerPtr LayoutLineRaw

-- | A possibly partial description of font(s).
--
{#pointer *PangoFontDescription as FontDescription foreign newtype #}

makeNewFontDescription :: Ptr FontDescription -> IO FontDescription
makeNewFontDescription llPtr = do
  liftM FontDescription $ newForeignPtr llPtr pango_font_description_free

foreign import ccall unsafe "&pango_font_description_free"
  pango_font_description_free :: FinalizerPtr FontDescription

-- | An RFC-3066 language designator to choose scripts.
--
{#pointer* Language newtype#} deriving Eq

instance Show Language where
  show (Language ptr)
    | ptr==nullPtr = ""
    | otherwise = unsafePerformIO $ peekUTFString (castPtr ptr)

-- | Specifying no particular language.
emptyLanguage = Language nullPtr

-- | Take a RFC-3066 format language tag as a string and convert it to a
--  'Language' type that can be efficiently passed around and compared with
--  other language tags.
--
-- * This function first canonicalizes the string by converting it to
--   lowercase, mapping \'_\' to \'-\', and stripping all characters
--   other than letters and \'-\'.
--
languageFromString :: String -> IO Language
languageFromString language = liftM Language $
  withUTFString language {#call language_from_string#}

-- | The characteristic measurements of a font.
--
-- * All values are measured in pixels.
--
-- * In Pango versions before 1.6 only 'ascent', 'descent',
--   'approximateCharWidth' and 'approximateDigitWidth' are available.
--
data FontMetrics = FontMetrics {
  -- | The ascent is the distance from the baseline to the logical top
  --   of a line of text. (The logical top may be above or below the
  --   top of the actual drawn ink. It is necessary to lay out the
  --   text to figure where the ink will be.)
  ascent :: Double,
  -- | The descent is the distance from the baseline to the logical
  --   bottom of a line of text. (The logical bottom may be above or
  --   below the bottom of the actual drawn ink. It is necessary to
  --   lay out the text to figure where the ink will be.)
  descent :: Double,
  -- | The approximate character width. This is merely a
  --   representative value useful, for example, for determining the
  --   initial size for a window. Actual characters in text will be
  --   wider and narrower than this.
  approximateCharWidth :: Double,
  -- | The approximate digit width. This is merely a representative
  --   value useful, for example, for determining the initial size for
  --   a window. Actual digits in text can be wider and narrower than
  --   this, though this value is generally somewhat more accurate
  --   than 'approximateCharWidth'.
  approximateDigitWidth :: Double
#if PANGO_CHECK_VERSION(1,6,0)
  ,
  -- | The suggested thickness to draw an underline.
  underlineThickness :: Double,
  -- | The suggested position to draw the underline. The value returned is
  --   the distance above the baseline of the top of the underline. Since
  --   most fonts have underline positions beneath the baseline, this value
  --   is typically negative.
  underlinePosition :: Double,
  -- | The suggested thickness to draw for the strikethrough.
  strikethroughThickenss :: Double,
  -- | The suggested position to draw the strikethrough. The value
  --   returned is the distance above the baseline of the top of the
  --   strikethrough.
  strikethroughPosition :: Double
#endif
  } deriving Show


