//
//  CSChromaKeyFilter.h
//  CSChromaKey
//
//  Created by Zakk on 8/24/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CSChromaKeyFilter : CIFilter {
    CIImage      *inputImage;
    CIVector     *inputColor;
    NSNumber     *inputThreshold;
    NSNumber     *inputSmoothing;
}

@end
