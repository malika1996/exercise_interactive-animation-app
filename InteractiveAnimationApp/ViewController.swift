//
//  ViewController.swift
//  InteractiveAnimationApp
//
//  Created by vinmac on 24/09/19.
//  Copyright © 2019 vinmac. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum DrawerState {
        case open
        case closed
    }

    @IBOutlet weak private var headerView: UIView!
    @IBOutlet weak private var lblOpenStateTitle: UILabel!
    @IBOutlet weak private var drawerView: UIView!
    @IBOutlet weak private var lblClosedStateTitle: UILabel!
    
    private var isDrawerOpen = true
    private let defaultHeightOfDrawerView = 600
    private let defaultHeightOfHeaderView = 60
    private var runningAnimationArray = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted:CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.headerView.addGestureRecognizer(tapGesture)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.drawerView.addGestureRecognizer(panGesture)
        self.drawerView.clipsToBounds = true
        self.drawerView.layer.cornerRadius = 30.0
        self.lblClosedStateTitle.alpha = 0
        self.lblClosedStateTitle.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 15))
    }
    
    @objc private func handleTap(tapGesture: UITapGestureRecognizer) {
        let nextState = self.isDrawerOpen ? DrawerState.closed : DrawerState.open
        animateTransitions(for: nextState)
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.startAnimations(for: self.isDrawerOpen ? DrawerState.closed : DrawerState.open)
        case .changed:
            let yTranslation = recognizer.translation(in: self.drawerView).y
            var fraction = yTranslation / self.drawerView.frame.height
            fraction = self.isDrawerOpen ? fraction : -fraction
            updateAnimations(fractionCompleted: fraction)
        case .ended:
            let yVelocity = recognizer.velocity(in: self.drawerView).y
            self.continueInteractiveTransitionAccordingToInterruption(yVelocity: yVelocity)
        default:
            break
        }
    }

    private func startAnimations(for state: DrawerState) {
        animateTransitions(for: state)
        for animator in self.runningAnimationArray {
            animator.pauseAnimation()
            self.animationProgressWhenInterrupted = animator.fractionComplete
        }
    }

    private func animateTransitions(for nextState: DrawerState) {
        if self.runningAnimationArray.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: 1.5, dampingRatio: 1, animations: {
                if nextState == .open {
                    self.drawerView.frame.origin.y = self.view.frame.height - CGFloat(self.defaultHeightOfDrawerView)
                } else {
                    self.drawerView.frame.origin.y = self.view.frame.height - CGFloat(self.defaultHeightOfHeaderView)
                }
            })
            frameAnimator.addCompletion({finalPosition in
                switch finalPosition {
                case .start:
                    self.isDrawerOpen = !self.isDrawerOpen
                default:
                    break
                }
                self.runningAnimationArray.removeAll()
                self.isDrawerOpen = !self.isDrawerOpen
            })
            
            var cornerRadiusAnimator: UIViewPropertyAnimator? = UIViewPropertyAnimator(duration: 1.5, curve: .linear) {
                switch nextState {
                case .open:
                    self.drawerView.layer.cornerRadius = 30
                case .closed:
                    self.drawerView.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator?.addCompletion({_ in
                cornerRadiusAnimator = nil
            })
            
            var textColorFontAnimator: UIViewPropertyAnimator? = UIViewPropertyAnimator(duration: 1.5, curve: .linear, animations: {
                self.lblOpenStateTitle.textColor = .white
                self.lblClosedStateTitle.textColor = .white
                switch nextState {
                case .open:
                    self.lblClosedStateTitle.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 15))
                    self.lblOpenStateTitle.transform = .identity
                    self.lblOpenStateTitle.alpha = 1
                    self.lblOpenStateTitle.textColor = .black
                    self.lblClosedStateTitle.alpha = 0
                    
                case .closed:
                    self.lblOpenStateTitle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).concatenating(CGAffineTransform(translationX: 0, y: -15))
                    self.lblClosedStateTitle.transform = .identity
                    self.lblOpenStateTitle.alpha = 0
                    self.lblClosedStateTitle.textColor = .blue
                    self.lblClosedStateTitle.alpha = 1
                }
            })
            textColorFontAnimator?.addCompletion({_ in
                self.lblOpenStateTitle.textColor = .black
                self.lblClosedStateTitle.textColor = .blue
                textColorFontAnimator = nil
            })
            
            //Start animations
            frameAnimator.startAnimation()
            textColorFontAnimator?.startAnimation()
            cornerRadiusAnimator?.startAnimation()
            
            //Add the animations to runningAnimations array
            runningAnimationArray.append(frameAnimator)
            runningAnimationArray.append(cornerRadiusAnimator!)
            runningAnimationArray.append(textColorFontAnimator!)
        }
    }

    private func updateAnimations(fractionCompleted: CGFloat) {
        var fraction = fractionCompleted
        for animator in self.runningAnimationArray {
            if animator.isReversed {
                fraction = -fraction
            }
            animator.fractionComplete = fraction + self.animationProgressWhenInterrupted
        }
    }

    private func continueInteractiveTransitionAccordingToInterruption(yVelocity: CGFloat) {
        //Knowing the direction of the touches
        let shouldClose = yVelocity > 0
        for animator in runningAnimationArray {
            if self.isDrawerOpen { //Open
                if (!shouldClose && !animator.isReversed)  {
                    animator.isReversed = !animator.isReversed
                }
                if (shouldClose && animator.isReversed) {
                    animator.isReversed = !animator.isReversed
                }
            } else { //Closed
                if (shouldClose && !animator.isReversed)  {
                    animator.isReversed = !animator.isReversed
                }
                if (!shouldClose && animator.isReversed) {
                    animator.isReversed = !animator.isReversed
                }
            }
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
