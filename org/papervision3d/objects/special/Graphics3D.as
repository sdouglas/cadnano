package org.papervision3d.objects.special {	import org.papervision3d.core.proto.GeometryObject3D;			import flash.display.BitmapData;	import flash.geom.Matrix;		import org.papervision3d.core.geom.renderables.Vertex3D;	import org.papervision3d.objects.special.commands.BeginFill;	import org.papervision3d.objects.special.commands.CurveTo;	import org.papervision3d.objects.special.commands.EndFill;	import org.papervision3d.objects.special.commands.LineStyle;	import org.papervision3d.objects.special.commands.LineTo;	import org.papervision3d.objects.special.commands.MoveTo;	import org.papervision3d.objects.DisplayObject3D;			/**	 * @author Mark Barcinski	 */	public class Graphics3D {		private var vectorshape : VectorShape3D;		public function Graphics3D(vectorshape : VectorShape3D) {			this.vectorshape = vectorshape;		}				// Added by smd		public function uninit():void {this.vectorshape = null;}				public function beginFill(color:uint, alpha:Number = 1):void		{			vectorshape.graphicsCommands.push( new BeginFill(color , alpha));			}				public function endFill():void		{			vectorshape.graphicsCommands.push( new EndFill());			}		public function curveTo(controlX:Number , controlY:Number , anchorX:Number , anchorY:Number):void		{			var v : Vertex3D = new Vertex3D( controlX , controlY , 0);			vectorshape.geometry.vertices.push(v);						var vc : Vertex3D = new Vertex3D(anchorX, anchorY , 0);			vectorshape.geometry.vertices.push(vc);						vectorshape.graphicsCommands.push( new CurveTo(v , vc));		}				public function lineTo(x:Number , y:Number):void		{			var v : Vertex3D = new Vertex3D( x , y , 0);			vectorshape.geometry.vertices.push(v);			vectorshape.graphicsCommands.push( new LineTo(v));		}				public function moveTo(x:Number , y:Number):void		{			var v : Vertex3D = new Vertex3D( x , y , 0);			vectorshape.geometry.vertices.push(v);			vectorshape.graphicsCommands.push( new MoveTo(v));		}				public function lineStyle(thickness : Number = 0, color : uint = 0, alpha : Number = 1.0, pixelHinting : Boolean = false, scaleMode : String = "normal", caps : String = null, joints : String = null, miterLimit : Number = 3) : void 		{			//NOTE stroke doesn't scale with perspective			vectorshape.graphicsCommands.push(new LineStyle(thickness, color , alpha, pixelHinting, scaleMode, caps, joints, miterLimit));		}		public function drawRect(x : Number, y : Number, width : Number, height : Number) : void		{			moveTo(x, y);			lineTo(x + width, y);			lineTo(x + width, y + height);			lineTo(x, y + height);			lineTo(x, y);		}				public function drawRoundRect(x : Number, y : Number, width : Number, height : Number, ellipseWidth : Number, ellipseHeight : Number) : void		{			moveTo(x, y + ellipseHeight);			curveTo(x, y , x + ellipseWidth, y);						lineTo(x + width - ellipseWidth, y);			curveTo(x + width , y , x + width , y + ellipseHeight);						lineTo(x + width, y + height - ellipseHeight);			curveTo(x + width, y + height , x + width - ellipseHeight, y + height);						lineTo(x + ellipseWidth, y + height);			curveTo(x , y + height , x , y + height - ellipseHeight);						lineTo(x, y + ellipseHeight);		}				public function clear() : void		{			vectorshape.geometry.vertices = [];			vectorshape.geometry.faces = [];			vectorshape.graphicsCommands = [];		}		 		public function drawCircle(x : Number, y : Number, radius : Number) : void		{			//TODO make a real circle			drawRoundRect(x - radius , y - radius, radius * 2 , radius * 2 , radius , radius);		}		/*		public function drawRoundRectComplex(x : Number, y : Number, width : Number, height : Number, topLeftRadius : Number, topRightRadius : Number, bottomLeftRadius : Number, bottomRightRadius : Number) : void		{					}		public function lineGradientStyle(type : String, colors : Array, alphas : Array, ratios : Array, matrix : Matrix = null, spreadMethod : String = "pad", interpolationMethod : String = "rgb", focalPointRatio : Number = 0) : void		{					}			public function drawEllipse(x : Number, y : Number, width : Number, height : Number) : void		{					}		public function beginBitmapFill(bitmap : BitmapData, matrix : Matrix = null, repeat : Boolean = true, smooth : Boolean = false) : void		{					}		public function beginGradientFill(type : String, colors : Array, alphas : Array, ratios : Array, matrix : Matrix = null, spreadMethod : String = "pad", interpolationMethod : String = "rgb", focalPointRatio : Number = 0) : void		{					}*/	}}