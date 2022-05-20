//
//  PNGQuantBinding.m
//
//
//  Created by Radzivon Bartoshyk on 27/04/2022.
//

#include "PNGQuantBinding.hxx"
#include "libimagequant.h"
#include "spng.h"
#import <zlib.h>
#import "Quantinizer.hpp"
#import "PNGEncoder.hpp"
#import "PNGSafeBuffer.hpp"

@implementation PNGImage (PngQuant)

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
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return rawData;
}

-(NSData * _Nullable) pngRGBA:(int)speed;
{
    int _width = (int)(self.size.width * self.scale);
    int _height = (int)(self.size.height * self.scale);
    
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
    
    NSData *dataOut = [[NSData alloc] initWithBytes:finalBuffer.getBuffer() length:finalBuffer.getBufSize()];
    return dataOut;
}

-(NSData * _Nullable) quantizedImageData:(int)speed;
{
    int _width = (int)(self.size.width * self.scale);
    int _height = (int)(self.size.height * self.scale);
    
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
    
    NSData *dataOut = [[NSData alloc] initWithBytes:finalBuffer.getBuffer() length:finalBuffer.getBufSize()];
    return dataOut;
}

-(NSError * _Nullable) quantizedImageTo:(NSString * _Nonnull)path speed:(int) speed;
{
    int _width = (int)(self.size.width * self.scale);
    int _height = (int)(self.size.height * self.scale);
    
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
