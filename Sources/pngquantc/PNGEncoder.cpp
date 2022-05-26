//
//  PNGEncoder.cpp
//  
//
//  Created by Radzivon Bartoshyk on 19/05/2022.
//

#include "PNGEncoder.hpp"
#include <stdio.h>
#include <string.h>

PNGEncoder::PNGEncoder() {
    ctx = spng_ctx_new(SPNG_CTX_ENCODER);
    file = nullptr;
}

PNGEncoder::~PNGEncoder() {
    spng_ctx_free(ctx);
    ctx = nullptr;
    if (file) {
        fclose(file);
        file = nullptr;
    }
}

void PNGEncoder::setTargetInternalBuffer() {
    spng_set_option(ctx, SPNG_ENCODE_TO_BUFFER, 1);
}

bool PNGEncoder::setTargetFile(const char* filename) {
    file = fopen(filename, "wb");
    if (!file) {
        return false;
    }
    spng_set_png_file(ctx, file);
    return true;
}

void PNGEncoder::setCompressionLevel(int level) {
    spng_set_option(ctx, SPNG_IMG_COMPRESSION_LEVEL, level);
}

bool PNGEncoder::encode(PNGSafeBuffer &buffer, int bufSize, int width, int height, int depth) {
    ihdr.width = width;
    ihdr.height = height;
    ihdr.color_type = SPNG_COLOR_TYPE_TRUECOLOR_ALPHA;
    ihdr.bit_depth = 8;
    
    spng_set_ihdr(ctx, &ihdr);
    
    int ret = spng_encode_image(ctx, buffer.getBuffer(), width*height*4, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret) {
        return false;
    }
    return true;
}

bool PNGEncoder::encode(Quantinizer &quantinizer, int width, int height) {
    
    const liq_palette *palette = quantinizer.getPallete();
    if (!palette)
    {
        return false;
    }
    
    ihdr.width = width;
    ihdr.height = height;
    ihdr.color_type = SPNG_COLOR_TYPE_INDEXED;
    ihdr.bit_depth = 8;
    
    spng_set_ihdr(ctx, &ihdr);
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
    spng_set_gama(ctx, quantinizer.getGamma());
    struct spng_trns trns;
    trns.n_type3_entries = sizeof(trns.type3_alpha);
    memset((void*)&trns.type3_alpha[0], 255, sizeof(trns.type3_alpha));
    spng_set_trns(ctx, &trns);
    auto buffer = quantinizer.getQuantinizedBuffer();
    auto bufSize = quantinizer.getQuantinizedBufferSize();
    int ret = spng_encode_image(ctx, buffer, bufSize, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret) {
        return false;
    }
    return true;
}

PNGUnsafeBuffer PNGEncoder::getEncodedImage() {
    size_t pngSize;
    void *pngBuf = NULL;
    
    int ret;
    pngBuf = spng_get_png_buffer(ctx, &pngSize, &ret);
    PNGUnsafeBuffer buf = PNGUnsafeBuffer(pngBuf, (int) pngSize);
    return buf;
}
