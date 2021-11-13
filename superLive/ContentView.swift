//
//  ContentView.swift
//  superLive
//
//  Created by Alexis Ponce on 10/20/21.
//

import SwiftUI
import CoreData
import AVFoundation
import HaishinKit
import ReplayKit
import VideoToolbox

var multiCapSession:AVCaptureMultiCamSession!
struct ContentView: View {
    var body: some View {
        camerPreview()
    }
}


struct camerPreview: View{
    @StateObject var camera = CameraModel()
    @StateObject var stream = Stream()
    @State var mapModel = MapModel()
    @State var mapView :MapView!
    @State var recordButton = "Start Recording"
    @State var workoutButton = "Start Workout"
     var semaphore = DispatchSemaphore(value: 1)
    var body: some View{
        ZStack{
//            RoundedRectangle(cornerRadius: 20)
//                .foregroundColor(.orange)
//            VStack{
//                HStack{
//
//                RoundedRectangle(cornerRadius: 20)
//                    .foregroundColor(.blue)
//                    .frame(width: 80, height: 80, alignment: .leading)
//                    Spacer()
//                }
//                Spacer()
//                HStack{
//                    Spacer()
//                RoundedRectangle(cornerRadius: 20)
//                    .foregroundColor(.red)
//                    .frame(width: 80, height: 80, alignment: .bottomTrailing)
//                }
//            }
            backCameraPreview(camera: camera)
            VStack{
                HStack(){
                        MapView(mapModel: mapModel)
                        .foregroundColor(.orange)
                        .frame(width: 190, height: 120, alignment: .topLeading)

                    Spacer()
                    Text("Distance: \(mapModel.getDistance())")
                        .padding()
                        
                        
                    Spacer()
                }
               Spacer()
                HStack(){
                    VStack{
                    Button(recordButton){
                        if !stream.isStreaming{
                            stream.startStream()
                            stream.isStreaming.toggle()
                            recordButton = "Stop Recording"
                        }else{
                            recordButton = "Start Recording"
                            stream.stopRecording()
                        }
                    }
                    .padding(.all)
                        Button(workoutButton){
                            if mapModel.workoutStarted{
                                workoutButton = "Start Workout"
                                mapModel.workoutStarted.toggle()
                            }else{
                                workoutButton = "Stop Workout"
                             mapModel.workoutStarted.toggle()
                                
                            }
                           
                        }
                    }
                    //Spacer().frame(width: 5).background(Color.red)
                    
                    frontCameraPreview(camera: camera).background(Color.black)
                        .padding(.all)
                        .frame(width: camera.frontCamWidth, height: camera.frontCamHeight, alignment: .bottomTrailing)
                    
                       // .scaledToFill()
                        
                        
                }
                
        }
    }
}
}
class CameraModel: ObservableObject{
    @Published var session =  AVCaptureMultiCamSession()
    @Published var alert = false
    @Published var frontCamPort: AVCaptureDeviceInput.Port!
    @Published var backCamPort : AVCaptureDeviceInput.Port!
    @Published var audioPort : AVCaptureDeviceInput.Port!
    @Published var frontPreview : AVCaptureVideoPreviewLayer!
    @Published var backPreview : AVCaptureVideoPreviewLayer!
    @Published var hasChecked = false
    @Published var frontCamHeight = 0.0
    @Published var frontCamWidth = 0.0
    
