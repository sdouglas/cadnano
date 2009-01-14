package org.jsonrpc
{

    import flash.utils.Proxy;
    import flash.utils.flash_proxy;
      
        
    public dynamic class JSONRPCService extends Proxy {
        
        protected var url:String="./"
        protected var name:String=null
        function JSONRPCService(url:String, name:String=null){
            this.url = url
            this.name = name
        }
        
        override flash_proxy function getProperty(name:*):*{
            if(this.name != null){
                name = this.name + "." + name
            }
            return getMethod(name, url) as Object
        }
        
        override flash_proxy function callProperty(name:*, ...args):*{
            var fn:Function = this.flash_proxy::getProperty(name)
            return fn.apply(this,args)    
        }
    }   
}
    import flash.net.URLRequest;
    import org.jsonrpc.JSONRPCService;
    import flash.net.URLRequestMethod;
    import flash.net.URLStream;
    import flash.events.IOErrorEvent;
    import flash.events.Event;
    import org.jsonrpc.PendingInvokation;
    import org.jsonrpc.ResultEvent;
    import flash.events.SecurityErrorEvent;
    import org.jsonrpc.FaultEvent;
    import org.jsonrpc.json.unmarshall;
    import org.jsonrpc.json.marshall;
    


function getMethod(name:String, url:String):Function{
    
    var fn:Function = function(...args):*{
        var cbResult:Function = null
        var cbError:Function = null
        if(args.length && args[args.length-1] is Function){
            cbResult = args.pop()
            if(args.length && args[args.length-1] is Function){
               cbError = cbResult
               cbResult = args.pop()
            }
        }
       
        var req:URLRequest = new URLRequest(url)
        req.contentType="text/json"
        req.method = URLRequestMethod.POST
        
        var inv:PendingInvokation =new PendingInvokation()
        
        if(cbError!=null){
            inv.addEventListener(FaultEvent.Fault, function(evt:FaultEvent):void{
                cbError(evt.fault)
            })
        }
        
        if(cbResult!=null){
            inv.addEventListener(ResultEvent.Result, function(evt:ResultEvent):void{
                cbResult(evt.result)
            }) 
        }

        try{
            req.data = marshall({method:name, "params":args, id:"json-rpc"})
        }catch(e:Error){
            inv.handleError(e)
            return  
        }
        
        var resp:URLStream = new URLStream()
        resp.addEventListener(IOErrorEvent.IO_ERROR, function(evt:IOErrorEvent):void{
            inv.handleError(new Error(evt.text))    
        })
        
        resp.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(evt:SecurityErrorEvent):void{
            inv.handleError(new Error(evt.text))    
        })
        
        resp.addEventListener(Event.COMPLETE, function(evt:Event):void{
            try{
                var src:String=resp.readUTFBytes(resp.bytesAvailable)
                var o:Object = unmarshall(src)
            }catch(e:Error){
                inv.handleError(e)
                return 
            }
            
            if(o.error == null){
                inv.handleResult(o.result)      
            }else{
                inv.handleError(new Error(o.error.message))        
            }
        })

        resp.load(req)
        return inv
    }
    return fn
}


