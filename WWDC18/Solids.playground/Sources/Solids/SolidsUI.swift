import ARKit
import UIKit
import Foundation
import PlaygroundSupport

func createButton(image: UIImage, y: CGFloat, scale: CGFloat, action: Selector) -> UIButton {
    guard let view = PlaygroundPage.current.liveView as? SolidsView else { fatalError("SolidsView not found at call by createButton()") }
    let button = UIButton(frame: CGRect(x: 0, y: y * 44, width: 44 * scale, height: 44 * scale))
    button.setImage(image, for: .normal)
    button.addTarget(Target.instance, action: action, for: .primaryActionTriggered)
    view.addSubview(button)
    return button
}

class Target {
    static let instance = Target()
    private init() {}

    let page = PlaygroundPage.current
    var solidsUI: SolidsUI!
    
    @objc
    @IBAction func aBack() {
        Controller.show2DScene(.menu, in: page)
    }

    @objc
    @IBAction func aReturn() {
        guard let view = page.liveView as? SolidsView else { fatalError("SolidsView not found at call by aReturn()") }
        view.returnToReferencePoint() 
    }

    @objc
    @IBAction func aGuide() {
        guard let view = page.liveView as? SolidsView else { fatalError("SolidsView not found at call by aGuide()") }
        view.guidesEnabled = !view.guidesEnabled
        if view.guidesEnabled {
            solidsUI.guideButton.setImage(#imageLiteral(resourceName: "guideButtonOn.png"), for: .normal)
            view.workStation.showGuides()
        } else {
            solidsUI.guideButton.setImage(#imageLiteral(resourceName: "guideButtonOff.png"), for: .normal)
            view.workStation.hideGuides()
        }
    }

    @objc
    @IBAction func aAdd() {
        guard let view = page.liveView as? SolidsView else { fatalError("SolidsView not found at call by aAdd()") }
        // view.addPointAtReferencePoint()
        view.workStation.endAllPlacing()
    }

    @objc
    @IBAction func aRemove() {
        guard let view = page.liveView as? SolidsView else { fatalError("SolidsView not found at call by aAdd()") }
        view.selected?.removeSelf()
        view.selected = nil
    }

    @objc
    @IBAction func aLine() {
        solidsUI.lineAction()
    }

    @objc
    @IBAction func aTriangle() {
        solidsUI.triangleAction()
    }

    @objc
    @IBAction func aProperties() {
        solidsUI.propertiesAction()
    }

    @objc
    @IBAction func aMove() {
        solidsUI.moveAction()
    }
    
    @objc
    @IBAction func willCancelAction() {
        guard let selected = solidsUI.solidsView.selected else { fatalError("Selected object not found at call by aCancelAction()") }
        solidsUI.solidsView.isInEditMode = false
        solidsUI.solidsView.workStation.cancelAllPlacing()
        solidsUI.didSelect(selected)
    }
}

public class SolidsUI {
    let       backButton = createButton(image: #imageLiteral(resourceName: "backButton.png"), y: 0, scale: 1, action: #selector(Target.aBack))
    let     returnButton = createButton(image: #imageLiteral(resourceName: "returnButton.png"), y: 1, scale: 1, action: #selector(Target.aReturn))
    let      guideButton = createButton(image: #imageLiteral(resourceName: "guideButtonOn.png"), y: 2, scale: 1, action: #selector(Target.aGuide))
    
    let        addButton = createButton(image: #imageLiteral(resourceName: "addButton.png"), y: 3, scale: 2, action: #selector(Target.aAdd))
    let     removeButton = createButton(image: #imageLiteral(resourceName: "removeButton.png"), y: 3, scale: 1, action: #selector(Target.aRemove))
    let       lineButton = createButton(image: #imageLiteral(resourceName: "lineButton.png"), y: 4, scale: 1, action: #selector(Target.aLine))
    let   triangleButton = createButton(image: #imageLiteral(resourceName: "triangleButton.png"), y: 4, scale: 1, action: #selector(Target.aTriangle))
    let propertiesButton = createButton(image: #imageLiteral(resourceName: "propertiesButton.png"), y: 4, scale: 1, action: #selector(Target.aProperties))
    let       moveButton = createButton(image: #imageLiteral(resourceName: "moveButton.png"), y: 5, scale: 1, action: #selector(Target.aMove))
    
    let     cancelActionButton = createButton(image: #imageLiteral(resourceName: "cancelButton.png"), y: 3, scale: 2, action: #selector(Target.willCancelAction))
    let       lineActionButton = createButton(image: #imageLiteral(resourceName: "lineButton.png"), y: 5, scale: 2, action: #selector(Target.aAdd))
    let   triangleActionButton = createButton(image: #imageLiteral(resourceName: "triangleButton.png"), y: 5, scale: 2, action: #selector(Target.aAdd))
    let propertiesActionButton = createButton(image: #imageLiteral(resourceName: "propertiesButton.png"), y: 5, scale: 2, action: #selector(Target.aAdd))
    let       moveActionButton = createButton(image: #imageLiteral(resourceName: "moveButton.png"), y: 5, scale: 2, action: #selector(Target.aAdd))

    let    mutableButtons: [UIButton]
    let     idleButtonSet: [UIButton]
    let    pointButtonSet: [UIButton]
    let     lineButtonSet: [UIButton]
    let triangleButtonSet: [UIButton]
    
    let       lineActionButtonSet: [UIButton]
    let   triangleActionButtonSet: [UIButton]
    let propertiesActionButtonSet: [UIButton]
    let       moveActionButtonSet: [UIButton]
    
    var solidsView: SolidsView

    init(with view: SolidsView) {
        solidsView = view
        
        mutableButtons = [
            addButton, removeButton,
            lineButton, triangleButton, propertiesButton,
            moveButton,
            cancelActionButton,
            lineActionButton, triangleActionButton, propertiesActionButton,
            moveActionButton
        ]
        
        /**/     idleButtonSet = [addButton]
        
        /**/    pointButtonSet = [removeButton, lineButton, moveButton]
        /**/     lineButtonSet = [removeButton, triangleButton, moveButton]
        /**/ triangleButtonSet = [removeButton, propertiesButton, moveButton]
        
        /**/       lineActionButtonSet = [cancelActionButton,       lineActionButton]
        /**/   triangleActionButtonSet = [cancelActionButton,   triangleActionButton]
        /**/ propertiesActionButtonSet = [cancelActionButton, propertiesActionButton]
        /**/       moveActionButtonSet = [cancelActionButton,       moveActionButton]
        
        Target.instance.solidsUI = self
        didDeselect()
    }

    func didSelect(_ selection: Object3D) {
        solidsView.workStation.cancelAllPlacing()
        if selection is Point {
            showButtonSet(pointButtonSet, from: mutableButtons)
        } else if selection is Line {
            showButtonSet(lineButtonSet, from: mutableButtons)
        } else if selection is Triangle {
            showButtonSet(triangleButtonSet, from: mutableButtons)
        }
    }
    
    func didDeselect() {
        showButtonSet(idleButtonSet, from: mutableButtons)
        solidsView.workStation.newPlacingPoint(at: solidsView.viewReferenceNode.convertPosition(SCNVector3Zero, to: solidsView.workStation))
    }
    
    func passEditingTouchObject(_ object: Object3D) {
        guard let placing = solidsView.workStation.placing else { fatalError("Placing not found at passEditingTouchObject(_:)") }
        
        if let point = object as? Point {
            if let placingPoint = placing as? Point {
                placingPoint.replaceBy(point)
                solidsView.workStation.endAllPlacing()
                solidsView.selected = object
            }
        } else if let line = object as? Line {
            if let placingLine = placing as? Line {
                placingLine.replaceBy(line)
                solidsView.workStation.endAllPlacing()
                solidsView.selected = object
            }
        } else if let triangle = object as? Triangle {
            if let placingTriangle = placing as? Triangle {
                placingTriangle.replaceBy(triangle)
                solidsView.workStation.endAllPlacing()
                solidsView.selected = object
            }
        }
    }
    
    func lineAction() {
        if let selected = solidsView.selected as? Point {
            showButtonSet(lineActionButtonSet, from: mutableButtons)
            solidsView.workStation.newPlacingLine(from: selected, to: solidsView.getReferencePoint())
            solidsView.isInEditMode = true
        }
    }
    
    func triangleAction() {
        if let selected = solidsView.selected as? Line {
            showButtonSet(triangleActionButtonSet, from: mutableButtons)
            solidsView.workStation.newPlacingTriangle(from: selected, to: solidsView.getReferencePoint())
            solidsView.isInEditMode = true
        }
    }
    
    func propertiesAction() {
        showButtonSet(propertiesActionButtonSet, from: mutableButtons)
        solidsView.isInEditMode = true
        solidsView.selected?.updateState(to: .placing)
    }
    
    func moveAction() {
        if let selected = solidsView.selected {
            showButtonSet(moveActionButtonSet, from: mutableButtons)
            solidsView.workStation.setPlacingObject(selected)
            solidsView.isInEditMode = true
        }
    }
}

