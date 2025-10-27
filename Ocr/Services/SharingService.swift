//
//  SharingService.swift
//  Ocr
//
//  Created by Claude Code
//

import Foundation
import UIKit
import MessageUI

/// 共有サービスの実装（SRP: 共有処理のみの責任）
final class SharingService: NSObject, SharingServiceProtocol {

    // MARK: - SharingServiceProtocol

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    func shareViaAirDrop(_ text: String, from viewController: UIViewController) async {
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // iPadの場合はpopoverで表示
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        await MainActor.run {
            viewController.present(activityViewController, animated: true)
        }
    }

    func shareViaEmail(_ text: String, from viewController: UIViewController) async throws {
        guard MFMailComposeViewController.canSendMail() else {
            throw SharingServiceError.mailNotAvailable
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setMessageBody(text, isHTML: false)

        await MainActor.run {
            viewController.present(mailComposer, animated: true)
        }
    }

    func share(_ text: String, from viewController: UIViewController, sourceView: UIView?) async {
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // iPadの場合はpopoverで表示
        if let popoverController = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceView.bounds
            } else {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }
        }

        await MainActor.run {
            viewController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension SharingService: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