    func check(){
        guard AVCaptureMultiCamSession.isMultiCamSupported else{
            print("Multi Camm sesion not supported on device")
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            setup()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ status in
                if status {
                    self.setup()
                }
            }
        case .restricted:
            alert.toggle()
            return
        case .denied:
            alert.toggle()
            return
        @unknown default:
            return
        }
    }
    
    func setup(){
        
        let frontCamDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        let backCamDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let micDevice = AVCaptureDevice.default(for: .audio)
        
        let (frontCamPort, backCamPort, audioPort) = setupCamSessionInputOutputs(fronCamDevice: frontCamDevice, backCamDevice: backCamDevice, audioDevice: micDevice)
        if frontCamPort == nil{
            print("it is nil")
        }else{
            print("it is not nil")
        }
        guard (frontCamPort != nil) else{
            print("frontCamPort return nil")
            return
        }
        self.frontCamPort = frontCamPort!
        guard (backCamPort != nil) else{
            print("backCamPort return nil")
            return
        }
        self.backCamPort = backCamPort!
        guard (audioPort != nil) else{
            print("Audio port return nil")
            return
        }
        self.audioPort = audioPort!
        
        
    }
    
    func setupCamSessionInputOutputs(fronCamDevice: AVCaptureDevice!, backCamDevice: AVCaptureDevice!, audioDevice: AVCaptureDevice!)-> (AVCaptureInput.Port?, AVCaptureInput.Port?, AVCaptureInput.Port?){
        
        var frontCamPort: AVCaptureInput.Port!
        var backCamPort: AVCaptureInput.Port!
        var audioPort: AVCaptureInput.Port!
        
        session.beginConfiguration()
        
        do{
            let frontCamInput = try AVCaptureDeviceInput(device: fronCamDevice)
            let frontCamPortsArray = frontCamInput.ports
            
            if session.canAddInput(frontCamInput){
                session.addInputWithNoConnections(frontCamInput)
            }else{
                print("can not add fronCamInput to the sesion")
            }
            
            for port in frontCamPortsArray{
                if port.mediaType == .video{
                    frontCamPort = port
                }
            }
        }catch{
            print(error.localizedDescription)
            return(nil,nil,nil)
        }
        
        do{
            let backCamInput = try AVCaptureDeviceInput(device: backCamDevice)
            let backCamPortsArray = backCamInput.ports
            
            if session.canAddInput(backCamInput){
                session.addInputWithNoConnections(backCamInput)
            }else{
                print("can not add back cam input to seesion")
            }
            
            for port in backCamPortsArray{
                if port.mediaType == .video{
                    backCamPort = port
                }
            }
        }catch{
            print(error.localizedDescription)
            return(nil,nil,nil)
        }
        
        do{
            let micInput = try AVCaptureDeviceInput(device: audioDevice)
            let audioPortsArray = micInput.ports
            
            if session.canAddInput(micInput){
                session.addInputWithNoConnections(micInput)
            }else{
                print("can not add the audio input to the session")
            }
            
            for port in audioPortsArray{
                if port.mediaType == .audio{
                    audioPort = port
                }
            }
        }
        catch{
            print(error.localizedDescription)
            return(nil,nil,nil)
        }
        
        session.commitConfiguration()
        return(frontCamPort,backCamPort,audioPort)
    }
}

