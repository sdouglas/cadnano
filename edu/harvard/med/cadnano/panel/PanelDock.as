//
//  PanelDock
//
//  Created by Shawn on 2007-12-02.
//

/* PanelDock sets up dock buttons and updates panels when they are 
minimized or maximized.
*/

package edu.harvard.med.cadnano.panel {
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    public class PanelDock extends Sprite {
        
        private var slicePanel:Panel;
        private var pathPanel:Panel;
        private var renderPanel:Panel;
        
        private var sliceTools:SliceTools;
        private var pathTools:PathTools;
        private var render3DTools:Render3DTools;
        
        // buttons for "minimized" Panel states
        private var minSlice:Sprite;
        private var minPath:Sprite;
        private var minRender:Sprite;
        
        // text label of dock
        private var tf:TextField;
        private var tfm:TextFormat;
        
        public function PanelDock(s:Panel, p:Panel, r:Panel) {
            // position the dock
            this.x = p.w - 150;
            this.y = p.h + 80;
            
            configureLabel(); // add "DOCK" label
            
            this.slicePanel = s;
            this.pathPanel = p;
            this.renderPanel = r;
            
            var rW:int = 32;
            var rH:int = 53;
            
            // create slice button
            this.minSlice = new Sprite();
            this.minSlice.graphics.beginFill(0xcc6600, 0.25);
            this.minSlice.graphics.drawRoundRect(0,0,rW,rH,4);
            this.minSlice.graphics.endFill();
            this.addChild(this.minSlice);
            this.minSlice.addEventListener(MouseEvent.CLICK, toggleSlice);
            
            // create path button
            this.minPath = new Sprite();
            this.minPath.x = this.minSlice.x + this.minSlice.width + 5;
            this.minPath.graphics.beginFill(0x0066cc, 0.25);
            this.minPath.graphics.drawRoundRect(0,0,rW,rH,4);
            this.minPath.graphics.endFill();
            this.addChild(this.minPath);
            this.minPath.addEventListener(MouseEvent.CLICK, togglePath);
            
            // create render3d button
            this.minRender = new Sprite();
            this.minRender.x = this.minPath.x + this.minPath.width + 5;
            this.minRender.graphics.beginFill(0x666666, 0.25);
            this.minRender.graphics.drawRoundRect(0,0,rW,rH,4);
            this.minRender.graphics.endFill();
            this.addChild(this.minRender);
            this.minRender.addEventListener(MouseEvent.CLICK, toggleRender);
        }
        
        // add "DOCK" label under PanelDock buttons
        private function configureLabel():void {
            var label = new TextField();
            label.text = "DOCK";
            label.x = 36;
            label.y = 60;
            var format:TextFormat = new TextFormat();
            format.font = "Verdana";
            format.color = 0x0066cc;
            format.size = 10;
            label.setTextFormat(format);
            addChild(label);
        }
        
        public function addTools(st:SliceTools, pt:PathTools, rt:Render3DTools):void {
            this.sliceTools = st;
            this.pathTools = pt;
            this.render3DTools = rt;
        }
        
        /* Notify panels and toolbars they may need to resize and/or move. */
        public function updatePanels():void {
            this.slicePanel.update();
            this.pathPanel.update();
            this.renderPanel.update();
            this.sliceTools.update();
            this.pathTools.update();
            this.render3DTools.update();
        }
        
        /* Minimize or maximize Slice panel. */
        private function toggleSlice(event:MouseEvent):void {
            //event.updateAfterEvent();
            
            if (this.slicePanel.minimized) {
                this.slicePanel.minimized = false;
                this.sliceTools.visible = true;
                this.pathPanel.left += 1;
                this.renderPanel.left += 1;
            } else {
                this.slicePanel.minimized = true;
                this.sliceTools.visible = false;
                this.pathPanel.left -= 1;
                this.renderPanel.left -= 1;
            }
            updatePanels();
            
            if (!this.slicePanel.minimized) {
                this.sliceTools.drawSlice.reCenter();
            }
        }
        
        /* Minimize or maximize Path panel. */
        private function togglePath(event:MouseEvent):void {
            if (this.pathPanel.minimized) {
                this.pathPanel.minimized = false;
                this.pathTools.visible = true;
                this.slicePanel.right += 1;
                this.renderPanel.left += 1;
            } else {
                this.pathPanel.minimized = true;
                this.pathTools.visible = false;
                this.slicePanel.right -= 1;
                this.renderPanel.left -= 1;
            }
            updatePanels();
        }
        
        /* Minimize or maximize Render panel. */
        public function toggleRender(event:MouseEvent):void {
            event.updateAfterEvent();
            if (this.renderPanel.minimized) {
                this.renderPanel.minimized = false;
                this.render3DTools.visible = true;
                this.render3DTools.render3d.suppressRendering = false;
                this.render3DTools.render3d.redrawBases();
                this.slicePanel.right += 1;
                this.pathPanel.right += 1;
            } else {
                this.renderPanel.minimized = true;
                this.render3DTools.visible = false;
                this.render3DTools.render3d.suppressRendering = true;
                this.slicePanel.right -= 1;
                this.pathPanel.right -= 1;
            }
            updatePanels();
        }
    }
}