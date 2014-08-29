//
//  AbstractCaptureDevice.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSAbstractCaptureDevice : NSObject

@property (weak) id captureDevice;
@property (strong) NSString * captureName;
@property (strong) NSString *uniqueID;


-(id) initWithName:(NSString *)name device:(id)device uniqueID:(NSString *) uniqueID;
-(bool) isEqual:(id)object;



@end
