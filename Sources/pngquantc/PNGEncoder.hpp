//
//  PNGEncoder.hpp
//  
//
//  Created by Radzivon Bartoshyk on 19/05/2022.
//

#ifndef PNGEncoder_hpp
#define PNGEncoder_hpp

#include <stdio.h>
#include "spng.h"
#include "libimagequant.h"
#include "PNGSafeBuffer.hpp"
#include "Quantinizer.hpp"

class PNGEncoder {
    
public:
    PNGEncoder();
    void setTargetInternalBuffer();
    bool setTargetFile(const char* filename);
    void setCompressionLevel(int level);
    bool encode(PNGSafeBuffer &buffer, int bufSize, int width, int height, int depth);
    bool encode(Quantinizer &quantinizer, int width, int height);
    PNGSafeBuffer getEncodedImage();
    ~PNGEncoder();
private:
    spng_ctx* ctx;
    struct spng_plte plte;
    struct spng_ihdr ihdr = {0};
    FILE* file;
};

#endif /* PNGEncoder_hpp */
