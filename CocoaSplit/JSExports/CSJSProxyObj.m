//
//  CSJSProxyObj.m
//  CocoaSplit
//
//  Created by Zakk on 6/18/17.
//

#import "CSJSProxyObj.h"

//Inspired by FMBridgeJSOC (https://github.com/acekiller/FMBridgeJSOC/)

#define ISARGUMENTTYPE(T,V) (*V == *@encode(T))

@implementation CSJSProxyObj

@synthesize jsObject = _jsObject;



-(void)setJsObject:(JSValue *)jsObject
{

    
    _jsObject = jsObject;
    
    //_managedObject = [JSManagedValue managedValueWithValue:jsObject];
    
    
    //[_managedObject.value.context.virtualMachine addManagedReference:_managedObject withOwner:self];
}


-(JSValue *)jsObject
{
    return _jsObject;
}



-(NSArray *)argumentListForInvocation:(NSInvocation *)invocation
{
    NSMethodSignature *signature = invocation.methodSignature;
    NSMutableArray *argArray = [NSMutableArray array];
    
    //we don't care about 0 and 1, objc internal
    
    
    for (int idx = 2; idx < signature.numberOfArguments; idx++)
    {
        const char *aType = [signature getArgumentTypeAtIndex:idx];
        if (ISARGUMENTTYPE(BOOL, aType))
        {
            BOOL tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
            NSLog(@"BOOL ARG IS %hhd", tmp);
            
        } else if (ISARGUMENTTYPE(char, aType)) {
            char tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(unsigned char, aType)) {
            unsigned char tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(short, aType)) {
            short tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(unsigned short, aType)) {
            unsigned short tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(int, aType)) {
            int tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(unsigned int, aType)) {
            unsigned int tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];

        } else if (ISARGUMENTTYPE(long, aType)) {
            long tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];

        } else if (ISARGUMENTTYPE(unsigned long, aType)) {
            unsigned long tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];

        } else if (ISARGUMENTTYPE(long long, aType)) {
            long long tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(unsigned long long, aType)) {
            unsigned long long tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];
        } else if (ISARGUMENTTYPE(double, aType)) {
            double tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];

        } else if (ISARGUMENTTYPE(float, aType)) {
            float tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:@(tmp)];

        } else if (ISARGUMENTTYPE(id, aType)) {
            id tmp;
            [invocation getArgument:&tmp atIndex:idx];
            [argArray addObject:tmp];
            NSLog(@"TMP IS %@", tmp);

        } else {
        
            NSLog(@"UNSUPPORTED TYPE");
            [argArray addObject:@(0)];
        }
    }
    
    return argArray;
}


-(NSString *)mangleName:(NSString *)name
{
    NSArray *selParts = [name componentsSeparatedByString:@":"];
    
    NSMutableString *jsFunction = [NSMutableString string];
    
    [selParts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *partString = (NSString *)obj;
        
        if (idx == 0)
        {
            [jsFunction appendString:partString];
        } else {
            [jsFunction appendString:partString.capitalizedString];
        }
    }];

    return jsFunction;
}


-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if (self.jsObject)
    {
        NSString *selName = [NSString stringWithUTF8String:sel_getName(aSelector)];
        
        NSString *jsFunction = [self mangleName:selName];
        NSString *jsSignature = [NSString stringWithFormat:@"%@_signature", jsFunction];
        
        if (self.jsObject[jsSignature].isString)
        {
            NSString *realSig = self.jsObject[jsSignature].toString;
            NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:realSig.UTF8String];
            return sig;
        }

    }
    
    return [NSMethodSignature signatureWithObjCTypes:"v@:v"];
}


-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    if (self.jsObject)
    {
        
        NSString *selName = [NSString stringWithUTF8String:sel_getName(anInvocation.selector)];
        
        NSString *jsFunction = [self mangleName:selName];
        
        NSLog(@"CALL JSFUNCTION %@", jsFunction);
        if (!self.jsObject[jsFunction].isUndefined)
        {
            NSArray *argArray = [self argumentListForInvocation:anInvocation];
            [self.jsObject[jsFunction] callWithArguments:argArray];
        }
    }
}


-(BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector])
    {
        return YES;
    }
    
    if (!self.jsObject)
    {
        return NO;
    }
    
    NSString *selName = [NSString stringWithUTF8String:sel_getName(aSelector)];
    
    
    
    NSString *jsFunction = [self mangleName:selName];
    
    if (!self.jsObject[jsFunction].isUndefined)
    {
        NSLog(@"DID IMPLEMENT");
        return YES;
    }
    
    return NO;
    
}

/*
-(void)dealloc
{
    if (_managedObject)
    {
        [_managedObject.value.context.virtualMachine removeManagedReference:_managedObject withOwner:self];
    }
}*/
@end


