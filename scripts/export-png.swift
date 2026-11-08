import Foundation
import CoreGraphics
import ImageIO
import Accelerate
import UniformTypeIdentifiers

let help = """
Usage: export-png --input IMAGE --output FILE.png --long-edge PIXELS
                  [--width-cm CM --height-cm CM] [--fit contain|stretch]
   or: export-png --input IMAGE --output FILE.png --width-cm CM --height-cm CM --dpi DPI
   or: export-png --input IMAGE --output FILE.png --native

contain preserves the image ratio and pads outside with transparency (default).
stretch fills the canvas but may distort the image. Existing files are not overwritten.
Without a physical size, no print size or DPI is asserted.
"""
func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}
let args = Array(CommandLine.arguments.dropFirst())
if args.contains("--help") || args.contains("-h") { print(help); exit(0) }
let valid: Set<String> = ["--input", "--output", "--width-cm", "--height-cm", "--long-edge", "--dpi", "--fit"]
var options: [String: String] = [:]
var native = false
var n = 0
while n < args.count {
    let key = args[n]
    if key == "--native" {
        guard !native else { fail("--native cannot be repeated.") }
        native = true
        n += 1
        continue
    }
    guard valid.contains(key), n + 1 < args.count, options[key] == nil else {
        fail("Unknown, repeated, or incomplete option: \(key)\n\(help)")
    }
    options[key] = args[n + 1]
    n += 2
}
guard let inputPath = options["--input"], let outputPath = options["--output"] else {
    fail("Both --input and --output are required.\n\(help)")
}
guard outputPath.lowercased().hasSuffix(".png") else { fail("Output must end in .png.") }
guard !FileManager.default.fileExists(atPath: outputPath) else { fail("Output already exists; choose a new filename.") }
guard FileManager.default.fileExists(atPath: inputPath) else { fail("Input file not found.") }
let fit = options["--fit"] ?? "contain"
guard fit == "contain" || fit == "stretch" else { fail("--fit must be contain or stretch.") }
func positive(_ key: String) -> Double? {
    guard let value = options[key] else { return nil }
    guard let number = Double(value.replacingOccurrences(of: ",", with: ".")), number.isFinite, number > 0 else {
        fail("\(key) must be a positive number.")
    }
    return number
}
let widthCM = positive("--width-cm")
let heightCM = positive("--height-cm")
let requestedDPI = positive("--dpi")
let requestedEdge = positive("--long-edge")
guard (widthCM == nil) == (heightCM == nil) else { fail("Specify both --width-cm and --height-cm.") }
let targetModes = (requestedDPI == nil ? 0 : 1) + (requestedEdge == nil ? 0 : 1) + (native ? 1 : 0)
guard targetModes == 1 else { fail("Specify exactly one of --dpi, --long-edge or --native.") }
if requestedDPI != nil && widthCM == nil { fail("--dpi requires --width-cm and --height-cm.") }
if native && widthCM != nil { fail("--native cannot be combined with a physical size.") }
if let edge = requestedEdge, edge.rounded() != edge { fail("--long-edge must be a whole number of pixels.") }

let sourceURL = URL(fileURLWithPath: inputPath)
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let rawWidth = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
      let rawHeight = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue else {
    fail("Cannot read the input image.")
}
let thumbOptions: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                      kCGImageSourceCreateThumbnailWithTransform: true,
                                      kCGImageSourceThumbnailMaxPixelSize: max(rawWidth, rawHeight)]
