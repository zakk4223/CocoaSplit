//
//  AbstractCaptureDevice.m
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//


//Why does this class exist?
//It makes it easy to bind the list to an NSArrayController; Using an NSDictionaryController requires the device to be
//copyable, and AVCaptureDevice isn't :(


#import "AbstractCaptureDevice.h"

@implementation AbstractCaptureDevice


-(id) initWithName:(NSString *)name device:(id)device uniqueID:(NSString *)uniqueID
{
    self = [super init];
    if (self)
    {
        self.captureName = name;
        self.captureDevice = device;
        self.uniqueID = uniqueID;
      
    }
    return self;
}


-(bool) isEqual:(id)object;
{
    return [self.uniqueID isEqualToString:((AbstractCaptureDevice *)object).uniqueID];
}

-(NSString *) description
{
    return [NSString stringWithFormat:@"<AbstractCaptureDevice: %p> [%@] %@:%@", self, self.captureName, self.uniqueID, self.captureDevice];
}

@end
