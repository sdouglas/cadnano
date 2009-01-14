//
//  Panel
//
//  Created by Shawn on 2007-11-27.
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

package edu.harvard.med.cadnano.panel {
    // flash
    import flash.display.Graphics;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.events.Event;
    import flash.display.Shape;
    
    // misc
    import com.yahoo.astra.utils.DynamicRegistration;
    import com.yahoo.astra.utils.NumberUtil;
    import gs.TweenLite;
    
    /*
    The Panel class extends MovieClip and is used for the main display objects
    in cadnano.  Its purpose is to tidy up Main.as and have a place to put
    display-related functions that are re-used for each of the panels,
    such as minimization. 
    */
    public class Panel extends MovieClip {
        public var h:int;
        public var w:int;
        public static const pad:int = 10;
        
        // sizing parameters
        public var fullC, halfL, halfR:Rectangle;
        public var thirdL, thirdC, thirdR:Rectangle;
        public var fullCcp, halfLcp, halfRcp:Point;
        public var thirdLcp, thirdCcp, thirdRcp:Point;
        
        // Drawing related
        public var canvas:Sprite; // main content shown here
        public var canvasmask:Shape; // mask for canvas
        public var border:Sprite; // border for canvas
        public var mouseLayer:Sprite; // invisible layer for mousing
        
        // Bookkeeping
        private var rank:int; // order in which the path positioned
        private var count:int; // total number of panels
        private var bcolor:uint; // border color
        public var left:int; // number of panels to the left
        public var right:int; // number of panels to the right
        public var center:Point; // mask center point (for zooming)
        public var leftX:int; // left boundary (for aligning Tools)
        public var canvascp:Point; // canvas center point
        public var minimized:Boolean = false;
        
        public function Panel(h:int, w:int, rank:int, count:int, canvas:Sprite, bcolor:uint) {
            this.setSize(h, w);
            // store input parameters
            this.rank = rank;
            this.count = count;
            this.bcolor = bcolor;
            this.canvas = canvas;
            this.addChild(canvas);
            this.left = rank - 1;
            this.right = count - rank;
            this.center = new Point();
            // set initial canvas center point
            this.canvascp = new Point(); // default to (0,0)
            // set up mask
            this.canvasmask = new Shape();
            this.canvas.mask = this.canvasmask;
            this.addChild(this.canvasmask);
            // set up border
            this.border = new Sprite();
            this.addChild(this.border);
            // set up mouseLayer
            this.mouseLayer = new Sprite();
            this.mouseLayer.alpha = 0;
            this.mouseLayer.visible = false;
            this.addChild(this.mouseLayer);
        }
        
        /* Configures Panel size according to screen dimensions. */
        private function setSize(h:int, w:int):void {
            h = NumberUtil.roundToNearest(h - 230);
            w = NumberUtil.roundToNearest(w - 30);
            this.h = h;
            this.w = w;
            this.fullC = new Rectangle(0,0,w,h);
            this.halfL = new Rectangle(0,0,(w-pad*2)*0.5,h);
            this.halfR = new Rectangle(w*0.5,0,(w-pad*2)*0.5,h);
            this.thirdL = new Rectangle(0*(w-pad*3)/3 + 0*pad,0,(w-pad*3)*1/3,h);
            this.thirdC = new Rectangle(1*(w-pad*3)/3 + 1*pad,0,(w-pad*3)*1/3,h);
            this.thirdR = new Rectangle(2*(w-pad*3)/3 + 2*pad,0,(w-pad*3)*1/3,h);
            this.fullCcp = new Point(fullC.width*0.5,fullC.height*0.5);
            this.halfLcp = new Point(halfL.width*0.5,halfL.height*0.5);
            this.halfRcp = new Point(halfR.width*0.5,halfR.height*0.5);
            this.thirdLcp = new Point(thirdL.width*0.5,thirdL.height*0.5);
            this.thirdCcp = new Point(thirdC.width*0.5,thirdC.height*0.5);
            this.thirdRcp = new Point(thirdR.width*0.5,thirdR.height*0.5);
        }
        
        /*
        centerCanvas will move the canvas to the current center of the mask
        using canvascp as the registration point.
        
        canvascp can be updated before centering by passing x,y
        coordinates to centerCanvas (e.g. when a mouse is clicked 
        to zoom).
        */
        public function centerCanvas(x:int=-1, y:int=-1):void {
            if (x == -1 && y == -1) { // mouse hasn't been clicked
                if (!this.canvascp.x && !this.canvascp.y) { // canvascp not set
                    var rect = this.canvas.getRect(this); // set to real center
                    this.canvascp.x = (rect.right-rect.left)*0.5;
                    this.canvascp.y = (rect.bottom-rect.top)*0.5;
                }
            } else {
                canvascp.x = x; // set to mouse click coordinates
                canvascp.y = y;
            }
            
            DynamicRegistration.move(this.canvas, canvascp, this.center.x, this.center.y);
        }
        
        /* Create the appearance of resizing the Panels by redrawing the mask
           and border. Updates new center point which will be needed by
           centerCanvas().
        */
        public function resize(r:Rectangle) {
            this.canvasmask.graphics.clear();
            this.canvasmask.graphics.beginFill(0xffffff);
            this.canvasmask.graphics.drawRoundRect(r.x, r.y, r.width, r.height, 10);
            this.canvasmask.graphics.endFill();
            this.border.graphics.clear();
            this.border.graphics.lineStyle(1, bcolor, 1, true);
            this.border.graphics.drawRoundRect(r.x, r.y, r.width, r.height, 10);
            this.border.graphics.endFill();
            this.mouseLayer.graphics.clear();
            this.mouseLayer.graphics.beginFill(0xffffff);
            this.mouseLayer.graphics.drawRoundRect(r.x, r.y, r.width, r.height, 10);
            this.mouseLayer.graphics.endFill();
            this.center.x = r.x + (r.width*0.5);
            this.center.y = r.y + (r.height*0.5);
            this.leftX = r.x;
        }
        
        /* After a panel has been resized, use update to move to its new
           arrangement.
         */
        public function update():void {
            if (this.minimized) {
                // reposition and rescale using TweenLite
                
                TweenLite.to(this, 0.2, {x:this.w-182+32*rank + 5*(rank-1), y:this.h+80, scaleX:0.1, scaleY:0.1});
                this.resize(new Rectangle(0,0,320,520));
            } else {
                TweenLite.to(this, 0.2, {x:0, y:0, scaleX:1, scaleY:1});
                // resize according to how many neighbors are maximized
                if (this.left == 0 && this.right == 0) {
                    this.resize(fullC);
                } else if (this.left == 0 && this.right == 1) {
                    this.resize(halfL);
                } else if (this.left == 1 && this.right == 0) {
                    this.resize(halfR);
                } else if (this.left == 0 && this.right == 2) {
                    this.resize(thirdL);
                } else if (this.left == 1 && this.right == 1) {
                    this.resize(thirdC);
                } else if (this.left == 2 && this.right == 0) {
                    this.resize(thirdR);
                } else {
                    trace("problem: unrecognized neighbor combination");
                }
                this.centerCanvas();
            }
        }
    }
}