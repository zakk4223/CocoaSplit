//
//  TextureWrapPluginFilter.h
//  TextureWrapPlugin
//
//  Created by Zakk on 8/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface TextureWrapPluginFilter : CIFilter {
    CIImage      *inputImage;
    NSNumber     *inputXOffset;
    NSNumber     *inputYOffset;
}

@end
