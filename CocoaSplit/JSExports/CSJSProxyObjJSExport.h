//
//  CSJSProxyObjJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 6/18/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


@protocol CSJSProxyObjJSExport <JSExport>
@property (strong) JSValue *jsObject;

@end
