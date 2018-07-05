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
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var contentButton: NSButton!
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
    override var representedObject: Any? {
        didSet {

        }
    }
    
    private func setUI() {
        progressView.isHidden = true
        waitingView.isDisplayedWhenStopped = false
    }
    
    @IBAction func primaryButtonClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "打开初始xlsx文件"
        openPanel.allowedFileTypes = ["xlsx"]
        performOnMain {
            openPanel.beginSheetModal(for: self.view.window!) { (response) in
                if response.rawValue == 1 {
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
        openPanel.prompt = "打开内容xlsx文件"
        openPanel.allowedFileTypes = ["xlsx"]
        performOnMain {
            openPanel.beginSheetModal(for: self.view.window!) { (response) in
                if response.rawValue == 1 {
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
            self.progressView.doubleValue = 0
            mergeButton.isEnabled = false
            contentSheet = BRAOfficeDocumentPackage.open(contentPath)?.workbook.worksheets.first as? BRAWorksheet
            processExcel(path: path)
        } else {
            let alert = NSAlert()
            alert.messageText = "必须选择两份xlsx文件"
            alert.alertStyle = NSAlert.Style.critical
            alert.beginSheetModal(for: self.view.window!) { _ in}
        }
    }
    
    private func processExcel(path: String) {
        let allSheet = BRAOfficeDocumentPackage.open(path)
        let lock = DispatchSemaphore(value: 1)
        if let currentSheet = allSheet?.workbook.worksheets.first as? BRAWorksheet {
            let cellRowsCount = currentSheet.rows.count
            let cellColumnsCount = (currentSheet.rows.firstObject as? BRARow)?.cells.count ?? 5
            
            self.progressView.maxValue = Double(cellRowsCount)
            performOnGlobal {
                for i in 2 ..< cellRowsCount+1 {
                    let enValueIndex = "C\(i)"
                    let enValue = currentSheet.cell(forCellReference: enValueIndex)?.stringValue()
                    let chValueIndex = "D\(i)"
                    let chValue = currentSheet.cell(forCellReference: chValueIndex)?.stringValue()
                    let values = self.match(en: enValue, ch: chValue, expectResultsCount: cellColumnsCount-4)
                    for (key,value) in values {
                        for j in 5 ..< cellColumnsCount+1 {
                        
                            if let letterIndex = j.numberToABC() {
                                let index = "\(letterIndex)1"
                                if key == currentSheet.cell(forCellReference: index)?.stringValue() {
                                    let valueIndex = "\(letterIndex)\(i)"
                                    _ = lock.wait(timeout: .distantFuture)
                                    currentSheet.cell(forCellReference: valueIndex, shouldCreate: true)?.setStringValue(value)
                                   
                                    lock.signal()
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
                        savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (response) in
                            if response == .OK {
                                if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                                    let url = savePanel.url {
                                    print(url)
                                    try? data.write(to: url)
                                    self.waitingView.stopAnimation(self)
                                }
                            } else {
                                self.waitingView.stopAnimation(self)
                            }
                            self.mergeButton.isEnabled = true
                        })
                    }
                }
            }
        }
    }
    
    private func match(en:String?, ch:String?, expectResultsCount: Int) -> [String: String] {
        var result = [String:String]()
        if let contentCurrentSheet = self.contentSheet {
            for row in contentCurrentSheet.rows {
                if let row = row as? BRARow {
                    let enValue = (row.cells[0] as? BRACell)?.stringValue()
                    let chValue = (row.cells[1] as? BRACell)?.stringValue()
                    if enValue == en || chValue == ch {
                        for i in 2 ..< row.cells.count {
                            if let letterIndex = (i+1).numberToABC() {
                                let index = "\(letterIndex)1"
                                if let key = contentCurrentSheet.cell(forCellReference: index)?.stringValue() {
                                    result[key] = (row.cells[i] as? BRACell)?.stringValue() ?? ""
                                }
                            }
                        }
                    }
                }
            }
        }
        return result
    }
}

