//
//  TextCapture.h
//  CocoaSplit
//
//  Created by Zakk on 7/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>
#import "CaptureBase.h"

@interface TextCapture : CaptureBase <CaptureSessionProtocol>

{
    CGLayerRef  _cgLayer;
    CIImage *_ciimage;
    NSAttributedString *_attribString;
    
}

@property (strong) NSString *text;
@property (strong) NSArray *fontNames;
@property (assign) double fontSize;
@property (assign) bool isItalic;
@property (assign) bool isBold;
@property (assign) bool isUnderline;
@property (assign) bool isStrikethrough;
@property (strong) NSColor *foregroundColor;

@property (assign) bool propertiesChanged;

@end
