//
//  Quantinizer.cpp
//  
//
//  Created by Radzivon Bartoshyk on 19/05/2022.
//

#include "Quantinizer.hpp"
#include <math.h>
#include <iostream>     // std::cout
#include <algorithm>    // std::max

using namespace std;

Quantinizer::Quantinizer(void* rgbaBuffer, int width, int height) {
    liq = liq_attr_create();
    gamma = 0;
    img = nullptr;
    quantinizationResult = nullptr;
    this->rgbaBuffer = rgbaBuffer;
    this->width = width;
    this->height = height;
    this->raw8BitPixels = nullptr;
    isPalleteReady = false;
}

void Quantinizer::setSpeed(int speed) {
    liq_set_speed(liq, std::max(std::min(speed, 10), 1));
}

const unsigned char* Quantinizer::getQuantinizedBuffer() {
    return this->raw8BitPixels;
}

const liq_palette* Quantinizer::getPallete() {
    if (isPalleteReady) {
        return palette;
    }
    isPalleteReady = true;
    img = liq_image_create_rgba(liq,
                                           rgbaBuffer,
                                           (int)width,
                                           (int)height,
                                           gamma);
    
    if (!img)
    {
        return nullptr;
    }
    
    if (liq_image_quantize(img, liq, &quantinizationResult) != LIQ_OK)
    {
        return nullptr;
    }
    
    raw8BitPixels = reinterpret_cast<unsigned char *>(malloc(getQuantinizedBufferSize()));
    liq_set_dithering_level(quantinizationResult, 1.0);
    
    liq_write_remapped_image(quantinizationResult, img, raw8BitPixels, getQuantinizedBufferSize());
    palette = (liq_palette*)liq_get_palette(quantinizationResult);
    return palette;
}

Quantinizer::~Quantinizer() {
    free(raw8BitPixels);
    raw8BitPixels = nullptr;
    if (quantinizationResult) {
        liq_result_destroy(quantinizationResult);
        quantinizationResult = nullptr;
    }
    if (img) {
        liq_image_destroy(img);
        img = nullptr;
    }
    if (liq) {
        liq_attr_destroy(liq);
        liq = nullptr;
    }
}
