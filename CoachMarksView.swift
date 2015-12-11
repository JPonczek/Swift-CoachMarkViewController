//
//  CoachMarks.swift
//
//  Created by Justin Ponczek on 10/1/15.
//  Copyright © 2015 Justin Ponczek. All rights reserved.
//
//  Based on WSCoachMarksView in OBJ-C
//  WSCoachMarksView.h
//  Version 0.2
//
//  Created by Dimitry Bentsionov on 4/1/13.
//  Copyright (c) 2013 Workshirt, Inc. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import QuartzCore

@objc protocol CoachMarksViewDelegate {
    optional func willNavigateToIndex(coachMarksView : CoachMarksView, index: Int)
    optional func didNavigateToIndex(coachMarksView : CoachMarksView, index: Int)
    optional func coachMarksViewWillCleanup(coachMarksView : CoachMarksView)
    optional func coachMarksViewDidCleanup(coachMarksView : CoachMarksView)
}

class CoachMarksView: UIView {
    let mask = CAShapeLayer()
    var markIndex = 0
    var lblContinue : UILabel!
    var btnSkipCoach : UIButton!
    var kAnimationDuration : Double = 0.3
    var kCutoutRadius : CGFloat = 2.0
    var kMaxLblWidth : CGFloat = 230.0
    var kLblSpacing : CGFloat = 35.0
    var kEnableContinueLabel = false
    var kEnableSkipButton = false
    var coachMarks = [AnyObject]()
    var lblCaption : UILabel!
    var maskColor : UIColor!
    var animationDuration : Double!
    var cutoutRadius : CGFloat!
    var maxLblWidth : CGFloat!
    var lblSpacing : CGFloat!
    var enableContinueLabel = false
    var enableSkipButton = false
    var delegate: CoachMarksViewDelegate?
    
    init(frame: CGRect, marks : [AnyObject]){
        super.init(frame: frame)
        self.coachMarks = marks
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setup(){
        self.animationDuration = kAnimationDuration
        self.cutoutRadius = kCutoutRadius
        self.maxLblWidth = kMaxLblWidth
        self.lblSpacing = kLblSpacing
        self.enableContinueLabel = kEnableContinueLabel
        self.enableSkipButton = kEnableSkipButton
        mask.fillRule = kCAFillRuleEvenOdd
        mask.fillColor = UIColor.blackColor().CGColor
        self.layer.addSublayer(mask)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "userDidTap:")
        self.addGestureRecognizer(tapGestureRecognizer)
        self.lblCaption = UILabel(frame: CGRectMake(0, 0, self.maxLblWidth, 0.0))
        self.lblCaption.backgroundColor = UIColor.clearColor()
        self.lblCaption.textColor = UIColor.whiteColor()
        self.lblCaption.font = UIFont.systemFontOfSize(15)
        self.lblCaption.lineBreakMode = .ByWordWrapping
        self.lblCaption.numberOfLines = 0
        self.lblCaption.textAlignment = .Center
        self.lblCaption.alpha = 0.0
        self.addSubview(self.lblCaption)
        self.hidden = true
    }
    
    func setCutoutToRect(rect : CGRect, shape : String){
        let maskPath = UIBezierPath(rect: self.bounds)
        var cutoutPath : UIBezierPath!
        if shape == "circle"{ cutoutPath = UIBezierPath(ovalInRect: rect) }
        else if shape == "square"{ cutoutPath = UIBezierPath(rect: rect) }
        else { cutoutPath = UIBezierPath(roundedRect: rect, cornerRadius: self.cutoutRadius) }
        maskPath.appendPath(cutoutPath)
        mask.path = maskPath.CGPath
    }
    
    func animateCutoutToRect(rect : CGRect, shape : String){
        let maskPath = UIBezierPath(rect: self.bounds)
        var cutoutPath : UIBezierPath!
        if shape == "circle"{ cutoutPath = UIBezierPath(ovalInRect: rect) }
        else if shape == "square"{ cutoutPath = UIBezierPath(rect: rect) }
        else { cutoutPath = UIBezierPath(roundedRect: rect, cornerRadius: self.cutoutRadius) }
        maskPath.appendPath(cutoutPath)
        let anim = CABasicAnimation(keyPath: "path")
        anim.delegate = self
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        anim.duration = self.animationDuration!
        anim.removedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        anim.fromValue = mask.path!
        anim.toValue = maskPath.CGPath
        mask.addAnimation(anim, forKey: "path")
        mask.path = maskPath.CGPath
    }
    
