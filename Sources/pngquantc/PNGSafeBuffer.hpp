//
//  PNGSafeBuffer.hpp
//  
//
//  Created by Radzivon Bartoshyk on 20/05/2022.
//

#ifndef PNGSafeBuffer_hpp
#define PNGSafeBuffer_hpp

#include <stdio.h>

class PNGSafeBuffer {

public:
    PNGSafeBuffer(void *buffer, int bufSize);
    ~PNGSafeBuffer();
    void* getBuffer();
    int getBufSize() {
        return bufSize;
    }
private:
    void* buffer;
    int bufSize;
};

#endif /* PNGSafeBuffer_hpp */