class Stream: ObservableObject{
    @Published var screenRecorder = RPScreenRecorder.shared()
    var rtmpConnection = RTMPConnection()
    var rtmpStream:RTMPStream!
    var isStreaming = false
    func setup(){
        rtmpStream = RTMPStream(connection: rtmpConnection)
        self.rtmpStream.audioSettings = [// sets up the audio settings
            .sampleRate: 44100.0,
            .bitrate: 32 * 1024,
            .actualBitrate: 96000,
        ]

        self.rtmpStream.recorderSettings = [// sets up the recording settings
            AVMediaType.audio: [
                AVNumberOfChannelsKey: 0,
                AVSampleRateKey: 0
            ]
        ]
        
        //let streamURL = "rtmp://phx.contribute.live-video.net/app/"
//        let streamURL = "rtmps://a.rtmps.youtube.com/live2/"// url where the stream will be sent to
//        //let pub = "live_205645450_W0qr5v0uoq7oQHw4SMgYSesOq7UODk"
//        let pub = "6yay-erur-6kxs-py4g-drvq"// the key for the account where the stream is being sent
//        self.rtmpConnection.connect(streamURL, arguments: nil)// connects to the stream url
//        self.rtmpStream.publish(pub)// sends the public key
        self.rtmpConnection.connect("rtmps://b.rtmps.youtube.com/live2?backup=1/",arguments: nil);
        //self.rtmpStream.publish("a96x-69j1-4e7u-zqg9-ac2g");
        self.rtmpStream.publish("xg3y-25t4-97d3-f5qg-dfjm")
        self.rtmpStream.attachAudio(nil)
        self.rtmpStream.attachCamera(nil)
    }
    func startStream(){
        setup()
        screenRecorder.startCapture{ (sampleBuffer, sampleBufferType, error) in
            if error != nil{
                print("There was an error when starting the recording")
            }
            switch sampleBufferType{
            case .video:

                if let description = CMSampleBufferGetFormatDescription(sampleBuffer){// stores the sample buffer format description
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)// stores the dimensions of the sample buffer
                    self.rtmpStream.videoSettings = [
                        .width: dimensions.width,// stores the width
                        .height: dimensions.height,// stored the heigh
                        .profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel// sets the profile of the video
                    ]
                }
                self.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video);
                return
            case .audioApp:

                return
            case .audioMic:
                self.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .audio)
                return
            @unknown default:
                print("Got weird input")
            }
        }completionHandler : { error in

        }
    }
    
    func stopRecording(){
        screenRecorder.stopCapture{ error in
            if error != nil{
                print("error when stopping the recording")
            }
        }
    }
}

struct frontCameraPreview: UIViewRepresentable {
    @ObservedObject var camera : CameraModel
    func makeUIView(context: Context) -> some UIView {
        let smallViewRect = CGRect(x: 0, y: 0, width: 191, height: 176)
        camera.frontCamWidth = 191.0
        camera.frontCamHeight = 176.0
       // let view = UIView(frame: UIScreen.main.bounds)
        let view = UIView(frame: smallViewRect)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        
        
        
        camera.session.beginConfiguration()
        if !camera.hasChecked{
            camera.check()
            camera.hasChecked = true
        }
        camera.frontPreview = AVCaptureVideoPreviewLayer()
        camera.frontPreview.setSessionWithNoConnection(camera.session)
        let frontVidPreviewLayerConection = AVCaptureConnection(inputPort: camera.frontCamPort, videoPreviewLayer: camera.frontPreview)
        if camera.session.canAddConnection(frontVidPreviewLayerConection){
            camera.session.addConnection(frontVidPreviewLayerConection)
            camera.frontPreview.frame = view.frame
            camera.frontPreview.videoGravity = .resizeAspectFill
        }else{
            print("Could not add the frontVidePreviewLayerConnection")
        }
        
        view.layer.addSublayer(camera.frontPreview)
        
//       view.bounds = .init(x: 0, y: 0, width: 50, height: 50)
        camera.session.commitConfiguration()
        return view
        
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct backCameraPreview : UIViewRepresentable{
   
    @ObservedObject var camera : CameraModel
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        if !camera.hasChecked{
            camera.check()
            camera.hasChecked = true
        }
        camera.session.beginConfiguration()
        camera.backPreview = AVCaptureVideoPreviewLayer()
        camera.backPreview.setSessionWithNoConnection(camera.session)
        let backVidPreviewLayerConnection = AVCaptureConnection(inputPort: camera.backCamPort, videoPreviewLayer: camera.backPreview)
        if camera.session.canAddConnection(backVidPreviewLayerConnection){
            camera.session.addConnection(backVidPreviewLayerConnection)
            camera.backPreview.frame = view.frame
            camera.backPreview.videoGravity = .resizeAspectFill
        }else{
            print("Could not add backCamConnection to session")
        }
        view.layer.addSublayer(camera.backPreview)
        camera.session.commitConfiguration()
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

