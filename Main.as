//
//  Main.as - cadnano
//
//  Created by Shawn on 2007-10-17.
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

package {
    // flash
    import flash.display.Sprite;
    import flash.display.Screen;
    import flash.geom.Rectangle;
    
    import flash.events.Event;
    import flash.events.ProgressEvent;
    
    // AIR
    import flash.desktop.NativeApplication;
    import flash.display.NativeWindow;
    import flash.display.NativeWindowResize;
    
    // misc
    import br.com.stimuli.loading.*;
    import de.polygonal.ds.*;
    import com.yahoo.astra.fl.managers.AlertManager;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    import edu.harvard.med.cadnano.data.*;
    import edu.harvard.med.cadnano.drawing.*;
    import edu.harvard.med.cadnano.panel.*;
    
    // debug
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.text.TextFieldType;
    
    public class Main extends Sprite {
        // constants, colors, initial parameters.
        public static const ROWS:int = 30; // rows of SliceNodes per slice
        public static const COLS:int = 32; // cols of SliceNodes per slice
        public static const SLICEBG:int = 0xcc6600; // orange border
        public static const PATHBG:int = 0x0066cc; // blue border
        public static const RENDERBG:int = 0x666666; // green border
        private var maxH:int = 1140;//800; // max application window height
        private var maxW:int = 1824;//1200; // max application window width
        private var h,w:int;
        public var radius:int = 20; // SliceTools.mouseClickHandler() requires (radius % 5) == 0.
        
        // Display components & tools
        private var slicePanel:Panel;
        private var pathPanel:Panel;
        private var render3DPanel:Panel;
        private var dock:PanelDock;
        private var sliceCanvas:Sprite;
        private var pathCanvas:Sprite;
        private var render3DCanvas:Sprite;
        private var sliceTools:SliceTools;
        private var pathTools:PathTools;
        private var render3DTools:Render3DTools;
        private var dataTools:DataTools;
        
        private var render3D:Render3D;
        
        // Data containers
        private var slice:Slice;
        private var drawSlice:DrawSlice;
        private var path:Path;
        private var drawPath:DrawPath;
        
        // Bulk loading
        public var bulkLoader:BulkLoader;
        
        /*
        Main handles the initial instantiation of the data and
        drawing components.
        */
        public function Main() {
            // set up window dimensions and scaling
            this.setSize();
            
            // set up main drawing areas (a.k.a. canvases)
            this.sliceCanvas = new Sprite();
            this.pathCanvas = new Sprite();
            this.render3DCanvas = new Sprite();
            
            // set up panels to house each canvas
            this.slicePanel = new Panel(h, w, 1, 3, sliceCanvas, SLICEBG);
            this.pathPanel = new Panel(h, w, 2, 3, pathCanvas, PATHBG);
            this.render3DPanel = new Panel(h, w, 3, 3, render3DCanvas, RENDERBG);
            this.addChild(this.slicePanel);
            this.addChild(this.pathPanel);
            this.addChild(this.render3DPanel);
            
            // set up the dock
            this.dock = new PanelDock(slicePanel, pathPanel, render3DPanel);
            this.addChild(this.dock);
            
            // set up Path data container and drawing routines
            this.path = new Path();
            this.drawPath = new DrawPath(this.path);
            this.pathCanvas.addChild(this.drawPath);
            
            // set up Slice data container and drawing routines
            this.slice = new Slice(ROWS,COLS);
            this.drawSlice = new DrawSlice(this.slice, ROWS, COLS, radius, this.path, this.drawPath);
            this.sliceCanvas.addChild(this.drawSlice);
            this.drawSlice.update(radius);
            
            // set up Render3D 
            this.render3D = new Render3D(this.path, this.render3DPanel);
            this.render3DCanvas.addChild(this.render3D);
            
            // add Render3D mousing area
            this.render3DCanvas.graphics.beginFill(0xffffff, 1);
            this.render3DCanvas.graphics.drawRect(0,10,this.render3DPanel.w,this.render3DPanel.h);
            this.render3DCanvas.graphics.endFill();
            
            this.render3D.init(this.render3DCanvas);
            this.drawPath.render3D = this.render3D;
            
            // bulk-load all icon images
            this.bulkLoader = new BulkLoader("main");
            setupBulkLoader();
            this.bulkLoader.start();
        }
        
        /* Establish window dimensions and scaling */
        private function setSize():void {
            var mainScreen:Screen = Screen.mainScreen;
            var screenBounds:Rectangle = mainScreen.bounds;
            this.h = Math.min(screenBounds.height*0.95, this.maxH);
            this.w = Math.min(screenBounds.width*0.95, this.maxW);
            stage.nativeWindow.x = stage.nativeWindow.y = 40;
            stage.showDefaultContextMenu = false;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            this.x = this.y = 20; // provide some edge padding
            stage.nativeWindow.addEventListener(Event.ACTIVATE, onActivate);
        }
        
        /* Set size of window when it's ready. */
        private function onActivate(event:Event):void {
            stage.nativeWindow.height = this.h;
            stage.nativeWindow.width = this.w;
            stage.nativeWindow.removeEventListener(Event.ACTIVATE, onActivate);
        }
        
        /* Bulk loader pre-load operations: add files and event listeners. */
        private function setupBulkLoader():void {
            // slice icons
            this.bulkLoader.add("icons/slice-edit.png");
            this.bulkLoader.add("icons/slice-go-first.png");
            this.bulkLoader.add("icons/slice-go-last.png");
            this.bulkLoader.add("icons/slice-go-next.png");
            this.bulkLoader.add("icons/slice-go-previous.png");
            this.bulkLoader.add("icons/slice-renumber.png");
            this.bulkLoader.add("icons/slice-transform-cursor.png");
            this.bulkLoader.add("icons/slice-transform.png");
            this.bulkLoader.add("icons/slice-zoom.png");
            this.bulkLoader.add("icons/slice-zoomin.png");
            this.bulkLoader.add("icons/slice-zoomout.png");
            this.bulkLoader.add("icons/slice-delete-last.png");
            // path icons
            this.bulkLoader.add("icons/path-autostaple.png");
            this.bulkLoader.add("icons/path-break.png");
            this.bulkLoader.add("icons/path-edit.png");
            this.bulkLoader.add("icons/path-erase.png");
            this.bulkLoader.add("icons/path-force-xover.png");
            this.bulkLoader.add("icons/path-lock.png");
            this.bulkLoader.add("icons/path-loop.png");
            this.bulkLoader.add("icons/path-sequence.png");
            this.bulkLoader.add("icons/path-skip.png");
            this.bulkLoader.add("icons/path-svg.png");
            this.bulkLoader.add("icons/path-transform-cursor.png");
            this.bulkLoader.add("icons/path-transform.png");
            this.bulkLoader.add("icons/path-vis.png");
            this.bulkLoader.add("icons/path-zoom.png");
            this.bulkLoader.add("icons/path-zoomin.png");
            this.bulkLoader.add("icons/path-zoomout.png");
            // render3D icons
            this.bulkLoader.add("icons/render3d-transform.png");
            this.bulkLoader.add("icons/render3d-transform-cursor.png");
            this.bulkLoader.add("icons/render3d-vis.png");
            this.bulkLoader.add("icons/render3d-x3d.png");
            this.bulkLoader.add("icons/render3d-zoom.png");
            // data icons
            this.bulkLoader.add("icons/data-document-new.png");
            this.bulkLoader.add("icons/data-document-open.png");
            this.bulkLoader.add("icons/data-document-save.png");
            this.bulkLoader.add("icons/data-document-save-as.png");
            this.bulkLoader.add("icons/data-network-off.png");
            this.bulkLoader.add("icons/data-network-on.png");
            // add event listeners
            this.bulkLoader.addEventListener(BulkLoader.COMPLETE, onCompleteHandler);
        }
        
        /*
        Once all icons are loaded by bulkLoader, set up the tool buttons.
        The tools cannot be created until their bitmap icons are available.
        */
        private function onCompleteHandler(event:ProgressEvent):void {
            this.sliceTools = new SliceTools(this.slicePanel, this.drawSlice, this.path, this.drawPath);
            this.slicePanel.addChild(this.sliceTools);
            
            this.drawPath.initSliceBar();
            
            this.pathTools = new PathTools(this.stage, this.pathPanel, this.drawPath);
            this.pathPanel.addChild(this.pathTools);
            
            this.render3DTools = new Render3DTools(this.render3D, this.render3DPanel);
            this.render3DPanel.addChild(this.render3DTools);
            
            // after tools are created, they can re-positioned by the dock
            this.dock.addTools(sliceTools, pathTools, render3DTools);
            
            // add DataTools
            this.dataTools = new DataTools(this.slice, this.path, this.pathTools, this.pathPanel);
            this.addChild(this.dataTools);
            this.render3DTools.dataTools = this.dataTools;
            
            // reposition path canvas so helices are drawn near top of panel
            this.pathPanel.canvascp.x = 197;
            this.pathPanel.canvascp.y = 268;
            //this.pathPanel.canvascp.y = 200;
            
            this.pathTools.svg = new Svg(this.drawPath,this.dataTools);
            
            this.dock.updatePanels();
            //this.dock.toggleRender(null);
            
            stage.nativeWindow.addEventListener(Event.CLOSING, onExit);
        }
        
        /* Enable the user to cancel exits in order to save data.*/
        private function onExit(event:Event):void { 
            event.preventDefault();
            // launch dialog to prompt user to save
            var buttons:Array = new Array("Return", "Exit Program");
            var msg:String = "Most recent status:\n" + this.dataTools.lastSave;
            AlertManager.createAlert(this, 
                                    msg,
                                    "Last save status", 
                                    buttons, 
                                    exitHandler, 
                                    null, 
                                    true, 
                                    {textColor:0x000000}, 
                                    TextFieldType.DYNAMIC);
        }
        
        /* Handle the user's choice in exit without saving changes dialog.*/
        private function exitHandler(event:Event):void {
            if (event.target.name == "Exit Program"){
                for each (var win:NativeWindow in NativeApplication.nativeApplication.openedWindows) {
                    win.close();
                }
            } else {
                // cancel exit
            }
        }
    }
}