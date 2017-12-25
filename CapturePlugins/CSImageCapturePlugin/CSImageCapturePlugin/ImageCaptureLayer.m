//
//  ImageCaptureLayer.m
//  CSImageCapturePlugin
//
//  Created by Zakk on 11/7/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "ImageCaptureLayer.h"

@implementation ImageCaptureLayer

@synthesize sourceRef = _sourceRef;


+(BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"gifIndex"])
    {
        return YES;
    }
    
    return NO;
}




-(void)dealloc
{
    if (_sourceRef)
    {
        CFRelease(_sourceRef);
    }
}


@end
