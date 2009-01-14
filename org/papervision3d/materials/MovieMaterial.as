package org.papervision3d.materials
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	
	import org.papervision3d.Papervision3D;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.core.render.draw.ITriangleDrawer;
	import org.papervision3d.core.render.material.IUpdateBeforeMaterial;

	/**
	* The MovieMaterial class creates a texture from an existing MovieClip instance.
	* <p/>
	* The texture can be animated and/or transparent. Current scale and color values of the MovieClip instance will be used. Rotation will be discarded.
	* <p/>
	* The MovieClip's content needs to be top left aligned with the registration point.
	* <p/>
	* Materials collects data about how objects appear when rendered.
	*/
	public class MovieMaterial extends BitmapMaterial implements ITriangleDrawer, IUpdateBeforeMaterial
	{
		// ______________________________________________________________________ PUBLIC
		
		private var _animated:Boolean;
		
		/**
		* The MovieClip that is used as a texture.
		*/
		public var movie :DisplayObject;

		/**
		* A Boolean value that determines whether the MovieClip is transparent. The default value is false, which is much faster.
		*/
		public var movieTransparent :Boolean;
		
		/**
		* When updateBitmap() is called on an animated material, it looks to handle a change in size on the texture.
		* 
		* This is true by default, but in certain situations, like drawing on an object, you wouldn't want the size to change
		*/
		public var allowAutoResize:Boolean = true;


		// ______________________________________________________________________ ANIMATED

		/**
		* A Boolean value that determines whether the texture is animated.
		*
		* If set, the material must be included into the scene so the BitmapData texture can be updated when rendering. For performance reasons, the default value is false.
		*/
		public function get animated():Boolean
		{
			return _animated;
		}

		public function set animated( status:Boolean ):void
		{
			_animated = status;
		}
		
		/**
		* A texture object.
		*/		
		override public function get texture():Object
		{
			return this._texture;
		}
		/**
		* @private
		*/
		override public function set texture( asset:Object ):void
		{
			if( asset is DisplayObject == false )
			{
				Papervision3D.log("Error: MovieMaterial.texture requires a Sprite to be passed as the object");
				return;
			}
			bitmap = createBitmapFromSprite( DisplayObject(asset) );
			_texture = asset;
		}

		// ______________________________________________________________________ NEW

		/**
		* The MovieMaterial class creates a texture from an existing MovieClip instance.
		*
		* @param	movieAsset		A reference to an existing MovieClip loaded into memory or on stage
		* @param	transparent		[optional] - If it's not transparent, the empty areas of the MovieClip will be of fill32 color. Default value is false.
		* @param	animated		[optional] - a flag setting whether or not this material has animation.  If set to true, it will be updated during each render loop
		*/
		public function MovieMaterial( movieAsset:DisplayObject=null, transparent:Boolean=false, animated:Boolean=false, precise:Boolean = false )
		{
			movieTransparent = transparent;
			this.animated = animated;
			this.interactive = interactive;
			this.precise = precise;
			if( movieAsset ) texture = movieAsset;
		}
		
		// ______________________________________________________________________ CREATE BITMAP

		/**
		* 
		* @param	asset
		* @return
		*/
		protected function createBitmapFromSprite( asset:DisplayObject ):BitmapData
		{
			// Set the new movie reference
			movie = asset;
			
			// initialize the bitmap since it's new
			initBitmap( movie );
			
			// Draw
			drawBitmap();

			// Call super.createBitmap to centralize the bitmap specific code.
			// Here only MovieClip specific code, all bitmap code (maxUVs, AUTO_MIP_MAP, correctBitmap) in BitmapMaterial.
			bitmap = super.createBitmap( bitmap );

			return bitmap;
		}
		
		protected function initBitmap( asset:DisplayObject ):void
		{
			// Cleanup previous bitmap if needed
			if( bitmap )
				bitmap.dispose();
			
		
			
			// Create new bitmap
			if(asset.width == 0 || asset.height == 0){
				bitmap = new BitmapData(256,256,movieTransparent, fillColor);
			}else{
				bitmap = new BitmapData( asset.width, asset.height, this.movieTransparent );
			}
			
		}

		// ______________________________________________________________________ UPDATE

		/**
		* Updates animated MovieClip bitmap.
		*
		* Draws the current MovieClip image onto bitmap.
		*/
		public function updateBeforeRender(renderSessionData:RenderSessionData):void
		{
			if(_animated){
				// using int is much faster than using Math.floor. And casting the variable saves in speed from having the avm decide what to cast it as
				var mWidth:int = int(movie.width);
				var mHeight:int = int(movie.height);
				
				if( allowAutoResize && ( mWidth != bitmap.width || mHeight != bitmap.height ) )
				{
					// Init new bitmap size
					initBitmap( movie );
					var recreateBitmapInSuper:Boolean = true;
				}
				
				drawBitmap();
				
				if (recreateBitmapInSuper)
					bitmap = super.createBitmap( bitmap );
			}		
		}
		
		public function drawBitmap():void
		{
			bitmap.fillRect( bitmap.rect, this.fillColor );

			var mtx:Matrix = new Matrix();
			mtx.scale( movie.scaleX, movie.scaleY );

			bitmap.draw( movie, mtx, movie.transform.colorTransform );
		}
		
				
		
	}
}