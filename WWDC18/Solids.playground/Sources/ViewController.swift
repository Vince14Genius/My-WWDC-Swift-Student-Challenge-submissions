import ARKit
import Foundation
import UIKit
import PlaygroundSupport

public enum Scene2D {
    case menu
    case slides
    case sinvaders
}

public enum SceneAR {
    case solids
}

public func showButtonSet(_ set: [UIButton], from allMutableButtons: [UIButton]) {
    for button in allMutableButtons {
        button.isEnabled = false
        button.isHidden = true
    }
    
    for button in set {
        button.isEnabled = true
        button.isHidden = false
    }
}

public class Controller {
    static public let sceneSize = CGSize(width: 1000, height: 1000)

    private init() {} // NOT a singleton. Just a container for static stuff.

    static func presentScene(_ scene: Scene2D, in view: SKView) {
        switch scene {
        case .menu     : view.presentScene(     MenuScene(fileNamed: "MenuScene"))
        case .slides   : view.presentScene(   SlidesScene(size: sceneSize))
        case .sinvaders: view.presentScene(SinvadersScene(size: sceneSize))
        }
    }

    static public func show2DScene(_ scene: Scene2D, in page: PlaygroundPage) {
        if let view = page.liveView as? SKView {
            presentScene(scene, in: view)
            return
        }
        let skView = SKView()
        page.liveView = skView
        presentScene(scene, in: skView)
    }

    static public func showARScene(_ scene: SceneAR, in page: PlaygroundPage) {
        switch scene {
        case .solids: 
            let session = ARSession()
            let view = SolidsView()

            page.liveView = view
            view.session = session
            view.translatesAutoresizingMaskIntoConstraints = false

            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            session.run(ARWorldTrackingConfiguration())

            view.solidsUI = SolidsUI(with: view)
        }
    }
}
