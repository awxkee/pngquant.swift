//
//  PNGQuantBinding.m
//
//
//  Created by Radzivon Bartoshyk on 27/04/2022.
//

#include "PNGQuantBinding.h"
#include "libimagequant.h"
#include "spng.h"
@import zlib;

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
    
    spng_ctx *ctx = NULL;
    struct spng_ihdr ihdr = {0};
    ctx = spng_ctx_new(SPNG_CTX_ENCODER);
    
    spng_set_option(ctx, SPNG_ENCODE_TO_BUFFER, 1);
    
    ihdr.width = _width;
    ihdr.height = _height;
    ihdr.color_type = SPNG_COLOR_TYPE_TRUECOLOR_ALPHA;
    ihdr.bit_depth = 8;
    
    spng_set_ihdr(ctx, &ihdr);
    spng_set_option(ctx, SPNG_IMG_COMPRESSION_LEVEL, speed);
    
    int ret = spng_encode_image(ctx, bitmap, _width*_height*4, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret) {
        spng_ctx_free(ctx);
        
        NSLog(@"error can't encode image %s", "real error");
        free(bitmap);
        return nil;
    }
    
    size_t png_size;
    void *png_buf = NULL;
    
    /* Get the internal buffer of the finished PNG */
    png_buf = spng_get_png_buffer(ctx, &png_size, &ret);
    
    if(png_buf == NULL)
    {
        spng_ctx_free(ctx);
        free(bitmap);
        return nil;
    }
    
    free(bitmap);
    
    NSData *data_out = [[NSData alloc] initWithBytes:png_buf length:png_size];

    free(png_buf);
    spng_ctx_free(ctx);
        
    return data_out;
}

-(NSData * _Nullable) quantizedImageData:(int)speed;
{
    int _width = (int)(self.size.width * self.scale);
    int _height = (int)(self.size.height * self.scale);
    
    unsigned char *bitmap = [self pngRgbaPixels];
    
    size_t _gamma = 0;
    
    //create liq attribute
    liq_attr *liq = liq_attr_create();
    liq_set_speed(liq, MAX(MIN(speed, 10), 1));
    
    liq_image *img = liq_image_create_rgba(liq,
                                           (void **)bitmap,
                                           (int)_width,
                                           (int)_height,
                                           _gamma);
    
    if (!img)
    {
        free(bitmap);
        return nil;
    }
    
    liq_result *quantization_result;
    if (liq_image_quantize(img, liq, &quantization_result) != LIQ_OK)
    {
        free(bitmap);
        return nil;
    }
    
    size_t pixels_size = _width * _height;
    unsigned char *raw_8bit_pixels = malloc(pixels_size);
    liq_set_dithering_level(quantization_result, 1.0);
    
    liq_write_remapped_image(quantization_result, img, raw_8bit_pixels, pixels_size);
    const liq_palette *palette = liq_get_palette(quantization_result);
    
    spng_ctx *ctx = NULL;
    struct spng_ihdr ihdr = {0};
    ctx = spng_ctx_new(SPNG_CTX_ENCODER);
    
    spng_set_option(ctx, SPNG_ENCODE_TO_BUFFER, 1);
    
    ihdr.width = _width;
    ihdr.height = _height;
    ihdr.color_type = SPNG_COLOR_TYPE_INDEXED;
    ihdr.bit_depth = 8;
    
    spng_set_ihdr(ctx, &ihdr);
    spng_set_option(ctx, SPNG_IMG_COMPRESSION_LEVEL, 6);
    
    struct spng_plte plte;
    plte.n_entries = palette->count;
    for (size_t i = 0; i < palette->count; ++i)
    {
        plte.entries[i].alpha = palette->entries[i].a;
        plte.entries[i].red = palette->entries[i].r;
        plte.entries[i].green = palette->entries[i].g;
        plte.entries[i].blue = palette->entries[i].b;
    }
    spng_set_plte(ctx, &plte);
    
    int ret = spng_encode_image(ctx, raw_8bit_pixels, pixels_size, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret) {
        spng_ctx_free(ctx);
        
        liq_result_destroy(quantization_result);
        liq_image_destroy(img);
        liq_attr_destroy(liq);
        NSLog(@"error can't encode image %s", "real error");
        if (raw_8bit_pixels) {
            free(raw_8bit_pixels);
        }
        free(bitmap);
        return nil;
    }
    
    size_t png_size;
    void *png_buf = NULL;
    
    /* Get the internal buffer of the finished PNG */
    png_buf = spng_get_png_buffer(ctx, &png_size, &ret);
    
    if(png_buf == NULL)
    {
        spng_ctx_free(ctx);
        
        liq_result_destroy(quantization_result);
        liq_image_destroy(img);
        liq_attr_destroy(liq);
        NSLog(@"error can't encode image %s", "real error");
        if (raw_8bit_pixels) {
            free(raw_8bit_pixels);
        }
        free(bitmap);
        return nil;
    }
    
    free(raw_8bit_pixels);
    free(bitmap);
    
    NSData *data_out = [[NSData alloc] initWithBytes:png_buf length:png_size];
    
    liq_result_destroy(quantization_result);
    liq_image_destroy(img);
    liq_attr_destroy(liq);
    free(png_buf);
    spng_ctx_free(ctx);
        
    return data_out;
}

