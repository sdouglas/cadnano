//
//  SliceTools
//
//  Created by Shawn on 2007-12-09.
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
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    // misc
    import br.com.stimuli.loading.BulkLoader;
    import com.yahoo.astra.utils.*;
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    import edu.harvard.med.cadnano.drawing.*;
    
    /*
    SliceTools handles all slice-associated buttons.  This means
    creating the buttons, loading appropriate icons, setting up
    eventlisteners to carry out click-associated actions.
    
    SliceTools is intended to be added as a child of the slice
    instance of the Panel class.
    */
    public class SliceTools extends Sprite {
        public static const ROWS:int = 30;
        public static const COLS:int = 30;
        
        public var radius:int = 20;
        
        private var slicePanel:Panel;
        private var sliceList:DLinkedList;
        private var sliceIter:DListIterator;
        public var drawSlice:DrawSlice;
        private var path:Path;
        private var drawPath:DrawPath;
        
        private var editTool:ToolButton = new ToolButton("edit", 0xcc6600);
        private var zoomTool:ToolButton = new ToolButton("zoom", 0xcc6600);
        private var moveTool:ToolButton = new ToolButton("move", 0xcc6600);
        private var firstSlice:ToolButton = new ToolButton("first", 0xcc6600);
        private var lastSlice:ToolButton = new ToolButton("last", 0xcc6600);
        private var renumberSlice:ToolButton = new ToolButton("re\nnum", 0xcc6600);
        private var deleteLast:ToolButton = new ToolButton("delete\nlast", 0xcc6600);
        
        private var buttonArray:Array;
        
        private var zoomInCursor:Sprite = new Sprite();
        private var zoomOutCursor:Sprite = new Sprite();
        private var moveCursor:Sprite = new Sprite();
        private var point:Point;
        private var localpoint:Point = new Point();
        
        /*
        SliceTools is passed pointers to several main data structures
        since its buttons can affect both the way the slice and path
        panels are drawn.
        
        In particular, use of the zoom button requires updates in DrawSlice
        and the firstSlice, prevSlice, nextSlice, and lastSlice buttons
        requires updates to both DrawSlice and DrawPath.
        */
        function SliceTools(slicePanel:Panel, drawSlice:DrawSlice, path:Path, drawPath:DrawPath) {
            this.y = slicePanel.h + 10;
            
            this.slicePanel = slicePanel;
            this.sliceList = sliceList;
            this.sliceIter = sliceIter;
            this.drawSlice = drawSlice;
            this.path = path;
            this.drawPath = drawPath;
            this.drawPath.sliceTools = this; // ref for sharing radius with sliceBar
            
            // retrieve pre-loaded Bitmaps
            var mainLoader:BulkLoader = BulkLoader.getLoader("main");
            editTool.addChild(mainLoader.getBitmap("icons/slice-edit.png"));
            zoomTool.addChild(mainLoader.getBitmap("icons/slice-zoom.png"));
            zoomInCursor.addChild(mainLoader.getBitmap("icons/slice-zoomin.png"));
            zoomOutCursor.addChild(mainLoader.getBitmap("icons/slice-zoomout.png"));
            moveTool.addChild(mainLoader.getBitmap("icons/slice-transform.png"));
            moveCursor.addChild(mainLoader.getBitmap("icons/slice-transform-cursor.png"));
            firstSlice.addChild(mainLoader.getBitmap("icons/slice-go-first.png"));
            lastSlice.addChild(mainLoader.getBitmap("icons/slice-go-last.png"));
            renumberSlice.addChild(mainLoader.getBitmap("icons/slice-renumber.png"));
            deleteLast.addChild(mainLoader.getBitmap("icons/slice-delete-last.png"));
            
            // initilize buttons by calling setupButton() on each sprite
            buttonArray = new Array(editTool, zoomTool, moveTool, firstSlice, lastSlice, renumberSlice, deleteLast);
            buttonArray.forEach(setupButton);
            
            // set up custom cursors
            zoomInCursor.visible = false;
            zoomOutCursor.visible = false;
            moveCursor.visible = false;
            this.addChild(zoomInCursor);
            this.addChild(zoomOutCursor);
            this.addChild(moveCursor);
            this.slicePanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
            this.slicePanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
            
            // assign specific button functions
            editTool.addEventListener(MouseEvent.CLICK, editToolAction);
            zoomTool.addEventListener(MouseEvent.CLICK, zoomToolAction);
            moveTool.addEventListener(MouseEvent.CLICK, moveToolAction);
            firstSlice.addEventListener(MouseEvent.CLICK, firstSliceAction);
            lastSlice.addEventListener(MouseEvent.CLICK, lastSliceAction);
            renumberSlice.addEventListener(MouseEvent.CLICK, renumberSliceAction);
            deleteLast.addEventListener(MouseEvent.CLICK, deleteLastToolAction);
            
            editTool.enabled = true;
            editTool.graphics.beginFill(0xffcc99,0.5);
            editTool.graphics.lineStyle(1, 0xcc6600, 1, true);
            editTool.graphics.drawRect(0,0,32,32);
            editTool.graphics.endFill();
        }
        
        /*
        Used to align SliceTools after resize
        */
        public function update():void {
            this.x = this.slicePanel.leftX;
        }
        
        /* 
        Add button as child of display object, set its x coordinate
        and add hover and unhover listeners.
        */
        private function setupButton(button:*, index:int, array:Array):void {
            this.addChild(button);
            button.x = index*40; // x position of button
            button.addEventListener(MouseEvent.MOUSE_OVER, hover);
            button.addEventListener(MouseEvent.MOUSE_OUT, unhover);
        }
        
        /*
        Update custom cursor as mouse moves.  Depending on what button
        is toggled, different cursors are displayed.
        */
        private function mouseMoveHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            if (zoomTool.enabled) {
                localpoint.x = event.localX;
                localpoint.y = event.localY;
                point = DisplayObjectUtil.localToLocal(localpoint, this.slicePanel.mouseLayer, this);
                if (event.shiftKey) { // zoom out 
                    zoomInCursor.visible = false;
                    zoomOutCursor.visible = true;
                    zoomOutCursor.x = point.x;
                    zoomOutCursor.y = point.y;
                } else { // zoom in
                    zoomOutCursor.visible = false;
                    zoomInCursor.visible = true;
                    zoomInCursor.x = point.x;
                    zoomInCursor.y = point.y;
                }
            } else if (moveTool.enabled) {
                localpoint.x = event.localX;
                localpoint.y = event.localY;
                point = DisplayObjectUtil.localToLocal(localpoint, this.slicePanel.mouseLayer, this);
                moveCursor.visible = true;
                moveCursor.x = point.x;
                moveCursor.y = point.y;
            } else {
                //Mouse.show();
            }
        }
        
        /*
        Slice resizing is done with a complete re-draw based on a new 
        radius, so we cannot just use a DynamicRegistration.scale() here.
        
        In order for slice centering to work, need to calculate the canvas local
        coordinates of the mouse click.  We then re-draw everything and the
        size of the canvas changes.  We then want to center the canvas
        within the slicePanel using the new x,y coordinates that correspond
        to the area where the mouse was clicked before resizing.
        
        I do this by calculating the clicked x,y coordinates as fractions
        of the original width and height, and then using those fractions
        to calculate corresponding x,y coordinates on the re-scaled canvas.
        */
        private function mouseClickHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            
            var preC:Rectangle; // canvas bounds before resizing
            var preX, preY:Number; // clicked x,y as fraction of canvas bounds
            var postC:Rectangle; // canvas bounds after resizing
            
            // get initial size of canvas before resize
            preC = this.slicePanel.canvas.getRect(this.slicePanel.canvas);
            point = this.slicePanel.canvas.globalToLocal(new Point(event.stageX, event.stageY));
            
            // make sure point is within bounds of canvas
            if (point.x < 0) {
                point.x = 0;
            } else if (point.x > preC.width) {
                point.x = preC.width;
            }
            
            if (point.y < 0) {
                point.y = 0;
            } else if (point.y > preC.height) {
                point.y = preC.height;
            }
            
            // determine point position as fraction of canvas size
            preX = point.x / preC.width;
            preY = (point.y+.01) / preC.height;
            
            if (zoomTool.enabled) {
                if (event.shiftKey) { // zoom out 
                    if (radius > 5) {
                        radius = radius - 5; // adjust radius and redraw
                        this.drawSlice.update(radius); 
                        postC = this.slicePanel.canvas.getRect(this.slicePanel.canvas); // get new canvas size
                        // adjust x,y to be in same relative position
                        point.x = preX * postC.width;
                        point.y = preY * postC.height; 
                        // center on scaled click point
                        this.slicePanel.centerCanvas(point.x, point.y);
                    } else {
                        this.slicePanel.centerCanvas(); // center on center
                    }
                } else { // zoom in
                    if (radius < 50) {
                        radius = radius + 5;
                        this.drawSlice.update(radius);
                        postC = this.slicePanel.canvas.getRect(this.slicePanel.canvas);
                        point.x = preX * postC.width;
                        point.y = preY * postC.height;
                        this.slicePanel.centerCanvas(point.x, point.y);
                    }
                }
            }
        }
        
        /* 
        Handle initial mouse entry onto slicePanel.  Hide default cursor,
        listen for mouse_move events.
        */
        private function mouseOverHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            if (zoomTool.enabled || moveTool.enabled) {
                Mouse.hide();
                this.slicePanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
                this.slicePanel.mouseLayer.addEventListener(MouseEvent.CLICK, mouseClickHandler);
                
                if (moveTool.enabled) {
                    this.slicePanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                }
            } else {
                //Mouse.show();
            }
        }
        
        /*
        Start dragging the slice canvas on MOUSE_DOWN event.
        */
        private function mouseDownHandler(event:MouseEvent):void {
            this.slicePanel.canvas.startDrag();
            this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /*
        Stop dragging the slice canvas on MOUSE_UP event.
        */
        private function mouseUpHandler(event:MouseEvent):void {
            this.slicePanel.canvas.stopDrag();
            // set new canvas center point
            this.slicePanel.canvascp = DisplayObjectUtil.localToLocal(this.slicePanel.center,this.slicePanel,this.slicePanel.canvas);
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /* 
        Handle mouse exit from slicePanel.  Restore default cursor,
        stop listening for mouse_move events.  Hide custom cursors.
        */
        private function mouseOutHandler(event:MouseEvent):void {
            Mouse.show();
            zoomInCursor.visible = false;
            zoomOutCursor.visible = false;
            moveCursor.visible = false;
            this.slicePanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
            if (moveTool.enabled) {
                    this.slicePanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            }
        }
        
        /*
        Adjust button appearance when active
        */
        private function hover(event:MouseEvent):void {
            event.target.graphics.beginFill(0xffcc99, 0);
            event.target.graphics.lineStyle(1, 0xcc6600, 1, true);
            event.target.graphics.drawRect(0,0,32,32);
            event.target.graphics.endFill();
        }
        
        /*
        Restore button appearance when mouse leaves
        */
        private function unhover(event:MouseEvent):void {
            if (!event.target.enabled) {
                event.target.graphics.clear();
            }
        }
        
        /*
        Default edit mode
        */
        private function editToolAction(event:MouseEvent):void {
            if (!editTool.enabled) {
                editTool.enabled = true; // enable edit mode
                if (zoomTool.enabled) {  // disable zoom mode
                    zoomTool.enabled = false;
                    zoomTool.graphics.clear();
                    this.slicePanel.mouseLayer.visible = false;
                }
                if (moveTool.enabled) {  // disable move mode
                    moveTool.enabled = false;
                    moveTool.graphics.clear();
                    this.slicePanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                    this.slicePanel.mouseLayer.visible = false;
                }
                // highlight edit tool button
                editTool.graphics.beginFill(0xffcc99, 0.5);
                editTool.graphics.lineStyle(1, 0xcc6600, 1, true);
                editTool.graphics.drawRect(0,0,32,32);
                editTool.graphics.endFill();
            }
        }
        
        /*
        Enable zoom and disable others when zoom button is clicked
        */
        private function zoomToolAction(event:MouseEvent):void {
            if (!zoomTool.enabled) {
                zoomTool.enabled = true; // enable zoom mode
                this.slicePanel.mouseLayer.visible = true;
                
                if (editTool.enabled) { // disable edit mode
                    editTool.enabled = false;
                    editTool.graphics.clear();
                }
                if (moveTool.enabled) { // disable move mode
                    moveTool.enabled = false;
                    moveTool.graphics.clear();
                    this.slicePanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                    this.slicePanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
                }
                
                zoomTool.graphics.beginFill(0xffcc99, 0.5);
                zoomTool.graphics.lineStyle(1, 0xcc6600, 1, true);
                zoomTool.graphics.drawRect(0,0,32,32);
                zoomTool.graphics.endFill();
            }
        }
        
        /*
        Enable move and disable others when move button is clicked
        */
        private function moveToolAction(event:MouseEvent):void {
            if (!moveTool.enabled) {
                moveTool.enabled = true; // enable move mode
                this.slicePanel.mouseLayer.visible = true;
                
                if (editTool.enabled) { // disable edit mode
                    editTool.enabled = false;
                    editTool.graphics.clear();
                }
                if (zoomTool.enabled) { // disable zoom mode
                    zoomTool.enabled = false;
                    zoomTool.graphics.clear();
                }
                // highlight move tool button
                moveTool.graphics.beginFill(0xffcc99, 0.5);
                moveTool.graphics.lineStyle(1, 0xcc6600, 1, true);
                moveTool.graphics.drawRect(0,0,32,32);
                moveTool.graphics.endFill();
            }
        }
        
        /*
        Move to second slice when button clicked.
        We move here because it's the first slice you can visit
        without prepending more segments to the structure.
        */
        private function firstSliceAction(event:MouseEvent):void {
            if (this.path.vsList.size > 0) {
                this.drawPath.currentSlice = 0;
                this.drawSlice.update(radius);
                this.drawPath.redrawSliceBar();
            }
        }
        
        /* 
        Move to the penultimate slice.
        We move here because it's the last slice you can visit without
        appending more segments to the structure.
        */
        private function lastSliceAction(event:MouseEvent):void {
            if (this.path.vsList.size > 0) {
                this.drawPath.currentSlice = this.path.vsList.head.data.scaf.length - 1;
                this.drawSlice.update(radius);
                this.drawPath.redrawSliceBar();
            }
        }
        
        private function renumberSliceAction(event:MouseEvent):void {
            this.path.renumberHelices();
        }
        
        private function deleteLastToolAction(event:MouseEvent):void {
            this.drawSlice.deleteLast();
        }
    }
}
