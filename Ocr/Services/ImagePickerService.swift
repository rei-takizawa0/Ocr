//
//  ImagePickerService.swift
//  Ocr
//
//  Created by takizawa rei on 2025/10/29.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    /// ステータス更新メソッド
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    /// データソースの橋渡し
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Coordinator の生成
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// UIImagePickerController のデリゲートを管理するクラス
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        /// 親 ImagePicker への参照
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
            guard let image = info[.originalImage] as? UIImage else {
                picker.dismiss(animated: true)
                return
            }
            parent.selectedImage = image
            parent.onImagePicked(image)
            picker.dismiss(animated: true)
        }

        /// ユーザーがキャンセルしたときに呼ばれる
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
