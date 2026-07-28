import AppKit
import SwiftUI

struct OCRTranslationView: View {
    let onDone: () -> Void

    @AppStorage(OCRTranslationSettings.autoCopyTranslationKey) private var autoCopyTranslation =
        false

    @State private var displaySourceText: String
    @State private var sourceLanguageCode = "auto"
    @State private var targetLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
    @State private var translatedText: String?
    @State private var detectedSourceLanguageCode: String?
    @State private var errorMessage: String?

    init(sourceText: String, onDone: @escaping () -> Void) {
        self.onDone = onDone
        _displaySourceText = State(initialValue: sourceText)
    }

    private static let detectLanguageOption: (code: String, name: String)? =
        SupportedLanguages.all.first { $0.code == "auto" }
    private static let sourceLanguageOptions: [(code: String, name: String)] =
        SupportedLanguages.all.filter { $0.code != "auto" }
    private static let targetLanguageOptions: [(code: String, name: String)] =
        SupportedLanguages.all.filter { $0.code != "auto" }

    private static let languageNamesByCode: [String: String] = Dictionary(
        uniqueKeysWithValues: SupportedLanguages.all.map { ($0.code, $0.name) })

    private var detectedSourceLanguageName: String? {
        detectedSourceLanguageCode.flatMap { Self.languageNamesByCode[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Original")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if sourceLanguageCode == "auto", let detectedSourceLanguageName {
                    Text("(\(detectedSourceLanguageName))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Picker("", selection: $sourceLanguageCode) {
                    if let detectLanguageOption = Self.detectLanguageOption {
                        Text(detectLanguageOption.name).tag(detectLanguageOption.code)
                        Divider()
                    }
                    ForEach(Self.sourceLanguageOptions, id: \.code) { option in
                        Text(option.name).tag(option.code)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }
            ScrollView {
                Text(displaySourceText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)

            HStack {
                Text("Translation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $targetLanguageCode) {
                    ForEach(Self.targetLanguageOptions, id: \.code) { option in
                        Text(option.name).tag(option.code)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let translatedText {
                ScrollView {
                    Text(translatedText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Translating…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }

            HStack {
                Button("Copy Original") {
                    copyToPasteboard(displaySourceText)
                }
                Button("Copy Translation") {
                    if let translatedText { copyToPasteboard(translatedText) }
                }
                .disabled(translatedText == nil)

                Spacer()

                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
        .task(id: "\(sourceLanguageCode)|\(targetLanguageCode)|\(displaySourceText)") {
            await translate()
        }
    }

    private func translate() async {
        translatedText = nil
        errorMessage = nil
        do {
            let result = try await GoogleTranslateService.translate(
                displaySourceText, from: sourceLanguageCode, to: targetLanguageCode)
            translatedText = result.text
            if sourceLanguageCode == "auto" {
                detectedSourceLanguageCode = result.detectedSourceLanguageCode
            }
            if autoCopyTranslation {
                copyToPasteboard(result.text)
            }
        } catch {
            DebugLog.log("OCR translation failed: \(error)")
            errorMessage = "Couldn't translate this text."
        }
    }

    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
