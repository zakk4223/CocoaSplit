//
//  CSIOSurfaceLayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSIOSurfaceLayer.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

@interface OpenGLProgram : NSObject
{
    
    GLint _sampler_uniform_locations[3];
}

@property (strong) NSString *label;
@property (assign) GLuint gl_programName;




-(void) setUniformLocation:(int)index location:(GLint)location;
-(GLint) getUniformLocation:(int)index;

@end


@implementation OpenGLProgram


-(id) init
{
    if (self = [super init])
    {
        _sampler_uniform_locations[0] = -1;
        _sampler_uniform_locations[1] = -1;
        _sampler_uniform_locations[2] = -1;
        
    }
    
    return self;
}


-(void)setUniformLocation:(int)index location:(GLint)location
{
    if (index < sizeof(_sampler_uniform_locations))
    {
        _sampler_uniform_locations[index] = location;
    }
}


-(GLint)getUniformLocation:(int)index
{
    if (index >= sizeof(_sampler_uniform_locations))
    {
        return -1;
    } else {
        return _sampler_uniform_locations[index];
    }
    
}

@end


@interface CIImageWrapper : NSObject
{
    uint32_t _csIOSurfaceSeed;
    
    CVImageBufferRef _csPixelBufferPriv;
}


@property (assign) IOSurfaceRef ioImage;
@end

@implementation CIImageWrapper




-(instancetype)init
{
    self = [super init];
    return self;
}


-(instancetype)initWithCVImageBuffer:(CVImageBufferRef)imageBuffer
{
    
    if (self = [super init])
    {
        IOSurfaceRef imageSurface = CVPixelBufferGetIOSurface(imageBuffer);
        if (imageSurface)
        {
            CVPixelBufferRetain(imageBuffer);
            _csPixelBufferPriv = imageBuffer;
            [self assignIOSurface:imageSurface];
        } else {
            _csPixelBufferPriv = NULL;
        }
    }
    
    return self;
}



-(void)assignIOSurface:(IOSurfaceRef)ioSurf
{
    
    IOSurfaceIncrementUseCount(ioSurf);
    CFRetain(ioSurf);
    self.ioImage = ioSurf;
    _csIOSurfaceSeed = IOSurfaceGetSeed(ioSurf);
}

-(instancetype)initWithIOSurface:(IOSurfaceRef)surface
{
    //CIImage retains the iosurface, we're just here to mess with the use count.
    if (self = [super init])
    {
        [self assignIOSurface:surface];
    }
    return self;
}


-(void)dealloc
{
    
    if (self.ioImage)
    {
        IOSurfaceDecrementUseCount(self.ioImage);
        CFRelease(self.ioImage);
    }
    
    if (_csPixelBufferPriv)
    {
        CVPixelBufferRelease(_csPixelBufferPriv);
    }
}

@end


@interface CSIOSurfaceLayer()
{
    CIFilter *_matrixFilter;
    GLuint _programId;
    GLuint _previewTextures[3];
    NSMutableDictionary *_shaderPrograms;
    bool _loadedShaders;
    int _num_planes;
    int _can_count;
    bool _reassert_async;
    BOOL _updateOnDemand;
    
    
    CGLContextObj _contextObj;
}


@property (strong) CIImageWrapper *imageWrapper;
@end


@implementation CSIOSurfaceLayer

@synthesize ioSurface = _ioSurface;
@synthesize ioImage = _ioImage;
@synthesize imageBuffer = _imageBuffer;

-(instancetype)init
{
    if (self = [super init])
    {
        _updateOnDemand = NO;

        self.asynchronous = YES;
        
        self.needsDisplayOnBoundsChange = YES;
        self.flipImage = NO;
        _lastSurfaceSize = NSMakeRect(0, 0, 0, 0);
        _privateCropRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        self.imageWrapper = nil;
        _reassert_async = YES;
        _can_count = 0;
        
    }
    
    return self;
}

