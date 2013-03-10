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
#import "THUserNotification.h"

@interface GAAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate, THUserNotificationCenterDelegate> {
    NSStatusItem        *statusBarItem;
    
    NSMutableArray      *servicesList;
    GAService           *proxyService;
    
    GAPACHTTPServer     *pacServer;
    
    IBOutlet NSTabView              *_mainTabView;
    
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
    
    IBOutlet NSTextField            *pacServerAddressField;
}


- (IBAction)showMainWindow:(id)sender;
- (IBAction)exitApplication:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showAbout:(id)sender;

- (IBAction)switchRunningService:(id)sender;
- (IBAction)selectedServiceChanged:(id)sender;
- (IBAction)toggleServiceStatus:(id)sender;
- (IBAction)clearStatusLog:(id)sender;

- (IBAction)applyCustomPACCustomDomainList:(id)sender;
- (IBAction)setAutoToggleProxySettingType:(id)sender;
- (IBAction)showStunnelConfigurationExample:(id)sender;
- (IBAction)selectLocalPacFileButtonClicked:(id)sender;

- (IBAction)importGoagentCA:(id)sender;


@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly) NSTabView   *mainTabView;
@property (nonatomic, readonly) GAService   *currentService;

@end
