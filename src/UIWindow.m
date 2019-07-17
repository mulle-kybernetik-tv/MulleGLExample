#define _GNU_SOURCE

#import "import-private.h"
#import "UIWindow.h"
#import "CGContext.h"
#import "UIEvent.h"
#import "UIView+UIEvent.h"
#include <time.h>


// #define DRAW_MOUSE_BOX   /* figure out how laggy mouse/draw is */
// #define PRINTF_PROFILE_RENDER
// #define ADD_RANDOM_LAG  /* make drawing sluggish */

#ifdef DRAW_MOUSE_BOX
# include <GL/gl.h>
#endif


struct timespec   timespec_diff( struct timespec start, struct timespec end)
{
   struct timespec temp;

   if ((end.tv_nsec-start.tv_nsec) < 0) 
   {
      temp.tv_sec  = end.tv_sec-start.tv_sec - 1;
      temp.tv_nsec = 1000000000 + end.tv_nsec - start.tv_nsec;
   } else 
   {
      temp.tv_sec = end.tv_sec-start.tv_sec;
      temp.tv_nsec = end.tv_nsec-start.tv_nsec;
   }
   return( temp);
}


@implementation UIWindow

static void   keyCallback( GLFWwindow* window, 
                           int key, 
                           int scancode, 
                           int action, 
                           int mods)
{
   UIWindow   *self;
   UIEvent    *event;

   self = glfwGetWindowUserPointer( window);
   self->_modifiers = mods;
   if( self->_discardEvents & UIEventTypePresses)
      return;

   event = [[UIKeyboardEvent alloc] initWithWindow:self
                                     mousePosition:self->_mousePosition
                                               key:key
                                          scanCode:scancode
                                            action:action
                                         modifiers:mods];
   [self handleEvent:event];
   [event release];   
}


static void   mouseButtonCallback( GLFWwindow* window, 
                                   int button, 
                                   int action, 
                                   int mods)
{
   UIWindow   *self;
   UIEvent    *event;
   uint64_t   bit;   

   assert( button >= 0 && button <= 63);

   self  = glfwGetWindowUserPointer( window);

   bit = 1 << button;
   self->_mouseButtonStates &= ~bit;
   if( action == GLFW_PRESS)
      self->_mouseButtonStates |= bit;
   self->_modifiers = mods;

   if( self->_discardEvents & UIEventTypeTouches)
      return;
   
   event = [[UIMouseButtonEvent alloc] initWithWindow:self
                                        mousePosition:self->_mousePosition
                                               button:button
                                               action:action
                                            modifiers:mods];
   [self handleEvent:event];
   [event release];   
}


static void   mouseMoveCallback( GLFWwindow* window, 
                                 double xpos, 
                                 double ypos)
{
   UIWindow   *self;
   UIEvent    *event;

   self = glfwGetWindowUserPointer( window);

   self->_mousePosition.x = xpos;
   self->_mousePosition.y = ypos;
   if( self->_discardEvents & UIEventTypeMotion)
      return;

   // TODO: wrap in autorelease pool ?
   //       + event don't leak if someone throws
   //       - latency
   event = [[UIMouseMotionEvent alloc] initWithWindow:self
                                        mousePosition:self->_mousePosition
                                         buttonStates:self->_mouseButtonStates
                                            modifiers:self->_modifiers];
   [self handleEvent:event];
   [event release];
}


static void   mouseScrollCallback( GLFWwindow *window, 
                                   double xoffset, 
                                   double yoffset)
{
   UIWindow   *self;
   UIEvent    *event;
   uint64_t   bit;   
   CGPoint    scrollOffset;

   self  = glfwGetWindowUserPointer( window);
   if( self->_discardEvents & UIEventTypeScroll)
      return;
   
   scrollOffset = CGPointMake( xoffset, yoffset);
   event        = [[UIMouseScrollEvent alloc] initWithWindow:self
                                               mousePosition:self->_mousePosition
                                                scrollOffset:scrollOffset
                                                   modifiers:self->_modifiers];
   [self handleEvent:event];
   [event release];   
}


