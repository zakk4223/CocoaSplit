//
//  NSImage+tintedImage.m
//  CocoaSplit
//
//  Created by Zakk on 11/19/17.
//

#import "NSImage+tintedImage.h"

@implementation NSImage (tintedImage)


-(NSImage *)tintedImageWithColor:(NSColor *)color
{
    NSImage *copy = self.copy;
    
    [copy lockFocus];
    [color set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, self.size.width, self.size.height), NSCompositingOperationSourceAtop);
    [copy unlockFocus];
    return copy;
}

@end
