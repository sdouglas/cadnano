/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls.autoCompleteClasses {
import flash.text.TextFormat;
	
import fl.events.ComponentEvent;
import fl.core.InvalidationType;
import fl.controls.listClasses.CellRenderer;
import fl.core.UIComponent;
//--------------------------------------
//  Class description
//--------------------------------------
/**
 * The AutoCompleteCellRenderer is the default renderer of a Menu's rows, 
 * adding support for branch icons and display of submenus.
 *
 * @langversion 3.0
 * @playerversion Flash 9.0.28.0
 * @includeExample examples/ButtonExample.as
 */	
public class AutoCompleteCellRenderer extends CellRenderer
{
	public function AutoCompleteCellRenderer() 
	{
		super();
		super.drawTextFormat();
	}
		
		
		/**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
		 */
		override protected function drawTextFormat():void 
		{
			//overrides highlighted text if emphasizeMatch is true
		}
}
}