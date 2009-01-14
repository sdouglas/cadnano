package org.jsonrpc
{
    import flash.events.Event;

    public class ResultEvent extends Event{
        public static const Result:String='result'
        
        public var result:*;
        
        public function ResultEvent(result:*)
        {
            this.result = result
            super(Result);
        }
    }
}