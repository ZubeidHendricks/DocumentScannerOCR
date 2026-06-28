import SwiftUI
import PhotosUI
import AppFactoryKit

// Doc Scanner — native VisionKit scanning (edge detection, perspective
// correction), on-device OCR, and PDF export. Free tier scans up to a few pages;
// Pro unlocks OCR, unlimited pages, and watermark-free export.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory

    @State private var pages: [UIImage] = []
    @State private var showScanner = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var ocrText: String?
    @State private var isRecognizing = false
    @State private var shareItem: ShareItem?

    private static let freePageLimit = 3

    var body: some View {
        NavigationStack {
            Group {
                if pages.isEmpty { empty } else { content }
            }
            .navigationTitle("Doc Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { addMenu }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentCameraView(
                onComplete: { scanned in addPages(scanned); showScanner = false },
                onCancel: { showScanner = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(items); photoItems = [] }
        }
        .sheet(item: $shareItem) { item in ActivityView(items: item.items) }
    }

    private var addMenu: some View {
        Menu {
            if DocTools.isSupported {
                Button { startScan() } label: { Label("Scan with Camera", systemImage: "doc.viewfinder") }
            }
            PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                Label("Import from Photos", systemImage: "photo.on.rectangle")
            }
        } label: { Image(systemName: "plus") }
    }

    private var empty: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.text.viewfinder").font(.system(size: 64)).foregroundStyle(.blue)
            Text("Scan a document").font(.title2.bold())
            Text("Edges are detected and straightened automatically. Export crisp PDFs and pull out the text.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if DocTools.isSupported {
                Button { startScan() } label: {
                    Label("New Scan", systemImage: "doc.viewfinder").frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent).tint(.blue).padding(.horizontal, 40)
            }
            PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                Label("Import from Photos", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered).padding(.horizontal, 40)
        }
        .padding()
    }

    private var content: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    Image(uiImage: page).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                        .overlay(alignment: .topTrailing) {
                            Button { pages.remove(at: index); ocrText = nil } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.white, .black.opacity(0.5))
                            }
                            .padding(6)
                        }
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
                    Text(ocrText.isEmpty ? "No text found on these pages." : ocrText)
                        .font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func startScan() {
        if atFreeLimit { factory.presentPaywall(placement: "page_limit") } else { showScanner = true }
    }

    private var atFreeLimit: Bool {
        !factory.subscriptions.isSubscribed && pages.count >= Self.freePageLimit
    }

    private func addPages(_ new: [UIImage]) {
        if atFreeLimit { factory.presentPaywall(placement: "page_limit"); return }
        let room = factory.subscriptions.isSubscribed ? new.count : max(0, Self.freePageLimit - pages.count)
        pages.append(contentsOf: new.prefix(room))
        ocrText = nil
        if room < new.count { factory.presentPaywall(placement: "page_limit") }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        var imgs: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                imgs.append(img)
            }
        }
        addPages(imgs)
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
            isRecognizing = true
            Task {
                var all = ""
                for page in pages { all += await DocTools.recognizeText(in: page) + "\n\n" }
                await MainActor.run {
                    ocrText = all.trimmingCharacters(in: .whitespacesAndNewlines)
                    isRecognizing = false
                }
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
