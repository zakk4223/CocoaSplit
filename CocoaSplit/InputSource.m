//
//  InputSource.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputSource.h"
#import "CaptureSessionProtocol.h"


@implementation InputSource



@synthesize selectedVideoType = _selectedVideoType;
@synthesize name = _name;



-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeFloat:self.x_pos forKey:@"x_pos"];
    [aCoder encodeFloat:self.y_pos forKey:@"y_pos"];
    [aCoder encodeDouble:self.rotationAngle forKey:@"rotationAngle"];
    [aCoder encodeFloat:self.scaleFactor forKey:@"scaleFactor"];
    [aCoder encodeFloat:self.opacity forKey:@"opacity"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.depth forKey:@"depth"];
    [aCoder encodeInteger:self.crop_top forKey:@"crop_top"];
    [aCoder encodeInteger:self.crop_bottom forKey:@"crop_bottom"];
    [aCoder encodeInteger:self.crop_left forKey:@"crop_left"];
    [aCoder encodeInteger:self.crop_right forKey:@"crop_right"];


    if (self.videoInput)
    {
        [aCoder encodeObject:self.videoInput forKey:@"videoInput"];
    }
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        
        self.x_pos = [aDecoder decodeFloatForKey:@"x_pos"];
        self.y_pos = [aDecoder decodeFloatForKey:@"y_pos"];
        self.rotationAngle = [aDecoder decodeDoubleForKey:@"rotationAngle"];
        self.scaleFactor = [aDecoder decodeFloatForKey:@"scaleFactor"];
        self.opacity = [aDecoder decodeFloatForKey:@"opacity"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.depth = (int)[aDecoder decodeIntegerForKey:@"depth"];
        self.videoInput = [aDecoder decodeObjectForKey:@"videoInput"];
        self.crop_top = (int)[aDecoder decodeIntegerForKey:@"crop_top"];
        self.crop_bottom = (int)[aDecoder decodeIntegerForKey:@"crop_bottom"];
        self.crop_left = (int)[aDecoder decodeIntegerForKey:@"crop_left"];
        self.crop_right = (int)[aDecoder decodeIntegerForKey:@"crop_right"];

        
    }
    return self;
}



-(id)init
{
    if (self = [super init])
    {
        
        self.scaleFactor = 1.0f;
        self.x_pos = 200.0f;
        self.y_pos = 200.0f;
        self.rotationAngle =  0.0f;
        self.depth = 0;
        self.opacity = 1.0f;
        self.crop_bottom = 0;
        self.crop_top = 0;
        self.crop_left = 0;
        self.crop_right = 0;
        
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        
        self.compositeFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [self.compositeFilter setDefaults];
        
        [self rebuildFilters];
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}


-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];

}

-(NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@ Depth %d", self.name, self.depth];
}


-(void)setName:(NSString *)name
{
    _name = name;
}


