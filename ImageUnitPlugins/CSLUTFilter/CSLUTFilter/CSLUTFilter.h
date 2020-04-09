//
//  CSLUTFilter.h
//  CSLUTFilter
//
//  Created by Zakk on 4/9/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSLUTFilter : CIFilter
{
    CIImage      *inputImage;
    CIImage      *inputLUTImage;
    NSData       *_cubeData;
}
@end

NS_ASSUME_NONNULL_END
