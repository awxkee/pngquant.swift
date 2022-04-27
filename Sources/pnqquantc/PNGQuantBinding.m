//
//  PNGQuantBinding.m
//  
//
//  Created by Radzivon Bartoshyk on 27/04/2022.
//

#include "PNGQuantBinding.h"
#include "libimagequant.h"
#include "lodepng.h"

NSData * quantizedImageData(UIImage *image, int speed)
{
    CGImageRef imageRef = image.CGImage;
    
    size_t _bitsPerPixel           = CGImageGetBitsPerPixel(imageRef);
    size_t _bitsPerComponent       = CGImageGetBitsPerComponent(imageRef);
    size_t _width                  = CGImageGetWidth(imageRef);
    size_t _height                 = CGImageGetHeight(imageRef);
    size_t _bytesPerRow            = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *bitmapData = (unsigned char *)malloc(_bytesPerRow * _height);
    
    CGContextRef context = CGBitmapContextCreate(bitmapData,
                                                 _width,
                                                 _height,
                                                 _bitsPerComponent,
                                                 _bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    //draw image
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef);
    
    //free data
    CGContextRelease(context);
    
    //create NSData from bytes
    NSData *data = [[NSData alloc] initWithBytes:bitmapData length:_bytesPerRow * _height];
    
    //check if free is needed
    free(bitmapData);
    
    unsigned char *bitmap = (unsigned char *)[data bytes];
    
    unsigned char **rows = (unsigned char **)malloc(_height * sizeof(unsigned char *));
    
    for (int i = 0; i < _height; ++i)
    {
        rows[i] = (unsigned char *)&bitmap[i * _bytesPerRow];
    }
    
    size_t _gamma = 0;
    
    //create liq attribute
    liq_attr *liq = liq_attr_create();
    liq_set_speed(liq, MAX(MIN(speed, 10), 1));
    
    liq_image *img = liq_image_create_rgba_rows(liq,
                                                (void **)rows,
                                                (int)_width,
                                                (int)_height,
                                                _gamma);
    
    if (!img)
    {
        return nil;
    }
    
    liq_result *quantization_result;
    if (liq_image_quantize(img, liq, &quantization_result) != LIQ_OK)
    {
        return nil;
    }
    
    // Use libimagequant to make new image pixels from the palette
    bool doRows = (_bytesPerRow / 4 > _width);
    size_t scanWidth = (doRows) ? (_bytesPerRow / 4) : _width;
    
    //create output data array
    size_t pixels_size = scanWidth * _height;
    unsigned char *raw_8bit_pixels = (unsigned char *)malloc(pixels_size);
    
    liq_set_dithering_level(quantization_result, 1.0);
    
    if (doRows)
    {
        unsigned char **rows_out = (unsigned char **)malloc(_height * sizeof(unsigned char *));
        for (int i = 0; i < _height; ++i)
            rows_out[i] = (unsigned char *)malloc(scanWidth);
        
        liq_write_remapped_image_rows(quantization_result, img, rows_out);
        
        //copy data to raw_8bit_pixels
        for (int i = 0; i < _height; ++i)
            memcpy(raw_8bit_pixels + i*(scanWidth), rows_out[i], scanWidth);
        
        free(rows_out);
    }
    else
    {
        liq_write_remapped_image(quantization_result, img, raw_8bit_pixels, pixels_size);
    }
    
    const liq_palette *palette = liq_get_palette(quantization_result);
    
    //save convert pixels to png file
    LodePNGState state;
    lodepng_state_init(&state);
    state.info_raw.colortype = LCT_PALETTE;
    state.info_raw.bitdepth = 8;
    state.info_png.color.colortype = LCT_PALETTE;
    state.info_png.color.bitdepth = 8;
    
    for (size_t i = 0; i < palette->count; ++i)
    {
        lodepng_palette_add(&state.info_png.color, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
        
        lodepng_palette_add(&state.info_raw, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
    }
    
    unsigned char *output_file_data;
    size_t output_file_size;
    
    unsigned int out_state = lodepng_encode(&output_file_data,
                                            &output_file_size,
                                            raw_8bit_pixels,
                                            (int)_width,
                                            (int)_height,
                                            &state);
    
    if (out_state)
    {
        NSLog(@"error can't encode image %s", lodepng_error_text(out_state));
        return nil;
    }
    
    NSData *data_out = [[NSData alloc] initWithBytes:output_file_data length:output_file_size];
    
    liq_result_destroy(quantization_result);
    liq_image_destroy(img);
    liq_attr_destroy(liq);
    
    free(rows);
    free(raw_8bit_pixels);
    
    lodepng_state_cleanup(&state);
    
    return data_out;
}
