//
//  ViewController.swift
//  FeImage
//  Todo:
//  1. 右侧图片的放大缩小
//  2. 动态加载图片，减少内存占用
//  3. 右侧图片显示边框
//  4. 图标(ok)
//  5. 左侧双击图片，右侧显示
//  6. dock 点击显示窗口(ok)
//  7. 双击图片直接打开应用并加载图片
//  8. 上传到 app store
//  Created by feshfans on 2018/5/26.
//  Copyright © 2018年 feshfans. All rights reserved.
//

import Cocoa
import os.log

class ViewController: NSSplitViewController {
    
    @IBOutlet weak var imagesSummary : NSView!
    @IBOutlet weak var contentImageView : NSImageView!
    @IBOutlet weak var scrollView : NSScrollView!
    
    var imagesMap : [Int:NSImage] = [:]
    // 图片大小
    let imageSize = 120
    // 左侧滚动条的宽度
    let scrollWidth = 210
    // 图片url集合
    var imagesUrl : [URL] = []
    // 图片索引，即第N张图片
    var imageIndex : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.scrollerStyle = .overlay
        scrollView.hasVerticalRuler = true
        scrollView.scrollerKnobStyle = .dark
        scrollView.verticalScrollElasticity = .automatic
        scrollView.scrollToTop()
        scrollView.wantsLayer = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction
    func selectImagesFromToolBar(sender : Any?) {
        selectImages()
    }
    
    
    @IBAction
    func selectImagesFromMenu(sender : Any?) {
        selectImages()
    }
    
    func selectImages() {
        let openFileDlg = NSOpenPanel()
        openFileDlg.title = "选择一个图片文件"
        openFileDlg.allowsMultipleSelection = true
        openFileDlg.showsResizeIndicator = true
        openFileDlg.showsHiddenFiles = false
        openFileDlg.canChooseDirectories = false
        openFileDlg.canCreateDirectories = false
        openFileDlg.allowedFileTypes = ["png","jpg"]
        if(openFileDlg.runModal() == NSApplication.ModalResponse.OK){
            let urls :[URL] = openFileDlg.urls
            for url in urls {
                
                imagesUrl.append(url)
            }
            buildImageSummary()
            showImage(imageIndex: 0,oldImageIndex: 0)
        }
    }
    
    @IBAction
    func selectImageDirFromMenu(sender : Any?){
        selectImageDir()
    }
    
    @IBAction
    func selectImageDirFromToolBar(sender : Any?){
        selectImageDir()
    }
    
    @IBAction
    func zoomInFromToolBar(sender : Any?) {
        
    }
    
    func zoomIn() {
        
    }
    
    
    func selectImageDir(){
        do {
            let openPanel = NSOpenPanel()
            openPanel.title = "选择一个文件夹"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.showsHiddenFiles = false
            openPanel.allowedFileTypes = ["png","jpg"]
            if(openPanel.runModal() == NSApplication.ModalResponse.OK){
                let imageDirUrl = openPanel.url
                let fileManager = FileManager.default
                let urls = try fileManager.contentsOfDirectory(at: imageDirUrl!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                for url in urls{
                    if(url.absoluteString.contains(".jpg")||url.absoluteString.contains(".png")){
                        imagesUrl.append(url)
                    }
                }
                buildImageSummary()
                showImage(imageIndex: 0,oldImageIndex: 0)
            }
        }
        catch let e as NSError{
            
            os_log("code:%d, error:%s, userInfo:%s", e.code, e.domain, e.userInfo)
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.warning
            alert.messageText = "打开文件夹失败，请重试"
            alert.runModal()
            
        }
    }
    
    @IBAction
    func nextImage(sender : Any?){
        let oldImageIndex = imageIndex
        if(imageIndex == imagesUrl.count-1){
            imageIndex = 0
        } else {
            imageIndex = imageIndex + 1
        }
        
        showImage(imageIndex: imageIndex,oldImageIndex: oldImageIndex)
        let scrollHeight = getScrollHeight()
        scrollView.documentView?.scroll(NSPoint(x: 45, y: scrollHeight-(imageSize*imageIndex+90)-imageSize*3))
    }
    
    @IBAction
    func preImage(sender : Any?){
        let oldImageIndex = imageIndex
        if (imageIndex == 0){
            imageIndex = imagesUrl.count - 1
        } else {
            imageIndex = imageIndex - 1
        }
        showImage(imageIndex: imageIndex,oldImageIndex:oldImageIndex)
        
        let scrollHeight = getScrollHeight()
        scrollView.documentView?.scroll(NSPoint(x: 45, y: scrollHeight-(imageSize*imageIndex+90)-imageSize*3))
    }
    
    /**
     根据图片 url 构建左侧图片缩略图
    */
    func buildImageSummary() {
        
        let theSubviews : Array = scrollView.documentView!.subviews
        for subView in theSubviews {
            subView.removeFromSuperview()
        }

        let scrollHeight = getScrollHeight()
        scrollView.setFrameSize(NSSize(width: scrollWidth, height: scrollHeight))
        
        for (index,url) in imagesUrl.enumerated() {
            let image = NSImage(byReferencing: url)
            let imageView = NSImageView.init()
            if(index == 0){
                imageView.wantsLayer = true
                imageView.layer?.borderWidth = 2
                imageView.layer?.borderColor = CGColor.black
            }
            imageView.frame = NSRect(x:45,y:scrollHeight-((index+1)*imageSize+45),width:imageSize,height:imageSize)
            
            imageView.image = image
            //imageView.target = self
            //imageView.action = #selector(ViewController.imageClick)
            scrollView.documentView?.addSubview(imageView)
            
        }
        
        os_log("%d", scrollView.subviews.count)
    }
    
    func showImage(imageIndex : Int,oldImageIndex : Int) {
        //显示内容图片
        let url = imagesUrl[imageIndex]
        let image = NSImage(byReferencing: url)
        
        let _ : NSBitmapImageRep = NSBitmapImageRep(cgImage: image as! CGImage)
        
        os_log("width:%f,heigth:%f", image.size.width,image.size.height)
        
        contentImageView.image = image
        os_log("width:%f,heigth:%f", contentImageView.fittingSize.width,contentImageView.fittingSize.height)
        // 高亮显示左侧第 imageIndex 张图片
        let subViews : [NSImageView] = scrollView.documentView!.subviews as! [NSImageView]
        os_log("imageIndex:%d,size:%d", imageIndex,subViews.count)
        //去掉之前图片的高亮
        let oldSubView = subViews[oldImageIndex]
        oldSubView.layer?.borderWidth = 0
        //高亮当前图片
        let currentSubView = subViews[imageIndex]
        currentSubView.wantsLayer = true
        currentSubView.layer?.borderWidth = 2
        currentSubView.layer?.borderColor = CGColor.black
        
    }
    
    func getScrollHeight() -> Int {
        return imageSize*imagesUrl.count+90
    }
    
    @objc func imageClick(){
        os_log("click")
    }
}

extension NSScrollView {
    
//    public func  isFlipped() -> Bool{
//        return true
//    }
    
    public func scrollToTop(){
        if let documentView = self.documentView {
            if(documentView.isFlipped){
                documentView.scroll(.zero)
            } else {
                let maxHeight = max(bounds.height, documentView.bounds.height)
                documentView.scroll(NSPoint(x: 0, y: maxHeight))
            }
        }
    }
}
