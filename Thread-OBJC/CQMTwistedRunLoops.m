//
//  CQMTwistedRunLoops.m
//  Thread-OBJC
//
//  Created by mar Jinn on 7/2/14.
//  Copyright (c) 2014 mar Jinn. All rights reserved.
//


#import "CQMTwistedRunLoop.h"
#import "AppDelegate.h"

@import CoreFoundation;

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
 
 
 Both Sources use Application specific routines to process the event
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
 j. For secondary-threads, you might use custom modes to prevent
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
 - signaled automatically by the kernel.
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
 - we define both
 - behavior of the custom source
 - (described above)
 - event delivery mechanism
 - runs on separate thread
 - is responsible for providing the input source with
 its data
 - signaling the input source when
 that data is ready for processing
 
 3. Cocoa Perform Selector Sources
 -------------------------------
 - Cocoa defined custom input source.
 - removes itself from runloop after it performs its selector
 - the target thread must have an active run loop
 - for ( secondary) threads we create, it means waiting until our
 code explicitly
 starts the runloop
 - main thread starts its on runloop, so we can begin issuing calls on
 the "main thread" as soon as application calls
 "applicationDidFinishLaunching:" method of application delegate.
 - "runloop processes all queued perform selector calls
 each time through the loop ,rather than processing one during
 each iteration"
 - can be used on POSIX threads as well
 - declared on NSObject
 - These methods do not create a new thread to perform a selector
 
 
 d. When you create an input source ,
 you assign it to one or more modes of your run loop.
 e. Modes affect which input sources are monitored at any given moment.
 f. If an input source is not in the currently monitored mode,
 any event it generates are held until the runlopp runs in correct mode.
 
 //-- Performing selectors on other threads
 -------------------------------------------
 
 Methods.:-     performSelectorOnMainThread:withObject:waitUntilDone:
 performSelectorOnMainThread:withObject:waitUntilDone:modes:
 Description.:-
 Performs the specified selector on the application’s
 main thread during that thread’s next run loop cycle.
 These methods give you the option of blocking the current
 thread until the selector is performed.
 
 Methods.:-     performSelector:onThread:withObject:waitUntilDone:
 performSelector:onThread:withObject:waitUntilDone:modes:
 Description.:-
 Performs the specified selector on any thread for which you
 have an NSThread object.
 These methods give you the option of blocking the current
 thread until the selector is performed.
 
 Methods.:-     performSelector:withObject:afterDelay:
 performSelector:withObject:afterDelay:inModes:
 Description.:-
 Performs the specified selector on the current thread during
 the next run loop cycle and after an optional delay period.
 Because it waits until the next run loop cycle to perform the
 selector, these methods provide an automatic mini delay from
 the currently executing code.
 Multiple queued selectors are performed one after another in
 the order they were queued.
 
 Methods.:-     cancelPreviousPerformRequestsWithTarget:
 cancelPreviousPerformRequestsWithTarget:selector:object:
 Description.:-
 Lets you cancel a message sent to the current thread using the
 performSelector:withObject:afterDelay: or
 performSelector:withObject:afterDelay:inModes: method.
 
 11. Timer Sources - In detail
 -----------------------------
 a. delivers evenst asynchronously to your threads at apreset time in future
 b. eg.:-
 - Timers are a way for a thread to notify itself to do something.
 - For example, a search field could use a timer to initiate an
 automatic search once a certain amount of time has passed
 between successive key strokes from the user. The use of
 this delay time gives the user a chance to type as much of
 the desired search string
 as possible before beginning the search.
 c. timers are associated with specific modes of your run loop
 d. If a timer is not in the mode currently being monitored by the run loop,
 it does not fire until you run the run loop in one of the timer’s
 supported modes.
 
 e.  if a timer fires when the run loop is in the middle of executing a
 handler routine, the timer waits until the next time through the run
 loop to invoke its handler routine.
 f.  If the run loop is not running at all,the timer never fires.
 h. Repeated Timers
 --------------
 - repeated timers recshedule itself automatically based on
 scheduled firing time
 - if a timer is scheduled to fire at a particular time and
 every 5 seconds after that, the scheduled firing time will
 always fall on the original 5 second time intervals, even if
 the actual firing time gets delayed.
 - if the firing time is delayed so much that
 it misses one or more of the scheduled firing times,
 the timer is fired only once for the missing time period
 - after firing for the missing time period,
 the timer is rescheduled for the next scheduled firing time
 
 12. RunLoop Observers - In detail
 ----------------------------------
 a. fire at special locations at the execution of the run loop itself.
 b. can be used to
 - prepare the thread to process a given event
 - prepare the thread before it goes to sleep
 - and the like.
 c. List of events you can associate run lopp obesrvers with
 
 -- Entrance of run loop notification
 ---------------------------------------
 1. the "entrance of the run loop"
 
 -- about to process a timer notification
 ------------------------------------------
 2. When the run loop is "about to process a timer".
 
 -- About to process an input source notification
 --------------------------------------------------
 3. When the run loop is "about to process an input source".
 
 -- About to go to sleep notification
 ---------------------------------------
 4. When the run loop is "about to go to sleep".
 
 -- Run loop has been woken up notification
 -------------------------------------------
 5. When the run lopp has been woken up,but before it has processed
 the event that woke it up.
 
 -- exit from the runloop notification
 ---------------------------------------
 6. The exit from the runloop.
 
 d. run-loop observers are added using Core Foundation
 e. To create a run-loop observer, you create a new instnce of the
 "CFRunLoopObserverRef" opaque type
 f.  This type keeps track of
 - your custom callback functions
 - the activities in which it is intersted in
 g. run-lopp observers are of 2 types
 1. one-shot observers
 - removes itself from the runlopp
 after it fires
 2. repeating observers
 - remain attached as they are run
 repeatedly.
 13. Run Loop - Sequence of Events
 ---------------------------------
 a. Each time you run it, your thread’s run loop processes pending events
 and generates notifications for any attached observers.
 The order in which it does this is very specific and is as follows:
 
 NOTIFY Functions
 ----------------
 1. Notify observers that the run loop has been entered.
 2. Notify observers that any ready timers are about to fire.
 3. Notify observers that any input sources that are
 not port based are about to fire.
 
 4. Fire any non-port-based input sources that are ready to fire.
 5. If a port-based input source is ready and waiting to fire,
 process the event immediately. Go to step 9.
 
 NOTIFY Functions
 ----------------
 6. Notify observers that the thread is about to sleep.
 
 7. Put the thread to sleep until one of the following events
 occurs:
 a. An event arrives for a port-based input source.
 b. A timer fires.
 c. The timeout value set for the run loop expires.
 d. The run loop is explicitly woken up.
 
 NOTIFY Functions
 ----------------
 8. Notify observers that the thread just woke up.
 
 9. Process the pending event.
 a. If a user-defined timer fired, process the timer event and
 restart the loop. Go to step 2.
 b. If an input source fired, deliver the event.
 c. If the run loop was explicitly woken up but has not yet
 timed out, restart the loop. Go to step 2.
 
 NOTIFY Functions
 ----------------
 10. Notify observers that the run loop has exited.
 
 b. Special behaviour
 ---------------------
 1. Since observer notifications for timer and input sources are delivered
 before those events actually occur, there may be  a "gap between the time
 of the notifications and the time of actual events".
 2. Time critical Events
 --------------------
 - for events where timing between the events is critical ,
 you can use the "sleep" and "wake up from sleep" notifications
 to help correlate the time between the actual events
 3. Events causing the run loop to wake up
 - explicit wake up using run loop object
 - adding another non-port based input source
 (will be processed immediatly)
 
 14. WHEN WOULD YOU USE A RUN LOOP
 ---------------------------------
 - The only time you need to run a run loop explicitly is
 when you create secondary threads for your application
 - You need to start a run loop if you plan to do any of the following:
 
 1. Use ports or custom input sources to communicate with other threads.
 2. Use timers on the thread.
 3. Use any of the performSelector… methods in a Cocoa application.
 4. Keep the thread around to perform periodic tasks.
 
 15. Using Run Loop Objects
 ---------------------------
 a. provides the main interface for adding
 1. input sources,
 2. timers and
 3. run-loop observers
 and the running it
 b. Evert thread has a single runLoop object
 c. Cocoa
 - NSRunLoop
 
 Core Foundation
 - CFRunLoopRef
 
 16. Getting the run loop object
 --------------------------------
 a. Cocoa
 - to retrieve an NSRunLoop object
 [NSRunLoop currentRunLoop]
 
 - to get CFRunLoopRef
 [[NSRunLoop currentRunLoop] getCFRunLoop]
 
 
 b. CoreFoundation
 - to retrieve CFRunLoopRef
 CFRunLoopGetCurrent()
 
 17. Configuring the runLoop
 ---------------------------
 1. Before you run a run loop on a secondary thread you must add
 atleast one input source or timer to it.
 2. If a run loop does not have any sources to monitor,
 it exits immediately when you try to run it.
 3. In addition to installing sources, you can also install
 run loop observers and use them
 to detect different execution stages of the run loop.
 - To install a run loop observer
 ---------------------------
 - you create a CFRunLoopObserverRef opaque type and
 use the CFRunLoopAddObserver function to add it
 to your run loop.
 - Run loop observers must be created using
 Core Foundation, even for Cocoa applications.
 
 18. Example "threadMain"
 -------------------------
 - shows adding runloop observer for all runloopactvities
 
 Caveats of timer based apparoach
 --------------------------------
 -- When configuring the run loop for a long-lived thread,
 it is better to add at least one input source to receive messages.
 -- Although you can enter the run loop with only a timer attached,
 once the timer fires,
 it is typically invalidated,
 which would then cause the run loop to exit.
 -- Attaching a repeating timer could keep the run loop running over a
 longer period of time,
 but would involve firing the timer
 periodically to wake your thread,
 which is effectively another form of polling.
 -- By contrast, an input source waits for an event to happen,
 keeping your thread asleep until it does.
 
 19. Starting The RunLoop
 ------------------------
 1. is necessary only for secondary threads
 2. A runLoop must have atleast one input source or timer to monitor
 3. if no sources are attached the runLoop exist immediatly.
 4. Some of the ways to start a RunLoop are .:-
 a. Unconditionally
 - simplest option,but lesat desirable
 - puts the thread into a permanent loop
 - gives you very little control
 - can add and remove input sources and timers ,but the only
 way to stop the runLoop will be to kill the loop.
 - there is no way to run the loop in custom mode.
 b. With a set time limit
 - better to run the runLoop with a timeout value.
 - runLoop runs unitil an event arrives or the alotted
 time expires.
 - If an event arrives, that event is dispathched to a
 handler for processing and the runLoop Exits
 - Code can then restart the run loop to handle the next
 event.
 - If the allotted time expires, you can simply restart the
 runLoop or do some houseKeeping.
 c. In a particular mode
 - Modes and time outs can be used together
 - modes limit the types of sources that deliver events
 to the runLoop.
 eg.:-
 - a skeleton version of a thread’s main entry routine.
 - The key portion of this example shows the basic
 structure of a run loop.
 - In essence, you add your input sources and timers to the
 run loop and then repeatedly call one of the routines
 to start the  run loop.
 - Each time the run loop routine returns, you check
 to see if any conditions have arisen that might warrant
 exiting the thread.
 - The example uses the Core Foundation run loop routines
 so that it can check the return result and
 determine why the run loop exited.
 
 20. Nested RunLoop Calls
 ------------------------
 1. It is possible to run runLoop recursively
 2. You can call CFRunLoopRun, CFRunLoopRunInMode, or any of the NSRunLoop
 methods for starting the run loop
 from within the handler routine of an input source or timer.
 3. you can use any mode you want to run the nested run loop,
 including the mode in use by the outer run loop
 4. Run loops can be run recursively.
 - You can call CFRunLoopRunInMode from within any run loop callout
 and create nested run loop activations on the
 current thread’s call stack.
 - You are not restricted in which modes you can run from within a
 callout.
 - You can create another run loop activation running in any available
 run loop mode, including any modes
 already running higher in the call stack.
 
 5. The run loop exits with the following return values under
 the indicated conditions:
 - kCFRunLoopRunFinished.
 The run loop mode mode has no sources or timers.
 - kCFRunLoopRunStopped.
 The run loop was stopped with CFRunLoopStop.
 - kCFRunLoopRunTimedOut.
 The time interval seconds passed.
 - kCFRunLoopRunHandledSource.
 A source was processed.
 This exit condition only applies when
 returnAfterSourceHandled is true.
 6. You must not specify the kCFRunLoopCommonModes constant for the mode
 parameter.
 Run loops always run in a specific mode.
 7.  You specify the common modes only
 - when configuring a run-loop observer and
 - only in situations where you want that observer to
 run in more than one mode
 
 21. Exiting a Run Loop
 -----------------------
 1. Two ways
 a. Configure the runLoop to run  with a timeOut Value
 - Specifying a timeout value lets
 the run loop finish all of its normal processing,
 including delivering notifications to run loop observers,
 before exiting.
 b. Tell the runLoop to stop.
 - Use CFRunLoopStop("runLoop")
 - The run loop sends out any remaining run-loop notifications
 and then exits.
 - The difference is that you can use this technique on
 run loops you started unconditionally.
 
 # Although removing a run loop’s input sources and timers may also
 cause the run loop to exit,
 this is not a reliable way to stop a run loop.
 # Some system routines add input sources to a run loop to handle needed
 events.
 # Because your code might not be aware of these input sources,
 it would be unable to remove them, which would prevent the
 run loop from exiting.
 
 
 22. Thread Safety
 ------------------
 
 1. Thread safety varies depending on which API you are using
 to manipulate your run loop.
 2. The functions in "Core Foundation" are generally "thread-safe"
 and can be called from any thread.
 3. If you are performing operations that alter the configuration of the run
 loop, however, it is still good practice to do so
 from the thread that owns the run loop whenever possible.
 
 4. The Cocoa NSRunLoop class is not as inherently thread safe as its Core
 Foundation counterpart.
 5.  If you are using the NSRunLoop class to modify your run loop,
 you should do so only from the same thread that owns that run loop.
 6.  Adding an input source or timer to a run loop belonging to a different
 thread could cause your code to crash or behave in an unexpected way.
 
 
 Key Summary
 -----------
 -- Core foundation runloop PAi thread-safe
 -- Cocoa Run loop apis - not threadsafe
 -- always better to alter runloop behaviour from the owner thread
 -- includes adding an input source or timer
 
 
 
 23. Configuring Input Sources
 -----------------------------
 
 1. Defining a custom Input Source
 ---------------------------------
 Creating a  custom input source involves defining the following
 a. The information you want your input source to process
 b. A scheduler routine to let interetsed clients
 know how to contact your input source.
 c. A handler routine to perform requests sent by any clients
 d. A cancellation routine to inavlidate your input source.
 
 a sample configuration of a custom input source.
 --------------------------------------------------
 
 Main Thread                                 Worker thread
 
 ^---->                                         ^---->v
 |    |      ------                             |    |            -------------
 ^    v---> | TASK |                            ^    v <---------|Input Source |
 |    |      ------                             |    |            -------------
 ^    v                                         ^    V            ^  ^  ^
 |    |              -------------------------> |    |            |  |  |
 ^    v             |                           ^    v    --------|  |  |
 |    |             |                           |    |    |   |------|  |
 ^    v             |                           ^<---v    |   |         |
 |<---|             |           Wake up                   |   |         |
 |     |-------------------------------|   |         |
 |     |          Signal Source            |         |
 runloop source -------------------------------|         |
 Send Command                            V
 Command data ----------------------------------->Command Buffer
 
 In this example,
 1. the application’s main thread maintains references to the input source,
 the custom command buffer for that input source,
 and the run loop on which the input source is installed.
 2. When the main thread has a task it wants to hand off to the worker
 thread, it posts a command to the command buffer along with any
 information needed by the worker thread to start the task.
 (Because both the main thread and the input source of the
 worker thread have access to the command buffer,
 that access must be synchronized.)
 3. Once the command is posted, the main thread signals
 the input source and wakes up the worker thread’s run loop.
 4. Upon receiving the wake up command, the run loop calls
 the handler for the input source, which processes
 the commands found in the command buffer.
 
 TASK 1 . Defining The Input Source
 ----------------------------------
 
 - The input source introduced uses an Objective-C object to manage a command
 buffer and coordinate with the run loop.
 - Also shows the definition of this object.
 - The RunLoopSource object manages a command buffer
 and uses that buffer to receive messages from other threads.
 - This listing also shows the definition of the RunLoopContext object,
 which is really just a container object used to
 pass a RunLoopSource object and a run loop reference
 to the application’s main thread
 
 - Although the Objective-C code manages the custom data of the input source,
 attaching the input source to a run loop requires C-based callback
 functions.
 - The first of these functions is called when you actually attach(schedule)
 the run loop source to your run loop,
 - Because this input source has only one client (the main thread),
 it uses the scheduler function to send a message
 to register itself with the application delegate on that thread.
 - When the delegate wants to communicate with the input source,
 it uses the information in RunLoopContext object to do so.
 - One of the most important callback routines is
 the one used to process custom data when your input source is signaled.
 - "example" function forwards the request to do the work to "sourceFired"
 method, which then processes any commands present in the command buffer.
 - if you remove your input source from its run loop using
 the "CFRunLoopSourceInvalidate()" function,the ystem calls your
 input source's cancellation routine.
 - You can use this routine to notify clients that the input source
 is no longer and that theys should remove any references to it.
 - "example" This function sends another RunLoopContext object to
 the application delegate, but this time asks the delegate to
 remove references to the run loop source.
 
 TASK 2 . Installing the input source on the Run loop
 ----------------------------------------------------
 1. The init method creates the CFRunLoopSourceRef opaque type
 that must actually be attached to the run loop.
 2. It passes the RunLoopSource object itself as the contextual information
 so that the callback routines have a pointer to the object.
 3. Installation of the input source does not occur until
 the worker thread invokes the addToCurrentRunLoop method,
 at which point the RunLoopSourceScheduleRoutine callback function
 is called.
 4. Once the input source is added to the run loop,
 the thread can run its run loop to wait on it.
 
 
 TASK 2 . Coordinating with Clients of the Input Source
 ------------------------------------------------------
 */


