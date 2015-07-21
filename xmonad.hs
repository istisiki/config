-- Originally not mine but I've already made multiple changes to this config.

{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, TypeSynonymInstances, FlexibleContexts, NoMonomorphismRestriction #-}
 
-- XMonad configuration file by Thomas ten Cate <ttencate@gmail.com>
-- 
-- Works on xmonad-0.8, NOT on 0.7 or below; and of course
-- xmonad-contrib needs to be installed as well
--
-- This is designed to play nice with a standard Ubuntu Hardy installation.
-- It gives you 10 workspaces, available through Alt+F1..F10. You can move
-- windows to a workspace with Win+F1..F10 (and you will automatically switch
-- to that workspace too).
--
-- All workspaces respect panels and docks.
--
-- Keybindings mostly use the Windows key, but some use Alt to mimic other
-- window managers. In general: Alt is used for navigation, Win for modification.
-- Some of the bindings resemble the XMonad defaults, but most don't.
-- The bindings are set up to be comfortable to use on a dvorak keyboard layout.
--
-- Navigation:
--   Alt+F1..F10          switch to workspace
--   Ctrl+Alt+Left/Right  switch to previous/next workspace
--   Alt+Tab              focus next window
--   Alt+Shift+Tab        focus previous window
--
-- Window management:
--   Win+F1..F10          move window to workspace
--   Win+Up/Down          move window up/down
--   Win+C                close window
--   Alt+ScrollUp/Down    move focused window up/down
--   Win+M                move window to master area
--   Win+N                refresh the current window
--   Alt+LMB              move floating window
--   Alt+MMB              resize floating window
--   Alt+RMB              unfloat floating window
--   Win+T                unfloat floating window
--
-- Layout management:
--   Win+Left/Right       shrink/expand master area
--   Win+W/V              move more/less windows into master area
--   Win+Space            cycle layouts
--
-- Other:
--   Win+Enter            start a terminal
--   Win+R                open the dmenu
--   Win+Q                restart XMonad
--   Win+Shift+Q          display Gnome shutdown dialog  # TODO not working, need to fix.

import XMonad
import XMonad.Util.Run
import XMonad.Util.EZConfig
import qualified XMonad.StackSet as S
import XMonad.Actions.CycleWS
import XMonad.Config.Gnome
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Combo
import XMonad.Layout.Grid
import XMonad.Layout.LayoutModifier
import XMonad.Layout.Named
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.TwoPane
import XMonad.Layout.WindowNavigation
import XMonad.Util.WindowProperties
import Control.Monad
import Data.Ratio
import qualified Data.Map as M
import XMonad.Hooks.DynamicLog
import System.IO

-- defaults on which we build
-- use e.g. defaultConfig or gnomeConfig
myBaseConfig = defaultConfig



-- display
-- replace the bright red border with a more stylish colour
myBorderWidth = 3
myNormalBorderColor = "#b7a4ad"
myFocusedBorderColor = "#8f0214"



-- workspaces
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10" ]



-- layouts
basicLayout = Tall nmaster delta ratio where
    nmaster = 1
    delta   = 3/100
    ratio   = 1/2

tallLayout   = named "tall"   $ avoidStruts $ basicLayout
wideLayout   = named "wide"   $ avoidStruts $ Mirror basicLayout
singleLayout = named "single" $ avoidStruts $ noBorders Full

myLayoutHook = normal where
    normal   = tallLayout ||| wideLayout ||| singleLayout

myManageHook = manageHook myBaseConfig



-- Mod4 is the Super / Windows key
myModMask = mod4Mask
altMask   = mod1Mask



-- better keybindings for dvorak
myKeys conf = M.fromList $
    [ ((myModMask              , xK_Return), spawn $ XMonad.terminal conf)
    , ((myModMask              , xK_r     ), spawn "exe=`dmenu_run -b -nb black -nf yellow -sf yellow` && eval \"exec $exe\"")
    , ((myModMask              , xK_c     ), kill)
    , ((myModMask              , xK_space ), sendMessage NextLayout)
    , ((myModMask              , xK_n     ), refresh)
    , ((myModMask              , xK_m     ), windows S.swapMaster)
    , ((altMask                , xK_Tab   ), windows S.focusDown)
    , ((altMask .|. shiftMask  , xK_Tab   ), windows S.focusUp)
    , ((myModMask              , xK_Down  ), windows S.swapDown)
    , ((myModMask              , xK_Up    ), windows S.swapUp)
    , ((myModMask              , xK_Left  ), sendMessage Shrink)
    , ((myModMask              , xK_Right ), sendMessage Expand)
    , ((myModMask              , xK_t     ), withFocused $ windows . S.sink)
    , ((myModMask              , xK_w     ), sendMessage (IncMasterN 1))
    , ((myModMask              , xK_v     ), sendMessage (IncMasterN (-1)))
    , ((myModMask              , xK_q     ), broadcastMessage ReleaseResources >> restart "xmonad" True)
    , ((myModMask .|. shiftMask, xK_q     ), spawn "gnome-session-save --kill")
    , ((altMask .|. controlMask, xK_Left  ), prevWS)
    , ((altMask .|. controlMask, xK_Right ), nextWS)
    ] ++
    -- Alt+F1..F10 switches to workspace
    -- (Alt is in a nicer location for the thumb than the Windows key,
    -- and 1..9 keys are already in use by Firefox, irssi, ...)
    [ ((altMask, k), windows $ S.greedyView i)
        | (i, k) <- zip myWorkspaces workspaceKeys
    ] ++
    -- mod+F1..F10 moves window to workspace and switches to that workspace
    [ ((myModMask, k), (windows $ S.shift i) >> (windows $ S.greedyView i))
        | (i, k) <- zip myWorkspaces workspaceKeys
    ]
    where workspaceKeys = [xK_F1 .. xK_F10]



-- mouse bindings that mimic Gnome's
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
    [ ((altMask, button1), (\w -> focus w >> mouseMoveWindow w))
    , ((altMask, button2), (\w -> focus w >> mouseResizeWindow w))
    , ((altMask, button3), (\w -> focus w >> (withFocused $ windows . S.sink)))
    , ((altMask, button4), (const $ windows S.swapUp))
    , ((altMask, button5), (const $ windows S.swapDown))
    ]



-- put it all together
main = do
  xmproc <- spawnPipe "xmobar"
  xmonad $ myBaseConfig
    { modMask = myModMask
    , workspaces = myWorkspaces
    , layoutHook = myLayoutHook
    , manageHook = myManageHook
    , logHook = dynamicLogWithPP xmobarPP
                  { ppOutput = hPutStrLn xmproc
                    , ppTitle = xmobarColor "green" "" . shorten 50
                  }
    , borderWidth = myBorderWidth
    , normalBorderColor = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor
    , keys = myKeys
    , mouseBindings = myMouseBindings
    }
