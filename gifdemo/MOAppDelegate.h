//
//  MOAppDelegate.h
//  gifdemo
//
//  Created by xu lian on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LXImageView.h"
#import "LXImageLayer.h"
#import "LXDisplaylinkView.h"

@interface MOAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet LXImageLayer *imagelayer;
@property (assign) IBOutlet LXImageView *imageview;
@property (assign) IBOutlet NSImageView *nsimageview;
@property (assign) IBOutlet LXDisplaylinkView *lxdisplaylinkview;

@property (assign) IBOutlet NSPopUpButton *popupbutton;



@end
