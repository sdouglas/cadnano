//
//  RenderTools
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
    import flash.display.Bitmap;
    import flash.display.BitmapData;
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
    
    // air
    import flash.filesystem.*;
    import flash.events.IOErrorEvent;
    
    import flash.events.Event;
    import br.com.stimuli.string.printf;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    
    public class Render3DTools extends Sprite {
        
        public var render3d:Render3D;
        private var render3DPanel:Panel;
        private var mainLoader:BulkLoader;
        private var point:Point; // for mouse calculations
        
        private var zoomTool:ToolButton = new ToolButton("zoom", 0x666666);
        private var moveTool:ToolButton = new ToolButton("move", 0x666666);
        private var exportX3DTool:ToolButton = new ToolButton("x3d", 0x666666);    
        private var moveCursor:Sprite = new Sprite();
        private var buttonArray:Array;
        
        // visibility buttons
        private var visArray:Array;
        private var visBitMap:Bitmap;
        public var visScaffold:ToolButton = new ToolButton("scaffold", 0x666666);
        public var visStaple:ToolButton = new ToolButton("staples", 0x666666);
        
        // file export
        public var dataTools:DataTools;
        private var currentFile:File;
        private var defaultX3DDirectory:File = File.desktopDirectory.resolvePath("a.x3d"); // user home directory is default

        // filestream for reading the current file
        private var stream:FileStream = new FileStream();
        private var x3DString:String;
        
        function Render3DTools(render3d:Render3D,render3DPanel:Panel) {
            this.y = render3DPanel.h + 10;
            this.render3d = render3d;
            this.render3DPanel = render3DPanel;
            
            var mainLoader:BulkLoader = BulkLoader.getLoader("main");
            zoomTool.addChild(mainLoader.getBitmap("icons/render3d-zoom.png"));
            exportX3DTool.addChild(mainLoader.getBitmap("icons/render3d-x3d.png"));
            moveTool.addChild(mainLoader.getBitmap("icons/render3d-transform.png"));
            moveCursor.addChild(mainLoader.getBitmap("icons/render3d-transform-cursor.png"));
            visBitMap = mainLoader.getBitmap("icons/render3d-vis.png");
            buttonArray = new Array(zoomTool, moveTool, exportX3DTool);
            buttonArray.forEach(setupButton);
            
            // initialize cursors
            this.moveCursor.visible = false;
            this.addChild(moveCursor);
            this.render3DPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
            this.render3DPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
            
            zoomTool.addEventListener(MouseEvent.CLICK, zoomToolAction);
            moveTool.addEventListener(MouseEvent.CLICK, moveToolAction);
            exportX3DTool.addEventListener(MouseEvent.CLICK, exportX3DToolAction);
        }
        
        private function loadBitMaps():void {
        }
        
        /*
        Used to align Render3DTools after resize
        */
        public function update():void {
            this.x = this.render3DPanel.leftX;
        }
        
        private function setupButton(button:*, index:int, array:Array):void {
            this.addChild(button);
            button.x = index*40; // x position of button
            button.addEventListener(MouseEvent.MOUSE_OVER, hover);
            button.addEventListener(MouseEvent.MOUSE_OUT, unhover);
        }
        
        /*
        Add vis button as child of display object, set its x,y coordinates
        and add hover and unhover listeners.
        */
        private function setupVis(vis:*, index:int, array:Array):void {
            vis.icon = new Bitmap(visBitMap.bitmapData);
            vis.addChild(vis.icon);
            vis.x = 4;
            vis.y = 70 + index*24;
            vis.tf.x = 28;
            vis.tf.y = 0;
            vis.graphics.beginFill(0xffffff,0.5);
            vis.graphics.lineStyle(1, 0x666666, 1, true);
            vis.graphics.drawRect(-1,-1,22,22);
            vis.graphics.endFill();
            this.addChild(vis);
            vis.addEventListener(MouseEvent.CLICK, visClick);
            vis.enabled = true;
        }
        
        /*
        Adjust button appearance so user knows it's active
        */
        private function hover(event:MouseEvent):void {
            event.target.graphics.beginFill(0xcccccc,0);
            event.target.graphics.lineStyle(1, 0x666666, 1, true);
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
        Toggle layer visibility when eye icon is clicked.
        */
        private function visClick(event:MouseEvent):void {
            event.target.enabled = !event.target.enabled;
            
            if (event.target.enabled) {
                event.target.icon.visible = true;
                event.target.lines.visible = true;
            } else {
                event.target.icon.visible = false;
                event.target.lines.visible = false;
            }
            this.render3d.render();
        }
        
        
        /*
        Change papervision camera.zoom when clicked.  Shift modifier key.
        */
        private function zoomToolAction(event:MouseEvent) {
            if (event.shiftKey) { // zoom out 
                if (this.render3d.camera.zoom < 5) {
                    return;
                } else {
                    this.render3d.camera.zoom -= 4;
                }
            } else {
                this.render3d.camera.zoom += 4;
            }
            this.render3d.render();
        }
        
        /*
        Update custom cursor as mouse moves.  Depending on what button
        is toggled, different cursors are displayed.
        */
        private function mouseMoveHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            if (moveTool.enabled) {
                point = DisplayObjectUtil.localToLocal(new Point(event.localX, event.localY), this.render3DPanel.mouseLayer, this);
                moveCursor.visible = true;
                moveCursor.x = point.x;
                moveCursor.y = point.y;
            } else {
                //Mouse.show();
            }
        }
        
        /* 
        Handle initial mouse entry onto render3DPanel.  vis default cursor,
        listen for mouse_move events.
        */
        private function mouseOverHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            if (moveTool.enabled) {
                Mouse.hide();
                this.render3DPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
                //this.render3DPanel.mouseLayer.addEventListener(MouseEvent.CLICK, mouseClickHandler);
                
                if (moveTool.enabled) {
                    this.render3DPanel.mouseLayer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                }
            } else {
                //Mouse.show();
            }
        }
        
        /*
        Start dragging the path canvas on MOUSE_DOWN event.
        */
        private function mouseDownHandler(event:MouseEvent):void {
            this.render3DPanel.canvas.startDrag();
            this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /*
        Stop dragging the path canvas on MOUSE_UP event.
        */
        private function mouseUpHandler(event:MouseEvent):void {
            this.render3DPanel.canvas.stopDrag();
            // set new canvas center point
            this.render3DPanel.canvascp = DisplayObjectUtil.localToLocal(this.render3DPanel.center,this.render3DPanel,this.render3DPanel.canvas);
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /* 
        Handle mouse exit from render3DPanel.  Restore default cursor,
        stop listening for mouse_move events.  hide custom cursors.
        */
        private function mouseOutHandler(event:MouseEvent):void {
            Mouse.show();
            moveCursor.visible = false;
            this.render3DPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
            if (moveTool.enabled) {
                    this.render3DPanel.mouseLayer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            }
        }
        
        /*
        Enable move and disable others when move button is clicked
        */
        private function moveToolAction(event:MouseEvent) {
            if (!moveTool.enabled) {
                moveTool.enabled = true; // enable move mode
                this.render3DPanel.mouseLayer.visible = true;
                // highlight move tool button
                moveTool.removeEventListener(MouseEvent.MOUSE_OVER, hover);
                moveTool.removeEventListener(MouseEvent.MOUSE_OUT, unhover);
                // redraw
                moveTool.graphics.beginFill(0xcccccc, 0.5);
                moveTool.graphics.lineStyle(1, 0x666666, 1, true);
                moveTool.graphics.drawRect(0,0,32,32);
                moveTool.graphics.endFill();
            } else {
                moveTool.enabled = false; // enable move mode
                this.render3DPanel.mouseLayer.visible = false;
                moveTool.graphics.clear();
                moveTool.addEventListener(MouseEvent.MOUSE_OVER, hover);
                moveTool.addEventListener(MouseEvent.MOUSE_OUT, unhover);
            }
        }
                
        private function exportX3DToolAction(event:MouseEvent):void {
            var helixSegments:Array = render3d.helixSegments;
            if (helixSegments == null) {
                return;
            }
            
            makeX3DString();
            writeX3DString();
        }
        
        private function makeX3DString():void {
            var helixSegments:Array = render3d.helixSegments;
            
            var coordinateString:String = "";
            var coordinateSubStringTemplate = "<Transform translation=\'%(drawX)s %(drawY)s %(drawZStart)s\'>\n<Transform rotation='1 0 0 1.57'>\n<Shape>\n<Cylinder height=\'%(drawZEndMinusdrawZStart)s\' radius=\'%(radius)s\'/> \n<Appearance><Material diffuseColor=\'0.16 0.55 0.94\'/></Appearance>\n</Shape></Transform>\n</Transform>\n\n";
            var coordinateSubStringTemplateInsertObject:Object;
            var x3DStringTemplate:String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE X3D PUBLIC \"ISO//Web3D//DTD X3D 3.0//EN\" \"http://www.web3d.org/specifications/x3d-3.0.dtd\">\n<X3D version=\'3.0\' profile=\'Immersive\' xmlns:xsd=\'http://www.w3.org/2001/XMLSchema-instance\' xsd:noNamespaceSchemaLocation=\'http://www.web3d.org/specifications/x3d-3.0.xsd\'>\n<Scene>\n<Background skyColor=\'0 0 0\'/>\n<Group>\n %(coordinateString)s \n</Group>\n</Scene>\n</X3D>";
            
            var drawX,drawY,drawZStart,drawZEnd,zDiff:int;
            
            for(var i:int = 0; i < helixSegments.length; i++){
                drawX = helixSegments[i][0];
                drawY = helixSegments[i][1];
                drawZStart = helixSegments[i][2];
                drawZEnd = helixSegments[i][3];
                zDiff = drawZEnd-drawZStart;
                if (zDiff < 0) {zDiff = -zDiff;}
                
                coordinateSubStringTemplateInsertObject = {"drawX":drawX.toString(),
                                                           "drawY":drawY.toString(),
                                                           "drawZStart":NumberUtil.roundToPrecision((-(drawZStart + drawZEnd)*0.5),2).toString(),
                                                           "drawZEndMinusdrawZStart":zDiff.toString(),
                                                           "radius":render3d.radius.toString()};
                coordinateString = coordinateString + printf(coordinateSubStringTemplate, coordinateSubStringTemplateInsertObject);
            }
            
            x3DString = printf(x3DStringTemplate, {"coordinateString":coordinateString});
        }
        
        private function writeX3DString():void {
            var fileChooser:File;
            if (currentFile) { // reuse existing name
                fileChooser = currentFile;
            } else { // never saved?
                if (this.dataTools.currentFile == null) {
                    fileChooser = defaultX3DDirectory; // json never saved either
                } else { // construct x3d filename based on json
                    var pattern:RegExp = /\.json$/;
                    var x3dFileName:String = this.dataTools.currentFile.name.replace(pattern, "");
                    fileChooser = this.dataTools.currentFile.parent.resolvePath(x3dFileName + ".x3d");
                }
            }
            fileChooser.browseForSave("Export X3D As");
            fileChooser.addEventListener(Event.SELECT, exportX3DToolFileSelected);
        }
        
        private function exportX3DToolFileSelected(event:Event):void{
            currentFile = event.target as File;
            currentFile.removeEventListener(Event.SELECT, exportX3DToolFileSelected);
            
            if (stream != null) {
                stream.close();
            }
            stream = new FileStream();
            stream.openAsync(currentFile, FileMode.WRITE);
            stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
            stream.writeUTFBytes(x3DString);
            stream.close();
        }
        
        private function writeIOErrorHandler(event:Event):void {
            trace("The specified currentFile cannot be saved.");
        }
    }
}