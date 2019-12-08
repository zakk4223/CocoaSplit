//
//  CSNSImageCellThemed.m
//  CocoaSplit
//
//  Created by Zakk on 11/19/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSNSImageCellThemed.h"
#import "CaptureController.h"

@implementation CSNSImageCellThemed

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    bool useDarkMode = [CaptureController sharedCaptureController].isDarkAppearance;
    NSImage *myimage = self.image;
    if (!myimage)
    {
        return;
    }
    
    if (!myimage.template)
    {
        [super drawInteriorWithFrame:cellFrame inView:controlView];
        return;
    }
    
    if (useDarkMode)
    {
        myimage = [self.image tintedImageWithColor:NSColor.whiteColor];
    } else {
        myimage = [self.image tintedImageWithColor:NSColor.blackColor];
    }
    
    [myimage drawInRect:cellFrame fromRect:NSMakeRect(0, 0, myimage.size.width, myimage.size.height) operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}
@end
