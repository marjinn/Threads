//
//  CQMTwistedRunLoops.m
//  Thread-OBJC
//
//  Created by mar Jinn on 7/2/14.
//  Copyright (c) 2014 mar Jinn. All rights reserved.
//


#import "CQMTwistedRunLoop.h"
//-- RunLoops --//
//--------------//
/*
 //-- THEORY --//
 //--------------
 //-- #1. a loop that a thread enters and uses to run event handlers in 
          response to incoming events
 //-- #2. User code will provide "control statements" used to implement
          the actual loop portion of the run loop -- i.e. the user code 
            provides the "for" or "while" loop that drives the run loop.
 //-- #3. Within the loop user uses a RunLoop object to "run" the event
          processing code that recieves events and calls the installed
          handlers
 4. A run loop can recieve events from (2(primarily)) 3 different sources
 a. Input Sources
    -------------
    - delivers asynchronous events,messages from another thread or
        from a different application
    - delivers asynchronous events to the corresponding handlers and
        cause "runUntillDate:" method
        (called on thread's associated RunLoop object)
        to exit.
 
 b. Timer Sources
    -------------
    - deliver synchronous events
      occuring at scheduled time or repeated intervals
    - also deliver events to their handler routines but do not cause 
        the runloop to exit
 
 c. Cocoa Perform Selector Sources
    ------------------------------
 
 All Sources use Application specific routines to process the event
 when it arrives
 
 //-- # "Run Loop Observers"
 //--------------------------
 5. Run loops also generate notifications about its behaviour.
 6. Registered runloop observers can recieve this notifications and 
    use them to do aadditional processing on the thread
 7. Core Foundation is used to install run-loop observers
 
 8. Run Loop Modes
    --------------
    a. A run lopp mode is a collection of 
            1. runloop sources (input and timer) to be monitored
            2. runloop event observers to be notified
    b. Each time you run the run lopp you specify a perticluar "mode"
        in which to run
    c. Only Sources associated with that mode are monitored and allowed to 
        deliver events
    d. Only observers associated with that mode are notified of the 
        runloop's progress
    e. Sources associated with other modes hold on to any new events 
        until subsequent passes through the loop in the appropriate mode.
    f. Modes are identified by name
    g. Cocoa and Core Foundation define a "default mode" and
        several "commonly used modes", along with
        strings for specifying those modes in your code.
    
    //-- Custom Modes
    -----------------
    h. Custom modes are specified by a custom string for mode name
    i. one or more input sources or/and run-loop observers should be
        added to custom modes for them to be useful.
    j. For secondary-thraeds, you might use custom modes to prevent
        low-priority sources from delivering events
        during time critical operations
 
    k. Modes are used to filter out events from unwanted sources.
    l. Modes discriminate based on "Source of the event" rather
        than "Type of the event".
        eg.:- 
                1. you would not use modes to match only 
                    mouse-down events or only keyboard events.
                2. You could use modes to listen to a different set of
                    ports, suspend timers temporarily, or 
                    otherwise change the sources and 
                    run loop observers currently being monitored.
 
 
 9. List of the standard modes defined by Cocoa and Core Foundation
    ----------------------------------------------------------------

 Mode.:-        Default
 Name.:-        NSDefaultRunLoopMode (Cocoa)
                kCFRunLoopDefaultMode (Core Foundation)
 Description.:- The default mode is the one used for most operations.
                Most of the time, you should use this mode 
                to start your run loop and configure your input sources.
 
 Mode.:-        Connection
 Name.:-        NSConnectionReplyMode (Cocoa)
 Description.:- Cocoa uses this mode in conjunction with NSConnection objects
                to monitor replies. 
                You should rarely need to use this mode yourself.
 
 Mode.:-        Modal
 Name.:-        NSModalPanelRunLoopMode (Cocoa)
 Description.:- Cocoa uses this mode to identify 
                events intended for modal panels.
 
 Mode.:-        Event tracking
 Name.:-        NSEventTrackingRunLoopMode (Cocoa)
 Description.:- Cocoa uses this mode to restrict incoming events during 
                mouse-dragging loops and other sorts of 
                user interface tracking loops.
 
 Mode.:-        Common modes
 Name.:-        NSRunLoopCommonModes (Cocoa)
                kCFRunLoopCommonModes (Core Foundation)
 Description.:- This is a configurable group of commonly used modes.
                Associating an input source with this mode also associates 
                it with each of the modes in the group. 
                For Cocoa applications, this set includes 
                        1. default,
                        2. modal, and
                        3. event tracking modes by default.
                Core Foundation includes 
                        1. just the default mode initially.
                You can add custom modes to the set using the
                "CFRunLoopAddCommonMode" function.
 
 
 10. Input Sources - In detail
     -------------------------
 a. Deliver asynchronous events to your threads.
 b. Source of the event depends on type of the input source.
 c. Input source types fall under 2 categories.
    1. Port-Based Sources
       ------------------
        - monitor application's Mach ports.
        - signaled automatically bt the kernel.
        - Creating a port-based source
            - Cocoa
                - built-in support for creating port-based input sources
                - you never create an input source directly.
                - create a "port" object an use methods of "NSPort" class
                    to add that port to the run loop.
                - the "port" ibject handles the creation and configuration of 
                    the needed input sources for you.
            - Core Foundation
                - manually create both port and its run loop source
                - functions associated with the port opaque type
                    - CFMacPortRef
                    - CFMessagePortRef
                    - CFSocketRef
                   to create the appropriate objects.
    2. Custom Input Sources
        -------------------
        - monitor custom event sources
        - signaled manually from another thread.
        - Creating a cutom input source
            - Cocoa 
                - no support
            - Core Foundation
                - use the functions associated with the opaque type 
                    "CFRunLoopSourceRef"
                - to configure a custom input source several 
                    call-back functions are used
                - CF calls these call-back functions at different points to
                    - configure the source
                    - handle any incoming events
                    - tear down a source when it is removed form the runloop
 
 
 
 d. When you create an input source ,
    you assign it to one or more modes of your run loop.
 e. Modes affect which input sources are monitored at any given moment.
 f. If an input source is not in the currently monitored mode,
    any event it generates are held until the runlopp runs in correct mode.
 
 
 
 
 */


@implementation CQMTwistedRunLoop

-(void)threadMainRoutineSampleRunLoop
{
    BOOL moreWorkToDo =  YES;
    BOOL exitNow      =  NO;
    
    NSRunLoop* runLoop = nil;
    runLoop = [NSRunLoop currentRunLoop];
    
    //-- Add the exit now BOOL to the thread local storage dictionary
    NSMutableDictionary* threadDict = nil;
    threadDict = [[NSThread currentThread] threadDictionary];
    [threadDict setValue:[NSNumber numberWithBool:exitNow]
                  forKey:@"ThreadShouldExitNow"];
    
    //-- Install Custom Input source
    [self myInstallCustomInputSource];
    
    while (moreWorkToDo && !exitNow)
    {
        //-- Do one chunk of larger body of work here
        //-- Change the value of the "moreWorkToDo" Boolean when done
        
        //-- Run the runloop but timeout immediatly,
        //-- if the input source isn't waiting to fire
        [runLoop runUntilDate:[NSDate date]];
        
        //Check to see if the inputSource Handler changed the exitNow value.
        exitNow =
        [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
    }
    
    return;
}

-(void)myInstallCustomInputSource
{
    return;
}

@end
