package org.papervision3d.objects.special.commands {	import flash.display.Graphics;			import org.papervision3d.core.geom.renderables.Vertex3D;			/**	 * @author Mark Barcinski	 */	public class LineTo implements IVectorShape{		public var vertex : Vertex3D;		public function LineTo(vertex : Vertex3D) {			this.vertex = vertex;			}		public function draw(graphics : Graphics) : void {			//if(vertex.vertex3DInstance.visible)			graphics.lineTo(vertex.vertex3DInstance.x , vertex.vertex3DInstance.y);		}	}}