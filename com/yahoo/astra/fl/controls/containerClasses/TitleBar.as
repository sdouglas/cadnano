/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls.containerClasses
{
	import fl.controls.Label;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;	
	import flash.display.DisplayObject;
	import fl.events.ComponentEvent;
	import fl.core.InvalidationType;

	//--------------------------------------
	//  Class description
	//--------------------------------------

	/**
	 * TitleBar extends Label, adding a background.  It is used by DialogBox.
	 *
     * @see fl.controls.Label
     * @see com.yahoo.astra.fl.controls.containerClasses.DialogBox
	 *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges	
	 */		
	public class TitleBar extends Label
	{

	//--------------------------------------
	//  Constructor
	//--------------------------------------	
	
		/**
		* Constructor
		*/
		public function TitleBar()
		{
			super();
		}		

	//--------------------------------------
	//  Properties
	//--------------------------------------		
		
		/**
		 * @private (protected)
		 */
		//background for the title bar
		protected var background:DisplayObject;
		
		/**
		 * Maximum width of the TitleBar instance
		 */
		public var maxWidth:int;		
		
		/**
		 * @private
		 */
		//styles for the titlebar
		private static var defaultStyles:Object = 
		{
			backgroundSkin:"Title_skin"
		};
		
		/**
		 * Color of the text
		 */
		public var textColor:uint = 0xffffff;		
		
		
		/**
		 * @private (setter)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 * override label set text adding setStyle
		 */		
		override public function set text(value:String):void
		{
			setStyle("textFormat", new TextFormat("_sans", 12, textColor, true, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0)),

			// Clear the HTML value, and redraw.
			_html = false;
			textField.text = value;	

			if (value == text) 
			{ 
				return;
			}			
			// Value in the PI is the default.
			if (componentInspectorSetting && value == defaultLabel) 
			{
				return;
			}
			
			if (textField.autoSize != TextFieldAutoSize.NONE) 
			{ 
				invalidate(InvalidationType.SIZE);
			}
		}
		
		/**
		 * @private (setter)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */	
		override public function get height():Number
		{
			var ht:Number = actualHeight;
			if(!isNaN(ht)) ht = _height;
			if(!isNaN(ht)) ht = this.textField.height;
			return _height;
		}		
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------				
		
		/**
		 * @return defaultStyles
		 */
		public static function getStyleDefinition():Object
		{
			return defaultStyles;
		}	
		
		/**
		 * Resizes the background skin
		 *
		 * @param wid - width to set the background
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */	
		public function drawBackground(wid:Number):void
		{
			this.background.width = wid;	
			this.background.height = _height;
		}

	//--------------------------------------
	//  Protected methods
	//--------------------------------------				
				
		/**
		 * @private (protected)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */			 
		override protected function configUI():void
		{
			super.configUI();
			this.textField.mouseEnabled = false;
			this.wordWrap = false;
			this.textField.autoSize = TextFieldAutoSize.LEFT;
			this.background = getDisplayObjectInstance(getStyleValue("backgroundSkin"));
			this.addChildAt(background, 0);
		}	
		
		/**
		 * @private (protected)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		 //Truncate the text field and call drawLayout if the text width is greater than 
		 //the maxWidth.  If not, dispatch the resize event
		override protected function drawLayout():void 
		{
			var resized:Boolean = false;
			
			textField.width = width;
			textField.height = height;			
			
			if (textField.autoSize != TextFieldAutoSize.NONE) 
			{
				
				var txtW:Number = textField.width;
				var txtH:Number = textField.height;
				
				resized = (_width != txtW || _height != txtH);				
				// set the properties directly, so we don't trigger a callLater:
				_width = txtW;
				_height = txtH;
				
				switch (textField.autoSize) 
				{
					case TextFieldAutoSize.CENTER:
						textField.x = (actualWidth/2)-(textField.width/2);
						break;
					case TextFieldAutoSize.LEFT:
						textField.x = 0;
						break;
					case TextFieldAutoSize.RIGHT:
						textField.x = -(textField.width - actualWidth);
						break;
				}
			} 
			else 
			{
				textField.width = actualWidth;
				textField.height = actualHeight;
				textField.x = 0;	
			}

			if(_width > maxWidth)
			{
				var truncatedText:String;					
				var tempText = this.textField.text;
				truncatedText = (tempText.lastIndexOf(" ") > 0)?tempText.slice(0, tempText.lastIndexOf(" ")) + "...":tempText.slice(0, this.textField.getCharIndexAtPoint(maxWidth, Math.round(_height/2)) - 3) + "...";
				textField.text = truncatedText;
				drawLayout();
			}
			else
			{
				dispatchEvent(new ComponentEvent(ComponentEvent.RESIZE, true));
			}				
		}		
	}
}