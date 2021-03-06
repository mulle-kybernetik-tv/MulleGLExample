#import "UIImage.h"

#import "CGGeometry.h"


typedef struct mulle_int_size
{
   int   width;
   int   height;
} mulle_int_size;


typedef struct mulle_bitmap_size
{
   struct mulle_int_size   size;
   unsigned char           colorComponents;
} mulle_bitmap_size;


@interface MulleBitmapImage : UIImage
{
   void                      *_image;
   struct mulle_bitmap_size  _bitmapSize;
   unsigned char             _shouldFree;
}

- (instancetype) initWithBytes:(void *) bytes 
                        length:(NSUInteger) length;
                     
// const meaning readonly memory 
- (instancetype) initWithConstBytes:(const void *) bytes 
                         bitmapSize:(mulle_bitmap_size) bitmapSize;
- (instancetype) initWithContentsOfFileWithFileRepresentationString:(char *) s;

- (mulle_int_size) intSize;
- (mulle_bitmap_size) bitmapSize;

- (void *) bytes;
- (NSUInteger) length;

@end
