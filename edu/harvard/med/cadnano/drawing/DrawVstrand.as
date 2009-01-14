//
//  DrawVstrand
//
//  Created by Shawn on 2008-04-08.
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
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.Graphics;
    import flash.display.LineScaleMode;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.utils.getTimer;
    
    // debugging
    import flash.system.System;
    
    // cadnano
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.handles.*;
    
    /*
    Drawing routines for virtual strands rendered on the path panel.
    */
    public class DrawVstrand extends Sprite {
        public static const COLORSCAF:int = 0x0066cc; // blue
        public static const COLORSTAP:int = 0xcc0000; // red
        private var lineThickness:Number = DrawPath.lineThickness;
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        public var drawPath:DrawPath;
        public var vstrand:Vstrand;
        public var sliceNode:SliceNode;
        public var rank:int;
        public var doStapRedraw:Boolean;
        
        private var scafLineLayer:Sprite; // for horizontal lines
        private var stapLineLayer:Sprite; // for horizontal lines
        
        private var scafxoLayer:Sprite; // for crossovers
        private var stapxoLayer:Sprite; // for crossovers
        
        public var scafbreaks:Array; // breakpoint handles
        public var stapbreaks:Array; // breakpoint handles
        
        private var scafxoList:Array;
        private var stapxoList:Array;
        
        private var loopLayer:Sprite;
        private var skipLayer:Sprite;
        
        private var point:Point = new Point();
        private var localpoint:Point = new Point();
        
        private var scafLineLayerGraphics, stapLineLayerGraphics:Graphics;
        
        private var time:Number;
        
        function DrawVstrand(drawPath:DrawPath, vstrand:Vstrand, node:SliceNode, rank:int, doInitDraw=true) {
            this.drawPath = drawPath;
            this.vstrand = vstrand;
            this.vstrand.drawVstrand = this;
            this.sliceNode = node;
            this.rank = rank;
            this.doStapRedraw = false;
            this.y = rank*baseWidth*5;
            
            this.scafbreaks = new Array();
            this.stapbreaks = new Array();
            this.scafxoList = new Array();
            this.stapxoList = new Array();
            this.scafLineLayer = new Sprite();
            this.addChild(this.scafLineLayer);
            this.stapLineLayer = new Sprite();
            this.addChild(this.stapLineLayer);
            this.scafxoLayer = new Sprite();
            this.addChild(this.scafxoLayer);
            this.stapxoLayer = new Sprite();
            this.addChild(this.stapxoLayer);
            this.loopLayer = new Sprite();
            this.addChild(this.loopLayer);
            this.skipLayer = new Sprite();
            this.addChild(this.skipLayer);
            
            scafLineLayerGraphics = this.scafLineLayer.graphics;
            stapLineLayerGraphics = this.stapLineLayer.graphics;
            
            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            
            if (doInitDraw) {
                this.drawClickArea();
                this.drawScafLines();
            }
        }
        
        /* Display stack trace for debugging.  */
        public static function TRACE(s:Object):void {
            try {
                throw new Error();
            } catch (e:Error) {
                trace(e.getStackTrace() + ": " + s);
            }
        }
        
        /* Called by Vstrand.clear, which is called by Path.resetPathData()
        when loading a new design into memory. */
        public function clear():void {
            this.drawPath = null;
            this.vstrand = null;
            this.sliceNode = null;
            this.scafbreaks = null;
            this.stapbreaks = null;
            this.scafxoList = null;
            this.stapxoList = null;
            this.removeChild(this.scafLineLayer);
            this.removeChild(this.stapLineLayer);
            this.removeChild(this.scafxoLayer);
            this.removeChild(this.stapxoLayer);
            this.removeChild(this.loopLayer);
            this.removeChild(this.skipLayer);
            this.scafLineLayer = null;
            this.stapLineLayer = null;
            this.scafxoLayer = null;
            this.stapxoLayer = null;
            this.loopLayer = null;
            this.skipLayer = null;
        }
        
        /* Called by DrawPath.addScafCrossover.  Add crossover (and breakpoint if necessary).
           If editTokenArray is false, then changes will not be made to the token data by xo.init().
         */
        public function addScafCrossover(xo:CrossoverHandle,editTokenArray:Boolean=true):void {
            this.scafxoList.push(xo);
            this.scafxoLayer.addChild(xo);
            xo.init(editTokenArray);
            if (editTokenArray) {
                this.updateScaf();
            }
        }
        
        /* Called by PathTools.forceXOClickHandler.  Add crossover (and breakpoint if necessary).
           Used when adding two crossovers to the same strand. 
           If editTokenArray is false, then changes will not be made to the token data by xo.init().
        */
        public function addScafCrossoverPair(xo1:CrossoverHandle,xo2:CrossoverHandle,editTokenArray:Boolean=true):void {
            if (xo1.vstrand.number % 2 == 0) {
                xo1.type = CrossoverHandle.LEFT_UP;
            } else {
                xo1.type = CrossoverHandle.RIGHT_DOWN;
            }
            if (xo2.vstrand.number % 2 == 0) {
                xo2.type = CrossoverHandle.RIGHT_UP;
            } else {
                xo2.type = CrossoverHandle.LEFT_DOWN;
            }
            
            this.scafxoList.push(xo1);
            this.scafxoList.push(xo2);
            this.scafxoLayer.addChild(xo1);
            this.scafxoLayer.addChild(xo2);
            xo1.init(editTokenArray);
            xo2.init(editTokenArray);
            if (editTokenArray) {
                this.updateScaf();
            }
        }
        
        /* Called by DrawPath when a breakpoint handle is dragged to a new position. */
        public function redrawCrossoverLines():void {
            var xo:CrossoverHandle;
            for each(xo in this.scafxoList) {
                xo.drawCrossoverLines();
            }
            for each(xo in this.stapxoList) {
                xo.drawCrossoverLines();
            }
        }
        
        /* Inform CrossoverHandles to update numbers. */
        public function reNumberCrossovers(transform:Object):void {
            var xo:CrossoverHandle;
            for each(xo in this.scafxoList) {
                xo.reNumber(transform);
            }
            for each(xo in this.stapxoList) {
                xo.reNumber(transform);
            }
        }
        
        /* Removes CrossoverHandle from appropriate xoList and xoLayer. */
        public function removeCrossover(xo:CrossoverHandle):void {
            var index:int;
            if (xo.strandType == CrossoverHandle.SCAFFOLD) {
                index = this.scafxoList.indexOf(xo);
                this.scafxoList.splice(index,1);
                this.scafxoLayer.removeChild(xo);
            } else {
                index = this.stapxoList.indexOf(xo);
                this.stapxoList.splice(index,1);
                this.stapxoLayer.removeChild(xo);
            }
        }
        
        /* FIX: neighboering inward-facing non-adjacent breakpoints 
        overwrite each other. */
        public function pushAllScafBreaks():void {
            var bp:BreakpointHandle;
            for each(bp in this.scafbreaks) {
                bp.moveToBound(false);
            }
        }
        
        /*
        Shift all crossovers 21 bases after extendVstrand(prepend).
        The tokenArray is already correct, just need to line up with
        old position.
        */
        public function shiftHandles(segments:int=1):void {
            var dist:int = segments*21;
            var i:int;
            var xo:CrossoverHandle;
            var loopHandle:LoopHandle;
            var skipHandle:SkipHandle;
            
            // scaffold crossovers
            for each(xo in this.scafxoList) {
                xo.pos += dist;
                xo.x = xo.pos*baseWidth;
                xo.refreshTokenArrayPointer();
            }
            // staple crossovers
            for each(xo in this.stapxoList) {
                xo.pos += dist;
                xo.x = xo.pos*baseWidth;
                xo.refreshTokenArrayPointer();
            }
            // scaffold loops
            for (i = 0; i < this.loopLayer.numChildren; i++) {
                loopHandle = this.loopLayer.getChildAt(i) as LoopHandle;
                loopHandle.pos += dist;
                loopHandle.x = loopHandle.pos*baseWidth;
            }
            // scaffold skips
            for (i = 0; i < this.skipLayer.numChildren; i++) {
                skipHandle = this.skipLayer.getChildAt(i) as SkipHandle;
                skipHandle.pos += dist;
                skipHandle.x = skipHandle.pos*baseWidth;
            }
        }
        
        private function mouseDownHandler(event:MouseEvent):void {
            if (!event.shiftKey) {
                var pos:int;
                pos = Math.round((event.localX-halfbaseWidth)/baseWidth);
                this.drawPath.makeActive(this.vstrand, pos);
            }
        }
        
        /*
        Clear graphics, redraw click area, scaffold lines, and recreate all
        BreakpointHandles based on scaffold arrangement.
        */
        public function update():void {
            this.graphics.clear();
            this.drawClickArea();
            this.clearScafBreakpoints();
            this.addScafBreakpoints();
            this.drawScafLines();
            this.updateScafBreakBounds();
            this.clearStapBreakpoints();
            this.addStapBreakpoints();
            this.updateStapBreakBounds();
            this.drawStapLines();
        }
        
        public function updateScaf():void {
            var allowRefresh:Boolean = this.drawPath.allowRefresh;
            if (allowRefresh) {
                this.clearScafBreakpoints();
                this.addScafBreakpoints();
                this.updateScafBreakBounds();
                this.drawScafLines();
            }
        }
        
        public function updateStap():void {
            var allowRefresh:Boolean = this.drawPath.allowRefresh;
            if (allowRefresh) {
                this.clearStapBreakpoints();
                this.addStapBreakpoints();
                this.updateStapBreakBounds();
                this.drawStapLines();
            }
        }
        
        /*
        Loop through array of scaffold BreakpointHandles and remove them
        (hopefully for eventual garbage collection).
        */
        public function clearScafBreakpoints():void {
            var bp:BreakpointHandle;
            while (bp = scafbreaks.pop()) {
                bp.clearListeners();
                this.removeChild(bp);
            }
        }
        
        /*
        Update dragging boundaries of all BreakpointHandles based on
        neighboring handles (BreakpointHandles and CrossoverHandles).
        */
        public function updateScafBreakBounds():void {
            var handles:Array = this.scafbreaks.concat(this.scafxoList);
            var count:int = handles.length;
            
            if (count == 0) {
                return;
            }
            
            // sort handles by position
            handles.sortOn("pos", Array.NUMERIC);
            
            if (count == 1) {
                handles[0].setBounds(0,this.vstrand.scaf.length-1);
            } else if (count == 2) {
                handles[0].setBounds(0, handles[1].pos-1);
                handles[1].setBounds(handles[0].pos+1, 
                                             this.vstrand.scaf.length-1);
            } else {
                // set first
                handles[0].setBounds(0, handles[1].pos-1);
                // set middle
                var i:int;
                for (i = 1; i < count-1; i++) {
                    handles[i].setBounds(handles[int(i-1)].pos+1, handles[int(i+1)].pos-1);
                }
                // set last
                handles[count-1].setBounds(handles[count-2].pos+1, this.vstrand.scaf.length-1);
            }
        }
        
        /*
        Create new BreakpointHandles based on token pointers and add them
        as children of this DrawVstrand.
        */
        public function addScafBreakpoints():void {
            var vs:Vstrand = this.vstrand;
            var helixNum:int = vs.number;
            var i,len:int;
            var bp:BreakpointHandle;
            
            // loop through scaffold to collect breakpoints
            len = vs.scaf.length;
            for (i = 0; i < len; i++) {
                if (vs.scaf[i].prev_strand != -1 && vs.scaf[i].next_strand == -1) {
                    // right end
                    if (helixNum % 2 == 0) {  // 3' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.SCAFFOLD, 0, i, BreakpointHandle.RIGHT_3PRIME);
                        this.scafbreaks.push(bp);
                        this.addChild(bp);
                    } else { // 5' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.SCAFFOLD, baseWidth, i, BreakpointHandle.LEFT_3PRIME);
                        this.scafbreaks.push(bp);
                        this.addChild(bp);
                    }
                } else if (vs.scaf[i].prev_strand == -1 && vs.scaf[i].next_strand != -1) {
                    // left end
                    if (helixNum % 2 == 0) {  // 5' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.SCAFFOLD, 0, i, BreakpointHandle.LEFT_5PRIME);
                        this.scafbreaks.push(bp);
                        this.addChild(bp);
                    } else { // 3' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.SCAFFOLD, baseWidth, i, BreakpointHandle.RIGHT_5PRIME);
                        this.scafbreaks.push(bp);
                        this.addChild(bp);
                    }
                }
            }
        }
        
        /* Draw a sprite underneath vstrand so mouse clicks are always caught. */
        public function drawClickArea():void {
            var vswidth:int = this.vstrand.scaf.length;
            this.graphics.beginFill(0xffffff,0);
            this.graphics.drawRect(0,0,vswidth*baseWidth,baseWidth*2);
            this.graphics.endFill();
        }
        
        /* Draw horizontal lines where non-breakpoint, non-crossover scaffold
           is present.
        */
        public function drawScafLines():void {
            scafLineLayerGraphics.clear();
            
            var vs:Vstrand = this.vstrand;
            var helixNum:int = vs.number;
            var endpoint:Array = new Array();
            var i,len,yoffset:int;
            var p1, p2:Point;
            var delta:Number;
            
            time = getTimer();
            
            // loop through scaffold
            len = vs.scaf.length;
            for (i = 0; i < len; i++) {
                if (vs.scaf[i].prev_strand == helixNum && vs.scaf[i].next_strand != helixNum) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                } else if (vs.scaf[i].prev_strand != helixNum && vs.scaf[i].next_strand == helixNum) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                } else if (helixNum % 2 == 0 && vs.scaf[i].prev_strand == helixNum && vs.scaf[i].prev_pos != i-1) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                } else if (helixNum % 2 == 0 && vs.scaf[i].next_strand == helixNum && vs.scaf[i].next_pos != i+1) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                } else if (helixNum % 2 == 1 && vs.scaf[i].prev_strand == helixNum && vs.scaf[i].prev_pos != i+1) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                } else if (helixNum % 2 == 1 && vs.scaf[i].next_strand == helixNum && vs.scaf[i].next_pos != i-1) {
                        endpoint.push(new Point(baseWidth*i+halfbaseWidth, halfbaseWidth));
                }
            }
            
            // draw horizontal lines for each xover position
            yoffset = (helixNum % 2) * baseWidth;
            this.scafLineLayerGraphics.beginFill(0xffffff,0);
            this.scafLineLayerGraphics.lineStyle(lineThickness, 0x0066cc, 1, false, LineScaleMode.NORMAL, 
                                              CapsStyle.NONE, JointStyle.MITER, 1);
            while (endpoint.length > 0) {
                p1 = endpoint.shift();
                p2 = endpoint.shift();
                
                delta = p1.x-p2.x;
                if (delta < 0) {delta = -delta;}
                if (delta >= baseWidth) {
                    this.scafLineLayerGraphics.moveTo(p1.x, p1.y + yoffset);
                    this.scafLineLayerGraphics.lineTo(p2.x, p2.y + yoffset);
                }
            }
            
            this.scafLineLayerGraphics.endFill();
            
            if (this.vstrand.scaf[this.drawPath.currentSlice].prev_strand != -1 ||
                this.vstrand.scaf[this.drawPath.currentSlice].next_strand != -1) {
                    this.sliceNode.marked = true;
            } else {
                this.sliceNode.marked = false;
            }
            
            this.sliceNode.drawNode.refreshNode();
            // render3d
            this.drawPath.render3D.redrawBases();
        }
        
        /* Add crossover (and breakpoint if necessary).
           If editTokenArray is false, then changes will not be made to the token data by xo.init().
         */
        public function addStapCrossover(xo:CrossoverHandle,editTokenArray:Boolean=true):void {
            this.stapxoList.push(xo);
            this.stapxoLayer.addChild(xo);
            xo.init(editTokenArray);
            if (editTokenArray) { // originated from mouse click
                this.updateStap();
            }
        }
        
        /* Add crossover (and breakpoint if necessary).
           If editTokenArray is false, then changes will not be made to the token data by xo.init().
         */
        public function addStapCrossoverPair(xo1:CrossoverHandle,xo2:CrossoverHandle,editTokenArray:Boolean=true):void {
            this.stapxoList.push(xo1);
            this.stapxoList.push(xo2);
            this.stapxoLayer.addChild(xo1);
            this.stapxoLayer.addChild(xo2);
            xo1.init(editTokenArray);
            xo2.init(editTokenArray);
            if (editTokenArray) {
                this.updateStap();
            }
        }
        
        /*
        Loop through array of staple BreakpointHandles and remove them.
        (hopefully for eventual garbage collection).
        */
        public function clearStapBreakpoints():void {
            var bp:BreakpointHandle;
            while (bp = stapbreaks.pop()) {
                bp.clearListeners();
                this.removeChild(bp);
            }
        }
        
        /*
        Pop every CrossoverHandle from scafxoList and remove from panel.
        */
        public function clearStapCrossovers():void {
            var xo:CrossoverHandle;
            while (xo = stapxoList.pop()) {
                xo.clearListeners();
                this.stapxoLayer.removeChild(xo);
            }
        }
        
        /*
        Update dragging boundaries of all BreakpointHandles based on
        neighboring handles (BreakpointHandles and CrossoverHandles).
        */
        public function updateStapBreakBounds():void {
            var handles:Array = this.stapbreaks.concat(this.stapxoList);
            var count:int = handles.length;
            
            if (count == 0) {
                return;
            }
            
            // sort handles by position
            handles.sortOn("pos", Array.NUMERIC);
            
            if (count == 1) {
                handles[0].setBounds(0,this.vstrand.stap.length-1);
            } else if (count == 2) {
                handles[0].setBounds(0, handles[1].pos-1);
                handles[1].setBounds(handles[0].pos+1, 
                                             this.vstrand.stap.length-1);
            } else {
                // set first
                handles[0].setBounds(0, handles[1].pos-1);
                // set middle
                var i:int;
                for (i = 1; i < count-1; i++) {
                    handles[i].setBounds(handles[int(i-1)].pos+1, handles[int(i+1)].pos-1);
                }
                // set last
                handles[count-1].setBounds(handles[count-2].pos+1, this.vstrand.stap.length-1);
            }
        }
        
        /*
        Create new BreakpointHandles based on token pointers and add them
        as children of this DrawVstrand.
        */
        public function addStapBreakpoints():void {
            var vs:Vstrand = this.vstrand;
            var helixNum:int = vs.number;
            var i,len:int;
            var bp:BreakpointHandle;
            
            // loop through staples to collect breakpoints
            len = vs.stap.length;
            for (i = 0; i < len; i++) {
                if (vs.stap[i].prev_strand != -1 && vs.stap[i].next_strand == -1) {
                    // right end
                    if (helixNum % 2 == 1) {  // 3' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.STAPLE, 0, i, BreakpointHandle.RIGHT_3PRIME);
                        this.stapbreaks.push(bp);
                        this.addChild(bp);
                    } else { // 5' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.STAPLE, baseWidth, i, BreakpointHandle.LEFT_3PRIME);
                        this.stapbreaks.push(bp);
                        this.addChild(bp);
                    }
                } else if (vs.stap[i].prev_strand == -1 && vs.stap[i].next_strand != -1) {
                    // left end
                    if (helixNum % 2 == 1) {  // 5' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.STAPLE, 0, i, BreakpointHandle.LEFT_5PRIME);
                        this.stapbreaks.push(bp);
                        this.addChild(bp);
                    } else { // 3' end
                        bp = new BreakpointHandle(vs, BreakpointHandle.STAPLE, baseWidth, i, BreakpointHandle.RIGHT_5PRIME);
                        this.stapbreaks.push(bp);
                        this.addChild(bp);
                    }
                }
            }
        }
        
        /* Return reference to BreakpointHandle at pos if exists, otherwise null. */
        public function getStapleBreakpointHandleAt(pos:int):BreakpointHandle {
            var bp:BreakpointHandle;
            for each(bp in this.stapbreaks) {
                if (bp.pos == pos) {
                    return bp;
                } 
            }
            return null;
        }
        
        /* Return reference to BreakpointHandle at pos if exists, otherwise null. */
        public function getStapleCrossoverHandleAt(pos:int):CrossoverHandle {
            var xo:CrossoverHandle;
            for each(xo in this.stapxoList) {
                if (xo.pos == pos) {
                    return xo;
                } 
            }
            return null;
        }
        
        /* Draw horizontal lines where non-breakpoint, non-crossover staple
           is present.
        */
        public function drawStapLines():void {
            var vs:Vstrand = this.vstrand;
            var helixNum:int = vs.number;
            var endpoint:Array = new Array();
            var colors:Array = new Array();
            var styles:Array = new Array();
            var i,len,yoffset:int;
            var p1,p2:Point;
            var color:String;
            var highlight:Boolean;
            
            var handles:Array = this.stapbreaks.concat(this.stapxoList);
            var count:int = handles.length;
            
            this.stapLineLayerGraphics.clear();
            
            if (count == 0) {return;}
            
            if (count % 2 != 0) {
                var msg:String = "odd number of handles in strand" + this.vstrand.number + " " + count;
                trace(msg);
                return;
            }
            
            // sort handles by position
            handles.sortOn("pos", Array.NUMERIC);
            for each(var handle in handles) {
                endpoint.push(new Point(baseWidth*handle.pos+halfbaseWidth, halfbaseWidth));
                colors.push(vs.stap[handle.pos].color);
                styles.push(vs.stap[handle.pos].highlight);
            }
            
            // draw horizontal lines for each xover position
            yoffset = ((helixNum + 1) % 2) * baseWidth;
            while (endpoint.length > 0) {
                p1 = endpoint.shift();
                p2 = endpoint.shift();
                color = colors.shift();
                colors.shift();
                highlight = styles.shift();
                styles.shift();
                
                if (highlight) {
                    this.stapLineLayerGraphics.lineStyle(baseWidth, uint(color), 0.5, false, LineScaleMode.NORMAL,
                                                         CapsStyle.NONE, JointStyle.MITER, 1);
                } else {
                    this.stapLineLayerGraphics.lineStyle(lineThickness, uint(color), 1, false, LineScaleMode.NORMAL,
                                                         CapsStyle.NONE, JointStyle.MITER, 1);
                }
                //trace("p1", (p1.x-halfbaseWidth)/baseWidth, "p2", (p2.x-halfbaseWidth)/baseWidth);
                if (Math.abs(p1.x-p2.x) >= baseWidth) {
                    this.stapLineLayerGraphics.moveTo(p1.x, p1.y + yoffset);
                    this.stapLineLayerGraphics.lineTo(p2.x, p2.y + yoffset);
                    
                }
            }
        } // end of drawStapLines()
        
        public function removeSkipHandle(pos:int):void {
            var i:int;
            var skipHandle:SkipHandle;
            for (i = 0; i < this.skipLayer.numChildren; i++) {
                skipHandle = this.skipLayer.getChildAt(i) as SkipHandle;
                if (skipHandle.pos == pos) {
                    this.skipLayer.removeChild(skipHandle);
                    return;
                }
            }
        }
        
        public function removeLoopHandle(pos:int):void {
            var i:int;
            var loopHandle:LoopHandle;
            for (i = 0; i < this.loopLayer.numChildren; i++) {
                loopHandle = this.loopLayer.getChildAt(i) as LoopHandle;
                if (loopHandle.pos == pos) {
                    this.loopLayer.removeChild(loopHandle);
                    return;
                }
            }
        }
        
        /* Called by PathTools.createLoopHandler() or DrawPath.loadHandles() to add a scaffold loop. */
        public function addLoopHandle(pos:int, loopSize:int):void {
            var i:int;
            var loopHandle:LoopHandle
            for (i = 0; i < this.loopLayer.numChildren; i++) {
                loopHandle = this.loopLayer.getChildAt(i) as LoopHandle;
                if (loopHandle.pos == pos) {
                    this.loopLayer.removeChild(loopHandle);
                }
            }
            loopHandle = new LoopHandle(this.vstrand, pos, loopSize);
            this.loopLayer.addChild(loopHandle);
            if (this.vstrand.hasStap(pos)) {
                this.drawPath.notifyLengthChange(loopSize, this.vstrand, pos, this.vstrand.stap[pos].color);
                this.drawPath.updateStap(true);
            }
        } // end of addLoopHandle()
        
        /* Called by PathTools.createSkipHandler() or DrawPath.loadHandles() to add a scaffold skip. */
        public function addSkipHandle(pos:int):void {
            var i:int;
            var skipHandle:SkipHandle;
            for (i = 0; i < this.skipLayer.numChildren; i++) {
                skipHandle = this.skipLayer.getChildAt(i) as SkipHandle;
                if (skipHandle.pos == pos) {
                    this.skipLayer.removeChild(skipHandle);
                }
            }
            skipHandle = new SkipHandle(this.vstrand, pos);
            this.skipLayer.addChild(skipHandle);
            if (this.vstrand.hasStap(pos)) {
                this.drawPath.notifyLengthChange(-1, this.vstrand, pos, this.vstrand.stap[pos].color);
                this.drawPath.updateStap(true);
            }
        } // end of addSkipHandle()
        
        public function getScafCrossoverAtPos(i:int):CrossoverHandle {
            var xo:CrossoverHandle;
            for each(xo in this.scafxoList) {
                if (xo.pos == i) {
                    return xo;
                }
            }
            return null; // nothing found
        }
        
        public function getStapCrossoverAtPos(i:int):CrossoverHandle {
            var xo:CrossoverHandle;
            for each(xo in this.stapxoList) {
                if (xo.pos == i) {
                    return xo;
                }
            }
            return null; // nothing found
        } // end of getStapCrossoverAtPos()
        
    } // end of public class DrawVstrand
} // end of package