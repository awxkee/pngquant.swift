//
//  Quantinizer.hpp
//  
//
//  Created by Radzivon Bartoshyk on 19/05/2022.
//

#ifndef Quantinizer_hpp
#define Quantinizer_hpp

#include <stdio.h>
#include "libimagequant.h"

class Quantinizer {
public:
    Quantinizer(void* rgbaBuffer, int width, int height);
    void setSpeed(int speed);
    const liq_palette* getPallete();
    const unsigned char* getQuantinizedBuffer();
    void setQuality(int minimum, int maximum);
    inline const int getQuantinizedBufferSize() {
        return width * height;
    };
    double getGamma() {
        return gamma;
    }
    ~Quantinizer();
private:
    bool isPalleteReady;
    double gamma;
    void* rgbaBuffer;
    int width;
    int height;
    liq_image *img;
    liq_attr *liq;
    liq_result *quantinizationResult;
    unsigned char *raw8BitPixels;
    liq_palette *palette;
};

#endif /* Quantinizer_hpp */
