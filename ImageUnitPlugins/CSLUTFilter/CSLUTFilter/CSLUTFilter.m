//
//  CSLUTFilter.m
//  CSLUTFilter
//
//  Created by Zakk on 4/9/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSLUTFilter.h"

@implementation CSLUTFilter


- (NSDictionary *)customAttributes
{
    return @{
        @"inputLUTImage":@{
            kCIAttributeType:kCIAttributeTypeImage,
            kCIAttributeClass: @"CIImage",
            kCIAttributeDisplayName: @"LUT Image",
        },
    };
}


-(void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:key];
    if ([key isEqualToString:@"inputLUTImage"])
    {
        [self processLUTImage:value];
    }
}



-(void)processLUTImage:(CIImage *)lutImage
{
    //We have to render to something we can extract data out of :(
    int useSize = 64;
    CGFloat width = lutImage.extent.size.width;
    CGFloat height = lutImage.extent.size.height;
    int rowCnt = height/useSize;
    int colCnt = width/useSize;
    
    CGColorSpaceRef colorSpace = NULL;
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    uint8_t *bitmapPtr = malloc(width*height*4);
    //CGContextRef cgContext = CGBitmapContextCreate(bitmapPtr, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    
    //CIContext *ctx = [CIContext contextWithCGContext:cgContext options:@{kCIContextOutputColorSpace: (__bridge id)colorSpace, kCIContextWorkingColorSpace: (__bridge id)colorSpace}];
    

    //[ctx drawImage:lutImage inRect:lutImage.extent fromRect:lutImage.extent];
    CIContext *ctx = [CIContext context];
    
    [ctx render:lutImage toBitmap:bitmapPtr rowBytes:width*4 bounds:CGRectMake(0, 0, width, height) format:kCIFormatRGBA8 colorSpace:CGColorSpaceCreateWithName(kCGColorSpaceSRGB)];
    float *cubePtr = malloc(useSize*useSize*useSize*4*sizeof(float));
    NSData *tmpCubeData = [[NSData alloc] initWithBytesNoCopy:cubePtr length:useSize*useSize*useSize*4*sizeof(float) ];
    
    int bitoffset = 0;
    uint z = 0;
    
    for(int rowNum = 0; rowNum < rowCnt; rowNum++)
    {
        for(uint y = 0; y < useSize; y++)
        {
            uint tmp = z;
            for(uint colNum = 0; colNum < colCnt; colNum++)
            {
                for (uint x = 0; x < useSize; x++)
                {
                    
                    float red = (float)bitmapPtr[bitoffset] /255.0;
                    float green = (float)bitmapPtr[bitoffset+1] / 255.0;
                    float blue = (float)bitmapPtr[bitoffset+2] / 255.0 ;
                    float alpha = (float)bitmapPtr[bitoffset+3] / 255.0 ;
                    //NSLog(@"BITMAP r: %f g: %f b: %f a: %f", red, green, blue, alpha);

                    int dataoffset = (z*useSize * useSize + y * useSize + x) * 4;
                    //NSLog(@"DATA OFFSET %d", dataoffset);
                    cubePtr[dataoffset] = red;
                    cubePtr[dataoffset+1] = green;
                    cubePtr[dataoffset+2] = blue;
                    cubePtr[dataoffset+3] = alpha;
                    bitoffset += 4;
                }
                z++;
            }
            z = tmp;
        }
        z += colCnt;
    }
    
    //CGContextRelease(cgContext);
    free(bitmapPtr);
    _cubeData = tmpCubeData;
}


- (CIImage *)outputImage
{
    if (_cubeData)
    {
        CIFilter *cubeFilter = [CIFilter filterWithName:@"CIColorCube" withInputParameters:@{
            kCIInputImageKey: inputImage,
            @"inputCubeData": _cubeData,
            @"inputCubeDimension": @(64),
        }
        ];
        return [cubeFilter outputImage];
    } else {
        return inputImage;
    }
}



@end