guard let sourceImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
    fail("Cannot decode or orient the input image.")
}
let sourceW = sourceImage.width, sourceH = sourceImage.height
let aspectW = widthCM ?? Double(sourceW)
let aspectH = heightCM ?? Double(sourceH)
let rawOutW: Double
let rawOutH: Double
if native {
    rawOutW = Double(sourceW)
    rawOutH = Double(sourceH)
} else if let dpi = requestedDPI, let wc = widthCM, let hc = heightCM {
    rawOutW = wc / 2.54 * dpi
    rawOutH = hc / 2.54 * dpi
} else if let edge = requestedEdge {
    rawOutW = edge * aspectW / max(aspectW, aspectH)
    rawOutH = edge * aspectH / max(aspectW, aspectH)
} else {
    fail("A target size is required.")
}
guard rawOutW >= 0.5, rawOutH >= 0.5, rawOutW <= 100_000, rawOutH <= 100_000 else {
    fail("Target dimensions are outside supported bounds.")
}
let outW = Int(rawOutW.rounded()), outH = Int(rawOutH.rounded())
let targetBytes = UInt64(outW) * UInt64(outH) * 4
let sourceBytes = UInt64(sourceW) * UInt64(sourceH) * 4
let physicalMemory = ProcessInfo.processInfo.physicalMemory
if physicalMemory > 0 && 2 * targetBytes + 2 * sourceBytes > physicalMemory * 3 / 4 {
    fail("The estimated memory for this output is too large; use a tiled export or a machine with more RAM.")
}
let scale: Double = fit == "contain" ? min(Double(outW) / Double(sourceW), Double(outH) / Double(sourceH)) : 0
let innerW = fit == "contain" ? min(outW, max(1, Int((Double(sourceW) * scale).rounded()))) : outW
let innerH = fit == "contain" ? min(outH, max(1, Int((Double(sourceH) * scale).rounded()))) : outH
let left = (outW - innerW) / 2, top = (outH - innerH) / 2
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let input = CGContext(data: nil, width: sourceW, height: sourceH, bitsPerComponent: 8,
                            bytesPerRow: sourceW * 4, space: cs,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
      let output = CGContext(data: nil, width: outW, height: outH, bitsPerComponent: 8,
                             bytesPerRow: outW * 4, space: cs,
                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fail("Cannot allocate image buffers.")
}
input.draw(sourceImage, in: CGRect(x: 0, y: 0, width: sourceW, height: sourceH))
output.clear(CGRect(x: 0, y: 0, width: outW, height: outH))
guard let inputData = input.data, let outputData = output.data else { fail("Cannot access image buffers.") }
var src = vImage_Buffer(data: inputData, height: vImagePixelCount(sourceH), width: vImagePixelCount(sourceW), rowBytes: sourceW * 4)
var dst = vImage_Buffer(data: outputData.advanced(by: top * outW * 4 + left * 4),
                        height: vImagePixelCount(innerH), width: vImagePixelCount(innerW), rowBytes: outW * 4)
let result = vImageScale_ARGB8888(&src, &dst, nil, vImage_Flags(kvImageHighQualityResampling))
guard result == kvImageNoError, let image = output.makeImage() else { fail("Image scaling failed: \(result).") }
let outputURL = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fail("Cannot create the PNG output.")
}
if let wc = widthCM, let hc = heightCM {
    let dpiX = Double(outW) * 2.54 / wc, dpiY = Double(outH) * 2.54 / hc
    let metadata: [CFString: Any] = [kCGImagePropertyDPIWidth: dpiX, kCGImagePropertyDPIHeight: dpiY]
    CGImageDestinationAddImage(destination, image, metadata as CFDictionary)
} else {
    CGImageDestinationAddImage(destination, image, nil)
}
guard CGImageDestinationFinalize(destination) else { fail("Could not save PNG output.") }
print("Saved: \(outputURL.path)")
print("Canvas: \(outW) × \(outH) px; image content: \(innerW) × \(innerH) px; fit: \(fit).")
if let wc = widthCM, let hc = heightCM {
    print(String(format: "Canvas: %.3f × %.3f cm, %.2f × %.2f ppi.", wc, hc, Double(outW) * 2.54 / wc, Double(outH) * 2.54 / hc))
    if innerW != outW || innerH != outH {
        print(String(format: "Content: %.3f × %.3f cm; remaining canvas is transparent.", wc * Double(innerW) / Double(outW), hc * Double(innerH) / Double(outH)))
    }
}
if fit == "stretch" && abs(Double(sourceW) / Double(sourceH) - Double(outW) / Double(outH)) > 0.0001 {
    print("Warning: stretch changed the aspect ratio.")
}
