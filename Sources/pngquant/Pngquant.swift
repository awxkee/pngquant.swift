#if os(macOS)
import AppKit
public typealias PNGQuantImage = NSImage
#else
import UIKit
public typealias PNGQuantImage = UIImage
#endif
import Foundation
#if SWIFT_PACKAGE
import pngquantc
#endif

public struct PNGQuantinizationError: Error, Equatable { }

public extension PNGQuantImage {
    
    /**
     Compress **UIImage** with libpngquant to file at *url*
     - Throws **CannotCompressError**: if error occured while compressing
     */
    func pngQuantData(at url: URL, speed: Int = 4) throws {
        try pngQuantData(atPath: url.path, speed: speed)
    }
    
    /**
     Compress **UIImage** with libpngquant to file at *path*
     - Throws **CannotCompressError**: if error occured while compressing
     */
    func pngQuantData(atPath path: String, speed: Int = 4) throws {
        if let error = self.quantizedImage(to: path, speed: Int32(speed)) {
            throw error
        }
    }
    
    /**
     Compress **UIImage** with libpngquant to **Data**
     - Throws **PNGQuantinizationError**: if error occured while compressing
     */
    func pngQuantData(speed: Int = 4) throws -> Data {
        guard let data = self.quantizedImageData(Int32(speed)) else {
            throw PNGQuantinizationError()
        }
        return data
    }
}