    func userDidTap(recognizer : UITapGestureRecognizer){
        self.goToCoachMarkIndexed(markIndex+1)
    }
    
    func start(){
        self.alpha = 0.0
        self.hidden = false
        UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in self.alpha = 1.0 })
            { (success : Bool) -> Void in self.goToCoachMarkIndexed(0) }
    }
    
    func skipCoach(){
        self.goToCoachMarkIndexed(self.coachMarks.count)
    }
    
    func goToCoachMarkIndexed(index : Int){
        if index >= self.coachMarks.count {
            self.cleanup()
            return
        }
        markIndex = index
        let markDef : [String : AnyObject] = self.coachMarks[index] as! [String : AnyObject]
        let markCaption = markDef["caption"] as! String
        let markRect = (markDef["rect"] as! NSValue).CGRectValue()
        var shape = "other"
        if markDef.keys.contains("shape"){ shape = markDef["shape"] as! String }
        if self.delegate != nil { self.delegate!.willNavigateToIndex!(self, index: markIndex) }
        self.lblCaption.alpha = 0.0
        self.lblCaption.frame = CGRectMake(0, 0, self.maxLblWidth, 0)
        self.lblCaption.text = markCaption
        self.lblCaption.sizeToFit()
        var y : CGFloat = markRect.origin.y + markRect.size.height + self.lblSpacing
        let bottomY = y + self.lblCaption.frame.size.height + self.lblSpacing
        if bottomY > self.bounds.size.height {
            y = markRect.origin.y - self.lblSpacing - self.lblCaption.frame.size.height
        }
        let x = floor((self.bounds.size.width - self.lblCaption.frame.size.width) / 2.0)
        self.lblCaption.frame = CGRectMake(x, y, self.lblCaption.frame.width, self.lblCaption.frame.height)
        UIView.animateWithDuration(0.3) { () -> Void in self.lblCaption.alpha = 1.0 }
        if markIndex == 0 {
            let center = CGPointMake(floor(markRect.origin.x + (markRect.size.width / 2.0)), floor(markRect.origin.y + (markRect.size.height / 2.0)))
            let centerZero = CGRectMake(center.x, center.y, 0, 0)
            self.setCutoutToRect(centerZero, shape : shape)
        }
        self.animateCutoutToRect(markRect, shape : shape)
        let lblContinueWidth = self.enableSkipButton ? (70/100) * self.bounds.width : self.bounds.width
        let btnSkipWidth = self.bounds.size.width - lblContinueWidth
        
        if self.enableContinueLabel {
            if markIndex == 0 {
                lblContinue = UILabel(frame: CGRectMake(0, self.bounds.height - 30, lblContinueWidth, 30))
                lblContinue.font = UIFont.systemFontOfSize(15)
                lblContinue.textAlignment = .Center
                lblContinue.text = "Tap to continue"
                lblContinue.alpha = 0
                lblContinue.backgroundColor = UIColor.whiteColor()
                self.addSubview(lblContinue)
                UIView.animateWithDuration(0.3, delay: 1.0, options: .CurveLinear, animations: { () -> Void in
                    self.lblContinue.alpha = 1.0
                    }, completion: nil)
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.lblContinue.alpha = 1
                })
            }
            else if markIndex > 0 && lblContinue != nil {
                lblContinue.removeFromSuperview()
                lblContinue = nil
            }
        }
        
        if self.enableSkipButton {
            btnSkipCoach = UIButton(frame: CGRectMake(lblContinueWidth, self.bounds.height - 30, btnSkipWidth, 30))
            btnSkipCoach.addTarget(self, action: "skipCoach", forControlEvents: .TouchUpInside)
            btnSkipCoach.setTitle("Skip", forState: .Normal)
            btnSkipCoach.titleLabel?.font = UIFont.systemFontOfSize(15)
            btnSkipCoach.alpha = 0
            btnSkipCoach.tintColor = UIColor.whiteColor()
            self.addSubview(btnSkipCoach)
            UIView.animateWithDuration(0.3, delay: 1.0, options: .CurveLinear, animations: { () -> Void in
                self.btnSkipCoach.alpha = 1
                }, completion: nil)
        }
    }
    
    func cleanup(){
        if self.delegate != nil { self.delegate?.coachMarksViewWillCleanup!(self) }
        UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                self.alpha = 0
            }) { (success : Bool) -> Void in
                self.removeFromSuperview()
                if self.delegate != nil { self.delegate?.coachMarksViewDidCleanup!(self) }
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if self.delegate != nil { self.delegate?.didNavigateToIndex!(self, index: self.markIndex) }
    }
}
