//
//  main.m
//  Thread-OBJC
//
//  Created by mar Jinn on 7/2/14.
//  Copyright (c) 2014 mar Jinn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CQMWeddedToThreads.h"
#import "CQMTwistedRunLoop.h"
#import "CQMTwistedRunLoopTests.h"

 // from CQMWeddedToThreads.h
void callsToMain(void);

//CQMTwistedRunLoop.h
void callsToMainFromRunLoop(void);

//CQMTwistedRunLoopTests.h
void callsToMainFromRunLoopTests(void);

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        // insert code here...
        NSLog(@"Hello, World!");
        
        // from CQMWeddedToThreads.h
        (void) callsToMain();
        
        //CQMTwistedRunLoop.h
        (void) callsToMainFromRunLoop();
        
        //CQMTwistedRunLoopTests.h
        (void) callsToMainFromRunLoopTests();
        
        
        
        //-- MainRunLoop - run for 10 extra seconds
        //             - wait for secondary threads
        //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeInterval:10.0 sinceDate:[NSDate date]]];
        
        //-- Run indefinetly
        [[NSRunLoop currentRunLoop] run];

    }
    return 0;
}

//CQMWeddedToThreads.h
void callsToMain(void)
{
    CQMWeddedToThreads* weddedToThreads = [CQMWeddedToThreads new];
    //[weddedToThreads NSThreads];
    
    //[weddedToThreads posiX];
    
    weddedToThreads = nil;
}

//CQMTwistedRunLoop.h
void callsToMainFromRunLoop(void)
{
    CQMTwistedRunLoop* twistedRunloop = nil;
    twistedRunloop = [CQMTwistedRunLoop new];
    
    [twistedRunloop theThread];
    
    twistedRunloop = nil;
    return;
}

//CQMTwistedRunLoopTests.h
void callsToMainFromRunLoopTests(void)
{
    CQMTwistedRunLoopTests* twistedRunloopTests = nil;
    twistedRunloopTests = [CQMTwistedRunLoopTests new];
    
    twistedRunloopTests = nil;
    return;
}