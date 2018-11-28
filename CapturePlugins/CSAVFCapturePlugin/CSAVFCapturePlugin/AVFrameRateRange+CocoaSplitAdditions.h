//
//  AVFrameRateRange+CocoaSplitAdditions.h
//  CocoaSplit
//
//  Created by Zakk on 1/19/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVFrameRateRange (CocoaSplitAdditions)
@property (readonly) NSString *localizedName;
-(NSComparisonResult)compare:(AVFrameRateRange *)otherObj;

@end
