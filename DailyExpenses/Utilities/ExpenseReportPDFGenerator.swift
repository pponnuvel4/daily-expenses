import UIKit

enum ExpenseReportPDFGenerator {
    static func makePDF(
        reportTitle: String,
        periodTitle: String,
        expenses: [Expense],
        total: Double,
        categoryTotals: [CategoryTotal]
    ) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var y = margin

            func startPageIfNeeded(requiredHeight: CGFloat) {
                if y + requiredHeight > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
            }

            context.beginPage()

            y = drawTitle(reportTitle, at: y, width: contentWidth, margin: margin)
            y = drawText(periodTitle, font: .systemFont(ofSize: 14), color: .darkGray, at: y + 8, width: contentWidth, margin: margin)
            y = drawText("Total: \(CurrencyFormatter.string(from: total))", font: .boldSystemFont(ofSize: 18), color: .black, at: y + 16, width: contentWidth, margin: margin)

            if !categoryTotals.isEmpty {
                y += 24
                y = drawText("By Category", font: .boldSystemFont(ofSize: 16), color: .black, at: y, width: contentWidth, margin: margin)
                for item in categoryTotals {
                    startPageIfNeeded(requiredHeight: 22)
                    let line = "\(item.category.title): \(CurrencyFormatter.string(from: item.amount)) (\(Int(item.percentage.rounded()))%)"
                    y = drawText(line, font: .systemFont(ofSize: 13), color: .black, at: y + 8, width: contentWidth, margin: margin)
                }
            }

            y += 24
            startPageIfNeeded(requiredHeight: 30)
            y = drawText("Expenses", font: .boldSystemFont(ofSize: 16), color: .black, at: y, width: contentWidth, margin: margin)

            if expenses.isEmpty {
                y = drawText("No expenses recorded for this period.", font: .italicSystemFont(ofSize: 13), color: .darkGray, at: y + 10, width: contentWidth, margin: margin)
            } else {
                for expense in expenses {
                    startPageIfNeeded(requiredHeight: 52)
                    y = drawExpense(expense, at: y + 12, width: contentWidth, margin: margin)
                }
            }

            let generatedAt = Date().formatted(date: .abbreviated, time: .shortened)
            startPageIfNeeded(requiredHeight: 20)
            _ = drawText("Generated \(generatedAt)", font: .systemFont(ofSize: 11), color: .gray, at: pageHeight - margin - 14, width: contentWidth, margin: margin)
        }
    }

    private static func drawTitle(_ text: String, at y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        drawText(text, font: .boldSystemFont(ofSize: 24), color: .black, at: y, width: width, margin: margin)
    }

    private static func drawExpense(_ expense: Expense, at y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = y
        currentY = drawText(expense.displayTitle, font: .boldSystemFont(ofSize: 14), color: .black, at: currentY, width: width, margin: margin)

        let dateText = expense.date.formatted(date: .abbreviated, time: .omitted)
        var detail = "\(dateText) • \(expense.category.title)"
        if let moneyFlow = expense.resolvedMoneyFlow {
            detail += " • \(moneyFlow.title)"
        }
        if let quantityLabel = expense.quantityLabel {
            detail += " • \(quantityLabel)"
        }
        currentY = drawText(detail, font: .systemFont(ofSize: 12), color: .darkGray, at: currentY + 4, width: width, margin: margin)

        if let unitPriceLabel = expense.unitPriceLabel {
            currentY = drawText(unitPriceLabel, font: .systemFont(ofSize: 12), color: .gray, at: currentY + 4, width: width, margin: margin)
        }

        if let note = expense.note, !note.isEmpty {
            currentY = drawText(note, font: .systemFont(ofSize: 12), color: .gray, at: currentY + 4, width: width, margin: margin)
        }

        currentY = drawText(CurrencyFormatter.string(from: expense.amount), font: .boldSystemFont(ofSize: 14), color: .black, at: currentY + 6, width: width, margin: margin)
        return currentY
    }

    @discardableResult
    private static func drawText(_ text: String, font: UIFont, color: UIColor, at y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        (text as NSString).draw(
            in: CGRect(x: margin, y: y, width: width, height: ceil(boundingRect.height)),
            withAttributes: attributes
        )

        return y + ceil(boundingRect.height)
    }
}
