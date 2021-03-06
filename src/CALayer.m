#import "import-private.h"

#import "CALayer.h"

#import "CGGeometry.h"
#import "CGGeometry+CString.h"
#import "CGContext.h"
#import "nanovg+CString.h"


@implementation CALayer

- (id) init
{
   self = [super init];
   if( ! self)
      return( self);

   _bounds.origin.x = INFINITY;
   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   self = [self init];
   if( self)
      _frame = frame;
   return( self);
}


- (void) dealloc
{
   struct mulle_allocator  *allocator;

   allocator = MulleObjCObjectGetAllocator( self);
   mulle_allocator_free( allocator, _cStringName);

   [super dealloc];
}


- (void) setTransform:(_NVGtransform) transform
              scissor:(NVGscissor *) scissor
{
   memcpy( _transform, transform, sizeof( _NVGtransform));
   memcpy( &_scissor, scissor, sizeof( NVGscissor));
}


- (BOOL) drawContentsInContext:(CGContext *) context
{
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGPoint      scale;
   CGRect       frame;
   CGRect       bounds;
   CGFloat      halfBorderWidth;
   CGFloat      halfBorderHeight;
   CGFloat      obscured;
   CGFloat      borderHeight;
   CGPoint      tl;
   CGPoint      br;
   CGSize       sz;
   int          radius;
   NVGcontext   *vg;
   struct NVGpaint   paint; // todo convert to CG ??

#ifdef CALAYER_DEBUG   
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif
   
   frame  = [self frame];
   if( frame.size.width == 0.0 || frame.size.height == 0.0)
      return( NO);

   vg = [context nvgContext];

   //
   // these are the "inherited" transforms
   //
   nvgResetTransform( vg);
   nvgTransform( vg, _transform[ 0], _transform[ 1], _transform[ 2],
                     _transform[ 3], _transform[ 4], _transform[ 5]);
#ifdef CALAYER_DEBUG   
   fprintf( stderr, "%s: set to local transform %s\n", 
                     [self cStringDescription],
                     _NVGtransformCStringDescription( _transform));                     
#endif   
   nvgSetScissor( vg, &_scissor);

#ifdef CALAYER_DEBUG   
   fprintf( stderr, "%s: set to local scissor %s\n", 
                     [self cStringDescription],
                     NVGscissorCStringDescription( &_scissor));                     

   fprintf( stderr, "%s: transform %s\n", 
                     [self cStringDescription],
                     _NVGtransformCStringDescription( _transform));
   fprintf( stderr, "%s: scissor %s\n", 
                     [self cStringDescription],
                     NVGscissorCStringDescription( &_scissor));
#endif

   //
   // fill and border are drawn as frame
   // contents in bounds of superview
   //

   //
   // if the stroke is alpha, it will have to render over pixels
   // otherwise reduce the size of the shape we draw
   //
   tl.x = frame.origin.x;
   tl.y = frame.origin.y;
   br.x = tl.x + frame.size.width - 1;
   br.y = tl.y + frame.size.height - 1;

   if( tl.x <= br.x || tl.y <= br.y)
   {
      // fill 
#if 1      
      nvgBeginPath( vg);
      nvgRoundedRect( vg, tl.x, 
                          tl.y, 
                          br.x - tl.x + 1, 
                          br.y - tl.y + 1, 
                          _cornerRadius);

   //   nvgMoveTo( vg, tl.x, tl.y);
   //   nvgLineTo( vg, br.x, tl.y);
   //   nvgLineTo( vg, br.x, br.y);
   //   nvgLineTo( vg, tl.x, br.y);
   //   nvgLineTo( vg, tl.x, tl.y);
      nvgFillColor(vg, _backgroundColor);
      nvgFill( vg);
#endif     
   }

   [self drawContentsInContext:vg];

   //
   // the strokeWidth isn't scaled in nvg, so we do this now ourselves
   //
   if( _borderWidth)
   {
      if( tl.x <= br.x || tl.y <= br.y)

      halfBorderWidth = _borderWidth / 2.0;

      tl.x = halfBorderWidth + frame.origin.x ;
      tl.y = halfBorderWidth + frame.origin.y;
      br.x = tl.x + frame.size.width - halfBorderWidth * 2 - 1;
      br.y = tl.y + frame.size.height - halfBorderWidth * 2 - 1;

      if( tl.x <= br.x || tl.y <= br.y)
      {
         //
         // the _cornerRadius is computed for a stroke of width 1 (or 0 ?)
         // the strokeWidth is just scaling it out
         //
         nvgBeginPath( vg);
         nvgStrokeWidth( vg, (int) _borderWidth);
         nvgRoundedRect( vg, tl.x, 
                             tl.y, 
                             br.x - tl.x + 1, 
                             br.y - tl.y + 1, 
                             _cornerRadius / _borderWidth);

         nvgStrokeColor( vg, _borderColor);
         nvgStroke( vg);

//      nvgMoveTo( vg, tl.x, tl.y);
//      nvgLineTo( vg, br.x, tl.y);
//      nvgLineTo( vg, br.x, br.y);
//      nvgLineTo( vg, tl.x, br.y);
//      nvgLineTo( vg, tl.x, tl.y);
      }
   }

   bounds = [self bounds];
   if( bounds.size.width <= 0.0 || bounds.size.height <= 0.0)
      return( NO);

#ifdef CALAYER_DEBUG   
   fprintf( stderr, "%s: frame %s\n", 
            [self cStringDescription],
            CGRectCStringDescription( frame));
   fprintf( stderr, "%s: bounds %s\n", 
            [self cStringDescription],
            CGRectCStringDescription( bounds));
#endif

   nvgTranslate( vg, frame.origin.x, frame.origin.y);
#if 1
   nvgIntersectScissor( vg, 0.0, 
                            0.0, 
                            frame.size.width, 
                            frame.size.height);
#endif

   //
   // now translate bounds for context
   //
   scale.x = frame.size.width / bounds.size.width;
   scale.y = frame.size.height / bounds.size.height;

   nvgScale( vg, scale.x, scale.y);
   nvgTranslate( vg, bounds.origin.x, bounds.origin.y);

   {
      CGPoint         point;
      _NVGtransform   transform;
      NVGscissor      scissor;

      nvgCurrentTransform( vg, transform);
#ifdef CALAYER_DEBUG   
      fprintf( stderr, "%s: modified transform %s\n", 
                        [self cStringDescription],
                        _NVGtransformCStringDescription( transform));
#endif
      nvgTransformPoint( &point.x, &point.y, transform, 0.0, 0.0);
#ifdef CALAYER_DEBUG   
      fprintf( stderr, "%s: transform 0.0/0.0 -> %s\n",
               [self cStringDescription],
               CGPointCStringDescription( point));
#endif
      nvgGetScissor( vg, &scissor);
#ifdef CALAYER_DEBUG   
      fprintf( stderr, "%s: modified scissor %s\n", 
                        [self cStringDescription],
                        NVGscissorCStringDescription( &scissor));
#endif
      nvgTransformPoint( &point.x, &point.y, transform, 0.0, 0.0);
#ifdef CALAYER_DEBUG   
      fprintf( stderr, "%s: scissor transform 0.0/0.0 -> %s\n",
               [self cStringDescription],
               CGPointCStringDescription( point));
#endif
   }

   return( YES);
}


- (CGRect) bounds
{
   CGRect  bounds;

   // not tied to frame anymore ? 
   if( _bounds.origin.x != INFINITY)
      return( _bounds);

   bounds.origin = CGPointMake( 0.0f, 0.0f);
   bounds.size   = _frame.size;
   return( bounds);
}


- (void) setCStringName:(char *) s
{
   struct mulle_allocator  *allocator;

   allocator = MulleObjCObjectGetAllocator( self);
   if( s)
      s = mulle_allocator_strdup( allocator, s);
   
   mulle_allocator_free( allocator, _cStringName);
   _cStringName = s;
}


- (char *) cStringDescription
{
   char        *result;
   char        *s;
   auto char   buf[ 64];
   size_t      len;
   char        *format;

   s = class_getName( object_getClass( self));  
   sprintf( buf, "%p",  self);

   format = "<%s %s>";
   len    = _cStringName ? strlen( _cStringName) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, _cStringName);
   MulleObjCAutoreleaseAllocation( result, NULL);

   return( result);
}

@end

