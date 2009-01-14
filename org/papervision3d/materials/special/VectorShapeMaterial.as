package org.papervision3d.materials.special {	import org.papervision3d.objects.special.commands.IVectorShape;		import org.papervision3d.core.proto.MaterialObject3D;	import org.papervision3d.objects.special.VectorShape3D;		import flash.display.Graphics;		import org.papervision3d.core.render.data.RenderSessionData;	/**	 * @author Mark Barcinski	 */	public class VectorShapeMaterial extends MaterialObject3D {		public function VectorShapeMaterial(fillColor:uint = 0xFF00FF) 		{			this.fillColor = fillColor;		}		public function drawShape(vectorShape : VectorShape3D, graphics : Graphics, renderSessionData : RenderSessionData) : void {			graphics.beginFill(fillColor);			for (var i:int=0; i<vectorShape.graphicsCommands.length; i++) {				IVectorShape(vectorShape.graphicsCommands[i]).draw(graphics);			}						graphics.endFill();		}			}}