import XCTest
import UIKit
import PDFKit
// Scanner.swift (DocTools) is compiled directly into this test target.

final class DocScannerTests: XCTestCase {

    /// Render a white image with known black text — a stand-in for a scanned page.
    private func textImage(_ text: String, size: CGSize = CGSize(width: 800, height: 300)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 64),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: 40, y: 110), withAttributes: attrs)
        }
    }

    // MARK: - OCR actually extracts text

    func testOCRExtractsKnownText() async {
        let image = textImage("INVOICE 2026")
        let result = await DocTools.recognizeText(in: image)
        let upper = result.uppercased()
        XCTAssertTrue(upper.contains("INVOICE"), "OCR did not find 'INVOICE'. Got: \(result)")
        XCTAssertTrue(upper.contains("2026"), "OCR did not find '2026'. Got: \(result)")
    }

    func testOCROnBlankImageIsEmpty() async {
        let blank = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400)).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
        }
        let result = await DocTools.recognizeText(in: blank)
        XCTAssertTrue(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      "Blank page should yield no text, got: \(result)")
    }

    // MARK: - PDF generation produces a valid multi-page document

    func testPDFGenerationProducesValidMultiPagePDF() {
        let pages = [textImage("Page One"), textImage("Page Two"), textImage("Page Three")]
        let data = DocTools.makePDF(from: pages)

        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
        // Valid PDFs start with the %PDF- header.
        let header = String(data: data.prefix(5), encoding: .ascii)
        XCTAssertEqual(header, "%PDF-", "Output is not a valid PDF (header: \(header ?? "nil"))")

        let doc = PDFDocument(data: data)
        XCTAssertNotNil(doc, "PDFKit could not parse the generated PDF")
        XCTAssertEqual(doc?.pageCount, 3, "Expected 3 pages")
    }

    func testSinglePagePDF() {
        let data = DocTools.makePDF(from: [textImage("Solo")])
        XCTAssertEqual(PDFDocument(data: data)?.pageCount, 1)
    }
}
