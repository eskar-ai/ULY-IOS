import SwiftUI
import UniformTypeIdentifiers
import UyghurLatinKit

enum PersonalDictionaryTransfer {
    static let utType = UTType.json
    static let exportFilename = "uyghur-uly-personal-words.json"

    static func makeExportURL() throws -> URL {
        let data = try PersonalDictionary().exportJSONData()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(exportFilename)
        try data.write(to: url, options: .atomic)
        return url
    }
}

/// Import a personal dictionary JSON via the system document picker (Files / iCloud Drive).
struct PersonalDictionaryImportPicker: UIViewControllerRepresentable {
    var onImport: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImport: onImport)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onImport: (Result<URL, Error>) -> Void

        init(onImport: @escaping (Result<URL, Error>) -> Void) {
            self.onImport = onImport
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onImport(.failure(CocoaError(.fileNoSuchFile)))
                return
            }
            onImport(.success(url))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

/// Export personal dictionary JSON into Files / iCloud Drive via document picker.
struct PersonalDictionaryExportPicker: UIViewControllerRepresentable {
    let fileURL: URL
    var onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onFinish()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onFinish()
        }
    }
}
