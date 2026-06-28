import SwiftUI
import AppFactoryKit

// Document Scanner + OCR — native VisionKit scanning (edge detection, perspective
// correction), on-device OCR, and PDF export. Free tier scans; Pro unlocks OCR
// text extraction and unlimited exports.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory

    @State private var pages: [UIImage] = []
    @State private var showScanner = false
    @State private var ocrText: String?
    @State private var isRecognizing = false
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationStack {
            Group {
                if pages.isEmpty { empty } else { content }
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showScanner = true } label: { Image(systemName: "doc.viewfinder") }
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentCameraView(
                onComplete: { scanned in pages.append(contentsOf: scanned); showScanner = false },
                onCancel: { showScanner = false }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $shareItem) { item in ActivityView(items: item.items) }
    }

    private var empty: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder").font(.system(size: 64)).foregroundStyle(.blue)
            Text("Scan a document").font(.title3.bold())
            Text("Edges are detected and corrected automatically.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button { showScanner = true } label: {
                Label("New Scan", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent).tint(.blue).padding(.horizontal, 40)
        }
        .padding()
    }

    private var content: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                    Image(uiImage: page).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                }
            }
            .padding()

            VStack(spacing: 12) {
                Button { exportPDF() } label: {
                    Label("Export PDF (\(pages.count) page\(pages.count == 1 ? "" : "s"))", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent).tint(.blue)

                Button { runOCR() } label: {
                    Label(isRecognizing ? "Reading…" : "Extract Text (OCR)", systemImage: "text.viewfinder")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
                .disabled(isRecognizing)

                if let ocrText {
                    Text(ocrText)
                        .font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal)
        }
    }

    private func exportPDF() {
        factory.requirePremium(feature: "export_pdf") {
            let data = DocTools.makePDF(from: pages)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Scan.pdf")
            try? data.write(to: url)
            shareItem = ShareItem(items: [url])
        }
    }

    private func runOCR() {
        factory.requirePremium(feature: "ocr") {
            guard let first = pages.first else { return }
            isRecognizing = true
            Task {
                var all = ""
                for page in pages { all += await DocTools.recognizeText(in: page) + "\n\n" }
                _ = first
                await MainActor.run { ocrText = all.trimmingCharacters(in: .whitespacesAndNewlines); isRecognizing = false }
            }
        }
    }
}

struct ShareItem: Identifiable { let id = UUID(); let items: [Any] }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
