//
//  CSChromaKeyFilter.m
//  CSChromaKey
//
//  Created by Zakk on 8/24/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSChromaKeyFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation CSChromaKeyFilter

static CIKernel *_CSChromaKeyFilterKernel = nil;

- (id)init
{
    if(!_CSChromaKeyFilterKernel) {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"CSChromaKeyFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"CSChromaKeyFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_CSChromaKeyFilterKernel = kernels[0];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return @{
        @"inputColor":@{
            kCIAttributeDefault:[CIColor colorWithRed:0.0f green:1.0f blue:0.0f],
            kCIAttributeType:kCIAttributeTypeOpaqueColor,
        },
        @"inputThreshold":@{
            kCIAttributeDefault:@0.1005,
            kCIAttributeType:kCIAttributeTypeScalar,
            kCIAttributeSliderMax:@0.5,
            kCIAttributeSliderMin:@0,
        },
        
        @"inputSmoothing":@{
            kCIAttributeDefault:@0.1344,
            kCIAttributeType:kCIAttributeTypeScalar,
            kCIAttributeSliderMax:@0.5,
            kCIAttributeSliderMin:@0,
        },
    };
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src;
    
    src = [CISampler samplerWithImage:inputImage];
    return [self apply:_CSChromaKeyFilterKernel, src, inputColor, inputThreshold, inputSmoothing, kCIApplyOptionDefinition, [src definition], nil];
}

@end
