import Cordova
import Foundation


@objc(Downloader) class Downloader : CDVPlugin {
    @objc
    var docController : UIDocumentInteractionController? = nil
    
    @objc
    func download(_ command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        var isError = false

        let args = command.arguments[0] as! NSDictionary
        guard let urlText = (args["url"]  as? String)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("No URL provided")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "No source URL provided"
            )
            
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return;
                    
        }
        guard let url = URL(string: urlText)
 else{
            print("Cannot Make URL from string")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Bad source URL provided"
            )
            
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return;
        }
        
        guard let targetFile = (args["path"] as? String)? .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else{
                   print("Cannot Make target URL from string")
                   pluginResult = CDVPluginResult(
                       status: CDVCommandStatus_ERROR,
                       messageAs: "No dest URL provided"
                   )
                   
                   self.commandDelegate!.send(
                       pluginResult,
                       callbackId: command.callbackId
                   )
                   return;
               }

        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?
        guard let destinationUrl = documentsUrl?.appendingPathComponent(targetFile) else{
            print("Cannot Make dest URL from string")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Bad dest URL provided"
            )
            
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return;
        }

        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("file already exists [\(destinationUrl.path)]")
            do {
                try FileManager().removeItem(atPath: destinationUrl.path)
            }
            catch let error as NSError {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: error.localizedDescription
                )
                
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                )
                
                isError = true
            }
        }
        if !(isError) {
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if (error == nil) {
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            if (try? data!.write(to: destinationUrl, options: [.atomic])) != nil {
                                
                                self.docController = UIDocumentInteractionController(url: destinationUrl)
                                
                                
                                DispatchQueue.main.async {
                                    self.docController?.presentOptionsMenu(from: self.viewController.view.frame, in: self.viewController.view, animated: false)
                                }
                                pluginResult = CDVPluginResult(
                                    status: CDVCommandStatus_OK,
                                    messageAs: documentsUrl?.path
                                )
                                
                                self.commandDelegate!.send(
                                    pluginResult,
                                    callbackId: command.callbackId
                                )
                            }
                        }
                    }
                }
            })
            task.resume()
        }
    }
}
