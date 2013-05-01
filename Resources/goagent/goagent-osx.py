#!/usr/bin/env python2.6
# coding:utf-8
# Contributor:
#      Phus Lu        <phus.lu@gmail.com>

__version__ = '1.5'

GOAGENT_ICON_DATA = """\
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAADtklEQVR42r3UW0xbdRwH8PqiLz7Y
xTTEJwMSdVMX2nMprZBSeqFd6cQlBgPGxGVJSwschLpNjDMap9vUxIxgKbcNKgHWdcU55nSJOpEx
Wkav0DIvC0pgPiy6+dD2nPP/ethMk5kljD34S/7J/+mT3/93+ctkG8cD/zn3F1sP4MHyD74p0x3+
sdF06EKb6eAUp3v360bbx4ntm4bXMfbtsX79O+f+ULp92bKmvpyqyZdTOX05yt2bN3cn924KpQ58
WVzdeXpa9oTloYq9gfeZlgFCu31gXT7QDi9hnF3TxkOXH7tnkH1vppT2jKQq909M0S1DyzR3XMqu
l9CuPsI4uiXYu/CMZ7JkQ+i5Iz8pdB9FnqIcfdry9s+PsB1+r6p10Me6Bryq14dE2tVDWIcXpbsH
FrjDbi1y6qexqHscuMvzjUPXa5n9E9+znvHfWc6/yrT51xju2BrTPLjGtg6uSvUjt8AmL7bUj6Sy
YcswouyKMKuN48+6PXdgmqGbCqbzTI7yjIp0+yih2/y3DzdE6JZBCeqXathfABX1/tTqd/YgonSe
zDAiomoB0CgKYMXRpFnpCeak7MB6RkFzIxI4TChuWKBa+3mqpY+nmnt52vUZTzm6eJl18gskqPMI
awRc1IDM0jxuVlUXBtfYlXEpOwLZdZDuGCdKblh8sjnEK16duCRvOBWSNwZC8pdPTMjrAyGZ6fzB
5WmbCwnmOiLlIi6WQ5ym88gbHQXQ0L3kLGu/Dao6RsVi56lrr33yqYPcUJ4ly88v4iqbxlUmTX5V
ZsiS8i+kJShSIWJWi3UQM3QOWbO78GT90bRe+UYgz3gCZDs3JmxrDZ4lOfYcUi/kEbcKiFkERM0C
5o0Cma8WMacjiFSSdVC8pJbuTB5/6wwF0Naz8ijdeTpPecbINu4kb32r5wRWq9NI2UUkbJBQIFYD
RE3AZQMQroIEYh2UmkIQZrOA7uE7x+bYjTp63/i3z3LBhP7N491kxZhBwk6Q3EGQsBAhaooLcVNC
iBkSQliXFCKVSSFckcSs5gKws/aug62RBluxL148NelUk59tGSlDCbQSLFqJELMExbmakBg1niRR
sy8/p1UjqykB6KINNwbYVSou7Fq6lWHKRhCzEhIzSfUz/ELixpAwXxXDNX3JPe8y0FRErrz4AxI7
CeL/1jBuIbhi/vC3r7ZuwZLpDGAt2tQXBrjtyLzEY6GWR7Qmj3mT1HEjj6RJakCD/b4+Walzj4Bv
kFr7SjPQ6Ea2zgjskMv+z/gHq6RKE1cMAqYAAAAASUVORK5CYII="""

import sys
import os
import base64

from PyObjCTools import AppHelper
from AppKit import NSObject
from AppKit import NSApplication
from AppKit import NSImage
from AppKit import NSData
from AppKit import NSStatusBar
from AppKit import NSMenu
from AppKit import NSMenuItem
from AppKit import NSVariableStatusItemLength


class GoAgentOSX(NSObject):

    def applicationDidFinishLaunching_(self, notification):
        self.statusbar = NSStatusBar.systemStatusBar()
        # Create the statusbar item
        self.statusitem = self.statusbar.statusItemWithLength_(NSVariableStatusItemLength)
        # Set initial image
        raw_data = base64.b64decode(''.join(GOAGENT_ICON_DATA.strip().splitlines()))
        self.image_data = NSData.dataWithBytes_length_(raw_data, len(raw_data))
        self.image = NSImage.alloc().initWithData_(self.image_data)
        self.statusitem.setImage_(self.image)
        # Let it highlight upon clicking
        self.statusitem.setHighlightMode_(1)
        # Set a tooltip
        self.statusitem.setToolTip_('GoAgent OSX')

        # Build a very simple menu
        self.menu = NSMenu.alloc().init()
        # Show Menu Item
        menuitem = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_('Show', 'show:', '')
        self.menu.addItem_(menuitem)
        # Hide Menu Item
        menuitem = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_('Hide', 'hide:', '')
        self.menu.addItem_(menuitem)
        # Rest Menu Item
        menuitem = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_('Reset', 'reset:', '')
        self.menu.addItem_(menuitem)
        # Default event
        menuitem = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_('Quit', 'terminate:', '')
        self.menu.addItem_(menuitem)
        # Bind it to the status item
        self.statusitem.setMenu_(self.menu)

    def show_(self, notification):
        print 'show'

    def hide_(self, notification):
        print 'hide'

    def reset_(self, notification):
        print 'reset'


def main():
    global __file__
    __file__ = os.path.abspath(__file__)
    if os.path.islink(__file__):
        __file__ = getattr(os, 'readlink', lambda x: x)(__file__)
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    app = NSApplication.sharedApplication()
    delegate = GoAgentOSX.alloc().init()
    app.setDelegate_(delegate)
    AppHelper.runEventLoop()

if __name__ == '__main__':
    main()
