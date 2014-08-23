//
//  WindowCapture.m
//  CocoaSplit
//
//  Created by Zakk on 8/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "WindowCapture.h"

@implementation WindowCapture

/* CGWindowListCreateImage sucks. It's really slow. This probably isn't a useful capture type, but whatever */



-(NSArray *) availableVideoDevices
{
    
    NSArray *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    
    NSDictionary *devinstance;
    
    for(devinstance in windows)
    {
        if (devinstance[(NSString *)kCGWindowSharingState] == kCGWindowSharingNone)
        {
            continue;
        }
        
        
        NSString *windowName = devinstance[(NSString *)kCGWindowOwnerName];
        if (!windowName)
        {
            windowName = @"?????";
        }
        
        NSNumber *windowID = devinstance[(NSString *)kCGWindowNumber];
        
        
        [retArray addObject:[[AbstractCaptureDevice alloc] initWithName:windowName device:windowID uniqueID:windowName]];
    }
    
    return retArray;
}

-(CIImage *)currentImage
{
    if (self.activeVideoDevice)
    {
        NSNumber *windowID = self.activeVideoDevice.captureDevice;
        
        
        CGImageRef windowImg = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, [windowID unsignedIntValue], kCGWindowImageBoundsIgnoreFraming|kCGWindowImageNominalResolution);
        CIImage *ret = [CIImage imageWithCGImage:windowImg];
        CGImageRelease(windowImg);
        return ret;
    }
    return nil;
}
@end
