-- -*-haskell-*-
--  GIMP Toolkit (GTK) General
--
--  Author : Axel Simon, Manuel M. T. Chakravarty, Duncan Coutts
--
--  Created: 11 October 2005
--
--  Version $Revision: 1.2 $ from $Date: 2005/11/16 13:14:16 $
--
--  Copyright (C) 2000..2005 Axel Simon, Manuel M. T. Chakravarty, Duncan Coutts
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
-- main event loop, and events
--
module System.Glib.MainLoop (
  HandlerId,
  timeoutAdd,
  timeoutAddFull,
  timeoutRemove,
  idleAdd,
  idleRemove,
  IOCondition(..),
  inputAdd,
  inputRemove,
  Priority,
  priorityLow,
  priorityDefaultIdle,
  priorityHighIdle,
  priorityDefault,
  priorityHigh,
  ) where

import Control.Monad	(liftM)

import System.Glib.FFI
import System.Glib.Flags
import System.Glib.GObject	(DestroyNotify, mkFunPtrDestroyNotify)

{#context lib="glib" prefix ="g"#}

{#pointer SourceFunc#}

foreign import ccall "wrapper" mkSourceFunc :: IO {#type gint#} -> IO SourceFunc

type HandlerId = {#type guint#}

-- Turn a function into a function pointer and a destructor pointer.
--
makeCallback :: IO {#type gint#} -> IO (SourceFunc, DestroyNotify)
makeCallback fun = do
  funPtr <- mkSourceFunc fun
  dPtr <- mkFunPtrDestroyNotify funPtr
  return (funPtr, dPtr)

-- | Sets a function to be called at regular intervals, with the default
-- priority 'priorityDefault'. The function is called repeatedly until it
-- returns @False@, after which point the timeout function will not be called
-- again. The first call to the function will be at the end of the first interval.
--
-- Note that timeout functions may be delayed, due to the processing of other
-- event sources. Thus they should not be relied on for precise timing. After
-- each call to the timeout function, the time of the next timeout is
-- recalculated based on the current time and the given interval (it does not
-- try to 'catch up' time lost in delays).
--
timeoutAdd :: IO Bool -> Int -> IO HandlerId
timeoutAdd fun msec = timeoutAddFull fun priorityDefault msec

-- | Sets a function to be called at regular intervals, with the given
-- priority. The function is called repeatedly until it returns @False@, after
-- which point the timeout function will not be called again. The first call
-- to the function will be at the end of the first interval.
--
-- Note that timeout functions may be delayed, due to the processing of other
-- event sources. Thus they should not be relied on for precise timing. After
-- each call to the timeout function, the time of the next timeout is
-- recalculated based on the current time and the given interval (it does not
-- try to 'catch up' time lost in delays).
--
timeoutAddFull :: IO Bool -> Priority -> Int -> IO HandlerId
timeoutAddFull fun pri msec = do
  (funPtr, dPtr) <- makeCallback (liftM fromBool fun)
  {#call unsafe g_timeout_add_full#}
    (fromIntegral pri)
    (fromIntegral msec)
    funPtr
    nullPtr
    dPtr

-- | Remove a previously added timeout handler by its 'HandlerId'.
--
timeoutRemove :: HandlerId -> IO ()
timeoutRemove id = {#call g_source_remove#} id >> return ()

-- | Add a callback that is called whenever the system is idle.
--
-- * A priority can be specified via an integer. This should usually be
--   'priorityDefaultIdle'.
--
-- * If the function returns @False@ it will be removed.
--
idleAdd :: IO Bool -> Priority -> IO HandlerId
idleAdd fun pri = do
  (funPtr, dPtr) <- makeCallback (liftM fromBool fun)
  {#call unsafe g_idle_add_full#} (fromIntegral pri) funPtr
    nullPtr dPtr

-- | Remove a previously added idle handler by its 'HandlerId'.
--
idleRemove :: HandlerId -> IO ()
idleRemove id = {#call g_source_remove#} id >> return ()

-- | Flags representing a condition to watch for on a file descriptor.
--
-- [@IOIn@]		There is data to read.
-- [@IOOut@]		Data can be written (without blocking).
-- [@IOPri@]		There is urgent data to read.
-- [@IOErr@]		Error condition.
-- [@IOHup@]		Hung up (the connection has been broken, usually for
--                      pipes and sockets).
-- [@IOInvalid@]	Invalid request. The file descriptor is not open.
--
{# enum IOCondition {
          G_IO_IN   as IOIn,
          G_IO_OUT  as IOOut,
          G_IO_PRI  as IOPri,
          G_IO_ERR  as IOErr,
          G_IO_HUP  as IOHup,
          G_IO_NVAL as IOInvalid
        } deriving (Eq, Bounded) #}
instance Flags IOCondition

{#pointer *IOChannel newtype#}
{#pointer IOFunc#}

foreign import ccall "wrapper" mkIOFunc :: (Ptr IOChannel -> CInt -> Ptr () -> IO {#type gboolean#}) -> IO IOFunc

type FD = Int

-- | Adds the file descriptor into the main event loop with the given priority.
--
inputAdd ::
    FD            -- ^ a file descriptor
 -> [IOCondition] -- ^ the condition to watch for
 -> Priority      -- ^ the priority of the event source
 -> IO Bool       -- ^ the function to call when the condition is satisfied.
                  --   The function should return False if the event source
                  --   should be removed.
 -> IO HandlerId  -- ^ the event source id
inputAdd fd conds pri fun = do
  funPtr <- mkIOFunc (\_ _ _ -> liftM fromBool fun)
  dPtr <- mkFunPtrDestroyNotify funPtr
  channel <- {#call unsafe g_io_channel_unix_new #} (fromIntegral fd)
  {#call unsafe g_io_add_watch_full#}
    (IOChannel channel)
    (fromIntegral pri)
    ((fromIntegral . fromFlags) conds)
    funPtr
    nullPtr
    dPtr

inputRemove :: HandlerId -> IO ()
inputRemove id = {#call g_source_remove#} id >> return ()

-- Standard priorities

#define G_PRIORITY_HIGH            -100
#define G_PRIORITY_DEFAULT          0
#define G_PRIORITY_HIGH_IDLE        100
#define G_PRIORITY_DEFAULT_IDLE     200
#define G_PRIORITY_LOW              300

-- | Priorities for installing callbacks.
--
type Priority = Int

priorityHigh :: Int
priorityHigh = G_PRIORITY_HIGH

priorityDefault :: Int
priorityDefault = G_PRIORITY_DEFAULT

priorityHighIdle :: Int
priorityHighIdle = G_PRIORITY_HIGH_IDLE

priorityDefaultIdle :: Int
priorityDefaultIdle = G_PRIORITY_DEFAULT_IDLE

priorityLow :: Int
priorityLow = G_PRIORITY_LOW
