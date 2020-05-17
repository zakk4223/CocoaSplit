//
//  CSNewTekNDIStreamService.m
//  CSNewTekNDIStreamServicePlugin
//
//  Created by Zakk on 1/21/18.
//

#import "CSNewTekNDIStreamService.h"
#import "CSNDIOutput.h"
#import "CSNewTekNDIStreamServiceViewController.h"

@implementation CSNewTekNDIStreamService

+(NSString *)label
{
    return @"NewTek NDI";
}




-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.sendName forKey:@"sendName"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.sendName = [aDecoder decodeObjectForKey:@"sendName"];
    }
    
    return self;
}

-(NSObject<CSOutputWriterProtocol> *)createOutput:(NSString *)layoutName
{
    return [[CSNDIOutput alloc] initWithName:self.sendName];
}


-(NSString *)getServiceDestination
{
    NSString *dest = self.sendName;
    if (!dest)
    {
        dest = @"COCOASPLIT";
    }
    return dest;
}

-(NSViewController *)getConfigurationView
{
    
     CSNewTekNDIStreamServiceViewController *configViewController;
    
    configViewController = [[CSNewTekNDIStreamServiceViewController alloc] initWithNibName:@"CSNewTekNDIStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}


@end