// TODO: move this to UIAppplication or ??
+ (void) initialize
{
   if( ! glfwInit())
   {
      fprintf( stderr, "Couldn't get GLFW initialized\n");
      abort(); 
   }
   // calling glSwapInterval here is too early
}


- (id) initWithFrame:(CGRect) frame
{
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 2);
   glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
   glfwWindowHint( GLFW_RESIZABLE, GL_FALSE);

   _window = glfwCreateWindow( frame.size.width, 
                               frame.size.height, 
                               "Demo", 
                               0, 
                               0);
   if( ! _window) 
   {
      fprintf( stderr, "glfwCreateWindow failed us\n");
      [self release];
      return( nil);
//		glfwTerminate();
//		return( -1);
   }

   // TODO: query glfw for actual frame
   _frame         = frame;
   _mousePosition = CGPointMake( -1.0, -1.0);

   glfwMakeContextCurrent( _window);
   glfwSetWindowUserPointer( _window, self);

   glfwSetMouseButtonCallback( _window, mouseButtonCallback);
   glfwSetCursorPosCallback( _window, mouseMoveCallback);
   glfwSetKeyCallback( _window, keyCallback);
   glfwSetScrollCallback( _window, mouseScrollCallback);

   return( self);
}

- (void) finalize
{
   // TODO: delete window ?
   _firstResponder = nil;
   [super finalize];
}


- (void) dealloc
{
   // TODO: delete window ?
   [super dealloc];
}


- (id) _firstResponder
{
   return( _firstResponder);
}


- (void) addLayer:(CALayer *) layer
{
   abort();
}

#ifdef DRAW_MOUSE_BOX

- (void) renderWithContext:(CGContext *) context
{
      double   x,y;
      double   pixelsX,pixelsY;

      // poll to get most up to date value 
      // this makes a difference on Linux X.org at least
      glfwGetCursorPos( _window, &x, &y);

//      assert( x == ctxt.mouse_x);
//      assert( y == ctxt.mouse_y);

      glColor3f(1.0, 1.0, 1.0);

      glBegin(GL_QUADS);
   
      // assume 0.0,0.0 is in the middle of the screen
      x = (x - (_frame.size.width / 2.0)) / (_frame.size.width / 2.0);
      y = ((_frame.size.height / 2.0) - y) / (_frame.size.height / 2.0);

      pixelsX = 32 / _frame.size.width;
      pixelsY = 32 / _frame.size.height;
      glVertex3f ( x - pixelsX, y - pixelsY, 0.0);
      glVertex3f ( x + pixelsX, y - pixelsY, 0.0);
      glVertex3f ( x + pixelsX, y + pixelsY, 0.0);
      glVertex3f ( x - pixelsX, y + pixelsY, 0.0);

      glEnd();
}
#endif