#pragma mark -
#pragma mark Custom input source object definition
#pragma mark -



@implementation RunLoopSource


-(instancetype)init
{
    /*
     typedef struct {
     CFIndex	version;
     void *	info;
     const void *(*retain)(const void *info);
     void	(*release)(const void *info);
     CFStringRef	(*copyDescription)(const void *info);
     Boolean	(*equal)(const void *info1, const void *info2);
     CFHashCode	(*hash)(const void *info);
     void	(*schedule)(void *info, CFRunLoopRef rl, CFStringRef mode);
     void	(*cancel)(void *info, CFRunLoopRef rl, CFStringRef mode);
     void	(*perform)(void *info);
     } CFRunLoopSourceContext;
     */
    CFRunLoopSourceContext context;
    context.version             = 0;
    context.info                = (__bridge void *)self;
    context.retain              = NULL;
    context.release             = NULL;
    context.copyDescription     = NULL;
    context.equal               = NULL;
    context.hash                = NULL;
    context.schedule            = &RunLoopSourceScheduleRoutine;
    context.cancel              = &RunLoopSourceCancelRoutine;
    context.perform             = &RunLoopSourcePerformRoutine;
    
    /*
     CF_EXPORT CFRunLoopSourceRef CFRunLoopSourceCreate(CFAllocatorRef allocator, CFIndex order, CFRunLoopSourceContext *context);
     */
    self->runLoopSource =
    CFRunLoopSourceCreate(
                          NULL,
                          0,
                          (CFRunLoopSourceContext*)&context);
    
    self->commands      = [NSMutableArray new];
    
    return self;
}


