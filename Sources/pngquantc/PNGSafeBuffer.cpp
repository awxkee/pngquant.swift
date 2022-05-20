//
//  PNGSafeBuffer.cpp
//  
//
//  Created by Radzivon Bartoshyk on 20/05/2022.
//

#include "PNGSafeBuffer.hpp"
#include <stdlib.h>

PNGSafeBuffer::PNGSafeBuffer(void *buffer, int bufSize) {
    this->buffer = buffer;
    this->bufSize = bufSize;
}

PNGSafeBuffer::~PNGSafeBuffer() {
    free(this->buffer);
}

void* PNGSafeBuffer::getBuffer() {
    return this->buffer;
}
