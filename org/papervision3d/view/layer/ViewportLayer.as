package org.papervision3d.view.layer {
	import flash.display.Sprite;
	
	import org.papervision3d.core.ns.pv3dview;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.view.Viewport3D;	

	/**
	 * @Author Ralph Hauwert
	 */
	public class ViewportLayer extends Sprite
	{
		use namespace pv3dview;
		
		private var childLayers:Array;
		protected var viewport:Viewport3D;
		protected var _displayObject3D:DisplayObject3D;
		
		public function ViewportLayer(viewport:Viewport3D, do3d:DisplayObject3D)
		{
			super();
			this.viewport = viewport;
			this.displayObject3D = do3d;
			init();
		}
		
		private function init():void
		{
			childLayers = new Array();
		}
		
		pv3dview function getChildLayerFor(displayObject3D:DisplayObject3D):ViewportLayer
		{
			if(displayObject3D){
				var vpl:ViewportLayer = new ViewportLayer(viewport,displayObject3D);
				addChild(vpl);
				return vpl;
			}else{
				trace("Needs to be a do3d");
			}
			return null;
		}
		
		pv3dview function clear():void
		{
			var vpl:ViewportLayer;
			for each(vpl in childLayers){
				vpl.clear();
				removeChild(vpl);
			}
			graphics.clear();
		}
		
		public function set displayObject3D(do3d:DisplayObject3D):void
		{
			_displayObject3D = do3d;
			
		}
		
		public function get displayObject3D():DisplayObject3D
		{
			return _displayObject3D;
		}
		
	}
}