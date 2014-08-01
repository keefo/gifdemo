//
//  LXDisplaylinkView.m
//  gifdemo
//
//  Created by liam on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXDisplaylinkView.h"
#import <AVFoundation/AVFoundation.h>
#import "gif_lib.h"

@interface LXDisplaylinkView ()
{
	CVDisplayLinkRef _displayLink;
    NSBitmapImageRep *gifbitmapRep;
    NSInteger currentFrameIdx;
    NSInteger frameNumber;
    NSArray *frameDelays;
    NSUInteger currentFrameLoopCount;
    CFAbsoluteTime lastdraw;
}
@end

@implementation LXDisplaylinkView

CVReturn displayLinkOutputCallback(
                                   CVDisplayLinkRef displayLink,
                                   const CVTimeStamp *inNow,
                                   const CVTimeStamp *inOutputTime,
                                   CVOptionFlags flagsIn,
                                   CVOptionFlags *flagsOut,
                                   void *displayLinkContext)
{
    @autoreleasepool {
        LXDisplaylinkView *self = (__bridge LXDisplaylinkView *)displayLinkContext;
        [self redrawIfNeeded];
    }
    return kCVReturnSuccess;
}



- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink, displayLinkOutputCallback, (__bridge void *)self);
        CVDisplayLinkStart(_displayLink);
    }
    return self;
}


- (NSArray*)frameDelays
{
    const char *GifFileName = [_path cStringUsingEncoding:NSUTF8StringEncoding];
    int ErrorCode;
    
    GifFileType *gif = DGifOpenFileName(GifFileName, &ErrorCode);
    
    NSMutableArray *frameDelay=[NSMutableArray array];
    
#define UNSIGNED_LITTLE_ENDIAN(lo, hi)	((lo) | ((hi) << 8))
    
    if (DGifSlurp(gif) == GIF_ERROR) {
        NSLog(@"DGifSlurp err");
    }
    else{
        for(int i=0; i<gif->ImageCount; i++){
            SavedImage sp = gif->SavedImages[i];
            if (sp.ExtensionBlocks->ByteCount==4) {
                NSUInteger delay = UNSIGNED_LITTLE_ENDIAN(sp.ExtensionBlocks->Bytes[1], sp.ExtensionBlocks->Bytes[2]);
                [frameDelay addObject:@(delay)];//0.01s units
            }
        }
    }
    
    return frameDelay;
}


- (void)redrawIfNeeded {
    if (frameDelays && currentFrameIdx<[frameDelays count]) {
        CGFloat diff = CFAbsoluteTimeGetCurrent()-lastdraw;
        @try {
            CGFloat delaySecond = [[frameDelays objectAtIndex:currentFrameIdx] integerValue]*0.01;
            //NSLog(@"currentFrameLoopCount=%lu delayCount=%lu", currentFrameLoopCount, delayCount);
            if (diff>=delaySecond) {
                lastdraw = CFAbsoluteTimeGetCurrent();
                currentFrameIdx++;
                [self display];
            }
        }
        @catch (NSException *exception) {
        }
        @finally {
        }
    }
    else{
        currentFrameIdx=0;
    }

}

- (void)setImagePath:(NSString *)path;
{
    _path = path;
    NSImage *img=[[NSImage alloc] initWithContentsOfFile:_path];
    if (img) {
        [self setImage:img];
    }
}

- (void)setImage:(NSImage *)newImage
{
    _image = newImage;
    gifbitmapRep = nil;
    {
        // get the image representations, and iterate through them
        NSArray * reps = [newImage representations];
        for (NSImageRep * rep in reps)
        {
            // find the bitmap representation
            if ([rep isKindOfClass:[NSBitmapImageRep class]] == YES)
            {
                // get the bitmap representation
                NSBitmapImageRep * bitmapRep = (NSBitmapImageRep *)rep;
                //[bitmapRep setSize:NSMakeSize(image.size.width, image.size.height)];
                
                // get the number of frames. If it's 0, it's not an animated gif, do nothing
                int numFrame = [[bitmapRep valueForProperty:NSImageFrameCount] intValue];
                if (numFrame == 0)
                    break;
                
                frameNumber = numFrame;
                frameDelays=[self frameDelays];
                currentFrameIdx = currentFrameLoopCount = lastdraw = 0;
                gifbitmapRep = bitmapRep;
                //NSLog(@"frameDelays=%@", frameDelays);
            }
        }
    }
    [self setNeedsDisplay:YES];
}



- (void)dealloc
{
	if (_displayLink)
	{
		CVDisplayLinkStop(_displayLink);
		CVDisplayLinkRelease(_displayLink);
        _displayLink=nil;
	}
}


- (void)drawRect:(NSRect)dirtyRect
{
    if (gifbitmapRep) {
        
        int numFrame = [[gifbitmapRep valueForProperty:NSImageFrameCount] intValue];
        if (currentFrameIdx>=numFrame) {
            currentFrameIdx=0;
        }
        [gifbitmapRep setProperty:NSImageCurrentFrame withValue:@(currentFrameIdx)];
        
        if (self.image.size.width>self.frame.size.width || self.image.size.height>self.frame.size.height) {
            
            float hfactor = self.image.size.width / self.frame.size.width;
            float vfactor = self.image.size.height / self.frame.size.height;
            float factor = fmax(hfactor, vfactor);
            float newWidth =  self.image.size.width / factor;
            float newHeight =  self.image.size.height / factor;
            
            [gifbitmapRep drawInRect:NSMakeRect((int)(self.frame.size.width-newWidth)/2.0, (int)(self.frame.size.height-newHeight)/2.0, newWidth, newHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:NO hints:nil];
        }
        else{
            [gifbitmapRep drawInRect:NSMakeRect((int)(self.frame.size.width-self.image.size.width)/2.0, (int)(self.frame.size.height-self.image.size.height)/2.0, self.image.size.width, self.image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:NO hints:nil];
        }
        return;
    }
    
    if (self.image) {
        if (self.image.size.width>self.frame.size.width || self.image.size.height>self.frame.size.height) {
            
            float hfactor = self.image.size.width / self.frame.size.width;
            float vfactor = self.image.size.height / self.frame.size.height;
            float factor = fmax(hfactor, vfactor);
            float newWidth =  self.image.size.width / factor;
            float newHeight =  self.image.size.height / factor;
            
            [self.image drawInRect:NSMakeRect((int)(self.frame.size.width-newWidth)/2.0, (int)(self.frame.size.height-newHeight)/2.0, newWidth, newHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
        }
        else{
            [self.image drawAtPoint:NSMakePoint((int)(self.frame.size.width-self.image.size.width)/2.0, (int)(self.frame.size.height-self.image.size.height)/2.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
        }
    }
}



@end
