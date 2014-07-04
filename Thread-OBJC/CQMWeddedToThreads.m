//
//  CQMWeddedToThreads.m
//  Thread-OBJC
//
//  Created by mar Jinn on 7/2/14.
//  Copyright (c) 2014 mar Jinn. All rights reserved.
//

#import "CQMWeddedToThreads.h"

//-- POSIX Threads
#include <assert.h>
#include <pthread.h>

@implementation CQMWeddedToThreads

#pragma mark -
#pragma mark NSThread

-(void)NSThreads
{
    //Creating a thread
    //-----------------
    
    //--# Two types of threads
    //------------------------
    //---#1 Detached Threads eg: threads created by API'S
            //-- A detached thread means that the thread’s resources are
            //-- automatically reclaimed by the system when the thread exits.
            //-- It also means that your code does not have to join explicitly
            //-- with the thread later.
    //---#2 Non-Detached or joining threads eg: main thread
    
    //--# inherits default set of attributes
    //--------------------------------------
    
    //--# Two Ways to create thread using - NSThread class
    //----------------------------------------------------
    //---#1 Use the "detachNewThreadSelector:toTarget:withObject:" class method
            //--to spawn the new thread.
    //---#2 Create a "new NSThread object" and call its "start" method.
            //--(Supported only in iOS and OS X v10.5 and later.)
    
    //---#1 using "detachNewThreadSelector:toTarget:withObject:"
    //------------------------------------------------------------
    [NSThread detachNewThreadSelector:@selector(myThreadMainMethod:)
                             toTarget:(id)self
                           withObject:(id)@"detachNewThreadSelector"];
    
    //---#2 Create a "new NSThread object"
    //------------------------------------
     NSThread* myThread = nil;
     myThread =
    [[NSThread alloc] initWithTarget:(id)self
                            selector:@selector(myThreadMainMethod:)
                              object:(id)NSStringFromClass([self class])];
    
    //---#2 Start the thread - call its "start" method.
    //-------------------------------------------------
    [myThread start];
    
    //---#2 -- out of curiosity - set a name
    //--------------------------------------
    [myThread setName:@"thread_using_new_nsthread_obj"];
    
    
    
    //---#2 -- send messages to a thread
    //-------- performSelector:onThread:withObject:waitUntilDone:
    //-----------------------------------------------------------
    //-- If you have an NSThread object whose thread is currently running,
    //-- one way you can send messages to that thread is to use the
    //-- "performSelector:onThread:withObject:waitUntilDone:" method of
    //-- almost any
    //-- object in your application. Support for performing selectors on
    //-- threads (other than the main thread) was introduced in OS X v10.5
    //-- and is a convenient way to communicate between threads. (This
    //-- support is also available in iOS.) The messages you send using this
    //-- technique are executed directly by the other thread as part of its
    //-- normal run-loop processing. (Of course, this does mean that the
    //-- target thread has to be running in its run loop; see “Run Loops.”)
    //-- You may still need some form of synchronization when you
    //-- communicate this way, but it is simpler than setting up
    //-- communications ports between the threads.
    [self performSelector:@selector(newSelectorToBePerformed:)
                 onThread:myThread
               withObject:@"performSelector:(newSelectorToBePerformed:)" waitUntilDone:YES];
    
    // -- This results in a crash - if used withut RunLoop Logic
    // --- target thread exited while waiting for the perform
    // ------------------------------------------------------
    // -- Here is where runLoop is necessary to hold up the thread
    /*
    *** Terminating app due to uncaught exception 'NSDestinationInvalidException', reason: '*** -[CQMWeddedToThreads performSelector:onThread:withObject:waitUntilDone:modes:]: target thread exited while waiting for the perform'
    *** First throw call stack:
    (
     0   CoreFoundation                      0x00007fff941f925c __exceptionPreprocess + 172
     1   libobjc.A.dylib                     0x00007fff94e94e75 objc_exception_throw + 43
     2   CoreFoundation                      0x00007fff941f910c +[NSException raise:format:] + 204
     3   Foundation                          0x00007fff969a62e7 -[NSObject(NSThreadPerformAdditions) performSelector:onThread:withObject:waitUntilDone:modes:] + 854
     4   Foundation                          0x00007fff96a26186 -[NSObject(NSThreadPerformAdditions) performSelector:onThread:withObject:waitUntilDone:] + 122
     5   Thread-OBJC                         0x0000000100001b88 -[CQMWeddedToThreads NSThreads] + 376
     6   Thread-OBJC                         0x00000001000019ee callsToMain + 78
     7   Thread-OBJC                         0x00000001000018c5 main + 53
     8   libdyld.dylib                       0x00007fff96feb5fd start + 1
     9   ???                                 0x0000000000000001 0x0 + 1
     )
    libc++abi.dylib: terminating with uncaught exception of type NSException
     */
    // --
    
    
    //---#2 -- out of curiosity - Thread Local Storage
    //-- PRint the "threadDictionary" used as Thread Local Storage
    //------------------------------------------------------------
    NSLog(@"[[NSThread mainThread] threadDictionary] - %@",[[NSThread mainThread] threadDictionary]);
    
    NSLog(@"[myThread threadDictionary] - %@",[myThread threadDictionary]);
    
    //---#3 - Thread Priority - NS_DEPRECATED(10_6, 10_10, 4_0, 8_0);
    //-----------------------
    //-- The thread priority to use when executing the operation
    //-- The value in this property is a floating-point number
    //-- in the range 0.0 to 1.0, where 1.0 is the highest priority.
    //-- The default thread priority is 0.5.
    [myThread setThreadPriority:(double)0.6];
    
    return;
}


