//
//  ViewController.swift
//  WhatConsole
//
//  Created by Valmir Junior on 29/10/20.
//

import UIKit
import Vision

final class ViewController: UIViewController {
    
    // MARK: - Properties
    lazy var classificationRequest: VNCoreMLRequest? = {
        guard let visionModule = try? VNCoreMLModel(for: Console(configuration: MLModelConfiguration()).model) else {return nil}
        let request = VNCoreMLRequest(model: visionModule) { [weak self] (request, _) in
            self?.processObservations(for: request)
        }
        request.imageCropAndScaleOption = .scaleFit
        return request
    }()
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelResult: UILabel!
    
    
    // MARK: - Super Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Methods
    func showPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func classify(image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let ciimage = CIImage(image: image)!
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(ciImage: ciimage, orientation: orientation)
            do {
                guard let classification = self.classificationRequest else {throw DefaultError.runtimeError("")}
                try handler.perform([classification])
            } catch {
                print(error)
            }
        }
    }
    
    func processObservations(for request: VNRequest) {
        DispatchQueue.main.async {
            guard let observation = (request.results as? [VNClassificationObservation])?.first else {return}
            let confidence = "Resultado: \(String(format: "%0.2f", observation.confidence * 100))%"
            self.labelResult.text = "\(confidence): \(observation.identifier)"
        }
    }
    
    // MARK: - IBActions
    @IBAction func showCamera(_ sender: Any) {
        showPicker(sourceType: .camera)
    }
    
    @IBAction func showLibrary(_ sender: Any) {
        showPicker(sourceType: .photoLibrary)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            classify(image: image)
        }
        
        dismiss(animated: true, completion: nil)
    }
}
