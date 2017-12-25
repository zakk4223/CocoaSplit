//
//  CSJSProxyObj.h
//  CocoaSplit
//
//  Created by Zakk on 6/18/17.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "CSJSProxyObjJSExport.h"

@interface CSJSProxyObj : NSObject <CSJSProxyObjJSExport>
{
    JSManagedValue *_managedObject;
}

@property (strong) JSValue *jsObject;


@end
