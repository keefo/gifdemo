//
//  LXImageView.m
//  gifdemo
//
//  Created by xu lian on 2014-07-31.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "gif_lib.h"

@interface LXImageView()
{
    CALayer *contentLayer;
    NSBitmapImageRep *gifbitmapRep;
    NSInteger currentFrameIdx;
    NSInteger frameNumber;
    NSArray *frameDelays;
    NSTimer *giftimer;
    NSUInteger currentFrameLoopCount;
}
@end

@implementation LXImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //[self setWantsLayer:YES];//create a layer-backed view
        //[self setLayer:[CALayer layer]];
        //contentLayer = [CALayer layer];
        //[self.layer addSublayer:contentLayer];
        //[contentLayer setNeedsDisplay];        
    }
    return self;
}

- (void)awakeFromNib
{
    //[self setWantsLayer:YES];//create a layer-backed view
    //[self setLayer:[CALayer layer]];
    //contentLayer = [CALayer layer];
    //[self.layer addSublayer:contentLayer];
    //[contentLayer setNeedsDisplay];
    
    /*
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/cow.gif"];
    path = [[NSBundle mainBundle] pathForImageResource:@"1.gif"];
    
    const char *GifFileName = [path cStringUsingEncoding:NSUTF8StringEncoding];
    int ErrorCode;
    GifByteType *Extension;
    int ExtCode, rc;
    char *type;
    GraphicsControlBlock gcb;
    GifRecordType       rec;
    
    NSLog(@"GifFileName=%s\n", GifFileName);
    GifFileType *gif = DGifOpenFileName(GifFileName, &ErrorCode);
    NSLog(@"pgif=%p", gif);
    if(DGifGetRecordType(gif, &rec)!=GIF_ERROR){
        if (rec == EXTENSION_RECORD_TYPE)
        {
            for (rc = DGifGetExtension(gif,&ExtCode,&Extension);
                 NULL != Extension;
                 rc = DGifGetExtensionNext(gif,&Extension)) {
                if (rc == GIF_ERROR) {
                    NSLog(@"gif: DGifGetExtension failed");
                    break;
                }
                switch (ExtCode) {
                    case COMMENT_EXT_FUNC_CODE:     type="comment";   break;
                    case GRAPHICS_EXT_FUNC_CODE:    type="graphics";  break;
                    case PLAINTEXT_EXT_FUNC_CODE:   type="plaintext"; break;
                    case APPLICATION_EXT_FUNC_CODE: type="appl";      break;
                    default:                        type="???";       break;
                }
                NSLog(@"gif: extcode=0x%x [%s]",ExtCode,type);
                
                if (ExtCode == GRAPHICS_EXT_FUNC_CODE) {
                    if(DGifExtensionToGCB(4, Extension, &gcb)==GIF_OK){
                        NSLog(@"gcb->DisposalMode=%d", gcb.DisposalMode);
                        NSLog(@"gcb->UserInputFlag=%d", gcb.UserInputFlag);
                        NSLog(@"gcb->DelayTime=%d", gcb.DelayTime);
                        NSLog(@"gcb->TransparentColor=%d", gcb.TransparentColor);
                    }
                }
                
            }
        }
        NSLog(@"rec=%d", rec);
    }
    
    if (DGifSlurp(gif) == GIF_ERROR) {
        NSLog(@"DGifSlurp err");
    }
    
    NSLog(@"ImageCount=%d", gif->ImageCount);
    
    EGifCloseFile(gif, &ErrorCode);
    */
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

- (void)delayUnit:(NSTimer*)t
{
    currentFrameLoopCount++;
    if (currentFrameIdx<[frameDelays count]) {
        @try {
            NSInteger delayCount = [[frameDelays objectAtIndex:currentFrameIdx] integerValue];
            //NSLog(@"currentFrameLoopCount=%lu delayCount=%lu", currentFrameLoopCount, delayCount);
            if (currentFrameLoopCount>=delayCount) {
                currentFrameIdx++;
                currentFrameLoopCount=0;
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

- (void)setImage:(NSImage *)newImage
{
    _image = newImage;
    [self setNeedsDisplay:YES];
    gifbitmapRep = nil;
    if (giftimer) {
        [giftimer invalidate];
        giftimer=nil;
    }
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
                currentFrameIdx = currentFrameLoopCount = 0;
                gifbitmapRep = bitmapRep;
                
                giftimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(delayUnit:) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:giftimer forMode:NSRunLoopCommonModes];
            }
        }
    }
   
}

@end
