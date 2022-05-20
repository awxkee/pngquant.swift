//
//  PNGUnsafeBuffer.hpp
//  
//
//  Created by Radzivon Bartoshyk on 20/05/2022.
//

#ifndef PNGUnsafeBuffer_hpp
#define PNGUnsafeBuffer_hpp

#include <stdio.h>

class PNGUnsafeBuffer {

public:
    PNGUnsafeBuffer(void *buffer, int bufSize) {
        this->buffer = buffer;
        this->bufSize = bufSize;
    };
    virtual ~PNGUnsafeBuffer() {
        
    };
    void* getBuffer() {
        return this->buffer;
    };
    int getBufSize() {
        return bufSize;
    }
private:
    void* buffer;
    int bufSize;
};

#endif /* PNGUnsafeBuffer_hpp */
