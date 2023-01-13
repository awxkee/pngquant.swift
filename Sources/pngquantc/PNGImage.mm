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
    CGImageRef imageRef = [self makeCGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    int stride = (int)4 * (int)width * sizeof(uint8_t);
    uint8_t *targetMemory = malloc((int)(stride * height));

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

    CGContextRef targetContext = CGBitmapContextCreate(targetMemory, width, height, 8, stride, colorSpace, bitmapInfo);

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: [NSGraphicsContext graphicsContextWithCGContext:targetContext flipped:FALSE]];
    CGColorSpaceRelease(colorSpace);

    [self drawInRect: NSMakeRect(0, 0, width, height)
            fromRect: NSZeroRect
           operation: NSCompositingOperationCopy
            fraction: 1.0];

    [NSGraphicsContext restoreGraphicsState];

    CGContextRelease(targetContext);

    return targetMemory;
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
    unsigned char *rawData = reinterpret_cast<unsigned char*>(malloc(height * width * 4 * sizeof(unsigned char)));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
png_rgba_pixels_exit:
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
