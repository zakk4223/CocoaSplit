//
//  CaptureBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CaptureBase.h"

@implementation CaptureBase

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.activeVideoDevice.uniqueID forKey:@"active_uniqueID"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
     
        NSString *uniqueID = [aDecoder decodeObjectForKey:@"active_uniqueID"];
        [self setDeviceForUniqueID:uniqueID];
    }
    
    return self;
}


-(void)setDeviceForUniqueID:(NSString *)uniqueID
{
    AbstractCaptureDevice *dummydev = [[AbstractCaptureDevice alloc] init];
    
    dummydev.uniqueID = uniqueID;
    
    NSArray *currentAvailableDevices;
    
    currentAvailableDevices = self.availableVideoDevices;
    
    NSUInteger sidx;
    sidx = [currentAvailableDevices indexOfObject:dummydev];
    if (sidx == NSNotFound)
    {
        self.activeVideoDevice = nil;
    } else {
        self.activeVideoDevice = [currentAvailableDevices objectAtIndex:sidx];
    }
}

-(CVImageBufferRef) getCurrentFrame
{
    return NULL;
}



@end
