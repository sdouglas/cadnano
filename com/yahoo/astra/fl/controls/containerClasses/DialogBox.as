/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls.containerClasses
{
    import br.com.stimuli.loading.BulkErrorEvent;
    import flash.text.*;
    import flash.display.Graphics;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import com.yahoo.astra.fl.controls.containerClasses.MessageBox;
    import fl.events.ComponentEvent;
    import com.yahoo.astra.fl.controls.containerClasses.TitleBar;
    import flash.display.Stage;
    import fl.core.UIComponent;
    import flash.utils.Dictionary;
    import flash.text.TextFieldAutoSize;
    import flash.filters.DropShadowFilter;
    import flash.events.KeyboardEvent;
    import flash.events.FocusEvent;
    import flash.ui.Keyboard;
    import flash.display.Sprite;

    //--------------------------------------
    //  Class description
    //--------------------------------------

    /**
     * DialogBox extends UIComponent and builds an AlertBox by assembling a TitleBar,
     * MessageBox and ButtonBar
     *
     * @see fl.core.UIComponent
     * @see com.yahoo.astra.fl.controls.containerClasses.TitleBar
     * @see com.yahoo.astra.fl.controls.containerClasses.MessageBox
     * @see com.yahoo.astra.fl.controls.containerClasses.ButtonBar
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges
     */
     
    public class DialogBox extends UIComponent
    {
        protected var _type:String;
    //--------------------------------------
    //  Constructor
    //--------------------------------------
    
        /**
         * Constructor
         *
         * @param container - DisplayObjectContainer to add the alert
         */
        public function DialogBox(container:Stage, type:String=TextFieldType.DYNAMIC)
        {
            _type = type;
            _messageBox.type = _type;
            _stage = container;
            this.visible = false;
        }
        
    //--------------------------------------
    //  Constants
    //--------------------------------------
    
        /**
         * @private (protected)
         */
        protected const TITLE:String = "title";
        
        /**
         * @private (protected)
         */
        protected const BUTTONS:String = "buttons";
        
    //--------------------------------------
    //  Properties
    //--------------------------------------
        // Sprite where special content can be displayed.
        protected var _canvas:Sprite;
        
        /**
         * @private (protected)
         */
        //instance of the title bar
        protected var _titleBar:TitleBar;
        
        /**
         * @private (protected)
         */
        //Distance from the top of the component when the user presses his mouse on the
        //title bar.  Used to calculate the drag.
        protected var _dragOffSetY:Number;
        
        /**
         * @private (protected)
         */
        //Distance from the left of the component when the user presses his mouse on the
        //title bar.  Used to calculate the drag.
        protected var _dragOffSetX:Number;
        
        /**
         * @private (protected)
         */
        //Reference to the ButtonBar class instance which manages the buttons
        public var _buttonBar:ButtonBar;
        
        /**
         * @private (protected)
         */
        protected var _minWidth:int;
        
        /**
         * Gets the value of the text field. (read-only)
         */
        public function get textField():TextField
        {
            return _messageBox.textField;
        }
        
        /**
         * Gets or sets the minimum width of the dialog box
         */
        public function get minWidth():int
        {
            return _minWidth;
        }
        
        /**
         * @private (setter)
         */
        public function set minWidth(value:int):void
        {
            _minWidth = value;
        }
        
        /**
         * @private (protected)
         */
        protected var _maxWidth:int;
        
        /**
         * Gets or sets the maximum width of the dialog box
         */
        public function get maxWidth():int
        {
            return _maxWidth;
        }
        
        /**
         * @private (setter)
         */
        public function set maxWidth(value:int):void
        {
            _maxWidth = value;
            //_buttonBar.maxWidth = _maxWidth - (_padding*2);
            _buttonBar.maxWidth = 300;
            _titleBar.maxWidth = _maxWidth;
        }
        
        /**
         * @private (protected)
         */
        protected var _padding:int;
        
        /**
         * Gets or sets the padding between components and edges
         */
        public function get padding():int
        {
            return _padding;
        }
        
        /**
         * @private (setter)
         */
        public function set padding(value:int):void
        {
            _padding = value;
            _buttonBar.maxWidth = 300;
            //_buttonBar.maxWidth = _maxWidth - (_padding*2);
        }
        
        /**
         * @private (protected)
         */
        //reference to the stage
        protected var _stage:Stage;
        
        /**
         * @private (protected)
         */
        //background skin
        protected var _skin:DisplayObject;
        
        /**
         * @private (protected)
         */
        //MessageBox instance used for the text area of the dialog
        protected var _messageBox:MessageBox;
        
        /**
         * @private (protected)
         */
        //reference to the text field in the message box
        protected var _message:TextField;
        
        /**
         * @private (protected)
         */
        //text to be rendered in the dialog
        protected var messageText:String;
        
        /**
         * @private (protected)
         */
        //Boolean indicating whether title has been drawn.  Used to determine whether
        //the elements should be positioned.
        protected var _titleDrawn:Boolean;
        
        /**
         * @private (protected)
         */
        //Boolean indicating whether buttons have been drawn.  Used to determine whether
        //the elements should be positioned</p>
        protected var _buttonsDrawn:Boolean;
        
        /**
         * @private (protected)
         */
        //class to use for an icon image
        protected var _iconClass:DisplayObject;
        
        /**
         * @private (protected)
         */
        //Indicates whether to display an icon graphic
        protected var _hasIcon:Boolean;
        
        /**
         * @private (protected)
         */
        //collection of icons that can be reused
        protected var _icons:Dictionary = new Dictionary();
        
        /**
         * @private
         */
        private static var defaultStyles:Object =
        {
            skin:"Background_skin"
        };
        
        /**
         * Indicates whether the Alert has a drop shadow
         */
        public var hasDropShadow:Boolean;
        
        /**
         * Direction of the drop shadow
         */
        public var shadowDirection:String;
        
        /**
         * Gets or sets the height of the ButtonBar instance
         */
        public function get buttonHeight():int
        {
            return _buttonBar.height;
        }
        
        /**
         * @private (setter)
         */
        public function set buttonHeight(value:int):void
        {
            _buttonBar.height = value;
        }
        
        /**
         * Gets or sets the value of the rowSpacing on the buttonBar component
         */
        public function get buttonRowSpacing():int
        {
            return _buttonBar.rowSpacing;
        }
        
        /**
         * @private (setter)
         */
        public function set buttonRowSpacing(value:int):void
        {
            _buttonBar.rowSpacing = value;
        }
        
        /**
         * Gets or sets the value of the spacing on the buttonBar component
         */
        public function get buttonSpacing():int
        {
            return _buttonBar.spacing;
        }
        
        /**
         * @private (setter)
         */
        public function set buttonSpacing(value:int):void
        {
            _buttonBar.spacing = value;
        }
        
        /**
         * Get or sets the value of the textColor on the titleBar component
         */
        public function get titleTextColor():uint
        {
            return _titleBar.textColor;
        }
        
        /**
         * @private (setter)
         */
        public function set titleTextColor(value:uint):void
        {
            _titleBar.textColor = value;
        }
        
        /**
         * Get or sets the value of the textColor on the messageBox component
         */
        public function get textColor():uint
        {
            return _messageBox.textColor;
        }
        
        /**
         * @private (setter)
         */
        public function set textColor(value:uint):void
        {
            _messageBox.textColor = value;
        }
        
    //--------------------------------------
    //  Public Methods
    //--------------------------------------
    
        /**
         * returns style definition
         *
         * @return defaultStyles object
         */
        public static function getStyleDefinition():Object
        {
            return defaultStyles;
        }
        
        /**
         * Centers the DialogBox
         */
        public function positionAlert():void
        {
            var left:int = _stage.stageWidth*0.5 - this.width*0.5;
            var top:int = _stage.stageHeight*0.33 - this.height*0.5;
            this.x = left>0?left:0;
            this.y = top>0?top:0;
        }
        
        /**
        * Draws a new DialogBox
        *
        * @param message - message to be displayed
        * @param title - title to be displayed
        * @param buttons - array of buttons to be drawn
        * @param listeners - array of functions to be attached to the buttons
        */
        public function update(message:String, title:String, buttons:Array, listeners:Array, content:Sprite, type:String):void
        {
            _messageBox.type = type;
            
            _titleDrawn = _buttonsDrawn = false;
            this.setFocus();
            
            if (message != messageText) {
                messageText = message;
            }
            
            
            // remove any existing sprites
            for (var i:int = 0; i<this._canvas.numChildren; i++) {
                this._canvas.removeChildAt(0);
            }
            
            // add new sprite
            if (content != null) {
                this._canvas.addChild(content);
            }
            
            if (title != _titleBar.text) {
                _titleBar.text = title;
            } else {
                _titleDrawn = true;
            }
            
            _buttonBar.drawButtons(buttons, listeners);
        }
        
    //--------------------------------------
    //  Protected Methods
    //--------------------------------------
    
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        protected override function configUI():void
        {
            _skin = getDisplayObjectInstance(getStyleValue("skin"));
            this.addChild(_skin);
            _titleBar = new TitleBar();
            _titleBar.buttonMode = true;
            _titleBar.useHandCursor = true;
            _titleBar.name = TITLE;
            _titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragAlert);
            _titleBar.addEventListener(ComponentEvent.RESIZE, resizeHandler);
            this.addChild(_titleBar);
            
            _messageBox = new MessageBox();
            _message = _messageBox.textField;
            _message.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, keyFocusChangeHandler);
            this.addChild(_message);
            _buttonBar = new ButtonBar();
            _buttonBar.name = BUTTONS;
            this.addChild(_buttonBar);
            _buttonBar.addEventListener(ComponentEvent.RESIZE, resizeHandler);
            
            _canvas = new Sprite();
            this.addChild(_canvas);
        }
        
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        //Fired by the resize event of the buttonBar and titleBar components.  Calls the draw function.
        protected function resizeHandler(evnt:ComponentEvent):void
        {
            var targetName:String = evnt.target.name;
            if(targetName == TITLE)
            {
                _titleDrawn = true;
            }
            if(targetName == BUTTONS) _buttonsDrawn = true;
            if(_titleDrawn && _buttonsDrawn) this.drawMessage();
        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        //Compare width of title, buttonBar and _maxWidth.  If buttonBar or titleBar
        //width is greater than max width, set maxTextWidth and minTextWidth to the
        //largest value minus total padding.  Otherwise, set maxTextWidth and minTextWidth
        //to _maxWidth and _minWidth minus total padding, call drawMessage, position and
        //set sizes of elements
        protected function drawMessage():void
        {
            
            var minTextWidth:int;
            var maxTextWidth:int;
            var totalPadding:int = _padding*2;
            
            if (messageText != null)
            {
                var max:int = Math.max(_minWidth, (_buttonBar.width + totalPadding), _titleBar.width, _canvas.width);
                if (max > _minWidth)
                {
                    maxTextWidth = _maxWidth - totalPadding;
                    minTextWidth = max - totalPadding;
                }
                else
                {
                    maxTextWidth = _maxWidth - totalPadding;
                    minTextWidth = _minWidth - totalPadding;
                }
                
                _messageBox.autoSizeStyle = TextFieldAutoSize.CENTER;
                
                _messageBox.drawMessage(maxTextWidth, minTextWidth, messageText);
                _titleBar.y = 0;
                _canvas.y = _titleBar.height + _padding;
                //_message.y = _titleBar.height + _canvas.getBounds(this).bottom + _padding*2;
                if (_canvas.numChildren > 0) {
                    _message.y = _titleBar.height + _canvas.y + _canvas.height + _padding*2;
                } else {
                    _message.y = _titleBar.height + _padding*2;
                }
                
                if (messageText == "") {
                    /* buttonBar positioning breaks when message is not used,
                    so we're just going to position from the bottom of the titlebar. */
                    _buttonBar.y = _canvas.getBounds(this).bottom + _padding + 50;
                } else {
                    _buttonBar.y = _message.getBounds(this).bottom + _padding;
                }
                
                var sizeX:int = Math.max(_message.width,_canvas.width)+_padding*2;
                this.setSize(sizeX, _buttonBar.height + _buttonBar.y  + _padding);
                _canvas.x = Math.round(this.width*0.5) - Math.round(_canvas.width*0.5);
                _message.x = Math.round(this.width*0.5) - Math.round(_message.width*0.5);
                _buttonBar.x = Math.round((this.width)*0.5- (_buttonBar.width)*0.5);
                _titleBar.drawBackground(this.width);
                this.drawSkin();
                this.positionAlert();
                this.visible = true;
            }
        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        //Sets dimensions for the background skin of the message box
        protected function drawSkin():void
        {
            _skin.width = this.width;
            _skin.height = this.height;
            if(hasDropShadow)
            {
                var shadowAngle:int = (shadowDirection == "left")?135:45;
                var filters:Array = [];
                var dropShadow:DropShadowFilter = new DropShadowFilter(2, shadowAngle, 0x000000, .5, 4, 4, 1, 1, false, false, false);
                filters.push(dropShadow);
                _skin.filters = filters;
            }
        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
         //Set x and y offsets based on of the mouse down location
         //Add mouseMove and mouseUp listeners
         //Remove the mouseDown listener
        protected function startDragAlert(evnt:MouseEvent):void
        {
            _dragOffSetX = Math.round(evnt.localX*evnt.target.scaleX);
            _dragOffSetY = Math.round(evnt.localY*evnt.target.scaleY);
            _stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAlert, false, 0, true);
            _stage.addEventListener(MouseEvent.MOUSE_UP, stopAlertDrag, false, 0, true);
            _titleBar.removeEventListener(MouseEvent.MOUSE_DOWN, startDragAlert);
        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        //Moves the Dialog with the mouse
        protected function dragAlert(evnt:MouseEvent):void
        {
            if(evnt.stageX < _stage.stageWidth && evnt.stageY < _stage.stageHeight && evnt.stageX > 0 && evnt.stageY > 0)
            {
                this.x = evnt.stageX - _dragOffSetX;
                this.y = evnt.stageY - _dragOffSetY;
                evnt.updateAfterEvent();
            }
        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
         //Remove mouseMove and mouseUp listeners
         //Add the mouseDown listener
        protected function stopAlertDrag(evnt:MouseEvent):void
        {
            _stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragAlert);
            _stage.removeEventListener(MouseEvent.MOUSE_UP, stopAlertDrag);
            _stage.removeEventListener(Event.MOUSE_LEAVE, stopAlertDrag);
            _titleBar.addEventListener(MouseEvent.MOUSE_DOWN, startDragAlert);
        }
        
        /*
         * @private (protected)
         *
         * Sets focus on the first button.
         *
         * @param event FocusEvent
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        protected function keyFocusChangeHandler(event:FocusEvent):void
        {
            if(event.keyCode == Keyboard.TAB)
            {
                event.preventDefault();
                //reset focus to the first button
                _buttonBar.focusIndex = 0;
                //if shift key is pressed, set focus on the last button
                if(event.shiftKey) _buttonBar.setFocusIndex(event.shiftKey);
                _buttonBar.setFocus();
                _buttonBar.setFocusButton();
            }
        }
    }
}