package org.jsonrpc
{
    public function service(url:String, name:string=null):JSONRPCService{
        return new JSONRPCService(url, name)
    }
}