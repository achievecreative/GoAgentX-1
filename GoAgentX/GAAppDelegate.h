//
//  GAAppDelegate.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GAAutoscrollTextView.h"
#import "GAService.h"
#import "GAPACHTTPServer.h"

@interface GAAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate> {
    NSStatusItem        *statusBarItem;
    
    NSMutableArray      *servicesList;
    GAService           *proxyService;
    
    GAPACHTTPServer     *pacServer;
    
    IBOutlet NSMenu                 *statusBarItemMenu;
    IBOutlet NSMenuItem             *statusMenuItem;
    
    IBOutlet NSPopUpButton          *servicesListPopButton;
    IBOutlet NSMenu                 *servicesListMenu;
    IBOutlet NSTabView              *servicesConfigTabView;
    
    // 状态
    IBOutlet NSTextField            *statusTextLabel;
    IBOutlet NSImageView            *statusImageView;
    IBOutlet NSButton               *statusToggleButton;
    IBOutlet GAAutoscrollTextView   *statusLogTextView;
    
    IBOutlet NSPopUpButton          *stunnelSelectedServerPopupButton;
    IBOutlet NSTextView             *stunnelServerListTextView;
}


- (IBAction)showMainWindow:(id)sender;
- (IBAction)exitApplication:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showAbout:(id)sender;

- (IBAction)selectedServiceChanged:(id)sender;
- (IBAction)toggleServiceStatus:(id)sender;
- (IBAction)togglePACSetting:(id)sender;
- (IBAction)clearStatusLog:(id)sender;

- (IBAction)showStunnelConfigurationExample:(id)sender;


@property (assign) IBOutlet NSWindow *window;

@end
