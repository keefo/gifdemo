//
//  LXColorView.m
//  gifdemo
//
//  Created by liam on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXColorView.h"

@implementation LXColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    // Drawing code here.
}

@end
