//
//  ImagePickerService.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/29.
//

import SwiftUI

/// 高解像度画像ピッカー
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    /// UIImagePickerControllerを作成（高画質設定）
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        // カメラの場合は高画質設定を適用
        if sourceType == .camera {
            // 画質を最高品質に設定
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear // 背面カメラを優先

            // 利用可能な場合は最高品質に設定
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                picker.cameraDevice = .rear
            }
        }

        // 編集を無効化して元の解像度を保持
        picker.allowsEditing = false

        return picker
    }

    /// データソースの橋渡し
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Coordinatorの生成
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// UIImagePickerControllerのデリゲートを管理するクラス
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        /// 親ImagePickerへの参照
        let parent: ImagePicker

        /// コンストラクタ
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// 画像選択が完了したときに呼ばれる
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // 元の画像を優先的に取得（最高解像度）
            let image: UIImage?

            if let originalImage = info[.originalImage] as? UIImage {
                image = originalImage
            } else if let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            } else {
                image = nil
            }

            guard let finalImage = image else {
                picker.dismiss(animated: true)
                return
            }

            // 画像の向きを正規化（カメラで撮影した場合の回転を修正）
            let normalizedImage = normalizeImageOrientation(finalImage)

            parent.selectedImage = normalizedImage
            parent.onImagePicked(normalizedImage)
            picker.dismiss(animated: true)
        }

        /// ユーザーがキャンセルしたときに呼ばれる
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        /// 画像の向きを正規化
        private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
            // 既に.upの場合は何もしない
            if image.imageOrientation == .up {
                return image
            }

            // 画像を再描画して向きを正規化
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            defer { UIGraphicsEndImageContext() }

            image.draw(in: CGRect(origin: .zero, size: image.size))
            return UIGraphicsGetImageFromCurrentImageContext() ?? image
        }
    }
}

