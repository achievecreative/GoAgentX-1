//
//  GAAppDelegate.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GAAutoscrollTextView.h"
#import "GACommandRunner.h"
#import "GAService.h"
#import "GAGoAgentService.h"

@interface GAAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    NSStatusItem        *statusBarItem;
    
    NSArray             *servicesList;
    GAService           *proxyService;
    
    IBOutlet NSMenu     *statusBarItemMenu;
    IBOutlet NSMenuItem *statusMenuItem;
    
    IBOutlet NSPopUpButton          *servicesListPopButton;
    IBOutlet NSTabView              *servicesConfigTabView;
    
    // 状态
    IBOutlet NSTextField            *statusTextLabel;
    IBOutlet NSImageView            *statusImageView;
    IBOutlet NSButton               *statusToggleButton;
    IBOutlet GAAutoscrollTextView   *statusLogTextView;
}


- (IBAction)showMainWindow:(id)sender;
- (IBAction)exitApplication:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showAbout:(id)sender;

- (IBAction)toggleServiceStatus:(id)sender;
- (IBAction)clearStatusLog:(id)sender;


@property (assign) IBOutlet NSWindow *window;

@end
