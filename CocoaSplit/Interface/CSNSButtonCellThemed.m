//
//  CSNSButtonCellThemed.m
//  CocoaSplit
//
//  Created by Zakk on 11/19/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSNSButtonCellThemed.h"
#import "CaptureController.h"
#import "NSImage+tintedImage.h"

@implementation CSNSButtonCellThemed



-(void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    bool darkMode = [CaptureController sharedCaptureController].isDarkAppearance;
    
    NSImage *useImage = image;
    if (darkMode)
    {
        useImage = [image tintedImageWithColor:NSColor.whiteColor];
    }
    [useImage drawInRect:frame fromRect:NSMakeRect(0, 0, image.size.width, image.size.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

@end
