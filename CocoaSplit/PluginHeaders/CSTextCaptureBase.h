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
    NSMutableAttributedString *_attribString;
    
    
}

@property (strong) NSFont *font;

@property (strong) NSAttributedString *attributedText;
@property (strong) NSString *text;
@property (strong) NSArray *fontNames;
@property (strong) NSColor *foregroundColor;
@property (assign) bool propertiesChanged;
@property (strong) NSDictionary *fontAttributes;
@property (strong) NSString *alignmentMode;
@property (assign) bool wrapped;
@property (readonly) NSString *saveText;
@property (readonly) NSDictionary *defaultAttributes;

@end