-(void)setAsynchronous:(BOOL)asynchronous
{
    _updateOnDemand = asynchronous;

    if (asynchronous)
    {
        [super setAsynchronous:asynchronous];
    }
}


-(void) logGLShader:(GLuint)logTarget shaderPath:(NSString *)shaderPath
{
    int infologLength = 0;
    int maxLength;
    
    if(glIsShader(logTarget))
    {
        glGetShaderiv(logTarget,GL_INFO_LOG_LENGTH,&maxLength);
    } else {
        glGetProgramiv(logTarget,GL_INFO_LOG_LENGTH,&maxLength);
    }
    char infoLog[maxLength];
    
    if (glIsShader(logTarget))
    {
        glGetShaderInfoLog(logTarget, maxLength, &infologLength, infoLog);
    } else {
        glGetProgramInfoLog(logTarget, maxLength, &infologLength, infoLog);
    }
    
    if (infologLength > 0)
    {
        NSLog(@"LOG FOR SHADER %@:  %s\n",shaderPath, infoLog);
    }
    
}


-(GLuint) loadShader:(NSString *)name  shaderType:(GLenum)shaderType
{
    
    
    NSBundle *appBundle = [NSBundle mainBundle];
    
    NSString *extension;
    if (shaderType == GL_FRAGMENT_SHADER)
    {
        extension = @"fgsh";
    } else if (shaderType == GL_VERTEX_SHADER) {
        extension = @"vtsh";
    }
    
    NSString *shaderPath = [appBundle pathForResource:name ofType:extension inDirectory:@"Shaders"];
    
    NSString *shaderSource = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:NULL];
    
    GLuint shaderName;
    
    shaderName = glCreateShader(shaderType);
    
    const char *sc_src = [shaderSource cStringUsingEncoding:NSASCIIStringEncoding];
    
    glShaderSource(shaderName, 1, &sc_src, NULL);
    glCompileShader(shaderName);
    [self logGLShader:shaderName shaderPath:shaderPath];
    return shaderName;
}

-(GLuint) createProgram:(NSString *)vertexName fragmentName:(NSString *)fragmentName
{
    GLuint progVertex = [self loadShader:vertexName shaderType:GL_VERTEX_SHADER];
    GLuint progFragment = [self loadShader:fragmentName shaderType:GL_FRAGMENT_SHADER];
    
    GLuint newProgram = glCreateProgram();
    glAttachShader(newProgram, progVertex);
    glAttachShader(newProgram, progFragment);
    glLinkProgram(newProgram);
    
    
    [self logGLShader:newProgram shaderPath:nil];
    
    
    
    return newProgram;
}


-(void) setProgramUniforms:(OpenGLProgram *)program
{
    GLint text_loc;
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture1");
    [program setUniformLocation:0 location:text_loc];
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture2");
    [program setUniformLocation:1 location:text_loc];
    
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture3");
    [program setUniformLocation:2 location:text_loc];
}


-(void) createShaders
{
    
    OpenGLProgram *progObj;
    _shaderPrograms = [[NSMutableDictionary alloc] init];
    
    
    GLuint newProgram = [self createProgram:@"passthrough" fragmentName:@"passthrough"];
    
    progObj = [[OpenGLProgram alloc] init];
    progObj.label = @"passthrough";
    progObj.gl_programName = newProgram;
    
    [self setProgramUniforms:progObj];
    
    [_shaderPrograms setObject: progObj forKey:@"passthrough"];
    
    newProgram = [self createProgram:@"passthrough" fragmentName:@"420v"];
    
    progObj = [[OpenGLProgram alloc] init];
    progObj.label = @"420v";
    progObj.gl_programName = newProgram;
    
    [self setProgramUniforms:progObj];
    
    [_shaderPrograms setObject:progObj forKey:@"420v"];
    
}

-(void)setImageBuffer:(CVImageBufferRef)imageBuffer
{
    @synchronized(self)
    {
        self.imageWrapper = [[CIImageWrapper alloc] initWithCVImageBuffer:imageBuffer];
    }
 
    //imageWrapper retains imageBuffer
    _imageBuffer = imageBuffer;
}

