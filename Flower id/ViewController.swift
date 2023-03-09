//
//  ViewController.swift
//  Flower id
//
//  Created by User01 on 6/3/23.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var wikiLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
//            imageView.image = userPickedImage
            
            guard let convertedCIImg = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage into CI Image")
            }
            
            detect(image: convertedCIImg)
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Failed to process image! ")
            }
            
            if let classification = results.first{
                if classification.identifier.isEmpty{
                    self.navigationItem.title = "Flower not Found !"
                }else{
                    self.navigationItem.title = classification.identifier.capitalized
                    self.requestInfo(flowerName: classification.identifier)
                }
            }
            
            //            print(results)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }
        catch{
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            
            
        ]
        
        let urlString = ("\(wikipediaURl)?format=json&action=query&prop=extracts&exintro&explaintext&redirects=1&titles=\(flowerName)")
        
        AF.request(urlString, method: .get, parameters: parameters).validate(contentType: ["application/json"]).responseJSON { (response) in
            
            switch response.result {
            case let .success(value):
                let wikipediaJSON = JSON(value)
                if let pageid = wikipediaJSON["query"]["pageids"][0].string {
                    if let extract = wikipediaJSON["query"]["pages"][pageid]["extract"].string {
                        let flowerImageURL = wikipediaJSON["query"]["pages"][pageid]["thumbnail"]["source"].string
                        self.wikiLabel.numberOfLines = 0
                        self.wikiLabel.text = extract
                        self.wikiLabel.sizeToFit()
                        self.imageView.sd_setImage(with: URL(string: flowerImageURL!))
                    }
                }
            case let .failure(error):
                fatalError(error.localizedDescription)
            }
        }
        
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
}