-(void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = NULL;
    runLoop = CFRunLoopGetCurrent();
    
    /*
     CF_EXPORT void CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef mode);
     */
    CFRunLoopAddSource(runLoop, self->runLoopSource, kCFRunLoopDefaultMode);
    
    return;
}


void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    RunLoopSource* obj = nil;
    obj = (__bridge RunLoopSource*)info;
    
    AppDelegate* del = nil;
    del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    RunLoopContext* theContext = nil;
    theContext = [[RunLoopContext alloc] initWithSource:(RunLoopSource *)obj
                                                andLoop:(CFRunLoopRef)rl];
    
    if([del respondsToSelector:@selector(registerSource:)])
    {
        [del performSelectorOnMainThread:@selector(registerSource:)
                              withObject:theContext waitUntilDone:NO];
    }
    
    
    return;
}

@end



void RunLoopSourcePerformRoutine (void* info)
{
    RunLoopSource* obj = nil;
    obj = obj = (__bridge RunLoopSource*)info;
    
    [obj sourceFired];
}


void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    RunLoopSource* obj = nil;
    obj = (__bridge RunLoopSource*)info;
    
    AppDelegate* del = nil;
    del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if([del respondsToSelector:@selector(removeSource:)])
    {
        [del performSelectorOnMainThread:@selector(removeSource:)
                              withObject:theContext waitUntilDone:NO];
    }
}

