//
//  AVCaptureDeviceFormat+CocoaSplitAdditions.h
//  CocoaSplit
//
//  Created by Zakk on 1/19/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVCaptureDeviceFormat (CocoaSplitAdditions)

@property (readonly) NSString *localizedName;
@property (readonly) NSDictionary *saveDictionary;


-(bool) compareToDictionary:(NSDictionary *)dict;


@end
