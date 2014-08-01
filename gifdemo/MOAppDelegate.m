//
//  MOAppDelegate.m
//  gifdemo
//
//  Created by xu lian on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "MOAppDelegate.h"

@implementation MOAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_popupbutton removeAllItems];
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] resourcePath] error:nil];
    for(NSString *p in array){
        if ([p hasSuffix:@".gif"]) {
            [_popupbutton addItemWithTitle:p];
        }
    }
    [_popupbutton setTarget:self];
    [_popupbutton setAction:@selector(changeImage:)];
    
    NSString *gifname = @"1";
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/cow.gif"];
    path = [[NSBundle mainBundle] pathForImageResource:gifname];
    [_imageview setImagePath:path];
    [_imagelayer setImagePath:path];
    [_lxdisplaylinkview setImagePath:path];
    [_nsimageview setImage:[NSImage imageNamed:gifname]];
}

- (IBAction)changeImage:(id)sender
{
    NSString *gifname=[[_popupbutton selectedItem] title];
    NSString *path = [[NSBundle mainBundle] pathForImageResource:gifname];
    [_imageview setImagePath:path];
    [_imagelayer setImagePath:path];
    [_lxdisplaylinkview setImagePath:path];
    [_nsimageview setImage:[NSImage imageNamed:gifname]];
}

@end
