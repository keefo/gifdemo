//
//  LXDisplaylinkView.h
//  gifdemo
//
//  Created by liam on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OpenGLView.h"

@interface LXDisplaylinkView : NSView
@property(retain, readonly) NSString *path;
@property(retain, readonly) NSImage *image;

- (void)setImagePath:(NSString *)path;


@end
