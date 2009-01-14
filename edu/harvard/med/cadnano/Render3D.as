//
//  Render
//
//  Created by Shawn on 2007-12-09.
//

/*
The MIT License

Copyright (c) 2007-2008 Shawn M. Douglas

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

package edu.harvard.med.cadnano {
    // flash
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.ui.Mouse;
    import flash.utils.*;
    import flash.geom.*;
    import flash.text.TextField;
    
    // misc
    import caurina.transitions.Tweener;
    import com.yahoo.astra.utils.NumberUtil;
    import de.polygonal.core.ObjectPool;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.Path;
    import edu.harvard.med.cadnano.data.Line3DFactory;
    import edu.harvard.med.cadnano.data.VectorShapeFactory;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.DrawSlice;
    import edu.harvard.med.cadnano.panel.Panel;
    
    // Papervision
    import org.papervision3d.cameras.FreeCamera3D;
    import org.papervision3d.render.BasicRenderEngine;
    import org.papervision3d.scenes.Scene3D;
    import org.papervision3d.view.Viewport3D;
    
    // Primitives
    import org.papervision3d.objects.DisplayObject3D;
    
    // Materials
    import org.papervision3d.materials.ColorMaterial;
    import org.papervision3d.materials.WireframeMaterial;
    import org.papervision3d.materials.utils.MaterialsList;
    import org.papervision3d.materials.special.LineMaterial;
    import org.papervision3d.materials.special.GradientLineMaterial;
    
    // Math stuff
    import org.papervision3d.core.math.*;
    
    // VectorVision
    import org.papervision3d.materials.special.VectorShapeMaterial;
    import org.papervision3d.objects.DisplayObject3D;
    import org.papervision3d.objects.special.Graphics3D;
    import org.papervision3d.objects.special.VectorShape3D;
    
    // Line3D
    import org.papervision3d.core.geom.Lines3D;
    import org.papervision3d.core.geom.renderables.Line3D;
    
    public class Render3D extends Sprite {
        public static const lineSize:Number = 16;
        public var radius:int = 10;
        public var suppressRendering:Boolean = false; // mode
        
        // papervision3D
        private var viewport:Viewport3D;
        private var scene:Scene3D;
        public var camera:FreeCamera3D;
        private var renderer:BasicRenderEngine;
        
        // Primitives
        public var scafLines:Lines3D;
        private var stapLineMaterial:LineMaterial;
        private var scafLineMaterial:LineMaterial;
        private var vectorMaterial:VectorShapeMaterial;
        
        // MouseEvents
        private var mouseDownState:Boolean = false;
        private var mouseUpState:Boolean = false;
        private var mouseMoveState:Boolean = false;
        
        // vector
        private var vectorMouseDown:Number3D;
        private var vectorMouseDrag:Number3D;
        private var trackBallVector:Number3D;
        private var rotY:Number = 0;
        
        private var lastPoint:Point;
        
        // debug
        private var lines:Array = null;
        private var t:Matrix3D;
        
        // data
        private var path:Path;
        private var vectPool:ObjectPool;
        private var line3DPool:ObjectPool;
        
        // DNA drawing
        private var lineContainer:DisplayObject3D;
        private var firstClick:Boolean = true;
        
        // "phosphate" coordinates
        private var stapX:Array = [ 0.866,  0.434, -0.149, -0.680, -0.975, -0.931, -0.563,
                                    0.000,  0.563,  0.931,  0.975,  0.680,  0.149, -0.434,
                                   -0.866, -0.997, -0.782, -0.295,  0.295,  0.782,  0.997];
        private var stapY:Array = [-0.500, -0.901, -0.989, -0.733, -0.223,  0.365,  0.826,
                                    1.000,  0.826,  0.365, -0.223, -0.733, -0.989, -0.901,
                                   -0.500,  0.075,  0.624,  0.956,  0.956,  0.623,  0.075];
        private var scafX:Array = [-1.000, -0.826, -0.365,  0.223,  0.733,  0.989,  0.901,
                                    0.500, -0.075, -0.623, -0.956, -0.956, -0.623, -0.075,
                                    0.500,  0.901,  0.989,  0.733,  0.222, -0.365, -0.826];
        private var scafY:Array = [ 0.000,  0.563,  0.931,  0.975,  0.680,  0.149, -0.434,
                                   -0.866, -0.997, -0.782, -0.295,  0.295,  0.782,  0.997,
                                    0.866,  0.434, -0.149, -0.680, -0.975, -0.931, -0.563];
        
        private var count:int = 0;
        private var startIndex:int = 0;
        private var endIndex:int = 0;
        private var minX, minY, minZ:Number;
        private var maxX, maxY, maxZ:Number;
        private var deltaX, deltaY, deltaZ:Number;
        
        public var helixSegments:Array;
        private var vFactory:VectorShapeFactory;
        private var line3DFactory:Line3DFactory;
        private var endcapVectorShapes:Array = new Array();
        private var render3DPanel:Panel;
        
        public function Render3D(path:Path, render3DPanel:Panel) {
            this.path = path;
            this.render3DPanel = render3DPanel;
        }
        
        public function init(canvas:Sprite):void {
            initPapervision();
            initMaterials();
            initObjects();
            initListeners(canvas);
            initObjectPools();
        }
        
        /* Viewport3D, scene, camera, renderer */
        private function initPapervision():void {
            this.viewport = new Viewport3D( this.render3DPanel.w, this.render3DPanel.h, false, true );
            this.addChild(viewport);
            this.scene = new Scene3D();
            this.camera = new FreeCamera3D();
            this.camera.zoom = 17;
            this.renderer = new BasicRenderEngine();
        }
        
        /* Set up pv3d materials. */
        private function initMaterials():void {
            this.scafLineMaterial = new GradientLineMaterial([0xffffff,0xcc6600,0xffffff],[100,100,100]);
            this.scafLines = new Lines3D(scafLineMaterial);
            this.vectorMaterial = new VectorShapeMaterial(0x00);
        }
        
        private function initObjects():void {
            this.lineContainer = new DisplayObject3D();
            this.lineContainer.addChild(scafLines);
            this.scene.addChild(lineContainer);
        }
        
        private function initListeners(canvas:Sprite):void {
            canvas.addEventListener(MouseEvent.MOUSE_UP, onMouseUpEvent);
            canvas.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEvent);
            canvas.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEvent);
        }
        
        private function initObjectPools():void {
            this.vectPool = new ObjectPool(true);
            this.vFactory = new VectorShapeFactory(vectorMaterial);
            this.vectPool.setFactory(this.vFactory);
            this.vectPool.allocate(100);
            this.line3DPool = new ObjectPool(true);
            this.line3DFactory = new Line3DFactory(this.scafLines, this.scafLineMaterial, Render3D.lineSize);
            this.line3DPool.setFactory(this.line3DFactory);
            this.line3DPool.allocate(100);
        }
        
        private function onMouseDownEvent(event:MouseEvent):void {
            vectorMouseDown = trackBallVector
            
            t = lineContainer.transform;
            lastPoint = new Point(this.stage.mouseX, this.stage.mouseY);
            mouseDownState = true;
            mouseUpState = false;
        }
        
        private function onMouseUpEvent(event:MouseEvent):void {
            mouseUpState = true;
            mouseDownState = false;
        }
        
        private function onMouseMoveEvent(event:MouseEvent):void {
            mouseMoveState = true;
            if (mouseDownState == true && mouseMoveState == true) {
                var xx:Number =  this.stage.mouseX - lastPoint.x;
                var yy:Number = -this.stage.mouseY + lastPoint.y;
                if (yy == 00) {return;}
                
                var rotAxis:Number3D = new Number3D();
                rotAxis.z = 0;
                rotAxis.x = yy;
                rotAxis.y = -xx;
                
                // calculate the amount of rotation 
                var rotAngle:Number = (Math.sqrt(xx*xx + yy*yy))/400*Math.PI;
                if (rotAngle == 0) return;
                
                // applaying the rotation
                // convert to Quaternion, the lineContainer rotaion and the mouse drag
                rotAxis.normalize();
                var deltaQ:Quaternion = Quaternion.createFromAxisAngle(rotAxis.x, rotAxis.y, rotAxis.z, rotAngle);
                var q:Quaternion = Quaternion.createFromMatrix(lineContainer.transform);
                deltaQ.mult(q);
                deltaQ.normalize();
                var newTransform = deltaQ.toMatrix();
                lineContainer.transform = newTransform;
                lastPoint = new Point(this.stage.mouseX, this.stage.mouseY);
                this.render();
            }
        }
        
        public function render():void {
            if (suppressRendering == true) {return;}
            showVector();
            renderer.renderScene(scene, camera, viewport);
        }
        
        private function toAxisRotation( q:Quaternion ):Number3D {
            q.normalize();
            var cos_a = q.w;
            var angle = Math.acos( cos_a ) * 2;
            var sin_a = Math.sqrt( 1.0 - cos_a * cos_a );
            if (sin_a < 0) {sin_a = -sin_a;}
            if (sin_a< 0.0005 ){ sin_a = 1 }
            var axisRotation:Number3D = new Number3D();
            axisRotation.x = q.x / sin_a;
            axisRotation.y = q.y / sin_a;
            axisRotation.z = q.z / sin_a;
            return axisRotation
        }
        
        private function angleBetween(v1:Number3D, v2:Number3D):Number {
            var angle:Number = Math.acos( Number3D.dot( v1, v2 ) / ( v1.modulo * v2.modulo ) );
            return angle;
        }
        
        private function showVector():void {
            if (lines != null) {
                for each (var l:Lines3D in lines) {
                    scene.removeChild(l);
                }
            }
            lines = [];
            var m:Matrix3D = lineContainer.transform;
            var xl:Lines3D = new Lines3D(new LineMaterial(0x0000ff));
            var yl:Lines3D = new Lines3D(new LineMaterial(0xff0000));
            var zl:Lines3D = new Lines3D(new LineMaterial(0x00ff00));
            scene.addChild(xl);
            scene.addChild(yl);
            scene.addChild(zl);
            xl.addNewLine(2,lineContainer.x,lineContainer.y,lineContainer.z,lineContainer.x + m.n11*20,lineContainer.y + m.n21*20,lineContainer.z + m.n31*20);
            yl.addNewLine(2,lineContainer.x,lineContainer.y,lineContainer.z,lineContainer.x + m.n12*20,lineContainer.y + m.n22*20,lineContainer.z + m.n32*20);
            zl.addNewLine(2,lineContainer.x,lineContainer.y,lineContainer.z,lineContainer.x + m.n13*20,lineContainer.y + m.n23*20,lineContainer.z + m.n33*20);
            lines.push(zl);
            lines.push(yl);
            lines.push(xl);
        }
        
        private function getHelixSegments():void {
            //centerViewport();
            var helixSegments:Array = new Array(); // refresh helixSegments
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            var vs:Vstrand;
            var drawX:int;
            var drawY:int
            var startZ, endZ, drawZ:int;
            var startIndex:int;
            var endIndex:int;
            var len:int;
            
            minX = minY = minZ =  999999;
            maxX = maxY = maxZ = -999999;
            
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                // determine segment coordinates
                drawX =  (vs.col)*(this.radius)*1.732051;
                drawY = -(vs.row)*(this.radius)*3.00;
                drawZ = -this.radius*0.34*21;
                
                if (vs.number % 2 == 1) { // odd parity
                    drawY = drawY - this.radius;
                }
                
                if (drawX < minX) {minX = drawX;}
                if (drawX > maxX) {maxX = drawX;}
                if (drawY < minY) {minY = drawY;}
                if (drawY > maxY) {maxY = drawY;}
                
                var start:Boolean = true;
                len = vs.scaf.length;
                for (var i:int = 0; i < len; i++) {
                    // check for bases to draw
                    if (vs.scafBreakOrXover(i)) {
                        if (!vs.hasScaf(i-1) || !vs.hasScaf(i+1)) {
                            if (start) {
                                start = false;
                                startIndex = i;
                            } else {
                                start = true;
                                endIndex = i;
                                startZ = NumberUtil.roundToPrecision(drawZ + this.radius*0.34*startIndex,2);
                                endZ = NumberUtil.roundToPrecision(drawZ + this.radius*0.34*endIndex,2); 
                                helixSegments.push([drawX, drawY, startZ, endZ]);
                                if (startZ < minZ) {minZ = startZ;}
                                if (endZ > maxZ) {maxZ = endZ;}
                            }
                        }
                    }
                }
            }
            
            deltaX = NumberUtil.roundToPrecision((maxX + minX)*0.5,3);
            deltaY = NumberUtil.roundToPrecision((maxY + minY)*0.5,3);
            deltaZ = NumberUtil.roundToPrecision((maxZ + minZ)*0.5,3);
            
            for each (var coord in helixSegments) {
                coord[0] -= deltaX;
                coord[1] -= deltaY;
                coord[2] -= deltaZ;
                coord[3] -= deltaZ;
            }
            this.helixSegments = helixSegments;
        }
        
        private function centerViewport():void{
            var ctrX,ctrY:Number;
            var avgX:Number = 0;
            var avgY:Number = 0;
            var drawX:int;
            var drawY:int;
            var vs:Vstrand;
            var numHelices:int = 0;
            var startIndex:int;
            var endIndex:int;
            var vsIter:DListIterator = this.path.vsList.getListIterator();
            // loop through each helix
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                numHelices++;
                vs = vsIter.node.data;
                // determine segment coordinates
                drawX =  (vs.col)*(this.radius*1.0)*1.732051;
                drawY = -(vs.row)*(this.radius*1.0) * 3;
                if (vs.number % 2 == 1) { // even parity
                    drawY = drawY - this.radius;
                }
                avgX += drawX;
                avgY += drawY;
            }
            avgX = avgX/numHelices;
            avgY = avgY/numHelices;
            viewport.y = 0;
            ctrX = avgX;
            ctrY = avgY;
            trace("centerViewport", ctrX, ctrY);
        }
        
        /* Draw vstrands */
        public function redrawBases():void {
            var end1, end2:VectorShape3D;
            var drawX:int;
            var drawY:int;
            var drawZStart:int;
            var drawZEnd:int;
            var len:int;
            var line3D:Line3D;
            
            if (suppressRendering) {
                return;
            }
            
            // clean up from last time
            // recover caps into vector pool
            while (endcapVectorShapes.length > 0) {
                end1 = endcapVectorShapes.pop() as VectorShape3D;
                lineContainer.removeChild(end1);
                vectPool.object = end1;
            }
            
            // recover lines into line3D pool
            while (this.scafLines.lines.length > 0) {
                line3D = this.scafLines.lines.pop() as Line3D;
                this.scafLines.removeLine(line3D);
                line3DPool.object = line3D;
            }
            
            // get the new structure
            getHelixSegments();
            len = helixSegments.length;
            for(var i:int = 0; i < len; i++){
                drawX = helixSegments[i][0];
                drawY = helixSegments[i][1];
                drawZStart = helixSegments[i][2];
                drawZEnd = helixSegments[i][3];
                // end caps
                end1 = vectPool.object;
                end2 = vectPool.object;
                end1.x = end2.x = drawX;
                end1.y = end2.y = drawY;
                end1.z = drawZStart;
                end2.z = drawZEnd;
                endcapVectorShapes.push(end1, end2);
                lineContainer.addChild(end1);
                lineContainer.addChild(end2);
                // retrieve Line3D from pool
                line3D = this.line3DPool.object;
                // update coordinates
                line3D.updateCoordinates(drawX, drawY, drawZStart, drawX, drawY, drawZEnd);
                // add back into scafLines
                this.scafLines.addLine(line3D);
            }
            this.render();
        }
    } // end class
} // end package
