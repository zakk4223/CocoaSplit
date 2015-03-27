//
//  TextureWrapPluginFilter.m
//  TextureWrapPlugin
//
//  Created by Zakk on 8/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TextureWrapPluginFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation TextureWrapPluginFilter

static CIKernel *_TextureWrapPluginFilterKernel = nil;

- (id)init
{
    if(!_TextureWrapPluginFilterKernel) {
        
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"TextureWrapPluginFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"TextureWrapPluginFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_TextureWrapPluginFilterKernel = kernels[0];
    }
    return [super init];
}







- (NSDictionary *)customAttributes
{
    return @{
        @"inputXOffset":@{
            kCIAttributeDefault:@0.00,
            kCIAttributeType:kCIAttributeTypeScalar,
        },
        
        @"inputYOffset":@{
                kCIAttributeDefault:@0.00,
                kCIAttributeType:kCIAttributeTypeScalar,
        },
        @"inputMaxX":@{
                kCIAttributeDefault:@0.00,
                kCIAttributeType:kCIAttributeTypeScalar,
                },
        @"inputMaxY":@{
                kCIAttributeDefault:@0.00,
                kCIAttributeType:kCIAttributeTypeScalar,
                },

        
    };
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src;
    
    NSLog(@"CI IMAGE BOUNDS %@", NSStringFromRect(inputImage.extent));
    src = [CISampler samplerWithImage:inputImage];
    //src = [CISampler samplerWithImage:inputImage keysAndValues:kCISamplerWrapMode, kCISamplerWrapClamp, nil];
    
    
    return [self apply:_TextureWrapPluginFilterKernel, src,
            inputXOffset,inputYOffset,kCIApplyOptionDefinition, [src definition], nil];
}

@end