@implementation RunLoopContext



@end


@implementation CQMTwistedRunLoop

#pragma mark -
#pragma mark Starting the Run loop
#pragma mark -
-(void)skeletonThreadMain
{
    //-- 1. Setting up an AutolreleasePool
    @autoreleasepool
    {
        BOOL done = NO;
        
        //--2 . Add your sources or timers to the runLop and do any other setup
        
        do
        {
            //--3. Start the runLoop but return after each source is handled
            SInt32 result = 0;
            /*
             CF_EXPORT SInt32 CFRunLoopRunInMode(CFStringRef mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled);
             */
            result = CFRunLoopRunInMode(
                                        kCFRunLoopDefaultMode,
                                        (CFTimeInterval) 10.0,
                                        true);
            
            //-- 4 SWicthing on all possible return Values
            /*
             Reasons for CFRunLoopRunInMode() to Return
             enum {
             kCFRunLoopRunFinished = 1,
             kCFRunLoopRunStopped = 2,
             kCFRunLoopRunTimedOut = 3,
             kCFRunLoopRunHandledSource = 4
             };
             
             */
            switch (result)
            {
                case kCFRunLoopRunFinished:
                    printf("\n kCFRunLoopRunFinished \n");
                    break;
                    
                case kCFRunLoopRunStopped:
                    printf("\n kCFRunLoopRunStopped \n");
                    break;
                    
                case kCFRunLoopRunTimedOut:
                    printf("\n kCFRunLoopRunTimedOut \n");
                    break;
                    
                case kCFRunLoopRunHandledSource:
                    printf("\n kCFRunLoopRunHandledSource \n");
                    break;
                    
                default:
                    printf("\n result \n");
                    break;
            }
            
            
            //-- 5  If a source explicitly stopped the run loop or ,
            //--  if there are no sources or timers
            //--  Exit the run loop
            if (
                (result == kCFRunLoopRunStopped) ||
                (result == kCFRunLoopRunFinished)
                )
            {
                done = YES;
                
                // Check for any other exit conditions here and set the
                // done variable as needed.
            }
            
        }
        while (!done);
        
        // Clean up code here.
        // Be sure to release any allocated autorelease pools.
    }
}