-(NSError * _Nullable) quantizedImageTo:(NSString * _Nonnull)path speed:(int) speed;
{
    int _width = (int)(self.size.width * self.scale);
    int _height = (int)(self.size.height * self.scale);
    
    unsigned char *bitmap = [self pngRgbaPixels];
    
    size_t _gamma = 0;
    
    //create liq attribute
    liq_attr *liq = liq_attr_create();
    liq_set_speed(liq, MAX(MIN(speed, 10), 1));
    liq_image *img = liq_image_create_rgba(liq,
                                           (void *)bitmap,
                                           (int)_width,
                                           (int)_height,
                                           _gamma);
    
    if (!img)
    {
        free(bitmap);
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`quantizedImageTo` failed with create image", nil) }];
    }
    
    liq_result *quantization_result;
    if (liq_image_quantize(img, liq, &quantization_result) != LIQ_OK)
    {
        free(bitmap);
        liq_image_destroy(img);
        liq_attr_destroy(liq);
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`liq_image_quantize` failed", nil) }];
    }
    
    size_t pixels_size = _width * _height;
    unsigned char *raw_8bit_pixels = malloc(pixels_size);
    liq_set_dithering_level(quantization_result, 1.0);
    
    liq_write_remapped_image(quantization_result, img, raw_8bit_pixels, pixels_size);
    const liq_palette *palette = liq_get_palette(quantization_result);
    
    spng_ctx *ctx = NULL;
    struct spng_ihdr ihdr = {0}; /* zero-initialize to set valid defaults */
    /* Creating an encoder context requires a flag */
    ctx = spng_ctx_new(SPNG_CTX_ENCODER);
    
    FILE* pngFile = fopen([path UTF8String], "wb");
    if (!pngFile) {
        free(bitmap);
        free(raw_8bit_pixels);
        liq_result_destroy(quantization_result);
        liq_image_destroy(img);
        liq_attr_destroy(liq);
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"Cannot open file" }];
    }
    
    spng_set_png_file(ctx, pngFile);
    
    ihdr.width = _width;
    ihdr.height = _height;
    ihdr.color_type = SPNG_COLOR_TYPE_INDEXED;
    ihdr.bit_depth = 8;
    
    spng_set_ihdr(ctx, &ihdr);
    spng_set_option(ctx, SPNG_IMG_COMPRESSION_LEVEL, 6);
    
    struct spng_plte plte;
    plte.n_entries = palette->count;
    for (size_t i = 0; i < palette->count; ++i)
    {
        plte.entries[i].alpha = palette->entries[i].a;
        plte.entries[i].red = palette->entries[i].r;
        plte.entries[i].green = palette->entries[i].g;
        plte.entries[i].blue = palette->entries[i].b;
    }
    spng_set_plte(ctx, &plte);
    
    int ret = spng_encode_image(ctx, raw_8bit_pixels, pixels_size, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret) {
        spng_ctx_free(ctx);
        fclose(pngFile);
        liq_result_destroy(quantization_result);
        liq_image_destroy(img);
        liq_attr_destroy(liq);
        NSLog(@"error can't encode image %s", "real error");
        if (raw_8bit_pixels) {
            free(raw_8bit_pixels);
        }
        free(bitmap);
        return [[NSError alloc] initWithDomain:@"quantizedImageTo" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"PNG Encoding Failed" }];
    }
    fclose(pngFile);
    liq_result_destroy(quantization_result);
    liq_image_destroy(img);
    liq_attr_destroy(liq);
    free(raw_8bit_pixels);
    free(bitmap);
    spng_ctx_free(ctx);
    
    return nil;
}


@end
