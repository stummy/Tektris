//
//  GameViewController.swift
//  Tektris
//
//  Created by Ara Atzuri on 1/11/17.
//  Copyright © 2017 hyalithus. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var scene: GameScene!
    var tektris:Tektris!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        
        // Create and configure the scene.
        scene = GameScene(size:skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        scene.tick = didTick
        
        tektris = Tektris()
        tektris.beginGame()
        
        
        // Present the scene.
        skView.presentScene(scene)
        
        scene.addPreviewShapeToScene(shape: tektris.nextShape!) {
            self.tektris.nextShape?.moveTo(column: StartingColumn, row: StartingRow)
            self.scene.movePreviewShape(shape: self.tektris.nextShape!) {
                let nextShapes = self.tektris.newShape()
                self.scene.startTicking()
                self.scene.addPreviewShapeToScene(shape: nextShapes.nextShape!){}
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    func didTick() {
        tektris.fallingShape?.lowerShapeByOneRow()
        scene.redrawShape(shape: tektris.fallingShape!, completion: {})
    }
    
}
