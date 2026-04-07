import UIKit

enum ImageProcessor {

    /// Resize to max 1024px on longest side, compress to JPEG at 0.82 quality.
    static func compress(_ image: UIImage) -> ImageData? {
        let maxDimension: CGFloat = 1024
        var width = image.size.width
        var height = image.size.height

        if width > maxDimension || height > maxDimension {
            if width > height {
                height = (height * maxDimension / width).rounded()
                width = maxDimension
            } else {
                width = (width * maxDimension / height).rounded()
                height = maxDimension
            }
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let resized = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        guard let jpegData = resized.jpegData(compressionQuality: 0.82) else {
            return nil
        }

        return ImageData(
            base64: jpegData.base64EncodedString(),
            mediaType: "image/jpeg",
            uiImage: resized
        )
    }
}
