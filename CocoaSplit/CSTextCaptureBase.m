//
//  CSTextSourceBase.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSTextCaptureBase.h"


#import "CSAbstractCaptureDevice.h"
#import "CSTextCaptureViewControllerBase.h"


@interface CSTextCaptureBase()
@property (strong) NSViewController *currentConfigController;
@end


@implementation CSTextCaptureBase

@synthesize text = _text;

-(instancetype)init
{
    if (self = [super init])
    {
        self.foregroundColor = [NSColor whiteColor];
        self.allowScaling = NO;
        self.needsSourceSelection = NO;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
        
        _font = [NSFont fontWithName:@"Helvetica" size:50];
        _fontAttributes = [NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        self.allowDedup = NO;
        self.alignmentMode = kCAAlignmentNatural;
    }
    
    return self;
}




-(CALayer *)createNewLayer
{
    CATextLayer *newLayer = [CATextLayer layer];
    newLayer.string = _attribString;
    
    newLayer.bounds = CGRectMake(0.0, 0.0, _attribString.size.width, _attribString.size.height);
    newLayer.alignmentMode = self.alignmentMode;
    newLayer.wrapped = self.wrapped;
    return newLayer;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    NSData *attrData = [NSKeyedArchiver archivedDataWithRootObject:self.fontAttributes];
    
    
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.font forKey:@"font"];
    [aCoder encodeObject:attrData forKey:@"fontAttributesData"];
    [aCoder encodeBool:self.wrapped forKey:@"wrapped"];
    [aCoder encodeObject:self.alignmentMode forKey:@"alignmentMode"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        
        if (!self.activeVideoDevice)
        {
            self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        }
        _text = [aDecoder decodeObjectForKey:@"text"];
        NSFont *savedFont = [aDecoder decodeObjectForKey:@"font"];
        if (savedFont)
        {
            _font = savedFont;
            
        }
        
        
        
        
        NSDictionary *savedfontAttributes = [aDecoder decodeObjectForKey:@"fontAttributes"];
        if (savedfontAttributes)
        {
            _fontAttributes = savedfontAttributes;
        } else {
            NSData *encodedAttrData = [aDecoder decodeObjectForKey:@"fontAttributesData"];
            if (encodedAttrData)
            {
                _fontAttributes = [NSKeyedUnarchiver unarchiveObjectWithData:encodedAttrData];
            }

        }
        
        _wrapped = [aDecoder decodeBoolForKey:@"wrapped"];
        _alignmentMode = [aDecoder decodeObjectForKey:@"alignmentMode"];
        
    }
    
    [self buildString];
    return self;
}


-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
}


-(NSImage *)libraryImage
{
    return [NSImage imageNamed:NSImageNameFontPanel];
}



-(void) buildString
{
    if (self.text)
    {
        
        self.activeVideoDevice.uniqueID = self.text;
        
        NSMutableDictionary *strAttrs = [NSMutableDictionary dictionaryWithDictionary:self.fontAttributes];
        strAttrs[NSFontAttributeName] = self.font;
        _attribString = [[NSAttributedString alloc] initWithString:self.text attributes:strAttrs];
        
        if ([self.alignmentMode isEqualToString:kCAAlignmentCenter] || [self.alignmentMode isEqualToString:kCAAlignmentRight])
        {
            self.allowScaling = YES;
        } else {
            self.allowScaling = NO;
        }

        
        [self updateLayersWithBlock:^(CALayer *layer) {
            layer.bounds = CGRectMake(0.0, 0.0, self->_attribString.size.width, self->_attribString.size.height);
            ((CATextLayer *)layer).string = self->_attribString;
            ((CATextLayer *)layer).alignmentMode = self.alignmentMode;
            ((CATextLayer *)layer).wrapped = self.wrapped;
        }];
        
        

    }
    
    
}
-(NSString *)text
{
    return _text;
}


-(void)setText:(NSString *)text
{
    
    if ([_text isEqualToString:text])
    {
        return;
    }
    _text = text;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.captureName = text;

    });
    
    
    
    [self buildString];
}


+(NSString *)label
{
    return @"Text";
}

-(NSViewController *)configurationView
{
    
    NSViewController *configViewController;
    CSTextCaptureViewControllerBase *returnViewController;
    
    NSString *controllerName = @"CSTextCaptureViewControllerBase";
    
    
    
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        
        returnViewController = [[viewClass alloc] initWithNibName:@"CSTextCaptureBaseView" bundle:[NSBundle mainBundle]];
        
        if (returnViewController)
        {
            
            returnViewController.view.hidden = NO;
            
            
            
            //Should probably make a base class for view controllers and put captureObj there
            //but for now be gross.
            [returnViewController setValue:self forKey:@"captureObj"];
        }
    }
    
    //Now load the plugin's provided controller and view and attach the view to ours
    
    controllerName = self.configurationViewClassName;
    
    viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        configViewController = [[viewClass alloc] initWithNibName:self.configurationViewName bundle:[NSBundle bundleForClass:self.class]];
        
        if (configViewController)
        {
            configViewController.view.hidden = NO;
            
            [configViewController setValue:self forKey:@"captureObj"];
        }

        self.currentConfigController  = configViewController;
        
    }
    
    
    
    
    
    CSTextCaptureViewControllerBase *vcont = (CSTextCaptureViewControllerBase *)returnViewController;
    
    

    //[vcont.view setBoundsSize:NSMakeSize(vcont.view.bounds.size.width, configViewController.view.bounds.size.height + vcont.sourceConfigView.bounds.size.height)];
    
    [[vcont.view animator] addSubview:configViewController.view];
    NSRect newFrame = configViewController.view.frame;

   [configViewController.view setFrameOrigin:NSMakePoint(newFrame.origin.x, NSMaxY(vcont.view.frame) - newFrame.size.height)];
    
    
    
    
    
    [[vcont.view animator] addSubview:vcont.sourceConfigView];
    
    [vcont.sourceConfigView setFrameOrigin:NSMakePoint(vcont.sourceConfigView.frame.origin.x, configViewController.view.frame.origin.y - vcont.sourceConfigView.bounds.size.height)];
    
    
    
    
    return returnViewController;
    
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"font", @"fontAttributes", @"alignmentMode", @"wrapped",nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self buildString];
    }
    
}


@end

