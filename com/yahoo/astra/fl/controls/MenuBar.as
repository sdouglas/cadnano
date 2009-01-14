/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls
{
	import com.yahoo.astra.fl.controls.Menu;
	import com.yahoo.astra.fl.events.MenuEvent;
	import com.yahoo.astra.fl.controls.menuBarClasses.MenuButtonRow;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.ui.Keyboard;
	import fl.data.DataProvider;
	import com.yahoo.astra.fl.controls.menuBarClasses.MenuButton;
	import com.yahoo.astra.fl.events.MenuButtonRowEvent;
	import flash.display.DisplayObject;
	import fl.core.UIComponent;
	
	//--------------------------------------
	//  Events
	//--------------------------------------	
 
	 /**
	 * Dispatched when the user clicks an item in the menu. 
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuEvent.ITEM_CLICK
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="itemClick", type="com.yahoo.astra.fl.events.MenuEvent")]		

	/**
	 * Dispatched when a menu is shown
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuEvent.MENU_SHOW
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="menuShow", type="com.yahoo.astra.fl.events.MenuEvent")]
	
	/**
	 * Dispatched when a menu is hidden.
	 *
	 * @eventType com.yahoo.astra.fl.events.MenuEvent.MENU_HIDE
	 *
	 * @langversion 3.0
	 * @playerversion Flash 9.0.28.0
	 */
	[Event(name="menuHide", type="com.yahoo.astra.fl.events.MenuEvent")]

	//--------------------------------------
	//  Styles
	//--------------------------------------	
	
	/**
	 * The number of pixels the top level menu will appear to the right of MenuBar 
	 * button.  A negative value can be used to set the menu to the left of the 
	 * MenuBar button. The default value is 5.
     *
     * @default 5
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="xOffset", type="Number")]

	/**
     * The number of pixels the top level menu will appear below the MenuBar button. 
	 * A negative value can be used to have the menu overlap the MenuBar button. The 
	 * default value is 5.
     *
     * @default 5
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="yOffset", type="Number")]
	
	
	/**
	 * The number of pixels between the left edge of the menu and the left edge of 
	 * the stage when the stage is too narrow to fit the menu. If the value were set 
	 * to 0, the left edge of the menu would be flush with the left edge of the stage. 
     *
     * @default 0
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="menuLeftMargin", type="Number")]
	
	/**
	 * The number of pixels between the bottom of the menuBar and the top of the 
	 * menu when the stage is to short to fit the menu. If the value were set to 0, 
	 * the top of the menu would be flush with bottom edge of the menuBar. 
     *
     * @default 0
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="menuTopMargin", type="Number")]	
	
	/**
	 * The number of pixels for a bottom gutter to a menu when the stage to short to 
	 * fit the menu. If the value were set to 0, the bottom of the menu would be 
	 * flush with the bottom edge of the stage. 
     *
     * @default 0
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="menuBottomMargin", type="Number")]	 

	/**
	 * The number of pixels between the right edge of the menu and the right edge of 
	 * the stage when the stage is too narrow to fit the menu. If the value were set 
	 * to 0, the right edge of the menu would be flush with the left edge of the 
	 * stage. 	
     *
     * @default 0
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="menuRightMargin", type="Number")]	 
	
	/**
	 * The number of pixels that each submenu will appear to right of its parent 
	 * menu. A negative value can be used to have the menus overlap. 
     *
     * @default -3
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="subMenuXOffset", type="Number")]		

	/**
	 * The number of pixels that each submenu will appear below the top of its parent 
	 * menu. A negative value can be used to have the menu appear above its parent 
	 * menu. 	
	 *
     * @default 3
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     */	
	[Style(name="subMenuYOffset", type="Number")]		

	/**
	 * The MenuBar extends the UIComponent and manages a MenuButtonRow and corresponding
	 * instances of Menu.
	 *
	 * @see fl.core.UIComponent
	 * @see com.yahoo.astra.fl.controls.MenuButtonRow
	 * @see com.yahoo.astra.fl.controls.Menu
	 *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges	 
	 */
	public class MenuBar extends UIComponent
	{

	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */		
		public function MenuBar(value:Object = null)
		{
			super();	
			tabEnabled = false;
			if(value != null) value.addChild(this);
			_buttonRow = new MenuButtonRow(this);
			_buttonRow.height = height;
			_buttonRow.addEventListener(MenuButtonRowEvent.ITEM_DOWN, itemDownHandler, false, 0, true);
			_buttonRow.addEventListener(MenuButtonRowEvent.ITEM_ROLL_OVER, itemRollOverHandler, false, 0, true);
			_buttonRow.addEventListener(MenuButtonRowEvent.ITEM_UP, itemUpHandler, false, 0, true);	
			if(this.isLivePreview)
			{
				_buttonRow.dataProvider = new DataProvider(["No live preview data"]);
			}				
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
	
        /**
         * @private
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
		private static var defaultStyles:Object = {
			xOffset:0,
			yOffset:0,
			menuLeftMargin:0,
			menuTopMargin:0,
			menuBottomMargin:0,
			menuRightMargin:0,
			subMenuXOffset:0,
			subMenuYOffset:0
		}
	
		/**
		 * @private (protected)
		 * 
		 * Instance of the MenuButtonRow.  Contains a row of buttons that control the menu 
		 * instances.
		 */
		protected var _buttonRow:MenuButtonRow;

		[Inspectable(defaultValue="false",type=Boolean)]
		/**
		 * Indicates whether or not to close open menus when the mouse leaves the stage 
		 * of the flash application. The default value is false.
		 */
		public var closeMenuOnMouseLeave:Boolean = false;
		
		[Inspectable(defaultValue=true,type=Boolean)]		
		/**
		 * Indicates whether or not a menu link that spawns a child menu will be 
		 * clickable. The default value is true. 
		 */
		public var parentMenuClickable:Boolean = true;
		
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
		 */
		protected var _dataProvider:XML;
		
		/**
		 * Gets or sets the XML dataProvider for the menubar and it's submenus.
		 */
		 public function get dataProvider():XML
		 {
			 return _dataProvider;
		 }
		 
		/**
		 * @private (setter)
		 */
		public function set dataProvider(menus:XML):void
		{
			_dataProvider = menus;
			var tabValues:Array = [];
			for each (var element:XML in menus.elements())
			{
				var tabValue:String = element.@label.toString();
				tabValues.push(tabValue); 		
				var menu:Menu = Menu.createMenu(this, element);
				menu.parentMenuClickable = parentMenuClickable;
				menu.setStyle("xOffset", Number(getStyleValue("subMenuXOffset")));
				menu.setStyle("yOffset", Number(getStyleValue("subMenuYOffset")));
				menu.setStyle("leftMargin", Number(getStyleValue("menuLeftMargin")));
				menu.setStyle("rightMargin", Number(getStyleValue("menuRightMargin")));
				menu.setStyle("topMargin", Number(getStyleValue("menuTopMargin")));
				menu.setStyle("bottomMargin", Number(getStyleValue("menuBottomMargin")));
				menu.name = tabValue;
				menu.closeOnMouseLeave = closeMenuOnMouseLeave;
				menu.addEventListener(MenuEvent.MENU_HIDE, clearSelected);
				menu.addEventListener(MenuEvent.ITEM_CLICK, dispatchMenuEvents);
				menu.addEventListener(MenuEvent.MENU_HIDE, dispatchMenuEvents);
				menu.addEventListener(MenuEvent.MENU_SHOW, dispatchMenuEvents);
				_menus.push(menu);
			}
			
			_buttonRow.dataProvider = new DataProvider(tabValues);
		}	
		
		/**
		 * @private (protected)
		 */
		protected var _menus:Array = [];		
						
		
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
		 * Listens for the MenuButtonRowEvent.ITEM_UP event and toggles menus.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */
		protected function itemDownHandler(event:MenuButtonRowEvent):void
		{		
			var selectedIndex:int = event.index;
			var button:MenuButton = event.item as MenuButton;
			var index:int = _buttonRow.buttons.indexOf(button);
			
			if(index == selectedIndex)			
			{
				_buttonRow.selectedIndex = -1;
				_menus[index].hide();
				button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
			}
			else
			{
				if(selectedIndex != -1) _menus[selectedIndex].hide(false);
				_buttonRow.selectedIndex = index;
				_menus[index].show(button.x + Number(getStyleValue("xOffset")), button.y + button.height + Number(getStyleValue("yOffset")));
				_menus[index].setFocus();
			}
		}
		
		/**
		 * @private (protected)
		 * 
		 * Listens for the MenuButtonRowEvent.ITEM_ROLL_OVER event and toggles menus.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		 
		protected function itemRollOverHandler(event:MenuButtonRowEvent):void
		{
			var button:MenuButton = event.item as MenuButton;
			var selectedIndex:int = event.index;
			var index:int = _buttonRow.buttons.indexOf(button);
			
			if(index != selectedIndex && selectedIndex != -1)
			{		
				_menus[selectedIndex].hide(false);
				_buttonRow.selectedIndex = index;
				_menus[index].show(button.x + Number(getStyleValue("xOffset")), button.y + button.height + Number(getStyleValue("yOffset")));
			}
		}
		
		/**
		 * @private (protected)
		 * 
		 * Listens for the MenuButtonRowEvent and sets focus on the selected 
		 * button.
		 *
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0		
		 */
		protected function itemUpHandler(event:MenuButtonRowEvent):void
		{
			var selectedIndex:int = _buttonRow.selectedIndex;
			if(selectedIndex > -1) _menus[selectedIndex].setFocus();
		}
				
		/**
		 * @private (protected)
		 *
		 * Listens for the menu hide event 
		 * If the hide event came from the currently selected button, clear the selected index
		 * Used to manage the menu bar button states when the menu is closed by the active button or within the menu
		 * 
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */		
		protected function clearSelected(event:MenuEvent):void
		{
			var selectedIndex:int = _buttonRow.selectedIndex;
			var menu:Menu = event.target as Menu;
			var index:int = _menus.indexOf(menu);
			var button:MenuButton = _buttonRow.buttons[index];	
			if(index == selectedIndex) _buttonRow.selectedIndex = -1;	
		}	
		
		/**
		 * @private (protected)
		 * 
		 * Listens for menu events and dispatches them.
		 * 
		 * @langversion 3.0
		 * @playerversion Flash 9.0.28.0
		 */	
		protected function dispatchMenuEvents(event:MenuEvent):void
		{
			dispatchEvent(event as MenuEvent);
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