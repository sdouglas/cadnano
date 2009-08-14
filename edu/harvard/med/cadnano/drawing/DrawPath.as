//
//  DrawPath
//
//  Created by Shawn on 2007-10-18.
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
    import flash.display.DisplayObject;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.*;
    
    // component-related
    import fl.controls.Label;
    import fl.controls.NumericStepper;
    import fl.controls.TextInput;
    import flash.text.TextFieldType;
    import flash.text.TextFieldAutoSize;

    // misc
    import br.com.stimuli.loading.BulkLoader;
    import com.yahoo.astra.fl.managers.AlertManager;
    import de.polygonal.core.ObjectPool;
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.Path;
    import edu.harvard.med.cadnano.Render3D;
    import edu.harvard.med.cadnano.data.*;
    import edu.harvard.med.cadnano.drawing.handles.*;
    import edu.harvard.med.cadnano.panel.SliceTools;
    import edu.harvard.med.cadnano.panel.ToolButton;
    
    /*
    DrawPath handles the high-level organization and drawing of paths.
    Path data is accessed by looping through the doubly-linked lists in the 
    Path object.
    */
    public class DrawPath extends Sprite {
        public static const lineThickness:Number = 2;
        public static const stapleColorSet:Array = new Array (
            0xCC0000, 0xF74308, 0xF7931E, 0xaaaa00, 0x57BB00, 0x007200, 0x03B6A2, 0x1700DE,  0x7300DE, 0xB8056C, 0x333333);
        
        /* 
        Colors are stored in decimal format in the json output.  RGB values included for reference.

        #cc0000 = 13369344 = (204,0,0)
        #f74308 = 16204552 = (247,67,8)
        #f7931e = 16225054 = (247,147,30)
        #aaaa00 = 11184640 = (170,170,0)
        #57bb00 =  5749504 = (87,187,0)
        #007200 =    29184 = (0,114,0)
        #03b6a2 =   243362 = (3,182,162)
        #1700de =  1507550 = (23,0,222)
        #7300de =  7536862 = (115,0,222)
        #b8056c = 12060012 = (184,5,108)
        #333333 =  3355443 = (51,51,51)
        
        0x888888 =  8947848 = (136,136,136)
        */
        
        public static const hairpinColor:uint = 0x0066cc;
        public static const markColor1:uint = 0x00ffff;
        public static const markColor2:uint = 0xff00ff;
        public static const markColor3:uint = 0xffff00;
        public static const markColor4:uint = 0xff6600;
        public static const markColor7:uint = 0xff0000;
        public static const baseWidth:int = 10;
        public static const halfbaseWidth:int = 5;
        public static const handleOffset:int = -15;
        public static var STAP_MAX:uint = 49; // max highlight threshold
        public static var STAP_MIN:uint = 18; // min highlight threshold
        
        // capy static vars from other classes
        private var SCAFFOLD:String = PreCrossoverHandle.SCAFFOLD;
        private var STAPLE:String = PreCrossoverHandle.STAPLE;
        private var LEFT:String =  PreCrossoverHandle.LEFT;
        private var RIGHT:String =  PreCrossoverHandle.RIGHT;
        private var LEFT_5PRIME:String = BreakpointHandle.LEFT_5PRIME;
        private var RIGHT_5PRIME:String = BreakpointHandle.RIGHT_5PRIME;
        
        // references
        public var path:Path;
        public var drawSlice:DrawSlice;
        public var render3D:Render3D;
        
        // bookkeeping
        public var currentSlice:int = 21;
        public var preXovers:Array;  // pointers to possible crossovers
        private var colorIndex:int;
        private var tokenList:Array; // keeping track of coloring
        // use to suppress multiple re-drawing during auto-staple
        public var allowRefresh:Boolean = true;
        
        // helix labels/drag handle
        public var helixlabelList:DLinkedList;
        
        // slice selector
        public var sliceTools:SliceTools;
        public var sliceBar:Sprite;
        private var prevSlice:Sprite;
        private var nextSlice:Sprite;
        private var sliceBarLabel:TextField;
        private var format:TextFormat;
        private var sliceBarAlertSprite:Sprite;
        private var numericStepper:NumericStepper;
        private var nsLabel:Label;
        
        private var dvLayer:Sprite;
        private var gridLayer:Sprite;
        private var hairpinLayer:Sprite;
        
        // pre-crossover
        private var activeLayer:Sprite;
        private var activeVstrand:Vstrand = null;
        private var activePos:int = 0;
        
        // scaffold sequence
        public var scafBasesAdded:int = 0;
        
        private var preXOpool:ObjectPool;
        
        function DrawPath(path:Path) {
            this.name = "drawPath";
            this.path = path;
            this.path.drawPath = this;
            
            this.gridLayer = new Sprite();
            this.addChild(this.gridLayer);
            
            this.hairpinLayer = new Sprite();
            this.addChild(this.hairpinLayer);
            
            this.activeLayer = new Sprite();
            this.addChild(this.activeLayer);
            
            this.dvLayer = new Sprite();
            this.addChild(this.dvLayer);
            
            this.helixlabelList = new DLinkedList();
            
            this.tokenList = new Array();
            
            this.preXovers = new Array();
            preXOpool = new ObjectPool(true);
            preXOpool.allocate(256, PreCrossoverHandle);
        }
        
        public function initSliceBar():void {
            this.sliceBar = new Sprite();
            this.addChild(this.sliceBar);
            this.setChildIndex(this.sliceBar, 0); // move to bottom
            this.sliceBarLabel = new TextField();
            this.sliceBarLabel.autoSize = "left";
            this.sliceBarLabel.selectable = false;
            this.format = new TextFormat();
            this.format.align = "center";
            this.format.font = "Verdana";
            this.format.color = 0xcc6600;
            this.format.size = 10;
            this.sliceBarLabel.y = -7*baseWidth;
            this.sliceBar.addChild(this.sliceBarLabel);
            this.sliceBar.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownSliceBar);
            
            this.prevSlice = new Sprite();
            this.nextSlice = new Sprite();
            this.prevSlice.x = -32 - baseWidth;
            this.nextSlice.x = 2*baseWidth;
            this.prevSlice.y = this.nextSlice.y = -5*baseWidth;
            
            this.prevSlice.addEventListener(MouseEvent.CLICK, prevSliceAction);
            this.nextSlice.addEventListener(MouseEvent.CLICK, nextSliceAction);
            this.addChild(this.prevSlice);
            this.addChild(this.nextSlice);
            
            // retrieve pre-loaded Bitmaps
            var mainLoader:BulkLoader = BulkLoader.getLoader("main");
            prevSlice.addChild(mainLoader.getBitmap("icons/slice-go-previous.png"));
            nextSlice.addChild(mainLoader.getBitmap("icons/slice-go-next.png"));
            this.prevSlice.visible = false;
            this.nextSlice.visible = false;
            
            sliceBarAlertSprite = new Sprite();
            nsLabel = new Label();
            // HACK: Fix the height of the Label TextField (aka I hate components)
            var tf:TextField = nsLabel.getChildAt(0) as TextField;
            nsLabel.height = tf.height = 20;
            nsLabel.width = tf.width = 245;
            sliceBarAlertSprite.addChild(nsLabel);
            nsLabel.text = "Extend width by (21x               ) bases.";
            nsLabel.setStyle("textFormat", new TextFormat("_sans", 14));
            numericStepper = new NumericStepper();
            numericStepper.stepSize = 1;
            numericStepper.minimum = 1;
            numericStepper.maximum = 200;
            // HACK: Fix the height of the NumericStepper TextField
            var tInput:TextInput = numericStepper.getChildAt(2) as TextInput;
            tInput.textField.height = 22;
            tInput.textField.width = 54;
            numericStepper.width = 54;
            sliceBarAlertSprite.addChild(numericStepper);
            numericStepper.x = 136;
            nsLabel.y = numericStepper.y = 15;
        }
        
        /* Handle mouse click on sliceBar left arrow to extend grid. */
        private function prevSliceAction(event:MouseEvent):void {
            if (this.currentSlice == 0) {
                AlertManager.createAlert(this.parent.parent,
                                         "",
                                         "Increase grid width",
                                         ["OK", "Cancel"],
                                         prependHandler,
                                         null,
                                         true,
                                         {textColor:0x000000},
                                         TextFieldType.DYNAMIC,
                                         sliceBarAlertSprite);
            }
            this.drawSlice.update(this.sliceTools.radius);
        }
        
        /* Handle user response to prevSliceAction dialog. */
        private function prependHandler(event:Event):void {
            if (event.target.name == "OK") {
                this.path.extendVstrands(Path.PREPEND, numericStepper.value);
                this.drawSlice.update(this.sliceTools.radius);
            } else if (event.target.name == "Cancel") {
                // do nothing
            }
        }
        
        /* Handle mouse click on sliceBar right arrow to extend grid. */
        private function nextSliceAction(event:MouseEvent):void {
            if (this.currentSlice == this.path.vsList.head.data.scaf.length-1) {
                AlertManager.createAlert(this.parent.parent, 
                                         "",
                                         "Increase grid width", 
                                         ["OK", "Cancel"],
                                         appendHandler,
                                         null,
                                         true,
                                         {textColor:0x000000},
                                         TextFieldType.DYNAMIC,
                                         sliceBarAlertSprite);
            }
        }
        
        /* Handle user response to nextSliceAction dialog. */
        private function appendHandler(event:Event):void {
            if (event.target.name == "OK") {
                this.path.extendVstrands(Path.APPEND, numericStepper.value);
                this.drawSlice.update(this.sliceTools.radius);
            } else if (event.target.name == "Cancel") {
                // do nothing
            }
        }
        
        /* Resets activeVstrand to avoid problems when loading new design. */
        public function clearActiveVstrand():void {
            var oldX:PreCrossoverHandle;
            this.activeVstrand = null;
            while (oldX = this.preXovers.pop()) {
                this.activeLayer.removeChild(oldX);
                preXOpool.object = oldX; // return PreCrossoverHandle to object pool.
            }
        }
        
        /* Remove all helices (Handles, DrawVstrands) from DrawPath.*/
        public function removeAllDrawVstrands():void {
            this.currentSlice = 21; // snap back to slice that must exist.
            
            // remove helix handles
            var dph:DrawPathHandle = helixlabelList.removeHead();
            while (dph != null) {
                this.removeChild(dph);
                dph = helixlabelList.removeHead();
            }
            
            // remove DrawVstrands from dvLayer
            while (this.dvLayer.numChildren != 0) {
                this.dvLayer.removeChildAt(0);
            }
            
            // remove crossover handles
            // remove loophandles
            // remove skip handles
            
            this.update();
        }
        
        /* Delete the vstrand from path and drawPath */
        public function removeLastVstrand():void {
            var lastVs:Vstrand = this.path.vsList.tail.data;
            if (lastVs.p0 != null) {
                lastVs.p0.p0 = null;
            }
            if (lastVs.p1 != null) {
                lastVs.p1.p1 = null;
            }
            if (lastVs.p2 != null) {
                lastVs.p2.p2 = null;
            }
/*
            if (lastVs.p3 != null) { // SQUARE LATTICE
                lastVs.p3.p3 = null;
            }
*/
            
            lastVs.drawVstrand.clear();
            
            var dph:DrawPathHandle = this.helixlabelList.removeTail();
            this.removeChild(dph);
            this.dvLayer.removeChild(lastVs.drawVstrand);
            
            this.path.vsList.removeTail();
            delete this.path.vsHash[lastVs.number];
            
            // remove loop handles
            // remove skip handles
            
            this.clearActiveVstrand();
            // update DrawPath
            this.update()
        }
        
        /* Add CrossoverHandles to DrawVstrand based on Vstrand data. */
        public function loadHandles():void {
            var vs,vs2:Vstrand;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var i, result:int;
            var pos1, pos2, strand1, strand2:int;
            var xo1,xo2:CrossoverHandle;
            var type1, type2:String;
            
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                for (i = 0; i < vs.scaf.length; i++) {
                    // SCAFFOLD CROSSOVER HANDLES
                    
                    result = 0;
                    if (vs.hasScafXover(i,false)) {
                        strand1 = vs.number;
                        pos1 = i;
                        if (strand1 % 2 == 0) {
                            type1 = LEFT;
                        } else {
                            type1 = RIGHT;
                        }
                        strand2 = vs.scaf[i].next_strand;
                        pos2 = vs.scaf[i].next_pos;
                        vs2 = this.path.vsHash[strand2];
                        if (vs.number % 2 == result) {
                            type1 = CrossoverHandle.LEFT_UP;
                        } else {
                            type1 = CrossoverHandle.RIGHT_DOWN;
                        }
                        if (vs2.number % 2 == result) {
                            type2 = CrossoverHandle.RIGHT_UP;
                        } else {
                            type2 = CrossoverHandle.LEFT_DOWN;
                        }
                        xo1 = new CrossoverHandle(this, vs, CrossoverHandle.SCAFFOLD, pos1, type1);
                        xo2 = new CrossoverHandle(this, vs2, CrossoverHandle.SCAFFOLD, pos2, type2);
                        xo1.neighbor = xo2; // pair crossovers
                        xo2.neighbor = xo1;
                        if (vs == vs2) {
                            vs.drawVstrand.addScafCrossoverPair(xo1,xo2,false);
                        } else {
                            vs.drawVstrand.addScafCrossover(xo1,false);
                            vs2.drawVstrand.addScafCrossover(xo2,false);
                        }
                    }
                    
                    // STAPLE CROSSOVER HANDLES
                    result = 1;
                    if (vs.hasStapXover(i,false)) {
                        strand1 = vs.number;
                        pos1 = i;
                        strand2 = vs.stap[i].next_strand;
                        pos2 = vs.stap[i].next_pos;
                        vs2 = this.path.vsHash[strand2];
                        
                        if (vs.number % 2 == result) {
                            type1 = CrossoverHandle.LEFT_UP;
                        } else {
                            type1 = CrossoverHandle.RIGHT_DOWN;
                        }
                        if (vs2.number % 2 == result) {
                            type2 = CrossoverHandle.RIGHT_UP;
                        } else {
                            type2 = CrossoverHandle.LEFT_DOWN;
                        }
                        xo1 = new CrossoverHandle(this, vs, CrossoverHandle.STAPLE, pos1, type1);
                        xo2 = new CrossoverHandle(this, vs2, CrossoverHandle.STAPLE, pos2, type2);
                        xo1.neighbor = xo2; // pair crossovers
                        xo2.neighbor = xo1;
                        if (vs == vs2) {
                            vs.drawVstrand.addStapCrossoverPair(xo1,xo2,false);
                        } else {
                            vs.drawVstrand.addStapCrossover(xo1,false);
                            vs2.drawVstrand.addStapCrossover(xo2,false);
                        }
                    }
                    
                    // LOOP HANDLES
                    if (vs.getLoop(i) != 0) {
                        vs.drawVstrand.addLoopHandle(i, vs.getLoop(i));
                    }
                    
                    // SKIP HANDLES
                    if (vs.getSkip(i) != 0) {
                        vs.drawVstrand.addSkipHandle(i);
                    }
                }
            }
        }
        
        /* Add a DrawVstrand object to the DrawPath. */
        public function addDrawVstrand(dv:DrawVstrand):void {
            this.dvLayer.addChild(dv);
            this.redrawSliceBar();
        }
        
        /*
        Start dragging the sliceBar on MOUSE_DOWN event.
        Add stage handler for mouseup event.
        */
        private function mouseDownSliceBar(event:MouseEvent):void {
            event.updateAfterEvent()
            if (event.shiftKey && event.altKey) {
                this.allowRefresh = false;
                var vsIter:DListIterator = this.path.vsList.getListIterator();
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    vsIter.node.data.drawVstrand.pushAllScafBreaks();
                }
                this.allowRefresh = true;
                this.update();
            } else {
                var w:int = (this.path.vsList.head.data.scaf.length-1)*baseWidth;
                this.sliceBar.startDrag(false,new Rectangle(0,0,w,0));
                this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpSliceBar);
                this.sliceBar.addEventListener(MouseEvent.MOUSE_MOVE, moveSliceBar);
                this.prevSlice.visible = false;
                this.nextSlice.visible = false;
            }
        }
        
        /*
        Stop dragging the sliceBar on MOUSE_UP event and snap to base grid.
        */
        private function mouseUpSliceBar(event:MouseEvent):void {
            event.updateAfterEvent();
            this.sliceBar.stopDrag();
            this.sliceBar.x = Math.round(this.sliceBar.x/baseWidth) * baseWidth;
            this.currentSlice = Math.round(this.sliceBar.x/baseWidth);
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpSliceBar);
            this.sliceBar.removeEventListener(MouseEvent.MOUSE_MOVE, moveSliceBar);
            this.drawSlice.update();
            this.sliceBarLabel.text = this.currentSlice.toString();
            this.sliceBarLabel.setTextFormat(this.format);
            
            if (this.currentSlice == 0) {
                this.prevSlice.x = -32 - baseWidth;
                this.prevSlice.visible = true;
            } else if (this.currentSlice == this.path.vsList.head.data.scaf.length-1) {
                this.nextSlice.x = this.sliceBar.x + 2*baseWidth;
                this.nextSlice.visible = true;
            }
        }
        
        private function moveSliceBar(event:MouseEvent):void {
            event.updateAfterEvent();
            this.currentSlice = Math.round(this.sliceBar.x/baseWidth);
            this.sliceBarLabel.text = this.currentSlice.toString();
            this.sliceBarLabel.setTextFormat(this.format);
            this.drawSlice.update();
        }
        
        public function resetSliceBar():void {
            var g:Graphics = this.sliceBar.graphics;
            g.clear();
            this.sliceBarLabel.text = "";
            this.currentSlice = 21;
            this.prevSlice.visible = false;
            this.nextSlice.visible = false;
        }
        
        public function redrawSliceBar():void {
            var g:Graphics = this.sliceBar.graphics;
            g.clear();
            var x,y,w,h:int;
            x = 0;
            y = -5*baseWidth;
            w = baseWidth;
            h = this.path.vsList.size*5*baseWidth + 6*baseWidth;
            g.beginFill(0xcc6600,0.25);
            g.drawRect(x,y,w,h);
            g.endFill();
            this.sliceBar.x = this.currentSlice * baseWidth;
            this.sliceBarLabel.text = this.currentSlice.toString();
            this.sliceBarLabel.setTextFormat(this.format);
            
            if (this.currentSlice == 0) {
                this.prevSlice.x = -32 - baseWidth;
                this.prevSlice.visible = true;
                this.nextSlice.visible = false;
            } else if (this.currentSlice == this.path.vsList.head.data.scaf.length-1) {
                this.nextSlice.x = this.sliceBar.x + 2*baseWidth;
                this.prevSlice.visible = false;
                this.nextSlice.visible = true;
            } else {
                this.prevSlice.visible = false;
                this.nextSlice.visible = false;
            }
        }
        
        public function addHelixHandle(node:SliceNode,rank:int):void {
            var dph:DrawPathHandle = new DrawPathHandle(this, node);
            this.helixlabelList.append(dph);
            this.addChild(dph);
            dph.x = handleOffset;
            dph.y = rank*baseWidth*5 + baseWidth;
        }
        
        public function addGridLines(rank:int, w:int):void {
            var i:int = rank;
            var vswidth:int = w;
            
            // draw horizontal lines
            var g:Graphics = this.gridLayer.graphics;
            g.lineStyle(0.25, 0xcccccc);
            g.moveTo(0, i*5*baseWidth);
            g.lineTo(vswidth*baseWidth, i*5*baseWidth);
            g.moveTo(0, i*5*baseWidth + baseWidth);
            g.lineTo(vswidth*baseWidth, i*5*baseWidth + baseWidth);
            g.moveTo(0, i*5*baseWidth + baseWidth*2);
            g.lineTo(vswidth*baseWidth, i*5*baseWidth + baseWidth*2);
            
            var j:int;
            for (j = 0; j <= vswidth; j++) {
                // draw vertical lines
                if (j % 7 == 0) {
                    g.lineStyle(0.25, 0x666666);
                } else {
                    g.lineStyle(0.25, 0xcccccc);
                }
                g.moveTo(j*baseWidth, i*5*baseWidth);
                g.lineTo(j*baseWidth, i*5*baseWidth + baseWidth*2);
            }
        }
        
        public function redrawGridLines():void {
            var g:Graphics = this.gridLayer.graphics;
            g.clear();
            if (this.path.vsList.size == 0) {return;}
            
            // look at the first helix to determine dimensions
            var vswidth:int = this.path.vsList.head.data.scaf.length;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var i:int = 0;
            
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                
                // draw horizontal lines
                g.lineStyle(0.25, 0xcccccc);
                g.moveTo(0, i*5*baseWidth);
                g.lineTo(vswidth*baseWidth, i*5*baseWidth);
                g.moveTo(0, i*5*baseWidth + baseWidth);
                g.lineTo(vswidth*baseWidth, i*5*baseWidth + baseWidth);
                g.moveTo(0, i*5*baseWidth + baseWidth*2);
                g.lineTo(vswidth*baseWidth, i*5*baseWidth + baseWidth*2);
                
                var j:int;
                for (j = 0; j <= vswidth; j++) {
                    // draw vertical lines
                    if (j % 7 == 0) {
                        g.lineStyle(0.25, 0x666666);
                    } else {
                        g.lineStyle(0.25, 0xcccccc);
                    }
                    g.moveTo(j*baseWidth, i*5*baseWidth);
                    g.lineTo(j*baseWidth, i*5*baseWidth + baseWidth*2);
                }
                
                i++; // next position
            }
            
            //this.setChildIndex(gridLayer, 0); // move to bottom
        }
        
        public function reNumberHelixLabels():void {
            var iter:DListIterator = this.helixlabelList.getListIterator();
            for (iter.start(); iter.valid(); iter.forth()) {
                iter.data.updateNumber();
            }
            this.makeActive(this.activeVstrand, this.activePos, true);
        }
        
        /*
        Re-orders handle and path linked lists when a DrawPath handle
        is dragged to a new position.
        */
        public function handleUpdate(helixNum:int, newY:int):void {
            var i, rank, oldpos:int; // new position in helix ordering
            var iter:DListIterator = this.helixlabelList.getListIterator();
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var vs:Vstrand;
            var dph:DrawPathHandle;
            i = rank = 0;
            
            // Step 1: find new position based on y coordinate
            for (iter.start(); iter.valid(); iter.forth()) {
                if (iter.node.data.num == helixNum) {
                    oldpos = i;  // found
                } else if (newY > iter.node.data.y) {
                    rank = rank + 1;
                }
                i = i + 1;
            }
            
            // Step 2: remove old data and store it for re-insertion
            iter.start();
            vsIter.start();
            for (i = 0; i < this.helixlabelList.size; i++) {
                if (i == oldpos) {
                    dph = iter.node.data;
                    vs = vsIter.node.data;
                    iter.remove();
                    vsIter.remove();
                    break;
                }
                iter.forth();
                vsIter.forth();
            }
            
            // Step 3: insert old data at new position
            if (rank == this.helixlabelList.size) {  // insert at end
                helixlabelList.append(dph);
                this.path.vsList.append(vs);
            } else {
                iter.start();
                vsIter.start();
                for (i = 0; i < rank; i++) {
                    iter.forth();
                    vsIter.forth();
                }
                helixlabelList.insertBefore(iter,dph);
                this.path.vsList.insertBefore(vsIter,vs);
            }
            
            // Step 4: re-position everything with the new order
            iter.start();
            vsIter.start();
            for (i = 0; i < this.helixlabelList.size; i++) {
                iter.node.data.x = handleOffset;
                iter.node.data.y = i*baseWidth*5 + baseWidth;
                vsIter.node.data.drawVstrand.y = i*baseWidth*5;
                iter.forth();
                vsIter.forth();
            }
            
            this.makeActive(this.activeVstrand, this.activePos, true);
            
            // loop through all vstrands and redraw all crossover lines
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vsIter.node.data.drawVstrand.redrawCrossoverLines();
            }
            
        }
        
        /*
        Update with paths new data and redraw.
        Draw scaf and stap lines by default.  DataTools.updateInterface()
        calls update with drawLines == false to speed things up.
        */
        public function update():void {
            // nothing to draw at first update
            if (this.path.vsList.size == 0) {return;}
            
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vsIter.node.data.drawVstrand.update();
            }
            
            this.redrawGridLines();
            this.redrawSliceBar();
            this.makeActive(this.activeVstrand, this.activePos);
        }
        
        /*
        Update drawVstrand staple paths with new data and redraw.
        Optional argument: checkForEdits, if true, will only redraw
        drawVstrand staples if drawVstrand.doStapRedraw == true.
        */
        public function updateStap(checkForEdits:Boolean=false):void {
            // nothing to draw at first update
            if (this.path.vsList.size == 0) {return;}
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            
            if (!checkForEdits) {
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    vsIter.node.data.drawVstrand.updateStap();
                }
            } else {
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    if (vsIter.node.data.drawVstrand.doStapRedraw) {
                        vsIter.node.data.drawVstrand.updateStap();
                    }
                }
            }
        }
        
        /* Called by PreCrossoverHandle or DrawPath.loadCrossoverHandles to install a new SCAFFOLD Crossover. */
        public function addScafCrossover(px1:PreCrossoverHandle, px2:PreCrossoverHandle):void {
            var xo1:CrossoverHandle = new CrossoverHandle(this, px1.vstrand, px1.strandType, px1.pos, px1.type);
            var xo2:CrossoverHandle = new CrossoverHandle(this, px2.vstrand, px2.strandType, px2.pos, px2.type);
            xo1.neighbor = xo2; // pair crossovers
            xo2.neighbor = xo1;
            if (px1.vstrand == px2.vstrand) {
                px1.vstrand.drawVstrand.addScafCrossoverPair(xo1,xo2);
            } else {
                px1.vstrand.drawVstrand.addScafCrossover(xo1);
                px2.vstrand.drawVstrand.addScafCrossover(xo2);
            }
            // PreCrossoverHandles will be reset on next pass to makeActive
            px1.visible = false;
            px2.visible = false;
        }
        
        /* Called by PreCrossoverHandle to install a new STAPLE Crossover. */
        public function addStapCrossover(px1:PreCrossoverHandle, px2:PreCrossoverHandle):void {
            var xo1:CrossoverHandle = new CrossoverHandle(this, px1.vstrand, px1.strandType, px1.pos, px1.type);
            var xo2:CrossoverHandle = new CrossoverHandle(this, px2.vstrand, px2.strandType, px2.pos, px2.type);
            xo1.neighbor = xo2; // pair crossovers
            xo2.neighbor = xo1;
            if (px1.vstrand == px2.vstrand) {
                px1.vstrand.drawVstrand.addStapCrossoverPair(xo1,xo2);
            } else {
                px1.vstrand.drawVstrand.addStapCrossover(xo1);
                px2.vstrand.drawVstrand.addStapCrossover(xo2);
            }
            // PreCrossoverHandles will be reset on next pass to makeActive
            px1.visible = false;
            px2.visible = false;
        }
        
        /* Called by PathTools.autoStapleHandler().
        Installs all possible staple crossovers at on active vstrand. */
        public function stapAutoXO():void {
            var px,preXO:PreCrossoverHandle;
            var stapPreXO:Array = new Array();
            
            this.preXovers.sortOn("pos", Array.NUMERIC);
            while (preXO = this.preXovers.pop()) {
                if (preXO.strandType == STAPLE) {
                    if (preXO.vstrand == this.activeVstrand) {
                        // ugly if statement to avoid installing
                        // staple xovers within 5 bases of scaf xover
                        // or 3 bases of an edge
                        if (!this.activeVstrand.hasScafXover(preXO.pos-4) &&
                            !this.activeVstrand.hasScafXover(preXO.pos+4) &&
                            !this.activeVstrand.hasScafXover(preXO.pos-5) &&
                            !this.activeVstrand.hasScafXover(preXO.pos+5) &&
                            this.activeVstrand.hasScaf(preXO.pos-3) &&
                            this.activeVstrand.hasScaf(preXO.pos+3)) {
                            stapPreXO.push(preXO);
                        } else {
                            preXOpool.object = preXO;
                        }
                    } else {
                        preXOpool.object = preXO;
                    }
                } else { // return scaffold preXO to the pool
                    preXOpool.object = preXO;
                }
            }
            
            while (px = stapPreXO.pop()) {
                this.addStapCrossover(px, px.neighbor);
                preXOpool.object = px;
            }
        }
        
        
        public function purgePreXOPool():void {
            preXOpool.purge();
        }
        
        
        public function stapAutoColor(inputData:Boolean=false):void {
            var vs:Vstrand;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var stap5pBreaks:Array = new Array();
            var pos:int;
            var stapToken:Token;
            var next_s, next_p:int;
            var color:uint;
            var bp:BreakpointHandle;
            var xo:CrossoverHandle;
            
            // collect 5' staple ends
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                for each (bp in vs.drawVstrand.stapbreaks) {
                    if (bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME) {
                        stap5pBreaks.push(bp);
                    }
                }
            }
            
            if (inputData) {
                allowRefresh = false;
                for each (bp in stap5pBreaks) {
                    vs = bp.vstrand;
                    pos = bp.pos;
                    stapToken = vs.stap[pos];
                    color = stapToken.color
                    this.updateStapleColor(vs,pos,color);
                }
                allowRefresh = true;
            } else {
                colorIndex = 0;
                // loop through each 5' end an color staple
                for each (bp in stap5pBreaks) {
                    vs = bp.vstrand;
                    pos = bp.pos;
                    stapToken = vs.stap[pos];
                    color = stapleColorSet[int(colorIndex % stapleColorSet.length)];
                    this.updateStapleColor(vs,pos,color);
                    colorIndex++; // next color in stapleColorSet
                }
            }
        }
        
        
        public function getStapLength(v:Vstrand, p:int):int {
            var vs:Vstrand = v;
            var pos:int = p;
            var stapToken:Token;
            var stapLength:int = 1 + vs.loop[pos] + vs.skip[pos];
            
            while(!vs.isStap5PrimeEnd(pos)) {
                stapToken = vs.stap[pos];
                if (stapToken.prev_strand != vs.number) { // switch to new vstrand
                    vs = this.path.vsHash[stapToken.prev_strand];
                }
                pos = stapToken.prev_pos;
                if (vs == v && pos == p) { // check for circular path
                    return stapLength;
                }
                stapLength += 1 + vs.loop[pos] + vs.skip[pos];
            }
            vs = v; // reset to start for 3'
            pos = p;
            while(!vs.isStap3PrimeEnd(pos)) {
                stapToken = vs.stap[pos];
                if (stapToken.next_strand != vs.number) { // switch to new vstrand
                    vs = this.path.vsHash[stapToken.next_strand];
                }
                pos = stapToken.next_pos;
                if (vs == v && pos == p) { // check for circular path
                    return stapLength;
                }
                stapLength += 1 + vs.loop[pos] + vs.skip[pos];
            }
            return stapLength;
        }
        
        /* Return whether staple should be highlighted. */
        public function notifyLengthChange(delta:int, vs:Vstrand, pos:int, color:uint):Boolean {
            var stapLength:int = this.getStapLength(vs, pos);
            var highlight:Boolean = false;
            
            if (stapLength > STAP_MAX || stapLength < STAP_MIN) {
                highlight = true;
            }
            
            // check if we need to redraw
            if (delta > 0) { // bases were added
                if (stapLength > STAP_MAX) {
                    if (stapLength-delta <= STAP_MAX) { // transition was made
                        this.updateStapleColor(vs, pos, color);
                    }
                } else if (stapLength >= STAP_MIN) {
                    if (stapLength-delta < STAP_MIN) { // transition was made
                        this.updateStapleColor(vs, pos, color);
                    }
                }
            } else { // bases were removed
                if (stapLength < STAP_MIN) {
                    if (stapLength-delta >= STAP_MIN) { // transition was made
                        this.updateStapleColor(vs, pos, color);
                    }
                } else if (stapLength <= STAP_MAX) {
                    if (stapLength-delta > STAP_MAX) { // transition was made
                        this.updateStapleColor(vs, pos, color);
                    }
                }
            }
            return highlight;
        }
        
        /* Recolor a staple and its crossover handles, and notify drawVstarnd that
        its staples should be redrawn on next call to drawPath.updateScaf(). */
        public function updateStapleColor(v:Vstrand, p:int, color:int=-1):void {
            var stapToken:Token;
            var xo:CrossoverHandle;
            var vs:Vstrand = v;
            var dvs:DrawVstrand = v.drawVstrand;
            var pos:int = p;
            var i,c:uint;
            var stapLength:int = 1 + vs.loop[pos] + vs.skip[pos];
            var circularPath:Boolean = false;
            
            if (color == -1) { // pick color at random
                i = int(Math.random()*stapleColorSet.length) % stapleColorSet.length;
                c = stapleColorSet[i];
            } else { // use specified color
                c = uint(color);
            }
            
            // traverse each staple until 5' is reached.
            while(!vs.isStap5PrimeEnd(pos)) {
                vs.stap[pos].color = c;
                if (vs.hasStapXover(pos)) { // set Crossover color handle if present
                    xo = vs.drawVstrand.getStapleCrossoverHandleAt(pos);
                    if (xo != null) {
                        xo.updateColor(c);
                        this.tokenList.push(vs.stap[pos]);
                    } else {
                        //trace("Error: attempted to color null 5' BreakpointHandle at", vs.number, "[", pos, "]");
                    }
                }
                
                // advance to next pos
                stapToken = vs.stap[pos];
                if (stapToken.prev_strand != vs.number) { // switch to new vstrand
                    vs = this.path.vsHash[stapToken.prev_strand]; // 
                    vs.drawVstrand.doStapRedraw = true;
                }
                pos = stapToken.prev_pos;
                
                // check for circular path
                if (vs == v && pos == p) {
                    // do highlighting
                    this.processTokenList(true);
                    return;
                }
                stapLength += 1 + vs.loop[pos] + vs.skip[pos];
            }
            
            this.tokenList.push(vs.stap[pos]);
            
            // set 5' staple token color
            vs.stap[pos].color = c;
            vs = v; // reset to start for 3'
            pos = p;
            // traverse each staple until 3' is reached.
            while(!vs.isStap3PrimeEnd(pos)) {
                vs.stap[pos].color = c;
                if (vs.hasStapXover(pos)) { // set Crossover color handle if present
                    xo = vs.drawVstrand.getStapleCrossoverHandleAt(pos);
                    if (xo != null) {
                        xo.updateColor(c);
                        this.tokenList.push(vs.stap[pos]);
                    } else {
                        //trace("Error: attempted to color null 3' BreakpointHandle at", vs.number, "[", pos, "]");
                    }
                }
                
                // advance to next pos
                stapToken = vs.stap[pos];
                if (stapToken.next_strand != vs.number) { // switch to new vstrand
                    vs = this.path.vsHash[stapToken.next_strand]; // 
                    vs.drawVstrand.doStapRedraw = true;
                }
                pos = stapToken.next_pos;
                
                // check for circular path
                if (vs == v && pos == p) {
                    // do highlighting
                    return;
                }
                stapLength += 1 + vs.loop[pos] + vs.skip[pos];
            }
            // set 3' staple token color
            vs.stap[pos].color = c;
            
            this.tokenList.push(vs.stap[pos]);
            
            if (stapLength < STAP_MIN || stapLength > STAP_MAX) {
                this.processTokenList(true);
            } else {
                this.processTokenList(false);
            }
            
            dvs.updateStap(); // redraw starting vstrand immediately
        }
        
        private function processTokenList(h:Boolean) {
            while (this.tokenList.length > 0) {
                this.tokenList[0].highlight = h;
                this.tokenList.shift();
            }
        }
        
        /* Called by PathTools.autoStapleHandler().
        Installs default breakpoints in staple strands.
        */
        public function stapAutoBreak():void {}
        
        /* Clear previous hairpins that have been drawn when loading 
           a new design from DataTools. */
        public function clearHairpins():void {
            this.hairpinLayer.graphics.clear();
        }
        
        /* Called by PathTools.autoStapleHandler().
        Populates scaffold tokens with scaffold sequence.
        Populates staple tokens with complementary sequence.
        */
        public function populateScaffold(vsNumber:int, startPos:int, seq:String):Array {
            var scafToken:Token;
            var pos:int = startPos;
            var vs:Vstrand = this.path.vsHash[vsNumber];
            var index:int = 0;
            var k:int; // number of bases to add
            var bases:String; // 
            var fullSeq:String;
            
            // hairpins & marked regions
            /* indexOf returns -1 if hairpin doesn't exist.  
               h1start and others are set to -1 once the hairpin has been drawn
               to avoid unnecessary 
            */
            var h1start:int = seq.indexOf(Sequence.hairpin1); 
            var h1end:int = h1start + Sequence.hairpin1.length;
            var h2start:int = seq.indexOf(Sequence.hairpin2);
            var h2end:int = h2start + Sequence.hairpin2.length;
            var m1start:int = seq.indexOf(Sequence.mark1);
            var m1end:int = m1start + Sequence.mark1.length;
            var m2start:int = seq.indexOf(Sequence.mark2);
            var m2end:int = m2start + Sequence.mark2.length;
            var m3start:int = seq.indexOf(Sequence.mark3);
            var m3end:int = m3start + Sequence.mark3.length;
            var m4start:int = seq.indexOf(Sequence.mark4);
            var m4end:int = m4start + Sequence.mark4.length;
            var m5start:int = seq.indexOf(Sequence.mark5);
            var m5end:int = m5start + Sequence.mark5.length;
            var m6start:int = seq.indexOf(Sequence.mark6);
            var m6end:int = m6start + Sequence.mark6.length;
            var m7start:int = seq.indexOf(Sequence.mark7);
            var m7end:int = m7start + Sequence.mark7.length;
            var g:Graphics = this.hairpinLayer.graphics;
            g.clear();
            scafBasesAdded = 0;
            
            // starting at vsIndex[pos], traverse scaffold and update each token with sequence
            while (!vs.isScaf3PrimeEnd(pos)) {
                k = 1 + vs.loop[pos] + vs.skip[pos];
                if (index+k < seq.length) {
                    bases = seq.substr(index,k);
                    vs.scaf[pos].sequence = bases; // populate scaffold
                    
                    fullSeq += bases;
                    if (vs.hasStap(pos)) { // populate staple if present
                        vs.stap[pos].sequence = comp(bases);
                    }
                    
                    // highlight hairpins
                    if (h1start != -1) { // check if hairpin is active
                        if (index >= h1start) {
                            h1start = highlightScaffold(index, h1start, h1end, vs, pos, g, DrawPath.hairpinColor);
                        }
                    }
                    if (h2start != -1) {
                        if (index >= h2start) {
                            h2start = highlightScaffold(index, h2start, h2end, vs, pos, g, DrawPath.hairpinColor);
                        }
                    }
                    if (m1start != -1) {
                        if (index >= m1start) {
                            m1start = highlightScaffold(index, m1start, m1end, vs, pos, g, markColor1);
                        }
                    }
                    if (m2start != -1) {
                        if (index >= m2start) {
                            m2start = highlightScaffold(index, m2start, m2end, vs, pos, g, markColor2);
                        }
                    }
                    if (m3start != -1) {
                        if (index >= m3start) {
                            m3start = highlightScaffold(index, m3start, m3end, vs, pos, g, markColor3);
                        }
                    }
                    if (m4start != -1) {
                        if (index >= m4start) {
                            m4start = highlightScaffold(index, m4start, m4end, vs, pos, g, markColor4);
                        }
                    }
                    if (m5start != -1) {
                        if (index >= m5start) {
                            m5start = highlightScaffold(index, m5start, m5end, vs, pos, g, DrawPath.hairpinColor);
                        }
                    }
                    if (m6start != -1) {
                        if (index >= m6start) {
                            m6start = highlightScaffold(index, m6start, m6end, vs, pos, g, DrawPath.hairpinColor);
                        }
                    }
                    if (m7start != -1) {
                        if (index >= m7start) {
                            m7start = highlightScaffold(index, m7start, m7end, vs, pos, g, markColor7);
                        }
                    }
                    
                    index += k;
                    
                    // advance to next position
                    scafToken = vs.scaf[pos];
                    vs = this.path.vsHash[scafToken.next_strand];
                    pos = scafToken.next_pos;
                } else {
                    // return null, PathTools will display error message.
                    //trace("1 not enough bases:",index, k, seq.length, "\n", fullSeq);
                    return null;
                }
            }
            
            // populate final 3' base
            k = 1 + vs.loop[pos] + vs.skip[pos];
            if (index+k <= seq.length) {
                bases = seq.substr(index,k);
                vs.scaf[pos].sequence = bases; // populate scaffold
                if (vs.hasStap(pos)) { // populate staple if present
                    vs.stap[pos].sequence = comp(bases);
                }
                if (h1start != -1) { // check if hairpin is active
                    if (index >= h1start) {
                        h1start = highlightScaffold(index, h1start, h1end, vs, pos, g, DrawPath.hairpinColor);
                    }
                }
                if (h2start != -1) {
                    if (index >= h2start) {
                        h2start = highlightScaffold(index, h2start, h2end, vs, pos, g, DrawPath.hairpinColor);
                    }
                }
                if (m1start != -1) {
                    if (index >= m1start) {
                        m1start = highlightScaffold(index, m1start, m1end, vs, pos, g, markColor1);
                    }
                }
                if (m2start != -1) {
                    if (index >= m2start) {
                        m2start = highlightScaffold(index, m2start, m2end, vs, pos, g, markColor2);
                    }
                }
                if (m3start != -1) {
                    if (index >= m3start) {
                        m3start = highlightScaffold(index, m3start, m3end, vs, pos, g, markColor3);
                    }
                }
                if (m4start != -1) {
                    if (index >= m4start) {
                        m4start = highlightScaffold(index, m4start, m4end, vs, pos, g, markColor4);
                    }
                }
                if (m5start != -1) {
                    if (index >= m4start) {
                        m5start = highlightScaffold(index, m5start, m5end, vs, pos, g, DrawPath.hairpinColor);
                    }
                }
                if (m6start != -1) {
                    if (index >= m4start) {
                        m6start = highlightScaffold(index, m6start, m6end, vs, pos, g, DrawPath.hairpinColor);
                    }
                }
                if (m7start != -1) {
                    if (index >= m4start) {
                        m7start = highlightScaffold(index, m7start, m7end, vs, pos, g, markColor7);
                    }
                }
                index += k;
            } else {
                // return null, PathTools will display error message.
                //trace("2 not enough bases:",index, k, seq.length, "\n", fullSeq);
                return null;
            }
            
            scafBasesAdded = index;
            return collectStapleSequences();
        }
        
        /* Check if currently populating a hairpin or marked scaffold region.
           If so, draw a square at that position.  Return -1 when reaching the end
           of the region so populateScaffold can stop checking for it.  */
        private function highlightScaffold(index:int, start:int, end:int, vs:Vstrand, pos:int, g:Graphics, color:uint):int {
            var yoffset:int;
            if (start != -1) { // check if hairpin is active
                if (index == start) { // set color for highlighting
                    g.lineStyle(baseWidth, color, 0.5, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                }
                if (index >= start && index < end) { // check if we're in bounds
                    yoffset = (vs.number % 2) * baseWidth;
                    g.moveTo(pos*baseWidth, vs.drawVstrand.y + halfbaseWidth + yoffset);
                    g.lineTo(pos*baseWidth+baseWidth, vs.drawVstrand.y + halfbaseWidth + yoffset);
                }
                if (index == end) {
                    return -1; // stop checking for hairpin1
                } 
            }
            return start;
        }
        
        /* Return reverse complement of string. */
        private var trans:Object = {"A":"T", "a":"T", "C":"G", "c":"G", "G":"C", "g":"C", "T":"A", "t":"A", "?":"?"}
        private function comp(s:String):String {
            var r:String = new String();
            for (var i:int = s.length-1; i>=0; i--) {
                r += trans[s.charAt(i)];
            }
            return r;
        }
        
        public function collectStapleSequences():Array {
            var result:Array = new Array();
            var pos:int;
            var ends:Array = new Array();
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var vs:Vstrand;
            var s:String;
            
            // collect 5' ends
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                for (pos = 0; pos < vs.stap.length; pos++) {
                    if (vs.isStap5PrimeEnd(pos)) {
                        ends.push(new Point(pos, vs.number));
                    }
                }
            }
            
            var stapToken:Token;
            var head, tail:Point;
            var h,t:String;
            var color:String;
            for each (var p in ends) { // loop through each 5' end
                head = new Point(p.x,p.y); // store head coordinate
                pos = p.x;
                vs = this.path.vsHash[p.y];
                color = getHexColorString(vs.stap[pos].color);
                s = "";
                while(!vs.isStap3PrimeEnd(pos)) { // traverse path until 3' end
                    s += vs.stap[pos].sequence;
                    stapToken = vs.stap[pos];
                    vs = this.path.vsHash[stapToken.next_strand];
                    pos = stapToken.next_pos;
                }
                // add on last base
                s += vs.stap[pos].sequence;
                tail = new Point(pos,vs.number);
                
                h = head.y + "[" + head.x + "]";
                t = tail.y + "[" + tail.x + "]";
                
                result.push({"Start":h, "End":t, "Sequence":s, "Length":s.length, "Color":color});
            }
            return result;
        }
        
        /*convert the uints used to specify color in caDNAno into hex strings, e.g., #FFFFFF*/
        public function getHexColorString(hex:uint):String {
            var r:int = hex >> 16;
            var g:int = (hex ^ hex >> 16 << 16) >> 8;
            var b:int = hex >> 8 << 8 ^ hex;
            var r2,g2,b2:String;
            r2 = r.toString(16);
            g2 = g.toString(16);
            b2 = b.toString(16);
            if (r2.length < 2) {r2 = "0"+r2;}
            if (g2.length < 2) {g2 = "0"+g2;}
            if (b2.length < 2) {b2 = "0"+b2;}
            return "#" + r2 + g2 + b2;
        }
        
        /*
        Update a virtual strand after mouseclick to display local features for editing.
        - Overlay PreCrossoverHandles according to hard-coded standard crossover positions: p0, p1, p2.
        - Populate the 21-base segment containing pos, along with the two flanking 21-base segments.
        - If argument pos is omitted, populate full length of drawVstrand (for autoStapling).
        */
        public function makeActive(vs:Vstrand, pos:int=-1, forceRefresh:Boolean=false):void {
            if (vs == null) {
                return;
            } else if (vs == this.activeVstrand && pos == this.activePos && forceRefresh == false) {
                return; // don't redraw when clicked in same spot
            } else {
                this.activeVstrand = vs;
                this.activePos = pos;
            }
            
            var c1:PreCrossoverHandle;
            var start,end,i,j,yoffset:int;
            
            // determine range of preXovers to draw
            if (pos == -1) { // auto-staple
                start = 0;
                end = end = vs.scaf.length;
            } else { // mouse-click
                start = pos - (pos % 21) - 21;
                if (start < 0) {start = 0;}
                end = pos - (pos % 21) + 42;
                if (end > vs.scaf.length) {end = vs.scaf.length;}
            }
            
            if (vs.number % 2 == 0) {
                yoffset = -baseWidth;
            } else {
                yoffset = 3*baseWidth;
            }
            
            // get rid of old crossovers
            var oldX:PreCrossoverHandle;
            while (oldX = this.preXovers.pop()) {
                if (oldX.parent != null) {
                    this.activeLayer.removeChild(oldX);
                } else {
                    //trace("px parent null",oldX.vstrand.number, oldX.pos);
                }
                preXOpool.object = oldX; // return PreCrossoverHandle to object pool.
            }
            
            // find all possible crossovers
            if (vs.p0 != null) {
                for (i = start; i < end; i+= 21) {
                    // SCAFFOLD
                    for each (j in [1,11]) {
                        if ((vs.scaf[int(i+j)].prev_strand == vs.p0.number) || (vs.scaf[int(i+j)].next_strand == vs.p0.number)) {
                            continue; // crossover already present
                        }
                        // check if base is present locally and in neighbor
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) &&
                            (vs.p0.scaf[int(i+j)].prev_strand != -1 || vs.p0.scaf[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, LEFT, vs.p0.number);
                            c1.neighbor.init(this, vs.p0, SCAFFOLD, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [2,12]) {
                        if (vs.scaf[int(i+j)].prev_strand == vs.p0.number || vs.scaf[int(i+j)].next_strand == vs.p0.number) {
                            continue;
                        }
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) && 
                            (vs.p0.scaf[int(i+j)].prev_strand != -1 || vs.p0.scaf[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, RIGHT, vs.p0.number);
                            c1.neighbor.init(this, vs.p0, SCAFFOLD, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    // STAPLE
                    for each (j in [6]) {
                        if ((vs.stap[int(i+j)].prev_strand == vs.p0.number) || (vs.stap[int(i+j)].next_strand == vs.p0.number)) {
                            continue; // crossover already present
                        }
                        // check if base is present locally and in neighbor
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) &&
                            (vs.p0.stap[int(i+j)].prev_strand != -1 || vs.p0.stap[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, LEFT, vs.p0.number);
                            c1.neighbor.init(this, vs.p0, STAPLE, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [7]) {
                        if (vs.stap[int(i+j)].prev_strand == vs.p0.number || vs.stap[int(i+j)].next_strand == vs.p0.number) {
                            continue;
                        }
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) && 
                            (vs.p0.stap[int(i+j)].prev_strand != -1 || vs.p0.stap[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, RIGHT, vs.p0.number);
                            c1.neighbor.init(this, vs.p0, STAPLE, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                }
            }
            
            if (vs.p1 != null) {
                for (i = start; i < end; i+= 21) {
                    // SCAFFOLD
                    for each (j in [8,18]) {
                        if (vs.scaf[int(i+j)].prev_strand == vs.p1.number || vs.scaf[int(i+j)].next_strand == vs.p1.number) {
                            continue;
                        }
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) && 
                            (vs.p1.scaf[int(i+j)].prev_strand != -1 || vs.p1.scaf[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, LEFT, vs.p1.number);
                            c1.neighbor.init(this, vs.p1, SCAFFOLD, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [9,19]) {
                        if (vs.scaf[int(i+j)].prev_strand == vs.p1.number || vs.scaf[int(i+j)].next_strand == vs.p1.number) {
                            continue;
                        }
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) && 
                            (vs.p1.scaf[int(i+j)].prev_strand != -1 || vs.p1.scaf[int(i+j)].next_strand != -1) &&
                            (vs.scaf[int(i+j)].prev_strand != vs.p1.number || vs.scaf[int(i+j)].next_strand != vs.p1.number)
                            ) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, RIGHT, vs.p1.number);
                            c1.neighbor.init(this, vs.p1, SCAFFOLD, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    // STAPLE
                    for each (j in [13]) {
                        if (vs.stap[int(i+j)].prev_strand == vs.p1.number || vs.stap[int(i+j)].next_strand == vs.p1.number) {
                            continue;
                        }
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) && 
                            (vs.p1.stap[int(i+j)].prev_strand != -1 || vs.p1.stap[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, LEFT, vs.p1.number);
                            c1.neighbor.init(this, vs.p1, STAPLE, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [14]) {
                        if (vs.stap[int(i+j)].prev_strand == vs.p1.number || vs.stap[int(i+j)].next_strand == vs.p1.number) {
                            continue;
                        }
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) && 
                            (vs.p1.stap[int(i+j)].prev_strand != -1 || vs.p1.stap[int(i+j)].next_strand != -1) &&
                            (vs.stap[int(i+j)].prev_strand != vs.p1.number || vs.stap[int(i+j)].next_strand != vs.p1.number)
                            ) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, RIGHT, vs.p1.number);
                            c1.neighbor.init(this, vs.p1, STAPLE, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                }
            }
            
            if (vs.p2 != null) {
                for (i = start; i < end; i+= 21) {
                    // SCAFFOLD
                    for each (j in [4,15]) {
                        if (vs.scaf[int(i+j)].prev_strand == vs.p2.number || vs.scaf[int(i+j)].next_strand == vs.p2.number) {
                            continue;
                        }
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) &&
                            (vs.p2.scaf[int(i+j)].prev_strand != -1 || vs.p2.scaf[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, LEFT, vs.p2.number);
                            c1.neighbor.init(this, vs.p2, SCAFFOLD, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [5,16]) {
                        if (vs.scaf[int(i+j)].prev_strand == vs.p2.number || vs.scaf[int(i+j)].next_strand == vs.p2.number) {
                            continue;
                        }
                        if ((vs.scaf[int(i+j)].prev_strand != -1 || vs.scaf[int(i+j)].next_strand != -1) && 
                            (vs.p2.scaf[int(i+j)].prev_strand != -1 || vs.p2.scaf[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, SCAFFOLD, i+j, RIGHT, vs.p2.number);
                            c1.neighbor.init(this, vs.p2, SCAFFOLD, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    // STAPLE
                    for each (j in [20]) {
                        if (vs.stap[int(i+j)].prev_strand == vs.p2.number || vs.stap[int(i+j)].next_strand == vs.p2.number) {
                            continue;
                        }
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) &&
                            (vs.p2.stap[int(i+j)].prev_strand != -1 || vs.p2.stap[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, LEFT, vs.p2.number);
                            c1.neighbor.init(this, vs.p2, STAPLE, i+j, LEFT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                    for each (j in [0]) {
                        if (vs.stap[int(i+j)].prev_strand == vs.p2.number || vs.stap[int(i+j)].next_strand == vs.p2.number) {
                            continue;
                        }
                        if ((vs.stap[int(i+j)].prev_strand != -1 || vs.stap[int(i+j)].next_strand != -1) && 
                            (vs.p2.stap[int(i+j)].prev_strand != -1 || vs.p2.stap[int(i+j)].next_strand != -1)) {
                            c1 = preXOpool.object;
                            c1.neighbor = preXOpool.object;
                            c1.init(this, vs, STAPLE, i+j, RIGHT, vs.p2.number);
                            c1.neighbor.init(this, vs.p2, STAPLE, i+j, RIGHT, vs.number);
                            c1.neighbor.neighbor = c1;
                            this.preXovers.push(c1);
                            this.preXovers.push(c1.neighbor);
                        }
                    }
                }
            }
            // add each crossover to the canvas
            if (pos != -1) {
                for each(var newX in this.preXovers) {
                    this.activeLayer.addChild(newX);
                }
            }
            
            this.setChildIndex(activeLayer, this.numChildren-1); // move to top
        }
    }
}