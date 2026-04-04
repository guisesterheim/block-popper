import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private var scenePresented = false

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !self.scenePresented,
              let skView = self.view as? SKView,
              skView.bounds.size.width > 0 else { return }

        self.scenePresented = true
        presentGameScene(in: skView)
    }

    private func presentGameScene(in skView: SKView) {
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = ColorPalette.background

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
