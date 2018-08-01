//
//  ViewController.swift
//  Excel2Strings
//
//  Created by Isaac on 2018/7/4.
//  Copyright © 2018年 IsaacPan. All rights reserved.
//

import Cocoa
import CoreFoundation

class ViewController: NSViewController {

    @IBOutlet weak var primaryView: NSView!
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var mergeButton: NSButton!
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var contentLabel: NSTextField!
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var waitingView: NSProgressIndicator!
    
    var primaryPath: String?
    var contentPath: String?
    var contentSheet: BRAWorksheet?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    private func setUI() {
        progressView.isHidden = true
        waitingView.isDisplayedWhenStopped = false
    }
    
    @IBAction func primaryButtonClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select .xlsx File"
        openPanel.allowedFileTypes = ["xlsx"]
        performOnMain {
            openPanel.beginSheetModal(for: self.view.window!) {
                [unowned self] (response) in
                if response == .OK {
                    if let url = openPanel.url {
                        let fileName = url.lastPathComponent
                        self.primaryLabel.stringValue = fileName
                        self.primaryPath = url.path
                    }
                }
            }
        }
    }
    
    @IBAction func contentButtonClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select .xlsx File"
        openPanel.allowedFileTypes = ["xlsx"]
        performOnMain {
            openPanel.beginSheetModal(for: self.view.window!) {
                [unowned self] (response) in
                if response == .OK {
                    if let url = openPanel.url {
                        let fileName = url.lastPathComponent
                        self.contentLabel.stringValue = fileName
                        self.contentPath = url.path
                    }
                }
            }
        }
    }

    @IBAction func mergeButtonClicked(_ sender: NSButton) {
        
        if let path = primaryPath, let contentPath = contentPath {
            self.progressView.isHidden = false
            self.progressView.minValue = 2
            self.progressView.doubleValue = 2
            mergeButton.isEnabled = false
            contentSheet = BRAOfficeDocumentPackage.open(contentPath)?.workbook.worksheets.first as? BRAWorksheet
            processExcel(path: path)
        } else {
            showAlert("Two .xlsx Files Are Required!")
        }
    }
    
    
    /// Merge Process
    ///
    /// - Parameter path: Primary xlsx File Path
    private func processExcel(path: String) {
        let allSheet = BRAOfficeDocumentPackage.open(path)
        let lock = DispatchSemaphore(value: 1)
        if let currentSheet = allSheet?.workbook.worksheets.first as? BRAWorksheet {
            let cellRowsCount = currentSheet.rows.count
            let cellColumnsCount = (currentSheet.rows.firstObject as? BRARow)?.cells.count ?? 5
            self.progressView.minValue = 2
            self.progressView.maxValue = Double(cellRowsCount)
            performOnGlobal {
                for i in 2 ..< cellRowsCount+1 {
                    let enValueIndex = "C\(i)"
                    let enValue = currentSheet.cell(forCellReference: enValueIndex)?.stringValue()
                    let chValueIndex = "D\(i)"
                    let chValue = currentSheet.cell(forCellReference: chValueIndex)?.stringValue()
                    if let en = enValue, let ch = chValue {
                        let values = self.match(en: en, ch: ch)
                        for (key,value) in values {
                            for j in 5 ..< cellColumnsCount+1 {
                                if let letterIndex = j.numberToABC() {
                                    let index = "\(letterIndex)1"
                                    if key == currentSheet.cell(forCellReference: index)?.stringValue() {
                                        let valueIndex = "\(letterIndex)\(i)"
                                        _ = lock.wait(timeout: .distantFuture)
                                        if value != "" {
                                            currentSheet.cell(forCellReference: valueIndex, shouldCreate: true)?.setStringValue(value)
                                        } else {
                                            currentSheet.cell(forCellReference: valueIndex, shouldCreate: true)?.setCellFillWithForegroundColor(NSColor.red, backgroundColor: NSColor.red, andPatternType: kBRACellFillPatternTypeDarkTrellis)
                                        }
                                        lock.signal()
                                    }
                                }
                            }
                        }
                    }
                    for column in currentSheet.columns {
                        if let col = column as? BRAColumn {
                            col.width = 20
                        }
                    }
                    performOnMain {
                        self.progressView.doubleValue = Double(i)
                        if i == cellRowsCount {
                            self.progressView.isHidden = true
                            self.waitingView.startAnimation(self)
                        }
                    }
                }
                performOnGlobal {
                    let path = NSHomeDirectory() + "/Documents/Final.xlsx"
                    allSheet?.save(as: path)
                    performOnMain {
                        let savePanel = NSSavePanel()
                        savePanel.allowedFileTypes = ["xlsx"]
                        savePanel.canCreateDirectories = true
                        savePanel.isExtensionHidden = true
                        savePanel.beginSheetModal(for: self.view.window!, completionHandler: {
                            [unowned self] (response) in
                            if response == .OK {
                                do {
                                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                                    if let url = savePanel.url {
                                        print(url)
                                        try data.write(to: url)
                                    }
                                    self.waitingView.stopAnimation(self)
                                } catch let error {
                                    self.showAlert(error.localizedDescription)
                                }
                            }
                            self.waitingView.stopAnimation(self)
                            self.mergeButton.isEnabled = true
                        })
                    }
                }
            }
        }
    }
    
    
    /// Match Content in Content xlsx File
    ///
    /// - Parameters:
    ///   - en: English content
    ///   - ch: Chinese content
    /// - Returns: result dictionary
    private func match(en:String, ch:String) -> [String: String] {
        var result = [String:String]()
        if let contentCurrentSheet = self.contentSheet {
            for row in contentCurrentSheet.rows {
                if let row = row as? BRARow {
                    if let enValue = (row.cells[0] as? BRACell)?.stringValue(),
                        let chValue = (row.cells[1] as? BRACell)?.stringValue() {
                        if enValue == en {
                            self.updateResult(row: row, sheet: contentCurrentSheet, result: &result)
                            break
                        }
                        if chValue == ch {
                            self.updateResult(row: row, sheet: contentCurrentSheet, result: &result)
                            break
                        }
                        if en.blurryEnMatch(with: enValue) {
                            self.updateResult(row: row, sheet: contentCurrentSheet, result: &result)
                            break
                        }
                        if ch.blurryCHMatch(with: chValue) {
                            self.updateResult(row: row, sheet: contentCurrentSheet, result: &result)
                            break
                        }
                    }
                }
            }
            if result.count == 0 {
                if let firsrRowCount = (contentCurrentSheet.rows.firstObject as? BRARow)?.cells.count {
                    if firsrRowCount > 2 {
                        for i in 2 ..< firsrRowCount {
                            if let letterIndex = (i+1).numberToABC() {
                                let index = "\(letterIndex)1"
                                if let key = contentCurrentSheet.cell(forCellReference: index)?.stringValue() {
                                    result[key] = ""
                                }
                            }
                        }
                    }
                }
            }
        }
        return result
    }
    
    
    /// Update Primary xlsx File Content.
    ///
    /// - Parameters:
    ///   - row: row to update
    ///   - sheet: sheet to update
    ///   - result: result dictionary
    private func updateResult(row: BRARow, sheet: BRAWorksheet, result: inout [String: String]) {
        for i in 2 ..< row.cells.count {
            if let letterIndex = (i+1).numberToABC() {
                let index = "\(letterIndex)1"
                if let key = sheet.cell(forCellReference: index)?.stringValue() {
                    result[key] = (row.cells[i] as? BRACell)?.stringValue() ?? ""
                }
            }
        }
    }
    
    
    /// Show an alert with content.
    ///
    /// - Parameter content: content text to show
    private func showAlert(_ content: String) {
        let alert = NSAlert()
        alert.messageText = content
        alert.alertStyle = NSAlert.Style.critical
        alert.beginSheetModal(for: self.view.window!) { _ in}
    }
}