-(CVImageBufferRef)imageBuffer
{
    return _imageBuffer;
}


-(void)calculateCrop:(NSRect)extent;
{
    CGRect newCrop;
    
    newCrop.origin.x = extent.size.width * _privateCropRect.origin.x;
    newCrop.origin.y = extent.size.height * _privateCropRect.origin.y;
    newCrop.size.width = extent.size.width * _privateCropRect.size.width;
    newCrop.size.height = extent.size.height * _privateCropRect.size.height;
    _lastSurfaceSize = extent;
    _calculatedCrop = newCrop;
}


//We handle this by cropping the source image, and never pass it on to the parent
-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
    if (self.imageWrapper && self.imageWrapper.ioImage)
    {
        size_t width, height;
    
        width = IOSurfaceGetWidth(self.imageWrapper.ioImage);
        height = IOSurfaceGetHeight(self.imageWrapper.ioImage);
        [self calculateCrop:NSMakeRect(0, 0, width, height)];
    }
}

-(CGRect)contentsRect
{
    return _privateCropRect;
}



-(void)setIoSurface:(IOSurfaceRef)ioSurface
{

    
    @synchronized(self)
    {
        self.imageWrapper = [[CIImageWrapper alloc] initWithIOSurface:ioSurface];
    }
    _ioSurface = ioSurface;

    
}


-(IOSurfaceRef)ioSurface
{
    return _ioSurface;
}




-(void)bindProgramTextures:(OpenGLProgram *)program
{
    
    
    for(int i = 0; i < 3; i++)
    {
        glUniform1i([program getUniformLocation:i], i);
    }
    
}



-(void)setupTextures:(IOSurfaceRef)surface withContext:(CGLContextObj)cgl_ctx
{
    GLenum gl_internal_format;
    GLenum gl_format;
    GLenum gl_type;
    
    OSType frame_pixel_format = IOSurfaceGetPixelFormat(surface);
    
    NSString *programName;
    
    programName = @"passthrough";
    

    GLenum plane_enums[3][3];
    
    switch (frame_pixel_format) {
    
        case kCVPixelFormatType_422YpCbCr8:
            plane_enums[0][0] = GL_YCBCR_422_APPLE;
            plane_enums[0][1] = GL_RGB8;
            plane_enums[0][2] = GL_UNSIGNED_SHORT_8_8_APPLE;
            _num_planes = 1;
            break;
        case kCVPixelFormatType_422YpCbCr8FullRange:
        case kCVPixelFormatType_422YpCbCr8_yuvs:
            plane_enums[0][0] = GL_YCBCR_422_APPLE;
            plane_enums[0][1] = GL_RGB;
            plane_enums[0][2] = GL_UNSIGNED_SHORT_8_8_REV_APPLE;
            _num_planes = 1;
            break;
        case kCVPixelFormatType_32BGRA:
            plane_enums[0][0] = GL_BGRA;
            plane_enums[0][1] = GL_RGBA;
            plane_enums[0][2] = GL_UNSIGNED_INT_8_8_8_8_REV;
            _num_planes = 1;
            break;
        case kCVPixelFormatType_32RGBA:
            plane_enums[0][0] = GL_RGBA;
            plane_enums[0][1] = GL_RGBA;
            plane_enums[0][2] = GL_UNSIGNED_INT_8_8_8_8;
            _num_planes = 1;
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            plane_enums[0][0] = GL_RED;
            plane_enums[0][1] = GL_RED;
            plane_enums[0][2] = GL_UNSIGNED_BYTE;
            plane_enums[1][0] = GL_RG;
            plane_enums[1][1] = GL_RG;
            plane_enums[1][2] = GL_UNSIGNED_BYTE;
            _num_planes = 2;
            programName = @"420v";
            break;
        default:
            gl_format = GL_LUMINANCE;
            gl_internal_format = GL_LUMINANCE;
            gl_type = GL_UNSIGNED_BYTE;
            _num_planes = 1;
            break;
    }
    
    for(int t_idx = 0; t_idx < _num_planes; t_idx++)
    {
        
        glActiveTexture(GL_TEXTURE0+t_idx);
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTextures[t_idx]);
        
        glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, plane_enums[t_idx][1], (GLsizei)IOSurfaceGetWidthOfPlane(surface, t_idx), (GLsizei)IOSurfaceGetHeightOfPlane(surface, t_idx), plane_enums[t_idx][0], plane_enums[t_idx][2], surface, t_idx);
        
        
    }
    
    
    
    OpenGLProgram *shProgram = [_shaderPrograms objectForKey:programName];
    
    _programId = shProgram.gl_programName;
    
    
    glUseProgram(_programId);
    [self bindProgramTextures:shProgram];

}




