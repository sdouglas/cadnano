package org.jsonrpc
{
    import flash.events.EventDispatcher;

    public class PendingInvokation extends EventDispatcher{
        
        public function PendingInvokation(){
            super(this);
        }
        
        
        public function handleError(e:Error):void{
            this.dispatchEvent(new FaultEvent(e))
        }
        
        public function handleFault(f:Error):void{
            this.dispatchEvent(new FaultEvent(f))
        }
        
        public function handleResult(r:*):void{
            this.dispatchEvent(new ResultEvent(r))
        }
    }
}