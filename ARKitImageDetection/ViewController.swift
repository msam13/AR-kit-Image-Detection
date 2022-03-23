/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import CoreMedia
class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    
    
    private func makeDinosaurVideo(size: CGSize) -> SCNNode? {
      // 1
      guard let videoURL = Bundle.main.url(forResource: "dinosaur",
                                           withExtension: "mp4") else {
                                            return nil
      }
      
      // 2
      let avPlayerItem = AVPlayerItem(url: videoURL)
      let avPlayer = AVPlayer(playerItem: avPlayerItem)
      avPlayer.play()
      
      // 3
      NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: nil,
        queue: nil) { notification in
            //avPlayer.seek(to: .kCMTimeZero)
          avPlayer.play()
      }
      
      // 4
      let avMaterial = SCNMaterial()
      avMaterial.diffuse.contents = avPlayer
      
      // 5
      let videoPlane = SCNPlane(width: size.width, height: size.height)
      videoPlane.materials = [avMaterial]
      
      // 6
      let videoNode = SCNNode(geometry: videoPlane)
      videoNode.eulerAngles.x = -.pi / 2
      return videoNode
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            
           let imageName = referenceImage.name ?? ""
            let name = imageAnchor.referenceImage.name!
               print("you found a \(name) image")

               let size = imageAnchor.referenceImage.physicalSize
            if let videoNode = self.makeDinosaurVideo(size: size) {
                 node.addChildNode(videoNode)
                 node.opacity = 1
                    
                      
        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
        
    }

}
