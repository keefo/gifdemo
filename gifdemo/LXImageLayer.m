//
//  LXImageLayer.m
//  gifdemo
//
//  Created by xu lian on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXImageLayer.h"
#import <QuartzCore/QuartzCore.h>
#import "gif_lib.h"


@interface LXImageLayer()
{
    CALayer *contentLayer;
}
@end

@implementation LXImageLayer


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];//create a layer-backed view
        contentLayer = [CALayer layer];
        [self.layer addSublayer:contentLayer];
        [contentLayer setNeedsDisplay];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setWantsLayer:YES];//create a layer-backed view
    contentLayer = [CALayer layer];
    [self.layer addSublayer:contentLayer];
    [contentLayer setNeedsDisplay];
}

- (void)setImagePath:(NSString *)path;
{
    _path = path;
    NSImage *img=[[NSImage alloc] initWithContentsOfFile:_path];
    if (img) {
        [self setImage:img];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
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
    // Drawing code here.
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

- (void)setImage:(NSImage *)newImage
{
    _image = newImage;
    [self setNeedsDisplay:YES];

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
                
                NSArray *frameDelays=[self frameDelays];

                // create a value array which will contains the frames of the animation
                NSMutableArray * values = [NSMutableArray array];
                
                // loop through the frames (animationDuration is the duration of the whole animation)
                float animationDuration = 0.0f;
                for (int i = 0; i < numFrame; ++i)
                {
                    // set the current frame
                    [bitmapRep setProperty:NSImageCurrentFrame withValue:[NSNumber numberWithInt:i]];
                    
                    // this part is optional. For some reasons, the NSImage class often loads a GIF with
                    // frame times of 0, so the GIF plays extremely fast. So, we check the frame duration, and if it's
                    NSInteger d = 0;
                    @try {
                        if (i<[frameDelays count]) {
                            d = [[frameDelays objectAtIndex:i] integerValue];
                        }
                    }
                    @catch (NSException *exception) {
                    }
                    @finally {
                    }
                    //NSLog(@"d=%d", d);
                    
                    //float currentFrameDuration = [[bitmapRep valueForProperty:NSImageCurrentFrameDuration] floatValue];
                    //NSLog(@"currentFrameDuration=%f", currentFrameDuration);
                    //currentFrameDuration = framedelay*0.01;
                    float currentFrameDuration = d*0.01;
                    //NSLog(@"currentFrameDuration=%f", currentFrameDuration);
                    
                    //if give frame duration 0, the core animation will draw the frame as fast as possible.
                    //currentFrameDuration = 0;
                    
                    [bitmapRep setProperty:NSImageCurrentFrameDuration withValue:@(currentFrameDuration)];
                    
                    // add the CGImageRef to this frame to the value array
                    [values addObject:(id)[bitmapRep CGImage]];
                    
                    // update the duration of the animation
                    animationDuration += [[bitmapRep valueForProperty:NSImageCurrentFrameDuration] floatValue];
                }
                
                // create and setup the animation (this is pretty straightforward)
                CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
                [animation setValues:values];
                [animation setCalculationMode:@"discrete"];
                [animation setDuration:animationDuration];
                [animation setRepeatCount:HUGE_VAL];
                animation.calculationMode = kCAAnimationDiscrete;
                
                if (self.image.size.width>self.frame.size.width || self.image.size.height>self.frame.size.height) {
                    
                    float hfactor = self.image.size.width / self.frame.size.width;
                    float vfactor = self.image.size.height / self.frame.size.height;
                    float factor = fmax(hfactor, vfactor);
                    float newWidth =  self.image.size.width / factor;
                    float newHeight =  self.image.size.height / factor;
                    
                    contentLayer.frame= NSMakeRect((int)(self.frame.size.width-newWidth)/2.0, (int)(self.frame.size.height-newHeight)/2.0, newWidth, newHeight);
                }
                else{
                    contentLayer.frame= NSMakeRect((int)(self.frame.size.width-self.image.size.width)/2.0, (int)(self.frame.size.height-self.image.size.height)/2.0, self.image.size.width, self.image.size.height);
                }
                
                [contentLayer addAnimation:animation forKey:@"contents"];
                //contentLayer.contentsScale = 1.0;
                //self.layer.transform = CATransform3DMakeScale(.95, .95, 1);  
            }
        }
    }
    
}

@end
