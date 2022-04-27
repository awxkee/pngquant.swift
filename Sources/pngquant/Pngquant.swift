import UIKit
import Foundation
#if SWIFT_PACKAGE
import pngquantc
#endif

public struct PNGQuantinizationError: Error, Equatable { }

public extension UIImage {
    func pngQuantData(speed: Int = 4) throws -> Data {
        guard let data = quantizedImageData(self, Int32(speed)) else {
            throw PNGQuantinizationError()
        }
        return data
    }
}