-(NSString *)name
{
    if (!_name && self.videoInput)
    {
        return self.videoInput.activeVideoDevice.captureName;
    }
    
    return _name;
}
-(void)rebuildFilters
{
    
    if(!self.selectedFilter)
    {
        self.selectedFilter = [CIFilter filterWithName:@"CIColorMatrix"];
        [self.selectedFilter setDefaults];
    }
    
    if(!self.scaleFilter)
    {
        self.scaleFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [self.scaleFilter setDefaults];
    }
    
    //crop here
    
    NSAffineTransform *identityTransform = [NSAffineTransform transform];
    
    
    if (self.rotationAngle > 0.0f)
    {
        NSAffineTransform *rotateTransform = [NSAffineTransform transform];
        [rotateTransform rotateByDegrees:self.rotationAngle];
        [identityTransform appendTransform:rotateTransform];
    }
    
    if (self.scaleFactor != 0.0f)
    {
        NSAffineTransform *scaleTransform = [NSAffineTransform transform];
        [scaleTransform scaleBy:self.scaleFactor];
        [identityTransform appendTransform:scaleTransform];
    }

    
    NSAffineTransform *moveTransform = [NSAffineTransform transform];
    [moveTransform translateXBy:self.x_pos yBy:self.y_pos];
    [identityTransform appendTransform:moveTransform];
    
    [self.scaleFilter setValue:identityTransform forKeyPath:kCIInputTransformKey];
    
    CIVector *alphaVector = [CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:self.opacity];
    [self.selectedFilter setDefaults];
    
    [self.selectedFilter setValue:alphaVector forKey:@"inputAVector"];
    if (self.is_selected)
    {
        [self.selectedFilter setValue:[CIVector vectorWithX:1.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBiasVector"];
    }
    
}

-(NSRect)calculateCropRect:(int)width height:(int)height
{
    return NSMakeRect(self.crop_left, self.crop_bottom, width-self.crop_right-self.crop_left, height-self.crop_top-self.crop_bottom);
}

-(CIImage *)currentImage:(CIImage *)backgroundImage
{
    CIImage *outimg = nil;
    CVPixelBufferRef newFrame = NULL;
    if (self.videoInput)
    {
        newFrame = [self.videoInput getCurrentFrame];
        if (newFrame)
        {
            self.inputImage = [CIImage imageWithIOSurface:CVPixelBufferGetIOSurface(newFrame) options:@{kCIImageColorSpace: (__bridge id)CGColorSpaceCreateDeviceRGB()}];
                                                                                                        
                                                                                                        
            _tmpCVBuf = newFrame;

        }
    }
    
    if (!self.cropFilter)
    {
        self.cropFilter = [CIFilter filterWithName:@"CICrop"];
        [self.cropFilter setDefaults];
    }

    
    if (!self.inputImage)
    {
        if (!self.solidFilter)
        {
            self.solidFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
            [self.solidFilter setDefaults];
            [self.solidFilter setValue:[CIColor colorWithRed:0.0f green:0.0f blue:0.85f] forKey:kCIInputColorKey];
        }
        
        //[self.cropFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:100.0f W:100.0f] forKey:@"inputRectangle" ];
        
        //[self.cropFilter setValue:[self.solidFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
        //self.inputImage = [self.cropFilter valueForKey:kCIOutputImageKey];
        self.inputImage = [[self.solidFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:CGRectMake(0.0f, 0.0f, 200.0f, 200.0f)];
        
        
        
    }
    
    outimg = self.inputImage;
    
    NSRect cropRect = [self calculateCropRect:self.inputImage.extent.size.width height:self.inputImage.extent.size.height];
    

    
    [self.cropFilter setValue:[CIVector vectorWithX:cropRect.origin.x Y:cropRect.origin.y Z:cropRect.size.width W:cropRect.size.height] forKeyPath:@"inputRectangle"];
    [self.cropFilter setValue:outimg forKeyPath:kCIInputImageKey];
    outimg = [self.cropFilter valueForKey:kCIOutputImageKey];
    
    [self.scaleFilter setValue:outimg forKeyPath:kCIInputImageKey];
    
    outimg = [self.scaleFilter valueForKey:kCIOutputImageKey];
    
    
    
    
    
    [self.selectedFilter setValue:outimg forKey:kCIInputImageKey];
    outimg = [self.selectedFilter valueForKey:kCIOutputImageKey];
    
    if (outimg)
    {
        self.layoutPosition = outimg.extent;
    }

    if (backgroundImage)
    {
        //CIFilter *compositeCopy = [self.compositeFilter copy];
        [self.compositeFilter setValue:outimg forKeyPath:kCIInputImageKey];
        [self.compositeFilter setValue:backgroundImage forKeyPath:kCIInputBackgroundImageKey];
        outimg = [self.compositeFilter valueForKey:kCIOutputImageKey];
    }
    
    return outimg;
}



-(void) frameRendered
{
    if (_tmpCVBuf)
    {
        CVPixelBufferRelease(_tmpCVBuf);
        _tmpCVBuf = NULL;
    }
}



-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    _x_pos = x;
    _y_pos = y;
    [self rebuildFilters];
}


-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}



-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    
    
    NSLog(@"SETTING SELECTED VIDEO TYPE %@", selectedVideoType);
    
    self.videoInput = nil;
    
    id newCaptureSession;
    
    if ([selectedVideoType isEqualToString:@"Desktop"])
    {
        newCaptureSession = [[DesktopCapture alloc ] init];
    } else if ([selectedVideoType isEqualToString:@"AVFoundation"]) {
        newCaptureSession = [[AVFCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"QTCapture"]) {
        newCaptureSession = [[QTCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Syphon"]) {
        newCaptureSession = [[SyphonCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Image"]) {
        
        newCaptureSession = [[ImageCapture alloc] init];
    } else {
        newCaptureSession = [[AVFCapture alloc] init];
    }
    
    
    self.videoInput = newCaptureSession;
    newCaptureSession = nil;
    
    _selectedVideoType = selectedVideoType;
}



+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"x_pos", @"y_pos", @"rotationAngle", @"scaleFactor", @"is_selected", @"depth", @"opacity", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self rebuildFilters];
    }
        
}




@end