#pragma mark -
#pragma mark Run Loop Observer
#pragma mark -

-(void)theThread
{
    NSThread* theThread = nil;
    theThread = [[NSThread alloc] initWithTarget:(id)self
                                        selector:@selector(threadMain)
                                          object:nil];
    
    [theThread setName:NSStringFromSelector(_cmd)];
    
    [theThread start];
    
    theThread = nil;
    return;
}


-(void)threadMain
{
    //-- No garbagle collection -
    //-- Set up the AutoRelease pool
    @autoreleasepool
    {
        //-- get the current run loop
        NSRunLoop* myRunLoop = nil;
        myRunLoop = [NSRunLoop currentRunLoop];
        
        //- Create a run loop observer
        /*
         typedef struct {
         CFIndex	version;
         void *	info;
         const void *(*retain)(const void *info);
         void	(*release)(const void *info);
         CFStringRef	(*copyDescription)(const void *info);
         } CFRunLoopObserverContext;
         
         */
        CFRunLoopObserverContext context;
        context.version         = 0.0;
        context.info            = (__bridge void *)(self);
        context.retain          = NULL;
        context.release         = NULL;
        context.copyDescription = NULL;
        
        /*
         CF_EXPORT CFRunLoopObserverRef CFRunLoopObserverCreate(CFAllocatorRef allocator, CFOptionFlags activities, Boolean repeats, CFIndex order, CFRunLoopObserverCallBack callout, CFRunLoopObserverContext *context);
         */
        CFRunLoopObserverRef observer = NULL;
        observer =
        CFRunLoopObserverCreate(
                                kCFAllocatorDefault,
                                kCFRunLoopAllActivities,
                                true,
                                0,
                                (CFRunLoopObserverCallBack)
                                &myCFRunLoopObserverCallBack,
                                (CFRunLoopObserverContext*)&context
                                );
        
        
        if (observer)
        {
            CFRunLoopRef cfLoop = NULL;
            cfLoop = [myRunLoop getCFRunLoop];
            
            if (cfLoop)
            {
                /*
                 CF_EXPORT void CFRunLoopAddObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef mode);
                 */
                CFRunLoopAddObserver(
                                     (CFRunLoopRef)cfLoop,
                                     (CFRunLoopObserverRef) observer,
                                     (CFStringRef)kCFRunLoopDefaultMode
                                     );
            }//cfLoop
            
        }//observer
        
        
        //Create a timer source
        [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.1
                                         target:(id)self
                                       selector:@selector(doFireTimer:)
                                       userInfo:nil
                                        repeats:NO];
        //if Yes - Thread Runs forever
        
        NSTimeInterval loopCount = 10;
        
        do
        {
            //run the run loop 10 times to let the timer fire
            [myRunLoop runUntilDate:
             [NSDate dateWithTimeIntervalSinceNow:loopCount]];
            
            NSLog(@"--- @@@@@@@ ---- \n");
            NSLog(@"--- @@loopCount@@@@ ---- %f \n",loopCount);
            NSLog(@"--- @@@@@@@ ----\n");
            
            loopCount--;
        }
        while (loopCount);
        
    }//@autoreleasepool
    return;
}