// glitch hunt:
//
// a) we sometimes overflow the current frame
// b) we are doublebuffering
// c) the glitch occurs when there is already drawing on the screen
// d) the glitch looks like the buffer is cleared and then not swapped
// 
- (void) renderLoopWithContext:(CGContext *) context
{
   struct timespec   start;
   struct timespec   end;
   struct timespec   diff;
   struct timespec   sleep;
   GLFWmonitor       *monitor;
   GLFWvidmode       *mode;
   int               refresh;
   long              nsperframe;
   float             scale_x, scale_y;

//   _discardEvents = UIEventTypeMotion;

   glfwSwapInterval( 0);  // need for smooth pointer/control sync

   monitor = glfwGetPrimaryMonitor();
   mode    = (GLFWvidmode *) glfwGetVideoMode( monitor);
   refresh = mode->refreshRate;

   nsperframe = (1000000000L + (mode->refreshRate - 1)) / mode->refreshRate;
#ifdef PRINTF_PROFILE_RENDER   
   fprintf( stderr, "Refresh: %d (%09ld ns/frame)\n", mode->refreshRate, nsperframe);
#endif
   #define PAINT_FRAMES  2 //  60 * 5

   // glfwMakeContextCurrent( _window );
   //
   // gut feeling: when we do onw swap buffers first, once, we know we have enough 
   // time on the first refresh (didn't work)
   //
   glfwSwapBuffers( _window);
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );
   glClear( GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

   while( ! glfwWindowShouldClose( _window)) 
   {
      if( 1 || _didRender < PAINT_FRAMES)
      {
         // nvgGlobalCompositeOperation( ctxt->vg, NVG_ATOP);
#ifdef PRINTF_PROFILE_RENDER   
         clock_gettime( CLOCK_REALTIME, &start);
#endif
         glfwGetWindowContentScale( _window, &scale_x, &scale_y);

         [context startRenderToFrame:_frame
                            fontScale:scale_y];

         [self renderWithContext:context];

         [context endRender];

#ifdef PRINTF_PROFILE_RENDER   
         clock_gettime( CLOCK_REALTIME, &end);
         diff = timespec_diff( start, end);
         if( diff.tv_sec > 0 || diff.tv_nsec >= nsperframe)
            fprintf( stderr, "frame #%ld: @%ld:%09ld render end, OVERFLW %.4f frames\n", 
                                 _didRender, 
                                 end.tv_sec, 
                                 end.tv_nsec,
                                 diff.tv_sec ? 9999.9999 : (diff.tv_nsec / (double) nsperframe) - 1);
#endif         
         glfwSwapBuffers( _window);
         _didRender++;

#ifdef ADD_RANDOM_LAG
         sleep.tv_sec  = 0.0;
         sleep.tv_nsec = nsperframe / 10 * (rand() % 100);
         nanosleep( &sleep, NULL);
#endif

         //
         // GL_COLOR_BUFFER_BIT brauchen wir, wenn wir nicht selber per
         // Hand abschnittsweise löschen
         // GL_STENCIL_BUFFER_BIT braucht nanovg 
         // GL_DEPTH_BUFFER_BIT ?
         //
         // glClearColor( 1.0 - _didRender / 120.0, 1.0 - _didRender / 120.0, 1.0 - _didRender / 240.0, 0.0f );
         glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );
         glClear( GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
      }
      else
         if( _didRender == PAINT_FRAMES)
         {
            printf( "finished\n");
            _didRender++;
         }

#ifdef PRINTF_PROFILE_EVENTS   
      clock_gettime( CLOCK_REALTIME, &start);
      printf( "@%ld:%09ld events start\n", start.tv_sec, start.tv_nsec);
#endif
      [self waitForEvents];

#ifdef PRINTF_PROFILE_EVENTS   
      clock_gettime( CLOCK_REALTIME, &end);
      diff = timespec_diff( start, end);
      printf( "@%ld:%09ld events end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif
   }
}


- (CGRect) frame
{
   return( _frame);
}


- (CGRect) bounds
{
   return( CGRectMake( 0.0, 0.0, _frame.size.width, _frame.size.height));
}


- (void) waitForEvents
{
   glfwWaitEventsTimeout( 1.0 / 200);
      // glfwPollEvents();   
}


- (void) discardPendingEvents
{
   BOOL   old;

   old = _discardEvents;
   _discardEvents = ~0;  // discard all
   {
      glfwPollEvents();
   }
   _discardEvents = old;
}


- (void) requestClose
{
   glfwSetWindowShouldClose( _window, GL_TRUE);
}


+ (void) sendEmptyEvent
{
   glfwPostEmptyEvent();
}


- (UIEvent *) handleEvent:(UIEvent *) event
{
   if( [event isKindOfClass:[UIMouseScrollEvent class]])
      [self dump];
   return( [super handleEvent:event]);
}

@end

