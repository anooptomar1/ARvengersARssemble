/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var nodeModel:SCNNode!
    let nodeName = "SketchUp"
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        /*
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This sample app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
         */
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self

//        sceneView.addGestureRecognizer(tapGesture)
        
//        let modelScene = SCNScene(named:"Models.scnassets/islands/islands.dae")!
        
//        nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
//        nodeModel.scale = SCNVector3(x: 0.000005, y: 0.000005, z: 0.000005)
    }
    
    func makeCylinder(x: Float = 0, y: Float = 0, z: Float = -0.2) -> SCNNode{
        let cylinder = SCNCylinder(radius: 0.01, height: 1)
        cylinder.firstMaterial?.diffuse.contents = UIColor.red
        let cylinderNode = SCNNode()
        cylinderNode.geometry = cylinder
        cylinderNode.position = SCNVector3(x,y,z)
        return cylinderNode
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let location = touches.first!.location(in: sceneView)
//        // Let's test if a 3D Object was touch
//        var hitTestOptions = [SCNHitTestOption: Any]()
//        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
//
//        //If we collided with an object, add a cylinder
//        //This will be a pin eventually
//        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
//        if let hit = hitResults.first {
//            if let _ = getParent(hit.node) {
//                let cylLoc = hit.worldCoordinates
//                sceneView.scene.rootNode.addChildNode(makeCylinder(x: cylLoc.x,y: cylLoc.y,z: cylLoc.z))
//                print("A wild cylinder appeared at x=\(cylLoc.x) y=\(cylLoc.y) z=\(cylLoc.z)")
//                return
//            }
//        }
//
//        // No object was touch? Try feature points
//        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
//
//        if let hit = hitResultsFeaturePoints.first {
//
//            // Get the rotation matrix of the camera
//            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 0, 0))
//
//            // Combine the matrices
//            let finalTransform = simd_mul(hit.worldTransform, rotate)
//            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
//        }
//
//    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
	func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
	}

    // MARK: - Focus Square

	func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
	}
    
	// MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

}