//
/*
 typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
 */

void myCFRunLoopObserverCallBack (CFRunLoopObserverRef observer,
                                  CFRunLoopActivity activity, void *info)
{
    NSLog(@"--- @@@@@@@ ---- \n");
    NSLog(@"--- @@__COUNTER__@@@@ ---- %u \n",arc4random());
    NSLog(@"--- @@@@@@@ ----\n");
    
    printf("observer - %p\n",observer);
    
    /*
     Run Loop Observer Activities
     -----------------------------
     typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity)
     {
     kCFRunLoopEntry = (1UL << 0),
     kCFRunLoopBeforeTimers = (1UL << 1),
     kCFRunLoopBeforeSources = (1UL << 2),
     kCFRunLoopBeforeWaiting = (1UL << 5),
     kCFRunLoopAfterWaiting = (1UL << 6),
     kCFRunLoopExit = (1UL << 7),
     kCFRunLoopAllActivities = 0x0FFFFFFFU
     };
     */
    switch (activity)
    {
        case (1UL << 0):
            printf("\n kCFRunLoopEntry \n");
            break;
            
        case (1UL << 1):
            printf("\n kCFRunLoopBeforeTimers \n");
            break;
            
        case (1UL << 2):
            printf("\n kCFRunLoopBeforeSources\n");
            break;
            
        case (1UL << 5):
            printf("\n kCFRunLoopBeforeWaiting \n");
            break;
            
        case (1UL << 6):
            printf("\n kCFRunLoopAfterWaiting \n");
            break;
            
        case (1UL << 7):
            printf("\n kCFRunLoopExit \n");
            break;
            
        case 0x0FFFFFFFU:
            printf("\n kCFRunLoopAllActivities \n");
            break;
            
        default:
            printf("activity - %lu\n",activity);
            break;
    }
    
    printf("info - %s\n",info);
    NSLog(@"info - %@\n",(__bridge CQMTwistedRunLoop*)(info));
    return;
}

//Timer Func
-(void)doFireTimer:(NSTimer *)timer
{
    NSString* timerString = nil;
    timerString = NSStringFromSelector(_cmd);
    
    NSLog(@"\n timerString \n %@\n",timerString);
    return;
}

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