-(void)myThreadMainMethod:(NSString*) NameTable
{
    //---#2
    //---#2 RunLoop logic to make the thread wait - 20s -an arbitrary number
    //-------------------------------------------
    //-- RunLoop of the caller Thread
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeInterval:20.0 sinceDate:[NSDate date]]];

    @autoreleasepool
    {
        NS_DURING
        NSLog(@"%s",__PRETTY_FUNCTION__);
        NSLog(@"%@",NameTable);
        
        NS_HANDLER
        NSLog(@"%@",[localException name]);
        NSLog(@"%@",[localException reason]);
        NSLog(@"%@",[localException callStackSymbols]);
        
        @throw(localException);
        
        NS_ENDHANDLER
    }
    return;
}

-(void)newSelectorToBePerformed:(NSString*) whatever
{
    @autoreleasepool
    {
        NSLog(@"%s",__PRETTY_FUNCTION__);
        NSLog(@"%@",whatever);
    }

    return;
}


//-- THREAD - Handling Manual Termination
//-- Checking for an exit condition during a long job
//----------------------------------------
// -- Steps Involved
//-------------------
// -- #1 For long running jobs stopping work periodically
// -- #2 Checking to see if such a cancel or exit message arrive
// -- #3 If YES perform any needed cleanup and exit gracefully
// -- #4 otherwise, simply go back to work and process the next chunk of data.
// -- #5 One way to respond to cancel messages is to use a run loop input
// --    source to receive such messages.
// --    (The example shows the main loop portion only and does not include the
// --    steps for setting up an autorelease pool or configuring the actual
// --    work to do.)
// -- #6 The example installs a custom input source on the run loop that
// --    presumably can be messaged from another one of your threads;
// -- #7 After performing a portion of the total amount of work, the thread
// --    runs the run loop briefly to see if a message arrived on the input
// --    source.
// -- #8 If not, the run loop exits immediately and the loop continues with the
// --    next chunk of work.
// -- #9 Because the handler does not have direct access to the exitNow local
// --    variable, the exit condition is communicated through a key-value pair
// --    in the thread dictionary.


-(void)threadMainRoutine
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
        
        //-- Run the runloop but timeput immediatly
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
#pragma mark -
#pragma mark POSIX Thread

-(void)posiX
{
    LaunchThread();
    return;
}

void* PosiXThreadMainRoutine(void* data)
{
    printf("\n%s\n",__PRETTY_FUNCTION__);
    return NULL;
}

void LaunchThread(void)
{
    
    //-- Create a new thread using PosiX routines
    
    //-- thread attributes object
    pthread_attr_t  attr ;
    
    //-- thread
    pthread_t       posix_thread_ID;
    
    //-- status flag
    int             returnVal = 0;
    
    //-- Initialize a thread attributes object with default values.
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    
    //-- Set the detach state in a thread attributes object
    //-- PTHREAD_CREATE_JOINABLE - is the default value
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
    
    int threadError = 0;
    //-- Creates a new thread of execution.
    //-- returns error if unable to do so
    threadError =
    pthread_create((pthread_t *)&posix_thread_ID,/* reference to new thread */
                   (const pthread_attr_t *)&attr,/* attributes */
                   (void *(*)(void *))&PosiXThreadMainRoutine,/* func to run */
                   NULL)/* func arguments */;
    
    //-- set a unique name for a thread
    int threadNameSetStatus = 0;
    threadNameSetStatus =
    pthread_setname_np((const char *)"Thread_POSIX_Way");
    
    //-- Destroy a thread attributes object.
    returnVal = pthread_attr_destroy((pthread_attr_t *)&attr);
    assert(!returnVal);
    
    //-- Check if thread was created successfully
    if (threadError !=0 )
    {
        //Report an error while creating a thread
    }
    
    //-- set Thread Priority
    
    struct sched_param sched_param_po =
    { .sched_priority = 0 };

    pthread_setschedparam(pthread_self() /* get current thread */,
                          SCHED_OTHER,
                          (const struct sched_param *)&sched_param_po);
    
    
    return;
}
@end