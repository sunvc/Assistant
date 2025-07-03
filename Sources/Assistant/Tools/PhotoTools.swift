//
//  PhotoTools.swift
//  Assistant
//
//  Created by lynn on 2025/7/3.
//

import SwiftUI
import UIKit
import PhotosUI


public extension View{
  
    @ViewBuilder
    func camera(_ show: Binding<Bool>, selectImage: Binding<UIImage?> )-> some View {
        fullScreenCover(isPresented: show) {
            CameraView(selectedImage: selectImage)
        }
    }
    
    @ViewBuilder
    func photo(_ show: Binding<Bool>, selectImage: Binding<UIImage?> )-> some View {
        fullScreenCover(isPresented: show) {
            PhotoPicker(selectedImage: selectImage)
        }
    }
    
    @ViewBuilder
    func fileImport(_ show: Binding<Bool>, outfile:Binding<URL?>, types: [UTType] = []) -> some View{
        fileImporter(isPresented: show, allowedContentTypes: types){ result in
            switch result {
            case .success(let file):
                defer { file.stopAccessingSecurityScopedResource() }
                guard file.startAccessingSecurityScopedResource(),
                      let filePath = self.documentUrl(file.lastPathComponent) else { return
                }
                
                do{
                    try FileManager.default.copyItem(at: file, to: filePath)
                    outfile.wrappedValue = filePath
                }catch{
                    debugPrint(error.localizedDescription)
                }
                
                
            case .failure(let failure):
                debugPrint(failure.localizedDescription)
            }
            
        }
    }
    
    func documentUrl(_ fileName: String) -> URL?{
        do{
            let filePaeh =  try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return filePaeh.appendingPathComponent(fileName)
        }catch{
            debugPrint(error.localizedDescription)
            return nil
        }
        
    }
    
    
}

// 拍照视图
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// 相册选择器
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}
