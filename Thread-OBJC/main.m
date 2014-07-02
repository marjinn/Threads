//
//  main.m
//  Thread-OBJC
//
//  Created by mar Jinn on 7/2/14.
//  Copyright (c) 2014 mar Jinn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CQMWeddedToThreads.h"

void callsToMain(void);

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        // insert code here...
        NSLog(@"Hello, World!");
        
        callsToMain();
        
        ///MainRunLoop - run for 10 extra seconds
        //             - wait for secondary threads
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeInterval:10.0 sinceDate:[NSDate date]]];
        
        
        
    }
    return 0;
}

void callsToMain(void)
{
    CQMWeddedToThreads* weddedToThreads = [CQMWeddedToThreads new];
    //[weddedToThreads NSThreads];
    
    [weddedToThreads posiX];
}