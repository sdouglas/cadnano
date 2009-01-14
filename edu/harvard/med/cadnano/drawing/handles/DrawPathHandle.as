//
//  DrawPathHandle
//
//  Created by Shawn on 2008-01-07.
//

/*
The MIT License

Copyright (c) 2008 Shawn M. Douglas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

http://www.opensource.org/licenses/mit-license.php
*/

package edu.harvard.med.cadnano.drawing.handles {
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    // misc
    import com.yahoo.astra.utils.DynamicRegistration;
    
    // cadnano
    import edu.harvard.med.cadnano.drawing.DrawNode;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.data.SliceNode;
    
    /*
    DrawPathHandle is a minimal extension of the Sprite class,
    allowing for simple textfield labeling and status tracking.
    Some default text formatting options are also maintained.
    */
    public class DrawPathHandle extends Sprite {
        public static var COLOR_FILL:uint = 0xeeeeee;
        public static var COLOR_ROLLFILL:uint = 0x99ccff;
        public static var COLOR_MARK:uint = 0xcc6600;
        public static var COLOR_MARKFILL:uint = 0xffcc99;
        public static var RADIUS:int = 10;
        
        public var num:int;
        public var label:TextField;
        private var format:TextFormat;
        private var drawPath:DrawPath;
        private var drawNode:DrawNode;
        private var sliceNode:SliceNode;
        
        function DrawPathHandle(drawPath:DrawPath, node:SliceNode) {
            this.drawPath = drawPath;
            this.drawNode = node.drawNode;
            this.drawNode.drawPathHandle = this;
            this.sliceNode = node;
            this.num = this.sliceNode.number;
            
            // Center label on circle
            this.graphics.beginFill(0xffcc99,1);
            this.graphics.lineStyle(0.5, COLOR_MARK);
            this.graphics.drawCircle(0, 0, RADIUS);
            this.graphics.endFill();
            
            this.label = new TextField();
            this.label.text = this.num.toString();
            this.label.autoSize = "left";
            this.format = new TextFormat();
            this.format.font = "Verdana";
            this.format.size = 10;
            this.label.setTextFormat(format);
            this.label.mouseEnabled = false;
            this.addChild(label);
            
            // center text
            var rect:Rectangle = this.label.getRect(this);
            var cp:Point = new Point((rect.right-rect.left)*0.5, (rect.bottom-rect.top)*0.5);
            DynamicRegistration.move(this.label, cp, 0, 0);
            
            addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            addEventListener(MouseEvent.CLICK, function() {});
        }
        
        private function mouseDownHandler(e:MouseEvent):void {
            startDrag();
            parent.setChildIndex(this, parent.numChildren - 1);
            addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        private function mouseUpHandler(e:MouseEvent):void {
            stopDrag();
            removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            this.drawPath.handleUpdate(e.target.num, e.target.y);
            e.updateAfterEvent();
        }
        
        public function updateNumber():void {
            this.num = this.sliceNode.number;
            this.label.text = this.num.toString();
            var rect:Rectangle = this.label.getRect(this);
            var cp:Point = new Point((rect.right-rect.left)*0.5, (rect.bottom-rect.top)*0.5);
            DynamicRegistration.move(this.label, cp, 0, 0);
        }
        
        /*
        Change appearance when corresponding slice node is hovered.
        */
        public function hover():void {
            var fill:uint;
            if (this.drawNode.sliceNode.marked) {
                fill = COLOR_FILL;
            } else {
                fill = COLOR_ROLLFILL;
            }
            this.graphics.clear();
            this.graphics.beginFill(fill,1);
            this.graphics.lineStyle(0.5, COLOR_MARK);
            this.graphics.drawCircle(0, 0, RADIUS);
            this.graphics.endFill();
        }
        
        /*
        Restore appearance when corresponding slice node is unhovered.
        */
        public function unhover():void {
            this.graphics.clear();
            this.graphics.beginFill(0xffcc99,1);
            this.graphics.lineStyle(0.5, COLOR_MARK);
            this.graphics.drawCircle(0, 0, RADIUS);
            this.graphics.endFill();
        }
    }
}