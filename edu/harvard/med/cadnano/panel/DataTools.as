//
//  DataTools
//
//  Created by Adam on 2008-05-20.
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

http://www.openToolsource.org/licenses/mit-license.php
*/

package edu.harvard.med.cadnano.panel {
    // flash
    import Date;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.ui.Mouse;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    // air
    import flash.filesystem.*; // File, FileMode, FileStream
    import flash.events.IOErrorEvent;
    
    // misc 3rd party
    import br.com.stimuli.loading.BulkLoader;
    import com.yahoo.astra.fl.controls.containerClasses.*;
    import com.yahoo.astra.fl.managers.AlertManager;
    import com.yahoo.astra.utils.*;
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.Path;
    import edu.harvard.med.cadnano.Slice;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.data.Token;
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.handles.CrossoverHandle;
    import edu.harvard.med.cadnano.drawing.handles.BreakpointHandle;
    import edu.harvard.med.cadnano.panel.PathTools;
    
    // JSON
    import org.jsonrpc.json.*;
    import org.jsonrpc.JSONRPCService;
    
    // DataGrid
    import fl.controls.DataGrid;
    import fl.data.DataProvider;
    import fl.controls.ScrollPolicy;
    import fl.events.ListEvent;
    import fl.controls.TextInput;
    import fl.controls.SelectableList;
    
    /*
    DataTools...
    */
    public class DataTools extends Sprite {
        // copy static vars from other classes
        private var baseWidth:int = DrawPath.baseWidth;
        private var LEFT_5PRIME:String = BreakpointHandle.LEFT_5PRIME;
        private var RIGHT_5PRIME:String = BreakpointHandle.RIGHT_5PRIME;
        
        //private var serverURL:String = "http://cadnano.org/services/admin.py";
        private var serverURL:String = "http://cadnano.org/services/readonly.py";
        //private var serverURL:String = "http://cadnano.org/services/shihlab.py";
        private var server:JSONRPCService = new JSONRPCService(serverURL);
        
        // bookkeeping
        private var slice:Slice;
        private var path:Path;
        private var pathTools:PathTools;
        private var mainLoader:BulkLoader;
        private var buttonArray:Array;
        private var point:Point = new Point(); // for mouse calculations
        private var networkEnabled:Boolean = false;
        public var lastSave:String = "Never saved.";
        private var writeAccess:Boolean = false;
        
        // the current file
        public var currentFile:File;
        
        // available structure names on server
        private var namesOnServer:Array;
        
        // current structure name
        private var currentLocalName:String = "";
        private var currentRemoteName:String = ""; // the name that was last sent to/from server
        private var currentRemoteID:String = "";
        private var wroteOnceToServer:Boolean = false;
        private var loadedFromServer:Boolean = false;
        private var stream:FileStream;
        private var defaultDirectory:File = File.desktopDirectory.resolvePath("a.json"); // user home directory is default
        
        // tools
        private var newTool:ToolButton = new ToolButton("new", 0x0066cc);
        private var openTool:ToolButton = new ToolButton("open", 0x0066cc);
        private var saveTool:ToolButton = new ToolButton("save", 0x0066cc);
        private var saveAsTool:ToolButton = new ToolButton("save\nas", 0x0066cc);
        private var remoteTool:ToolButton = new ToolButton("use\nserver", 0x0066cc);
        private var statusBox:TextField;
        private var format:TextFormat;
        private var largeText:TextFormat = new TextFormat();
        
        // data & alerts
        private var uploadDataGrid:DataGrid;
        private var uploadTextInput:TextInput;
        private var uploadAlertSprite:Sprite;
        private var downloadDataGrid:DataGrid;
        private var downloadAlertSprite:Sprite;
        
        
        function DataTools(slice:Slice, path:Path, pathTools:PathTools, pathPanel:Panel) {
            this.x = pathPanel.w - 380;
            this.y = pathPanel.h + 80;
            
            this.slice = slice;
            this.path = path;
            this.pathTools = pathTools;
            
            // initialize variables
            this.namesOnServer = [{"name":"", "id":"", "created":"", "modified":""}];
            this.loadedFromServer = false;
            this.stream = new FileStream();
            
            // retrieve pre-loaded Bitmaps
            this.mainLoader = BulkLoader.getLoader("main");
            this.loadBitMaps();
            
            // initilize buttons by calling setupButton() on each sprite
            this.buttonArray = new Array(newTool, openTool, saveTool, saveAsTool, remoteTool);
            this.buttonArray.forEach(setupButton);
            remoteTool.x += 2;
            remoteTool.y += 2;
            
            // assign specific button functions
            this.newTool.addEventListener(MouseEvent.CLICK, newToolAction);
            this.openTool.addEventListener(MouseEvent.CLICK, openToolAction);
            this.saveTool.addEventListener(MouseEvent.CLICK, saveAction);
            this.saveAsTool.addEventListener(MouseEvent.CLICK, saveAsToolAction);
            this.remoteTool.addEventListener(MouseEvent.CLICK, remoteToolAction);
            
            createUploadAlertSprite();
            createDownloadAlertSprite();
            // Draw box under Data buttons
            this.graphics.beginFill(0xcccccc, 0.5);
            this.graphics.drawRoundRect(-15,-10,220,80,4);
            this.graphics.endFill();
            
            this.statusBox = new TextField();
            this.statusBox.autoSize = "left";
            this.format = new TextFormat();
            this.format.align = "left";
            this.format.font = "Verdana";
            this.format.color = 0x0066cc;
            this.format.size = 10;
            this.statusBox.x = -15;
            this.statusBox.y = 75;
            this.statusBox.visible = true;
            this.addChild(this.statusBox);
            
            this.largeText;
            this.largeText.align = "left";
            this.largeText.font = "Verdana";
            this.largeText.size = 14;
        }
        
        // ----miscellaneous interface functions----
        
        private function loadBitMaps():void {
            newTool.addChild(this.mainLoader.getBitmap("icons/data-document-new.png"));
            openTool.addChild(this.mainLoader.getBitmap("icons/data-document-open.png"));
            saveTool.addChild(this.mainLoader.getBitmap("icons/data-document-save.png"));
            saveAsTool.addChild(this.mainLoader.getBitmap("icons/data-document-save-as.png"));
            remoteTool.addChild(this.mainLoader.getBitmap("icons/data-network-off.png"));
            remoteTool.addChild(this.mainLoader.getBitmap("icons/data-network-on.png"));
            remoteTool.getChildAt(2).visible = false;
        }
        
        /*
        Add button as child of display object, set its x coordinate
        and add hover and unhover listeners.
        */
        private function setupButton(button:*, index:int, array:Array):void {
            button.x = index*40; // x position of button
            this.addChild(button);
            if (button.name != "use\nserver") {
                button.addEventListener(MouseEvent.MOUSE_OVER, hover);
                button.addEventListener(MouseEvent.MOUSE_OUT, unhover);
            }
        }
        
        /*
        Adjust button appearance when active
        */
        private function hover(event:MouseEvent):void {
            event.target.graphics.beginFill(0x99ccff, 0);
            event.target.graphics.lineStyle(1, 0x0066cc, 1, true);
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
        
        // ----debug functions----
        
        private function traceEncodeDebug(l:DLinkedList):void{
            // trace json encoding of l to the screen
            trace(packTppArray(l, currentName()));
        }
        
        private function traceDecodeEncodeDebug(s:String):void{
            // trace json encoding of json decoding of s to the screen
            trace(packTppArray(unpackTppArray(s), currentName()));
        }
        
        // ----button responses----
        private function remoteToolAction(event:MouseEvent):void {
            if (networkEnabled == true) {
                networkEnabled = false;
                remoteTool.getChildAt(2).visible = false;
                this.statusBox.text = "";
            } else {
                networkEnabled = true;
                remoteTool.getChildAt(2).visible = true;
                this.server.canwrite(checkServerAccess);
            }
        }
        
        private function currentName():String{
            var date:Date = new Date();
            return date.toDateString() + " " + date.toTimeString();
        }
        
        /* Parse output from read all to return the input to the DataProvider
        */
        private function parseServerReadAllOutput(o:Object):void {
            var individualEntries:Array = o.toString().split("(");
           
            for(var i:int = 0; i<individualEntries.length; i++){
                 // prune the closing parenthesis off the ends of each element
                individualEntries[i] = individualEntries[i].substring(0,individualEntries[i].length -2);
                 // make an array of data elements
                individualEntries[i] = individualEntries[i].split(",");
                // prune single quotes
                for (var j:int = 1;j<individualEntries[i].length;j++){
                    individualEntries[i][j] = individualEntries[i][j].substring(2,individualEntries[i][j].length - 1);
                }
            }
            individualEntries.shift();
            var formattedEntries:Array = new Array();
            for(var k:int = 0; k<individualEntries.length; k++){
                formattedEntries.push({"name":individualEntries[k][1],
                                       "id":individualEntries[k][0].substring(0,individualEntries[k][0].length - 1),
                                       "created":individualEntries[k][2],
                                       "modified":individualEntries[k][3]});
            }
            this.namesOnServer = formattedEntries;
        }
        
        private function newToolAction(event:MouseEvent):void {
            var vsList:DLinkedList = new DLinkedList();
            var dp:DrawPath = this.path.drawPath;
            dp.render3D.suppressRendering = true;
            this.path.resetPathData();
            dp.drawSlice.resetSliceNodes();
            dp.drawSlice.resetCounters(-2,-1);
            dp.removeAllDrawVstrands();
            this.updateInterface(vsList);
            dp.resetSliceBar();
            dp.redrawGridLines();
            dp.render3D.suppressRendering = false;
            currentFile = null;
            currentLocalName = "";
            currentRemoteName = "";
            currentRemoteID = "";
            wroteOnceToServer = false;
            loadedFromServer = false;
        }
        
        private function openToolAction(event:MouseEvent):void {
            if (networkEnabled == false) {
                // get the file
                var fileChooser:File;
                if (this.currentFile) {
                    fileChooser = this.currentFile;
                } else {
                    fileChooser = this.defaultDirectory;
                }
                // launch the dialog box
                fileChooser.browseForOpen("Open");
                fileChooser.addEventListener(Event.SELECT, this.fileOpenSelected);
            } else{
                this.readFromServerAction(event);
            }
        }
        
        /* FIX: add comment */
        private function saveAction(event:MouseEvent):void {
            if (this.networkEnabled == false) {
                var jsonString:String = packTppArray(this.path.vsList, this.currentName());
                if (this.currentFile) {
                    if (this.stream != null) {
                        this.stream.close();
                    }
                    this.stream = new FileStream();
                    this.stream.openAsync(currentFile, FileMode.WRITE);
                    this.stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
                    this.stream.writeUTFBytes(jsonString);
                    this.stream.close();
                    var date:Date = new Date();
                    this.statusBox.text = "saved: " + currentFile.name + " (local)\n" + date.toTimeString().substr(0,8);
                    this.statusBox.setTextFormat(this.format);
                    this.lastSave = "saved: " + currentFile.name + " (local) " + date.toTimeString().substr(0,8);
                } else {
                    this.saveAsToolAction(event);
                }
            } else {
                // check for write access on the server
                if (this.writeAccess) {
                    this.statusBox.text = "connecting...";
                    this.statusBox.setTextFormat(this.format);
                    if (this.wroteOnceToServer == false && 
                        this.loadedFromServer == false) {
                        // never saved, so launch all the dialog boxes etc.
                        this.writeToServerAction(event);
                    } else {
                        // just an update, so go directly to writing by ID
                        this.writeToServerByID(this.path.vsList, 
                                               this.currentRemoteID);
                    }
                } else {
                    AlertManager.createAlert(this.parent,
                                             "Sorry, this database is read-only.",
                                             "Server response",
                                             null,
                                             null,
                                             null,
                                             true,
                                             {textColor:0x000000},
                                             TextFieldType.DYNAMIC,
                                             null);
                }
            }
        }
        
        /* FIX: add comment */
        private function saveAsToolAction(event:MouseEvent):void {
            if (networkEnabled == false) {
                var fileChooser:File;
                if (currentFile) {
                    fileChooser = currentFile;
                } else {
                    fileChooser = defaultDirectory;
                }
                fileChooser.browseForSave("Save As");
                fileChooser.addEventListener(Event.SELECT, saveAsToolFileSelected);
            } else {
                // check for write access on the server
                if (this.writeAccess) {
                    this.statusBox.text = "connecting...";
                    this.statusBox.setTextFormat(this.format);
                    this.writeToServerAction(event);
                } else {
                    AlertManager.createAlert(this.parent,
                                             "Sorry, this database is read-only.",
                                             "Server response",
                                             null,
                                             null,
                                             null,
                                             true,
                                             {textColor:0x000000},
                                             TextFieldType.DYNAMIC,
                                             null);

                }
            }
        }
        
        /* FIX: add comment */
        private function writeToServerAction(event:MouseEvent):void {
            // choose a name
            // get the available names
            this.statusBox.text = "connecting...";
            this.statusBox.setTextFormat(this.format);
            this.server.readAll(getExistingNamesBeforeSave);
        }
        
        /* FIX: add comment */
        private function readFromServerAction(event:MouseEvent):void {
            // choose a name
            // get the available names
            this.statusBox.text = "connecting...";
            this.statusBox.setTextFormat(this.format);
            this.server.readAll(getLoadableNamesFromServerHandler);
        }
        
        // ----conversion to and from JSON----
        // package tpp_ra as a JSON string for saving
        private function packTppArray(vsList:DLinkedList, name:String):String{
            //scaffold
            name = trim(name); // remove sorrounding whitespace
            
            // virtual strands from path
            var vsIter:DListIterator = vsList.getListIterator(); //vstrands
            
            // the list of vstrands
            var strandData:Array = new Array();
            
            var fullStrandSpecs:Object;
            
            for( vsIter.start(); vsIter.valid(); vsIter.forth() ) {
                var scafDataList:Array = new Array();
                var stapDataList:Array = new Array();
                var skipDataList:Array = new Array();
                var loopDataList:Array = new Array();
                var stapColorData:Array = new Array();
                
                // get the tokens
                for( var i:int = 0; i<vsIter.node.data.scaf.length; i++ ) {
                    scafDataList.push ([vsIter.node.data.scaf[i].prev_strand,
                                        vsIter.node.data.scaf[i].prev_pos,
                                        vsIter.node.data.scaf[i].next_strand,
                                        vsIter.node.data.scaf[i].next_pos]);
                    stapDataList.push ([vsIter.node.data.stap[i].prev_strand,
                                        vsIter.node.data.stap[i].prev_pos,
                                        vsIter.node.data.stap[i].next_strand,
                                        vsIter.node.data.stap[i].next_pos]);
                    // skipDataList ...
                    // loopDataList ...
                }
                
                // get the color data for the 5' breakpoints on this vstrand in the form [pos, color]
                var bp:BreakpointHandle;
                for each (bp in vsIter.node.data.drawVstrand.stapbreaks) {
                    if (bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME) {
                        stapColorData.push([bp.pos, bp.color]);
                    }
                }
                
                fullStrandSpecs = {"col":vsIter.node.data.col,
                                   "row":vsIter.node.data.row,
                                   "stap":stapDataList,
                                   "scaf":scafDataList,
                                   "num": vsIter.node.data.number,
                                   "loop":vsIter.node.data.loop,
                                   "scafLoop":vsIter.node.data.scafLoop,
                                   "stapLoop":vsIter.node.data.stapLoop,
                                   "skip":vsIter.node.data.skip, 
                                   "stap_colors":stapColorData};
                strandData.push(fullStrandSpecs);
            }
            // convert to JSON
            var data:Object = {"name":name , "vstrands":strandData};
            // TO DO: incorporate structure names
            var encodedData:String = marshall(data);
            return encodedData;
        }
        
        private function getStructureName(jsonString:String):String {
            var data:Object = unmarshall(jsonString);
            return data["name"];
        }
        
        private function unpackTppArray(jsonString:String):DLinkedList{
            //this.statusBox.text = "parsing...";
            //this.statusBox.setTextFormat(this.format);
            var data:Object;
            
            // returns new vstrands
            try {
                data = unmarshall(jsonString);
                //trace("data", data);
            } catch (e:Error) {
                this.currentFile = null; // avoid overwriting invalid file in future saves
                AlertManager.createAlert(this.parent,
                                             "Bad JSON source.",
                                             "Error",
                                             null,
                                             null,
                                             null,
                                             true,
                                             {textColor:0x000000},
                                             TextFieldType.DYNAMIC,
                                             null);
                return null;
            }
            var strandData:Array = data["vstrands"];
            
            // the arrays to be produced
            var scafArray:Array;
            var stapArray:Array;
            
            // the arrays read from json
            var scafStrand:Array;
            var stapStrand:Array;
            
            // loops and skips
            var scafLoop:Array;
            var stapLoop:Array;
            
            var loop:Array; // double-stranded
            var skip:Array
            
            // the vstrands to output
            var vsList:DLinkedList = new DLinkedList();
            
            var sliceNode:SliceNode;
            var row,col,num:Number;
            var even:int = -2;
            var odd:int = -1;
            var len:int;
            
            this.path.resetPathData();
            this.path.drawPath.drawSlice.resetSliceNodes();
            
            // loop through vstrands
            len = strandData.length;
            for (var i:int = 0; i < len; i++) {
                scafArray = new Array();
                stapArray = new Array();
                scafStrand = strandData[i]["scaf"];
                stapStrand = strandData[i]["stap"];
                // construct the scaf array
                for (var j:int = 0; j < scafStrand.length; j++) {
                    var scafToken:Token = new Token();
                    scafToken.prev_strand = scafStrand[j][0];
                    scafToken.prev_pos = scafStrand[j][1];
                    scafToken.next_strand = scafStrand[j][2];
                    scafToken.next_pos = scafStrand[j][3];
                    scafArray.push(scafToken);
                }
                
                // construct the stap array
                for (var k:int = 0; k < stapStrand.length; k++) {
                    var stapToken:Token = new Token();
                    stapToken.prev_strand = stapStrand[k][0];
                    stapToken.prev_pos = stapStrand[k][1];
                    stapToken.next_strand = stapStrand[k][2];
                    stapToken.next_pos = stapStrand[k][3];
                    
                    // if the json data contains color info for this vstrand
                    if((strandData[i].hasOwnProperty("stap_colors")) && (strandData[i]["stap_colors"] != null)){
                        var stapColorData:Array = strandData[i]["stap_colors"];
                        for(var l:int = 0; l < stapColorData.length; l++){
                            if (stapColorData[l][0] == k){ // if we are at a breakpoint with color info in the json data
                                // assign the corresponding staple token's color in the output DLinkedList
                                stapToken.color = stapColorData[l][1];
                            }
                        }
                    }
                    stapArray.push(stapToken);
                }
                
                row = Number(strandData[i]["row"]);
                col = Number(strandData[i]["col"]);
                sliceNode = slice.getSliceNode(row,col);
                sliceNode.number = strandData[i]["num"];
                
                var vstrand:Vstrand = new Vstrand(sliceNode, scafArray.length);
                
                if ((strandData[i].hasOwnProperty("scafLoop")) && (strandData[i]["scafLoop"] != null)) {
                    vstrand.scafLoop = strandData[i]["scafLoop"];
                }
                if ((strandData[i].hasOwnProperty("stapLoop")) && (strandData[i]["stapLoop"] != null)) {
                    vstrand.stapLoop = strandData[i]["stapLoop"];
                }
                if ((strandData[i].hasOwnProperty("loop")) && (strandData[i]["loop"] != null)) {
                    vstrand.loop = strandData[i]["loop"];
                }
                if ((strandData[i].hasOwnProperty("skip")) && (strandData[i]["skip"] != null)) {
                    vstrand.skip = strandData[i]["skip"];
                }
                
                vstrand.scaf = scafArray;
                vstrand.stap = stapArray;
                sliceNode.vstrand = vstrand;
                vsList.append(vstrand);
                
                // reset counters for adding new nodes
                if (sliceNode.number % 2 == 0) {
                    if (sliceNode.number > even) {
                        even = sliceNode.number;
                    }
                } else {
                    if (sliceNode.number > odd) {
                        odd = sliceNode.number;
                    }
                }
            }
            
            this.path.drawPath.drawSlice.resetCounters(even,odd);
            
            return vsList;
        }
        
        private function updateInterface(vsList:DLinkedList):void {
            var dp:DrawPath = this.path.drawPath;
            dp.render3D.suppressRendering = true;
            dp.allowRefresh = false;
            
            // remove existing drawVstrands from DrawPath
            dp.removeAllDrawVstrands();
            dp.resetSliceBar();
            dp.redrawGridLines();
            
            // pass newVstrands to Path.importVstrands (similar to addHelix)
            this.path.importVstrands(vsList);
            
            // loop through SliceNodes and pair neighboring vstrands
            slice.pairAllVstrands(this.path);
            
            // detect installed crossovers, loops, and skips and add appropriate handles
            dp.loadHandles();
            dp.allowRefresh = true;
            
            // populate colors from read data
            dp.update();
            dp.stapAutoColor(true);
            dp.updateStap();
            dp.clearHairpins();
            dp.render3D.suppressRendering = false;
            dp.render3D.redrawBases();
        }
        
        // ----invokation from file opening --- //
        public function invokeFromFile(fileName:String, currentDir:File){
            try {
                // resolve path
                var file:File = currentDir.resolvePath(fileName);
                // set currentFile
                this.currentFile = file;
                // set the stream
                this.stream = new FileStream();
                // open the file
                stream.addEventListener(Event.COMPLETE, fileReadHandler);
                stream.addEventListener(IOErrorEvent.IO_ERROR, readIOErrorHandler);
            } catch(e:Error) { // FIX: this is poor exception handling
                this.statusBox.text = "Error: could not open file.";
                trace(e.toString());
            }
        }
        
        // ----file reading and writing utils----
        private function fileOpenSelected(event:Event):void {
            currentFile = event.target as File;
            stream = new FileStream();
            stream.openAsync(currentFile, FileMode.READ);
            stream.addEventListener(Event.COMPLETE, fileReadHandler);
            stream.addEventListener(IOErrorEvent.IO_ERROR, readIOErrorHandler);
            currentFile.removeEventListener(Event.SELECT, fileOpenSelected);
        }
        
        private function fileReadHandler(event:Event):void {
            var jsonString:String = stream.readUTFBytes(stream.bytesAvailable);
            stream.close();
            // problematic line endings?
            var lineEndPattern:RegExp = new RegExp(File.lineEnding, "g");
            jsonString = jsonString.replace(lineEndPattern, "\n");
            // unpack the String into a new tpp_ra
            var vsList:DLinkedList = unpackTppArray(jsonString);
            if (vsList == null) {
                this.statusBox.text = "error: bad JSON";
                this.statusBox.setTextFormat(this.format);
                return;
            }
            // set the current structure name
            this.currentLocalName = this.getStructureName(jsonString);
            this.updateInterface(vsList);
            var date:Date = new Date();
            this.statusBox.text = "loaded: " + currentFile.name + "\n" + date.toTimeString().substr(0,8);
            this.statusBox.setTextFormat(this.format);
            // refresh server information when a new file is loaded locally
            currentRemoteName = ""; // the name that was last sent to/from server
            currentRemoteID = "";
            wroteOnceToServer = false;
            loadedFromServer = false;
        }
        
        private function saveAsToolFileSelected(event:Event):void
            {
            currentFile = event.target as File;
            currentFile.removeEventListener(Event.SELECT, saveAsToolFileSelected);
            
            var jsonString:String = packTppArray(this.path.vsList, this.currentName());
            
            if (stream != null) {
                stream.close();
            }
            this.stream = new FileStream();
            this.stream.openAsync(currentFile, FileMode.WRITE);
            this.stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
            this.stream.writeUTFBytes(jsonString);
            this.stream.close();
            var date:Date = new Date();
            this.statusBox.text = "saved as: " + currentFile.name + " (local)\n" + date.toTimeString().substr(0,8);
            this.statusBox.setTextFormat(this.format);
            this.lastSave = "saved as: " + currentFile.name + " (local) " + date.toTimeString().substr(0,8);
        }
        
        // ----file error handlers----
        
        /**
        * Handles I/O errors that may come about when using openTool with the currentFile.
        */
        private function readIOErrorHandler(event:Event):void {
            trace("The specified currentFile cannot be opened with openTool.");
        }
        
        /**
        * Handles I/O errors that may come about when writing the currentFile.
        */
        private function writeIOErrorHandler(event:Event):void {
            trace("The specified currentFile cannot be saved.");
        }
        
        // ----server reading and writing----
        private function createUploadAlertSprite():void {
            this.uploadAlertSprite = new Sprite();
            this.uploadTextInput = new TextInput();
            this.uploadTextInput.width = 600;
            this.uploadTextInput.textField.width = 600;
            this.uploadTextInput.textField.height = 22;
            this.uploadTextInput.textField.text = currentRemoteName;
            this.uploadTextInput.textField.setTextFormat(largeText);
            this.uploadAlertSprite.addChild(uploadTextInput);
            this.uploadDataGrid = new DataGrid();
            this.uploadDataGrid.columns = ["id", "name", "created", "modified"];
            this.uploadDataGrid.columns[0].width = 55;
            this.uploadDataGrid.columns[1].width = 250;
            this.uploadDataGrid.columns[2].width = 120;
            this.uploadDataGrid.horizontalScrollPolicy = ScrollPolicy.AUTO;
            this.uploadDataGrid.y = uploadTextInput.height + uploadTextInput.y;
            this.uploadDataGrid.width = 600;
            this.uploadDataGrid.rowCount = 6;
            this.uploadDataGrid.addEventListener(fl.events.ListEvent.ITEM_CLICK, uploadDataGridClickHandler)
            this.uploadAlertSprite.addChild(uploadDataGrid);
        }
        
        private function uploadDataGridClickHandler(e:fl.events.ListEvent):void{
            uploadTextInput.textField.text = this.namesOnServer[e.rowIndex]["name"];
        }
        
        /* Server returns 1 or 0 depending on whether the serverURL is
           pointing at a python script that has write access to the 
           database.
        */
        private function checkServerAccess(result:Object):void {
            var s:String = result.toString();
            if (s.search("1") != -1) {
                this.writeAccess = true;
                this.statusBox.text = "server: read+write.";
                this.statusBox.setTextFormat(this.format);
            } else {
                this.writeAccess = false;
                this.statusBox.text = "server: read-only.";
                this.statusBox.setTextFormat(this.format);
            }
        }
        
        private function getExistingNamesBeforeSave(result:Object):void {
            parseServerReadAllOutput(result);
            uploadDataGrid.dataProvider = new DataProvider(this.namesOnServer);
            uploadDataGrid.setStyle("headerTextFormat", largeText);
            uploadDataGrid.setRendererStyle("textFormat", largeText);
            this.uploadDataGrid.rowHeight = 20;
            var buttons:Array = new Array("Upload", "Cancel");
            uploadTextInput.textField.addEventListener(Event.CHANGE, disableSaveWhenExistingNameTyped);
            this.pathTools.toolKeysEnabled = false;
            AlertManager.createAlert(this.parent,
                                     "Choose a unique name for your design.",
                                     "Designs available on server",
                                     buttons,
                                     remoteSaveDialogHandler,
                                     null,
                                     true,
                                     {textColor:0x000000},
                                     TextFieldType.DYNAMIC,
                                     uploadAlertSprite);
            // initially disable the save button
            DialogBox(uploadAlertSprite.parent.parent)._buttonBar._buttons[0].button.enabled = false;
        }
        
        public function disableSaveWhenExistingNameTyped(event:Event):void {
            var textStr = event.target.text;
            var nameIsNew:Boolean = true;
            
            var element:Object = DialogBox(uploadAlertSprite.parent.parent)._buttonBar._buttons[0];
            var button:AutoSizeButton = element.button; // the save button
            button.enabled = false;
            for(var i:int = 0; i< this.namesOnServer.length;i++){
                if (trim(this.namesOnServer[i]["name"]) == trim(textStr)){
                    nameIsNew = false;
                }
            }
            
            if(nameIsNew == true){
                // enable button
                button.enabled = true;
            } else{
                // TO DO: print a message about needing a new name
                // need to re-position sprite so that the message actually shows up
                // don't know if this works
                // DialogBox(event.target.parent.parent.parent.parent).messageText = 
                // "Please choose a name which is not already in use.";
            }
        }
        
        private function remoteSaveDialogHandler(event:Event):void {
            this.pathTools.toolKeysEnabled = true;
            if (event.target.name == "Upload") {
                // get the textfield text for the name
                var objectName:String = trim(uploadTextInput.textField.text);
                writeToServerByName(this.path.vsList, objectName);
            } else {
                this.statusBox.text = "";
            }
            DialogBox(uploadAlertSprite.parent.parent)._buttonBar._buttons[0].button.enabled = true; // renable button
        }
         
        /* writes the data with key = name of structure, value = json vstrand data */
        private function writeToServerByName(vsList:DLinkedList, name:String):void {
            name = trim(name);
            // get the data to write
            var jsonString:String = packTppArray(vsList, name); // pack all relevant data as String
            var vstrandData:Array = unmarshall(jsonString)["vstrands"]; // unpack and leave off the name info
            var name:String = unmarshall(jsonString)["name"]; // unpack and take just the name info
            
            // test if a structure of the same name is present on the server and prompt for over-write
            
            // write data to server
            try {
                var dataToSend:Object = {"name":name, "data":vstrandData};
                //encode using json
                var encodedDataToSend:String = marshall(dataToSend);
                this.statusBox.text = "connecting...";
                this.statusBox.setTextFormat(this.format);
                this.server.saveAs(encodedDataToSend, serverWriteHandler);
                // next time save as opposed to save as is an option
                this.wroteOnceToServer = true;
                this.currentRemoteName = name; // assume the save worked properly
                var date:Date = new Date();
                this.statusBox.text = "saved (remote)\n" + date.toTimeString().substr(0,8);
                this.statusBox.setTextFormat(this.format);
                this.lastSave = "saved (remote) " + date.toTimeString().substr(0,8);
            } catch(e:Error) {  // FIX: this is poor exception handling
                trace(e.toString()); // should enumerate all expected exceptions and handle each appropriately
            }
        }
        
        /*We only do this once the object being edited already has an id via loading or saving*/
        private function writeToServerByID(vsList:DLinkedList, id:String):void {
            name = currentRemoteName;
            // pack all relevant data as String
            var jsonString:String = packTppArray(vsList, name); 
            // unpack and leave off the name info
            var vstrandData:Array = unmarshall(jsonString)["vstrands"]; 
            // unpack and take just the name info
            var name:String = unmarshall(jsonString)["name"]; 
            
            // test if a structure of the same name is present on the server
            this.statusBox.text = "connecting...";
            this.statusBox.setTextFormat(this.format);
            try {
                var dataToSend:Object = {"id":id, "data":vstrandData};
                //encode using json
                var encodedDataToSend:String = marshall(dataToSend);
                server.updateEntryByID(encodedDataToSend, serverWriteHandler);
                // assume the save worked properly
                this.currentRemoteName = name; 
                this.statusBox.text = "saving...";
                this.statusBox.setTextFormat(this.format);
            } catch(e:Error) { // FIX: this is poor exception handling
                trace(e.toString());
            }
        }
        
        private function createDownloadAlertSprite():void {
            this.downloadAlertSprite = new Sprite();
            this.downloadDataGrid = new DataGrid();
            this.downloadDataGrid.columns = ["id", "name", "created", "modified"];
            this.downloadDataGrid.columns[0].width = 55;
            this.downloadDataGrid.columns[1].width = 250;
            this.downloadDataGrid.columns[2].width = 120;
            this.downloadDataGrid.horizontalScrollPolicy = ScrollPolicy.AUTO;
            this.downloadDataGrid.width = 600;
            this.downloadDataGrid.dataProvider = new DataProvider(this.namesOnServer);
            
            // HACK - fix size of DataGrid sprite.
            this.downloadDataGrid.getChildAt(3).width = 600;
            this.downloadAlertSprite.addChild(downloadDataGrid);
        }
        
        private function getLoadableNamesFromServerHandler(result:Object):void{
            //this.statusBox.text = "parsing...";
            //this.statusBox.setTextFormat(this.format);
            parseServerReadAllOutput(result);
            this.downloadDataGrid.dataProvider = new DataProvider(this.namesOnServer)
            this.downloadDataGrid.setStyle("headerTextFormat", largeText);
            this.downloadDataGrid.setRendererStyle("textFormat", largeText);
            this.downloadDataGrid.rowCount = 6;
            this.downloadDataGrid.rowHeight = 20;
            this.statusBox.text = "";
            var buttons:Array = new Array("Download", "Cancel");
            this.pathTools.toolKeysEnabled = false;
            AlertManager.createAlert(this.parent,
                                     "Select a design to load.",
                                     "Designs available on server",
                                     buttons,
                                     loadSelectedStructure,
                                     null,
                                     true,
                                     {textColor:0x000000},
                                     TextFieldType.DYNAMIC,
                                     downloadAlertSprite);
        }
        
        private function loadSelectedStructure(event:Event) {
            this.pathTools.toolKeysEnabled = true;
            try {
                if (event.target.name == "Download") {
                    var structureIDChosen:String = this.namesOnServer[downloadDataGrid.selectedIndex]["id"];
                    //trace("user chose to download object with ID:", structureIDChosen);
                    this.readStructureFromServer(structureIDChosen);
                 } else if (event.target.name == "Cancel") {
                     this.statusBox.text = "";
                 }
            } catch(e:Error) { // FIX: this is poor exception handling
                // handle any error that arises
            }
        }
        
        /* Handles response from server after a write attempt. */
        private function serverWriteHandler(result:Object):void {
            // info returned by server
            var resultString:String = result.toString();
            //trace("save result string returned by server: ", resultString);
            //need to update the current name and ID based on this output
            var id:String = resultString.substring(1, resultString.length - 4);
            //trace("the id extracted is: ", id);
            this.currentRemoteID = id;
            
            var date:Date = new Date();
            this.statusBox.text = "saved (remote)\n" + date.toTimeString().substr(0,8);
            this.statusBox.setTextFormat(this.format);
            this.lastSave = "saved (remote)" + date.toTimeString().substr(0,8);
        }
        
        private function readStructureFromServer(id:String):void {
            this.statusBox.text = "connecting...";
            this.statusBox.setTextFormat(this.format);
            // openTool up a server connection
            //this.server = new JSONRPCService(serverURL);
            try { // read data from server
                server.readDataByID(id, serverReadHandler);
            } catch(e:Error) { // FIX: this is poor exception handling
                trace("Error in reading server data:");
                trace(e.toString());
            }
        }
        
        /* Handles response from server after a read attempt. */
        private function serverReadHandler(result:Object):void {
            //this.statusBox.text = "parsing...";
            //this.statusBox.setTextFormat(this.format);
            // not really sure how to do this...
            var resultString:String = result.toString();
            
            // extract the data
            var substrings:Array = resultString.split("'");
            var jsonNameString:String = trim(substrings[1]);
            var jsonDataString:String = trim(substrings[3]);
            var jsonString:String = "{\"name\":" + "\"" + jsonNameString + "\"" + ", \"vstrands\":" + jsonDataString + "}";
            // get the new vsList and new name from the json data
            try {
                var vsList:DLinkedList = unpackTppArray(jsonString);
                if (vsList == null) {
                    this.statusBox.text = "error: bad JSON";
                    this.statusBox.setTextFormat(this.format);
                    return;
                }
                this.currentRemoteName = jsonNameString;
                this.currentRemoteID = substrings[0].substring(1,substrings[0].length -3);
                this.loadedFromServer = true;
                this.updateInterface(vsList);
                var date:Date = new Date();
                this.statusBox.text = "loaded: " + this.currentRemoteName + "\n" + date.toTimeString().substr(0,8);
                this.statusBox.setTextFormat(this.format);
                // next local save must be a save-as
                this.currentFile = null;
                this.currentLocalName = "";
            } catch(e:Error) { // FIX: this is poor exception handling
                // handle error (e.g., if a null structure was read)
            }
        }
        
        private function translateMySQL(msg:String):String {
            return msg.slice(2, msg.length - 3);
        }
        
        // String parsing utils
        public function ltrim(s:String):String 
        {
            if ((s.length>1) || (s.length == 1 && s.charCodeAt(0)>32 && s.charCodeAt(0)<255)) {
                var i:int = 0;
                while (i<s.length && (s.charCodeAt(i)<=32 || s.charCodeAt(i)>=255)) {
                    i++;
                }
                s = s.substring(i);
            } else {
                s = "";
            }
            return s;
        }
        
        public function rtrim(s:String):String 
        {
            if ((s.length>1) || (s.length == 1 && s.charCodeAt(0)>32 && s.charCodeAt(0)<255)) {
               var i:int = s.length-1;
               while (i>=0 && (s.charCodeAt(i)<=32 || s.charCodeAt(i)>=255)) {
                    i--;
                }
                s = s.substring(0, i+1);
            } else {
                s = "";
            }
            return s;
        }
        
        public function trim(s:String):String 
        {
            return ltrim(rtrim(s));
        }
    }
}