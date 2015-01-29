//
//  CSTextSourceBase.h
//  CocoaSplit
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>
#import "CSCaptureBase.h"

@interface CSTextCaptureBase : CSCaptureBase <CSCaptureSourceProtocol>

{
    CGLayerRef  _cgLayer;
    CIImage *_ciimage;
    NSAttributedString *_attribString;
    
    
}

@property (strong) NSFont *font;

@property (strong) NSString *text;
@property (strong) NSArray *fontNames;
@property (strong) NSColor *foregroundColor;
@property (assign) bool propertiesChanged;
@property (strong) NSDictionary *fontAttributes;

@end

