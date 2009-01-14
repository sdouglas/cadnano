//
//  PathTools
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
    // components
    import fl.controls.BaseButton;
    import fl.controls.DataGrid;
    import fl.controls.Label;
    import fl.controls.NumericStepper;
    import fl.controls.TextArea;
    import fl.controls.TextInput;
    import fl.controls.ColorPicker;
    import fl.data.DataProvider;
    import fl.managers.FocusManager;
    
    // flash
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.InteractiveObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldType;
    import flash.text.TextFieldAutoSize;
    import flash.ui.Mouse;
    // debug
    import flash.utils.getTimer;
    
    // misc
    import br.com.stimuli.loading.BulkLoader;
    import com.yahoo.astra.fl.managers.AlertManager;
    import com.yahoo.astra.utils.*;
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.data.Sequence;
    import edu.harvard.med.cadnano.data.Svg;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.handles.CrossoverHandle;
    
    /*
    PathTools handles all path-associated buttons.  This means
    creating the buttons, loading appropriate icons, setting up
    eventlisteners to carry out click-associated actions.
    
    PathTools is intended to be added as a child of the path
    instance of the Panel class.
    */
    public class PathTools extends Sprite {
        
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        // bookkeeping
        private var pathPanel:Panel;
        private var drawPath:DrawPath;
        private var mainLoader:BulkLoader;
        private var buttonArray:Array;
        private var point:Point = new Point(); // for mouse calculations
        private var localpoint:Point = new Point(); // for mouse calculations
        private var loopCoord:Point = new Point(-1,-1); // store loop info when using loopTool
        private var xoType:String; // store xo type when using crossoverTool
        private var xoCoord1:Point = new Point(-1,-1); // store xo info when using crossoverTool
        private var xoCoord2:Point = new Point(-1,-1); // store xo info when using crossoverTool
        private var seqCoord:Point = new Point(-1,-1); // store seq info when using sequenceTool
        private var vs1, vs2:Vstrand; // store vstrands when using crossoverTool
        private var hoverBox:Sprite;
        private var hoverLoop:Sprite;
        private var hoverSkip:Sprite;
        private var xoBox:Sprite;
        private var redBox,xoSprite:Sprite;
        private var firstautostaple:Boolean = true; // pop up warning if false
        private var arrowKeysEnabled:Boolean = true;
        public var toolKeysEnabled:Boolean = true;
        private var fm:FocusManager;
        public var svg:Svg;
        
        // buttons
        private var editTool:ToolButton = new ToolButton("edit\n(v)", 0x0066cc);
        private var zoomTool:ToolButton = new ToolButton("zoom\n(z)", 0x0066cc);
        private var moveTool:ToolButton = new ToolButton("move\n(m)", 0x0066cc);
        private var breakTool:ToolButton = new ToolButton("break\n(b)", 0x0066cc);
        private var eraseTool:ToolButton = new ToolButton("erase\n(e)", 0x0066cc);
        private var autoStapleTool:ToolButton = new ToolButton("auto\nstaple", 0x0066cc);
        private var sequenceTool:ToolButton = new ToolButton("add\nseq", 0x0066cc); 
        private var loopTool:ToolButton = new ToolButton("3'loop\n(l)", 0x0066cc);
        private var skipTool:ToolButton = new ToolButton("skip\nbase\n(s)", 0x0066cc);
        private var crossoverTool:ToolButton = new ToolButton("force\npath\n(f)", 0x0066cc);
        private var svgTool:ToolButton = new ToolButton("export", 0x0066cc);
        private var paintTool:ToolButton = new ToolButton("paint\n(p)", 0x0066cc);
        
        private var colorPicker:ColorPicker;
        
        // mouse tools
        private var zoomInCursor:Sprite = new Sprite();
        private var zoomOutCursor:Sprite = new Sprite();
        private var moveCursor:Sprite = new Sprite();
        
        // alert box components
        private var loopAlertSprite:Sprite;
        private var numericStepper:NumericStepper;
        private var nsLabel:Label;
        private var stapleDataGridSprite:Sprite;
        private var stapleDataGrid:DataGrid;
        private var stapleDataProvider:DataProvider;
        private var customScaffoldSprite:Sprite;
        private var customScaffoldInput:TextArea;

        
        function PathTools(stage:Stage, pathPanel:Panel, drawPath:DrawPath) {
            this.y = pathPanel.h + 10;
            this.pathPanel = pathPanel;
            this.drawPath = drawPath;
            
            // retrieve pre-loaded Bitmaps
            mainLoader = BulkLoader.getLoader("main");
            this.loadBitMaps();
            
            // initilize buttons by calling setupButton() on each sprite
            this.buttonArray = new Array(editTool, zoomTool, moveTool, breakTool, eraseTool, 
                                         crossoverTool, loopTool, skipTool, paintTool);
            this.buttonArray.forEach(setupButton);
            
            // 2nd row of buttons
            this.buttonArray = new Array(autoStapleTool, sequenceTool, svgTool);
            this.buttonArray.forEach(setupAdvButton);
            
            // set up cursors
            this.zoomInCursor.visible = false;
            this.zoomOutCursor.visible = false;
            this.moveCursor.visible = false;
            this.addChild(zoomInCursor);
            this.addChild(zoomOutCursor);
            this.addChild(moveCursor);
            this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
            this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
            
            // assign specific button functions
            this.editTool.addEventListener(MouseEvent.CLICK, editToolAction);
            this.zoomTool.addEventListener(MouseEvent.CLICK, zoomToolAction);
            this.moveTool.addEventListener(MouseEvent.CLICK, moveToolAction);
            this.breakTool.addEventListener(MouseEvent.CLICK, breakToolAction);
            this.eraseTool.addEventListener(MouseEvent.CLICK, eraseToolAction);
            this.autoStapleTool.addEventListener(MouseEvent.CLICK, autoStapleToolAction);
            this.svgTool.addEventListener(MouseEvent.CLICK, svgToolAction);
            this.sequenceTool.addEventListener(MouseEvent.CLICK, sequenceToolAction);
            this.crossoverTool.addEventListener(MouseEvent.CLICK, crossoverToolAction);
            this.loopTool.addEventListener(MouseEvent.CLICK, loopToolAction);
            this.skipTool.addEventListener(MouseEvent.CLICK, skipToolAction);
            this.paintTool.addEventListener(MouseEvent.CLICK, paintToolAction);
            
            // start with edit tool enabled
            editTool.enabled = true;
            editTool.graphics.beginFill(0x99ccff,0.5);
            editTool.graphics.lineStyle(1, 0x0066cc, 1, true);
            editTool.graphics.drawRect(0,0,32,32);
            editTool.graphics.endFill();
            
            setupPaintTool();
            setupMouseOverSprites();
            setupAlertBoxSprites();
            
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            this.fm = new FocusManager(stage);
        }
        
        private function setupPaintTool():void {
            colorPicker = new ColorPicker();
            colorPicker.colors = DrawPath.stapleColorSet.concat(0x888888);
            colorPicker.selectedColor = 0xcc0000;
            colorPicker.height = colorPicker.width = 20;
            paintTool.addChild(colorPicker);
            colorPicker.x = colorPicker.y = 7;
            // HACK: disable left & right arrow keys when ColorPicker palette is open.
            colorPicker.addEventListener(Event.OPEN, cpOpenHandler);
            // HACK: set focus away from ColorPicker when a color is selected and SwatchPalette is closed.
            colorPicker.addEventListener(Event.CLOSE, cpCloseHandler);
        }
        
        /* Disable LEFT and RIGHT arrowkeys when ColorPicker SwatchPalette is open. */
        private function cpOpenHandler(event:Event):void {
            this.arrowKeysEnabled = false;
        }
        
        /* By setting the focus back to the stage, we get around the problem that 
        ColorPicker continues to pass keyDown events to its SwatchPalette even when
        the palette is hidden. */
        private function cpCloseHandler(event:Event):void {
            this.arrowKeysEnabled = true;
            fm.setFocus(this.stage);
        }
        
        /*
        Create a sprite which will snap to the mouse cursor when loop
        or crossover tools are enabled.
        */
        private function setupMouseOverSprites():void {
            // DropShadowFilter params: dist, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject
            var filter:DropShadowFilter = new DropShadowFilter(8,290,0,0.5,6,8,1,1,false,false,false);
            // set up hoverBox
            this.hoverBox = new Sprite();
            this.hoverBox.graphics.lineStyle(0.25, 0xcc0000);
            this.hoverBox.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.hoverBox.visible = false;
            this.pathPanel.canvas.addChild(this.hoverBox);
            // draw a loop within hoverBox
            this.hoverLoop = new Sprite();
            this.hoverLoop.graphics.lineStyle(1, 0x0066cc);
            this.hoverLoop.graphics.moveTo(halfbaseWidth,halfbaseWidth);
            this.hoverLoop.graphics.curveTo(-halfbaseWidth,-baseWidth,halfbaseWidth,-baseWidth);
            this.hoverLoop.graphics.curveTo(1.5*baseWidth,-baseWidth,halfbaseWidth,halfbaseWidth);
            this.hoverLoop.filters = new Array(filter);
            this.hoverLoop.visible = false;
            this.hoverBox.addChild(this.hoverLoop);
            // draw a red X within hoverBox
            this.hoverSkip = new Sprite();
            this.hoverSkip.graphics.lineStyle(2, 0xcc0000);
            this.hoverSkip.graphics.moveTo(0,0);
            this.hoverSkip.graphics.lineTo(baseWidth,baseWidth);
            this.hoverSkip.graphics.moveTo(baseWidth,0);
            this.hoverSkip.graphics.lineTo(0,baseWidth);
            this.hoverSkip.filters = new Array(filter);
            this.hoverSkip.visible = false;
            this.hoverBox.addChild(this.hoverSkip);
            // draw a semi-transparent red box
            this.redBox = new Sprite();
            this.redBox.graphics.lineStyle(1, 0xcc0000);
            this.redBox.graphics.beginFill(0xcc0000, 0.6);
            this.redBox.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.redBox.graphics.endFill();
            this.redBox.visible = false;
            this.hoverBox.addChild(this.redBox);
            // set up crossoverBox
            this.xoBox = new Sprite();
            this.xoBox.graphics.lineStyle(0.25, 0xcc0000);
            this.xoBox.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.xoBox.visible = false;
            this.pathPanel.canvas.addChild(this.xoBox);
            // draw same half-crossover within xoBox
            this.xoSprite = new Sprite();
            this.xoSprite.graphics.lineStyle(1, 0x00cc00);
            this.xoSprite.graphics.beginFill(0x00cc00, 0.6);
            this.xoSprite.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.xoSprite.graphics.endFill();
            this.xoBox.addChild(this.xoSprite);
        }
        
        
        private function setupAlertBoxSprites():void {
            // Loop Tool
            loopAlertSprite = new Sprite();
            nsLabel = new Label();
            loopAlertSprite.addChild(nsLabel);
            nsLabel.text = "scaffold loop length";
            nsLabel.autoSize = TextFieldAutoSize.LEFT;
            numericStepper = new NumericStepper();
            numericStepper.stepSize = 1;
            numericStepper.minimum = 1;
            numericStepper.maximum = 9999;
            // HACK: Fix the height of the TextField (aka I hate components)
            var tInput:TextInput = numericStepper.getChildAt(2) as TextInput;
            tInput.textField.height = 22;
            tInput.textField.width = 54;
            numericStepper.width = 54;
            loopAlertSprite.addChild(numericStepper);
            numericStepper.x = 110;
            
            // Staple Data Grid
            stapleDataGridSprite = new Sprite();
            stapleDataGrid = new DataGrid();
            stapleDataGrid.width = 400;
            stapleDataGrid.rowCount = 10;
            stapleDataGrid.columns = ["Start", "End", "Sequence", "Length", "Color"];
            stapleDataGrid.columns[0].width = 50;
            stapleDataGrid.columns[1].width = 50;
            stapleDataGrid.columns[3].width = 50;
            stapleDataGrid.columns[4].width = 60;
            stapleDataGridSprite.addChild(stapleDataGrid);
            
            // Custom sequence input
            customScaffoldSprite = new Sprite(); 
            this.customScaffoldInput = new TextArea();
            this.customScaffoldInput.maxChars = 20000;
            this.customScaffoldInput.width = 600;
            this.customScaffoldInput.height = 600;
            this.customScaffoldInput.textField.width = 600;
            this.customScaffoldInput.textField.height = 600;
            var tf:TextFormat = new TextFormat();
            tf.align = "left";
            tf.font = "Courier";
            tf.size = 10;
            this.customScaffoldInput.textField.setTextFormat(tf);
            this.customScaffoldSprite.addChild(customScaffoldInput);
        }
        
        /*
        Used to align PathTools after resize
        */
        public function update():void {
            this.x = this.pathPanel.leftX;
        }
        
        private function loadBitMaps():void {
            autoStapleTool.addChild(mainLoader.getBitmap("icons/path-autostaple.png"));
            breakTool.addChild(mainLoader.getBitmap("icons/path-break.png"));
            crossoverTool.addChild(mainLoader.getBitmap("icons/path-force-xover.png"));
            editTool.addChild(mainLoader.getBitmap("icons/path-edit.png"));
            eraseTool.addChild(mainLoader.getBitmap("icons/path-erase.png"));
            loopTool.addChild(mainLoader.getBitmap("icons/path-loop.png"));
            moveCursor.addChild(mainLoader.getBitmap("icons/path-transform-cursor.png"));
            moveTool.addChild(mainLoader.getBitmap("icons/path-transform.png"));
            sequenceTool.addChild(mainLoader.getBitmap("icons/path-sequence.png"));
            skipTool.addChild(mainLoader.getBitmap("icons/path-skip.png"));
            svgTool.addChild(mainLoader.getBitmap("icons/path-svg.png"));
            zoomInCursor.addChild(mainLoader.getBitmap("icons/path-zoomin.png"));
            zoomOutCursor.addChild(mainLoader.getBitmap("icons/path-zoomout.png"));
            zoomTool.addChild(mainLoader.getBitmap("icons/path-zoom.png"));
        }
        
        /*
        Add button as child of display object, set its x coordinate
        and add hover and unhover listeners.
        */
        private function setupButton(button:*, index:int, array:Array):void {
            button.x = index*40; // x position of button
            this.addChild(button);
            button.addEventListener(MouseEvent.MOUSE_OVER, hover);
            button.addEventListener(MouseEvent.MOUSE_OUT, unhover);
        }
        
        /*
        Add button as child of display object, set its x and y coordinates
        and add hover and unhover listeners.
        
        Advanced buttons go in a second row.
        */
        private function setupAdvButton(button:*, index:int, array:Array):void {
            button.x = index*40; // x position of button
            button.y = 70;
            this.addChild(button);
            button.addEventListener(MouseEvent.MOUSE_OVER, hover);
            button.addEventListener(MouseEvent.MOUSE_OUT, unhover);
        }
        
        private function onKeyDown(event:KeyboardEvent):void {
            if (!toolKeysEnabled) {
                return;
            }
            try {
                switch (event.keyCode) {
                    case 37: // left
                        if (arrowKeysEnabled) {
                            this.pathPanel.canvas.x += 210;
                            this.pathPanel.canvascp.x -= 210;
                        }
                        break;
                    case 38: // up
                        if (arrowKeysEnabled) {
                            this.pathPanel.canvas.y += 100;
                            this.pathPanel.canvascp.y -= 100;
                        }
                        break;
                    case 39: // right
                        if (arrowKeysEnabled) {
                            this.pathPanel.canvas.x -= 210;
                            this.pathPanel.canvascp.x += 210;
                        }
                        break;
                    case 40: // down
                        if (arrowKeysEnabled) {
                            this.pathPanel.canvas.y -= 100;
                            this.pathPanel.canvascp.y += 100;
                        }
                        break;
                    case 86: // v
                        if (!editTool.enabled) {
                            this.switchActiveTool(this.editTool, false);
                        }
                        break;
                    case 66: // b
                        if (!breakTool.enabled) {
                            this.switchActiveTool(this.breakTool);
                        }
                        break;
                    case 77: // m
                        if (!moveTool.enabled) {
                            this.switchActiveTool(this.moveTool);
                        }
                        break;
                    case 90: // z
                        if (!zoomTool.enabled) {
                            this.switchActiveTool(this.zoomTool);
                        }
                        break;
                    case 69: // e
                        if (!eraseTool.enabled) {
                            this.switchActiveTool(this.eraseTool);
                        }
                        break;
                    case 80: // p
                        if (!paintTool.enabled) {
                            this.switchActiveTool(this.paintTool);
                        } else {
                            var i:int = colorPicker.colors.indexOf(colorPicker.selectedColor) + 1;
                            i = i % colorPicker.colors.length;
                            colorPicker.selectedColor = colorPicker.colors[i];
                        }
                        break;
                    case 70: // f
                        if (!crossoverTool.enabled) {
                            this.switchActiveTool(this.crossoverTool);
                        }
                        break;
                    case 76: // l
                        if (!loopTool.enabled) {
                            this.switchActiveTool(this.loopTool);
                        }
                        break;
                    case 83: // s
                        if (!skipTool.enabled) {
                            this.switchActiveTool(this.skipTool);
                        }
                        break;
                }
            } catch(event:Error) {
                // trace("keyDown error");
            }
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
                point = DisplayObjectUtil.localToLocal(localpoint, this.pathPanel.mouseLayer, this);
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
                point = DisplayObjectUtil.localToLocal(localpoint, this.pathPanel.mouseLayer, this);
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
        within the pathPanel using the new x,y coordinates that correspond
        to the area where the mouse was clicked before resizing.
        
        I do this by calculating the clicked x,y coordinates as fractions
        of the original width and height, and then using those fractions
        to calculate corresponding x,y coordinates on the re-scaled canvas.
        */
        private function mouseClickHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            
            var preC:Rectangle; // canvas bounds before resizing
            // get initial size of canvas before resize
            preC = this.pathPanel.canvas.getRect(this.pathPanel.canvas);
            
            var canvascp = new Point((preC.right-preC.left)*0.5, (preC.bottom-preC.top)*0.5);
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            point = this.pathPanel.canvas.globalToLocal(localpoint);
            
            var delta:Number;
            if (zoomTool.enabled) {
                if (event.shiftKey) { // zoom out 
                        if (this.pathPanel.canvas.scaleX > 0.5) {
                            delta = -0.5; // zoom quickly
                        } else if (this.pathPanel.canvas.scaleX > 0.1) {
                            delta = -0.1; // zoom slowly
                        }
                } else { // zoom in
                    if (this.pathPanel.canvas.scaleX < 0.5) {
                        delta = 0.1; // zoom slowly
                    } else {
                        delta = 0.5; // zoom quickly
                    }
                }
                
                if (NumberUtil.roundToPrecision(this.pathPanel.canvas.scaleX + delta,1) > 0) {
                    DynamicRegistration.scale(this.pathPanel.canvas, canvascp,
                        NumberUtil.roundToPrecision(this.pathPanel.canvas.scaleX + delta,1),
                        NumberUtil.roundToPrecision(this.pathPanel.canvas.scaleY + delta,1));
                    this.pathPanel.centerCanvas(point.x, point.y);
                }
            }
        }
        
        /* 
        Handle initial mouse entry onto pathPanel.  vis default cursor,
        listen for mouse_move events.
        */
        private function mouseOverHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            this.addMouseLayerListeners();
        }
        
        /*
        Start dragging the path canvas on MOUSE_DOWN event.
        */
        private function mouseDownHandler(event:MouseEvent):void {
            this.pathPanel.canvas.startDrag();
            this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /*
        Stop dragging the path canvas on MOUSE_UP event.
        */
        private function mouseUpHandler(event:MouseEvent):void {
            this.pathPanel.canvas.stopDrag();
            // set new canvas center point
            this.pathPanel.canvascp = DisplayObjectUtil.localToLocal(this.pathPanel.center,this.pathPanel,this.pathPanel.canvas);
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /* 
        Handle mouse exit from pathPanel.  Restore default cursor,
        stop listening for mouse_move events.  hide custom cursors.
        */
        private function mouseOutHandler(event:MouseEvent):void {
            Mouse.show();
            zoomInCursor.visible = false;
            zoomOutCursor.visible = false;
            moveCursor.visible = false;
            this.removeMouseLayerListeners();
        }
        
        /*
        Adjust button appearance when active
        */
        private function hover(event:MouseEvent):void {
            var g:Graphics;
            if (event.target is ToolButton) {
                g = event.target.graphics;
            } else if (event.target is BaseButton) { // stupid hack to handle ColorPicker
                g = event.target.parent.parent.graphics;
            } else {
                return;
            }
            g.beginFill(0x99ccff, 0);
            g.lineStyle(1, 0x0066cc, 1, true);
            g.drawRect(0,0,32,32);
            g.endFill();
        }
        
        /*
        Restore button appearance when mouse leaves
        */
        private function unhover(event:MouseEvent):void {
            if (!event.target.enabled) {
                event.target.graphics.clear();
            }
        }
        
        private function switchActiveTool(target:ToolButton, enableMouseLayer:Boolean=true):void {
            var index:int;
            var tb:ToolButton;
            var g:Graphics = target.graphics;
            var buttons:Array = new Array(editTool, zoomTool, moveTool, breakTool, 
                                          eraseTool, autoStapleTool, sequenceTool, 
                                          crossoverTool, loopTool, skipTool, paintTool);
            
            this.removeMouseLayerListeners();
            
            for each(tb in buttons) {
                if (tb.enabled) {
                    tb.enabled = false;
                    tb.graphics.clear();
                    if (tb.name == "move") {
                        this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                    }
                }
            }
            
            if (enableMouseLayer) {
                this.pathPanel.mouseLayer.visible = true;
            } else {
                this.pathPanel.mouseLayer.visible = false;
            }
            
            // highlight active tool button
            target.enabled = true;
            g.beginFill(0x99ccff, 0.5);
            g.lineStyle(1, 0x0066cc, 1, true);
            g.drawRect(0,0,32,32);
            g.endFill();
            
            // update mouse indicators
            this.redBox.visible = false;
            this.xoBox.visible = false;
            this.hoverLoop.visible = false;
            this.hoverSkip.visible = false;
            
            if (!this.pathPanel.mouseLayer.hasEventListener(MouseEvent.MOUSE_MOVE)) {
                this.addMouseLayerListeners();
            } 
        }
        
        
        private function addMouseLayerListeners():void {
            if (zoomTool.enabled || moveTool.enabled) {
                Mouse.hide();
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.CLICK, mouseClickHandler);
                
                if (moveTool.enabled) {
                    this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                } 
            } else if (breakTool.enabled) {
                this.hoverBox.visible = true;
                this.redBox.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, breakDownHandler);
            } else if (eraseTool.enabled) {
                this.hoverBox.visible = true;
                this.redBox.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, eraseDownHandler);
            } else if (sequenceTool.enabled) {
                this.hoverBox.visible = true;
                this.redBox.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, sequenceDownHandler);
            } else if (loopTool.enabled) {
                this.hoverBox.visible = true;
                this.hoverLoop.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, loopDownHandler);
            } else if (skipTool.enabled) {
                this.hoverBox.visible = true;
                this.hoverSkip.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, skipDownHandler);
            } else if (crossoverTool.enabled) {
                this.hoverBox.visible = true;
                this.redBox.visible = true;
                if (vs1 != null) {xoBox.visible = true;} // show first click position again
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, crossoverDownHandler);
                //resetCrossoverTool(); // leave on for drawing distant crossovers
            } else if (paintTool.enabled) {
                this.hoverBox.visible = true;
                this.redBox.visible = true;
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, paintDownHandler);
            } else {
                //Mouse.show();
            }
        }
        
        private function removeMouseLayerListeners():void {
            if (zoomTool.enabled || moveTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.CLICK, mouseClickHandler);
                
                if (moveTool.enabled) {
                     this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                     moveCursor.visible = false;
                } else {
                    zoomInCursor.visible = false;
                    zoomOutCursor.visible = false;
                }
                Mouse.show();
            }
            if (sequenceTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, sequenceDownHandler);
            } else if (paintTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, paintDownHandler);
            } else if (breakTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, breakDownHandler);
            } else if (eraseTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, eraseDownHandler);
            } else if (crossoverTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, crossoverDownHandler);
            } else if (loopTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, loopDownHandler);
            } else if (skipTool.enabled) {
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, hoverMoveHandler);
                this.pathPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, skipDownHandler);
            }
            
            this.hoverBox.visible = false;
        }
        
        /*
        Default edit mode
        */
        private function editToolAction(event:MouseEvent):void {
            if (!editTool.enabled) {
                this.switchActiveTool(editTool, false);
                this.pathPanel.mouseLayer.visible = false;
            }
        }
        
        /*
        Enable zoom and disable others when zoom button is clicked
        */
        private function zoomToolAction(event:MouseEvent):void {
            if (!zoomTool.enabled) {
                this.switchActiveTool(zoomTool);
            }
        }
        
        /*
        Enable move and disable others when move button is clicked
        */
        private function moveToolAction(event:MouseEvent):void {
            if (!moveTool.enabled) {
                this.switchActiveTool(moveTool);
            }
        }
        
        /*
        Breakpoint Tool
        */
        private function breakToolAction(event:MouseEvent):void {
            if (!breakTool.enabled) {
                this.switchActiveTool(breakTool);
            }
        }
        
        /*
        Erase Tool
        */
        private function eraseToolAction(event:MouseEvent):void {
            if (!eraseTool.enabled) {
                this.switchActiveTool(eraseTool);
            }
        }
        
        private function svgToolAction(event:MouseEvent):void {
            svg.writeFullSVGOutput();
        }
        
        /*
        Auto-generate staples.
        */
        private function autoStapleToolAction(event:MouseEvent):void {
            // do not prompt if 1st use of tool or never loaded external data.
            if (firstautostaple && !this.drawPath.path.loadedData) {
                this.drawPath.allowRefresh = false;
                var vs:Vstrand;
                var vsIter:DListIterator = this.drawPath.path.vsList.getListIterator();
                // loop through each vstrand
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    vs = vsIter.node.data;
                    vs.autoStaple();
                    vs.drawVstrand.addStapBreakpoints();
                }
                
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    this.drawPath.makeActive(vsIter.node.data);
                    this.drawPath.stapAutoXO();
                }
                
                // add color
                this.drawPath.stapAutoColor();
                this.drawPath.allowRefresh = true;
                this.drawPath.updateStap();
                this.drawPath.purgePreXOPool();
            } else {
                var buttons:Array = new Array("Confirm", "Cancel");
                var msg:String;
                msg = "Warning: all existing staple strands will be overwritten.";
                AlertManager.createAlert(this.parent.parent, 
                                        msg,
                                        "Auto-generate staples", 
                                        buttons,
                                        autoStapleHandler, 
                                        null, 
                                        true, 
                                        {textColor:0x000000}, 
                                        TextFieldType.DYNAMIC);
            }
            firstautostaple = false;
        }
        
        private function autoStapleHandler(event:Event):void {
            var vs:Vstrand;
            var vsIter:DListIterator = this.drawPath.path.vsList.getListIterator();
            if (event.target.name == "Confirm") {
                this.drawPath.allowRefresh = false;
                // add edge breakpoints
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    vs = vsIter.node.data;
                    vs.autoStaple();
                    vs.drawVstrand.addStapBreakpoints();
                }
                
                // install crossovers
                for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                    this.drawPath.makeActive(vsIter.node.data);
                    this.drawPath.stapAutoXO();
                }
                
                // add color
                this.drawPath.stapAutoColor();
                this.drawPath.allowRefresh = true;
                this.drawPath.updateStap();
                this.drawPath.purgePreXOPool();
            } else if (event.target.name == "Cancel") {
                // do nothing
            }
        }
        
        /*
        Sequence population mode
        */
        private function sequenceToolAction(event:MouseEvent):void {
            if (!sequenceTool.enabled) {
                this.switchActiveTool(sequenceTool);
            }
        }
        
        /*
        loop drawing mode
        */
        private function loopToolAction(event:MouseEvent):void {
            if (!loopTool.enabled) {
                this.switchActiveTool(loopTool);
                this.hoverLoop.visible = true;  // show mouse position indicator
            }
        }
        
        /*
        Skip drawing mode
        */
        private function skipToolAction(event:MouseEvent):void {
            if (!skipTool.enabled) {
                this.switchActiveTool(skipTool);
                this.hoverSkip.visible = true;  // show mouse position indicator
            }
        }
        
        /*
        Crossover drawing mode
        */
        private function crossoverToolAction(event:MouseEvent):void {
            if (!crossoverTool.enabled) {
                this.switchActiveTool(crossoverTool);
            }
        }
        
        private function paintToolAction(event:MouseEvent):void {
            if (!paintTool.enabled) {
                this.switchActiveTool(paintTool);
            }
        }
        
        /* Called by several of the mouse_down handlers to get a reference
           to the vstrand that was clicked. */
        private function getClickedVstrand(gridY:int):Vstrand {
            var vs:Vstrand;
            var vsIndex:int;
            var vsIter:DListIterator;
            var vsCount:int = this.drawPath.path.vsList.size;
            
            // convert mouseY to vstrand index
            if (gridY % 5 == 0) {
                vsIndex = gridY / 5;
            } else if ((gridY-1) % 5 == 0) {
                vsIndex = (gridY-1) / 5;
            }
            
            if (vsIndex < vsCount) {
                vsIter = this.drawPath.path.vsList.getListIterator();
                for (var i:int = 0; i < vsIndex; i++) {
                    vsIter.forth(); // advance to clicked vstrand
                }
                return vsIter.node.data;
            } else {
                return null;
            }
        }
        
        /* Create breakpoint where clicked */
        private function breakDownHandler(event:MouseEvent):void {
            var vs:Vstrand;
            var gridY,vsIndex,pos:int;
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            var point:Point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 1) {return;} // need to be able to check pos-1
            vs = getClickedVstrand(gridY);
            
            if (vs != null) {
                if (pos == vs.scaf.length-1) {return;} // need to be able to check pos+1
                if (gridY % 5 == 0) { // look for scaffold on even strand or staple on odd strand
                    if (vs.number % 2 == 0) { // check for scaffold
                        if ( vs.hasScaf(pos) &&
                            !vs.hasScafXover(pos) && !vs.hasScafXover(pos+1) && 
                            !vs.isScaf5PrimeEnd(pos) && !vs.isScaf5PrimeEnd(pos+1) &&
                            !vs.isScaf3PrimeEnd(pos) && !vs.isScaf3PrimeEnd(pos+1)) {
                            vs.scaf[pos].clearNext();
                            vs.scaf[int(pos+1)].clearPrev();
                            vs.drawVstrand.updateScaf();
                        }
                    } else { // check for staple
                        if ( vs.hasStap(pos) &&
                            !vs.hasStapXover(pos) && !vs.hasStapXover(pos+1) && 
                            !vs.isStap5PrimeEnd(pos) && !vs.isStap5PrimeEnd(pos+1) &&
                            !vs.isStap3PrimeEnd(pos) && !vs.isStap3PrimeEnd(pos+1)) {
                            vs.stap[pos].clearNext();
                            vs.stap[int(pos+1)].clearPrev();
                            this.drawPath.updateStapleColor(vs,pos,vs.stap[pos].color);
                            this.drawPath.updateStapleColor(vs,pos+1);
                            this.drawPath.updateStap(true);
                        }
                    }
                } else if ((gridY-1) % 5 == 0) { // look for scaffold on odd strand or staple on even strand
                    if (vs.number % 2 == 1) { // check for scaffold
                        if ( vs.hasScaf(pos) &&
                            !vs.hasScafXover(pos) && !vs.hasScafXover(pos-1) && 
                            !vs.isScaf5PrimeEnd(pos) && !vs.isScaf5PrimeEnd(pos-1) &&
                            !vs.isScaf3PrimeEnd(pos) && !vs.isScaf3PrimeEnd(pos-1)) {
                            vs.scaf[pos].clearNext();
                            vs.scaf[int(pos-1)].clearPrev();
                            vs.drawVstrand.updateScaf();
                        }
                    } else { // check for staple
                        if ( vs.hasStap(pos) &&
                            !vs.hasStapXover(pos) && !vs.hasStapXover(pos-1) && 
                            !vs.isStap5PrimeEnd(pos) && !vs.isStap5PrimeEnd(pos-1) &&
                            !vs.isStap3PrimeEnd(pos) && !vs.isStap3PrimeEnd(pos-1)) {
                            vs.stap[pos].clearNext();
                            vs.stap[int(pos-1)].clearPrev();
                            this.drawPath.updateStapleColor(vs,pos,vs.stap[pos].color);
                            this.drawPath.updateStapleColor(vs,pos-1);
                            this.drawPath.updateStap(true);
                        }
                    }
                }
            }
        }
        
        /* Remove scaffold or staple path until break or crossover is reached. */
        private function eraseDownHandler(event:MouseEvent):void {
            var vs:Vstrand;
            var gridY,vsIndex,pos, i:int;
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            var point:Point = this.pathPanel.canvas.globalToLocal(localpoint);
            var done:Boolean;
            var xo,xo2:CrossoverHandle;
            
            // snap hoverBox to grid
            this.hoverBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
            this.hoverBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 0) {return;} // need to be able to check pos-1
            vs = getClickedVstrand(gridY);
            
            if (vs != null) {
                if (pos == vs.scaf.length-1) {return;} // need to be able to check pos+1
                if (gridY % 5 == 0) { // look for scaffold on even strand or staple on odd strand
                    if (vs.number % 2 == 0) { // check for scaffold
                        done = false;
                        i = pos;
                        while (!done) { // EVEN SCAF RIGHT-->
                            if (vs.scafHasNextToken(i)) {
                                if (vs.hasScafXover(i,false,true)) { // check only for 3' crossover
                                    xo = vs.drawVstrand.getScafCrossoverAtPos(i);
                                    vs.scaf[i].clearNext();
                                    xo.neighbor.vstrand.scaf[xo.neighbor.pos].clearPrev();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateScaf();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.scaf[i].clearNext();
                                    vs.scaf[int(i+1)].clearPrev();
                                    i += 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        done = false;
                        i = pos;
                        while (!done) { // EVEN SCAF LEFT <--
                            if (vs.scafHasPrevToken(i)) {
                                if (vs.hasScafXover(i,true,false)) { // check only for 5' crossover
                                    xo = vs.drawVstrand.getScafCrossoverAtPos(i);
                                    vs.scaf[i].clearPrev();
                                    xo.neighbor.vstrand.scaf[xo.neighbor.pos].clearNext();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateScaf();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.scaf[i].clearPrev();
                                    vs.scaf[int(i-1)].clearNext();
                                    i -= 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        vs.drawVstrand.updateScaf();
                        this.drawPath.makeActive(vs,pos);
                    } else { // check for staple
                        done = false;
                        i = pos;
                        while (!done) { // ODD STAP RIGHT -->
                            if (vs.stapHasNextToken(i)) {
                                // check for crossover
                                if (vs.hasStapXover(i,false,true)) {
                                    xo = vs.drawVstrand.getStapCrossoverAtPos(i);
                                    vs.stap[i].clearNext();
                                    xo.neighbor.vstrand.stap[xo.neighbor.pos].clearPrev();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateStap();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.stap[i].clearNext();
                                    vs.stap[int(i+1)].clearPrev();
                                    i += 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        done = false;
                        i = pos;
                        while (!done) { // ODD STAP LEFT <--
                            if (vs.stapHasPrevToken(i)) {
                                // check for crossover
                                if (vs.hasStapXover(i,true,false)) {
                                    xo = vs.drawVstrand.getStapCrossoverAtPos(i);
                                    vs.stap[i].clearPrev();
                                    xo.neighbor.vstrand.stap[xo.neighbor.pos].clearNext();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateStap();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.stap[i].clearPrev();
                                    vs.stap[int(i-1)].clearNext();
                                    i -= 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        vs.drawVstrand.updateStap();
                        this.drawPath.makeActive(vs,pos);
                    }
                } else if ((gridY-1) % 5 == 0) { // look for scaffold on odd strand or staple on even strand
                    if (vs.number % 2 == 1) { // check for scaffold
                        done = false;
                        i = pos;
                        while (!done) {  // ODD SCAF LEFT <-- (3' direction)
                            if (vs.scafHasNextToken(i)) {
                                // check for crossover
                                if (vs.hasScafXover(i,false,true)) {
                                    xo = vs.drawVstrand.getScafCrossoverAtPos(i);
                                    vs.scaf[i].clearNext();
                                    xo.neighbor.vstrand.scaf[xo.neighbor.pos].clearPrev();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateScaf();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.scaf[i].clearNext();
                                    vs.scaf[int(i-1)].clearPrev();
                                    i -= 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        done = false;
                        i = pos;
                        while (!done) { // ODD SCAF RIGHT --> (5' direction)
                            if (vs.scafHasPrevToken(i)) {
                                // check for crossover
                                if (vs.hasScafXover(i,true,false)) {
                                    xo = vs.drawVstrand.getScafCrossoverAtPos(i);
                                    vs.scaf[i].clearPrev();
                                    xo.neighbor.vstrand.scaf[xo.neighbor.pos].clearNext();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateScaf();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.scaf[i].clearPrev();
                                    vs.scaf[int(i+1)].clearNext();
                                    i += 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        vs.drawVstrand.updateScaf();
                        this.drawPath.makeActive(vs,pos);
                    } else { // check for staple
                        done = false;
                        i = pos;
                        while (!done) { // EVEN STAP LEFT <-- (3' direction)
                            if (vs.stapHasNextToken(i)) {
                                // check for crossover
                                if (vs.hasStapXover(i,false,true)) {
                                    xo = vs.drawVstrand.getStapCrossoverAtPos(i);
                                    vs.stap[i].clearNext();
                                    xo.neighbor.vstrand.stap[xo.neighbor.pos].clearPrev();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateStap();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.stap[i].clearNext();
                                    vs.stap[int(i-1)].clearPrev();
                                    i -= 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        done = false;
                        i = pos;
                        while (!done) { // EVEN STAP RIGHT --> (5' direction)
                            if (vs.stapHasPrevToken(i)) {
                                // check for crossover
                                if (vs.hasStapXover(i,true,false)) {
                                    xo = vs.drawVstrand.getStapCrossoverAtPos(i);
                                    vs.stap[i].clearPrev();
                                    xo.neighbor.vstrand.stap[xo.neighbor.pos].clearNext();
                                    xo.neighbor.vstrand.drawVstrand.removeCrossover(xo.neighbor);
                                    if (xo.vstrand.number != xo.neighbor.vstrand.number) {
                                        xo.neighbor.vstrand.drawVstrand.updateStap();
                                    }
                                    vs.drawVstrand.removeCrossover(xo);
                                    done = true;
                                } else {
                                    vs.stap[i].clearPrev();
                                    vs.stap[int(i+1)].clearNext();
                                    i = i + 1;
                                }
                            } else {
                                done = true;
                            }
                        }
                        vs.drawVstrand.updateStap();
                        this.drawPath.makeActive(vs,pos);
                    }
                }
            }
        }
        
        /*
        Populate scaffold sequence if 5' end was clicked.
        */
        private function sequenceDownHandler(event:MouseEvent):void {
            var gridY,vsNumber,pos:int;
            var vs:Vstrand;
            var vsIter:DListIterator;
            var buttons:Array = new Array("M13mp18", "p7308", "p7560", "p7704", "p8064", "p8634", "pEGFP", "Custom", "Cancel");
            var msg:String;
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            var point:Point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 0) {return;}
            vs = getClickedVstrand(gridY);
            vsNumber = vs.number;
            
            // convert mouseY to vstrand index
            if (gridY % 5 == 0) { // look for scaffold on even strand
                if (vs.number % 2 == 0) { // this is an even strand
                    if (vs.isScaf5PrimeEnd(pos)) {
                        seqCoord.x = pos;
                        seqCoord.y = vsNumber;
                        msg = "Choose a scaffold to apply at " + 
                              vs.number + "[" + seqCoord.x + "]";
                        AlertManager.createAlert(this.parent.parent, 
                                                 msg,
                                                 "Populate scaffold sequence", 
                                                 buttons,
                                                 sequenceClickHandler, 
                                                 null, 
                                                 true, 
                                                 {textColor:0x000000}, 
                                                 TextFieldType.DYNAMIC);
                    }
                }
            } else if ((gridY-1) % 5 == 0) { // look for scaffold on even strand
                if (vs.number % 2 == 1) { // this is an odd strand
                    if (vs.isScaf5PrimeEnd(pos)) {
                        seqCoord.x = pos;
                        seqCoord.y = vsNumber;
                        msg = "Choose a scaffold to apply at " + 
                              vs.number + "[" + seqCoord.x + "]";
                        AlertManager.createAlert(this.parent.parent, 
                                                 msg,
                                                 "Populate scaffold sequence", 
                                                 buttons,
                                                 sequenceClickHandler, 
                                                 null, 
                                                 true, 
                                                 {textColor:0x000000}, 
                                                 TextFieldType.DYNAMIC);
                    }
                }
            }
        }
        
        /*
        By this point, user has clicked in a legal position to add a sequence,
        whose coordinates were recorded in sequenceDownHandler().
        
        If user clicks anything other than "Cancel", then install the sequence.
        */
        private function sequenceClickHandler(event:Event):void {
            var i:int;
            var vsIter:DListIterator;
            var seq, msg:String;
            
            if (event.target.name == "Cancel") {
                return;
            } 
            
            if (event.target.name == "p7308") {
                seq = Sequence.p7308;
            } else if (event.target.name == "p7560") {
                seq = Sequence.p7560;
            } else if (event.target.name == "p7704") {
                seq = Sequence.p7704;
            } else if (event.target.name == "p8064") {
                seq = Sequence.p8064;
            } else if (event.target.name == "p8064") {
                seq = Sequence.p8064;
            } else if (event.target.name == "p8634") {
                seq = Sequence.p8634;
            } else if (event.target.name == "M13mp18") {
                seq = Sequence.M13mp18;
            } else if (event.target.name == "pEGFP") {
                seq = Sequence.pEGFP;
            } else if (event.target.name == "Custom") {  // new alert with textbox
                this.toolKeysEnabled = false;
                AlertManager.createAlert(this.parent,
                                         "[ACGTacgt] only, 20kb max.",
                                         "Enter custom scaffold sequence",
                                         ["OK", "Cancel"],
                                         customScaffoldHandler,
                                         null,
                                         true,
                                         {textColor:0x000000},
                                         TextFieldType.DYNAMIC,
                                         customScaffoldSprite);
                return;
            } else {
                return;  // just in case of unaccounted buttons
            }
            
            var result:Array;
            result = drawPath.populateScaffold(seqCoord.y, seqCoord.x, seq);
            if (result == null) {
                displayErrorAlert("Not enough bases in " + event.target.name + " to populate this scaffold path.");
            } else {
                this.displayStapleSequences(result);
            }
        }
        
        private function displayErrorAlert(msg:String):void {
                AlertManager.createAlert(this.parent.parent, 
                                         msg, 
                                         "ERROR", 
                                         ["OK"],
                                         stapleGridHandler,
                                         null, 
                                         true, 
                                         {textColor:0x000000},
                                         TextFieldType.DYNAMIC);
        }
        
        private function displayStapleSequences(result:Array):void {
            // create alert to display sequences
            stapleDataGrid.dataProvider = new DataProvider(result);
            var msg:String = "Scaffold bases applied:" + 
                              drawPath.scafBasesAdded + 
                              "\nTotal staple count:" + 
                              stapleDataGrid.dataProvider.length
            AlertManager.createAlert(this.parent.parent, 
                                     msg, 
                                     "Staple Result", 
                                     ["Copy To Clipboard", "Close"],
                                     stapleGridHandler,//createLoopHandler, 
                                     null, 
                                     true, 
                                     {textColor:0x000000},
                                     TextFieldType.DYNAMIC,
                                     stapleDataGridSprite);
        }
        
        private function customScaffoldHandler(event:Event):void {
            this.toolKeysEnabled = true;
            
            if (event.target.name == "Cancel") {
                this.customScaffoldInput.text = "";
                return;
            }
            
            var re:RegExp = /![ACGTacgt]|\s/; // split on anything other than ACGTacgt
            var splitresult:Array = this.customScaffoldInput.text.split(re);
            if (splitresult.length != 1) {
                displayErrorAlert("Sequence can only contain DNA base letters [ACGTacgt]. Remove other characters and/or whitespace and try again." );
                this.customScaffoldInput.text = "";
            } else {
                var result:Array;
                result = drawPath.populateScaffold(seqCoord.y, seqCoord.x, this.customScaffoldInput.text);
                if (result == null) {
                    displayErrorAlert("Not enough bases in " + event.target.name + " to populate this scaffold path.");
                } else {
                    this.displayStapleSequences(result);
                }
            }
        }
        
        /* Extract datagrid data and copy to clipboard after displayed. */
        public function stapleGridHandler(event:Event):void {
            var clip:String = "Start\tEnd\tSequence\tLength\tColor\n";
            var dp:DataProvider = stapleDataGrid.dataProvider;
            var row:Object;
            if (event.target.name == "Copy To Clipboard") {
                // loop through DataGrid
                var s:String;
                for (var i:int = 0; i < dp.length; i++ ) {
                    row = dp.getItemAt(i);
                    clip += row["Start"] + "\t" + row["End"] + "\t" + 
                            row["Sequence"] + "\t" + row["Length"] + "\t" + 
                            row["Color"] + "\n";
                }
                System.setClipboard(clip);
            } else if (event.target.name == "Close") {
                // do nothing
                // trace("action canceled");
            }
        }
        
        /*
        Add scaffold loop if possible.
        
        Converting mouse coords to strand positions is a little messy, 
        moreso because vstrands can be rearranged.
        
        First use y-coord to find vstrand, then check to see if
        we expect a scaffold strand at that position (since even and odd
        strands are drawn on top and bottom rows, respectively).
        
        If y-coord checks out, examine vstrand for a scaffold 3' pointer 
        based on x-coord.  If that checks out, pop up an alert window to
        prompt for loop length.
        */
        private function loopDownHandler(event:MouseEvent):void {
            var point:Point;
            var gridY,vsIndex,pos:int;
            var vs:Vstrand;
            var buttons:Array = new Array("Save", "Cancel");
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 0) {return;}
            vs = getClickedVstrand(gridY);
            
            // convert mouseY to vstrand index
            if (gridY % 5 == 0) { // look for scaffold on even strand
                vsIndex = gridY / 5;
                if (vs.number % 2 == 0) { // this is an even strand
                    if (vs.scafHasPrevToken(pos)) {
                        loopCoord.x = pos;
                        loopCoord.y = vsIndex;
                        // get loop parameters from user
                        AlertManager.createAlert(this.parent.parent, 
                                                 "Choose loop length", 
                                                 "Create 3' Loop", 
                                                 buttons,
                                                 createLoopHandler, 
                                                 null, 
                                                 true, 
                                                 {textColor:0x000000}, 
                                                 TextFieldType.DYNAMIC,
                                                 loopAlertSprite);
                    }
                }
            } else if ((gridY-1) % 5 == 0) { // look for scaffold on even strand
                vsIndex = (gridY-1) / 5;
                if (vs.number % 2 == 1) { // this is an odd strand
                    if (vs.scafHasPrevToken(pos)) {
                        loopCoord.x = pos;
                        loopCoord.y = vsIndex;
                        // get loop parameters from user
                        AlertManager.createAlert(this.parent.parent, 
                                                 "Choose loop length", 
                                                 "Create 3' Loop", 
                                                 buttons,
                                                 createLoopHandler, 
                                                 null, 
                                                 true, 
                                                 {textColor:0x000000}, 
                                                 TextFieldType.DYNAMIC,
                                                 loopAlertSprite);
                        //this.hoverBox.x = this.hoverBox.y = 0;
                    }
                }
            }
        }
        
        /*
        By this point, user has clicked in a legal position to add a loop,
        whose coordinates were recorded in loopDownHandler().
        
        If user clicks "save", then install the loop.
        */
        private function createLoopHandler(event:Event):void {
            var i:int;
            var vsIter:DListIterator;
            var vs:Vstrand;
            if (event.target.name == "Save") {
                // advance to target vstrand
                vsIter = this.drawPath.path.vsList.getListIterator();
                for (i = 0; i < loopCoord.y; i++) {
                    vsIter.forth();
                }
                vs = vsIter.node.data;
                vs.drawVstrand.addLoopHandle(loopCoord.x,numericStepper.value);
            } else if (event.target.name == "Cancel") {
                // do nothing
                // trace("action canceled");
            }
        }
        
        
        /*
        Add scaffold skip if possible.
        */
        private function skipDownHandler(event:MouseEvent):void {
            var point:Point;
            var gridY,vsIndex,pos:int;
            var vs:Vstrand;
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 0) {return;} // need to be able to check pos-1
            vs = getClickedVstrand(gridY);
            
            // convert mouseY to vstrand index
            if (gridY % 5 == 0) { // look for scaffold on even strand
                vsIndex = gridY / 5;
                if (vs.number % 2 == 0) { // this is an even strand
                    if (vs.scafHasPrevToken(pos)) {
                        vs.drawVstrand.addSkipHandle(pos);
                    }
                }
            } else if ((gridY-1) % 5 == 0) { // look for scaffold on odd strand
                vsIndex = (gridY-1) / 5;
                if (vs.number % 2 == 1) { // this is an odd strand
                    if (vs.scafHasPrevToken(pos)) {
                        vs.drawVstrand.addSkipHandle(pos);
                    }
                }
            }
        }
        
        /* Zero out all crossover tool parameters and coordinates
        when enabling the tool or after using the tool. */
        private function resetCrossoverTool():void {
                vs1 = vs2 = null;
                xoCoord1.x = xoCoord1.y = xoCoord2.x = xoCoord2.y = -1;
                xoBox.visible = false;
                hoverBox.x = hoverBox.y = 0;
        }
        
        /*
        Handle mouse movement in crossover drawing mode.
        */
        private function hoverMoveHandler(event:MouseEvent):void {
                // get mouse coords local to canvas
                localpoint.x = event.stageX;
                localpoint.y = event.stageY;
                point = this.pathPanel.canvas.globalToLocal(localpoint);
                // snap to grid.
                this.hoverBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
                this.hoverBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
        }
        
        /*
        Handle mouse clicks in crossover drawing mode.
        
        If a position has been previously clicked, compare old and new location.
        If parities are different, then install the crossover.
        
        If a position has not been clicked, store new coordinates.
        
        */
        private function crossoverDownHandler(event:MouseEvent):void {
            var point:Point;
            var gridY,vsIndex,pos:int;
            var vs:Vstrand;
            var buttons:Array = new Array("Confirm", "Cancel");
            var msg:String;
            
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 0) {return;} // need to be able to check pos-1
            vs = getClickedVstrand(gridY);
            
            // convert mouseY to vstrand index
            if (gridY % 5 == 0) {
                vsIndex = gridY / 5;
            } else if ((gridY-1) % 5 == 0) {
                vsIndex = (gridY-1) / 5;
            }
            
            if (vs1 == null) {  // first click
                if (gridY % 5 == 0) { // look for scaffold on even strand or staple on odd strand
                    if (vs.number % 2 == 0) { // check for scaffold
                        if (vs.scafHasPrevToken(pos)) {
                            xoType = CrossoverHandle.SCAFFOLD;
                            vs1 = vs;
                            xoCoord1.x = pos;
                            xoCoord1.y = vsIndex;
                            xoBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.visible = true;
                        }
                    } else { // check for staple
                        if (vs.stapHasPrevToken(pos)) {
                            xoType = CrossoverHandle.STAPLE;
                            vs1 = vs;
                            xoCoord1.x = pos;
                            xoCoord1.y = vsIndex;
                            xoBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.visible = true;
                        }
                    }
                } else if ((gridY-1) % 5 == 0) { // look for scaffold on odd strand or staple on even strand
                    if (vs.number % 2 == 1) { // check for scaffold
                        if (vs.scafHasPrevToken(pos)) {
                            xoType = CrossoverHandle.SCAFFOLD;
                            vs1 = vs;
                            xoCoord1.x = pos;
                            xoCoord1.y = vsIndex;
                            xoBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.visible = true;
                        }
                    } else { // check for staple
                        if (vs.stapHasPrevToken(pos)) {
                            xoType = CrossoverHandle.STAPLE;
                            vs1 = vs;
                            xoCoord1.x = pos;
                            xoCoord1.y = vsIndex;
                            xoBox.x = Math.round((point.x-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.y = Math.round((point.y-halfbaseWidth)/baseWidth) * baseWidth;
                            xoBox.visible = true;
                        }
                    }
                }
            } else {  // second click
                vs2 = vs;
                xoCoord2.x = pos;
                xoCoord2.y = vsIndex;
                
                if (xoCoord1.x == xoCoord2.x && xoCoord1.y == xoCoord2.y) {
                    return; // user clicked same spot twice
                }
                
                msg = "Force a crossover from\n" + 
                            vs1.number + "[" + xoCoord1.x + "] to " +
                            vs2.number + "[" + xoCoord2.x + "]?";
                
                if (xoType == CrossoverHandle.SCAFFOLD) {
                    if (gridY % 5 == 0 && vs.number % 2 == 0) { // look for scaffold on even strand 
                        if (vs.scafHasNextToken(pos)) {
                            AlertManager.createAlert(this.parent.parent, msg, "Force Crossover", buttons,
                                                     forceXOClickHandler, null, true, {textColor:0x000000}, 
                                                     TextFieldType.DYNAMIC);
                        }
                    } else if ((gridY-1) % 5 == 0 && vs.number % 2 == 1) { // look for scaffold on odd strand 
                        if (vs.scafHasNextToken(pos)) {
                            AlertManager.createAlert(this.parent.parent, msg, "Force Crossover", buttons,
                                                     forceXOClickHandler, null, true, {textColor:0x000000}, 
                                                     TextFieldType.DYNAMIC);
                        }
                    }
                } else if (xoType == CrossoverHandle.STAPLE) {
                    if (gridY % 5 == 0 && vs.number % 2 == 1) { // look for staple on odd strand
                        if (vs.stapHasNextToken(pos)) {
                            AlertManager.createAlert(this.parent.parent, msg, "Force Crossover", buttons,
                                                     forceXOClickHandler, null, true, {textColor:0x000000}, 
                                                     TextFieldType.DYNAMIC);
                        }
                    } else if ((gridY-1) % 5 == 0 && vs.number % 2 == 0) { // look for staple on even strand
                        if (vs.stapHasNextToken(pos)) {
                            AlertManager.createAlert(this.parent.parent, msg, "Force Crossover", buttons,
                                                     forceXOClickHandler, null, true, {textColor:0x000000}, 
                                                     TextFieldType.DYNAMIC);
                        }
                    }
                }
            }
        }
        
        private function forceXOClickHandler(event:Event):void {
            if (event.target.name == "Confirm") {
                var type1, type2:String;
                var result:int = 0;
                if (xoType == CrossoverHandle.STAPLE) {
                    result = 1;
                }
                if (vs1.number % 2 == result) {
                    type1 = CrossoverHandle.LEFT_UP;
                } else {
                    type1 = CrossoverHandle.RIGHT_DOWN;
                }
                if (vs2.number % 2 == result) {
                    type2 = CrossoverHandle.RIGHT_UP;
                } else {
                    type2 = CrossoverHandle.LEFT_DOWN;
                }
                
                var xo1:CrossoverHandle = new CrossoverHandle(drawPath, vs1, xoType, xoCoord1.x, type1, true);
                var xo2:CrossoverHandle = new CrossoverHandle(drawPath, vs2, xoType, xoCoord2.x, type2, true);
                xo1.neighbor = xo2; // pair crossovers
                xo2.neighbor = xo1;
                
                if (xoType == CrossoverHandle.SCAFFOLD) {
                    if (vs1 == vs2) {
                        vs1.drawVstrand.addScafCrossoverPair(xo1,xo2);
                    } else {
                        vs1.drawVstrand.addScafCrossover(xo1);
                        vs2.drawVstrand.addScafCrossover(xo2);
                    }
                } else if (xoType == CrossoverHandle.STAPLE) {
                    if (vs1 == vs2) {
                        vs1.drawVstrand.addStapCrossoverPair(xo1,xo2);
                    } else {
                        vs1.drawVstrand.addStapCrossover(xo1);
                        vs2.drawVstrand.addStapCrossover(xo2);
                    }
                    this.drawPath.updateStapleColor(vs1, xo1.pos, vs1.stap[xo1.pos].color);
                    this.drawPath.updateStap(true);
                }
                
                // FIX (?)
                // CrossoverHandle should be updated with "forced" flag,
                // which if enabled will also show text of position
                // and color the line red.  Will need to detect forced
                // crossovers when loading saved structures.
                
            } else if (event.target.name == "Cancel") {
                // do nothing
                // trace("action canceled");
            }
            
            resetCrossoverTool();
        }
        
        private function paintDownHandler(event:MouseEvent):void {
            var vs:Vstrand;
            var gridY,vsIndex,pos:int;
            localpoint.x = event.stageX;
            localpoint.y = event.stageY;
            var point:Point = this.pathPanel.canvas.globalToLocal(localpoint);
            gridY = Math.round((point.y-halfbaseWidth)/baseWidth);
            pos = Math.round((point.x-halfbaseWidth - drawPath.x)/baseWidth);
            if (gridY < 0 || pos < 1) {return;} // need to be able to check pos-1
            vs = getClickedVstrand(gridY);
            
            if (vs != null) {
                if (pos == vs.scaf.length-1) {return;} // need to be able to check pos+1
                if (gridY % 5 == 0) { // look for scaffold on even strand or staple on odd strand
                    if (vs.number % 2 == 0) { // check for scaffold
                        // scaffold
                    } else { // check for staple
                        if (vs.hasStap(pos)) {
                            this.drawPath.updateStapleColor(vs, pos, colorPicker.selectedColor);
                            this.drawPath.updateStap(true);
                        }
                    }
                } else if ((gridY-1) % 5 == 0) { // look for scaffold on odd strand or staple on even strand
                    if (vs.number % 2 == 1) { // check for scaffold
                        // scaffold
                    } else { // check for staple
                        if (vs.hasStap(pos)) {
                            this.drawPath.updateStapleColor(vs, pos, colorPicker.selectedColor);
                            this.drawPath.updateStap(true);
                        }
                    }
                }
            }
        }
    }
}