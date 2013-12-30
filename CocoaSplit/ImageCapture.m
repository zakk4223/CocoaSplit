//
//  ImageCapture.m
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "ImageCapture.h"
#import "AbstractCaptureDevice.h"

@implementation ImageCapture


@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize imageDirectory = _imageDirectory;
@synthesize settingsController = _settingsController;

-(id)init
{
    if (self = [super init])
    {
        
        

    }
    
    return self;
    
}


-(id<ControllerProtocol>)settingsController
{
    return _settingsController;
}


-(void)setSettingsController:(id<ControllerProtocol>)settingsController
{
    _settingsController = settingsController;
    self.imageDirectory = [self.settingsController getExtraData:@"ImageCapture:Directory"];
}


- (BOOL)needsAdvancedVideo
{
    return YES;
}


-(void) setImageDirectory:(NSString *)imageDirectory
{
    
    _imageDirectory = imageDirectory;
    [self refreshDirectory];
    [self.settingsController setExtraData:imageDirectory forKey:@"ImageCapture:Directory"];
    
}



-(NSString *)imageDirectory
{
    return _imageDirectory;
}



-(void)refreshDirectory
{
 
    if (!self.imageDirectory)
    {
        return;
    }
    
    
    NSArray *filetypes = [NSImage imageFileTypes];
    
    NSArray *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.imageDirectory error:nil];
    
    NSArray *imageFiles = [allFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", filetypes]];
    
    NSString *fileName;
    
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];

    for(fileName in imageFiles)
    {
        
        [retArray addObject:[[AbstractCaptureDevice alloc] initWithName:fileName device:self.imageDirectory uniqueID:fileName]];
    }

    [self willChangeValueForKey:@"availableVideoDevices"];
    _sourceList = retArray;
    [self didChangeValueForKey:@"availableVideoDevices"];
    
}

-(NSArray *) availableVideoDevices
{
    
    return _sourceList;
}

-(AbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}

-(void)setActiveVideoDevice:(AbstractCaptureDevice *)activeVideoDevice
{
    _activeVideoDevice = activeVideoDevice;
    
    //.device is the directory, uniqueID is the filename
    
    NSImage *newImage = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", activeVideoDevice.captureDevice, activeVideoDevice.uniqueID]];
    
    if (newImage)
    {
        CVPixelBufferRef newFrame = NULL;
        
        size_t width = [newImage size].width;
        size_t height = [newImage size].height;
        CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO] forKey: (NSString *)kIOSurfaceIsGlobal];

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, ioAttrs, kCVPixelBufferIOSurfacePropertiesKey, nil];
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, k32BGRAPixelFormat, (__bridge CFDictionaryRef)dict, &newFrame);
        CVPixelBufferLockBaseAddress(newFrame, 0);
        void *rasterData = CVPixelBufferGetBaseAddress(newFrame);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(newFrame);
    
        CGContextRef ctxt = CGBitmapContextCreate(rasterData, width, height, 8, bytesPerRow, cs, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst);
        
        NSGraphicsContext *nsctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:nsctxt];
        [newImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
        [NSGraphicsContext restoreGraphicsState];
        
        CVPixelBufferUnlockBaseAddress(newFrame, 0);
        CFRelease(ctxt);
        
        if (self.currentFrame)
        {
            CVPixelBufferRelease(self.currentFrame);
        }

        self.currentFrame = newFrame;
    }
    
}

-(CVImageBufferRef) getCurrentFrame
{
    if (self.currentFrame)
    {
        CVPixelBufferRetain(self.currentFrame);
    }
    
    
    return self.currentFrame;
}


-(void)chooseDirectory:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    
    if ([openPanel runModal] == NSOKButton)
    {
        NSArray *directories = [openPanel URLs];
        NSURL *dirUrl = [directories objectAtIndex:0];
        if (dirUrl)
        {
            self.imageDirectory = [dirUrl path];
        }
    }
}
@end
