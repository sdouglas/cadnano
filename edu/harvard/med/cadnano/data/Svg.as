//
//  Svg
//
//  Created by Adam on 2008-06-04.
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

package edu.harvard.med.cadnano.data {
    // cadnano
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.DrawVstrand;
    import edu.harvard.med.cadnano.drawing.handles.BreakpointHandle;
    import edu.harvard.med.cadnano.drawing.handles.CrossoverHandle;
    import edu.harvard.med.cadnano.Path;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.data.Token;
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.panel.DataTools;
    // utilities
    import br.com.stimuli.string.printf;
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    import com.adobe.utils.ArrayUtil;
    
    public class Svg {
        // caDNAno resources
        private var path:Path;
        private var drawPath:DrawPath;
        private var dataTools:DataTools;
        
        // capy static vars from other classes
        private var LEFT_5PRIME:String = BreakpointHandle.LEFT_5PRIME;
        private var RIGHT_5PRIME:String = BreakpointHandle.RIGHT_5PRIME;
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        // constant SVG string templates
        private static var individualStaplePathTemplate:String = "\n<path d=\"%(path)s\" id=\"staple_path_%(staple_path_number)s_\" stroke-width = \"%(stroke_width)s\" stroke=\"%(stroke)s\"/>";
        private static var staplePathsGroupTemplate:String = "\n<g id = \"Staple Paths\" fill=\"none\">\n%(allStaplePathsString)s\n</g>";
        private static var individualScaffoldPathTemplate:String = "\n <path d=\"%(path)s\" id=\"scaffold_path_%(scaffold_path_number)s_\" stroke-width = \"%(stroke_width)s\" stroke=\"%(stroke)s\"/>";
        private static var scaffoldPathsGroupTemplate:String = "<g id = \"Scaffold Paths\" fill=\"none\">\n%(allScaffoldPathsString)s\n</g>";
        private static var stapleBreakpointLayer:String = "\n<g id = \"Staple Breakpoints\" fill=\"none\">\n%(stapleBreaksString)s\n</g>";
        private static var scaffoldBreakpointLayer:String = "\n<g id = \"Scaffold Breakpoints\" fill=\"none\">\n%(scaffoldBreaksString)s\n</g>";
        private static var helixNumbersLayer:String = "\n<g id = \"Helix Numbers\" stroke=\"black\" font-size = \"18pt\" fill=\"black\">\n%(helixNumberLabels)s\n</g>";
        private static var subzoneNumbersLayer:String = "\n<g id = \"Subzone Numbers\" stroke=\"black\" font-size = \"18pt\" fill=\"black\">\n%(subzoneNumberLabels)s\n</g>";
        private static var ticksLayer:String = "\n<g id=\"Tick Marks\" stroke-width=\"0.25\" opacity=\"2\">\n%(ticksString)s\n</g>";
        private static var latticeSlicesLayer:String = "\n<g id=\"Lattice Slices\"> %(latticeSlicesString)s\n</g>";
        private static var loopsAndSkipsLayer:String = "\n<g id=\"Loops and Skips\"> %(dsSkipsString)s %(dsLoopsString)s %(scafLoopsString)s %(stapLoopsString)s\n</g>";
        private static var sequenceLayerScaf:String = "\n<g id=\"Scaf_Sequence\" font-family=\"Monaco\" font-size=\"11.1111\" letter-spacing=\"3.333\"> %(sequenceStringScaf)s\n</g>";
        private static var sequenceLayerStap:String = "\n<g id=\"Stap_Sequence\" font-family=\"Monaco\" font-size=\"11.1111\" letter-spacing=\"3.333\"> %(sequenceStringStap)s\n</g>";
        private static var sequencesLayer:String = "\n<g id=\"Sequences\"> %(bothSequenceStringGroups)s\n</g>";
        private static var overallSvgTemplate:String = "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" baseProfile=\"full\">\n<g id=\" %s \" transform=\"translate(0, -3.5) scale(0.9)\">\n%s\n</g>\n</svg>";
        
        // internal machinery
        private var stapleToScaffoldOffset = baseWidth*1; // use this to set the spacing between staple and scaffold... < 2.5 for no ambiguity
        private var currentStapleNumber = 0; // the number of staple paths written to the staple group string
        private var currentScaffoldNumber = 0; // the number of scaffold paths written to the scaffold group string
        private var vsList:Array;
        private var vsHash:Object;
        private var numHelices:int;
        private var endToken:Token;
        private var nextToken:Token;
        private var donorInternalCoords:Array;
        private var acceptorInternalCoords:Array;
        public var outputSequence:Boolean = true; // note: enabling this leads to much larger svg files
        
        // holders for substituting string data
        private var stapleSubstitutionObject: Object;
        private var stapleDataString:String;
        private var scaffoldSubstitutionObject;
        private var scaffoldDataString:String;
        private var stapleBreakpointSubstitutionObject;
        private var scaffoldBreakpointSubstitutionObject:Object;
        private var breakpointDataString:String;
        private var loopAndSkipSubstitutionObject:Object;
        private var loopsAndSkips:String;
        private var helixNumbersSubstitutionsObject:Object;
        private var helixNumbers:String;
        private var subzoneNumbersSubstitutionsObject:Object;
        private var subzoneNumbers:String;
        private var ticksSubstitutionObject:Object;
        private var ticks:String;
        private var sliceSubstitutionObject:Object;
        private var lattice:String;
        private var sequenceScaf:String;
        private var sequenceStap:String;
        private var sequenceSubstitutionObjectScaf:Object;
        private var sequenceSubstitutionObjectStap:Object;
        private var sequencesSubstitutionObject:Object;
        private var sequences:String;
        private var dataString:String;
        private var outputString:String;
        
        // collected SVG <path/> strings for staple and scaffold paths
        private var allStaplePathsString:String = "";
        private var allScaffoldPathsString:String = "";
        private var stapleBreaksString = "";
        private var scaffoldBreaksString = "";
        private var dsSkipsString = "";
        private var dsLoopsString = "";
        private var scafLoopsString = "";
        private var stapLoopsString = "";
        private var helixNumberLabelsString = "";
        private var subzoneNumberLabelsString = "";
        private var ticksString = "";
        private var latticeSlicesString = "";
        private var sequenceStringScaf = "";
        private var sequenceStringStap = "";
        
        // air
        import flash.filesystem.*;
        import flash.events.IOErrorEvent;
        import flash.events.Event;
        
        // file export
        private var currentFile:File = null;
        private var defaultDirectory:File = File.desktopDirectory.resolvePath("a.svg"); // user home directory is default

        
        // filestream for reading the current file
        private var stream:FileStream = new FileStream();
        
        // timing for debugging
        import flash.utils.getTimer;
        
        /*Construct a new Svg object*/
        public function Svg(drawPath:DrawPath, dataTools:DataTools) {
            this.drawPath = drawPath;
            this.dataTools = dataTools;
            this.path = this.drawPath.path;
        }
        
        /*Compute the full SVG output string and write it to a user-chosen file*/
        public function writeFullSVGOutput():void {
            
            if (this.path.vsList.size == 0){
                return;
            }
            
            // clear previously written output strings
            this.allStaplePathsString = "";
            this.allScaffoldPathsString = "";
            this.stapleBreaksString = "";
            this.scaffoldBreaksString = "";
            this.dsSkipsString = "";
            this.dsLoopsString = "";
            this.scafLoopsString = "";
            this.stapLoopsString = "";
            this.helixNumberLabelsString = "";
            this.subzoneNumberLabelsString = "";
            this.ticksString = "";
            this.latticeSlicesString = "";
            this.sequenceStringScaf = "";
            this.sequenceStringStap = "";
            
            // update structure info
            this.vsHash = this.path.vsHash;
            this.vsList = this.path.vsList.toArray();
            this.numHelices = this.vsList.length;
            
            // assign allStaplePathsString and allScaffoldPathsString
            this.writeHelixNumberText();
            this.writeSubzoneMarkerText();
            this.writeTickMarks();
            this.writeScaffoldPathsWithBreaks();
            this.writeScaffoldPathsWithoutBreaks();
            this.writeStaplePathsWithBreaks();
            this.writeStaplePathsWithoutBreaks();
            this.writeBreakpoints();
            this.writeSkips();
            this.writeDsLoops();
            this.writeSsLoops();
            this.writeSlices();
            if (this.outputSequence == true) {
                this.writeSequence();
            }
            this.refreshVisitedTokens();
            
            // write the file
            var fileChooser:File;
            if (currentFile) { // reuse filename
                fileChooser = currentFile;
            } else { // never saved
                if (this.dataTools.currentFile == null) { // json never saved
                    fileChooser = defaultDirectory; // default to a.svg
                } else {  // construct svg name based on saved json name
                    var pattern:RegExp = /\.json$/;
                    var svgFileName:String = this.dataTools.currentFile.name.replace(pattern, "");
                    fileChooser = this.dataTools.currentFile.parent.resolvePath(svgFileName + ".svg");
                }
            }
            
            fileChooser.browseForSave("Export SVG As");
            fileChooser.addEventListener(Event.SELECT, svgToolFileSelected);
        }
        
        private function svgToolFileSelected(event:Event):void {
            // hierarchically put together the final SVG output string
            stapleSubstitutionObject = {"allStaplePathsString":this.allStaplePathsString};
            stapleDataString = printf(Svg.staplePathsGroupTemplate, stapleSubstitutionObject);
            scaffoldSubstitutionObject = {"allScaffoldPathsString":this.allScaffoldPathsString}
            scaffoldDataString = printf(Svg.scaffoldPathsGroupTemplate, scaffoldSubstitutionObject);
            stapleBreakpointSubstitutionObject = {"stapleBreaksString": this.stapleBreaksString};
            scaffoldBreakpointSubstitutionObject ={"scaffoldBreaksString":this.scaffoldBreaksString};
            breakpointDataString = printf(Svg.stapleBreakpointLayer, stapleBreakpointSubstitutionObject) + printf(Svg.scaffoldBreakpointLayer, scaffoldBreakpointSubstitutionObject);
            loopAndSkipSubstitutionObject = {"dsSkipsString":this.dsSkipsString, "dsLoopsString":this.dsLoopsString, "scafLoopsString":this.scafLoopsString, "stapLoopsString":this.stapLoopsString};
            loopsAndSkips = printf(Svg.loopsAndSkipsLayer, loopAndSkipSubstitutionObject);
            helixNumbersSubstitutionsObject = {"helixNumberLabels": this.helixNumberLabelsString};
            helixNumbers = printf(Svg.helixNumbersLayer, helixNumbersSubstitutionsObject);
            subzoneNumbersSubstitutionsObject = {"subzoneNumberLabels": this.subzoneNumberLabelsString};
            subzoneNumbers = printf(Svg.subzoneNumbersLayer, subzoneNumbersSubstitutionsObject);
            ticksSubstitutionObject = {"ticksString":this.ticksString};
            ticks = printf(Svg.ticksLayer, ticksSubstitutionObject);
            sliceSubstitutionObject = {"latticeSlicesString": this.latticeSlicesString};
            lattice = printf(Svg.latticeSlicesLayer, sliceSubstitutionObject);
            sequenceSubstitutionObjectScaf = {"sequenceStringScaf":this.sequenceStringScaf};
            sequenceSubstitutionObjectStap = {"sequenceStringStap":this.sequenceStringStap};
            sequenceScaf = printf(Svg.sequenceLayerScaf, sequenceSubstitutionObjectScaf);
            sequenceStap = printf(Svg.sequenceLayerStap, sequenceSubstitutionObjectStap);
            sequencesSubstitutionObject = {"bothSequenceStringGroups": sequenceScaf + "\n" + sequenceStap}
            sequences = printf(Svg.sequencesLayer, sequencesSubstitutionObject)
            // elements that come first in dataString are on the bottom of the display heirarchy
            dataString = helixNumbers + subzoneNumbers + ticks + scaffoldDataString + stapleDataString + breakpointDataString + loopsAndSkips + lattice + sequences;
            
            // get the structure name from dataTools
            var name:String = "caDNAno";
            
            outputString = printf(Svg.overallSvgTemplate, name, dataString);
            
            // set up the file
            currentFile = event.target as File;
            currentFile.removeEventListener(Event.SELECT, svgToolFileSelected);
            
            if (stream != null) {
                stream.close();
            }
            stream = new FileStream();
            stream.openAsync(currentFile, FileMode.WRITE);
            stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
            stream.writeUTFBytes(outputString);
            stream.close();
        }
        
        private function writeIOErrorHandler(event:Event):void {
            trace("There was an error writing the file.");
        }
        
        /*Add unbroken scaffold paths to this.allScaffoldPathsString*/
        private function writeScaffoldPathsWithoutBreaks():void {
            // first collect all circular scaffold paths
            var circularScaffoldPath:Array;
            var vs:Vstrand;
            var helixNum:int = 0;
            var pos:int;
            var horiz_len:int;
            var scafToken:Token;
            var scaffoldPathString:String;
            var stringSubstitutionObject:Object;
            var color:String;
            var drawVstrand:DrawVstrand;
            var internalCoords:Array;
            for (var i:int = 0; i < this.numHelices; i++) {
                vs = this.vsList[i];
                horiz_len = vs.scaf.length;
                for (var j:int = 0; j < horiz_len; j++) {
                    pos = j;
                    scafToken = vs.scaf[pos];
                    if ( (scafToken.visited == false) && 
                         (scafToken.prev_strand != -1) && 
                         (scafToken.prev_pos != -1) && 
                         (scafToken.next_strand != -1) && 
                         (scafToken.next_pos != -1)) { // ignore the edges of the diagram
                        // if we're starting at a crossover, shift away
                        internalCoords = this.getInternalCoordsOfScaffoldToken(scafToken);
                        drawVstrand = this.vsHash[internalCoords[0]].drawVstrand;
                        while ((drawVstrand.getScafCrossoverAtPos(pos) != null) && (scafToken.visited == false)) {
                            internalCoords = [scafToken.next_strand, scafToken.next_pos];
                            scafToken = this.getNextScaffoldToken(scafToken);
                            vs = this.vsHash[internalCoords[0]];
                            drawVstrand = this.vsHash[internalCoords[0]].drawVstrand;
                            pos = internalCoords[1];
                        }
                        circularScaffoldPath = new Array();
                        var k:int = 0;
                        while(scafToken.visited == false) { // until we get back to the beginning
                            scafToken.visited = true;
                            circularScaffoldPath.push(scafToken);
                            scafToken = this.getNextScaffoldToken(scafToken);
                        }
                        // do it one more time to seal up
                        scafToken.visited = true;
                        circularScaffoldPath.push(scafToken);
                        
                        // now write the circular scaffold path to svg
                        var len:int;
                        scafToken = circularScaffoldPath[0];
                        len = circularScaffoldPath.length;
                        this.endToken = circularScaffoldPath[len - 1];
                        scaffoldPathString = printf(" M %s %s ", this.getScaffoldTokenSVGCoords(scafToken)[0] + this.getScaffoldTokenSVGCoordOffset(scafToken), this.getScaffoldTokenSVGCoords(scafToken)[1]);
                        for each(scafToken in circularScaffoldPath) {
                             // internal tokens and coordinates
                            this.nextToken = this.getNextScaffoldToken(scafToken);
                            this.donorInternalCoords = [vs.number, pos];
                            this.acceptorInternalCoords = [scafToken.next_strand, scafToken.next_pos];
                            vs = this.vsHash[this.acceptorInternalCoords[0]];
                            pos = this.acceptorInternalCoords[1];
                            
                            //  don't return anything unless we are at a salient point
                            var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]);
                            if (this.nextToken != null) {
                                scaffoldPathString += this.writeNextScaffoldPathPortion(scafToken);
                            }
                        }
                        color = "#0066cc";
                        stringSubstitutionObject = {"path":scaffoldPathString, "scaffold_path_number":((++this.currentScaffoldNumber).toString()),"stroke_width":"2", "stroke":color};
                        this.allScaffoldPathsString += printf(Svg.individualScaffoldPathTemplate, stringSubstitutionObject);
                    }
                }
            }
        }
        
        /*Add broken scaffold paths to this.allScaffoldPathsString*/
        private function writeScaffoldPathsWithBreaks():void {
            this.endToken == null;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var scaf5pBreaks:Array = new Array();
            var scafToken:Token;
            var vs:Vstrand;
            var pos:int;
            var scaffoldPathString:String;
            var stringSubstitutionObject:Object;
            var color:String; // hex color string
            // collect 5' scaffold ends
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                for each (bp in vs.drawVstrand.scafbreaks) {
                    if (bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME) {
                        scaf5pBreaks.push(bp);
                    }
                }
            }
            for each (var bp in scaf5pBreaks) {
                var initial_shift:Number;
                if (bp.vstrand.number % 2 == 1) {
                    initial_shift = -halfbaseWidth/2;
                } else {
                    initial_shift = halfbaseWidth/2;
                }
                // start position
                scafToken = bp.vstrand.scaf[bp.pos];
                scaffoldPathString = printf(" M %s %s ", bp.x + this.getScaffoldTokenSVGCoordOffset(scafToken) + initial_shift, bp.y + bp.vstrand.drawVstrand.y  - (bp.vstrand.number%2)*baseWidth);
                pos = this.getInternalCoordsOfScaffoldToken(scafToken)[1];
                vs = this.vsHash[this.getInternalCoordsOfScaffoldToken(scafToken)[0]];
                var i:int = 0;
                while(scafToken.next_strand != -1) {
                    // internal tokens and coordinates
                    this.nextToken = this.getNextScaffoldToken(scafToken);
                    this.donorInternalCoords = [vs.number, pos];
                    this.acceptorInternalCoords = [scafToken.next_strand, scafToken.next_pos];
                    //  don't return anything unless we are at a salient point
                    var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]);
                    if ((this.nextToken != null) && ((this.donorInternalCoords[0] != this.acceptorInternalCoords[0]) || (this.nextToken.next_strand == -1) || (this.nextToken == this.endToken) || (Math.abs(diff) >= 2))) {
                        scaffoldPathString += this.writeNextScaffoldPathPortion(scafToken);
                    }
                    i++;
                    // prepare for the next iteration
                    scafToken.visited = true;
                    scafToken = this.nextToken;
                    pos = this.acceptorInternalCoords[1];
                    vs = this.vsHash[this.acceptorInternalCoords[0]];
                }
                // do it one more time
                
                // internal tokens and coordinates
                this.nextToken = this.getNextScaffoldToken(scafToken);
                this.donorInternalCoords = getInternalCoordsOfScaffoldToken(scafToken);

                if ((this.nextToken != null) && (this.nextToken.next_strand == -1)) {
                    scaffoldPathString += this.writeNextScaffoldPathPortion(scafToken);
                }
                scafToken.visited = true;
                color = "#0066cc";
                
                stringSubstitutionObject = {"path":scaffoldPathString, "scaffold_path_number":((++this.currentScaffoldNumber).toString()),"stroke_width":"2", "stroke":color};
                this.allScaffoldPathsString += printf(Svg.individualScaffoldPathTemplate, stringSubstitutionObject);
            }
        }
        
        /*Add unbroken staple paths to this.allStaplePathsString*/
        private function writeStaplePathsWithoutBreaks():void {
            // first collect all circular Staple paths
            var circularStaplePath:Array;
            var vs:Vstrand;
            var helixNum:int = 0;
            var pos:int;
            var horiz_len:int;
            var stapToken:Token;
            var staplePathString:String;
            var stringSubstitutionObject:Object;
            var color:String;
            var drawVstrand:DrawVstrand;
            var internalCoords:Array;
            for (var i:int = 0; i < this.numHelices; i++) {
                vs = this.vsList[i];
                horiz_len = vs.stap.length;
                for (var j:int = 0; j < horiz_len; j++) {
                    pos = j;
                    stapToken = vs.stap[pos];
                    if ( (stapToken.visited == false) && (stapToken.prev_strand != -1) && (stapToken.prev_pos != -1) && (stapToken.next_strand != -1) && (stapToken.next_pos != -1)) { // ignore the edges of the diagram
                        // if we're starting at a crossover, shift away
                        internalCoords = this.getInternalCoordsOfStapleToken(stapToken);
                        drawVstrand = this.vsHash[internalCoords[0]].drawVstrand;
                        while ((drawVstrand.getStapCrossoverAtPos(pos) != null) && (stapToken.visited == false)) {
                            internalCoords = [stapToken.next_strand, stapToken.next_pos];
                            stapToken = this.getNextStapleToken(stapToken);
                            drawVstrand = this.vsHash[internalCoords[0]].drawVstrand;
                            pos = internalCoords[1];
                        }
                        circularStaplePath = new Array();
                        var k:int = 0;
                        while(stapToken.visited == false) { // until we get back to the beginning
                            stapToken.visited = true;
                            circularStaplePath.push(stapToken);
                            stapToken = this.getNextStapleToken(stapToken);
                        }
                        // do it one more time to seal up
                        stapToken.visited = true;
                        circularStaplePath.push(stapToken);
                        
                        // now write the circular Staple path to svg
                        var len:int;
                        stapToken = circularStaplePath[0];
                        len = circularStaplePath.length;
                        this.endToken = circularStaplePath[len - 1];
                        staplePathString = printf(" M %s %s ", this.getStapleTokenSVGCoords(stapToken)[0] + getStapleTokenSVGCoordOffset(stapToken), this.getStapleTokenSVGCoords(stapToken)[1]);
                        for each(stapToken in circularStaplePath) {
                             // internal tokens and coordinates
                            this.nextToken = this.getNextStapleToken(stapToken);
                            this.donorInternalCoords = [vs.number, pos];
                            this.acceptorInternalCoords = [stapToken.next_strand, stapToken.next_pos];
                            vs = this.vsHash[this.acceptorInternalCoords[0]];
                            pos = this.acceptorInternalCoords[1];

                            //  don't return anything unless we are at a salient point
                            var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]);
                            if ((this.nextToken != null) && ((this.donorInternalCoords[0] != this.acceptorInternalCoords[0]) || (this.nextToken.next_strand == -1) || (this.nextToken == this.endToken) || (Math.abs(diff) >= 2))) {
                                staplePathString += this.writeNextStaplePathPortion(stapToken);
                            }
                        }
                        color = "#888888";
                        stringSubstitutionObject = {"path":staplePathString, "staple_path_number":((++this.currentStapleNumber).toString()),"stroke_width":"1", "stroke":color};
                        this.allStaplePathsString += printf(Svg.individualStaplePathTemplate, stringSubstitutionObject);
                    }
                }
            }
        }
        
        /*Add broken staple paths to this.allstaplePathsString*/
        private function writeStaplePathsWithBreaks():void {
            this.endToken == null;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var stap5pBreaks:Array = new Array();
            var stapToken:Token;
            var vs:Vstrand;
            var pos:int;
            var staplePathString:String;
            var stringSubstitutionObject:Object;
            var color:String; // hex color string
            // collect 5' staple ends
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                for each (bp in vs.drawVstrand.stapbreaks) {
                    if (bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME) {
                        stap5pBreaks.push(bp);
                    }
                }
            }
            for each (var bp in stap5pBreaks) {
                // start position
                stapToken = bp.vstrand.stap[bp.pos];
                var initial_shift:Number;
                if (bp.vstrand.number % 2 == 0) {
                    initial_shift = -halfbaseWidth/2;
                } else {
                    initial_shift = halfbaseWidth/2;
                }
                staplePathString = printf(" M %s %s ", bp.x + getStapleTokenSVGCoordOffset(stapToken) + initial_shift, bp.y + bp.vstrand.drawVstrand.y + this.getStapleToScaffoldSVGCoordOffset(bp.vstrand.number));
                pos = this.getInternalCoordsOfStapleToken(stapToken)[1];
                vs = this.vsHash[this.getInternalCoordsOfStapleToken(stapToken)[0]];
                var i:int = 0;
                while(stapToken.next_strand != -1) {
                    // internal tokens and coordinates
                    this.nextToken = this.getNextStapleToken(stapToken);
                    this.donorInternalCoords = [vs.number, pos];
                    this.acceptorInternalCoords = [stapToken.next_strand, stapToken.next_pos];
                    
                    //  don't return anything unless we are at a salient point
                    var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]);
                    if ((this.nextToken != null) && ((this.donorInternalCoords[0] != this.acceptorInternalCoords[0]) || (this.nextToken.next_strand == -1) || (this.nextToken == this.endToken) || (Math.abs(diff) >= 2))) {
                        staplePathString += this.writeNextStaplePathPortion(stapToken);
                    }
                    // prepare for the next iteration
                    stapToken.visited = true;
                    stapToken = this.nextToken;
                    pos = this.acceptorInternalCoords[1];
                    vs = this.vsHash[this.acceptorInternalCoords[0]];
                }
                // do it one more time
                
                // internal tokens and coordinates
                this.nextToken = this.getNextStapleToken(stapToken);
                this.donorInternalCoords = getInternalCoordsOfStapleToken(stapToken);
                
                if ((this.nextToken != null) && (this.nextToken.next_strand == -1)) {
                    staplePathString += this.writeNextStaplePathPortion(stapToken);
                }
                stapToken.visited = true;
                color = this.drawPath.getHexColorString(bp.color);
                
                stringSubstitutionObject = {"path":staplePathString, "staple_path_number":((++this.currentStapleNumber).toString()),"stroke_width":"1", "stroke":color};
                this.allStaplePathsString += printf(Svg.individualStaplePathTemplate, stringSubstitutionObject);
            }
        }
        
        /*Choose what text, if any, to add to the svg string for a single scaffold path,
        when token is hit as the path is being traversed.*/
        private function writeNextStaplePathPortion(token:Token):String {
            
            // svg coordinates
            var start_x_coord:int = this.getStapleTokenSVGCoords(token)[0];
            var start_y_coord:int = this.getStapleTokenSVGCoords(token)[1];
            var end_x_coord:int;
            var end_y_coord:int;
            if (this.nextToken != null) { 
                end_x_coord = this.getStapleTokenSVGCoords(this.nextToken)[0];
                end_y_coord = this.getStapleTokenSVGCoords(this.nextToken)[1];
            } else { // we won't return anything when we are AT a breakpoint
                return "";
            }
            
            // svg coordinates of control points
            var xc:Number = 0.04; // control.x constant
            var yc:Number = 0.04; // control.y constant
            var control_x:Number;
            var control_y:Number;
            var coeff:int;
            var donor_shift:int;
            var acceptor_shift:int;
            
            // for drawing crossovers
            var spline_string:String;
            // for drawing segments of vstrand
            var line_string:String;
            
            // crossover handles
            var donorHandle:CrossoverHandle = this.vsHash[this.donorInternalCoords[0]].drawVstrand.getStapCrossoverAtPos(this.donorInternalCoords[1]);
            var neighbor:CrossoverHandle = this.vsHash[this.acceptorInternalCoords[0]].drawVstrand.getStapCrossoverAtPos(this.acceptorInternalCoords[1]);
            if (neighbor == null) { // no crossover, so either breakpoint or sealup of circular path, or a routine base
                if (this.nextToken.next_strand == -1) { // breakpoint 
                    var final_shift:Number;
                    if (acceptorInternalCoords[0] % 2 == 1) {
                        final_shift = -halfbaseWidth;
                    } else {
                        final_shift = halfbaseWidth;
                    }
                    // connect through the breakpoint
                    line_string = printf("L %s %s", this.getStapleBreakpointHandleSVGCoords(this.nextToken)[0] + (this.acceptorInternalCoords[0]%2)*baseWidth + final_shift, this.getStapleBreakpointHandleSVGCoords(this.nextToken)[1]);
                    return line_string;
                } else if (this.nextToken == this.endToken) { // seal up a circular path
                    line_string = printf("L %s %s", this.getStapleTokenSVGCoords(this.nextToken)[0], this.getStapleTokenSVGCoords(this.nextToken)[1]);
                    return line_string; // need to give a return value
                } else { // hold off on drawing anything until a salient point is reached (e.g., breakpoint, crossover, seal-up point for circular path...)
                    return "";
                }
            } else if (donorHandle != null) { // there is a crossover, but possibly a non-standard one or one to the same helix
                if (this.donorInternalCoords[0] == this.acceptorInternalCoords[0]) { // same strand
                    var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]); // compute absolute difference in base position along the SINGLE vstrand involved 
                    if (Math.abs(diff) >= 2 && (this.donorInternalCoords[0] == this.acceptorInternalCoords[0])) { // "crossover" to same helix
                      if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) {
                            start_x_coord += baseWidth - 3;
                        } else {
                            start_x_coord += 3;
                        }
                        if ((neighbor.type == CrossoverHandle.LEFT_UP) || (neighbor.type == CrossoverHandle.LEFT_DOWN)) {
                          end_x_coord += baseWidth - 3;
                        } else {
                          end_x_coord += 3;
                        }
                        if (donorHandle.type == CrossoverHandle.LEFT_UP || donorHandle.type == CrossoverHandle.RIGHT_UP) { // need correct shift
                            coeff = -1;
                        } else {
                            coeff = 1;
                        }
                        control_y = start_y_coord + coeff*yc*Math.abs(end_x_coord-start_x_coord);
                        control_x = (start_x_coord + end_x_coord)*0.5;
                        spline_string = printf("L %s %s Q %s,%s %s,%s", (start_x_coord).toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), (end_x_coord).toString(), end_y_coord.toString());
                        return spline_string;
                    } else {
                        return "";
                    }
                } else if ((this.donorInternalCoords[0]%2 == this.acceptorInternalCoords[0]%2) && (this.donorInternalCoords[0] != this.acceptorInternalCoords[0])) { // same parity
                    if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) {
                        start_x_coord += baseWidth - 3;
                    } else {
                        start_x_coord += 3;
                    }
                    if ((neighbor.type == CrossoverHandle.LEFT_UP) || (neighbor.type == CrossoverHandle.LEFT_DOWN)) {
                        end_x_coord += baseWidth - 3;
                    } else {
                        end_x_coord += 3;
                    }
                    if (this.donorInternalCoords[0] < this.acceptorInternalCoords[0]) {
                        control_x = start_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                    } else {
                        control_x = end_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                    }
                    control_y = (start_y_coord + end_y_coord)*0.5;
                    spline_string = printf("L %s %s Q %s,%s %s,%s", start_x_coord.toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), end_x_coord.toString(), end_y_coord.toString());
                    return spline_string;
                } else if (this.donorInternalCoords[0]%2 != this.acceptorInternalCoords[0]%2) { // default case
                     // determine if it is a left or right crossover
                     if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) { // left-hand crossover
                         // get the right control point
                         start_x_coord += baseWidth - 3;
                         end_x_coord += baseWidth - 3;
                         xc = -xc;
                     } else { // right-hand crossover
                         // get the right control point
                         start_x_coord += 3;
                         end_x_coord += 3;
                     }
                     if (this.donorInternalCoords[0]%2 == 0) {
                         control_x = start_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                     } else {
                         control_x = end_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                     }
                     control_y = (start_y_coord + end_y_coord)*0.5;
                     spline_string = printf("L %s %s Q %s,%s %s,%s", start_x_coord.toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), end_x_coord.toString(), end_y_coord.toString());
                     return spline_string;
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }
        
        /*Choose what text, if any, to add to the svg string for a single scaffold path,
        when token is hit as the path is being traversed.*/
        private function writeNextScaffoldPathPortion(token:Token):String {
            
            // svg coordinates
            var start_x_coord:int = this.getScaffoldTokenSVGCoords(token)[0];
            var start_y_coord:int = this.getScaffoldTokenSVGCoords(token)[1];
            var end_x_coord:int = this.getScaffoldTokenSVGCoords(this.nextToken)[0];
            var end_y_coord:int = this.getScaffoldTokenSVGCoords(this.nextToken)[1];
            
            // svg coordinates of control points
            var xc:Number = 0.02; // control.x constant
            var yc:Number = 0.04; // control.y constant
            var control_x:Number;
            var control_y:Number;
            var coeff:int;
            
            // for drawing crossovers
            var spline_string:String;
            // for drawing segments of vstrand
            var line_string:String;
            
            // crossover handles
            var donorHandle:CrossoverHandle = this.vsHash[this.donorInternalCoords[0]].drawVstrand.getScafCrossoverAtPos(this.donorInternalCoords[1]);
            var neighbor:CrossoverHandle = this.vsHash[this.acceptorInternalCoords[0]].drawVstrand.getScafCrossoverAtPos(this.acceptorInternalCoords[1]);
            if (neighbor == null) { // no crossover, so either breakpoint or sealup of circular path, or a routine base
                if (this.nextToken.next_strand == -1) { // breakpoint 
                    var final_shift:Number;
                    if (acceptorInternalCoords[0] % 2 == 0) {
                        final_shift = -halfbaseWidth;
                    } else {
                        final_shift = halfbaseWidth;
                    }
                    // connect through the breakpoint
                    line_string = printf("L %s %s", this.getScaffoldBreakpointHandleSVGCoords(this.nextToken)[0] + final_shift + ((this.acceptorInternalCoords[0]+1)%2)*baseWidth, this.getScaffoldBreakpointHandleSVGCoords(this.nextToken)[1] - (this.acceptorInternalCoords[0]%2)*baseWidth);
                    return line_string;
                } else if (this.nextToken == this.endToken) { // seal up a circular path
                    //trace(this.getInternalCoordsOfScaffoldToken(this.endToken));
                    line_string = printf("L %s %s", this.getScaffoldTokenSVGCoords(this.nextToken)[0] + this.getScaffoldTokenSVGCoordOffset(this.nextToken), this.getScaffoldTokenSVGCoords(this.nextToken)[1]);
                    return line_string; // need to give a return value
                } else { //don't return anything unless we are at a salient point
                    return "";
                }
            } else if (donorHandle != null) { // there is a crossover, but possibly a non-standard one or one to the same helix
                if (this.donorInternalCoords[0] == this.acceptorInternalCoords[0]) { // same strand
                    var diff:int = (this.donorInternalCoords[1] - this.acceptorInternalCoords[1]); // compute absolute difference in base position along the SINGLE vstrand involved 
                    if (Math.abs(diff) >= 2 && (this.donorInternalCoords[0] == this.acceptorInternalCoords[0])) { // "crossover" to same helix
                        if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) {
                            start_x_coord += baseWidth - 3;
                        } else {
                            start_x_coord += 3;
                        }
                        if ((neighbor.type == CrossoverHandle.LEFT_UP) || (neighbor.type == CrossoverHandle.LEFT_DOWN)) {
                          end_x_coord += baseWidth - 3;
                        } else {
                          end_x_coord += 3;
                        }
                        if (donorHandle.type == CrossoverHandle.LEFT_UP || donorHandle.type == CrossoverHandle.RIGHT_UP) { // need correct shift
                            coeff = -1;
                        } else {
                            coeff = 1;
                        }
                        control_y = start_y_coord + coeff*yc*Math.abs(end_x_coord-start_x_coord);
                        control_x = (start_x_coord + end_x_coord)*0.5;
                        spline_string = printf("L %s %s Q %s,%s %s,%s", (start_x_coord).toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), (end_x_coord).toString(), end_y_coord.toString());
                        return spline_string;
                    } else {
                        return "";
                    }
                } else if ((this.donorInternalCoords[0]%2 == this.acceptorInternalCoords[0]%2) && (this.donorInternalCoords[0] != this.acceptorInternalCoords[0])) { // same parity
                      if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) {
                          start_x_coord += baseWidth - 3;
                      } else {
                          start_x_coord += 3;
                      }
                      if ((neighbor.type == CrossoverHandle.LEFT_UP) || (neighbor.type == CrossoverHandle.LEFT_DOWN)) {
                        end_x_coord += baseWidth - 3;
                      } else {
                        end_x_coord += 3;
                      }
                      if (this.donorInternalCoords[0] < this.acceptorInternalCoords[0]) {
                          control_x = start_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                      } else {
                          control_x = end_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                      }
                      control_y = (start_y_coord + end_y_coord)*0.5;
                      spline_string = printf("L %s %s Q %s,%s %s,%s", start_x_coord.toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), end_x_coord.toString(), end_y_coord.toString());
                      return spline_string;
                } else if (this.donorInternalCoords[0]%2 != this.acceptorInternalCoords[0]%2) { // default case
                     // determine if it is a left or right crossover
                     if ((donorHandle.type == CrossoverHandle.LEFT_UP) || (donorHandle.type == CrossoverHandle.LEFT_DOWN)) { // left-hand crossover
                         // get the right control point
                         start_x_coord += baseWidth - 3;
                         end_x_coord += baseWidth - 3;
                        xc = -xc;
                     } else { // right-hand crossover
                         // get the right control point
                         start_x_coord += 3;
                         end_x_coord += 3;
                     }
                     if (this.donorInternalCoords[0]%2 == 0) {
                         control_x = start_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                     } else {
                         control_x = end_x_coord + xc*Math.abs(end_y_coord - start_y_coord);
                     }
                     control_y = (start_y_coord + end_y_coord)*0.5;
                     spline_string = printf("L %s %s Q %s,%s %s,%s", start_x_coord.toString(), start_y_coord.toString(), control_x.toString(), control_y.toString(), end_x_coord.toString(), end_y_coord.toString());
                     return spline_string;
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }
        
        private function writeBreakpoints():void {
            var vs:Vstrand;
            var bp:BreakpointHandle;
            for (var i:int = 0; i < this.numHelices; i++) {
                vs = this.vsList[i];
                for each (bp in vs.drawVstrand.stapbreaks) {
                    if (!(bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME)) {
                        this.stapleBreaksString += writeBreakpoint(bp);
                    }
                }
                for each (bp in vs.drawVstrand.scafbreaks) {
                    if (!(bp.type == LEFT_5PRIME || bp.type == RIGHT_5PRIME)) {
                        this.scaffoldBreaksString += writeBreakpoint(bp);
                    }
                }
            }
        }
        
        private function writeBreakpoint(breakpointHandle:BreakpointHandle):String {
            var left_arrow_string:String = "\n<g name = \"staple breakpoint\">\n<polygon fill=\"%s\" points=\"%s, %s %s %s %s %s\"/>\n</g>";
            var right_arrow_string:String = "\n<g name = \"staple breakpoint\">\n<polygon fill=\"%s\" points=\"%s, %s %s %s %s %s\"/>\n</g>"
            var x:int = breakpointHandle.x;
            var y:int = breakpointHandle.y + breakpointHandle.vstrand.drawVstrand.y;
            var shift:int;
            var baseWidth:int = 0.75*this.baseWidth;
            if (breakpointHandle.strandType == BreakpointHandle.SCAFFOLD) {
                // create a space between broken scaffold paths
                if (breakpointHandle.vstrand.number % 2 == 0) {
                    shift = -2.5;
                } else {
                    shift = 2.5;
                }
                x += shift;
                y -= (breakpointHandle.vstrand.number % 2)*this.baseWidth;
                if (breakpointHandle.vstrand.number % 2 == 0) {
                    x += this.baseWidth;
                    return printf(right_arrow_string, "#0066cc", x-1*baseWidth, y-0.5*baseWidth, x, y+0.5*baseWidth-0.5*baseWidth, x-1*baseWidth, y+1*baseWidth-0.5*baseWidth);
                } else {
                    return printf(left_arrow_string, "#0066cc", x+1*baseWidth, y-0.5*baseWidth, x, y+0.5*baseWidth-0.5*baseWidth,x+1*baseWidth, y+1*baseWidth-0.5*baseWidth);
                }
            } else if (breakpointHandle.strandType == BreakpointHandle.STAPLE) {
                // create a space between broken staple paths
                if (breakpointHandle.vstrand.number % 2 == 1) {
                    shift = -2.5;
                } else {
                    shift = 2.5;
                }
                x = x + this.baseWidth*(breakpointHandle.vstrand.number % 2) + shift;
                y = y + this.getStapleToScaffoldSVGCoordOffset(breakpointHandle.vstrand.number);
                if (breakpointHandle.vstrand.number % 2 == 0) {
                    return printf(left_arrow_string, drawPath.getHexColorString(breakpointHandle.color), x+1*baseWidth, y-0.5*baseWidth, x, y+0.5*baseWidth-0.5*baseWidth,x+1*baseWidth, y+1*baseWidth-0.5*baseWidth);
                } else {
                    return printf(right_arrow_string, drawPath.getHexColorString(breakpointHandle.color), x-1*baseWidth, y-0.5*baseWidth, x, y+0.5*baseWidth-0.5*baseWidth, x-1*baseWidth, y+1*baseWidth-0.5*baseWidth);
                }
            } else {
                return "";
            }
        }
        
        private function writeSkips():void {
            var skipMarkerTemplate:String = "\n<g><line fill=\"none\" stroke=\"#CC0000\" stroke-width=\"1\" stroke-linecap=\"round\" x1=\"%s\" y1=\"%s\" x2=\"%s\" y2 =\"%s\"/><line fill=\"none\" stroke=\"#CC0000\" stroke-width=\"1\" stroke-linecap=\"round\" x1=\"%s\" y1=\"%s\" x2=\"%s\" y2=\"%s\"/></g>";
            var vs:Vstrand;
            var skip:Array;
            var len:int;
            var pos:int;
            var xctr:Number;
            var yctr:Number;
            for each(vs in this.vsList) {
                skip = vs.skip;
                len = vs.skip.length;
                for (pos = 0; pos < len; pos++) {
                    if (skip[pos] != 0) {
                        xctr = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[0] + baseWidth/2;
                        yctr = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[1];
                        this.dsSkipsString += printf(skipMarkerTemplate, xctr - baseWidth/2, yctr - baseWidth/2, xctr + baseWidth/2, yctr + baseWidth/2, xctr - baseWidth/2, yctr + baseWidth/2, xctr + baseWidth/2, yctr - baseWidth/2); 
                    }
                }
            }
        }
        
        private function writeDsLoops():void {
            // double-stranded loops drawn with stroke = 2, whereas single-stranded loops have stroke = 1
            var loopTemplateUpright:String = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,1.2)\"><g transform = \"scale(1,1.05)\"><path fill=\"#FFFFFF\" stroke=\"%s\" stroke-width=\"0.5\" d=\"M-0.007-2.221c0,0-6.011-6.438,0-6.438C6.118-8.66-0.007-2.221-0.007-2.221z\"/></g><path fill=\"none\" stroke=\"#3366CC\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,-5)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            var loopTemplateReflected:String = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,-1.2) \"><g transform = \"scale(1,1.05)\"><path fill=\"#FFFFFF\" stroke=\"%s\" stroke-width=\"0.5\" d=\"M-0.007-2.221c0,0-6.011-6.438,0-6.438C6.118-8.66-0.007-2.221-0.007-2.221z\"/></g><path fill=\"none\" stroke=\"#3366CC\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,10)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            var loopTemplate:String;
            var vs:Vstrand;
            var loop:Array;
            var len:int;
            var pos:int;
            var xbase:Number;
            var ybase:Number;
            var shift:Number = 0;
            var textShift:Number = 0;
            var color:uint;
            for each(vs in this.vsList) {
                loop = vs.loop;
                len = vs.loop.length;
                for (pos = 0; pos < len; pos++) {
                    if (loop[pos] != 0) {
                        if (vs.number % 2 == 0) {
                            shift = 2*baseWidth/3;
                            loopTemplate = loopTemplateUpright;
                        } else {
                            shift = baseWidth/3;
                            loopTemplate = loopTemplateReflected;
                        }
                        if (loop[pos] >= 10) {
                            textShift = -4;
                        } else {
                            textShift = -2;
                        }
                        xbase = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[0] + shift;
                        ybase = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[1];
                        color = this.getStapleToken([vs.number, pos]).color;
                        this.dsLoopsString += printf(loopTemplate, xbase, ybase, drawPath.getHexColorString(color) , textShift, loop[pos]);
                    }
                }
            }
        }
        
        private function writeSsLoops():void {
            // staple ss loops
            var loopTemplateUpright:String = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,1.2)\"><path fill=\"none\" stroke=\"%s\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,-5)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            var loopTemplateReflected:String = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,-1.2)\"><path fill=\"none\" stroke=\"%s\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,9)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            var loopTemplate:String;
            var vs:Vstrand;
            var loop:Array;
            var len:int;
            var pos:int;
            var xbase:Number;
            var ybase:Number;
            var shift:Number;
            var textShift:Number;
            var color:uint;
            for each(vs in this.vsList) {
                loop = vs.stapLoop;
                len = loop.length;
                for (pos = 0; pos < len; pos++) {
                    if (loop[pos] != 0) {
                        if (vs.number % 2 == 1) {
                            shift = 2*baseWidth/3;
                            loopTemplate = loopTemplateUpright;
                        } else {
                            shift = baseWidth/3;
                            loopTemplate = loopTemplateReflected;
                        }
                        if (loop[pos] >= 10) {
                            textShift = -4;
                        } else {
                            textShift = -2;
                        }
                        xbase = this.getStapleTokenSVGCoords(this.getStapleToken([vs.number, pos]))[0] + shift;
                        ybase = this.getStapleTokenSVGCoords(this.getStapleToken([vs.number, pos]))[1];
                        color = this.getStapleToken([vs.number, pos]).color;
                        this.stapLoopsString += printf(loopTemplate, xbase, ybase, drawPath.getHexColorString(color), textShift, loop[pos]);
                    }
                }
            }
            // scaffold ss loops
            loopTemplateUpright = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,1.2)\"><path fill=\"none\" stroke=\"#3366CC\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,-5)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            loopTemplateReflected = "\n<g transform = \"translate(%s, %s)\">\n<g transform = \"scale(1,-1.2)\"><path fill=\"none\" stroke=\"#3366CC\" stroke-width=\"0.5\" d=\"M-0.007-0.472c0,0-9.562-9.536,0-9.536C9.556-10.007-0.007-0.472-0.007-0.472z\"/></g>\n<text transform=\"translate(%s,9)\" fill=\"#CC6600\" font-family=\"'Verdana'\" font-size=\"7\">%s</text>\n</g>";
            for each(vs in this.vsList) {
                loop = vs.scafLoop;
                len = loop.length;
                for (pos = 0; pos < len; pos++) {
                    if (loop[pos] != 0) {
                        if (vs.number % 2 == 0) {
                            shift = 2*baseWidth/3;
                            loopTemplate = loopTemplateUpright;
                        } else {
                            shift = baseWidth/3;
                            loopTemplate = loopTemplateReflected;
                        }
                        if (loop[pos] >= 10) {
                            textShift = -4;
                        } else {
                            textShift = -2;
                        }
                        xbase = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[0] + shift;
                        ybase = this.getScaffoldTokenSVGCoords(this.getScaffoldToken([vs.number, pos]))[1];
                        this.scafLoopsString += printf(loopTemplate, xbase, ybase, textShift, loop[pos]);
                    }
                }
            }
        }
        
        private function writeSequence():void {
            var horizTemplate:String = "\n<text transform=\"translate(%s,%s) scale(%s)\"  fill=\"%s\">%s</text>";
            var vs:Vstrand;
            var pos,i:int;
            var scafLen:int;
            var stapLen:int;
            var token:Token;
            var startCoords:Array;
            var scale:Number;
            var xShift:Number;
            var yShift:Number;
            var horizScaffoldSection:String;
            var horizStapleSection:String;
            var startNewHorizSection:Boolean;
            var reversedString:String;
            
            // staple
            for each(vs in this.vsList) {
                startNewHorizSection = true;
                horizStapleSection = "";
                stapLen = vs.stap.length;
                for (pos = 0; pos < stapLen; pos++) {
                    token = vs.stap[pos];
                    if ((token.sequence == "?" || token.sequence.length == 0) && startNewHorizSection == false) { // no staple here
                        startNewHorizSection = true;
                        if (horizStapleSection != "") {
                            if (((token.prev_strand == vs.number && vs.stap[token.prev_pos].sequence != "?" && vs.stap[token.prev_pos].sequence.length != 0) && 
                                  this.getInternalCoordsOfStapleToken(vs.stap[token.prev_pos])[0] % 2 == 0) || 
                                ((token.next_strand == vs.number && vs.stap[token.next_pos].sequence != "?" && vs.stap[token.next_pos].sequence.length != 0) && 
                                  this.getInternalCoordsOfStapleToken(vs.stap[token.next_pos])[0] % 2 == 0)) {
                                scale = -1;
                                reversedString = "";
                                for (i = horizStapleSection.length - 1; i >= 0; i--) {
                                    reversedString += horizStapleSection.charAt(i);
                                }
                                horizStapleSection = reversedString;
                                xShift = horizStapleSection.length*this.baseWidth - 2;
                                yShift = 2;
                            } else {
                                scale = 1;
                                xShift = 0 + 2;
                                yShift = -2;
                            }
                            this.sequenceStringStap += printf(horizTemplate, startCoords[0]+xShift, startCoords[1] + yShift, scale , drawPath.getHexColorString(token.color), horizStapleSection);
                            continue;
                        }
                    } else if (token.sequence != "?" && token.sequence.length != 0) {
                        if (startNewHorizSection == true) {
                            horizStapleSection = "";
                            startCoords = this.getStapleTokenSVGCoords(vs.stap[pos]);
                            startNewHorizSection = false;
                        }
                        if (token.sequence.length == 1) {
                            horizStapleSection += token.sequence;
                        } else if (token.sequence.length > 1) {
                            // figure out what to do in this case
                            horizStapleSection += "+";
                        }
                        if (((token.next_strand != vs.number || (token.next_strand == vs.number && token.next_pos != pos + 1)) && vs.number % 2 == 1) || 
                            ((token.prev_strand != vs.number || (token.prev_strand == vs.number && token.prev_pos != pos + 1)) && vs.number % 2 == 0)) {
                            if (this.getInternalCoordsOfStapleToken(token)[0]%2 == 0) {
                                scale = -1;
                                reversedString = "";
                                for (i = horizStapleSection.length - 1; i >= 0; i--) {
                                    reversedString += horizStapleSection.charAt(i);
                                }
                                horizStapleSection = reversedString;
                                xShift = horizStapleSection.length*this.baseWidth - 2;
                                yShift = 2;
                            } else {
                                scale = 1;
                                xShift = 0 + 2;
                                yShift = -2;
                            }
                            this.sequenceStringStap += printf(horizTemplate, startCoords[0]+xShift, startCoords[1] + yShift, scale , drawPath.getHexColorString(token.color), horizStapleSection);
                            startNewHorizSection = true;
                        }
                    }
                }
            }

            // scaffold
            for each(vs in this.vsList) {
                startNewHorizSection = true;
                scafLen = vs.scaf.length;
                for (pos = 0; pos < scafLen; pos++) {
                    token = vs.scaf[pos];
                    if ((token.sequence.length == 0 || token.sequence == "?") && startNewHorizSection == false) {
                         startNewHorizSection = true;
                         if (horizScaffoldSection != "") {
                            if (((token.prev_strand == vs.number && vs.scaf[token.prev_pos].sequence != "?" && vs.scaf[token.prev_pos].sequence.length != 0) && 
                                  this.getInternalCoordsOfScaffoldToken(vs.scaf[token.prev_pos])[0] % 2 == 1) || 
                                ((token.next_strand == vs.number && vs.scaf[token.next_pos].sequence != "?" && vs.scaf[token.next_pos].sequence.length != 0) && 
                                  this.getInternalCoordsOfScaffoldToken(vs.scaf[token.next_pos])[0] % 2 == 1)) {
                                scale = -1;
                                reversedString = "";
                                for (i = horizScaffoldSection.length - 1; i >= 0; i--) {
                                    reversedString += horizScaffoldSection.charAt(i);
                                }
                                horizScaffoldSection = reversedString;
                                xShift = horizScaffoldSection.length*this.baseWidth - 2;
                                yShift = 2;
                            } else {
                                scale = 1;
                                xShift = 0 + 2;
                                yShift = -2;
                            }
                            this.sequenceStringScaf += printf(horizTemplate, startCoords[0]+xShift, startCoords[1] + yShift, scale , drawPath.getHexColorString(token.color), horizScaffoldSection);
                            continue;
                        }
                    } else if (token.sequence != "?" && token.sequence.length != 0) {
                        if (startNewHorizSection == true) {
                            horizScaffoldSection = "";
                            startCoords = this.getScaffoldTokenSVGCoords(vs.scaf[pos]);
                            startNewHorizSection = false;
                        }
                        
                        if (token.sequence.length == 1) {
                            horizScaffoldSection += token.sequence;
                        } else if (token.sequence.length > 1) {
                            // figure out what to do in this case
                            horizScaffoldSection += "+";
                        }
                        
                        if (((token.next_strand != vs.number || (token.next_strand == vs.number && token.next_pos != pos + 1)) && vs.number % 2 == 0) || 
                            ((token.prev_strand != vs.number || (token.prev_strand == vs.number && token.prev_pos != pos + 1)) && vs.number % 2 == 1)) {
                            if (this.getInternalCoordsOfScaffoldToken(token)[0]%2 == 1) {
                                scale = -1;
                                reversedString = "";
                                for (i = horizScaffoldSection.length - 1; i >= 0; i--) {
                                    reversedString += horizScaffoldSection.charAt(i);
                                }
                                horizScaffoldSection = reversedString;
                                xShift = horizScaffoldSection.length*this.baseWidth - 2;
                                yShift = 2;
                            } else {
                                scale = 1;
                                xShift = 0 + 2;
                                yShift = -2;
                            }
                            
                            this.sequenceStringScaf += printf(horizTemplate, startCoords[0]+xShift, startCoords[1]+yShift, scale, drawPath.getHexColorString(token.color), horizScaffoldSection);
                            startNewHorizSection = true;
                        }
                    }
                }
            }
        }
        
        private function getLeftmostBasePosition():Number {
            return 0;
        }
        
        private function getRightmostBasePosition():Number {
            var gridwidth:int;
            if (this.path.vsList.size == 0) { // use default size for first vstrand
                gridwidth = 42;
            } else { // use calculated size of existing vstrand
                gridwidth = this.path.vsList.head.data.scaf.length;
            }
            return gridwidth*baseWidth;
        }
        
        private function writeHelixNumberText():void {
            // LHS
            var leftmostPosition:Number = this.getLeftmostBasePosition();
            for (var i:int = 0; i < this.numHelices; i++) {
                this.helixNumberLabelsString += printf("\n<text x=\"%s\" y=\"%s\">%s</text>", leftmostPosition - 30, this.vsList[i].drawVstrand.y, this.vsList[i].number);
            }
            // RHS
            var rightmostPosition:Number = this.getRightmostBasePosition();
            for (i= 0; i < this.numHelices; i++) {
                this.helixNumberLabelsString += printf("\n<text x=\"%s\" y=\"%s\">%s</text>", rightmostPosition, this.vsList[i].drawVstrand.y, this.vsList[i].number);
            }
        }
        
        private function writeSubzoneMarkerText():void {
            var gridwidth:int;
            // set the gridwidth
            if (this.path.vsList.size == 0) { // use default size for first vstrand
                gridwidth = 42;
            } else { // use calculated size of existing vstrand
                gridwidth = this.path.vsList.head.data.scaf.length;
            }
            // write the markers
            // TOP
            var i:int;
            for (i = 0; i< gridwidth; i++) {
                if (i % 7 == 0) {
                    this.subzoneNumberLabelsString += printf("\n<text x=\"%s\" y=\"-30\">%s</text>", (i*baseWidth).toString(), i.toString());
                }
            } 
            
           // BOTTOM
            for (i = 0; i< gridwidth; i++) {
                if (i % 7 == 0) {
                    this.subzoneNumberLabelsString += printf("\n<text x=\"%s\" y=\"%s\">%s</text>", (i*baseWidth).toString(), this.vsList[this.vsList.length - 1].drawVstrand.y + 30 , i.toString());
                }
            }
        }
        
        private function writeTickMarks():void {
            if (this.vsList.length < 1) {
                return;
            }
            
            var gridwidth:int;
            var start_y:Number;
            var end_y:Number;
            var x:Number
            var pos:int;
            var distances:Array = [2,2+3,2+3+4,2+3+4+3,2+3+4+3+4,2+3+4+3+4+3];
            gridwidth = this.path.vsList.head.data.scaf.length;
            
            start_y = this.vsList[0].drawVstrand.y;
            end_y = this.vsList[vsList.length - 1].drawVstrand.y;
            for (pos = 0; pos < gridwidth; pos++) {
                x = pos*baseWidth;
                if (pos % 7 == 0) {
                    this.ticksString += printf("\n<line x1=\"%s\" y1=\"%s\"  x2=\"%s\" y2=\"%s\" stroke=\"grey\"/>", x, start_y, x, end_y); 
                }
                /* don't draw scaffold ticks
                if (distances.indexOf(pos % 21) != -1) {
                    this.ticksString += printf("\n<line x1=\"%s\" y1=\"%s\"  x2=\"%s\" y2=\"%s\" stroke=\"green\" stroke-dasharray=\"9,36,9,72\"/>", x, start_y, x, end_y);
                }
                */
            }
        }
        
        private function getSliceRowShift():Number {
            var sliceHash:Object = this.drawPath.drawSlice.slice.sliceHash;
            var rowShift:int = 0;
            var sliceNode:SliceNode;
            for (var key in sliceHash){
                sliceNode = sliceHash[key];
                if(sliceNode.vstrand != null){
                    if(sliceNode.row > rowShift){
                        rowShift = sliceNode.row;
                    }
                }
            }
            return rowShift;
        }
        
        private function getSliceColShift():Number {
            var sliceHash:Object = this.drawPath.drawSlice.slice.sliceHash;
            var colShift:int = 0;
            var sliceNode:SliceNode;
            for (var key in sliceHash){
                sliceNode = sliceHash[key];
                if(sliceNode.vstrand != null){
                    if(sliceNode.col > colShift){
                        colShift = sliceNode.col;
                    }
                }
            }
            return colShift;
        }
        
        private function writeSlices():void {
            var sliceString:String;
            var sliceHash:Object = this.drawPath.drawSlice.slice.sliceHash;
            var drawNodeArray:Object = this.drawPath.drawSlice.drawNodeArray;
            var sliceNode:SliceNode;
            var radius:Number = 20;
            var rows:int = this.drawPath.drawSlice.rows;
            var cols:int = this.drawPath.drawSlice.cols;
            var x:Number;
            var y:Number;
            var gridwidth:int;
            var index:String;
            var c:int;
            var colShift:int = this.getSliceColShift();
            var rowShift:int = this.getSliceRowShift();
            var x_offset:Number = 0;
            var y_offset:Number = this.vsList[this.vsList.length - 1].drawVstrand.y + 400;
            var filled_circle_template:String = "\n<circle fill=\"#FFDDA8\" stroke=\"#FCAF21\" stroke-width=\"2\" cx=\"%s\" cy=\"%s\" r=\"%s\"/>";
            var unfilled_circle_template:String = "\n<circle fill=\"#FFFFFF\" stroke=\"#FCAF21\" stroke-width=\"2\" cx=\"%s\" cy=\"%s\" r=\"%s\"/>";
            // set the gridWidth
            if (this.path.vsList.size == 0) { // use default size for first vstrand
                gridwidth = 42;
            } else { // use calculated size of existing vstrand
                gridwidth = this.path.vsList.head.data.scaf.length;
            }
            // loop through the slices
            for (c = 0; c < gridwidth; c += 7) {
                // decide whether to draw this slice
                var drawThisSlice:Boolean;
                if (c == 0) {
                    drawThisSlice = false;
                } else {
                    drawThisSlice = false;
                    for (var col:int = 0; col < cols; col++) {
                        for (var row:int = 0; row < rows; row++) {
                            index = row + "," + col;
                            sliceNode = sliceHash[index];
                            if (sliceNode.vstrand != null) {
                                if(((sliceNode.vstrand.scaf[c].prev_strand != -1 || sliceNode.vstrand.scaf[c].next_strand != -1) && (!(sliceNode.vstrand.scaf[c-7].prev_strand != -1 || sliceNode.vstrand.scaf[c-7].next_strand != -1))) || ((sliceNode.vstrand.scaf[c-7].prev_strand != -1 || sliceNode.vstrand.scaf[c-7].next_strand != -1) && (!(sliceNode.vstrand.scaf[c].prev_strand != -1 || sliceNode.vstrand.scaf[c].next_strand != -1)))){
                                    drawThisSlice = true;
                                    break;
                                }
                            }
                        }
                    }    
                }
                // do the drawing
                if (drawThisSlice == true){
                    sliceString = "";
                    sliceString += printf("\n<text font-size = \"18pt\" x=\"%s\" y=\"%s\">%s</text>", x_offset + 60, y_offset-5, "Slice at Base Position " + c.toString());
                    // draw an individual slice
                    for (col = 0; col < cols; col++) {
                        for (row = 0; row < rows; row++) {
                            index = row + "," + col;
                            sliceNode = sliceHash[index];
                            // get the position of the node
                            x = col*radius*1.732051;
                            if ((row % 2) ^ (col % 2)) {  // odd parity
                                y = row*radius*3 + radius;
                            } else {                      // even parity
                                y = row*radius*3;
                            }
                            // draw the node
                            if (sliceNode.vstrand != null) {
                                if (sliceNode.vstrand.scaf[c].prev_strand != -1 || sliceNode.vstrand.scaf[c].next_strand != -1) {
                                // draw the marked node
                                    sliceString += printf(filled_circle_template, x + x_offset, y + y_offset - rows*radius, radius);
                                    sliceString += printf("\n<text font-size = \"12pt\" x=\"%s\" y=\"%s\">%s</text>", x + x_offset - 5, y + y_offset - rows*radius + 5, sliceNode.vstrand.number);
                                } else { 
                                //draw the unmarked node
                                    sliceString += printf(unfilled_circle_template, x + x_offset, y + y_offset - rows*radius, radius);
                                    sliceString += printf("\n<text font-size = \"12pt\" x=\"%s\" y=\"%s\">%s</text>", x + x_offset - 5, y + y_offset  - rows*radius + 5, sliceNode.vstrand.number);
                                }
                            }
                        }
                    }
                    // draw the next slice lower down
                    y_offset += rowShift*radius*3; 
                    y_offset += 80;
                    if (y_offset > this.vsList[this.vsList.length - 1].drawVstrand.y + 400 + 3*rowShift*radius*3) {
                        y_offset = this.vsList[this.vsList.length - 1].drawVstrand.y + 400;
                        x_offset += colShift*radius*1.732051*1.1;
                    }
                    // add the currrent slice to the output
                    this.latticeSlicesString += sliceString;
                }                
            }
        }
        
        // translation to SVG coordinates
        
        private function getStapleToScaffoldSVGCoordOffset(helixNum:int):Number {
            if (helixNum % 2 == 0) {
                return (this.stapleToScaffoldOffset - baseWidth);
            } else {
                return (-1*this.stapleToScaffoldOffset);
            }
        }
        
        /*translate internal coords of a staple token into the coords of the left edge
        of that token in the svg output, scaled in units of base-widths*/
        private function getStapleTokenSVGCoords(token:Token):Array {
            var internalCoords:Array = this.getInternalCoordsOfStapleToken(token);
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            var helixNum:int = vs.number;
            var vShift:int = 0;
            return [internalCoords[1]*baseWidth, vs.drawVstrand.y + (((helixNum + 1) % 2) * baseWidth) + this.getStapleToScaffoldSVGCoordOffset(helixNum)];
        }
        
        /*translate internal coords of a scaffold token into the coords of the left edge
        of that token in the svg output, scaled in units of base-widths*/
        private function getScaffoldTokenSVGCoords(token:Token):Array {
            var internalCoords:Array = this.getInternalCoordsOfScaffoldToken(token);
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            var helixNum:int = vs.number;
            return [internalCoords[1]*baseWidth, vs.drawVstrand.y]; 
        }
        
        private function getStapleTokenSVGCoordsFromInternalCoords(internalCoords:Array) {
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            var helixNum:int = vs.number;
            var vShift:int = 0;
            return [internalCoords[1]*baseWidth, vs.drawVstrand.y + (((helixNum + 1) % 2) * baseWidth) + this.getStapleToScaffoldSVGCoordOffset(helixNum)];
        }
        
        private function getScaffoldTokenSVGCoordsFromInternalCoords(internalCoords:Array) {
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            var helixNum:int = vs.number;
            return [internalCoords[1]*baseWidth, vs.drawVstrand.y];
        }
        
        /*Return the SVG x and y coords of the breakpoint handle, if 
        there is one, corresponding to the token, t. If there
        is no breakpoint corresponding to t, then return null.*/
        private function getScaffoldBreakpointHandleSVGCoords(t:Token):Array {
            var internalCoords:Array = this.getInternalCoordsOfScaffoldToken(t);
            if (internalCoords == null) {
                return null;
            }
            // list of staple crossovers on the relevant vstrand
            var breaks:Array = this.vsHash[internalCoords[0]].drawVstrand.scafbreaks;
            var br:BreakpointHandle = null;
            var len = breaks.length;
            for (var i:int = 0; i < len; i++) {
               if (breaks[i].pos == internalCoords[1]) {
                   br = breaks[i];
                   return [br.x, br.y + br.vstrand.drawVstrand.y];
               }
            }
            if (br == null) {
               return null;
            }
            // otherwise
            return [br.x, br.y + br.vstrand.drawVstrand.y + this.getStapleToScaffoldSVGCoordOffset(br.vstrand.number)];
        }
        
        /*Return the SVG x and y coords of the breakpoint handle, if 
        there is one, corresponding to the token, t. If there
        is no breakpoint corresponding to t, then return null.*/
        private function getStapleBreakpointHandleSVGCoords(t:Token):Array {
            var internalCoords:Array = this.getInternalCoordsOfStapleToken(t);
            if (internalCoords == null) {
                return null;
            }
            // list of staple crossovers on the relevant vstrand
            var breaks:Array = this.vsHash[internalCoords[0]].drawVstrand.stapbreaks;
            var br:BreakpointHandle = null;
            var len = breaks.length;
            for (var i:int = 0; i < len; i++) {
               if (breaks[i].pos == internalCoords[1]) {
                   br = breaks[i];
                   return [br.x, br.y + br.vstrand.drawVstrand.y + this.getStapleToScaffoldSVGCoordOffset(br.vstrand.number)];
               }
            }
            if (br == null) {
               return null;
            }
            // otherwise
            return [br.x, br.y + br.vstrand.drawVstrand.y + this.getStapleToScaffoldSVGCoordOffset(br.vstrand.number)];
        }
        
        /*Return the SVG x and y coords of the crossover handle, if 
        there is one, corresponding to the token, t. If there
        is no crossover corresponding to t, then return null.*/
        private function getStapleCrossoverHandleSVGCoords(t:Token):Array {
            var internalCoords:Array = this.getInternalCoordsOfStapleToken(t);
            if (internalCoords == null) {
                return null;
            }
            // list of staple crossovers on the relevant vstrand
            var xovers:Array = this.vsHash[internalCoords[0]].drawVstrand.stapxolist;
            var xover:CrossoverHandle = null;
            var len = xovers.length;
            for (var i:int = 0; i < len; i++) {
                if (xovers[i].pos == internalCoords[1]) {
                    xover = xovers[i];
                    return [xover.x, xover.y];
                }
            }
            if (xover == null) {
                return null;
            }
            // otherwise
            return [xover.x, xover.y];
        }
        
        private function getStapleTokenSVGCoordOffset(t:Token):Number {
            var internalCoords:Array = this.getInternalCoordsOfStapleToken(t);
            return ((internalCoords[0]+1)%2)*(baseWidth);
        }
        
        private function getScaffoldTokenSVGCoordOffset(t:Token):Number {
            var internalCoords:Array = this.getInternalCoordsOfScaffoldToken(t);
            return ((internalCoords[0]%2)*(baseWidth));
        }
        
        // utilities for jumping around staple and scaffold paths ( TO DO: these should be put into Path.as since they will be useful for data verification etc. )
        /*get the next token on the relevant staple path, return null if there is none*/
        private function getNextStapleToken(t:Token):Token {
            return this.getStapleToken([t.next_strand, t.next_pos]);
        }
        /*get the next token on the relevant scaffold path, return null if there is none*/
        private function getNextScaffoldToken(t:Token):Token {
            return this.getScaffoldToken([t.next_strand, t.next_pos]);
        }
        
        /*get the prev token on the relevant staple path, return null if there is none*/
        private function getPrevStapleToken(t:Token):Token {
            return this.getStapleToken([t.prev_strand, t.prev_pos]);
        }
        /*get the prev token on the relevant scaffold path, return null if there is none*/
        private function getPrevScaffoldToken(t:Token):Token {
            return this.getScaffoldToken([t.prev_strand, t.prev_pos]);
        }
        
        /*"internal coords" means: [helix number, horizontal base position]*/
        private function getInternalCoordsOfStapleToken(t:Token):Array {
            if (t == null) {
                return null;
            }
            // otherwise try to find coords
            var len:int;
            var arr:Array = [t.prev_strand, t.next_strand];
            for (var i:int = 0; i<2; i++) {
                if (arr[i] != -1) {
                    len = this.vsHash[arr[i]].stap.length;
                    for (var j:int = 0; j < len; j++) {
                        if (this.getStapleToken([arr[i],j]) == t) {
                            return [arr[i],j];
                        }
                    }
                }
            }
            // if appropriate coords not found, return null
            return null;
        }
        /*"internal coords" means: [helix number, horizontal base position]*/
        private function getInternalCoordsOfScaffoldToken(t:Token):Array {
            if (t == null) {
                return null;
            }
            // otherwise try to find coords
            var len:int;
            var arr:Array = [t.prev_strand, t.next_strand];
            for (var i:int = 0; i<2; i++) {
                if (arr[i] != -1) {
                    len = this.vsHash[arr[i]].scaf.length;
                    for (var j:int = 0; j < len; j++) {
                        if (this.getScaffoldToken([arr[i],j]) == t) {
                            return [arr[i],j];
                        }
                    }
                }
            }
            // if appropriate coords not found, return null
            return null;
        }
        
        /*return the staple token at this array position*/
        private function getStapleToken(internalCoords:Array):Token {
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            if (vs != null) {
                return vs.stap[internalCoords[1]];
            } else {
                return null;
            }
        }
        
        /*return the scaffold token at this array position*/
        private function getScaffoldToken(internalCoords:Array):Token {
            var vs:Vstrand = this.vsHash[internalCoords[0]];
            if (vs != null) {
                return vs.scaf[internalCoords[1]];
            } else {
                return null;
            }
            
        }
        
        /*set all staple and scaffold tokens to token.visited = false*/
        private function refreshVisitedTokens():void {
            var len:int;
            for (var i:int = 0; i < numHelices; i++) {
                len = vsList[i].scaf.length;
                for (var j:int = 0; j < len ; j++) {
                    vsList[i].scaf[j].visited = false;
                }
                len = vsList[i].stap.length;
                for (j = 0; j < len ; j++) {
                    vsList[i].stap[j].visited = false;
                }
            }
        }
    } // end class Svg
} // end package edu.harvard.med.cadnano.data