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
@synthesize imageContext = _imageContext;


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
    [aCoder encodeObject:self.selectedVideoType forKey:@"selectedVideoType"];

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
        _selectedVideoType = [aDecoder decodeObjectForKey:@"selectedVideoType"];
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


-(void)setImageContext:(CIContext *)imageContext
{
    _imageContext = imageContext;
    if (self.videoInput)
    {
        self.videoInput.imageContext = imageContext;
    }
}

-(CIContext *)imageContext
{
    return _imageContext;
}


-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];

}

-(void)setSettingsTab:(NSString *)settingsTab
{
    return;
}


-(NSString *)settingsTab
{
    if (self.videoInput)
    {
        return @"Settings";
    }
    
    return @"Source";
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
    
    if(!self.transformFilter)
    {
        self.transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [self.transformFilter setDefaults];
    }
    

    CGFloat scale_cx = 0.0f;
    CGFloat scale_cy = 0.0f;
    

    NSAffineTransform *scaleTransform = [NSAffineTransform transform];
    CGFloat cent_x, cent_y, x,y;
    
    
    cent_x = (self.inputImage.extent.origin.x) + self.inputImage.extent.size.width/2;
    cent_y = (self.inputImage.extent.origin.y) + self.inputImage.extent.size.height/2;
    scale_cx = cent_x*self.scaleFactor;
    scale_cy = cent_y*self.scaleFactor;
    x = (scale_cx)-cent_x;
    y = (scale_cy)-cent_y;
    
    [scaleTransform translateXBy:-x yBy:-y];
    
    [scaleTransform scaleBy:self.scaleFactor];
    

    cent_x = scale_cx-x;
    cent_y = scale_cy-y;
    [scaleTransform translateXBy:cent_x yBy:cent_y];
    [scaleTransform rotateByDegrees:self.rotationAngle];
    [scaleTransform translateXBy:-cent_x yBy:-cent_y];
    
    NSAffineTransform *idtrans = [[NSAffineTransform alloc] init];
    [idtrans translateXBy:self.x_pos yBy:self.y_pos];
    [scaleTransform appendTransform:idtrans];
    
    [self.transformFilter setValue:scaleTransform forKeyPath:kCIInputTransformKey];
    
    
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
    self.source_width = 0;
    self.source_height = 0;
    
    CIImage *outimg = nil;
    CVPixelBufferRef newFrame = NULL;
    if (self.videoInput)
    {
        if ([self.videoInput respondsToSelector:@selector(currentImage)])
        {
            self.inputImage = [self.videoInput currentImage];
            self.source_width = self.inputImage.extent.size.width;
            self.source_height = self.inputImage.extent.size.height;
        }
        
        
        newFrame = [self.videoInput getCurrentFrame];
        if (newFrame)
        {
            self.source_width = CVPixelBufferGetWidth(newFrame);
            self.source_height = CVPixelBufferGetHeight(newFrame);
            
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
        
        self.inputImage = [[self.solidFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:CGRectMake(0.0f, 0.0f, 200.0f, 200.0f)];
        
        
        
    }
    
    outimg = self.inputImage;
    
    NSRect cropRect = [self calculateCropRect:self.inputImage.extent.size.width height:self.inputImage.extent.size.height];
    

    
    [self.cropFilter setValue:[CIVector vectorWithX:cropRect.origin.x Y:cropRect.origin.y Z:cropRect.size.width W:cropRect.size.height] forKeyPath:@"inputRectangle"];
    
    
    [self.cropFilter setValue:outimg forKeyPath:kCIInputImageKey];
    
    outimg = [self.cropFilter valueForKey:kCIOutputImageKey];

    
    self.inputImage = outimg;

    
    if (!NSEqualSizes(self.oldSize, self.inputImage.extent.size))
    {
        [self rebuildFilters];
    }
    
    self.oldSize = self.inputImage.extent.size;
    
    

    
    [self.transformFilter setValue:outimg forKeyPath:kCIInputImageKey];

    outimg = [self.transformFilter valueForKey:kCIOutputImageKey];
    

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


-(void) scaleTo:(CGFloat)width height:(CGFloat)height
{

    CGFloat source_width, source_height;
    
    source_width = self.inputImage.extent.size.width;
    source_height = self.inputImage.extent.size.height;
    
    
    if (source_width == 0 && source_height == 0)
    {
        return;
    }
    
    float wr = width / source_width;
    float hr = height / source_height;
    
    float ratio;
    float new_w, new_h;
    float new_x, new_y;
    
    ratio = (hr < wr ? hr : wr);
    
    new_w = source_width * ratio;
    new_h = source_height * ratio;
    
    new_x = (width - new_w)/2;
    new_y = (height - new_h)/2;
    float x_adj, y_adj;
    //compensate for scaling adjustment. This adjustment is only valid when we're force-setting to center.
    //There's probably a general case method for compensating for the scaling-at-center movement of the origin
    //but I'm not good with computer
    
    
    x_adj = ((new_w-source_width)/2)-self.inputImage.extent.origin.x;
    y_adj = ((new_h-source_height)/2)-self.inputImage.extent.origin.y;
    

 
    _x_pos = new_x+x_adj;
    _y_pos = new_y+y_adj;
    _scaleFactor = ratio;

    
    [self rebuildFilters];
}


-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    _x_pos += x;
    _y_pos += y;
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
    
    id <CaptureSessionProtocol> newCaptureSession;
    
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
    } else if ([selectedVideoType isEqualToString:@"Text"]) {
        newCaptureSession = [[TextCapture alloc] init];
    } else {
        newCaptureSession = [[AVFCapture alloc] init];
    }
    
    newCaptureSession.imageContext = self.imageContext;

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
