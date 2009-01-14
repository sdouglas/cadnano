/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls.containerClasses
{
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import fl.core.UIComponent;
	import flash.text.TextFieldType;

	//--------------------------------------
	//  Class description
	//--------------------------------------

	/**
	 * MessageBox extends UIComponent and creates a text field based on minimum and 
	 * maximum widths<
	 *
	 * @see fl.core.UIComponent
	 *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges	
	 */	
	public class MessageBox extends UIComponent
	{

	//--------------------------------------
	//  Constructor
	//--------------------------------------

		/**
		 * Constructor
		 */
		public function MessageBox()
		{
			_textField = new TextField();
			_autoSizeStyle = TextFieldAutoSize.CENTER;
		}

	//--------------------------------------
	//  Properties
	//--------------------------------------
	
		/**
		 * @private (protected)
		 */
		protected var _textField:TextField;	
		protected var _type:String;	
		
		/**
		 * Gets the value of the text field. (read-only)
		 */
		public function get textField():TextField
		{
			return _textField;
		}		
		
		/**
		 * @private (protected)
		 */		
		protected var _autoSizeStyle:String;
		
		/**
		 * Gets or sets autoSizeStyle
		 */
		public function get autoSizeStyle():String
		{
			return _autoSizeStyle;	
		}
		
		/**
		 * @private (setter)
		 */	
		public function set autoSizeStyle(value:String):void {_autoSizeStyle = value;}		
		
		public function set type(value:String):void {
			_type = value;
			_textField.type = value;
		}

		/**
		 * The color of the text.
		 */
		public var textColor:uint = 0xffffff;
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------

		/**
		 * Displays the message text and updates the height of the MessageBox
		 *
		 * @param maxTextWidth - maximum width allowed for textfield
		 * @param minTextWidth - minimum width allowed for textfield
		 * @param messageText - string to display in the text field
		 */ 
		public function drawMessage(maxTextWidth:int, minTextWidth:int, messageText:String):void
		{
            //trace("messageBox drawMessage called", messageText);
			var textFieldWidth:int = getTextFieldWidth(messageText, maxTextWidth, minTextWidth);
			_textField.multiline = false;
			_textField.wordWrap = true;
			_textField.autoSize = _autoSizeStyle;
			_textField.width = textFieldWidth;
			if (_type == TextFieldType.INPUT){
				_textField.border = true;
			}else {
				_textField.border = false;
			}
			_textField.height = 5;
			var tF:TextFormat = new TextFormat("_sans", 14);
			tF.align = _autoSizeStyle;
			tF.color = textColor;
			_textField.defaultTextFormat = tF;
			_textField.text = messageText;
			this.width = _textField.width;
		}
	
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * @private (protected)
		 * Gets the width of the text field.
		 *
		 * @param message - text to use
		 * @param maxTextWidth - maximum width allowed for textfield		 
		 * @paramminTextWidth - minimum width allowed for textfield		 
		 *
		 * @return int
		 */
		protected function getTextFieldWidth(message:String, maxTextWidth:int, minTextWidth:int):int
		{
			var textFieldWidth:int;
			var tempText:TextField = new TextField();
			var tF:TextFormat = new TextFormat("_sans", 14);
			tF.align = _autoSizeStyle;	
			tempText.defaultTextFormat = tF;
			tempText.width = 10;
			tempText.height = 5;
			tempText.wordWrap = false;
			tempText.multiline = false;
			tempText.autoSize = TextFieldAutoSize.LEFT;
			tempText.text = message;
			var tempTextWidth:int = Math.round(tempText.width);
			if(tempTextWidth > maxTextWidth)
			{
				textFieldWidth = maxTextWidth;				
			}
			else if(tempTextWidth > minTextWidth)
			{
				textFieldWidth = tempTextWidth;
			}
			else
			{
				textFieldWidth = minTextWidth;
			}		
			if(_autoSizeStyle == TextFieldAutoSize.LEFT) textFieldWidth += 1;
			return textFieldWidth;			
		}		
	}
}