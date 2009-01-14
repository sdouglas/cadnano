package org.jsonrpc
{
    import flash.events.ErrorEvent;

    public class FaultEvent extends ErrorEvent
    {
        public static const Fault:String="fault"
        
        public var fault:Error
        
        public function FaultEvent(err:Error)
        {
            this.fault = err
            super(Fault, true, true, err.message);
        }
    }
}