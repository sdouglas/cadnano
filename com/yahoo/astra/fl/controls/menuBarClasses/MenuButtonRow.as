/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls.menuBarClasses
{
	import com.yahoo.astra.fl.controls.Menu;
	import com.yahoo.astra.fl.controls.AbstractButtonRow;
	import com.yahoo.astra.fl.events.MenuEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.ui.Keyboard;
	import fl.data.DataProvider;
	import com.yahoo.astra.fl.controls.menuBarClasses.MenuButton;
	import com.yahoo.astra.fl.events.MenuButtonRowEvent;
	import flash.display.DisplayObject;
	import fl.controls.Button;	

	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * Dispatched when a MenuButton is pressed.
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuButtonRowEvent.ITEM_DOWN
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="itemDown", type="com.yahoo.astra.fl.events.MenuButtonRowEvent")]	
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * Dispatched when a MenuButton is moused over.
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuButtonRowEvent.ITEM_ROLL_OVER
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="itemRollOver", type="com.yahoo.astra.fl.events.MenuButtonRowEvent")]	
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * Dispatched when a MenuButton is released.
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuButtonRowEvent.ITEM_UP
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="itemUp", type="com.yahoo.astra.fl.events.MenuButtonRowEvent")]		
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
    /**
     * The skin to be used to display the background of the button row.
     *
     * @default MenuBar_background
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */
    [Style(name="skin", type="Class")]
	
	/**
	 * The MenuButtonRow extends AbstractButtonRow and creates a row of MenuButton instances.
	 *
	 * @see com.yahoo.astra.fl.controls.AbstractButtonRow
	 *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges	 
	 */
	public class MenuButtonRow extends AbstractButtonRow
	{

	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */		
		public function MenuButtonRow(value:Object = null)
		{        
			super();	
			tabEnabled = false;
			_selectedIndex = _focusIndex = -1;
			if(value != null) value.addChild(this);
			_skin = getDisplayObjectInstance(getStyleValue("skin"));
			this.addChild(_skin);
			this.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, keyFocusChangeHandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, navigationKeyDownHandler, false, 0, true);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
				
		/**
		 * Creates the Accessibility class.
		 * This method is called from UIComponent.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		
		public static var createAccessibilityImplementation:Function;		
				
		/**
		 * @private (protected)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		
		protected var _skin:DisplayObject;
				
		/**
		 * @private
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		
		private static var defaultStyles:Object =
		{
			skin:"MenuBar_background"
		}	
		
		/**
		 * Gets the array of buttons (read-only)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		public function get buttons():Array
		{
			return _buttons;
		}
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * @copy fl.core.UIComponent#getStyleDefinition()
		 *
		 * @includeExample ../core/examples/UIComponent.getStyleDefinition.1.as -noswf
		 *
		 * @see fl.core.UIComponent#getStyle()
		 * @see fl.core.UIComponent#setStyle()
		 * @see fl.managers.StyleManager
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		public static function getStyleDefinition():Object
		{
			return defaultStyles;
		}	
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------		

		/**
		 * @private (protected)
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 * 
		 */		
		override protected function initializeAccessibility():void
		{
			if(MenuButtonRow.createAccessibilityImplementation != null)
			{
				MenuButtonRow.createAccessibilityImplementation(this);
			}
		}		
		
		/**
		 * @private (protected)
		 * 
		 * Updates the position and size of the buttons.
		 *
		 * Overrides the AbstractButtonRow <code>drawButtons</code> function.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		override protected function drawButtons():void
		{
			//xPosition and yPosition need to be configurable
			//should pull from topPadding and leftPadding variables
			//which will need to be created
			var xPosition:Number = 0;
			var yPosition:Number = 0;
			var buttonCount:int = _dataProvider.length;
			for(var i:int = 0; i < buttonCount; i++)
			{
				var button:MenuButton = this.getButton() as MenuButton;
				button.rightButton = (i == buttonCount-1 && i != 0);
				button.leftButton = (i == 0 && buttonCount > 1);
				button.addEventListener(MouseEvent.MOUSE_DOWN, buttonDownHandler, false, 0, true);
				button.addEventListener(MouseEvent.ROLL_OVER, buttonRollOverHandler, false, 0, true);
				button.addEventListener(MouseEvent.MOUSE_UP, buttonUpHandler, false, 0, true);
				this._buttons.push(button);
				
				var item:Object = this._dataProvider.getItemAt(i);
				button.label = this.itemToLabel(item);
				button.selected = this._selectedIndex == i;
				if(i == this._selectedIndex)
				{
					button.setMouseState("down");
				}
				else if(i == this._focusIndex)
				{
					button.setMouseState("over");
				}
				else
				{
					button.setMouseState("up");
				}
				
				button.x = xPosition;
				button.y = yPosition;
				button.height = this.height;
				button.drawNow();
				
				xPosition += button.width;
			}
			//width changes automatically based on the size of the tabs.
			this.width = xPosition;
			_skin.width = width;
			_skin.height = height;			
		}
		
		/**
		 * @private (protected)
		 * 
		 * Either retrieves a button from the cache or creates a new one.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		override protected function getButton():Button
		{
			var button:MenuButton;
			if(this._cachedButtons.length > 0)
			{
				button = this._cachedButtons.shift() as MenuButton;
			}
			else
			{
				button = new MenuButton();	
				button.toggle = false;	
				button.tabEnabled = false;
				this.addChild(button);
			}
			return button;
		}		
			
		/**
		 * @private (protected)
		 * 
		 * Captures click events from each button and dispatches the
		 * MenuButtonRowEvent.ITEM_CLICK event to listeners.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		protected function buttonDownHandler(event:MouseEvent):void
		{		
			dispatchEvent(new MenuButtonRowEvent(MenuButtonRowEvent.ITEM_DOWN, false, false, selectedIndex, event.currentTarget, event.currentTarget.label));
		}
		
		/**
		 * @private (protected)
		 * 
		 * Captures roll-over events from each button and dispatches the
		 * MenuButtonRowEvent.ITEM_ROLL_OVER event to listeners.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		 
		protected function buttonRollOverHandler(event:MouseEvent):void
		{
			dispatchEvent(new MenuButtonRowEvent(MenuButtonRowEvent.ITEM_ROLL_OVER, false, false, selectedIndex, event.currentTarget, event.currentTarget.label));
		}
		
		/**
		 * @private (protected)
		 * 
		 * Capture mouseUp events from each button and dispatches the
		 * MenuButtonRowEvent.ITEM_UP event to listeners
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0		
		 */
		protected function buttonUpHandler(event:MouseEvent):void
		{
			dispatchEvent(new MenuButtonRowEvent(MenuButtonRowEvent.ITEM_UP, false, false, selectedIndex, event.currentTarget, event.currentTarget.label));
		}
				
		/**
		 * @private (protected)
		 * 
		 * Removes unneeded buttons that were cached for a redraw.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		 
		override protected function clearCache():void
		{
			var cacheLength:int = this._cachedButtons.length;
			for(var i:int = 0; i < cacheLength; i++)
			{
				var button:MenuButton = this._cachedButtons.pop() as MenuButton;
				button.removeEventListener(MouseEvent.ROLL_OVER, buttonRollOverHandler);
				button.removeEventListener(MouseEvent.MOUSE_DOWN, buttonDownHandler);
				button.removeEventListener(MouseEvent.MOUSE_UP, buttonUpHandler);
				this.removeChild(button);
			}
		}
		
		/**
		 * @private (protected)
		 *
		 * Listen for events to allow for keyboard navigation.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		override protected function navigationKeyDownHandler(event:KeyboardEvent):void
		{
			var len:int = _buttons.length - 1;
			if(_selectedIndex > -1 && len > -1)
			{
				switch(event.keyCode)
				{
					//right goes to next tab
					case Keyboard.RIGHT:
						if(len == 0)
						{
							_buttons[_selectedIndex].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
						}
						else if(_selectedIndex == len)
						{
							_buttons[0].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
						}
						else if(_selectedIndex < len) 
						{
							_buttons[_selectedIndex + 1].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
						}
						break;
					//left goes to previous tab
					case Keyboard.LEFT:					
						if(len == 0)
						{
							_buttons[_selectedIndex].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
						}
						else if(_selectedIndex == 0)
						{
							_buttons[len].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
						}
						else if(_selectedIndex > 0)
						{
							_buttons[_selectedIndex - 1].dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
						}
						break;
				}
			}
			event.updateAfterEvent();
		}
		
		/**
		 * @private (protected)
		 *
		 * disables default tab key behavior
		 * 
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		protected function keyFocusChangeHandler(event:FocusEvent):void
		{
			if(event.keyCode == Keyboard.TAB)
			{
				event.preventDefault();
				event.stopPropagation();	
			}
		}
		
	}	
}