//
//  PNGQuantBinding.m
//
//
//  Created by Radzivon Bartoshyk on 27/04/2022.
//

#include "PNGImage.hxx"
#include "libimagequant.h"
#include "spng.h"
#import <zlib.h>
#import "Quantinizer.hpp"
#import "PNGEncoder.hpp"
#import "PNGSafeBuffer.hpp"
#import <Accelerate/Accelerate.h>

@implementation PNGImage (PngQuant)

#if TARGET_OS_OSX
- (unsigned char *)pngRgbaPixels {
    auto rect = NSMakeRect(0, 0, self.size.width, self.size.height);
    CGImageRef imageRef = [self CGImageForProposedRect: &rect context:nil hints:nil];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return rawData;
}

-(int)pngIntrinsicWidth {
    return self.size.width;
}

-(int)pngIntrinsicHeight {
    return self.size.height;
}

#else
- (unsigned char *)pngRgbaPixels {
    CGImageRef imageRef = [self CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return rawData;
}
-(int)pngIntrinsicWidth {
    return self.size.width * self.scale;
}
-(int)pngIntrinsicHeight {
    return self.size.height * self.scale;
}
#endif

+(unsigned char*)quantUnpremultiplyRGBA:(CGImageRef)cgNewImageRef {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    vImage_Buffer src;
    void* result = nullptr;
    vImage_CGImageFormat srcFormat = {
          .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(cgNewImageRef),
          .bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(cgNewImageRef),
          .colorSpace = colorSpace,
          .bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big,
          .renderingIntent = kCGRenderingIntentDefault
      };
    auto vEerror = vImageBuffer_InitWithCGImage(&src, &srcFormat, NULL, cgNewImageRef, kvImageNoFlags);
    if (vEerror != kvImageNoError) {
        goto unpremultiply_exit;
    }
    
    vImage_Buffer dest;
    vEerror = vImageBuffer_Init(&dest, CGImageGetHeight(cgNewImageRef), CGImageGetWidth(cgNewImageRef), 32, kvImageNoFlags);
    if (vEerror != kvImageNoError) {
        goto unpremultiply_exit;
    }
    
    vEerror = vImageUnpremultiplyData_RGBA8888(&src, &dest, kvImageNoFlags);
    if (vEerror != kvImageNoError) {
        goto unpremultiply_exit;
    }
    result = dest.data;
    
unpremultiply_exit:
    free(src.data);
    CGColorSpaceRelease(colorSpace);
    return reinterpret_cast<unsigned char*>(result);
}

-(NSData * _Nullable) pngRGBA:(int)speed;
{
    int _width = self.pngIntrinsicWidth;
    int _height = self.pngIntrinsicHeight;
    
    unsigned char *bitmap = [self pngRgbaPixels];
    
    auto safeBuffer = PNGSafeBuffer(bitmap, _width*_height*4);
    
    auto encoder = PNGEncoder();
    encoder.setTargetInternalBuffer();
    encoder.setCompressionLevel(speed);
    if (!encoder.encode(safeBuffer, safeBuffer.getBufSize(), _width, _height, 8)) {
        return nil;
    }
    
    auto finalBuffer = encoder.getEncodedImage();
    if (!finalBuffer.getBuffer()) {
        return nil;
    }
    
    NSData *dataOut = [[NSData alloc] initWithBytesNoCopy:finalBuffer.getBuffer() length:finalBuffer.getBufSize() deallocator:^(void * _Nonnull bytes, NSUInteger length) {
        free(bytes);
    }];
    return dataOut;
}

-(NSData * _Nullable) quantizedImageData:(int)speed;
{
    int _width = self.pngIntrinsicWidth;
    int _height = self.pngIntrinsicHeight;
    
    unsigned char *bitmap = [self pngRgbaPixels];
    
    auto pngSafeBuffer = PNGSafeBuffer(bitmap, _width*_height*4);
    
    auto quantinizer = Quantinizer(pngSafeBuffer.getBuffer(), _width, _height);
    quantinizer.setSpeed(speed);
    
    auto encoder = PNGEncoder();
    encoder.setTargetInternalBuffer();
    encoder.setCompressionLevel(speed);
    if (!encoder.encode(quantinizer, _width, _height)) {
        return nil;
    }

    auto finalBuffer = encoder.getEncodedImage();
    if (!finalBuffer.getBuffer()) {
        return nil;
    }
    
    NSData *dataOut = [[NSData alloc] initWithBytesNoCopy:finalBuffer.getBuffer() length:finalBuffer.getBufSize() deallocator:^(void * _Nonnull bytes, NSUInteger length) {
        free(bytes);
    }];
    return dataOut;
}

-(NSError * _Nullable) quantizedImageTo:(NSString * _Nonnull)path speed:(int) speed;
{
    int _width = self.pngIntrinsicWidth;
    int _height = self.pngIntrinsicHeight;
    
    unsigned char *bitmap = [self pngRgbaPixels];
    
    auto safeBuffer = PNGSafeBuffer(bitmap, _width*_height*4);
    
    auto quantinizer = Quantinizer(safeBuffer.getBuffer(), _width, _height);
    quantinizer.setSpeed(speed);
    
    auto encoder = PNGEncoder();
    if (!encoder.setTargetFile([path UTF8String])) {
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"Cannot open file" }];
    }
    encoder.setCompressionLevel(speed);
    if (!encoder.encode(quantinizer, _width, _height)) {
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"Cannot open file" }];
    }

    return nil;
}

@end
