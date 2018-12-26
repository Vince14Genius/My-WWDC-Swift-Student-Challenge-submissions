import ARKit
import PlaygroundSupport
import Foundation

public class SolidsView: ARSCNView, ARSCNViewDelegate {

    private var guidesEnabledInternal = true
    public var guidesEnabled: Bool {
        get { return guidesEnabledInternal }
        set {
            guidesEnabledInternal = newValue
            // Now enable or disable the guides
        }
    }

    public var selected: Object3D? {
        didSet {
            oldValue?.updateState(to: .idle)
            if let new = selected {
                new.updateState(to: .selected)
                solidsUI?.didSelect(new)
            } else {
                solidsUI?.didDeselect()
            }
        }
    }
    
    public var isInEditMode = false

    var didInitialize = false
    var touchesDidMove = [UITouch: Bool]()
    
    let viewReferencePoint = SCNVector3(0, 0, -1)
    let viewReferenceNode = SCNNode()
    let vrnVisual = SCNNode()
    
    let workStation = WorkStation()
    public var solidsUI: SolidsUI?
    
    func initializeScene() {
        scene = SCNScene()
        delegate = self
        
        showsStatistics = true
        
        pointOfView?.addChildNode(viewReferenceNode)
        scene.rootNode.addChildNode(vrnVisual)
        
        scene.rootNode.addChildNode(workStation)
        workStation.solidsView = self
        
        // setup for viewReferenceNode begins

        viewReferenceNode.position = viewReferencePoint
        
        func vrnAddChild(_ y: CGFloat, _ z: CGFloat, color: UIColor) {
            let vrnMaterial = SCNMaterial()
            vrnMaterial.diffuse.contents = color
            vrnMaterial.blendMode = .replace
            let blackRod = SCNMaterial()
            blackRod.diffuse.contents = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            blackRod.blendMode = .screen
            let vrnGeometry = SCNBox(width: 0.1, height: 0.01, length: 0.01, chamferRadius: 0.0025)
            
            func addMaterial(_ material: SCNMaterial, to node: SCNNode) {
                for i in 0 ... 5 {
                    node.geometry?.materials.insert(vrnMaterial, at: i)
                }
            }
            
            let vrnChildNode = SCNNode(geometry: vrnGeometry)
            addMaterial(vrnMaterial, to: vrnChildNode)
            let rotate = SCNAction.rotateBy(x: 0, y: y, z: z, duration: 0)
            vrnChildNode.runAction(rotate)
            vrnVisual.addChildNode(vrnChildNode)
            
            let vrnChildChild = SCNNode(geometry: vrnGeometry)
            addMaterial(blackRod, to: vrnChildChild)
            vrnChildChild.scale = SCNVector3(0.3, 0.3, 0.3)
            vrnChildNode.addChildNode(vrnChildChild)
        }
        vrnAddChild(0, 0, color: #colorLiteral(red: 0.2, green: 0.2, blue: 1, alpha: 1))
        vrnAddChild(0, .pi / 2, color: #colorLiteral(red: 0.2, green: 1, blue: 0.2, alpha: 1))
        vrnAddChild(.pi / 2, 0, color: #colorLiteral(red: 1, green: 0.2, blue: 0.2, alpha: 1))

        // initializing stage
        addPoint(at: viewReferenceNode.convertPosition(SCNVector3Zero, to: workStation))
        scene.rootNode.runAction(.repeat(.sequence([
            .wait(duration: 0.01),
            .run { _ in
                self.returnToReferencePoint()
            }
            ]), count: 100))
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeScene()
    }
    
    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        initializeScene()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchesDidMove[touch] = false
            
            // start test for object selection
            guard !isInEditMode else { return }
            let hitResults = hitTest(touch.location(in: self))
            var didSelect = false
            
            // select the first guide object hit
            for hitResult in hitResults {
                if let selectedObject = hitResult.node as? Object3D {
                    if selectedObject.state != .placing {
                        selected = selectedObject
                        didSelect = true
                        break
                    }
                } else if let selectedObject = hitResult.node.parent as? Object3D {
                    if selectedObject.state != .placing {
                        selected = selectedObject
                        didSelect = true
                        break
                    }
                }
            }
            if !didSelect {
                selected = nil
            }
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchesDidMove[touch] = true
            
            if isInEditMode {
                if let selectedTriangle = selected as? Triangle {
                    selectedTriangle.previousColor = selectedTriangle.color
                    let touchPoint = touch.location(in: self)
                    switch touchPoint.y {
                    case 0..<frame.height * 0.25:
                        selectedTriangle.red = touchPoint.x / frame.width
                    case frame.height * 0.25..<frame.height * 0.5:
                        selectedTriangle.green = touchPoint.x / frame.width
                    case frame.height * 0.5..<frame.height * 0.75:
                        selectedTriangle.blue = touchPoint.x / frame.width
                    default:
                        selectedTriangle.alpha = touchPoint.x / frame.width
                    }
                }
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let didMove = touchesDidMove[touch] {
                if !didMove {
                    // Check for editing
                    
                }
            }
            touchesDidMove[touch] = nil
            
            if isInEditMode {
                let hitResults = hitTest(touch.location(in: self))
                // Pass the first guide object hit
                for hitResult in hitResults {
                    if let hitObject = hitResult.node as? Object3D {
                        if hitObject.state != .selected && hitObject.state != .placing {
                            solidsUI?.passEditingTouchObject(hitObject)
                            break
                        }
                    }
                }
            }
        }
    }
    
    public func addPoint(at point: SCNVector3) {
        let pointNode = Point(at: point, in: workStation)
        pointNode.endPlacing()
        workStation.addGuide(pointNode)
    }

    public func addPointAtReferencePoint() {
        addPoint(at: getReferencePoint())
    }
    
    public func getReferencePoint() -> SCNVector3 {
        return viewReferenceNode.convertPosition(SCNVector3Zero, to: workStation)
    }

    public func returnToReferencePoint() {
        if let pov = pointOfView {
            // move workstation to the camera 
            workStation.position = pov.position
            workStation.orientation = viewReferenceNode.worldOrientation
            vrnVisual.orientation = workStation.orientation
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // update VRN
        vrnVisual.position = viewReferenceNode.worldPosition
        workStation.placing?.move(to: viewReferenceNode.convertPosition(SCNVector3Zero, to: workStation))
    }
}