-(BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    if (_updateOnDemand != self.isAsynchronous)
    {
        if (_can_count > 5)
        {
            super.asynchronous = _updateOnDemand;
            _can_count = 0;
        } else {
            _can_count++;
        }
    }
    
    return YES;
}


-(void) drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    
    
    
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    
    CIImageWrapper *wrappedImage;
    
    @synchronized(self)
    {
        wrappedImage = self.imageWrapper;
    }
    
    
    
    
    
    if (!wrappedImage)
    {
        return;
    }
    
    IOSurfaceRef useImage;
    
    useImage = wrappedImage.ioImage;
    
    if (!useImage)
    {
        return;
    }

    [self setupTextures:useImage withContext:ctx];

    NSRect imageExtent = NSMakeRect(0, 0, IOSurfaceGetWidth(useImage), IOSurfaceGetHeight(useImage));
    
    
    
    
    if (!NSEqualRects(imageExtent, _lastSurfaceSize))
    {
        [self calculateCrop:imageExtent];
    }
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    glOrtho(0.0, self.bounds.size.width, 0.0, self.bounds.size.height, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glTranslated(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5, 0.0);

    
    
    //I'm cheating here. Technically I should probably care about all the values of contentsGravity, but I know I don't want
    //the modes that don't involve resizing of some type. I don't want the layer to leak outside of the bounds of the superlayer
    //so all I'm doing here is Resize and ResizeAspect.
    
    GLfloat tex_coords[] =
    {
        _calculatedCrop.origin.x ,  _calculatedCrop.origin.y,
        _calculatedCrop.origin.x+_calculatedCrop.size.width, _calculatedCrop.origin.y,
        _calculatedCrop.origin.x+_calculatedCrop.size.width, _calculatedCrop.origin.y+_calculatedCrop.size.height,
        _calculatedCrop.origin.x,    _calculatedCrop.origin.y+_calculatedCrop.size.height
    };
    
    NSSize useSize = self.bounds.size;
    
    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        float wr = _calculatedCrop.size.width / self.bounds.size.width;
        float hr = _calculatedCrop.size.height / self.bounds.size.height;
        
        float ratio = (hr < wr ? wr : hr);
        useSize = NSMakeSize(_calculatedCrop.size.width / ratio, _calculatedCrop.size.height / ratio);
        
    }
    
    
    
    
    float halfw = useSize.width * 0.5;
    float halfh = useSize.height * 0.5;
    
    if (self.flipImage)
    {
        halfh *= -1;
    }
    
    
    GLfloat verts[] =
    {
        -halfw, halfh,
        halfw, halfh,
        halfw, -halfh,
        -halfw, -halfh
    };
    

    
    
    

    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    


    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    
    
}



-(CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    CGLContextObj currCtx = CGLGetCurrentContext();
    CGLContextObj contextObj = [super copyCGLContextForPixelFormat:pf];
    CGLSetCurrentContext(contextObj);
    glGenTextures(3, _previewTextures);
    [self createShaders];

    
    CGLSetCurrentContext(currCtx);
    
    
    return contextObj;
}


@end
