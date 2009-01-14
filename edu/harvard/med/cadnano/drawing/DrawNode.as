//
//  DrawNode
//
//  Created by Shawn on 2007-11-05.
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
package edu.harvard.med.cadnano.drawing {
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    // misc
    import com.yahoo.astra.utils.DynamicRegistration;
    
    // cadnano
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.drawing.handles.DrawPathHandle;
    
    /*
    DrawNode contains code related to drawing the individual circles
    representing helices in the slice panel.
    */
    public class DrawNode extends Sprite {
        // Color values
        public static var COLOR_FILL:uint = 0xeeeeee;//0xffffff;
        public static var COLOR_BLANK:uint = 0x999999;
        public static var COLOR_ROLLOVER:uint = 0x0066cc;
        public static var COLOR_ROLLFILL:uint = 0x99ccff;
        public static var COLOR_MARK:uint = 0xcc6600; //0xf40095;
        public static var COLOR_MARKFILL:uint = 0xffcc99; //0xf40095;
        
        // SliceNode-cloned variables
        public var sliceNode:SliceNode;     // the sliceNode
        
        // DrawNode-specific variables
        public var radius:int;
        public var row:int;
        public var col:int;
        public var tf:TextField;
        public var tfm:TextFormat;
        public var linewidth:int;
        public var drawPathHandle:DrawPathHandle = null;
        private var rect:Rectangle;
        private var point:Point = new Point();
        private var txtHeight:int = -1;
        
        public function DrawNode(row:int, col:int, radius:int=20)
        {
            // Minimal setup; everything else is added on first refreshNode()
            this.row = row;
            this.col = col;
            this.radius = radius;
            this.linewidth = 1;
            this.tf = new TextField();
            this.tfm = tf.getTextFormat();
            this.tf.antiAliasType = "advanced";
            this.tf.autoSize = "left";
            this.tf.selectable = false;
            this.tf.mouseEnabled = false;
            this.addChild(tf);
        }
        
        public function updateRadius(r:int):void {
            this.radius = r;
            if (this.sliceNode.number == -1) {
                return;
            }
            this.tfm.size = this.radius;
            this.tf.setTextFormat(this.tfm);
            this.tf.x = this.tf.y = 0;
            this.rect = this.tf.getRect(this);
            this.txtHeight = (this.rect.bottom-this.rect.top)*0.5; // save original textHeight on first pass
            //DynamicRegistration.move(this.tf, point, 1, 1);
        }
        
        public function refreshNode():void
        {
            /**
             * Node coordinate determination
             * Note: in Flash, the stage y direction is reversed from Cartesian y.
             **/
            this.x = this.col*this.radius*1.732051;
            if ((row % 2) ^ (col % 2)) {  // odd parity
                this.y = this.row*this.radius*3 + this.radius;
            } else {                      // even parity
                this.y = this.row*this.radius*3;
            }
            
            /**
             * Node drawing
             **/
            var color:uint;
            var fill:uint;
            graphics.clear();
            if (this.sliceNode.marked) {
                color = COLOR_MARK;
                fill = COLOR_MARKFILL;
                // always draw colored nodes on top
                this.parent.setChildIndex(this, this.parent.numChildren-1);
            } else {
                color = COLOR_BLANK;
                fill = COLOR_FILL;
            }
            graphics.beginFill(fill, 1);
            graphics.lineStyle(this.linewidth, color);
            graphics.drawCircle(0, 0, radius);
            graphics.endFill();
            
            /**
             * Text format and coordinate determination
             **/
            if (this.sliceNode.number != -1) {
                this.tf.text = this.sliceNode.number.toString();
            } else {
                this.tf.text = "";
                return;
            }
            
            this.tfm.size = this.radius;
            this.tf.setTextFormat(this.tfm);
            this.tf.x = this.tf.y = 0;
            this.rect = this.tf.getRect(this);
            
            // HACK: to deal with TextField autoSize mysteriously changing tf.textHeight from 24 to 34 and back to 24
            if (this.txtHeight == -1) {
                this.txtHeight = (this.rect.bottom-this.rect.top)*0.5; // save original textHeight on first pass
            }
            point.x = (this.rect.right-this.rect.left)*0.5;
            point.y = this.txtHeight;
            DynamicRegistration.move(this.tf, point, 1, 1);
        }
        
        public function reCenterNumber():void {
            if (this.sliceNode.number != -1) {
                this.tf.text = this.sliceNode.number.toString();
            } else {
                return;
            }
            this.tfm.size = this.radius;
            this.tf.setTextFormat(this.tfm);
            this.rect = this.tf.getRect(this);
            point.x = (this.rect.right-this.rect.left)*0.5;
            point.y = this.txtHeight;
            DynamicRegistration.move(this.tf, point, 1, 1);
        }
        
        public function reNumber():void {
            this.tf.text = this.sliceNode.number.toString();
            this.tf.setTextFormat(this.tfm);
            this.rect = this.tf.getRect(this);
            point.x = (this.rect.right-this.rect.left)*0.5;
            point.y = this.txtHeight;
            DynamicRegistration.move(this.tf, point, 1, 1);
        }
        
        public function hover():void {
            var color:uint;
            var fill:uint;
            graphics.clear();
            if (this.sliceNode.marked) {
                color = COLOR_MARK;
                fill = COLOR_FILL;
            } else {
                color = COLOR_ROLLOVER;
                fill = COLOR_ROLLFILL;
            }
            graphics.beginFill(fill, 1);
            graphics.lineStyle(this.linewidth, color);
            graphics.drawCircle(0, 0, this.radius);
            graphics.endFill();
            
            // always draw colored nodes on top
            this.parent.setChildIndex(this, this.parent.numChildren-1);
            
            if (this.drawPathHandle != null) {
                this.drawPathHandle.hover();
            }
        }
        
        private function getDist(x1:int,x2:int,y1:int,y2:int):int {
            return Math.sqrt(Math.pow(x1-x2,2)+Math.pow(y1-y2,2));
        }
        
        public function unhover():void
        {
            var color:uint;
            var fill:uint;
            graphics.clear();
            if (this.sliceNode.marked) {
                color = COLOR_MARK;
                fill = COLOR_MARKFILL;
                // always draw colored nodes on top
                this.parent.setChildIndex(this, this.parent.numChildren-1);
            } else {
                color = COLOR_BLANK;
                fill = COLOR_FILL;
                this.parent.setChildIndex(this, 0); // unhover to bottom
            }
            graphics.beginFill(fill, 1);
            graphics.lineStyle(this.linewidth, color);
            graphics.drawCircle(0, 0, radius);
            graphics.endFill();
            
            if (this.drawPathHandle != null) {
                this.drawPathHandle.unhover();
            }
        }
    }
}