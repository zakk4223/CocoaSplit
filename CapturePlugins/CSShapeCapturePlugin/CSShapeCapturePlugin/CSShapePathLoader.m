//
//  CSShapePathLoader.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 6/6/17.
//

#import "CSShapePathLoader.h"
#import "CSShapeWrapper.h"
#import <JavaScriptCore/JavaScriptCore.h>



@implementation CSShapePathLoader


-(void)evaluateJavascriptAtPath:(NSString *)path usingContext:(JSContext *)context
{
    
    
    NSString *scriptContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [context evaluateScript:scriptContents];
}



-(NSDictionary *)allPaths
{
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    NSArray *library_dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    NSMutableArray *plugin_dirs = [NSMutableArray array];
    
    for(NSString *libDir in library_dirs)
    {
    
        [plugin_dirs addObject:[NSString stringWithFormat:@"%@/%@", libDir, @"/Application Support/CocoaSplit/Plugins/Paths"]];
    }
    NSString *bundlePath = [NSBundle bundleForClass:self.class].resourcePath;
    
    [plugin_dirs addObject:[NSString stringWithFormat:@"%@/%@", bundlePath, @"/Paths"]];
    
    
    NSPredicate *jsFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.js'"];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    
    for (NSString *pPath in plugin_dirs)
    {
        NSArray *files = [fm contentsOfDirectoryAtPath:pPath error:nil];
        NSArray *scripts = [files filteredArrayUsingPredicate:jsFilter];
        
        for (NSString *scriptPath in scripts)
        {
            JSContext *jsCtx = [[JSContext alloc] init];
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", pPath, scriptPath];
            
            [self evaluateJavascriptAtPath:fullPath usingContext:jsCtx];
            if (jsCtx[@"name"])
            {
                JSValue *jName = jsCtx[@"name"];
                NSString *name = jName.toString;
                
                CSShapeWrapper *wrapper = [[CSShapeWrapper alloc] initWithName:name usingPath:fullPath];
                ret[name] = @{@"name": name, @"path":scriptPath, @"wrapper":wrapper};
                
            }
        }
        
    }
    return ret;
}

@end
