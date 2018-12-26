import SceneKit
import Foundation

public func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

public func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
}

public func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
}

public func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

public enum ObjectState {
    case idle
    case placing
    case selected
    case hidden
}

protocol HasDependency {
    func update()
}

protocol HasConnectedObjects {
    var connectedObjects: Set<Object3D> { get set }
    func removeAllConnected()
    func addConnectedObject(_ object: Triangle)
}

public class Object3D: SCNNode {
    var stateInternal = ObjectState.idle
    public var state: ObjectState { return stateInternal }
    
    var workStation: WorkStation
    
    var positionBeforePlacing: SCNVector3?
    
    public init(in workStation: WorkStation) {
        self.workStation = workStation
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func removeSelf() { removeFromParentNode() }
    
    public func startPlacing(isNewObject: Bool) {
        placingAlong(isNewObject: isNewObject)
    }
    
    func placingAlong(isNewObject: Bool) {
        updateState(to: .placing)
        if !isNewObject || positionBeforePlacing != nil {
            positionBeforePlacing = position
        }
    }
    
    public func endPlacing() {
        positionBeforePlacing = position
        if let view = workStation.solidsView {
            if self === view.selected {
                updateState(to: .selected)
            } else {
                updateState(to: .idle)
            }
        }
    }
    
    public func updateState(to newState: ObjectState) {
        stateInternal = newState
        update()
    }
    
    func idlize() {
        isHidden = false
        
        let material = SCNMaterial()
        material.diffuse.contents = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        material.blendMode = .alpha
        geometry?.materials = []
        for _ in 1...6 {
            geometry?.materials.append(material)
        }
    }
    
    public func move(to point: SCNVector3) {}
    public func update() {}
}

public class SolidsModel: SCNNode {
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class WorkStation: SCNNode {
    private let model = SolidsModel()
    public let guides = SCNNode()
    
    private var placingInternal: Object3D?
    public var placing: Object3D? { return placingInternal }
    
    var solidsView: SolidsView?
    
    public override init() {
        super.init()
        addChildNode(model)
        addChildNode(guides)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func render() {
        /*
        var vertices = [SCNVector3]()
        var indices = [Int32]()
        var count: Int32 = 0
        var modelMaterials = [SCNMaterial]()
        
        for child in guides.childNodes {
            if let triangle = child as? Triangle {
                // Geometry
                let vertexA = triangle.pointA.position
                let vertexB = triangle.pointB.position
                let vertexC = triangle.pointC.position
                vertices.append(contentsOf: [vertexA, vertexB, vertexC, vertexC, vertexB, vertexA])
                for _ in 0...5 {
                    indices.append(count)
                    count += 1
                }
                
                // Material
                let material = SCNMaterial()
                material.diffuse.contents = triangle.color
                material.blendMode = .alpha
                modelMaterials.append(material)
            }
        }
 
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        model.geometry = SCNGeometry(sources: [source], elements: [element])
        model.geometry?.materials = modelMaterials
        */
        for child in model.childNodes {
            child.removeFromParentNode()
        }
        for child in guides.childNodes {
            if let triangle = child as? Triangle {
                // Geometry
                let vertexA = triangle.pointA.position
                let vertexB = triangle.pointB.position
                let vertexC = triangle.pointC.position
                let source = SCNGeometrySource(vertices: [vertexA, vertexB, vertexC, vertexC, vertexB, vertexA])
                let indices: [Int32] = [0, 1, 2, 3, 4, 5]
                let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
                
                // Material
                let material = SCNMaterial()
                material.diffuse.contents = triangle.color
                material.blendMode = .alpha
                
                // Node
                let modelTriangle = SCNNode(geometry: SCNGeometry(sources: [source], elements: [element]))
                modelTriangle.geometry?.materials = [material, material]
                model.addChildNode(modelTriangle)
            }
        }
    }
    
    public func showGuides() {
        guides.isHidden = false
    }
    
    public func hideGuides() {
        guides.isHidden = true
        render()
    }
    
    public func addGuide(_ guide: Object3D) {
        guides.addChildNode(guide)
    }
    
    public func setPlacingObject(_ object: Object3D) {
        cancelAllPlacing()
        placingInternal = object
        object.startPlacing(isNewObject: false)
    }
    
    public func newPlacingPoint(at point: SCNVector3) {
        cancelAllPlacing()
        let newPoint = Point(at: point, in: self)
        placingInternal = newPoint
        addGuide(newPoint)
        newPoint.startPlacing(isNewObject: true)
    }
    
    public func newPlacingLine(from pointA: Point, to point: SCNVector3) {
        cancelAllPlacing()
        let newPoint = Point(at: point, in: self)
        placingInternal = newPoint
        addGuide(newPoint)
        
        let line = Line(from: pointA, to: newPoint, in: self)
        addGuide(line)
        
        newPoint.startPlacing(isNewObject: true)
    }
    
    public func newPlacingTriangle(from line: Line, to point: SCNVector3) {
        cancelAllPlacing()
        let newPoint = Point(at: point, in: self)
        placingInternal = newPoint
        addGuide(newPoint)
        
        let triangle = Triangle(from: line, to: newPoint, in: self)
        addGuide(triangle)
        newPoint.startPlacing(isNewObject: true)
    }
    
    public func endAllPlacing() {
        solidsView?.isInEditMode = false
        for childNode in guides.childNodes {
            if let object = childNode as? Object3D {
                object.endPlacing()
            }
        }
        solidsView?.selected = placingInternal
        placingInternal = nil
    }
    
    public func cancelAllPlacing() {
        solidsView?.isInEditMode = false
        for childNode in guides.childNodes {
            if let object = childNode as? Object3D {
                if let pBP = object.positionBeforePlacing {
                    object.position = pBP
                    object.endPlacing()
                } else {
                    if object === placingInternal {
                        placingInternal = nil
                    }
                    object.removeSelf()
                }
            }
        }
 
        //solidsView?.selected = placingInternal
        placingInternal = nil
    }
}
