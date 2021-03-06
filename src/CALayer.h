#import "import.h"

#import "CGBase.h"

#import "nanovg.h"


typedef NVGcolor   CGColorRef;
typedef void       *CGColorSpaceRef;


static inline NVGcolor getNVGColor( uint32_t color) 
{
	return nvgRGBA(
		(color >> 24) & 0xff,
		(color >> 16) & 0xff,
		(color >> 8) & 0xff,
		(color >> 0) & 0xff);
}


static inline CGColorRef CGColorCreateGenericRGB( CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
      return( nvgRGBA( (uint32_t) round( 0xff * red),
                       (uint32_t) round( 0xff * green),
                       (uint32_t) round( 0xff * blue),
                       (uint32_t) round( 0xff * alpha)));
}


static inline CGColorRef CGColorCreate( CGColorSpaceRef space, const CGFloat *components)
{
   return( CGColorCreateGenericRGB( components[ 0], 
                                    components[ 1], 
                                    components[ 2],
                                    components[ 3]));
}


static inline size_t CGColorGetNumberOfComponents(CGColorRef color)
{
   return( 4);
}



static inline CGFloat   CGColorGetAlpha( CGColorRef color)
{
   return( color.a / (CGFloat) 0xFF);
}



typedef float   _NVGtransform[ 6];   


@class CGContext;


@interface CALayer : NSObject  
{
   _NVGtransform   _transform;
   NVGscissor      _scissor;
}


- (instancetype) init;
- (instancetype) initWithFrame:(CGRect) frame;

- (BOOL) drawInContext:(CGContext *) ctx;

@property CGFloat cornerRadius;
@property CGFloat borderWidth;
@property CGColorRef borderColor;
@property CGColorRef backgroundColor;

@property CGRect frame;
@property CGRect bounds;

@property char  *cStringName;

// properties used for rendering only
@property CGRect   clipRect;

- (void) setTransform:(_NVGtransform) transform
              scissor:(NVGscissor *) scissor;


@end


@class UIImage;


@protocol CAImageLayer 

@property( retain) UIImage   *image;

@end
  
