//
//  PhotoSaver.swift
//  Reps
//

import SwiftUI
import Photos

/// Renders a SwiftUI view to an image and saves it to the photo library using
/// add-only access.
enum PhotoSaver {
    enum SaveError: Error { case renderFailed, notAuthorized }

    /// Renders `card` and adds it to the photo library.
    @MainActor
    static func save(_ card: SummaryCardView) async throws {
        // Back the card with a solid square so the exported PNG is a clean,
        // full-bleed square. If a rounded-corner variant ever slips through,
        // the opaque surface fills what would otherwise be transparent corners.
        let content = card
            .frame(width: 358, height: 358)
            .background(Theme.surface)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        renderer.isOpaque = true
        guard let image = renderer.uiImage else { throw SaveError.renderFailed }
        try await addToLibrary(image)
    }

    @MainActor
    private static func addToLibrary(_ image: UIImage) async throws {
        let status = await requestAddAuthorization()
        guard status == .authorized || status == .limited else { throw SaveError.notAuthorized }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private static func requestAddAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
